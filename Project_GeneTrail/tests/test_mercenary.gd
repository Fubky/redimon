extends SceneTree
var passed=0
var failed=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: passed+=1
	else: failed+=1; push_error("MERCENARY FAIL: "+label)
func fresh() -> GameState:
	var g=GameState.new(); g.new_game(32019); return g
func json_copy(g: GameState) -> GameState:
	var copy=GameState.new()
	check(copy.restore(JSON.parse_string(JSON.stringify(g.serialize()))),"state roundtrip "+g.mode)
	return copy
func run() -> void:
	check(Genome.SPECIES.size()==7 and MercenaryRules.JOBS.size()==3,"seven races and three professions")
	for race in range(7):
		for job in range(3):
			var arena=fresh(); arena.enter_dungeon(0)
			arena.world.rooms.assign([Rect2i(1,1,24,14)]); arena.world.cells.clear()
			for x in range(1,25):
				for y in range(1,15): arena.world.cells[Vector2i(x,y)]=true
			arena.enemies.resize(2)
			arena.party[0].cell=Vector2i(5,5); arena.party[1].cell=Vector2i(5,6)
			arena.enemies[0].cell=Vector2i(6,5); arena.enemies[1].cell=Vector2i(7,5)
			arena.start_battle(0); arena.active_id=arena.party[0].uid
			var actor=arena.current(); actor.bloodline=Bloodline.pure(race); Genome.seed_traits(actor.genes,actor.bloodline); actor.profession=job; actor.level=10; actor.profession_xp=[1000,1000,1000]
			for id in [BattleRules.SIGNATURES[race],MercenaryRules.RACE_ADV[race]]+MercenaryRules.JOB_SKILLS[job]:
				var rule=GameState.SKILLS[id]
				var target=arena.enemies[0] if rule.target=="enemy" else (actor if rule.target=="self" else arena.party[1])
				if target!=actor: Genome.seed_traits(target.genes,Bloodline.pure(3))
				target.genes.affinity=[60,60]; target.genes.gloss=[0,0]; target.genes.coat=[0,0]; target.genes.pattern=[2,2]
				target.hp=1 if rule.has("heal") else 500; target.ready_at=100; target.guard=false
				actor.equipped_skills.assign([id]); actor.cooldowns.clear(); actor.ap=100; actor.spent=0
				var before=target.hp
				check(arena.cast(id,target) and actor.ap==100-rule.cost,"new race / career skill executes: "+id)
				if rule.has("power"): check(target.hp<before,"new skill deals damage: "+id)
				if rule.has("heal"): check(target.hp>before,"new skill heals: "+id)
				if rule.has("shift"): check(target.ready_at==100+rule.shift,"new skill changes timeline: "+id)
				if rule.has("guard"): check(target.guard,"new skill protects target: "+id)
	for race in range(7):
		for job in range(3):
			var u=MercenaryRules.sample(race,job,2)
			check(Genome.valid(u.genes) and u.carried_skills().size()==4,"valid starting genome and four skills")
			check(BattleRules.SIGNATURES[race] in u.skill_pool() and MercenaryRules.JOB_SKILLS[job][0] in u.skill_pool(),"race and profession contribute learned skills")
			check(not MercenaryRules.JOB_SKILLS[job][2] in u.skill_pool(),"advanced profession skill is initially locked")
			u.gain_xp(1000); u.level=10
			check(MercenaryRules.JOB_SKILLS[job][2] in u.skill_pool() and MercenaryRules.RACE_ADV[race] in u.skill_pool(),"experience unlocks profession and race skills")
			check(MercenaryRules.rank(u)==5 and u.carried_skills().size()==4,"rank cap and loadout cap")
			var d=u.serialize(); var restored=UnitData.deserialize(JSON.parse_string(JSON.stringify(d)))
			check(restored.profession==job and restored.profession_xp==u.profession_xp and restored.bloodline==u.bloodline,"identity and training persist")
	var g=fresh(); var hero=g.party[0]; var alleles=hero.genes.duplicate(true)
	hero.gain_xp(200); var original_xp=hero.profession_xp[0]
	check(g.change_profession(hero,1) and hero.genes==alleles and hero.profession_xp[0]==original_xp,"transfer preserves inherited traits and previous profession progress")
	check(not "knight_cut" in hero.carried_skills() and "mage_bolt" in hero.carried_skills(),"transfer replaces incompatible skill loadout")
	var gold=g.gold
	check(g.train_profession(hero) and g.gold==gold-30 and hero.profession_xp[1]==30,"paid profession training earns real proficiency")
	var low=alleles.duplicate(true); var high=alleles.duplicate(true)
	for locus in ["bone","muscle","affinity","gloss","agility","length"]: low[locus]=[0,0]; high[locus]=[100,100]
	for job in range(3): check(MercenaryRules.threshold(high,job,1)<MercenaryRules.threshold(low,job,1),"genetic aptitude changes training requirement")
	g.party[1].bloodline=Bloodline.pure(6); Genome.seed_traits(g.party[1].genes,g.party[1].bloodline); g.gold=1000
	var child=g.breed(hero,g.party[1])
	check(child!=null and child.bloodline==[5000,0,0,0,0,0,5000] and child.profession_xp==[0,0,0],"cross-race descendant inherits hidden lineage but not career")
	check(child.parents==[hero.uid,g.party[1].uid] and child.total_effort()==0,"heredity retains family and excludes learned effort")
	check(g.breed(hero,child)==null,"parent-child pairing rejected")
	g=json_copy(g)
	check(g.home[0].bloodline==[5000,0,0,0,0,0,5000] and g.party[0].profession==1,"family and profession survive full save")
	var legacy=g.serialize(); legacy.version=3
	legacy.erase("contracts"); legacy.erase("escorts"); legacy.erase("debt")
	for u in legacy.party+legacy.home: u.species=0; u.erase("bloodline"); u.erase("ancestry"); u.erase("profession"); u.erase("profession_xp"); u.equipped=["strike"]
	var old=GameState.new()
	check(old.restore(legacy) and old.gold==g.gold and old.home.size()==1 and old.debt==3000,"v3 migration preserves roster and resources while adding campaign")
	g=fresh()
	check(not ContractRules.accept(g,"kill_1"),"locked region contracts cannot be accepted")
	check(ContractRules.accept(g,"kill_0") and not ContractRules.accept(g,"kill_0"),"accept and reject duplicate commission")
	check(ContractRules.accept(g,"escort_0"),"can also accept escort")
	g.enter_dungeon(0)
	check(g.escorts.size()==1 and g.party.size()==2 and g.contracts.escort_0.state=="travel","escort spawns separately from four-unit roster")
	check(not g.change_profession(g.party[0],2) and not ContractRules.repay(g,100),"career and lender require town")
	for i in range(4):
		var target=g.enemies[i]; target.hp=0; g.defeated(target,g.party[0]); g.defeated(target,g.party[0])
	check(g.contracts.kill_0.progress==4 and g.contracts.kill_0.state=="ready","real defeats advance once and complete kill target")
	g=json_copy(g)
	check(g.escorts.size()==1 and g.contracts.kill_0.state=="ready","escort and commission progress persist in dungeon")
	g.current().cell=g.world.stairs; g.pending.clear(); g.descend()
	check(g.floor_number==2 and g.escorts.size()==1,"escort follows floor transitions")
	g.current().cell=g.world.stairs
	g.escorts[0].cell=g.world.start
	check(not g.descend() and g.floor_number==2,"cannot abandon a distant client through target stairs")
	for p in g.world.reachable(g.world.stairs,3):
		if g.unit_at(p)==null: g.escorts[0].cell=p; break
	check(g.descend() and g.contracts.escort_0.state=="ready" and g.escorts.is_empty(),"living nearby escort is delivered at floor two stairs")
	g.retreat(); gold=g.gold
	check(ContractRules.claim(g,"kill_0") and ContractRules.claim(g,"escort_0") and g.gold==gold+580,"town pays exact kill and escort rewards")
	check(not ContractRules.claim(g,"kill_0") and not ContractRules.accept(g,"kill_0"),"completed contract cannot duplicate rewards")
	g.gold=3100
	check(ContractRules.repay(g,100) and g.debt==2900 and g.gold==3000,"partial repayment")
	check(ContractRules.repay(g,9999) and g.debt==0 and g.gold==100,"final repayment clamps to debt")
	check(not ContractRules.repay(g,100),"cleared debt cannot be repaid again")
	check(json_copy(g).debt==0,"main story completion persists")
	g=fresh(); ContractRules.accept(g,"escort_0"); g.enter_dungeon(0)
	var escort=g.escorts[0]; var foe=g.enemies[0]; var room=g.world.room_at(foe.cell)
	var positions=g.world.reachable(foe.cell,3).keys().filter(func(p): return g.world.room_at(p)==room and g.unit_at(p)==null)
	g.party[0].cell=positions[0]; g.party[1].cell=positions[1]
	g.start_battle(room)
	check(g.world.room_at(escort.cell)==room and not escort.uid in g.combat_ids,"escort gathers in room but does not take player turns")
	g.active_id=g.party[0].uid; hero=g.current(); hero.level=10; hero.genes.coat=[1,1]; hero.equipped_skills.assign(["mend"])
	escort.cell=hero.cell+Vector2i.DOWN; escort.hp=1; hero.ap=100
	check(g.cast("mend",escort) and escort.hp>1,"player can heal a vulnerable escort")
	g.active_id=foe.uid; foe.profession=2; foe.equipped_skills.assign(["ranger_shot"]); foe.cooldowns.clear(); foe.ap=100
	foe.cell=hero.cell; escort.hp=1; Genome.seed_traits(escort.genes,Bloodline.pure(0)); escort.genes.affinity=[0,0]; escort.genes.gloss=[0,0]; escort.genes.pattern=[1,1]; escort.genes.coat=[0,0]
	check(g.can_cast("ranger_shot",escort) and g.cast("ranger_shot",escort),"enemy attacks escort through real combat rules")
	check(g.contracts.escort_0.state=="failed" and not escort.alive(),"client death fails contract")
	g.retreat()
	check(ContractRules.accept(g,"escort_0"),"failed escort can be retried")
	g.enter_dungeon(0); g.retreat()
	check(g.contracts.escort_0.state=="failed" and g.escorts.is_empty(),"early retreat fails active escort and removes NPC")
	var data=g.serialize(); data.party[0].profession=9
	check(not g.valid_save(data),"invalid profession rejected")
	data=g.serialize(); data.party[0].profession_xp=[-1,0,0]
	check(not g.valid_save(data),"negative profession XP rejected")
	data=g.serialize(); data.debt=-1
	check(not g.valid_save(data),"negative debt rejected")
	data=g.serialize(); data.contracts={"unknown":{"state":"ready","progress":1}}
	check(not g.valid_save(data),"unknown contract rejected")
	print("MERCENARY_TESTS: ",passed," passed; ",failed," failed.")
	quit(1 if failed else 0)
