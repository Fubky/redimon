extends SceneTree
var passed=0
var failed=0
func check(value: bool, description: String) -> void:
	if value: passed+=1
	else: failed+=1; push_error("FAIL: "+description)
func _initialize() -> void: call_deferred("run")

func arena() -> GameState:
	var g=GameState.new(); g.new_game(881)
	g.enter_dungeon(0)
	g.world.cells.clear(); g.world.rooms.assign([Rect2i(1,1,8,12),Rect2i(9,1,15,12)])
	for x in range(1,25):
		for y in range(1,15): g.world.cells[Vector2i(x,y)]=true
	g.party[0].cell=Vector2i(6,4); g.party[1].cell=Vector2i(6,5)
	g.enemies.resize(3)
	g.enemies[0].cell=Vector2i(7,4); g.enemies[1].cell=Vector2i(8,5); g.enemies[2].cell=Vector2i(9,4)
	g.start_battle(0); g.active_id=g.party[0].uid; g.clock=20
	for u in g.party+g.enemies: u.ready_at=60
	return g

func run() -> void:
	var result={"genes":MercenaryRules.sample(0,0,0).genes}
	var g=arena(); var u=g.current()
	u.genes=result.genes.duplicate(true)
	var entries=GeneSkills.catalog(u.genes)
	check(entries.size()==54,"four shared tactics and two unlocks for all 25 shared genes")
	for locus in Genome.LIMITS:
		check(entries.filter(func(e): return e.locus==locus).size()==2,"every locus owns a skill pool: "+locus)
	u.equipped_skills.clear()
	check(u.skill_pool().size()==10 and u.carried_skills().size()==4,"level one learns gene, species and common tactics but carries four")
	var learned=u.skill_pool()
	var locked=entries.filter(func(e): return e.level>1)[0]
	check(not u.equip(locked.id),"cannot equip level-locked skill")
	for id in learned:
		if not id in u.carried_skills(): check(not u.equip(id),"cannot carry a fifth skill")
	u.gain_xp(25)
	check(u.level==2 and u.skill_pool().size()>learned.size(),"level-up automatically unlocks new gene skills")
	u.level=10
	check(u.skill_pool().size()==43,"all phenotype skills available at level ten")
	var covered={}
	for high in [false,true]:
		g=arena(); u=g.current(); u.level=10
		for locus in Genome.LIMITS: u.genes[locus]=[Genome.LIMITS[locus] if high else 0,Genome.LIMITS[locus] if high else 0]
		for entry in GeneSkills.catalog(u.genes):
			if not GeneSkills.expressed(u.genes,entry): continue
			var id: String=entry.id
			covered[id]=true
			u.equipped_skills.assign([id]); u.ap=100; u.spent=0; u.cooldowns.clear(); u.status=""
			var rule=GeneSkills.RULES[id]
			var target=g.enemies[0] if rule.target=="enemy" else (u if rule.target=="self" else g.party[1])
			target.hp=1 if rule.has("heal") else 500
			target.ready_at=80
			if rule.target=="enemy":
				Genome.seed_traits(target.genes,Bloodline.pure(3)); target.genes.affinity=[0,0]; target.genes.gloss=[0,0]; target.genes.pattern=[0,0]; target.genes.coat=[1,1]
			var original_accuracy=rule.accuracy
			rule.accuracy=100 # Separate accuracy tests cover misses; here exercise each effect deterministically.
			var before=target.hp
			check(g.can_cast(id,target) and g.cast(id,target) and u.ap==100-rule.cost,"actual skill execution and AP: "+id)
			if rule.has("power"): check(target.hp<before,"damage applies: "+id)
			if rule.has("heal"): check(target.hp==mini(target.max_hp(),before+rule.heal),"healing applies: "+id)
			if rule.has("shift"): check(target.ready_at==maxi(g.clock+1,80+rule.shift),"timeline shift applies: "+id)
			rule.accuracy=original_accuracy
			check(not g.cast(id,u if rule.target=="enemy" else g.enemies[0]),"wrong team / self rejected: "+id)
	check(covered.size()>=50,"both expression branches and advanced skills exercised")
	g=arena(); u=g.current()
	u.genes.body_a=[1,1]; u.genes.body_b=[1,1]; u.equipped_skills.assign(["delay"])
	var outsider=g.enemies[2]; var outsider_hp=outsider.hp
	check(g.combat_ids.size()==4 and not outsider.uid in g.combat_ids,"battle includes two allies and only two enemies in this room")
	check(not g.cast("delay",outsider) and outsider.hp==outsider_hp,"nearby other-room enemy cannot join through a ranged skill")
	check(not g.move_to(Vector2i(9,3)),"movement cannot leave combat room")
	var start=u.cell
	check(g.move_to(start+Vector2i.LEFT) and u.moved and u.ap==92,"click movement consumes path AP and one movement action")
	check(not g.move_to(start+Vector2i.LEFT*2),"second movement in the same turn rejected")
	u.cell=Vector2i(6,4); u.ap=100
	for foe in g.enemies.slice(0,2):
		foe.hp=1; u.cooldowns.clear()
		check(g.cast("delay",foe),"defeat member of current room encounter")
	check(g.mode=="explore" and g.combat_ids.is_empty() and outsider.hp==outsider_hp,"room clear immediately exits battle without touching the next room")
	check(g.party[0].total_effort()==4 and g.party[0].level>=2,"combat grants EVs and level progress")
	g.current().cell=Vector2i(10,4); g.check_aggro()
	check(g.mode=="battle" and g.combat_room==1 and outsider.uid in g.combat_ids,"entering next occupied room starts a separate encounter")
	g=GameState.new(); g.new_game(195)
	u=g.party[0]
	var base=u.base_stats(); var before=u.max_hp()
	check(g.train(u,"hp") and u.effort.hp==4 and u.max_hp()==before+1 and g.gold==160,"town training converts payment into actual stat growth")
	check(u.base_stats()==base,"training does not rewrite genetic base stats")
	u.add_effort("attack",999); u.add_effort("defense",999); u.add_effort("speed",999)
	check(u.total_effort()==192 and u.effort.attack==64 and u.effort.defense==64,"per-stat and total EV limits enforced")
	check(u.add_effort("hp",4)==0,"full EV budget rejects extra gain")
	var child=g.breed(g.party[0],g.party[1])
	check(child!=null and child.total_effort()==0 and child.carried_skills().size()==4,"offspring inherits genes and starts with no acquired EVs")
	for locus in Genome.LIMITS:
		var low=u.genes.duplicate(true); var high=low.duplicate(true)
		low[locus]=[0,0]; high[locus]=[Genome.LIMITS[locus],Genome.LIMITS[locus]]
		check(GeneTraits.innate(Bloodline.pure(0),low)!=GeneTraits.innate(Bloodline.pure(0),high),"every gene influences innate stats: "+locus)
	var rng=RandomNumberGenerator.new(); rng.seed=481
	var a=u.genes.duplicate(true); a.body_a=[0,1]; a.body_b=[0,1]; a.ears=[0,2]
	var recessive=false
	for i in range(200):
		var baby=Genome.inherit_genes(a,a,rng,0).genes
		var pool=GeneSkills.pool(baby,10)
		recessive=recessive or "rally" in pool
		check(("delay" in pool)==(Genome.body_name(baby) in ["大型","中大型"]),"inherited body and skill stay coupled")
	check(recessive,"recessive long-ear gene expresses in offspring")
	var copy=GameState.new(); var data=JSON.parse_string(JSON.stringify(g.serialize()))
	check(copy.restore(data) and copy.party[0].effort==u.effort and copy.party[0].carried_skills()==u.carried_skills(),"EV and equipped slots survive JSON roundtrip")
	data.party[0].equipped=["strike","strike"]
	check(not copy.valid_save(data),"duplicate equipped skills rejected")
	data=JSON.parse_string(JSON.stringify(g.serialize())); data.party[0].effort.hp=900
	check(not copy.valid_save(data),"invalid EVs rejected")
	var music=GameAudio.new(); root.add_child(music)
	for context in ["title","town","forest","mountain","island","volcano","cave","battle"]:
		music.play_context(context)
		var stream=music.music[music.active].stream
		check(stream!=null and stream.get_length()>20 and stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_end>0,"playable looping score: "+context)
		await create_timer(0.03).timeout
	for effect in ["ui","step","hit","cast","heal","delay","battle_start","defeat","victory","level_up","save","recruit"]:
		music.sfx(effect)
		check(music.stream("sfx_"+effect).get_length()>0,"sound effect loads: "+effect)
		await create_timer(0.03).timeout
	music._process(2)
	check(not music.music[1-music.active].playing,"crossfade stops outgoing music")
	var motion=UnitMotion.new(); var actor=g.party[0]; var target=g.party[1]
	motion.update(g.party,func(v): return Vector2(v.cell)*40,false,0.01)
	actor.cell+=Vector2i.RIGHT
	motion.update(g.party,func(v): return Vector2(v.cell)*40,false,0.1)
	check(motion.pose(actor).state=="walk","position changes produce locomotion pose")
	motion.enqueue(actor,target,"delay")
	motion.update(g.party,func(v): return Vector2(v.cell)*40,false,0.4)
	check(motion.busy() and motion.pose(actor).state=="cast" and motion.pose(target).state=="hurt","skill queues caster and target animations")
	motion.update(g.party,func(v): return Vector2(v.cell)*40,false,1)
	check(not motion.busy(),"finished animation releases input lock")
	print("GENETIC_SKILL_TESTS: ",passed," passed; ",failed," failed.")
	music.shutdown()
	await create_timer(0.12).timeout
	quit(1 if failed>0 else 0)
