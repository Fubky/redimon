class_name BattleRules
extends RefCounted
## Data-oriented combat rules shared by prediction, AI and execution.
const TYPES = {"normal":"常态", "fire":"炎", "water":"潮", "leaf":"森", "stone":"岩", "wind":"风", "frost":"霜", "spirit":"灵"}
const COLORS = {"normal":"b8b9a7","fire":"ec8d62","water":"69bfd0","leaf":"9dc06c","stone":"bda47e","wind":"b6ded0","frost":"9edbe8","spirit":"bea0d9"}
const CHART = {
 "normal":{"stone":0.5,"spirit":0.0},
 "fire":{"leaf":2.0,"frost":2.0,"fire":0.5,"water":0.5,"stone":0.5},
 "water":{"fire":2.0,"stone":2.0,"water":0.5,"leaf":0.5},
 "leaf":{"water":2.0,"stone":2.0,"leaf":0.5,"fire":0.5,"wind":0.5},
 "stone":{"fire":2.0,"wind":2.0,"frost":2.0,"stone":0.5},
 "wind":{"leaf":2.0,"stone":0.5,"frost":0.5},
 "frost":{"leaf":2.0,"wind":2.0,"fire":0.5,"water":0.5,"frost":0.5},
 "spirit":{"spirit":2.0,"normal":0.0}
}
const SPECIES_TYPES = ["normal","wind","fire","leaf","water","spirit","stone"]
const SIGNATURES = ["human_call","gust","ember","vine","tide","serpent_fang","horn_ram"]
const STATUS_NAMES = {"burn":"灼伤","poison":"中毒","sleep":"睡眠","shock":"麻痹","frost":"冻伤"}
const ABILITIES = ["再生体质","厚甲","引水","引火","清醒","顺风"]
const ABILITY_DESC = ["每次行动恢复 5% 生命", "满血时受到的伤害减半", "免疫潮伤害并恢复 12.5% 生命", "免疫炎伤并回复 12.5%，低于半血时炎伤害提高", "免疫睡眠与麻痹", "进入战斗时行动提前 10 刻"]
const WEATHER = ["繁茂 · 森系每次行动回复","山岚 · 岩系防御增强","雨幕 · 潮强炎弱","烈日 · 炎强潮弱","晶辉 · 灵系共鸣"]

static func types(u: UnitData) -> Array:
 var traits=Genome.expressed_traits(u.genes)
 var result=[]
 for locus in traits:
  var element=SPECIES_TYPES[Genome.TRAITS.find(locus)]
  if not element in result: result.append(element)
  if result.size()==2: break
 if result.is_empty(): result.append("normal")
 var secondary = ["fire","stone","leaf","water","normal","spirit"][Genome.express(u.genes,"color")]
 if result.size()<2 and Genome.express(u.genes,"gloss")>=45 and not secondary in result: result.append(secondary)
 return result

static func type_label(u: UnitData) -> String:
 var labels: PackedStringArray=[]
 for id in types(u): labels.append(TYPES[id])
 return "/".join(labels)

static func ability(u: UnitData) -> int:
 return (Genome.express(u.genes,"affinity")/20+Genome.express(u.genes,"pattern")+Genome.express(u.genes,"coat"))%6

static func effectiveness(element: String, target: UnitData) -> float:
 var value=1.0
 for kind in types(target): value*=CHART.get(element,{}).get(kind,1.0)
 if (element=="water" and ability(target)==2) or (element=="fire" and ability(target)==3): return 0.0
 return value

static func stage_factor(stage: int) -> float:
 return (2.0+stage)/2.0 if stage>=0 else 2.0/(2.0-stage)

static func stat(u: UnitData, name: String) -> float:
 var base={"attack":u.attack(),"magic":u.magic(),"defense":u.defense(),"resist":u.resistance(),"speed":u.speed()}[name]
 var result=base*stage_factor(int(u.stages.get(name,0)))
 if name=="attack" and u.status=="burn": result*=0.5
 if name=="speed" and u.status in ["shock","frost"]: result*=0.65
 return result

static func damage(actor: UnitData, target: UnitData, rule: Dictionary, biome: int, critical: bool=false) -> int:
 var effect=effectiveness(rule.get("element","normal"),target)
 if effect==0 or not rule.has("power"): return 0
 var magic=rule.get("damage_type","physical")=="magic"
 var offense=stat(actor,"magic" if magic else "attack")
 var defense=stat(target,"resist" if magic else "defense")
 var element=rule.get("element","normal")
 var multiplier=effect*(1.5 if element in types(actor) else 1.0)
 if biome==2: multiplier*=1.25 if element=="water" else (0.75 if element=="fire" else 1.0)
 if biome==3: multiplier*=1.25 if element=="fire" else (0.75 if element=="water" else 1.0)
 if biome==4 and element=="spirit": multiplier*=1.25
 if biome==1 and "stone" in types(target): defense*=1.5
 if ability(actor)==3 and element=="fire" and actor.hp*2<=actor.max_hp(): multiplier*=1.3
 if ability(target)==1 and target.hp==target.max_hp(): multiplier*=0.5
 if target.guard: multiplier*=0.5
 if critical: multiplier*=1.5
 return maxi(1,roundi(maxf(2.0,offense*float(rule.power)-defense)*multiplier))

static func immune_status(u: UnitData, status: String) -> bool:
 return (ability(u)==4 and status in ["sleep","shock"]) or (status=="burn" and "fire" in types(u)) or (status=="frost" and "frost" in types(u)) or (status=="poison" and "leaf" in types(u))

static func info(u: UnitData) -> String:
 var result=type_label(u)+" · "+ABILITIES[ability(u)]
 if not u.status.is_empty(): result+=" · "+STATUS_NAMES[u.status]+str(u.status_turns)
 if u.guard: result+=" · 守势"
 return result

static func enrich(rules: Dictionary) -> void:
 for id in rules:
  var r: Dictionary=rules[id]
  r.element="normal"; r.accuracy=100; r.cooldown=1
  if id=="strike": r.cooldown=0
  if id.begins_with("color"): r.element="fire" if id.ends_with("0") else "frost"; r.status="burn" if r.element=="fire" else "frost"; r.chance=0.35
  elif id.begins_with("pattern"): r.element="spirit"; r.status="sleep"; r.chance=0.3
  elif id.begins_with("gloss") or id=="spark": r.element="water"; r.damage_type="magic"
  elif id.begins_with("bone") or id in ["delay","body_a_2"]: r.element="stone"
  elif id.begins_with("agility") or id in ["dart","body_a_small_2","body_a_mid_2"]: r.element="wind"
  elif id=="thorn": r.element="leaf"; r.status="poison"; r.chance=0.35
  elif id.begins_with("eyes"): r.element="spirit"; r.status="shock"; r.chance=0.4
  if id in ["mend","focus","white_2","coat_2","affinity_2"]: r.cleanse=true; r.cooldown=2
  if id.begins_with("muscle"): r.stage="attack"; r.stage_amount=1; r.stage_self=true
  if id.begins_with("face"): r.stage="defense"; r.stage_amount=-1
  if id.begins_with("contrast"): r.stage="resist"; r.stage_amount=-1
  if id.ends_with("_2") and r.has("power"): r.cooldown=2; r.accuracy=90; r.splash=1
 var added={
  "ember":{"name":"余烬弹","element":"fire","power":0.85,"status":"burn","chance":0.5,"damage_type":"magic"},
  "gust":{"name":"风切刃","element":"wind","power":0.9,"stage":"speed","stage_amount":-1},
  "rockfall":{"name":"岩楔","element":"stone","power":1.0,"shift":20},
  "vine":{"name":"缠藤","element":"leaf","power":0.8,"status":"poison","chance":0.5,"drain":0.35},
  "tide":{"name":"潮涌","element":"water","power":0.9,"damage_type":"magic","stage":"attack","stage_amount":-1},
  "guard":{"name":"守势","element":"normal","target":"self","range":0,"guard":true,"cost":20},
  "cleanse":{"name":"净化","element":"leaf","target":"ally","range":3,"cleanse":true,"heal":8,"cost":25},
  "befriend":{"name":"劝降印记","element":"spirit","target":"enemy","range":3,"mark":true,"cost":20}
 }
 added.merge({
  "human_call":{"name":"军团号令","element":"normal","target":"other_ally","shift":-25,"range":4,"cost":20},
  "serpent_fang":{"name":"毒刃","element":"spirit","power":0.85,"status":"poison","chance":0.65},
  "horn_ram":{"name":"破阵顶击","element":"stone","power":0.9,"range":2,"shift":25},
  "human_order":{"name":"坚守誓言","target":"ally","heal":35,"guard":true,"element":"normal"},
  "wing_storm":{"name":"振翼风暴","power":1.15,"splash":1,"element":"wind","shift":20},
  "dragon_roar":{"name":"龙焰咆哮","power":1.3,"damage_type":"magic","element":"fire","status":"burn","chance":0.6},
  "beast_hunt":{"name":"狩猎本能","power":1.15,"cost":20,"element":"leaf","drain":0.35},
  "fish_song":{"name":"潮汐之歌","target":"ally","heal":40,"cleanse":true,"element":"water"},
  "serpent_bind":{"name":"蛇尾缚阵","power":0.8,"shift":45,"element":"spirit","range":2},
  "horn_charge":{"name":"山岳突贯","power":1.25,"shift":30,"element":"stone","range":2},
  "knight_cut":{"name":"长剑斩","power":1.1,"cost":25,"range":1,"element":"normal","cooldown":0},
  "knight_oath":{"name":"守护誓约","target":"ally","guard":true,"heal":15,"range":2,"element":"normal"},
  "knight_break":{"name":"盾击破势","power":1.1,"shift":35,"stage":"defense","stage_amount":-1,"range":1,"element":"stone"},
  "mage_bolt":{"name":"以太箭","power":0.85,"damage_type":"magic","range":3,"cost":25,"element":"spirit","cooldown":0},
  "mage_mend":{"name":"圣光术","target":"ally","heal":32,"cleanse":true,"range":3,"element":"leaf"},
  "mage_clock":{"name":"时序枷锁","power":0.75,"damage_type":"magic","shift":45,"range":4,"element":"frost","cost":40},
  "ranger_shot":{"name":"游猎射击","power":0.8,"range":3,"cost":20,"element":"wind","cooldown":0},
  "ranger_mark":{"name":"破甲箭","power":0.8,"stage":"defense","stage_amount":-1,"range":4,"element":"normal"},
  "ranger_flurry":{"name":"双刃疾袭","power":1.3,"cost":25,"range":2,"element":"wind"}
 })
 for id in added:
  var r={"cost":30,"range":3,"target":"enemy","source":"共同战术 / 种族天赋","accuracy":100,"cooldown":1}
  r.merge(added[id],true); rules[id]=r
 for id in rules:
  var r: Dictionary=rules[id]
  var description="%s属性 · %s · 命中 %d%% · 冷却 %d 行动。" % [TYPES[r.element],"特攻" if r.get("damage_type","")=="magic" else "物攻",r.accuracy,r.cooldown]
  if r.has("power"): description+="威力 %d%%。" % roundi(r.power*100)
  if r.has("heal"): description+="回复 %d。" % r.heal
  if r.has("shift"): description+="时间轴 %+d。" % r.shift
  if r.has("status"): description+="%d%% %s。" % [roundi(r.chance*100),STATUS_NAMES[r.status]]
  if r.has("stage"): description+="%s%s %+d 级。" % ["自身" if r.get("stage_self",false) else "目标",GeneTraits.STAT_NAMES[r.stage],r.stage_amount]
  if r.get("splash",0)>0: description+="溅射邻近敌人 50%。"
  if r.get("cleanse",false): description+="解除异常。"
  if r.get("guard",false): description+="抵挡下次伤害的一半，持续至下次行动。"
  if r.get("mark",false): description+="本场招募率 +10 个百分点，不叠加。"
  if r.has("drain"): description+="吸取 35% 伤害。"
  r.desc=description
