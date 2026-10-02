@static_unload
class_name GameState
extends RefCounted

signal changed
signal message(text: String)
signal effect(cell: Vector2i, text: String, good: bool)
signal movement_path(unit_id: String, path: Array)
signal action_performed(actor_id: String, target_id: String, skill: String)
signal battle_finished

const SAVE_PATH = "user://expedition_v1.json"
static var SKILLS: Dictionary = GeneSkills.RULES
var rng = RandomNumberGenerator.new()
var party: Array[UnitData] = []
var home: Array[UnitData] = []
var enemies: Array[UnitData] = []
var pending: Array[UnitData] = []
var escorts: Array[UnitData] = []
var contracts: Dictionary = {}
var debt: int = ContractRules.DEBT
var world = Dungeon.new()
var mode: String = "town"
var selected: int = 0
var gold: int = 180
var capacity: int = 6
var potions: int = 5
var stored_potions: int = 0
var stored_gold: int = 0
var floor_number: int = 1
var cleared: Array = []
var combat_ids: Array = []
var clock: int = 0
var active_id: String = ""
var turn_serial: int=0 # Runtime action identity, including consecutive turns by one actor.
var serial: int = 0
var last_error: String = ""
var save_blocked: bool = false
var log_lines: Array[String] = []
var combat_room: int=-1
var origin_profile="负债继承人"
var quiz_answers: Array=[]
var expedition_plan: String=""
var expedition_risk: bool=false

func new_game(seed_number: int = 0) -> void:
	if seed_number == 0: rng.randomize()
	else: rng.seed = seed_number
	party.clear()
	home.clear()
	enemies.clear()
	pending.clear()
	serial = 0
	escorts.clear(); contracts.clear(); debt=ContractRules.DEBT
	gold = 180
	capacity = 6
	potions = 5
	stored_potions = 0
	stored_gold = 0
	cleared.clear()
	clock=0
	floor_number=1
	for i in range(2):
		var u = create_unit(0, ["阿德勒","莉泽"][i],"party")
		u.profession=0 if i==0 else 1
		u.equipped_skills.clear(); u.ensure_loadout()
		party.append(u)
	save_blocked=false
	last_error=""
	log_lines.clear()
	origin_profile="负债继承人"
	quiz_answers.clear()
	return_town(false)
	note("你继承了一张 3000 金币的借据。自由市的佣兵公会愿为你提供工作：从任务栏接取第一份清剿或护送委托。")

func create_unit(species: int, unit_name: String, faction: String) -> UnitData:
	serial += 1
	var u = UnitData.new()
	u.uid = "%08x-%06d" % [rng.randi(),serial]
	u.bloodline=Bloodline.pure(species)
	if faction=="enemy":
		var weights=u.bloodline.duplicate(); weights[species]=rng.randi_range(4500,8000)
		weights[(species+rng.randi_range(1,6))%7]=10000-weights[species]
		u.bloodline=weights
	u.profession=rng.randi_range(0,2) if faction=="enemy" else 0
	u.display_name = unit_name
	u.faction = faction
	u.genes = Genome.random_genes(rng)
	Genome.seed_traits(u.genes,u.bloodline)
	# Shared latent alleles occasionally occur in any background.
	if faction=="enemy":
		for locus in Genome.TRAITS:
			if rng.randf()<0.12: u.genes[locus][rng.randi_range(0,1)]=rng.randi_range(40,100)
	u.ensure_loadout()
	u.heal()
	return u

func note(text: String) -> void:
	log_lines.append(text)
	if log_lines.size() > 40: log_lines.pop_front()
	message.emit(text)

func roster_size() -> int: return party.size() + home.size()
func expand_cost() -> int: return 120 + (capacity - 6) * 20
func current() -> UnitData:
	if mode == "battle": return by_id(active_id)
	if party.is_empty(): return null
	return party[clampi(selected,0,party.size()-1)]

func by_id(id: String) -> UnitData:
	for u in party + enemies + home + escorts:
		if u.uid == id: return u
	return null

func field_units() -> Array:
	return party+enemies+escorts

func occupied(exclude: UnitData = null) -> Array:
	var cells = []
	for u in field_units():
		if u != exclude and u.alive(): cells.append(u.cell)
	return cells

func unit_at(p: Vector2i) -> UnitData:
	for u in field_units():
		if u.cell == p and u.alive(): return u
	return null

func select_unit(index: int) -> void:
	if mode == "battle": return
	if index >= 0 and index < party.size() and party[index].alive():
		selected = index
		changed.emit()

func return_town(announce: bool = true) -> void:
	expedition_plan=""; expedition_risk=false
	ContractRules.fail_escort(self,"提前返回自由市")
	escorts.clear()
	mode = "town"
	combat_ids.clear()
	combat_room=-1
	active_id = ""
	enemies.clear()
	world = Dungeon.new()
	world.biome = 0
	for x in range(1,25):
		for y in range(1,15): world.cells[Vector2i(x,y)] = true
	# Buildings occupy solid footprints; doors remain approachable.
	for r in [Rect2i(3,3,4,3),Rect2i(17,3,4,3),Rect2i(3,10,4,3),Rect2i(17,10,4,3)]:
		for x in range(r.position.x,r.end.x):
			for y in range(r.position.y,r.end.y): world.cells.erase(Vector2i(x,y))
	for i in range(party.size()):
		party[i].cell = Vector2i(11+i,8)
		party[i].town_position=Vector2(party[i].cell)*40+Vector2(20,20)
		party[i].clear_battle_state(true)
		party[i].heal()
		party[i].ap = 100
	for u in home: u.clear_battle_state(true); u.heal()
	for u in pending: u.clear_battle_state()
	selected = 0
	if announce: note("回到阿德勒自由市，所有伙伴已恢复。欢迎回家。")
	changed.emit()

func enter_dungeon(style: int, plan: String="", high_risk: bool=false) -> bool:
	if mode != "town" or not pending.is_empty() or style < 0 or style >= 5: return false
	if not ExpeditionRules.valid_plan(plan): return false
	if not dungeon_unlocked(style): note("先完成前一片区域的远征，才能取得通行徽记。"); return false
	expedition_plan=plan; expedition_risk=high_risk
	floor_number = 1
	build_floor(style)
	if not plan.is_empty(): note("本次战术："+ExpeditionRules.PLANS[plan].name+(" · 高危悬赏" if high_risk else " · 普通强度"))
	return true

func build_floor(style: int) -> void:
	world = Dungeon.new()
	world.generate(rng.randi(),style)
	mode = "explore"
	selected = 0
	combat_ids.clear()
	combat_room=-1
	active_id = ""
	enemies.clear()
	var spawn = world.reachable(world.start,4).keys()
	for i in range(party.size()):
		party[i].cell = spawn[i]
		party[i].ap = 100
	for room_index in range(1,6):
		var room: Rect2i=world.rooms[room_index]
		for j in range(2):
			var species=(style+room_index+j)%7
			var u=create_unit(species,"流寇 · "+MercenaryRules.NAMES[(room_index*2+j+style)%10],"enemy")
			u.level=1+style*3+floor_number+room_index/3+(2 if expedition_risk else 0)
			u.elite=floor_number==3 and room_index==5 and j==0
			if u.elite:
				u.level+=3
				u.display_name="守望者 · "+u.display_name
				u.genes.body_a=[1,1]; u.genes.body_b=[1,1]
				u.equipped_skills.assign([u.carried_skills().back(),"guard","delay","mend"])
			u.ensure_loadout()
			u.heal()
			u.cell=room.get_center()+Vector2i(j,0)
			enemies.append(u)
	ContractRules.enter_floor(self)
	note("抵达%s · 第 %d / 3 层。进入有敌人的房间开始战斗，清空该房间即可脱战。" % [Dungeon.BIOMES[style].name,floor_number])
	changed.emit()

func distance(a: Vector2i, b: Vector2i) -> int: return absi(a.x-b.x)+absi(a.y-b.y)

func move_to(target: Vector2i) -> bool:
	if mode=="town": return false # TownMovement owns continuous safe-zone motion.
	var u = current()
	if u == null or not u.alive() or u.faction != "party": return false
	var route: Array[Vector2i]=[]
	if mode=="explore" and distance(u.cell,target)==1:
		if world.walkable(target) and unit_at(target)==null: route.append(target)
	else: route=world.path(u.cell,target,battle_blocked(u) if mode=="battle" else occupied(u))
	if route.is_empty(): return false
	if mode == "battle":
		if u.moved or route.size()>u.movement(): return false
		var cost = route.size() * 8
		if cost > u.ap: note("行动点不足：每格移动消耗 8 AP。"); return false
		u.moved=true
		u.ap -= cost
		u.spent += cost
		movement_path.emit(u.uid,route)
		u.cell = target
		collect_loot(u)
		join_nearby()
		changed.emit()
		return true
	# Exploration progresses one cell at a time, checking aggro after every step.
	var old = u.cell
	movement_path.emit(u.uid,[route[0]])
	u.cell = route[0]
	var follow = old
	for ally in party:
		if ally == u or not ally.alive(): continue
		var p: Array[Vector2i]=[]
		if distance(ally.cell,follow)==1 and world.walkable(follow) and unit_at(follow)==null: p.append(follow)
		else: p=world.path(ally.cell,follow,occupied(ally))
		var previous = ally.cell
		if not p.is_empty():
			movement_path.emit(ally.uid,[p[0]])
			ally.cell = p[0]
		follow = previous
	ContractRules.follow(self,follow)
	if mode == "explore":
		collect_loot(u)
		check_aggro()
	changed.emit()
	return true

func collect_loot(u: UnitData) -> void:
	if u.cell in world.loot:
		world.loot.erase(u.cell)
		gold += 25
		potions += 1
		effect.emit(u.cell,"+25 金币 / 药草 +1",true)
		note("找到旅行补给：25 金币与 1 份药草。")

func battle_blocked(u: UnitData) -> Array:
	var blocked=occupied(u)
	if mode=="battle" and combat_room>=0:
		for cell in world.cells:
			if world.room_at(cell)!=combat_room and cell!=u.cell: blocked.append(cell)
	return blocked

func move_range(u: UnitData) -> Dictionary:
	if u==null or u.moved: return {}
	return world.reachable(u.cell,mini(u.movement(),u.ap/8),battle_blocked(u))

func check_aggro() -> void:
	if mode!="explore": return
	var room_id=world.room_at(current().cell)
	if room_id<0: return
	if enemies.any(func(e): return e.alive() and world.room_at(e.cell)==room_id): start_battle(room_id)

func start_battle(room_id: int=-1) -> void:
	if room_id<0: room_id=world.room_at(current().cell)
	if room_id<0 or room_id>=world.rooms.size(): return
	var threats=enemies.filter(func(e): return e.alive() and world.room_at(e.cell)==room_id)
	if threats.is_empty(): return
	combat_room=room_id
	# Companions gather at the entrance instead of fighting across room borders.
	var spots: Array=[]
	for cell in world.cells:
		if world.room_at(cell)==room_id and unit_at(cell)==null: spots.append(cell)
	var entrance=current().cell
	spots.sort_custom(func(a,b): return distance(a,entrance)<distance(b,entrance))
	for ally in party+escorts:
		if not ally.alive() or world.room_at(ally.cell)==room_id: continue
		if not spots.is_empty():
			var destination: Vector2i=spots.pop_front()
			var route=world.path(ally.cell,destination,occupied(ally))
			if not route.is_empty(): movement_path.emit(ally.uid,route)
			ally.cell=destination
	mode="battle"
	clock=0
	combat_ids.clear()
	for u in party+threats:
		if u.alive():
			combat_ids.append(u.uid)
			u.clear_battle_state()
			u.ready_at=maxi(0,(20 if u.faction=="party" else 26)-u.speed()-(10 if BattleRules.ability(u)==5 else 0))
	note("房间 %d 的战斗开始。我方回合自动选中角色；点击目标格移动，WASD 移动镜头。" % (room_id+1))
	advance()

func join_nearby() -> void:
	pass # The encounter roster is locked to a single room at battle start.

func timeline() -> Array:
	var list = []
	for id in combat_ids:
		var u = by_id(id)
		if u != null and u.alive(): list.append(u)
	list.sort_custom(func(a,b): return a.ready_at < b.ready_at if a.ready_at != b.ready_at else a.uid < b.uid)
	return list

func advance() -> void:
	var allies_alive = party.any(func(u): return u.alive())
	if not allies_alive:
		gold = floori(gold * 0.8)
		pending.clear()
		return_town(false)
		note("远征队被救援回镇，遗失随身金币的 20%。伙伴与仓库物品均被保留。")
		changed.emit()
		return
	var threats = enemies.filter(func(e): return e.alive() and e.uid in combat_ids)
	if threats.is_empty():
		mode = "explore"
		combat_room=-1
		battle_finished.emit()
		active_id = ""
		combat_ids.clear()
		for foe in enemies: foe.combo_from=""; foe.combo_used=false
		for unit in party:
			unit.clear_battle_state()
			if expedition_plan=="tempo" and unit.alive():
				var recovery=mini(unit.max_hp()-unit.hp,maxi(1,roundi(unit.max_hp()*0.1)))
				unit.hp+=recovery
				if recovery>0: effect.emit(unit.cell,"战后整备 +%d" % recovery,true)
		for i in range(party.size()):
			if party[i].alive(): selected = i; break
		note("战斗结束。可以邀请倒下的落败佣兵，或继续探索。")
		changed.emit()
		return
	var list = timeline()
	var u: UnitData = list[0]
	active_id = u.uid
	turn_serial+=1
	clock = maxi(clock,u.ready_at)
	u.ap = 100
	u.spent = 0
	u.moved=false
	begin_action(u)
	changed.emit()

func end_turn() -> bool:
	if mode != "battle": return false
	var u = current()
	u.ready_at = clock + return_delay(u)
	if u.faction=="enemy": ContractRules.tick_escorts(self)
	advance()
	return true

func return_delay(u: UnitData, extra_cost: int = 0) -> int:
	var spent=u.spent+extra_cost
	var tempo=12 if expedition_plan=="tempo" and u.faction=="party" and spent>0 and spent<=50 else 0
	return maxi(12,(80 if spent<=50 else 150)-roundi(BattleRules.stat(u,"speed"))*2-tempo)

func can_cast(skill: String, target: UnitData) -> bool:
	if mode!="battle" or not SKILLS.has(skill): return false
	var u=current()
	if u==null or target==null or not target in field_units(): return false
	if target.faction=="enemy" and not target.uid in combat_ids: return false
	if not u.has_skill(skill) or not u.alive() or not target.alive(): return false
	var rule=SKILLS[skill]
	if target in escorts and rule.has("shift") and not rule.has("power") and not rule.has("heal"): return false
	if u.cooldown(skill)>0 or u.status=="sleep": return false
	if u.ap<rule.cost or distance(u.cell,target.cell)>rule.range or not world.sight(u.cell,target.cell): return false
	var friendly=(u.faction=="enemy")== (target.faction=="enemy")
	match rule.target:
		"enemy": return not friendly
		"ally": return friendly
		"other_ally": return friendly and u!=target
		"self": return u==target
	return false

func predict(skill: String, target: UnitData) -> Dictionary:
	if not SKILLS.has(skill) or target==null or current()==null: return {}
	var rule=SKILLS[skill]
	var rate=RecruitmentRules.breakdown(target,party[0],cleared).chance
	if target.elite and not world.biome in cleared: rate=0.0
	var bonus=ExpeditionRules.bonus(expedition_plan,current(),target,rule,current().spent+rule.cost)
	return {"damage":roundi(BattleRules.damage(current(),target,rule,world.biome)*bonus.multiplier),"effect":BattleRules.effectiveness(rule.element,target),"accuracy":rule.accuracy,"rate":rate,"bonus_shift":bonus.shift,"tactic":bonus.tag}

func cast(skill: String, target: UnitData) -> bool:
	if not can_cast(skill,target): return false
	var u=current()
	var rule=SKILLS[skill]
	action_performed.emit(u.uid,target.uid,skill)
	u.ap-=rule.cost; u.spent+=rule.cost
	u.cooldowns[skill]=rule.cooldown
	if rng.randf()*100>=rule.accuracy:
		effect.emit(target.cell,"闪避",true); note(u.display_name+"的"+rule.name+"未命中。"); changed.emit(); return true
	var targets=[target]
	if rule.get("splash",0)>0:
		for other in field_units():
			if other!=target and other.alive() and (other.faction=="enemy")!=(u.faction=="enemy") and (other.uid in combat_ids or other in escorts) and distance(other.cell,target.cell)<=1: targets.append(other)
	for victim in targets:
		apply_skill(u,victim,rule,victim!=target)
	if not party.any(func(a): return a.alive()) or not enemies.any(func(e): return e.alive() and e.uid in combat_ids): advance()
	changed.emit()
	return true

func apply_skill(actor: UnitData, target: UnitData, rule: Dictionary, splash: bool=false) -> void:
	var detail=""
	var immune=false
	if rule.has("power"):
		var critical=rng.randf()<0.0625
		var amount=BattleRules.damage(actor,target,rule,world.biome,critical)
		var bonus=ExpeditionRules.bonus(expedition_plan,actor,target,rule,actor.spent) if not splash else {"multiplier":1.0,"shift":0,"tag":""}
		amount=roundi(amount*bonus.multiplier)
		if splash: amount=roundi(amount*0.5)
		immune=BattleRules.effectiveness(rule.element,target)==0
		if immune:
			detail="无效"
			if BattleRules.ability(target) in [2,3]:
				target.hp=mini(target.max_hp(),target.hp+maxi(1,target.max_hp()/8))
				detail="特性吸收"
		else:
			target.hp=maxi(0,target.hp-amount); target.guard=false
			detail="-%d%s%s" % [amount," 会心" if critical else ""," 克制!" if BattleRules.effectiveness(rule.element,target)>1 else (" 抵抗" if BattleRules.effectiveness(rule.element,target)<1 else "")]
			if not bonus.tag.is_empty():
				detail+=" · "+bonus.tag
				if target.alive(): target.ready_at=maxi(clock+1,target.ready_at+bonus.shift)
				if expedition_plan=="relay": target.combo_used=true; target.combo_from=""
				if expedition_plan=="burst": actor.burst_used=true
			elif expedition_plan=="relay" and actor.faction=="party" and target.faction=="enemy" and not target.combo_used and not splash:
				target.combo_from=actor.uid; detail+=" · 协同标记"
			if target.status=="sleep": target.status=""; target.status_turns=0
			if rule.has("drain"): actor.hp=mini(actor.max_hp(),actor.hp+roundi(amount*rule.drain))
	if rule.has("heal"):
		var recovered=mini(rule.heal,target.max_hp()-target.hp); target.hp+=recovered; detail="+%d HP" % recovered
	if rule.get("cleanse",false): target.status=""; target.status_turns=0; detail+=" 净化"
	if rule.get("guard",false): target.guard=true; detail+=" 守势"
	if rule.get("mark",false): target.marked=true; detail+=" 共鸣 +10%"
	if not immune and target.alive():
		if rule.has("shift"): target.ready_at=maxi(clock+1,target.ready_at+rule.shift); detail+=" 时序%+d" % rule.shift
		if rule.has("stage"):
			var recipient=actor if rule.get("stage_self",false) else target
			recipient.stages[rule.stage]=clampi(int(recipient.stages.get(rule.stage,0))+int(rule.stage_amount),-3,3)
			detail+=" "+GeneTraits.STAT_NAMES[rule.stage]+"%+d" % rule.stage_amount
		if rule.has("status") and target.status.is_empty() and not BattleRules.immune_status(target,rule.status) and rng.randf()<rule.chance:
			target.status=rule.status; target.status_turns=1 if rule.status=="sleep" else 3
			detail+=" "+BattleRules.STATUS_NAMES[rule.status]
	effect.emit(target.cell,detail,rule.target!="enemy")
	note("%s → %s：%s，%s" % [actor.display_name,target.display_name,rule.name,detail])
	if not target.alive(): defeated(target,actor)

func begin_action(u: UnitData) -> void:
	u.combo_from=""; u.combo_used=false; u.burst_used=false
	u.guard=false
	for id in u.cooldowns.keys(): u.cooldowns[id]=maxi(0,int(u.cooldowns[id])-1)
	if u.status in ["burn","poison"]:
		var damage=maxi(1,u.max_hp()/(8 if u.status=="poison" else 12))
		u.hp=maxi(0,u.hp-damage); effect.emit(u.cell,BattleRules.STATUS_NAMES[u.status]+" -%d" % damage,false)
		if not u.alive(): defeated(u); advance(); return
	if BattleRules.ability(u)==0 or (world.biome==0 and "leaf" in BattleRules.types(u)):
		u.hp=mini(u.max_hp(),u.hp+maxi(1,u.max_hp()/20))
	if u.status=="shock": u.ap=75
	var asleep=u.status=="sleep"
	if not u.status.is_empty():
		u.status_turns-=1
		if u.status_turns<=0: u.status=""
	if asleep:
		note(u.display_name+"睡眠中，错过一次行动。")
		u.ready_at=clock+return_delay(u); advance()

func defeated(u: UnitData, finisher: UnitData=null) -> void:
	if u.faction=="escort":
		ContractRules.defeated(self,u); return
	if u.faction!="enemy": note(u.display_name+"暂时倒下，回镇后可恢复。"); return
	if u.recruit_rolled: return
	u.recruit_rolled=true
	ContractRules.defeated(self,u)
	gold+=roundi((35 if u.elite else 18)*(1.5 if expedition_risk else 1.0))
	for ally in party:
		if ally.alive():
			var before=ally.level
			ally.gain_xp(40 if u.elite else 18); ally.add_effort(GeneTraits.STATS[Genome.express(u.genes,"pattern")%6],2)
			if ally.level>before: note("%s 升至 Lv.%d！新技能已可配招。" % [ally.display_name,ally.level])
	var rate=RecruitmentRules.breakdown(u,party[0],cleared).chance
	u.last_recruit_rate=rate
	if finisher==null or finisher.faction!="party": note(u.display_name+"被环境击倒，无法建立同行羁绊。"); return
	if u.elite and not world.biome in cleared: note("首次击败守望者！现在可以前往终点取得通行徽记。"); return
	if rng.randf()*100<rate:
		pending.append(u); note("%s 愿意同行！本次招募率 %.1f%%。" % [u.display_name,rate])
	else: note("%s 离开了，招募未成功（%.1f%%）。可在下次相遇时尝试。" % [u.display_name,rate])

func best_ai_action(u: UnitData) -> Dictionary:
	var best={"score":0.0,"skill":"","target":null}
	for id in u.carried_skills():
		var rule=SKILLS[id]
		for target in field_units():
			if (not target.uid in combat_ids and not target in escorts) or not can_cast(id,target): continue
			var score=0.0
			if rule.has("power"):
				var dealt=BattleRules.damage(u,target,rule,world.biome)
				score=dealt+(25 if dealt>=target.hp else 0)
				if rule.has("status") and target.status.is_empty() and not BattleRules.immune_status(target,rule.status): score+=12*rule.chance
				if rule.has("shift"): score+=rule.shift*0.16
			if rule.has("heal"): score+=mini(rule.heal,target.max_hp()-target.hp)*1.3
			if rule.get("cleanse",false) and not target.status.is_empty(): score+=15
			if rule.get("guard",false) and not target.guard and u.hp<u.max_hp()/2: score+=10
			if rule.get("shift",0)<0: score+=maxi(0,target.ready_at-clock)*0.3
			score=score/maxf(15,rule.cost)*30
			if score>best.score: best={"score":score,"skill":id,"target":target}
	return best

func enemy_turn() -> void:
	if mode!="battle" or current().faction!="enemy": return
	var u=current()
	var choice=best_ai_action(u)
	if choice.skill.is_empty():
		var targets=(party+escorts).filter(func(a): return a.alive())
		if targets.is_empty(): advance(); return
		targets.sort_custom(func(a,b): return distance(a.cell,u.cell)<distance(b.cell,u.cell))
		var target: UnitData=targets[0]
		var positions=world.reachable(u.cell,mini(u.movement(),6),battle_blocked(u))
		var best=u.cell
		for cell in positions:
			if positions[cell]*8<=u.ap-25 and distance(cell,target.cell)<distance(best,target.cell): best=cell
		if best!=u.cell:
			var path=world.path(u.cell,best,battle_blocked(u)); movement_path.emit(u.uid,path)
			u.cell=best; u.ap-=path.size()*8; u.spent+=path.size()*8; u.moved=true
	for i in range(3):
		if mode!="battle" or current()!=u: break
		choice=best_ai_action(u)
		if choice.skill.is_empty(): break
		if u.spent>0 and u.spent+SKILLS[choice.skill].cost>50 and choice.score<25: break
		cast(choice.skill,choice.target)
	if mode=="battle" and current()==u: end_turn()

func dungeon_unlocked(style: int) -> bool:
	return style>=0 and style<5 and (style==0 or style-1 in cleared)

func recruit(candidate: UnitData) -> bool:
	if mode == "battle" or not candidate in pending: return false
	if roster_size() >= capacity:
		note("家园床位已满，请先回镇扩容。待邀请伙伴会保留在邀请列表中。")
		return false
	pending.erase(candidate)
	enemies.erase(candidate)
	candidate.display_name=candidate.display_name.trim_prefix("流寇 · ")
	candidate.heal()
	if party.size() < 4:
		candidate.faction = "party"
		var spots = world.reachable(current().cell,20,occupied()).keys()
		spots.erase(current().cell)
		if not spots.is_empty(): candidate.cell = spots[0]
		party.append(candidate)
		note("%s 加入远征队！" % candidate.display_name)
	else:
		candidate.faction = "home"
		home.append(candidate)
		note("远征队已达 4 人；最后加入的 %s 已安全送回家园。" % candidate.display_name)
	changed.emit()
	return true

func release_candidate(u: UnitData) -> void:
	if u in pending:
		pending.erase(u)
		note("与 %s 道别，愿在旅途中再次相遇。" % u.display_name)
		changed.emit()

func expand_home() -> bool:
	if mode != "town" or gold < expand_cost(): return false
	gold -= expand_cost()
	capacity += 4
	note("家园扩容完成：现在可为 %d 位伙伴保留床位。" % capacity)
	changed.emit()
	return true

func send_home(u: UnitData) -> bool:
	if mode != "town" or not u in party or u == party[0]: return false
	party.erase(u)
	u.faction = "home"
	home.append(u)
	selected = 0
	changed.emit()
	return true

func add_to_party(u: UnitData) -> bool:
	if mode != "town" or not u in home or party.size() >= 4: return false
	home.erase(u)
	u.faction = "party"
	var p = world.reachable(party[0].cell,10,occupied()).keys()
	p.erase(party[0].cell)
	u.cell = p[0]
	u.town_position=Vector2(u.cell)*40+Vector2(20,20)
	party.append(u)
	changed.emit()
	return true

func breed(a: UnitData, b: UnitData) -> UnitData:
	if mode != "town" or a == null or b == null or a == b: return null
	if not a in party+home or not b in party+home: return null
	if roster_size() >= capacity or gold < 60: return null
	if a.uid in b.parents or b.uid in a.parents or a.parents.any(func(id): return id in b.parents):
		note("请选择不同家系的伙伴，避免亲子与同胞配对。")
		return null
	var baby = create_unit(0,"后裔 · "+MercenaryRules.NAMES[serial%10],"home")
	var inherited = Genome.inherit_genes(a.genes,b.genes,rng)
	baby.bloodline=Bloodline.inherit(a.bloodline,b.bloodline)
	baby.profession=0; baby.profession_xp=[0,0,0]
	baby.genes = inherited.genes
	baby.equipped_skills.clear()
	baby.ensure_loadout()
	baby.mutations = inherited.mutations
	baby.parents = [a.uid,b.uid]
	baby.generation = maxi(a.generation,b.generation)+1
	baby.heal()
	gold -= 60
	home.append(baby)
	note("家系推演完成：成年后裔 %s 登记为候补佣兵，发现 %d 处变异。" % [baby.display_name,baby.mutations.size()])
	changed.emit()
	return baby

func buy_potion() -> bool:
	if mode != "town" or gold < 20: return false
	gold -= 20
	potions += 1
	note("购买药草 ×1。")
	changed.emit()
	return true

func use_potion(u: UnitData) -> bool:
	if u == null or not u in party or not u.alive() or potions <= 0 or u.hp >= u.max_hp(): return false
	if mode == "battle":
		if current() != u or u.ap < 20: return false
		u.ap -= 20
		u.spent += 20
	potions -= 1
	u.hp = mini(u.max_hp(),u.hp+40)
	effect.emit(u.cell,"+40",true)
	note("%s 使用药草，恢复 40 点生命。" % u.display_name)
	changed.emit()
	return true

func transfer(item: String, deposit: bool) -> bool:
	if mode != "town": return false
	if item == "potion":
		if (potions if deposit else stored_potions) < 1: return false
		potions += -1 if deposit else 1
		stored_potions += 1 if deposit else -1
	elif item == "gold":
		if (gold if deposit else stored_gold) < 50: return false
		gold += -50 if deposit else 50
		stored_gold += 50 if deposit else -50
	else: return false
	changed.emit()
	return true

func descend() -> bool:
	if mode != "explore" or current().cell != world.stairs: return false
	if not pending.is_empty(): note("请先处理待邀请伙伴，再前往下一层。也可以带着邀请列表回镇。 "); return false
	ContractRules.stairs(self)
	if escorts.any(func(u): return u.alive()) and floor_number>=2:
		note("请接应护送委托人后再下楼。"); return false
	if floor_number == 3:
		if enemies.any(func(e): return e.elite and e.alive()): note("终点的守望者尚未被击败，通行徽记仍被封印。"); return false
		var style = world.biome
		if not style in cleared: cleared.append(style)
		var reward=240 if expedition_risk else 120
		gold += reward
		return_town(false)
		note("完成%s远征，获得 %d 金币！%s" % [Dungeon.BIOMES[style].name,reward,"解锁 "+Dungeon.BIOMES[style+1].name if style<4 else "五域远征全部完成！"])
	else:
		floor_number += 1
		build_floor(world.biome)
	changed.emit()
	return true

func retreat() -> bool:
	if mode == "town": return false
	if mode == "battle":
		gold = floori(gold * 0.9)
		note("紧急撤离，遗失随身金币的 10%。")
	return_town()
	return true

func serialize() -> Dictionary:
	return {"version":5,"expedition_plan":expedition_plan,"expedition_risk":expedition_risk,"debt":debt,"contracts":contracts.duplicate(true),"escorts":escorts.map(func(u): return u.serialize()),"combat_room":combat_room,"origin_profile":origin_profile,"quiz_answers":quiz_answers,"saved_at":Time.get_datetime_string_from_system(),"party":party.map(func(u): return u.serialize()),"home":home.map(func(u): return u.serialize()),"enemies":enemies.map(func(u): return u.serialize()),"pending":pending.map(func(u): return u.serialize()),"world":world.serialize(),"mode":mode,"selected":selected,"gold":gold,"capacity":capacity,"potions":potions,"stored_potions":stored_potions,"stored_gold":stored_gold,"floor":floor_number,"cleared":cleared,"combat_ids":combat_ids,"clock":clock,"active_id":active_id,"serial":serial,"rng":str(rng.state),"log":log_lines}

func valid_save(d: Variant) -> bool:
	if not d is Dictionary: return false
	for key in ["version","party","home","enemies","pending","world","mode","selected","gold","capacity","potions","stored_potions","stored_gold","floor","cleared","combat_ids","clock","active_id","serial","rng"]:
		if not d.has(key): return false
	if (d.version!=1 and d.version!=2 and d.version!=3 and d.version!=4 and d.version!=5) or not d.mode in ["town","explore","battle"]: return false
	if d.version>=4:
		if not d.has("debt") or not MercenaryRules.is_number(d.debt) or d.debt!=int(d.debt) or d.debt<0 or d.debt>ContractRules.DEBT: return false
		if not d.has("contracts") or not ContractRules.valid(d.contracts): return false
		if not d.has("escorts") or not d.escorts is Array or d.escorts.size()>1: return false
	if d.has("expedition_plan") and (not d.expedition_plan is String or not ExpeditionRules.valid_plan(d.expedition_plan)): return false
	if d.has("expedition_risk") and not d.expedition_risk is bool: return false
	if d.mode=="town" and (not d.get("expedition_plan","").is_empty() or d.get("expedition_risk",false)): return false
	if d.has("escorts"):
		if not d.escorts is Array or d.escorts.size()>1: return false
		if d.mode=="town" and not d.escorts.is_empty(): return false
	if d.has("contracts"):
		if not ContractRules.valid(d.contracts): return false
		var traveling=d.contracts.values().filter(func(q): return q.state=="travel").size()
		if traveling>0 and (d.mode=="town" or d.get("escorts",[]).size()!=1): return false
	if d.has("combat_room"):
		if not (d.combat_room is int or d.combat_room is float) or d.combat_room<-1 or d.combat_room>5: return false
		if d.mode=="battle" and d.combat_room<0: return false
	if d.has("origin_profile") and not d.origin_profile is String: return false
	if d.has("quiz_answers"):
		if not d.quiz_answers is Array or (not d.quiz_answers.is_empty() and d.quiz_answers.size()!=10): return false
		if not d.quiz_answers.all(func(a): return (a is int or a is float) and a>=0 and a<=3 and float(a)==floor(float(a))): return false
	for key in ["party","home","enemies","pending","cleared","combat_ids"]:
		if not d[key] is Array: return false
	for key in ["gold","capacity","potions","stored_potions","stored_gold","floor","selected","clock","serial"]:
		if not (d[key] is float or d[key] is int) or d[key]<0: return false
	if not d.cleared.all(func(v): return (v is int or v is float) and float(v)==floor(float(v)) and v>=0 and v<5): return false
	if d.party.is_empty() or d.party.size()>4 or d.party.size()+d.home.size()>d.capacity: return false
	if d.has("log"):
		if not d.log is Array or not d.log.all(func(line): return line is String): return false
	if d.floor<1 or d.floor>3 or d.selected >= d.party.size(): return false
	if not d.rng is String or not d.rng.is_valid_int(): return false
	var ids = []
	for u in d.party+d.home+d.enemies+d.pending+d.get("escorts",[]):
		if not u is Dictionary: return false
		for key in ["uid","name","genes","level","xp","faction","hp","cell","ready_at","ap","spent"]:
			if not u.has(key): return false
		if not u.genes is Dictionary or not Genome.valid(u.genes,d.version<5): return false
		if d.version>=5:
			if not u.has("bloodline") or not Bloodline.valid(u.bloodline): return false
		else:
			if not u.has("species") or not MercenaryRules.is_number(u.species) or u.species!=int(u.species) or u.species<0 or u.species>6: return false
		if not u.uid is String or not u.name is String or not u.faction in ["party","home","enemy","escort"]: return false
		for key in ["level","xp","hp","ready_at","ap","spent"]:
			if not (u[key] is float or u[key] is int) or u[key]<0: return false
		if not MercenaryRules.valid_unit_fields(u) or not ExpeditionRules.valid_unit(u): return false
		if not u.get("combo_from","").is_empty():
			if d.mode!="battle" or u.faction!="enemy" or not u.uid in d.combat_ids or not d.party.any(func(ally): return ally is Dictionary and ally.get("uid","")==u.combo_from and ally.get("uid","") in d.combat_ids): return false
		if u.has("effort"):
			if not u.effort is Dictionary: return false
			var total=0
			for stat in GeneTraits.STATS:
				var value=u.effort.get(stat,0)
				if not (value is int or value is float) or value<0 or value>64 or float(value)!=floor(float(value)): return false
				total+=int(value)
			if total>192: return false
		if u.has("equipped"):
			if not u.equipped is Array or u.equipped.is_empty() or u.equipped.size()>4: return false
			var specimen=UnitData.new()
			specimen.bloodline=u.get("bloodline",Bloodline.legacy(u)); specimen.genes=Genome.migrate_traits(u.genes,specimen.bloodline); specimen.level=int(u.level); specimen.profession=int(u.get("profession",0)); specimen.profession_xp=u.get("profession_xp",[0,0,0])
			var learned=specimen.skill_pool()
			if d.version<4: learned.append(["ember","gust","rockfall","vine","tide"][mini(4,int(u.species))])
			var unique=[]
			for id in u.equipped:
				if not id is String or not id in learned or id in unique: return false
				unique.append(id)
		if u.has("status") and (not u.status is String or (not u.status.is_empty() and not BattleRules.STATUS_NAMES.has(u.status))): return false
		for key in ["status_turns","last_recruit_rate"]:
			if u.has(key) and (not (u[key] is int or u[key] is float) or u[key]<0 or u[key]>100): return false
		for key in ["guard","marked","elite","recruit_rolled"]:
			if u.has(key) and not u[key] is bool: return false
		for key in ["stages","cooldowns"]:
			if not u.has(key): continue
			if not u[key] is Dictionary: return false
			for k in u[key]:
				if not k is String or (key=="stages" and not k in ["attack","defense","magic","resist","speed"]) or (key=="cooldowns" and not SKILLS.has(k)): return false
				var v=u[key][k]
				if not (v is float or v is int) or v!=floor(v) or v>3 or v<(-3 if key=="stages" else 0): return false
		if u.has("moved") and not u.moved is bool: return false
		if u.level<1 or u.ap>100: return false
		for key in ["parents","mutations"]:
			if u.has(key) and (not u[key] is Array or not u[key].all(func(v): return v is String)): return false
		if u.has("generation") and not (u.generation is int or u.generation is float): return false
		if not u.cell is Array or u.cell.size()!=2: return false
		if u.has("town_position"):
			if not u.town_position is Array or u.town_position.size()!=2: return false
			for v in u.town_position:
				if not (v is float or v is int) or not is_finite(float(v)): return false
		for v in u.cell:
			if not (v is float or v is int): return false
	for u in d.party+d.home+d.enemies+d.get("escorts",[]):
		if u.uid in ids: return false
		ids.append(u.uid)
	for u in d.party:
		if u.faction != "party": return false
	for u in d.home:
		if u.faction != "home": return false
	for u in d.get("escorts",[]):
		if u.faction!="escort" or u.uid in d.combat_ids: return false
	if d.mode == "battle" and (not d.active_id in d.combat_ids or not d.active_id in ids): return false
	for id in d.combat_ids:
		if not id in ids: return false
	if not d.world is Dictionary: return false
	if d.world.has("rooms"):
		if not d.world.rooms is Array or d.world.rooms.size()>6: return false
		for room in d.world.rooms:
			if not room is Array or room.size()!=4: return false
			if not room.all(func(n): return (n is int or n is float) and float(n)==floor(float(n))): return false
			if room[0]<0 or room[1]<0 or room[2]<1 or room[3]<1 or room[0]+room[2]>26 or room[1]+room[3]>16: return false
		if d.mode=="battle" and d.get("combat_room",-1)>=d.world.rooms.size(): return false
	for key in ["seed","biome","cells","loot","start","stairs"]:
		if not d.world.has(key): return false
	if not (d.world.seed is int or d.world.seed is float): return false
	if not (d.world.biome is float or d.world.biome is int) or d.world.biome<0 or d.world.biome>4: return false
	for key in ["cells","loot","explored"]:
		if key=="explored" and not d.world.has(key): continue
		if not d.world[key] is Array: return false
		for p in d.world[key]:
			if not p is Array or p.size()!=2: return false
			for v in p:
				if not (v is int or v is float): return false
			if p[0]<0 or p[0]>=Dungeon.WIDTH or p[1]<0 or p[1]>=Dungeon.HEIGHT: return false
	for key in ["start","stairs"]:
		if not d.world[key] is Array or d.world[key].size()!=2: return false
		for v in d.world[key]:
			if not (v is int or v is float): return false
	return true

func restore(d: Dictionary) -> bool:
	if not valid_save(d): return false
	party.clear(); home.clear(); enemies.clear(); pending.clear(); escorts.clear()
	debt=int(d.get("debt",ContractRules.DEBT)); contracts=d.get("contracts",{}).duplicate(true)
	save_blocked=false
	expedition_plan=d.get("expedition_plan",""); expedition_risk=d.get("expedition_risk",false)
	combat_room=int(d.get("combat_room",-1))
	origin_profile=d.get("origin_profile","负债继承人")
	quiz_answers=d.get("quiz_answers",[]).map(func(a): return int(a))
	for u in d.party: party.append(UnitData.deserialize(u))
	for u in d.home: home.append(UnitData.deserialize(u))
	for u in d.enemies: enemies.append(UnitData.deserialize(u))
	for u in d.pending:
		var existing = by_id(u.uid)
		pending.append(existing if existing != null else UnitData.deserialize(u))
	for u in d.get("escorts",[]): escorts.append(UnitData.deserialize(u))
	world = Dungeon.deserialize(d.world)
	mode = d.mode
	selected = int(d.selected)
	gold = int(d.gold)
	capacity = int(d.capacity)
	potions = int(d.potions)
	stored_potions = int(d.stored_potions)
	stored_gold = int(d.stored_gold)
	floor_number = int(d.floor)
	cleared = d.cleared.map(func(i): return int(i))
	combat_ids = d.combat_ids
	clock = int(d.clock)
	active_id = d.active_id
	serial = int(d.serial)
	rng.state = int(d.rng)
	log_lines.assign(d.get("log",[]))
	changed.emit()
	return true

func save_game(path: String = SAVE_PATH) -> bool:
	if save_blocked: return false
	var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: last_error = "无法写入存档"; return false
	file.store_string(JSON.stringify(serialize()))
	file.close()
	if FileAccess.file_exists(path):
		var copy_error = DirAccess.copy_absolute(path,path+".bak")
		if copy_error != OK: last_error = "无法备份存档"; return false
	var error = DirAccess.rename_absolute(path+".tmp",path)
	if error != OK: last_error = "无法替换存档"; return false
	return true

func load_game(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path): return false
	var parser = JSON.new()
	var parse_error = parser.parse(FileAccess.get_file_as_string(path))
	if parse_error != OK or not valid_save(parser.data):
		last_error = "存档损坏或版本不兼容，原文件已保留，自动保存已禁用。"
		save_blocked = true
		return false
	return restore(parser.data)

func train(u: UnitData, stat: String) -> bool:
	if mode!="town" or not u in party+home or gold<20 or not stat in GeneTraits.STATS: return false
	if u.add_effort(stat,4)==0: return false
	gold-=20
	u.heal()
	note("%s 完成训练：%s努力值提升，花费 20 金币。" % [u.display_name,GeneTraits.STAT_NAMES[stat]])
	changed.emit()
	return true

func equip_skill(u: UnitData, id: String, take: bool) -> bool:
	if mode=="battle" or not u in party+home: return false
	var success=u.equip(id) if take else u.unequip(id)
	if success: changed.emit()
	return success

func change_profession(u: UnitData, job: int) -> bool:
	if mode!="town" or not u in party+home or job<0 or job>2 or u.profession==job: return false
	u.profession=job; u.equipped_skills.clear(); u.ensure_loadout()
	note("%s 转职为%s。已保留各职业熟练度，当前技能已自动重新配备。"%[u.display_name,MercenaryRules.JOBS[job]])
	changed.emit(); return true

func train_profession(u: UnitData) -> bool:
	if mode!="town" or not u in party+home or gold<30 or MercenaryRules.rank(u)>=5: return false
	gold-=30; u.profession_xp[u.profession]=int(u.profession_xp[u.profession])+30
	note("%s 完成职业训练，熟练度 +30。"%u.display_name); changed.emit(); return true
