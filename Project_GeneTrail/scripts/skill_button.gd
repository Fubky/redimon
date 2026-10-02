class_name SkillButton
extends Button
## Opaque, wrapped native tooltips stay inside the viewport and never take input.
var skill_id=""
var actor: UnitData
var game: GameState
const TEXT=Color("fff5df")
const SOFT=Color("c4d4cd")
const ACCENT=Color("ffbc7c")

func _make_custom_tooltip(for_text: String) -> Object:
	var card=PanelContainer.new()
	card.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style=StyleBoxFlat.new()
	style.bg_color=Color("14252d"); style.border_color=Color("b9cdbb")
	style.set_border_width_all(2); style.set_corner_radius_all(10)
	style.set_content_margin_all(18)
	style.shadow_color=Color(0,0,0,0.55); style.shadow_size=8
	card.add_theme_stylebox_override("panel",style)
	var rows=VBoxContainer.new()
	rows.add_theme_constant_override("separation",10)
	rows.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.add_child(rows)
	if actor==null or skill_id.is_empty():
		add_line(rows,for_text,18,TEXT); return card
	if skill_id=="move":
		add_line(rows,"移动 · 每次行动一次",23,TEXT)
		add_line(rows,"每格 8 AP  /  最多 %d 格" % actor.movement(),18,SOFT)
		add_line(rows,"蓝色区域：保持快速回归\n橙色斜线区域：累计消耗超过 50 AP，下次行动延后。",18,ACCENT)
		add_line(rows,"悬停目标格，可预览消耗、剩余 AP 和时间轴中的回归位置。",18,TEXT)
	else:
		var rule: Dictionary=GameState.SKILLS[skill_id]
		add_line(rows,rule.name,23,TEXT)
		var target={"enemy":"敌方","ally":"自己 / 队友","other_ally":"其他队友","self":"自己"}.get(rule.target,"单位")
		add_line(rows,"%d AP  ·  射程 %d 格  ·  %s  ·  %s" % [rule.cost,rule.range,target,BattleRules.TYPES.get(rule.get("element","normal"),"常态")],18,SOFT)
		add_line(rows,rule.desc,18,TEXT)
		add_line(rows,"来源：%s\n冷却：%d 回合  /  当前剩余 %d 回合" % [rule.get("source","种族本能"),rule.get("cooldown",0),actor.cooldown(skill_id)],16,SOFT)
		if game!=null:
			var extra=game.return_delay(actor,int(rule.cost))-game.return_delay(actor)
			if actor.spent<=50 and actor.spent+rule.cost>50:
				add_line(rows,"越过 50 AP 分界：下次行动额外延后 %d 刻。" % extra,18,ACCENT)
			elif actor.spent>50: add_line(rows,"本轮已进入爆发区，结束后按延后时间回归。",18,ACCENT)
		if actor.ap<rule.cost: add_line(rows,"当前 AP 不足。",18,ACCENT)
	return card

func add_line(parent: Node, value: String, pixels: int, color: Color) -> void:
	var line=Label.new()
	line.text=value
	line.custom_minimum_size.x=440
	line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_font_size_override("font_size",pixels)
	line.add_theme_color_override("font_color",color)
	line.add_theme_constant_override("line_spacing",4)
	line.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)
