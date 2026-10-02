class_name MercenaryUI
extends RefCounted

static func contracts(app) -> void:
	var game: GameState=app.game
	app.open_modal("自由市佣兵公会 · 任务栏","神圣罗马帝国诸邦之间的幻想佣兵故事。最多承接 3 份委托；同时只护送 1 位委托人。")
	app.panel(app.modal_body,Rect2(30,111,1006,137),Color("24384b"),Color("bc9a65"))
	app.label(app.modal_body,"主线 · 继承的借据" if game.debt>0 else "主线完成 · 自由之旗",Vector2(48,124),22,Color("f1d39f"))
	app.label(app.modal_body,"继承的产业抵不过旧债。拿起武器赚取佣金，赎回家族的未来。" if game.debt>0 else "债务已经清偿。佣兵团、家系与未完成的委托将继续陪你前行。",Vector2(49,162),15,Color("d8dfde"))
	app.label(app.modal_body,"剩余贷款  %d / %d    ·    随身金币 %d"%[game.debt,ContractRules.DEBT,game.gold],Vector2(49,203),18,Color("fff3cf"))
	app.button(app.modal_body,"偿还 100",Rect2(715,195,140,37),func(): ContractRules.repay(game,100); contracts(app),game.mode=="town" and game.gold>0 and game.debt>0)
	app.button(app.modal_body,"尽力偿还",Rect2(871,195,147,37),func(): ContractRules.repay(game,game.gold); contracts(app),game.mode=="town" and game.gold>0 and game.debt>0,true)
	var list=app.roster_scroll(263); list.get_parent().size.y=435
	for q in ContractRules.board():
		var status=game.contracts.get(q.id,{"state":"available","progress":0})
		var available=game.dungeon_unlocked(q.biome)
		var row=Panel.new(); row.custom_minimum_size=Vector2(977,145)
		row.add_theme_stylebox_override("panel",app.box(Color("e6e7d8") if available else Color("deddd7")))
		list.add_child(row)
		var state_label=ContractRules.STATES.get(status.state,"可接取" if available else "区域未解锁")
		app.label(row,q.title+"  ·  "+state_label,Vector2(19,10),20)
		var target="在该区域击败 %d 名敌人（%d / %d），进度可跨远征累积。"%[q.count,status.progress,q.count] if q.kind=="kill" else "从第 1 层入口护送至第 2 层楼梯；委托人必须存活并跟上队伍。"
		app.label(row,target,Vector2(20,44),15,app.MUTED,770)
		app.label(row,"委托人：%s  ·  报酬 %d 金币 + 小队经验"%[q.client,q.reward],Vector2(20,76),14,app.GREEN)
		app.label(row,"失败可重接；提前撤离会使正在进行的护送失败。" if q.kind=="escort" else "任务目标达成后回镇交付。每份委托仅结算一次。",Vector2(20,110),13,app.MUTED)
		if status.state=="ready": app.button(row,"领取报酬",Rect2(824,50,139,43),func(): ContractRules.claim(game,q.id); contracts(app),game.mode=="town",true)
		elif status.state in ["available","failed"]: app.button(row,"重新接取" if status.state=="failed" else "接受委托",Rect2(824,50,139,43),func():
			if not ContractRules.accept(game,q.id): app.show_toast("委托上限为 3；同时最多承接 1 份护送。请先交付其他任务。")
			contracts(app),game.mode=="town" and available,true)
	app.label(app.modal_body,"借据没有倒计时或自动扣款；可保留补给费用，分期偿还。楼梯交付护送后，仍可继续挑战第 3 层。",Vector2(35,726),14,app.MUTED,990)

static func professions(app, u: UnitData) -> void:
	app.open_modal(u.display_name+" · 职业教官","转职免费，仅在城镇进行。各职业熟练度保留；切换后自动重配 4 个技能，努力值与遗传基因不变。")
	for job in range(3):
		var y=132+job*168
		app.panel(app.modal_body,Rect2(32,y,1000,154),Color("e3e4d6"))
		app.label(app.modal_body,MercenaryRules.JOBS[job]+"  ·  R%d"%MercenaryRules.rank(u,job),Vector2(53,y+12),25)
		app.label(app.modal_body,MercenaryRules.OUTFITS[job]+"  /  "+MercenaryRules.aptitude_label(u.genes,job),Vector2(55,y+49),17,app.GREEN)
		app.label(app.modal_body,MercenaryRules.rank_progress(u,job),Vector2(55,y+79),15,app.MUTED)
		var names=[]
		for i in range(3): names.append("R%d %s"%[i+1,GeneSkills.RULES[MercenaryRules.JOB_SKILLS[job][i]].name])
		app.label(app.modal_body," → ".join(names),Vector2(55,y+115),15,app.MUTED)
		app.button(app.modal_body,"当前职业" if u.profession==job else "转为此职业",Rect2(813,y+43,197,46),func(): app.game.change_profession(u,job); professions(app,u),app.game.mode=="town" and u.profession!=job,true)
	app.label(app.modal_body,"骨量 / 肌肉→骑士；共感 / 以太→法师；敏捷 / 肢体→游侠。经验同时增加当前职业熟练度。\nR2—R5 增强职业攻防或速度；基因决定所需熟练度（×0.75—1.35）。职业与经验不遗传。",Vector2(35,652),15,app.MUTED,980)
	app.button(app.modal_body,"职业训练 +30 / 30 金币",Rect2(34,714,340,41),func(): app.game.train_profession(u); professions(app,u),app.game.mode=="town" and app.game.gold>=30 and MercenaryRules.rank(u)<5)
	app.button(app.modal_body,"遗传技能 / 配招",Rect2(715,714,313,41),func(): ProgressionUI.skills(app,u),true,true)
