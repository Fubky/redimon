from pathlib import Path
p=Path('scripts/front_end.gd');s=p.read_text(encoding='utf-8-sig');a=s.index('\tdraw_rect(Rect2(Vector2.ZERO,view)');b=s.index('\tif page=="result"',a);s=s[:a]+'''	var art=load("res://assets/art_v5/expedition_keyart.png")
	var factor=maxf(view.x/art.get_width(),view.y/art.get_height())
	var size=art.get_size()*factor
	draw_texture_rect(art,Rect2((view-size)*0.5,size),false)
	if page=="title":
		draw_style_box(app.box(Color(0.97,0.96,0.88,0.91),Color(0.85,0.76,0.52,0.8),1,24),Rect2(Vector2(78,118)+offset,Vector2(570,615)))
	else: draw_rect(Rect2(Vector2.ZERO,view),Color(0.94,0.95,0.86,0.92))
	for i in range(28):
		var p=Vector2(fmod(i*179.0+elapsed*(5+i%4),view.x),100+fmod(i*77.0,view.y-170)+sin(elapsed+i)*12)
		draw_circle(p,1+i%3,Color(1,0.94,0.65,0.6))
''' +s[b:];s=s.replace('v0.4','v0.5');p.write_text(s,encoding='utf-8')
p=Path('scripts/main.gd');s=p.read_text(encoding='utf-8-sig');a=s.index('func show_expeditions()');b=s.index('func roster_scroll(',a);s=s[:a]+'''func show_expeditions() -> void:
	open_modal("五域远征 · 通行徽记","依次挑战三层迷宫与终点守望者。击败守望者并抵达楼梯，才能解锁下一区域。")
	for i in range(5):
		var data=Dungeon.BIOMES[i]
		var unlocked=game.dungeon_unlocked(i)
		var y=124+i*121
		panel(modal_body,Rect2(30,y,1006,109),Color(data.floor).lightened(0.35) if unlocked else Color("d1d3c9"),Color(data.wall))
		var tex=TextureRect.new()
		tex.texture=load("res://assets/art_v5/expedition_keyart.png")
		tex.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; tex.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.position=Vector2(38,y+8); tex.size=Vector2(206,93); tex.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tex.modulate=Color.WHITE if unlocked else Color("6f7b77")
		modal_body.add_child(tex)
		label(modal_body,"0%d  %s" % [i+1,data.name],Vector2(267,y+10),24)
		label(modal_body,BattleRules.WEATHER[i],Vector2(269,y+44),14,GREEN)
		label(modal_body,("已获徽记 · 可再次远征" if i in game.cleared else ("推荐 Lv.%d—%d · 三层守望者" % [1+i*3,5+i*3] if unlocked else "解锁条件：完成 "+Dungeon.BIOMES[i-1].name)),Vector2(269,y+74),14,MUTED)
		button(modal_body,"进入  →" if unlocked else "尚未解锁",Rect2(849,y+31,171,48),func(): close_modal(); chosen_skill="move"; game.enter_dungeon(i),game.mode=="town" and game.pending.is_empty() and unlocked,unlocked)
	label(modal_body,"招募徽记：首通森林 +5%，首通海岛升级至 +15%（不叠加）。",Vector2(36,736),14,MUTED)

''' +s[b:];s=s.replace('and (id!="move" or not actor.moved)', 'and (id!="move" or not actor.moved) and (id=="move" or actor.cooldown(id)==0)');s=s.replace('var title="移动" if id=="move" else GameState.SKILLS[id].name','var title="移动" if id=="move" else GameState.SKILLS[id].name\n\t\tif id!="move" and actor.cooldown(id)>0: title+=" [冷却%d]" % actor.cooldown(id)');s=s.replace('if scene in ["forest","mountain","island","volcano","cave","battle","battle_burst","animation"]:\n\t\tgame.enter_dungeon','if scene in ["forest","mountain","island","volcano","cave","battle","battle_burst","animation"]:\n\t\tgame.cleared=[0,1,2,3,4] # QA scene selection only; real new games remain locked.\n\t\tgame.enter_dungeon');s=s.replace('目标无效：请检查射程、阵营、携带技能和 AP。','目标无效：请检查射程、阵营、AP、异常状态和技能冷却。');p.write_text(s,encoding='utf-8')
p=Path('scripts/progression_ui.gd');s=p.read_text(encoding='utf-8-sig').replace('已解锁 %d / 37','已解锁 %d / 41');s=s.replace('var entries=GeneSkills.catalog(u.genes)','var entries=GeneSkills.catalog(u.genes)\n\tentries.append({"id":BattleRules.SIGNATURES[u.species],"locus":"instinct","level":1})');s=s.replace('row.custom_minimum_size=Vector2(977,99)','row.custom_minimum_size=Vector2(977,117)');s=s.replace('app.MUTED,792)','app.MUTED,790)');s=s.replace('基因决定可学技能，等级决定解锁进度。探索与城镇中可调整配招，战斗中不能更换。','属性：%s · 特性：%s（%s）。战斗中不能更换。" % [BattleRules.type_label(u),BattleRules.ABILITIES[BattleRules.ability(u)],BattleRules.ABILITY_DESC[BattleRules.ability(u)]]+"');p.write_text(s,encoding='utf-8')
p=Path('scripts/combat_hud.gd');s=p.read_text(encoding='utf-8-sig');s=s.replace('text_at("攻击 %d   防御 %d   速度 %d" % [u.attack(),u.defense(),u.speed()],Vector2(81,64),12,MUTED)','text_at(BattleRules.info(u),Vector2(81,64),10,MUTED)');s+='''
	if prediction.target!=null:
		var info=g.predict(app.chosen_skill,prediction.target)
		if not info.is_empty():
			var target: UnitData=prediction.target
			var panel_y=-84.0
			draw_style_box(app.box(DARK,GOLD,1,8),Rect2(320,panel_y,790,70))
			text_at(target.display_name+" · "+BattleRules.info(target),Vector2(336,panel_y+23),14)
			text_at("预计伤害 %d · 克制 ×%.2f · 命中 %d%% · 招募 %.1f%%" % [info.damage,info.effect,info.accuracy,info.rate],Vector2(336,panel_y+48),15,GOLD)
''';p.write_text(s,encoding='utf-8')
