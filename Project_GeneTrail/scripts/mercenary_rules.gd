class_name MercenaryRules
extends RefCounted
## Shared genes recombine; ancestry averages; a profession is learned, never inherited.
const JOBS=["骑士","魔法师","游侠 / 战士"]
const OUTFITS=["板甲 · 长剑","法袍 · 法杖","皮甲 · 短弓"]
const RACE_DESC=["普通人类；均衡体质与战场号令。","人类躯干与鸟翼；羽型遗传为鹰、鸦或天鹅。","鳞纹皮肤与蜥蜴尾；高背部表达可生龙翼。","人类面孔；遗传猫耳或犬耳、兽尾与爪。","人类上身与鳞片鱼尾，以潮汐术在陆地滑行。","人类上身与盘绕蛇尾，擅长毒与迟滞。","人类面孔；角型分为牛、羊与鹿。"]
const RACE_ADV=["human_order","wing_storm","dragon_roar","beast_hunt","fish_song","serpent_bind","horn_charge"]
const JOB_SKILLS=[["knight_cut","knight_oath","knight_break"],["mage_bolt","mage_mend","mage_clock"],["ranger_shot","ranger_mark","ranger_flurry"]]
const NAMES=["阿德勒","莉泽","奥托","米拉","康拉德","艾达","卢卡斯","弗里达","卡斯帕","格蕾塔"]

static func aptitude(genes: Dictionary, job: int) -> float:
	var score=0.0
	for locus in [["bone","muscle"],["affinity","gloss"],["agility","length"]][job]: score+=Genome.express(genes,locus)/200.0
	return snappedf(1.35-score*0.6,0.01)

static func aptitude_label(genes: Dictionary, job: int) -> String:
	var factor=aptitude(genes,job)
	return "%s · 训练需求 ×%.2f" % ["擅长" if factor<0.95 else ("适中" if factor<=1.15 else "较难"),factor]

static func rank(u: UnitData, job: int=-1) -> int:
	if job<0: job=u.profession
	var xp=int(u.profession_xp[job])
	var result=1
	while result<5 and xp>=threshold(u.genes,job,result):
		xp-=threshold(u.genes,job,result); result+=1
	return result

static func threshold(genes: Dictionary, job: int, current_rank: int) -> int:
	return roundi(60*current_rank*aptitude(genes,job))

static func stat_bonus(u: UnitData, stat: String) -> int:
	var trained=rank(u)-1
	if u.profession==0: return trained if stat=="attack" else (trained/2 if stat=="defense" else 0)
	if u.profession==1: return trained if stat=="magic" else (trained/2 if stat=="resist" else 0)
	return trained/2 if stat in ["attack","speed"] else 0

static func rank_progress(u: UnitData, job: int) -> String:
	var xp=int(u.profession_xp[job]); var r=1
	while r<5 and xp>=threshold(u.genes,job,r): xp-=threshold(u.genes,job,r); r+=1
	return "熟练度已满" if r==5 else "%d / %d 熟练度" % [xp,threshold(u.genes,job,r)]

static func catalog(u: UnitData) -> Array:
	var entries=GeneSkills.catalog(u.genes)
	for i in range(3): entries.append({"id":JOB_SKILLS[u.profession][i],"locus":"profession","level":1,"rank":i+1})
	return entries

static func learned(u: UnitData, entry: Dictionary) -> bool:
	return u.level>=entry.level and rank(u)>=int(entry.get("rank",1)) and GeneSkills.expressed(u.genes,entry)

static func is_number(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v))

static func valid_unit_fields(d: Dictionary) -> bool:
	if d.has("profession") and (not is_number(d.profession) or d.profession!=int(d.profession) or d.profession<0 or d.profession>2): return false
	for field in ["profession_xp","ancestry"]:
		if not d.has(field): continue
		if not d[field] is Array or d[field].size()!=(3 if field=="profession_xp" else 2): return false
		for value in d[field]:
			if not is_number(value) or value!=int(value) or value<0 or value>(1000000 if field=="profession_xp" else 6): return false
	if d.has("ancestry") and mini(int(d.ancestry[0]),int(d.ancestry[1]))!=int(d.get("species",0)): return false
	if d.has("bloodline") and not Bloodline.valid(d.bloodline): return false
	return true

static func sample(race: int, job: int=0, variant: int=0) -> UnitData:
	var u=UnitData.new(); var rng=RandomNumberGenerator.new(); rng.seed=19500+variant*671+race*79
	u.uid="preview-%d-%d-%d" % [race,job,variant]; u.display_name=NAMES[(race+variant)%NAMES.size()]
	u.bloodline=Bloodline.pure(race); u.profession=job; u.genes=Genome.random_genes(rng)
	Genome.seed_traits(u.genes,u.bloodline)
	u.genes.body_a=[0,1]; u.genes.body_b=[1,0]; u.genes.height=[55,55]
	u.genes.color=[variant%6,variant%6]; u.genes.coat=[variant%4,variant%4]
	u.genes.tail=[variant%4,variant%4]; u.genes.ears=[variant%3,variant%3]
	u.heal(); return u
