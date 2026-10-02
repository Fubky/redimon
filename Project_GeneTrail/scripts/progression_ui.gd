class_name ProgressionUI
extends RefCounted

static func skills(app, u: UnitData) -> void:
	app.open_modal(u.display_name+" · 技能与配招","属性：%s · 特性：%s（%s）。战斗中不能更换。" % [BattleRules.type_label(u),BattleRules.ABILITIES[BattleRules.ability(u)],BattleRules.ABILITY_DESC[BattleRules.ability(u)]]+"")
	app.preview_unit=u
	var carried=u.carried_skills()
	app.label(app.modal_body,"Lv.%d  ·  已携带 %d / 4  ·  已解锁 %d 项" % [u.level,carried.size(),u.skill_pool().size()],Vector2(34,124),20)
	for i in range(4):
		var id=carried[i] if i<carried.size() else ""
		app.panel(app.modal_body,Rect2(34+i*251,164,239,54),Color("dce3cb"))
		app.label(app.modal_body,"%d  %s" % [i+1,GeneSkills.RULES[id].name if not id.is_empty() else "空技能槽"],Vector2(48+i*251,180),17)
	var entries=MercenaryRules.catalog(u)
	entries.sort_custom(func(a,b):
		if (a.id in carried)!=(b.id in carried): return a.id in carried
		if MercenaryRules.learned(u,a)!=MercenaryRules.learned(u,b): return MercenaryRules.learned(u,a)
		return a.id<b.id if a.level==b.level else a.level<b.level)
	var list=app.roster_scroll(234)
	for entry in entries:
		var rule=GeneSkills.RULES[entry.id]
		var unlocked=MercenaryRules.learned(u,entry)
		var equipped=entry.id in carried
		var row=Panel.new()
		row.custom_minimum_size=Vector2(977,117)
		row.add_theme_stylebox_override("panel",app.box(Color("e3e7d2") if equipped else Color("eeeadb")))
		list.add_child(row)
		app.label(row,rule.name+("  ·  职业 R%d"%entry.rank if entry.has("rank") else "  ·  Lv.%d"%entry.level),Vector2(18,9),20,app.INK if unlocked else app.MUTED)
		app.label(row,"%s  ·  %d AP / %d 格  ·  %s" % [{"instinct":"基础训练","race":"种族天赋","profession":"职业训练"}.get(entry.locus,GeneTraits.NAMES.get(entry.locus,"")),rule.cost,rule.range,"已携带" if equipped else ("可学习" if unlocked else ("表达 %d / 40 · Lv.%d" % [Genome.express(u.genes,entry.locus),entry.level] if entry.has("expression") else "提升等级 / 职业后解锁"))],Vector2(19,39),13,app.GREEN)
		app.label(row,rule.desc,Vector2(19,65),14,app.MUTED,790)
		app.button(row,"卸下" if equipped else ("携带" if unlocked else "未解锁"),Rect2(837,24,125,45),func():
			app.game.equip_skill(u,entry.id,not equipped)
			skills(app,u),app.game.mode!="battle" and u in app.game.party+app.game.home and unlocked and (carried.size()>1 if equipped else carried.size()<4),equipped)

static func training(app, u: UnitData) -> void:
	app.open_modal(u.display_name+" · 成长与培养","基础属性由血统加权与共用基因共同决定；努力值来自战斗与训练，不会遗传给后代。")
	var base=u.base_stats()
	app.label(app.modal_body,"Lv.%d   经验 %d / %d    努力值 %d / 192    金币 %d" % [u.level,u.xp,u.level*25,u.total_effort(),app.game.gold],Vector2(35,133),20)
	for heading in [["属性",48],["基因种族值",245],["努力值 / 64",461],["实战值",684]]:
		app.label(app.modal_body,heading[0],Vector2(heading[1],193),17)
	var values=[u.max_hp(),u.attack(),u.defense(),u.magic(),u.resistance(),u.speed()]
	for i in range(GeneTraits.STATS.size()):
		var stat=GeneTraits.STATS[i]
		var y=232+i*67
		app.panel(app.modal_body,Rect2(34,y,995,56),Color("e5e7d4"))
		app.label(app.modal_body,GeneTraits.STAT_NAMES[stat],Vector2(48,y+17),18)
		app.label(app.modal_body,str(base[stat]),Vector2(267,y+17),18)
		app.label(app.modal_body,str(u.effort[stat])+" / 64",Vector2(477,y+17),18)
		app.label(app.modal_body,str(values[i]),Vector2(697,y+17),18)
		app.button(app.modal_body,"训练 +4 / 20 金币",Rect2(792,y+7,218,42),func(): app.game.train(u,stat); training(app,u),app.game.mode=="town" and u in app.game.party+app.game.home and app.game.gold>=20 and u.effort[stat]<64 and u.total_effort()<192)
	app.label(app.modal_body,"每项努力值最多 64，总和最多 192。击败敌人时，存活队友自动获得对应属性的 2 点努力值。",Vector2(37,664),16,app.MUTED,976)
	app.button(app.modal_body,"转职与职业训练",Rect2(34,709,314,41),func(): MercenaryUI.professions(app,u),true,true)
	app.button(app.modal_body,"查看技能与配招",Rect2(714,709,314,41),func(): skills(app,u),true,true)

static func codex(app) -> void:
	app.open_modal("基因图鉴","所有血统共用 25 个双等位基因位点。外观与技能由基因表达，不按血统来源限制。")
	app.button(app.modal_body,"混合血统 · 角色名录 →",Rect2(715,114,310,39),func(): HumanGallery.open_preview(app),true,true)
	app.label(app.modal_body,"遗传决定天赋；后天训练决定职业。",Vector2(35,123),18,app.GREEN)
	var list=app.roster_scroll(168)
	for locus in Genome.LIMITS:
		var row=Panel.new()
		row.custom_minimum_size=Vector2(977,141)
		row.add_theme_stylebox_override("panel",app.box(Color("e5e7d4")))
		list.add_child(row)
		app.label(row,GeneTraits.NAMES[locus]+" / "+locus,Vector2(18,13),21)
		var maximum=Genome.LIMITS[locus]
		var inheritance="二位点共同决定大 / 中 / 小体型" if locus in ["body_a","body_b"] else ("取编号较小的显性等位基因" if maximum<=5 else "取双亲等位基因平均值")
		app.label(row,"等位基因 0—%d · %s" % [maximum,inheritance],Vector2(19,45),14,app.MUTED)
		var names=GeneSkills.FAMILIES[locus]
		app.label(row,("表达 ≥40：%s → Lv.8 %s" % [GeneSkills.RULES[BattleRules.SIGNATURES[Genome.TRAITS.find(locus)]].name,GeneSkills.RULES[MercenaryRules.RACE_ADV[Genome.TRAITS.find(locus)]].name] if locus in Genome.TRAITS else "技能方向：%s / %s → %s（进阶）" % names),Vector2(19,72),16,app.GREEN)
		app.label(row,GeneTraits.description(locus),Vector2(19,108),14,app.MUTED)
	app.label(app.modal_body,"初阶技能在 Lv.1—4 解锁，进阶技能在 Lv.6—10 解锁；角色档案显示自身表达的准确技能。",Vector2(36,730),14,app.MUTED)

static func tactics(app) -> void:
	app.open_modal("战术图鉴 · 选择比连点更重要","行是攻击属性，列是防守属性。双属性乘算；本系技能额外 ×1.5。特性可以改变免疫和伤害。")
	var kinds=BattleRules.TYPES.keys()
	app.label(app.modal_body,"攻击 ↓ / 防守 →",Vector2(38,131),15)
	for i in range(kinds.size()):
		app.label(app.modal_body,BattleRules.TYPES[kinds[i]],Vector2(225+i*95,130),18)
		app.label(app.modal_body,BattleRules.TYPES[kinds[i]],Vector2(70,181+i*43),18)
		for j in range(kinds.size()):
			var value=BattleRules.CHART.get(kinds[i],{}).get(kinds[j],1.0)
			app.panel(app.modal_body,Rect2(192+j*95,172+i*43,88,37),Color("c1d7b1") if value>1 else (Color("d1c6dc") if value==0 else Color("e7dec6")))
			app.label(app.modal_body,"×%.1f" % value,Vector2(213+j*95,180+i*43),16)
	app.label(app.modal_body,"灼伤：物攻减半、持续伤害。中毒：持续伤害。麻痹：75 AP、速度下降。冻伤：移动与速度下降。",Vector2(36,530),15,app.MUTED,990)
	app.label(app.modal_body,"睡眠跳过一次行动，受伤醒来。守势抵挡一次伤害；净化移除异常。能力变化最多 ±3 级，脱战重置。",Vector2(36,574),15,app.MUTED,990)
	app.label(app.modal_body,"招募：七源基础率 25 / 18 / 12 / 8 / 5 / 10 / 16%，按全部血统占比加权。守望者 -8%，首次击败不能招募。每名敌人仅掷一次概率。",Vector2(36,618),15,app.MUTED,990)
	app.label(app.modal_body,"等级加成：Lv.30 +5%，40 +7.5%，50 +12.5%，99 +24.5%；亲和基因 ≥80 再 +5%。共鸣印记 +10%。",Vector2(36,662),15,app.MUTED,990)
	app.label(app.modal_body,"首通森林 / 海岛给予 +5% / +15% 徽记（不叠加）。毒伤击倒不能招募。技能预览未计会心；会心率 6.25%。",Vector2(36,706),14,app.MUTED,990)
