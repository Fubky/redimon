class_name RecruitmentRules
extends RefCounted
## Sky-inspired base species rate + additive level/item bonuses; not exact species copying.
const BASE=[25.0,18.0,12.0,8.0,5.0,10.0,16.0]
static func level_bonus(level: int) -> float:
 if level>=99: return 24.5
 if level>=50: return 12.5
 if level>=40: return 7.5
 if level>=30: return 5.0
 return 0.0
static func breakdown(target: UnitData, leader: UnitData, cleared: Array) -> Dictionary:
 var base=-8.0 if target.elite else Bloodline.weighted(target.bloodline,BASE)
 var charm=15.0 if 2 in cleared else (5.0 if 0 in cleared else 0.0)
 var affinity=5.0 if Genome.express(leader.genes,"affinity")>=80 else 0.0
 var mark=10.0 if target.marked else 0.0
 var chance=clampf(base+level_bonus(leader.level)+charm+affinity+mark,0.0,95.0)
 return {"base":base,"level":level_bonus(leader.level),"charm":charm,"affinity":affinity,"mark":mark,"chance":chance}
