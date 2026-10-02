class_name GeneTraits
extends RefCounted

const STATS=["hp","attack","defense","magic","resist","speed"]
const STAT_NAMES={"hp":"生命","attack":"攻击","defense":"防御","magic":"特攻","resist":"特防","speed":"速度"}
const NAMES={"body_a":"体型 A","body_b":"体型 B","height":"身高","bone":"骨量","muscle":"肌肉","length":"肢体比例","color":"肤色","pattern":"肤纹","white":"背部显性","contrast":"发色","coat":"发型","gloss":"以太传导","face":"脸型","ears":"耳 / 角型","eyes":"瞳色","tail":"尾 / 羽型","affinity":"共感","agility":"敏捷","poise":"统御表达","plumage":"羽翼表达","scales":"龙鳞表达","feral":"兽征表达","fins":"鱼尾表达","coils":"蛇尾表达","horns":"角冠表达"}
const SPECIES_BASE=[[68,57,50,59,53,61],[74,65,54,46,49,65],[57,51,44,63,56,77],[76,61,69,48,58,44],[64,49,51,73,65,49],[70,54,57,70,64,43],[82,72,67,42,55,40]]
# Every locus contributes to at least one innate stat. EVs are separate.
const WEIGHTS={
	"body_a":[20,8,8,0,0,-8],"body_b":[14,6,8,0,4,-6],"height":[14,4,0,0,0,-4],
	"bone":[10,0,22,0,4,-4],"muscle":[4,26,2,0,0,0],"length":[4,6,0,0,0,10],
	"color":[0,0,0,10,4,0],"pattern":[0,4,0,0,8,4],"white":[6,0,0,6,6,0],
	"contrast":[0,6,0,8,0,0],"coat":[6,0,10,0,10,-2],"gloss":[0,0,0,12,6,0],
	"face":[0,8,4,6,0,0],"ears":[0,0,0,8,12,0],"eyes":[0,4,0,12,0,4],
	"tail":[0,4,6,0,0,10],"affinity":[4,0,0,8,18,0],"agility":[0,0,0,0,0,30],
	"poise":[0,0,0,4,4,0],"plumage":[0,0,0,0,0,8],"scales":[0,0,8,0,0,0],"feral":[0,8,0,0,0,0],"fins":[0,0,0,8,0,0],"coils":[0,0,0,0,8,0],"horns":[8,0,0,0,0,0]
}

static func innate(bloodline: Array, genes: Dictionary) -> Dictionary:
	var result={}
	for i in range(STATS.size()):
		var column=[]
		for base in SPECIES_BASE: column.append(base[i])
		var value=Bloodline.weighted(bloodline,column)
		for locus in Genome.LIMITS:
			var maximum=2.0 if locus in ["body_a","body_b"] else float(Genome.LIMITS[locus])
			value+=(Genome.express(genes,locus)/maximum-0.5)*WEIGHTS[locus][i]
		result[STATS[i]]=clampi(roundi(value),25,130)
	return result

static func description(locus: String) -> String:
	var pieces: PackedStringArray=[]
	for i in range(STATS.size()):
		if WEIGHTS[locus][i]!=0: pieces.append(STAT_NAMES[STATS[i]]+("↑" if WEIGHTS[locus][i]>0 else "↓"))
	return "表达值升高："+" / ".join(pieces)
