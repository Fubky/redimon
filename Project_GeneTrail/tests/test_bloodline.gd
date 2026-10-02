extends SceneTree
var passed=0
var failed=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: passed+=1
	else: failed+=1; push_error("BLOODLINE FAIL: "+label)
func fresh() -> GameState:
	var g=GameState.new(); g.new_game(88303); return g
func run() -> void:
	var half=Bloodline.inherit(Bloodline.pure(1),Bloodline.pure(6))
	check(half==[0,5000,0,0,0,0,5000],"two pure origins contribute equally")
	var third=Bloodline.inherit(half,Bloodline.pure(3))
	check(third==[0,2500,0,5000,0,0,2500],"grandparent ancestry persists without dominant race")
	var mix=Bloodline.normalize([1,1,1,1,1,1,1]); var rng=RandomNumberGenerator.new(); rng.seed=193
	for generation in range(200):
		var weights=[]
		for i in range(7): weights.append(rng.randi_range(0,10000))
		var parent=Bloodline.normalize(weights); var child=Bloodline.inherit(mix,parent)
		check(Bloodline.valid(child),"100% total survives generation "+str(generation))
		check(child==Bloodline.inherit(parent,mix),"parent order has no dominance")
		for i in range(7): check(absf(child[i]-(mix[i]+parent[i])/2.0)<=1,"rounding is within one basis point")
		mix=child
	check(Bloodline.percent(1250)=="12.50%" and Bloodline.percent(5000)=="50%","fractional lineage is displayed accurately")
	for origin in range(7):
		var u=MercenaryRules.sample(origin); u.level=10
		check(u.genes.size()==25 and Genome.valid(u.genes),"all origins share exactly the same schema")
		for locus in Genome.TRAITS: u.genes[locus]=[100,100]
		for id in BattleRules.SIGNATURES+MercenaryRules.RACE_ADV: check(id in u.skill_pool(),"all trait skills accessible regardless of origin: "+id)
		var before=u.skill_pool(); var art=HumanAssembly.build(u); var types=BattleRules.types(u)
		u.bloodline=Bloodline.pure((origin+3)%7)
		check(u.skill_pool()==before and HumanAssembly.build(u)==art and BattleRules.types(u)==types,"bloodline never gates phenotype or learned skills")
		u.species=6; u.ancestry=[6,6]
		check(u.skill_pool()==before and HumanAssembly.build(u)==art,"obsolete race field has no mechanical authority")
		u.genes.horns=[39,39]; check(not "horn_ram" in u.skill_pool(),"trait below threshold is dormant")
		u.genes.horns=[40,40]; u.level=1
		check("horn_ram" in u.skill_pool() and not "horn_charge" in u.skill_pool(),"expression unlock and level gate both apply")
		u.level=8; check("horn_charge" in u.skill_pool(),"advanced shared trait skill unlocks at level eight")
	var u=MercenaryRules.sample(0); u.bloodline=third
	Genome.seed_traits(u.genes,Bloodline.pure(0))
	for locus in ["plumage","scales","feral","horns"]: u.genes[locus]=[80,80]
	u.genes.white=[0,0]
	var parts=HumanAssembly.build(u).parts.map(func(p): return p.id)
	check(parts.has("bird_wing_0") and parts.has("scales_face") and parts.has("cat_ears") and parts.has("horns_0"),"compatible features coexist on one human")
	check(not parts.has("dragon_wing"),"dormant back gene cannot suppress expressed bird wing")
	u.genes.fins=[90,90]; u.genes.coils=[50,50]
	parts=HumanAssembly.build(u).parts.map(func(p): return p.id)
	check(parts.has("fish_tail") and not parts.has("snake_tail") and not parts.has("knight_leg") and not parts.has("lizard_tail"),"stronger aquatic lower body replaces conflicting anatomy")
	u.genes.coils=[100,100]; parts=HumanAssembly.build(u).parts.map(func(p): return p.id)
	check(parts.has("snake_tail") and not parts.has("fish_tail"),"expression mutation switches anatomical slot and cache")
	var g=fresh(); g.gold=5000; g.capacity=16
	var a=g.party[0]; var b=g.party[1]; a.bloodline=half; b.bloodline=Bloodline.pure(3)
	a.genes.horns=[0,100]; b.genes.horns=[0,100]; a.add_effort("attack",30); a.profession_xp=[100,200,300]
	var baby=g.breed(a,b)
	check(baby!=null and baby.bloodline==third and baby.total_effort()==0 and baby.profession_xp==[0,0,0],"real nursery transmits ancestry and genes but excludes acquired training")
	var latent=false; var expressed=false
	for trial in range(200):
		var genes=Genome.inherit_genes(a.genes,b.genes,rng,0).genes
		check(Genome.valid(genes) and genes.horns[0] in a.genes.horns and genes.horns[1] in b.genes.horns,"shared alleles inherit from each parent")
		latent=latent or Genome.express(genes,"horns")==0
		expressed=expressed or Genome.express(genes,"horns")==100
	check(latent and expressed,"same ancestry can produce different expressed phenotypes")
	var copy=fresh(); var data=g.serialize(); var original=data.duplicate(true)
	check(data.version==5 and not data.party[0].has("species") and not data.party[0].has("ancestry"),"v5 persists full ancestry without fixed race")
	check(copy.restore(JSON.parse_string(JSON.stringify(data))) and copy.home[0].bloodline==third and copy.home[0].genes==baby.genes,"full game roundtrip preserves all percentages and alleles")
	check(data==original,"save validation does not mutate caller data")
	for value in [[0,0,0,0,0,0,0],[10001,0,0,0,0,0,0],[-1,10001,0,0,0,0,0],[5000.5,4999.5,0,0,0,0,0],[10000],"human",[NAN,0,0,0,0,0,0]]:
		data=g.serialize(); data.party[0].bloodline=value; check(not g.valid_save(data),"invalid v5 ancestry rejected")
	data=g.serialize(); data.party[0].erase("bloodline"); check(not g.valid_save(data),"missing v5 ancestry rejected")
	data=g.serialize(); data.party[0].genes.erase("horns"); check(not g.valid_save(data),"missing v5 shared locus rejected")
	for version in [1,2,3,4]:
		data=g.serialize(); data.version=version
		for record in data.party+data.home:
			record.species=1; record.ancestry=[1,6]; record.erase("bloodline"); record.equipped=["strike"]
			for locus in Genome.TRAITS: record.genes.erase(locus)
		original=data.duplicate(true)
		check(copy.restore(JSON.parse_string(JSON.stringify(data))),"legacy save migrates: "+str(version))
		check(copy.party[0].bloodline==half and copy.party[0].genes.plumage==[50,50] and copy.party[0].genes.horns==[50,50],"both old ancestral alleles survive as percentages and common genes")
		check(copy.gold==g.gold and copy.home.size()==g.home.size() and copy.debt==g.debt and data==original,"migration preserves progress and source")
		check(g.valid_save(copy.serialize()),"migrated data resaves as valid v5")
	data.party[0].erase("ancestry"); data.party[0].species=5
	check(copy.restore(data) and copy.party[0].bloodline==Bloodline.pure(5),"old single species becomes 100% source")
	u=MercenaryRules.sample(0); var leader=MercenaryRules.sample(0); leader.genes.affinity=[0,0]
	u.bloodline=[5000,0,0,0,5000,0,0]
	check(is_equal_approx(RecruitmentRules.breakdown(u,leader,[]).base,15.0),"recruitment uses weighted 25% and 5% origins, not dominant origin")
	var base=u.base_stats(); u.bloodline=Bloodline.pure(6)
	check(u.base_stats()!=base,"stat cache invalidates ancestry edits")
	g=fresh(); g.enter_dungeon(0)
	check(g.enemies.all(func(e): return Bloodline.valid(e.bloodline) and e.bloodline.filter(func(v): return v>0).size()>=2 and Genome.valid(e.genes)),"world spawns valid mixed-lineage enemies using common genome")
	print("BLOODLINE_TESTS: ",passed," passed; ",failed," failed.")
	quit(1 if failed else 0)
