extends SceneTree

var passed = 0
var failed = 0

func check(condition: bool, description: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		push_error("FAIL: "+description)

func fresh(seed_value: int = 481) -> GameState:
	var g = GameState.new()
	g.new_game(seed_value)
	g.cleared=[0,1,2,3] # Unlocked transaction fixture; campaign gates have dedicated tests.
	# Four-member transaction fixture; the actual new-game default is tested below.
	g.party.append(g.create_unit(1,"小风","party"))
	g.party.append(g.create_unit(2,"糯米","party"))
	g.home.append(g.create_unit(3,"苔豆","home"))
	g.return_town(false)
	return g

func arena() -> GameState:
	var g = fresh()
	g.enter_dungeon(0)
	g.world.cells.clear()
	g.world.rooms.assign([Rect2i(1,1,24,14)])
	for x in range(1,25):
		for y in range(1,15): g.world.cells[Vector2i(x,y)] = true
	for i in range(4):
		g.party[i].cell=Vector2i(4,4+i)
		g.party[i].genes.body_a=[1,1]
		g.party[i].genes.body_b=[1,1]
		g.party[i].genes.ears=[1,1]
		g.party[i].genes.coat=[1,1]
		g.party[i].equipped_skills.assign(["strike","delay","rally","mend"])
	g.enemies.resize(1)
	g.enemies[0].cell=Vector2i(6,4)
	g.start_battle()
	g.active_id=g.party[0].uid
	g.clock=20
	for u in g.party+g.enemies: u.ready_at=50
	return g

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var opening=GameState.new(); opening.new_game(81)
	check(opening.party.size()==2 and opening.home.is_empty(),"new game has exactly two units")
	var rng = RandomNumberGenerator.new()
	rng.seed=12345
	var a = Genome.random_genes(rng)
	var b = Genome.random_genes(rng)
	for i in range(150):
		var c = Genome.inherit_genes(a,b,rng,0.0)
		check(Genome.valid(c.genes),"inherited genome validates")
		for locus in Genome.LIMITS:
			check(c.genes[locus][0] in a[locus] and c.genes[locus][1] in b[locus],"one allele from each parent")
	var mutated = Genome.inherit_genes(a,b,rng,1.0)
	check(mutated.mutations.size()==Genome.LIMITS.size()*2,"forced mutation affects all shared alleles")
	a.body_a=[1,1]; a.body_b=[1,1]
	check(Genome.body_name(a)=="大型","aa bb large")
	a.body_a=[0,1]; a.body_b=[0,1]
	check(Genome.body_name(a)=="小型","Aa Bb small")
	for style in range(5):
		for seed_value in range(100):
			var d = Dungeon.new()
			d.generate(seed_value,style)
			check(d.reachable(d.start,2000).size()==d.cells.size(),"all floor cells connected")
			check(not d.path(d.start,d.stairs).is_empty(),"stairs accessible")
			check(d.cells.keys().all(func(p): return p.x>0 and p.x<25 and p.y>0 and p.y<15),"map stays inside boundary")
			var same = Dungeon.new()
			same.generate(seed_value,style)
			check(d.cells==same.cells,"seed reproducibility")
	var g = fresh()
	check(g.party.size()==4 and g.home.size()==1 and g.capacity==6,"four-unit transaction fixture")
	var newborn = g.breed(g.party[0],g.party[1])
	check(newborn!=null and g.home.size()==2 and g.gold==120,"breeding consumes resources and occupies home")
	check(newborn.parents==[g.party[0].uid,g.party[1].uid],"parentage preserved")
	check(g.breed(g.party[0],g.party[1])==null,"full home rejects birth")
	check(g.expand_home() and g.capacity==10 and g.gold==0,"expansion cost and capacity")
	g.gold=300
	check(g.breed(g.party[0],newborn)==null,"parent-child breeding prevented")
	check(g.breed(g.party[0],g.party[2])!=null,"different human races can inherit lineage")
	check(not g.send_home(g.party[0]),"hero cannot leave party")
	check(g.send_home(g.party[3]) and g.party.size()==3,"bench ally")
	check(g.add_to_party(g.home[0]) and g.party.size()==4,"replace ally")
	check(not g.add_to_party(g.home[0]),"party maximum enforced")
	g = fresh()
	g.enter_dungeon(1)
	var recruit = g.enemies[0]
	recruit.hp=0
	g.pending.append(recruit)
	check(g.recruit(recruit),"recruit defeated monster")
	check(g.party.size()==4 and g.home.has(recruit) and recruit.faction=="home","last joining monster goes home")
	check(recruit.genes==g.home[-1].genes,"recruit preserves genome")
	var second = g.enemies[0]
	second.hp=0
	g.pending.append(second)
	check(not g.recruit(second) and second in g.pending,"full house retains invitation")
	g.retreat()
	check(second in g.pending and g.expand_home() and g.recruit(second),"pending survives return and capacity expansion")
	g = arena()
	var actor = g.current()
	var foe = g.enemies[0]
	check(not g.cast("strike",foe),"melee rejects out of range")
	var before = foe.ready_at
	check(g.cast("delay",foe) and foe.ready_at==before+35 and actor.ap==65,"delay skill affects timeline and AP")
	var ally = g.party[1]
	before = ally.ready_at
	check(g.cast("rally",ally) and ally.ready_at==maxi(g.clock+1,before-30),"haste moves ally forward and clamps at current time")
	check(not g.cast("rally",actor),"cannot haste self")
	actor.ap=0
	before=foe.hp
	check(not g.cast("delay",foe) and foe.hp==before,"no skill with insufficient AP")
	g = arena()
	actor=g.current()
	actor.spent=50
	g.end_turn()
	var fast=actor.ready_at
	g = arena()
	actor=g.current()
	actor.spent=51
	g.end_turn()
	check(actor.ready_at-fast==70,"burst threshold adds 70 timeline ticks")
	g = arena()
	actor=g.current()
	var origin=actor.cell
	check(g.move_to(origin+Vector2i.LEFT) and actor.ap==92,"movement spends path length times 8")
	check(not g.move_to(g.party[1].cell),"occupied cell cannot be entered")
	g.world.cells.erase(Vector2i(5,4))
	check(not g.world.sight(Vector2i(4,4),Vector2i(6,4)),"walls block line of sight")
	g = fresh()
	g.enter_dungeon(0)
	var start=g.current().cell
	check(g.mode=="explore","dungeon starts out of battle")
	g.enemies[0].cell=start+Vector2i.RIGHT
	g.check_aggro()
	check(g.mode=="battle","range triggers battle")
	g = arena()
	foe=g.enemies[0]
	g.party[0].cell=foe.cell+Vector2i.LEFT
	foe.hp=1
	check(g.cast("strike",foe) and g.mode=="explore" and foe.recruit_rolled,"last kill ends combat and rolls recruitment once")
	g = arena()
	g.stored_gold=200
	for u in g.party: u.hp=0
	g.advance()
	check(g.mode=="town" and g.gold==144 and g.stored_gold==200,"defeat penalty affects only carried gold")
	check(g.party.all(func(u): return u.hp==u.max_hp()),"all party restored after defeat")
	g = arena()
	g.retreat()
	check(g.mode=="town" and g.gold==162,"emergency retreat costs 10 percent")
	g = fresh()
	check(g.transfer("gold",true) and g.gold==130 and g.stored_gold==50,"deposit gold")
	check(g.transfer("gold",false) and g.gold==180,"withdraw gold")
	check(g.transfer("potion",true) and g.potions==4 and g.stored_potions==1,"deposit potion")
	check(g.buy_potion() and g.gold==160 and g.potions==5,"shop transaction")
	g.party[0].hp=1
	check(g.use_potion(g.party[0]) and g.party[0].hp==41,"potion restores hp")
	g = fresh()
	g.enter_dungeon(4)
	for i in range(3):
		g.current().cell=g.world.stairs
		for enemy in g.enemies:
			if enemy.elite: enemy.hp=0
		check(g.descend(),"floor transition")
	check(g.mode=="town" and 4 in g.cleared and g.gold==300,"three floors award completion")
	# Mid-battle roundtrip, RNG state, invite identity, atomic replacement and malformed files.
	g = arena()
	g.cast("delay",g.enemies[0])
	var data=g.serialize()
	var copy = fresh()
	check(copy.restore(JSON.parse_string(JSON.stringify(data))),"JSON roundtrip accepts valid save")
	check(copy.mode==g.mode and copy.active_id==g.active_id and copy.current().ap==g.current().ap,"battle state preserved")
	check(copy.rng.randi()==g.rng.randi(),"RNG sequence restored")
	check(copy.world.cells==g.world.cells,"map restored")
	var file_path="res://diagnostics/rules_test_save.json"
	check(g.save_game(file_path),"write test save")
	g.gold+=10
	check(g.save_game(file_path) and FileAccess.file_exists(file_path+".bak"),"replace save with backup")
	var loaded=fresh()
	check(loaded.load_game(file_path) and loaded.gold==g.gold,"load written save")
	var bad=data.duplicate(true)
	bad.party[0].genes.erase("color")
	check(not g.valid_save(bad),"invalid genome rejected")
	bad=data.duplicate(true)
	bad.party[0].cell="bad"
	check(not g.valid_save(bad),"malformed unit cell rejected")
	bad=data.duplicate(true)
	bad.version=999
	check(not g.valid_save(bad),"future schema rejected")
	bad=data.duplicate(true)
	bad.world.cells=[[999,999]]
	check(not g.valid_save(bad),"invalid tile rejected")
	var f=FileAccess.open("res://diagnostics/corrupt_test.json",FileAccess.WRITE)
	f.store_string("{broken"); f.close()
	check(not loaded.load_game("res://diagnostics/corrupt_test.json") and loaded.save_blocked,"corrupt save preserved and autosave blocked")
	# Autonomous real-rule skirmish: validates repeated scheduling / enemy AI / eventual victory.
	g = arena()
	var turns=0
	while g.mode=="battle" and turns<80:
		turns+=1
		if g.current().faction=="enemy": g.enemy_turn(); continue
		actor=g.current()
		foe=g.enemies[0]
		while g.mode=="battle" and actor.ap>=35 and foe.alive() and g.distance(actor.cell,foe.cell)<=3:
			if not g.cast("delay",foe): break
		if g.mode=="battle": g.end_turn()
	check(g.mode=="explore" and g.enemies[0].recruit_rolled,"combat simulation resolves and rolls recruitment")
	print("RULE_TESTS: ",passed," passed; ",failed," failed. 500 procedural maps and 150 inheritance trials.")
	quit(1 if failed>0 else 0)
