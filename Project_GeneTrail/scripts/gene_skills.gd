@static_unload
class_name GeneSkills
extends RefCounted
## Skills are expressed from the same diploid loci used by CreatureArt.
## Never save a second skill list: recombination and mutations remain authoritative.
const CORE = {
	"strike":{"name":"武器攻击","cost":30,"range":1,"target":"enemy","power":1.0,"source":"基础训练","desc":"近身攻击，造成 100% 攻击伤害。"},
	"delay":{"name":"重躯震荡","cost":35,"range":3,"target":"enemy","power":0.7,"shift":35,"source":"大型 / 中大型体态","desc":"造成 70% 伤害，敌人下一次行动推后 35 刻。"},
	"quick":{"name":"轻巧连击","cost":15,"range":1,"target":"enemy","power":0.6,"source":"小型 / 紧凑型体态","desc":"仅需 15 AP，造成 60% 攻击伤害。"},
	"lunge":{"name":"踏步突刺","cost":25,"range":2,"target":"enemy","power":0.85,"source":"中型体态","desc":"攻击两格内敌人，造成 85% 攻击伤害。"},
	"rally":{"name":"敏锐协同","cost":25,"range":4,"target":"other_ally","shift":-30,"source":"舒展感官 · 感官 ≥1","desc":"另一位队友行动提前 30 刻，最早到当前时间 +1。"},
	"focus":{"name":"凝神休息","cost":20,"range":0,"target":"self","heal":18,"source":"短感官 · 感官 0","desc":"选择自己，恢复 18 点生命。"},
	"mend":{"name":"生命疗愈","cost":30,"range":3,"target":"ally","heal":28,"source":"波浪发型 · 发型 1 / 2","desc":"选择自己或队友，恢复 28 点生命。"},
	"thorn":{"name":"飞针","cost":25,"range":3,"target":"enemy","power":0.65,"source":"短发型 · 发型 0","desc":"凝聚以太飞针，造成 65% 攻击伤害。"},
	"spark":{"name":"鳞光","cost":30,"range":3,"target":"enemy","power":0.9,"source":"以太适性 · 发型 3","desc":"以太折射光芒，造成 90% 攻击伤害。"},
	"sweep":{"name":"牵制扫击","cost":30,"range":2,"target":"enemy","power":0.65,"shift":20,"source":"长肢 · 尾型 ≥2","desc":"造成 65% 伤害，敌人行动推后 20 刻。"},
	"dart":{"name":"疾步飞跃","cost":20,"range":2,"target":"enemy","power":0.7,"source":"短肢 · 尾型 0 / 1","desc":"轻盈攻击两格内敌人，造成 70% 攻击伤害。"}
}

# Low-expression / high-expression names and an advanced expression for every locus.
const FAMILIES={
	"body_a":["轻巧连击","重躯震荡","地脉回响"],"body_b":["紧凑冲刺","厚实撞击","体态觉醒"],
	"height":["贴地掠影","高枝压制","凌空震落"],"bone":["柔骨突刺","硬骨重击","磐石振击"],
	"muscle":["柔劲掌","强肌猛击","全力冲击"],"length":["短身回旋","长身横扫","流线突袭"],
	"color":["暖色火花","冷色微光","虹彩迸发"],"pattern":["素纹弹","斑纹迷踪","纹路封印"],
	"white":["暮色星屑","羽光祝福","月白疗光"],"contrast":["柔影针","锐纹光束","明暗震荡"],
	"coat":["飞针","生命疗愈","护生灵光"],"gloss":["哑光微尘","亮泽闪光","镜辉折射"],
	"face":["灵巧突击","坚毅冲撞","面甲震击"],"ears":["凝神休息","敏锐协同","远音合奏"],
	"eyes":["暖瞳凝视","冷瞳星芒","慧眼迟滞"],"tail":["疾步飞跃","牵制扫击","回旋风暴"],
	"affinity":["独行决意","共感抚慰","羁绊回声"],"agility":["稳步重击","迅捷点刺","追风连击"],
	"poise":["战场号令","战场号令","统御军令"],"plumage":["风羽","风羽","风暴羽阵"],"scales":["火花","火花","龙吼"],"feral":["藤蔓","藤蔓","狩猎本能"],"fins":["潮汐","潮汐","潮汐之歌"],"coils":["蛇牙","蛇牙","缠绕束缚"],"horns":["角击","角击","角冠冲锋"]
}
static var RULES: Dictionary=build_rules()

static func build_rules() -> Dictionary:
	var rules=CORE.duplicate(true)
	for locus in FAMILIES:
		if locus in Genome.TRAITS: continue
		for tier in range(3):
			if tier<2 and locus in ["body_a","ears","coat","tail"]: continue
			var id=locus+"_"+str(tier)
			var magic=locus in ["color","pattern","white","contrast","gloss","eyes","affinity"]
			var rule={"name":FAMILIES[locus][tier],"cost":20 if tier==0 else (30 if tier==1 else 40),"range":3 if magic else 2,"target":"enemy","power":0.7 if tier==0 else (0.95 if tier==1 else 1.25),"source":GeneTraits.NAMES[locus],"damage_type":"magic" if magic else "physical"}
			if locus in ["body_a","body_b","bone","pattern","eyes","tail"] and tier>0: rule.shift=20 if tier==1 else 40
			if locus in ["white","coat","affinity"] and tier>0:
				rule.erase("power"); rule.target="ally"; rule.heal=24 if tier==1 else 42
			if locus=="ears":
				rule.erase("power")
				if tier==0: rule.target="self"; rule.heal=18; rule.range=0
				else: rule.target="other_ally"; rule.shift=-25 if tier==1 else -45; rule.range=4
			if locus=="agility" and tier==1: rule.cost=15; rule.power=0.65
			var desc=""
			if rule.has("power"): desc="造成 %d%% %s伤害。" % [roundi(rule.power*100),"特攻" if magic else "攻击"]
			if rule.has("heal"): desc="恢复 %d 点生命。" % rule.heal
			if rule.has("shift"): desc+="目标行动%s %d 刻。" % ["推后" if rule.shift>0 else "提前",absi(rule.shift)]
			rule.desc=desc
			rules[id]=rule
	for id in ["thorn","spark"]: rules[id].damage_type="magic"
	rules.body_a_small_2={"name":"风息疾连","cost":20,"range":2,"target":"enemy","power":1.1,"source":"小型 / 紧凑型进阶","desc":"仅需 20 AP，造成 110% 攻击伤害。"}
	rules.body_a_mid_2={"name":"纵跃追击","cost":25,"range":3,"target":"enemy","power":1.0,"source":"中型进阶","desc":"攻击三格内敌人，造成 100% 攻击伤害。"}
	BattleRules.enrich(rules)
	for i in range(Genome.TRAITS.size()):
		for id in [BattleRules.SIGNATURES[i],MercenaryRules.RACE_ADV[i]]:
			rules[id].source=GeneTraits.NAMES[Genome.TRAITS[i]]+" ≥40 · 共用基因池"
	return rules

static func expression_skill(genes: Dictionary, locus: String) -> String:
	if locus in Genome.TRAITS: return BattleRules.SIGNATURES[Genome.TRAITS.find(locus)]
	match locus:
		"body_a":
			match Genome.body_name(genes):
				"大型","中大型": return "delay"
				"小型","紧凑型": return "quick"
				_: return "lunge"
		"ears": return "rally" if Genome.express(genes,locus)>=1 else "focus"
		"coat":
			var coat=Genome.express(genes,locus)
			return "mend" if coat in [1,2] else ("spark" if coat==3 else "thorn")
		"tail": return "sweep" if Genome.express(genes,locus)>=2 else "dart"
	var maximum=2.0 if locus=="body_b" else float(Genome.LIMITS[locus])
	return locus+("_1" if Genome.express(genes,locus)>=maximum*0.5 else "_0")

static func catalog(genes: Dictionary) -> Array:
	var entries=[{"id":"strike","locus":"instinct","level":1},{"id":"guard","locus":"instinct","level":1},{"id":"cleanse","locus":"instinct","level":1},{"id":"befriend","locus":"instinct","level":1}]
	var i=0
	for locus in Genome.LIMITS:
		if locus in Genome.TRAITS:
			var index=Genome.TRAITS.find(locus)
			entries.append({"id":BattleRules.SIGNATURES[index],"locus":locus,"level":1,"expression":Genome.TRAIT_THRESHOLD})
			entries.append({"id":MercenaryRules.RACE_ADV[index],"locus":locus,"level":8,"expression":Genome.TRAIT_THRESHOLD})
			continue
		entries.append({"id":expression_skill(genes,locus),"locus":locus,"level":1 if locus in ["body_a","ears","coat","tail"] else 2+i%3})
		var advanced=locus+"_2"
		if locus=="body_a":
			var body=Genome.body_name(genes)
			if body in ["小型","紧凑型"]: advanced="body_a_small_2"
			elif body=="中型": advanced="body_a_mid_2"
		entries.append({"id":advanced,"locus":locus,"level":6+i%5})
		i+=1
	return entries

static func expressed(genes: Dictionary, entry: Dictionary) -> bool:
	return not entry.has("expression") or Genome.express(genes,entry.locus)>=int(entry.expression)

static func pool(genes: Dictionary, level: int=1) -> Array[String]:
	var result: Array[String]=[]
	for entry in catalog(genes):
		if entry.level<=level and expressed(genes,entry) and not entry.id in result: result.append(entry.id)
	return result

static func summary(genes: Dictionary) -> String:
	var names: PackedStringArray=[]
	for id in pool(genes):
		if not id in ["strike","guard","cleanse","befriend"]: names.append(RULES[id].name)
	return " / ".join(names.slice(0,6))+(" 等 %d 项" % names.size() if names.size()>6 else "")
