class_name ExpeditionRules
extends RefCounted

const PLANS={
	"relay":{"name":"协同追击","tag":"接力 · 控场","color":"79b9bf","desc":"一名队友命中后留下协同标记。\n另一名队友接力命中同一敌人：\n伤害 +25%，敌方行动推后 15 刻。\n每名敌人每次行动间仅触发一次；\n敌人开始行动时，标记消失。","tip":"用两名佣兵接力集火，抢在敌人行动前\n打出连携。单人重复攻击不会触发。"},
	"tempo":{"name":"轻装轮替","tag":"节奏 · 续航","color":"99b97b","desc":"本回合消耗 1—50 AP 后结束行动：\n下次回归最多提前 12 刻。\n清空房间后，存活队友回复 10% HP。\n空过回合不会得到加速奖励；\n超过 50 AP 时失去本次加速。","tip":"移动与低消耗技能搭配，保持快速轮替，\n适合连续探索和保护护送人。"},
	"burst":{"name":"破阵强攻","tag":"爆发 · 风险","color":"d79679","desc":"累计消耗超过 50 AP 后，\n本回合第一次有效的直接伤害：\n伤害 +35%，敌方行动推后 20 刻。\n每回合仅一次，溅射不重复触发。\n仍需承担原有超支行动延迟。","tip":"先走位或铺垫，再用重击打出爆发。\n留意敌方时间轴，避免强攻后被反击。"}
}

static func valid_plan(id: String) -> bool: return id.is_empty() or PLANS.has(id)

static func bonus(plan: String, actor: UnitData, target: UnitData, rule: Dictionary, spent: int) -> Dictionary:
	var result={"multiplier":1.0,"shift":0,"tag":""}
	if actor.faction!="party" or target.faction!="enemy" or not rule.has("power") or BattleRules.effectiveness(rule.element,target)==0: return result
	if plan=="relay" and not target.combo_used and not target.combo_from.is_empty() and target.combo_from!=actor.uid:
		return {"multiplier":1.25,"shift":15,"tag":"协同追击"}
	if plan=="burst" and spent>50 and not actor.burst_used:
		return {"multiplier":1.35,"shift":20,"tag":"破阵强攻"}
	return result

static func valid_unit(d: Dictionary) -> bool:
	if d.has("combo_from") and not d.combo_from is String: return false
	for field in ["combo_used","burst_used"]:
		if d.has(field) and not d[field] is bool: return false
	return true
