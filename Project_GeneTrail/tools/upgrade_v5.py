from pathlib import Path
p=Path('scripts/unit_data.gd');s=p.read_text(encoding='utf-8-sig');s=s.replace('var moved: bool=false','''var moved: bool=false
var status: String=""
var status_turns: int=0
var stages: Dictionary={}
var cooldowns: Dictionary={}
var guard: bool=false
var marked: bool=false
var elite: bool=false
var recruit_rolled: bool=false
var last_recruit_rate: float=0.0

func clear_battle_state(full: bool=false) -> void:
	stages.clear(); cooldowns.clear(); guard=false
	if full: status=""; status_turns=0

func cooldown(id: String) -> int: return int(cooldowns.get(id,0))
''');s=s.replace('func movement() -> int: return clampi(3+speed()/6,4,7)','func movement() -> int: return maxi(2,clampi(3+speed()/6,4,7)-(2 if status=="frost" else 0))');s=s.replace('func skill_pool() -> Array[String]: return GeneSkills.pool(genes,level)','''func skill_pool() -> Array[String]:
	var result=GeneSkills.pool(genes,level)
	result.append(BattleRules.SIGNATURES[species])
	return result''');s=s.replace('for locus in ["body_a","ears","coat","tail"]:', 'for locus in ["body_a","ears","coat"]:');s=s.replace('if id in learned: equipped_skills.append(id)','if id in learned: equipped_skills.append(id)\n\t\tequipped_skills.append(BattleRules.SIGNATURES[species])');s=s.replace('"moved":moved}', '"moved":moved,"status":status,"status_turns":status_turns,"stages":stages.duplicate(),"cooldowns":cooldowns.duplicate(),"guard":guard,"marked":marked,"elite":elite,"recruit_rolled":recruit_rolled,"last_recruit_rate":last_recruit_rate}');s=s.replace('\tu.ensure_loadout()\n\treturn u','''	u.status=d.get("status",""); u.status_turns=int(d.get("status_turns",0))
	u.stages=d.get("stages",{}).duplicate(); u.cooldowns=d.get("cooldowns",{}).duplicate()
	u.guard=d.get("guard",false); u.marked=d.get("marked",false); u.elite=d.get("elite",false)
	u.recruit_rolled=d.get("recruit_rolled",false); u.last_recruit_rate=float(d.get("last_recruit_rate",0))
	u.ensure_loadout()
	return u''');p.write_text(s,encoding='utf-8')
p=Path('scripts/gene_skills.gd');s=p.read_text(encoding='utf-8-sig').replace('\treturn rules','\tBattleRules.enrich(rules)\n\treturn rules',1);s=s.replace('var entries=[{"id":"strike","locus":"instinct","level":1}]','var entries=[{"id":"strike","locus":"instinct","level":1},{"id":"guard","locus":"instinct","level":1},{"id":"cleanse","locus":"instinct","level":1},{"id":"befriend","locus":"instinct","level":1}]');p.write_text(s,encoding='utf-8')
p=Path('scripts/game_state.gd');s=p.read_text(encoding='utf-8-sig');s=s.replace('party[i].heal()','party[i].clear_battle_state(true)\n\t\tparty[i].heal()',1);s=s.replace('for u in home: u.heal()','for u in home: u.clear_battle_state(true); u.heal()');s=s.replace('\tfloor_number = 1\n\tbuild_floor(style)','\tif not dungeon_unlocked(style): note("先完成前一片区域的远征，才能取得通行徽记。"); return false\n\tfloor_number = 1\n\tbuild_floor(style)');s=s.replace('u.level=floor_number+room_index/2','''u.level=1+style*3+floor_number+room_index/3
			u.elite=floor_number==3 and room_index==5 and j==0
			if u.elite:
				u.level+=3
				u.display_name="守望者 · "+u.display_name
				u.genes.body_a=[1,1]; u.genes.body_b=[1,1]
				u.equipped_skills.assign([BattleRules.SIGNATURES[u.species],"guard","delay","mend"])
			u.ensure_loadout()''');s=s.replace('u.ready_at=maxi(0,(20 if u.faction=="party" else 26)-u.speed())','u.clear_battle_state()\n\t\t\tu.ready_at=maxi(0,(20 if u.faction=="party" else 26)-u.speed()-(10 if BattleRules.ability(u)==5 else 0))');s=s.replace('for i in range(party.size()):\n\t\t\tif party[i].alive(): selected = i; break','for unit in party: unit.clear_battle_state()\n\t\tfor i in range(party.size()):\n\t\t\tif party[i].alive(): selected = i; break');s=s.replace('\tu.moved=false\n\tchanged.emit()','''	u.moved=false
	begin_action(u)
	changed.emit()''',1);s=s.replace('return (80 if u.spent+extra_cost<=50 else 150)-u.speed()*2','return maxi(12,(80 if u.spent+extra_cost<=50 else 150)-roundi(BattleRules.stat(u,"speed"))*2)');s=s.replace('if u.ap<rule.cost or distance','if u.cooldown(skill)>0 or u.status=="sleep": return false\n\tif u.ap<rule.cost or distance');start=s.index('func cast(');end=s.index('func recruit(',start)
s=s[:start]+'''func predict(skill: String, target: UnitData) -> Dictionary:
	if not SKILLS.has(skill) or target==null or current()==null: return {}
	var rule=SKILLS[skill]
	return {"damage":BattleRules.damage(current(),target,rule,world.biome),"effect":BattleRules.effectiveness(rule.element,target),"accuracy":rule.accuracy,"rate":RecruitmentRules.breakdown(target,party[0],cleared).chance}

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
		for other in party+enemies:
			if other!=target and other.alive() and other.faction!=u.faction and other.uid in combat_ids and distance(other.cell,target.cell)<=1: targets.append(other)
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
	if u.faction!="enemy": note(u.display_name+"暂时倒下，回镇后可恢复。"); return
	if u.recruit_rolled: return
	u.recruit_rolled=true
	gold+=35 if u.elite else 18
	for ally in party:
		if ally.alive():
			var before=ally.level
			ally.gain_xp(40 if u.elite else 18); ally.add_effort(GeneTraits.STATS[u.species%6],2)
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
		for target in party+enemies:
			if not target.uid in combat_ids or not can_cast(id,target): continue
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
		var targets=party.filter(func(a): return a.alive())
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

''' +s[end:]
s=s.replace('if floor_number == 3:\n\t\tvar style', 'if floor_number == 3:\n\t\tif enemies.any(func(e): return e.elite and e.alive()): note("终点的守望者尚未被击败，通行徽记仍被封印。"); return false\n\t\tvar style');s=s.replace('note("完成%s远征，获得 120 金币！" % Dungeon.BIOMES[style].name)','note("完成%s远征，获得 120 金币！%s" % [Dungeon.BIOMES[style].name,"解锁 "+Dungeon.BIOMES[style+1].name if style<4 else "五域远征全部完成！"])');s=s.replace('"version":2','"version":3');s=s.replace('(d.version!=1 and d.version!=2)','not d.version in [1,2,3]');s=s.replace('var learned=GeneSkills.pool(u.genes,int(u.level))','var learned=GeneSkills.pool(u.genes,int(u.level))\n\t\t\tif int(u.species) in range(5): learned.append(BattleRules.SIGNATURES[int(u.species)])');s=s.replace('cleared = d.cleared','cleared = d.cleared.map(func(i): return int(i))');p.write_text(s,encoding='utf-8')
