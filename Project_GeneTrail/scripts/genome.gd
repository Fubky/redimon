class_name Genome
extends RefCounted
## Versioned diploid genome. Hero, allies, enemies and offspring use the same schema.
const LIMITS = {"body_a":1,"body_b":1,"height":100,"bone":100,"muscle":100,"length":100,"color":5,"pattern":3,"white":100,"contrast":100,"coat":3,"gloss":100,"face":2,"ears":2,"eyes":4,"tail":3,"affinity":100,"agility":100,"poise":100,"plumage":100,"scales":100,"feral":100,"fins":100,"coils":100,"horns":100}
const TRAITS=["poise","plumage","scales","feral","fins","coils","horns"]
const TRAIT_THRESHOLD=40
const COLORS = [Color("e9ab60"),Color("a68b80"),Color("e38270"),Color("80c3cc"),Color("f2ddb2"),Color("b59bdc")]
const SPECIES = ["灵长人","翼人","龙人","兽人","鱼人","蛇人","角人"]

static func random_genes(rng: RandomNumberGenerator) -> Dictionary:
	var genes = {}
	for locus in LIMITS:
		genes[locus] = [rng.randi_range(0, LIMITS[locus]), rng.randi_range(0, LIMITS[locus])]
	return genes

static func express(genes: Dictionary, locus: String) -> int:
	var pair = genes[locus]
	if locus in ["body_a", "body_b"]:
		return int(pair[0]) + int(pair[1])
	if LIMITS[locus] <= 5:
		return mini(int(pair[0]), int(pair[1])) # dominant lower allele
	return roundi((float(pair[0]) + float(pair[1])) * 0.5)

static func body_name(g: Dictionary) -> String:
	var a = express(g, "body_a")
	var b = express(g, "body_b")
	if a == 2 and b == 2: return "大型"
	if (a == 2 and b == 1) or (a == 1 and b == 2): return "中大型"
	if a == 1 and b == 1: return "小型"
	if a == 0 and b == 0: return "紧凑型"
	return "中型"

static func inherit_genes(a: Dictionary, b: Dictionary, rng: RandomNumberGenerator, mutation_rate: float = 0.025) -> Dictionary:
	var result = {}
	var mutations: Array[String] = []
	for locus in LIMITS:
		var pair = [int(a[locus][rng.randi_range(0,1)]), int(b[locus][rng.randi_range(0,1)])]
		for i in range(2):
			if rng.randf() < mutation_rate:
				var old = pair[i]
				pair[i] = (old + rng.randi_range(1, LIMITS[locus])) % (LIMITS[locus] + 1)
				mutations.append(locus)
		result[locus] = pair
	return {"genes":result, "mutations":mutations}

static func seed_traits(genes: Dictionary, bloodline: Array) -> void:
	# Starting frequencies are presets only. Any lineage can carry any allele.
	for i in range(TRAITS.size()):
		var value=roundi(float(bloodline[i])/100.0)
		genes[TRAITS[i]]=[value,value]

static func seed_creator_traits(genes: Dictionary, bloodline: Array) -> void:
	# Creator convenience only; inheritance and migration remain independent.
	for i in range(TRAITS.size()):
		var value=0 if bloodline[i]==0 else TRAIT_THRESHOLD+roundi((100-TRAIT_THRESHOLD)*float(bloodline[i])/Bloodline.TOTAL)
		genes[TRAITS[i]]=[value,value]

static func migrate_traits(genes: Dictionary, bloodline: Array) -> Dictionary:
	var result=genes.duplicate(true); var defaults={}
	seed_traits(defaults,bloodline)
	for locus in TRAITS:
		if not result.has(locus): result[locus]=defaults[locus]
	return result

static func expressed_traits(genes: Dictionary) -> Array:
	var result=[]
	for locus in TRAITS:
		if express(genes,locus)>=TRAIT_THRESHOLD: result.append(locus)
	result.sort_custom(func(a,b): return TRAITS.find(a)<TRAITS.find(b) if express(genes,a)==express(genes,b) else express(genes,a)>express(genes,b))
	return result

static func valid(g: Dictionary, legacy: bool=false) -> bool:
	for locus in LIMITS:
		if legacy and locus in TRAITS and not g.has(locus): continue
		if not g.has(locus) or not g[locus] is Array or g[locus].size() != 2: return false
		for allele in g[locus]:
			if not (allele is float or allele is int) or not is_finite(float(allele)): return false
			if allele < 0 or allele > LIMITS[locus] or float(allele) != floor(float(allele)): return false
	return true
