extends SceneTree
var passed=0
var failed=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: passed+=1
	else: failed+=1; push_error("TACTICS FAIL: "+label)
func fresh() -> GameState:
	var g=GameState.new(); g.new_game(123019); return g
func arena(plan: String) -> GameState:
	var g=fresh(); g.enter_dungeon(0,plan)
	g.world.rooms.assign([Rect2i(1,1,24,14)]); g.world.cells.clear()
	for x in range(1,25):
		for y in range(1,15): g.world.cells[Vector2i(x,y)]=true
	g.party[0].cell=Vector2i(4,4); g.party[1].cell=Vector2i(5,5)
	g.enemies.resize(2); g.enemies[0].cell=Vector2i(5,4); g.enemies[1].cell=Vector2i(6,4)
	for u in g.party:
		Genome.seed_traits(u.genes,Bloodline.pure(0)); u.genes.gloss=[0,0]
		u.equipped_skills.assign(["strike","guard","cleanse","befriend"])
	for u in g.enemies:
		Genome.seed_traits(u.genes,Bloodline.pure(3)); u.genes.gloss=[0,0]; u.genes.pattern=[2,2]; u.genes.coat=[0,0]; u.genes.affinity=[60,60]
		u.hp=1000
	g.start_battle(0); g.active_id=g.party[0].uid
	for u in g.enemies: u.ready_at=100
	return g
func no_critical(g: GameState) -> void:
	for attempt in range(50):
		var state=g.rng.state; g.rng.randf()
		if g.rng.randf()>=0.0625: g.rng.state=state; return
func run() -> void:
	var g=arena("relay"); var a=g.party[0]; var b=g.party[1]; var target=g.enemies[0]
	check(g.cast("strike",target) and target.combo_from==a.uid,"first teammate establishes opening")
	check(g.predict("strike",target).tactic.is_empty(),"same teammate cannot self-chain")
	g.active_id=b.uid
	var preview=g.predict("strike",target); var hp=target.hp; var ready=target.ready_at
	check(preview.tactic=="协同追击" and preview.bonus_shift==15,"other teammate gets visible combo forecast")
	var copy=fresh(); check(copy.restore(JSON.parse_string(JSON.stringify(g.serialize()))),"active combo save validates")
	check(copy.enemies[0].combo_from==a.uid and copy.expedition_plan=="relay","save/load preserves opening and selected plan")
	no_critical(g)
	check(g.cast("strike",target) and hp-target.hp==preview.damage and target.ready_at==ready+15,"combo actual damage and timeline exactly match forecast")
	check(target.combo_used and target.combo_from.is_empty() and g.predict("strike",target).tactic.is_empty(),"combo is consumed once per enemy action interval")
	g.begin_action(target)
	check(not target.combo_used and target.combo_from.is_empty(),"enemy action clears chain window")
	g.active_id=a.uid; a.ap=100; a.cooldowns.clear()
	Genome.seed_traits(target.genes,Bloodline.pure(5))
	check(g.cast("strike",target) and target.combo_from.is_empty(),"elemental immunity never establishes a false combo")
	Genome.seed_traits(target.genes,Bloodline.pure(3)); a.ap=100; a.cooldowns.clear()
	var accuracy=GameState.SKILLS.strike.accuracy; GameState.SKILLS.strike.accuracy=0
	check(g.cast("strike",target) and target.combo_from.is_empty(),"miss never establishes opening")
	GameState.SKILLS.strike.accuracy=accuracy
	a.ap=100; a.cooldowns.clear()
	check(g.cast("befriend",target) and target.combo_from.is_empty(),"non-damaging skills never establish opening")
	a.ap=100; a.cooldowns.clear(); g.cast("strike",target)
	g.retreat()
	check(g.expedition_plan.is_empty() and g.valid_save(g.serialize()),"retreat ends the plan without corrupting invitations or saves")
	g=arena("relay"); a=g.party[0]; target=g.enemies[0]
	target.hp=1; g.enemies[1].hp=0
	check(g.cast("strike",target) and g.mode=="explore" and target.combo_from.is_empty() and g.valid_save(g.serialize()),"room victory clears dead target openings before saving")
	g=arena("burst"); a=g.party[0]; target=g.enemies[0]
	a.spent=20; a.ap=80
	check(g.predict("strike",target).tactic.is_empty(),"exactly 50 AP is not overuse")
	a.spent=21; a.ap=79; preview=g.predict("strike",target); hp=target.hp; ready=target.ready_at
	check(preview.tactic=="破阵强攻" and preview.bonus_shift==20,"crossing threshold forecasts burst")
	no_critical(g)
	check(g.cast("strike",target) and hp-target.hp==preview.damage and target.ready_at==ready+20,"burst actual damage and timeline match preview")
	check(a.burst_used and g.predict("strike",target).tactic.is_empty(),"burst cannot repeat on subsequent attacks this turn")
	check(copy.restore(JSON.parse_string(JSON.stringify(g.serialize()))) and copy.party[0].burst_used,"reload cannot restore an already consumed burst")
	g.begin_action(a); check(not a.burst_used,"next action restores one burst opportunity")
	var rule=GameState.SKILLS.strike
	check(ExpeditionRules.bonus("burst",target,a,rule,100).tag.is_empty(),"enemy cannot receive player doctrine bonus")
	g=arena("tempo"); a=g.party[0]
	a.spent=0; var baseline=g.return_delay(a)
	a.spent=30
	check(g.return_delay(a)==maxi(12,baseline-12),"low AP action returns sooner")
	a.spent=51
	check(g.return_delay(a)==baseline+70,"overuse still pays original delay and loses tempo boost")
	a.spent=0; a.hp=10; g.party[1].hp=10; target=g.enemies[0]; target.hp=1; g.enemies[1].hp=0
	check(g.cast("strike",target) and g.mode=="explore" and a.hp==10+maxi(1,roundi(a.max_hp()*0.1)),"actual room victory applies tempo recovery")
	g=fresh(); var normal=fresh()
	check(not g.enter_dungeon(0,"invented") and g.mode=="town","invalid tactic cannot begin expedition")
	check(g.enter_dungeon(0,"relay",true) and normal.enter_dungeon(0),"risk is optional and basic API remains compatible")
	for i in range(g.enemies.size()): check(g.enemies[i].level==normal.enemies[i].level+2,"high-risk enemies are genuinely stronger")
	target=g.enemies[0]; target.hp=0; var gold=g.gold
	g.defeated(target,g.party[0]); check(g.gold==gold+27,"high-risk kill pays 1.5 times normal reward")
	g.defeated(target,g.party[0]); check(g.gold==gold+27,"risk reward cannot be claimed twice")
	check(copy.restore(JSON.parse_string(JSON.stringify(g.serialize()))) and copy.expedition_risk,"plan and risk persist through save/load")
	g.pending.clear()
	for floor_index in range(2):
		g.current().cell=g.world.stairs
		check(g.descend() and g.expedition_plan=="relay" and g.expedition_risk,"strategy and risk persist to next floor")
	for enemy in g.enemies: enemy.hp=0
	gold=g.gold; g.current().cell=g.world.stairs
	check(g.descend() and g.gold==gold+240 and g.mode=="town","high-risk full clear pays exact completion bonus")
	check(g.expedition_plan.is_empty() and not g.expedition_risk,"completion clears temporary strategy")
	var data=g.serialize(); data.erase("expedition_plan"); data.erase("expedition_risk")
	for unit in data.party:
		unit.erase("combo_from"); unit.erase("combo_used"); unit.erase("burst_used")
	check(copy.restore(data) and copy.expedition_plan.is_empty(),"existing v5 saves without tactics still load")
	data=g.serialize(); data.expedition_plan="invalid"; check(not g.valid_save(data),"unknown saved plan rejected")
	data=g.serialize(); data.expedition_risk="true"; check(not g.valid_save(data),"invalid risk value rejected")
	data=g.serialize(); data.party[0].combo_from="missing"; check(not g.valid_save(data),"invalid combo source rejected")
	data=g.serialize(); data.party[0].burst_used=1; check(not g.valid_save(data),"invalid consumed-burst flag rejected")
	print("TACTICS_TESTS: ",passed," passed; ",failed," failed.")
	quit(1 if failed else 0)
