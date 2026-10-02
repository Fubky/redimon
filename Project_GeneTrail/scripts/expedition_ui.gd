class_name ExpeditionUI
extends RefCounted

static func open(app, biome: int, selection: String="relay", high_risk: bool=false) -> void:
	app.open_modal("出征战术 · "+Dungeon.BIOMES[biome].name,"战术持续本次三层远征，回城后结束。按队伍技能选择打法，每次出发都可以重新组合。")
	var risk=CheckButton.new(); risk.position=Vector2(38,623); risk.size=Vector2(974,43)
	risk.text="高危悬赏：敌人等级 +2 · 击杀金币 ×1.5 · 通关额外 +120 金币"; risk.button_pressed=high_risk
	risk.add_theme_font_size_override("font_size",17); app.modal_body.add_child(risk)
	var i=0
	for id in ExpeditionRules.PLANS:
		var plan=ExpeditionRules.PLANS[id]; var x=34+i*337; var selected=id==selection
		app.panel(app.modal_body,Rect2(x,140,324,461),Color("e2e8d9") if selected else Color("ece6d8"),Color(plan.color),2)
		app.label(app.modal_body,"0%d / %s" % [i+1,plan.tag],Vector2(x+18,159),14,app.MUTED)
		app.label(app.modal_body,plan.name,Vector2(x+18,199),27)
		app.label(app.modal_body,plan.desc,Vector2(x+18,262),16,app.INK)
		app.label(app.modal_body,plan.tip,Vector2(x+18,449),14,app.MUTED)
		app.button(app.modal_body,"已选择" if selected else "选择"+plan.name,Rect2(x+18,530,288,47),func(): open(app,biome,id,risk.button_pressed),not selected,selected)
		i+=1
	app.label(app.modal_body,"战术无额外金币成本。高危悬赏可关闭；撤退没有通关奖金。\n协同 / 爆发的额外伤害与延时会显示在目标预览里。",Vector2(40,693),15,app.MUTED)
	app.button(app.modal_body,"按此战术出征  →",Rect2(718,704,308,50),func():
		if app.game.enter_dungeon(biome,selection,risk.button_pressed):
			app.chosen_skill="move"; app.close_modal(),true,true)

static func inspect(app) -> void:
	var id=app.game.expedition_plan
	if id.is_empty(): return
	var plan=ExpeditionRules.PLANS[id]
	app.open_modal("本次战术 · "+plan.name,"本次远征内固定生效；回城后可选择另一种战术。")
	app.label(app.modal_body,plan.desc,Vector2(45,158),24)
	app.label(app.modal_body,plan.tip,Vector2(45,415),20,app.GREEN)
	app.label(app.modal_body,"高危悬赏生效：敌人 +2 级，击杀金币 ×1.5，通关额外 +120。" if app.game.expedition_risk else "当前为普通强度远征。",Vector2(45,549),20,app.MUTED)
