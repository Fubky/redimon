class_name UnitData
extends RefCounted

var uid: String = ""
var display_name: String = ""
## Legacy preview scripts only; gameplay identity is bloodline + genes.
var species: int = 0
var bloodline: Array = [10000,0,0,0,0,0,0]
var genes: Dictionary = {}
var ancestry: Array = [0,0]
var profession: int = 0
var profession_xp: Array = [0,0,0]
var parents: Array = []
var mutations: Array = []
var generation: int = 0
var level: int = 1
var xp: int = 0
var faction: String = "party"
var hp: int = 1
var cell: Vector2i = Vector2i.ZERO
var town_position: Vector2 = Vector2(-1,-1)
var ready_at: int = 0
var ap: int = 100
var spent: int = 0

var equipped_skills: Array[String]=[]
var effort: Dictionary={"hp":0,"attack":0,"defense":0,"magic":0,"resist":0,"speed":0}
var moved: bool=false
var status: String=""
var status_turns: int=0
var stages: Dictionary={}
var cooldowns: Dictionary={}
var guard: bool=false
var marked: bool=false
var elite: bool=false
var recruit_rolled: bool=false
var last_recruit_rate: float=0.0
var combo_from: String=""
var combo_used: bool=false
var burst_used: bool=false
var _genetic_key: Array=[]
var _base_cache: Dictionary={}
var _pool_key: Array=[]
var _pool_cache: Array[String]=[]
var _loadout_key: Array=[]

func clear_battle_state(full: bool=false) -> void:
	stages.clear(); cooldowns.clear(); guard=false
	combo_from=""; combo_used=false; burst_used=false
	if full: status=""; status_turns=0

func cooldown(id: String) -> int: return int(cooldowns.get(id,0))

const EFFORT_CAP=64
const EFFORT_TOTAL=192

func base_stats() -> Dictionary:
	var key=[hash(bloodline),hash(genes)]
	if key!=_genetic_key:
		_genetic_key=key
		_base_cache=GeneTraits.innate(bloodline,genes)
	return _base_cache.duplicate()
func max_hp() -> int: return 30+base_stats().hp/2+level*4+int(effort.hp)/4
func attack() -> int: return 6+base_stats().attack/5+level*2+int(effort.attack)/8+MercenaryRules.stat_bonus(self,"attack")
func magic() -> int: return 6+base_stats().magic/5+level*2+int(effort.magic)/8+MercenaryRules.stat_bonus(self,"magic")
func speed() -> int: return mini(28,7+base_stats().speed/10+int(effort.speed)/8)+MercenaryRules.stat_bonus(self,"speed")
func defense() -> int: return 1+base_stats().defense/12+level/3+int(effort.defense)/12+MercenaryRules.stat_bonus(self,"defense")
func resistance() -> int: return 1+base_stats().resist/12+level/3+int(effort.resist)/12+MercenaryRules.stat_bonus(self,"resist")
func movement() -> int: return maxi(2,clampi(3+speed()/6,4,7)-(2 if status=="frost" else 0))
func color() -> Color: return Genome.COLORS[Genome.express(genes,"color")]
func alive() -> bool: return hp>0
func heal() -> void: hp=max_hp()
func skill_pool() -> Array[String]:
	var key=[level,hash(genes),profession,hash(profession_xp)]
	if key!=_pool_key:
		_pool_key=key
		_pool_cache.clear()
		for entry in MercenaryRules.catalog(self):
			if MercenaryRules.learned(self,entry) and not entry.id in _pool_cache: _pool_cache.append(entry.id)
	return _pool_cache.duplicate()
func total_effort() -> int:
	var total=0
	for value in effort.values(): total+=int(value)
	return total

func add_effort(stat: String, amount: int) -> int:
	if not effort.has(stat) or amount<=0: return 0
	var gain=mini(amount,mini(EFFORT_CAP-int(effort[stat]),EFFORT_TOTAL-total_effort()))
	effort[stat]+=gain
	return gain

func ensure_loadout() -> void:
	var key=[level,hash(genes),hash(equipped_skills),profession,hash(profession_xp)]
	if key==_loadout_key: return
	var learned=skill_pool()
	var valid: Array[String]=[]
	for id in equipped_skills:
		if id in learned and not id in valid and valid.size()<4: valid.append(id)
	equipped_skills=valid
	if equipped_skills.is_empty():
		# Expressive genes take priority over the shared basic attack.
		equipped_skills.append(MercenaryRules.JOB_SKILLS[profession][0])
		for locus in ["body_a","coat"]:
			var id=GeneSkills.expression_skill(genes,locus)
			if id in learned: equipped_skills.append(id)
		for locus in Genome.expressed_traits(genes):
			var id=GeneSkills.expression_skill(genes,locus)
			if id in learned and not id in equipped_skills:
				equipped_skills.append(id); break
		if equipped_skills.size()<4: equipped_skills.append("strike")
	_loadout_key=[level,hash(genes),hash(equipped_skills),profession,hash(profession_xp)]

func carried_skills() -> Array[String]:
	ensure_loadout()
	return equipped_skills.duplicate()

func has_skill(id: String) -> bool:
	ensure_loadout()
	return id in equipped_skills

func equip(id: String) -> bool:
	if not id in skill_pool() or id in equipped_skills or equipped_skills.size()>=4: return false
	equipped_skills.append(id)
	return true

func unequip(id: String) -> bool:
	if not id in equipped_skills or equipped_skills.size()<=1: return false
	equipped_skills.erase(id)
	return true

func gain_xp(amount: int) -> void:
	xp += amount
	profession_xp[profession]=mini(1000000,int(profession_xp[profession])+maxi(0,amount))
	while xp >= level * 25:
		xp -= level * 25
		level += 1
		hp = mini(hp + 10, max_hp())

func serialize() -> Dictionary:
	return {"uid":uid,"name":display_name,"bloodline":bloodline.duplicate(),"profession":profession,"profession_xp":profession_xp.duplicate(),"genes":genes.duplicate(true),"parents":parents.duplicate(),"mutations":mutations.duplicate(),"generation":generation,"level":level,"xp":xp,"faction":faction,"hp":hp,"cell":[cell.x,cell.y],"town_position":[town_position.x,town_position.y],"ready_at":ready_at,"ap":ap,"spent":spent,"equipped":carried_skills(),"effort":effort.duplicate(),"moved":moved,"status":status,"status_turns":status_turns,"stages":stages.duplicate(),"cooldowns":cooldowns.duplicate(),"guard":guard,"marked":marked,"elite":elite,"recruit_rolled":recruit_rolled,"last_recruit_rate":last_recruit_rate,"combo_from":combo_from,"combo_used":combo_used,"burst_used":burst_used}

static func deserialize(d: Dictionary) -> UnitData:
	var u = UnitData.new()
	u.uid = d.uid
	u.display_name = d.name
	u.species = int(d.get("species",0))
	u.bloodline=d.get("bloodline",Bloodline.legacy(d)).map(func(v): return int(v))
	u.ancestry=d.get("ancestry",[u.species,u.species]).map(func(v): return int(v))
	u.profession=int(d.get("profession",0))
	u.profession_xp=d.get("profession_xp",[0,0,0]).map(func(v): return int(v))
	u.genes = Genome.migrate_traits(d.genes,u.bloodline)
	for locus in Genome.LIMITS: u.genes[locus]=[int(u.genes[locus][0]),int(u.genes[locus][1])]
	u.parents = d.get("parents",[])
	u.mutations = d.get("mutations",[])
	u.generation = int(d.get("generation",0))
	u.level = int(d.level)
	u.xp = int(d.xp)
	u.faction = d.faction
	u.hp = int(d.hp)
	u.cell = Vector2i(int(d.cell[0]),int(d.cell[1]))
	var pos = d.get("town_position",[u.cell.x*40+20,u.cell.y*40+20])
	u.town_position=Vector2(float(pos[0]),float(pos[1]))
	u.ready_at = int(d.ready_at)
	u.ap = int(d.ap)
	u.spent = int(d.spent)
	for stat in GeneTraits.STATS: u.effort[stat]=int(d.get("effort",{}).get(stat,0))
	u.equipped_skills.assign(d.get("equipped",[]))
	u.moved=d.get("moved",false)
	u.status=d.get("status",""); u.status_turns=int(d.get("status_turns",0))
	u.stages=d.get("stages",{}).duplicate(); u.cooldowns=d.get("cooldowns",{}).duplicate()
	u.guard=d.get("guard",false); u.marked=d.get("marked",false); u.elite=d.get("elite",false)
	u.recruit_rolled=d.get("recruit_rolled",false); u.last_recruit_rate=float(d.get("last_recruit_rate",0))
	u.combo_from=d.get("combo_from",""); u.combo_used=d.get("combo_used",false); u.burst_used=d.get("burst_used",false)
	u.ensure_loadout()
	return u
