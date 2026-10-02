class_name ContractRules
extends RefCounted
const DEBT=3000
const CLIENTS=["商队书记 · 埃尔莎","巡林官 · 马丁","港务使 · 汉斯","矿务官 · 莱娜","档案员 · 约翰"]
const STATES={"accepted":"已接取","travel":"护送中","ready":"待交付","failed":"失败 · 可重接","claimed":"已结清"}

static func board() -> Array:
	var result=[]
	for biome in range(5):
		result.append({"id":"kill_%d"%biome,"kind":"kill","biome":biome,"floor":1,"count":4+biome,"reward":220+biome*100,"title":"清剿悬赏 · "+Dungeon.BIOMES[biome].name,"client":"自由市卫戍厅"})
		result.append({"id":"escort_%d"%biome,"kind":"escort","biome":biome,"floor":2,"count":1,"reward":360+biome*120,"title":"安全通行 · "+Dungeon.BIOMES[biome].name,"client":CLIENTS[biome]})
	return result

static func definition(id: String) -> Dictionary:
	for q in board():
		if q.id==id: return q
	return {}

static func accept(game: GameState, id: String) -> bool:
	var q=definition(id)
	if game.mode!="town" or q.is_empty() or not game.dungeon_unlocked(q.biome): return false
	if game.contracts.has(id) and game.contracts[id].state!="failed": return false
	var active=0
	for key in game.contracts:
		if game.contracts[key].state in ["accepted","travel","ready"]:
			active+=1
			if q.kind=="escort" and definition(key).kind=="escort": return false
	if active>=3: return false
	game.contracts[id]={"state":"accepted","progress":0}
	game.note("接下委托：%s。%s" % [q.title,"委托人将在该区域入口等候，护送至第 2 层楼梯。" if q.kind=="escort" else "在指定区域击败敌人，回镇领取报酬。"])
	game.changed.emit(); return true

static func enter_floor(game: GameState) -> void:
	for id in game.contracts:
		var q=definition(id); var state=game.contracts[id]
		if q.kind!="escort" or q.biome!=game.world.biome: continue
		if state.state=="accepted" and game.floor_number==1:
			var u=game.create_unit(q.biome%7,q.client,"escort")
			u.level=3+q.biome*3; u.profession=1; u.heal()
			game.escorts.append(u); state.state="travel"
		if state.state=="travel":
			for u in game.escorts:
				for p in game.world.reachable(game.world.start,5):
					if game.unit_at(p)==null: u.cell=p; break
			game.note("护送目标：%s；抵达第 2 层楼梯并确保委托人存活。可对其使用治疗或守护。"%q.client)

static func defeated(game: GameState, u: UnitData) -> void:
	if u.faction=="escort":
		fail_escort(game,"委托人倒下"); return
	if u.faction!="enemy": return
	for id in game.contracts:
		var q=definition(id); var state=game.contracts[id]
		if q.kind=="kill" and q.biome==game.world.biome and state.state=="accepted":
			state.progress=mini(q.count,int(state.progress)+1)
			if state.progress==q.count:
				state.state="ready"; game.note("委托达成：%s。返回自由市任务栏领取 %d 金币。"%[q.title,q.reward])

static func follow(game: GameState, destination: Vector2i) -> void:
	for u in game.escorts:
		if not u.alive(): continue
		var route=game.world.path(u.cell,destination,game.occupied(u))
		if not route.is_empty():
			game.movement_path.emit(u.uid,[route[0]]); u.cell=route[0]

static func tick_escorts(game: GameState) -> void:
	# Clients do not occupy the initiative timeline. A hostile turn advances their ailments.
	for u in game.escorts:
		if not u.alive() or u.status.is_empty(): continue
		if u.status in ["burn","poison"]:
			u.hp=maxi(0,u.hp-maxi(1,u.max_hp()/(8 if u.status=="poison" else 12)))
			game.effect.emit(u.cell,BattleRules.STATUS_NAMES[u.status],false)
		u.status_turns-=1
		if u.status_turns<=0: u.status=""
		if not u.alive(): defeated(game,u)

static func stairs(game: GameState) -> void:
	for id in game.contracts:
		var q=definition(id); var state=game.contracts[id]
		if q.kind=="escort" and state.state=="travel" and game.world.biome==q.biome and game.floor_number==q.floor:
			if not game.escorts.any(func(u): return u.alive() and game.distance(u.cell,game.world.stairs)<=6):
				game.note("委托人尚未跟上。请先靠近接应，再使用楼梯。"); continue
			state.state="ready"; state.progress=1; game.escorts.clear()
			game.note("护送完成，委托人已安全抵达。回镇领取 %d 金币。"%q.reward)

static func fail_escort(game: GameState, reason: String) -> void:
	for id in game.contracts:
		if game.contracts[id].state=="travel":
			game.contracts[id].state="failed"
			game.note("护送失败：%s。可在任务栏免费重新接取。"%reason)

static func claim(game: GameState, id: String) -> bool:
	if game.mode!="town" or not game.contracts.has(id) or game.contracts[id].state!="ready": return false
	var q=definition(id)
	game.contracts[id].state="claimed"; game.gold+=q.reward
	for u in game.party: u.gain_xp(25+q.biome*10)
	game.note("委托结清：%s，报酬 %d 金币，小队获得经验与职业熟练度。"%[q.title,q.reward])
	game.changed.emit(); return true

static func repay(game: GameState, amount: int) -> bool:
	if game.mode!="town" or amount<=0 or game.debt<=0: return false
	var paid=mini(amount,mini(game.gold,game.debt))
	if paid<=0: return false
	game.gold-=paid; game.debt-=paid
	game.note("已偿还 %d 金币，剩余债务 %d。"%[paid,game.debt] if game.debt>0 else "旧债清偿！你的家族与佣兵团重获自由。仍可继续远征、招募和培养后裔。")
	game.changed.emit(); return true

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size()>10: return false
	var active=0; var escorted=0
	for id in data:
		if not id is String: return false
		var q=definition(id); var s=data[id]
		if q.is_empty() or not s is Dictionary or not s.has("state") or not s.has("progress"): return false
		if not s.state is String or not STATES.has(s.state): return false
		if not (s.progress is int or s.progress is float) or s.progress!=int(s.progress) or s.progress<0 or s.progress>q.count: return false
		if s.state in ["ready","claimed"] and s.progress!=q.count: return false
		if s.state=="travel" and q.kind!="escort": return false
		if s.state in ["accepted","travel","ready"]:
			active+=1
			if q.kind=="escort": escorted+=1
	if active>3 or escorted>1: return false
	return true
