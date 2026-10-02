extends Control

const INK = Color("26384c")
const MUTED = Color("687885")
const PAPER = Color("f5efdc")
const GREEN = Color("367b83")
const AMBER = Color("e8ad68")
var game = GameState.new()
var board: GameBoard
var font: SystemFont
var hud: Control
var modal: Control
var modal_body: Control
var chosen_skill = "move"
var goal_cell = Vector2i(-1,-1)
var ai_timer = 0.0
var save_timer = -1.0
var refresh_queued = false
var toast: Label
var toast_timer = 0.0
var qa_mode = false
var preview_unit: UnitData
var map_frame: Control
var field_overlay: FieldOverlay
var combat_ui: CombatHUD
var town_movement = TownMovement.new()
var dungeon_movement = DungeonMovement.new()
var audio: GameAudio
var frontend: FrontEnd
var active_slot=0
var battle_selection=""
var last_actor=""
var last_mode="town"
var animation_locked=false
var last_turn_serial=-1
var hud_key: Array=[]
var hud_builds=0

func _ready() -> void:
	get_tree().auto_accept_quit=false
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei","Noto Sans CJK SC","WenQuanYi Micro Hei","sans-serif"])
	var ui_theme = Theme.new()
	ui_theme.default_font = font
	ui_theme.default_font_size = 16
	ui_theme.set_stylebox("normal","LineEdit",box(Color("fff6e4"),Color("9cadab"),1,6))
	ui_theme.set_color("font_color","LineEdit",INK)
	ui_theme.set_color("caret_color","LineEdit",GREEN)
	ui_theme.set_color("font_color","Label",INK)
	ui_theme.set_color("font_color","Button",INK)
	ui_theme.set_color("font_hover_color","Button",INK)
	ui_theme.set_color("font_pressed_color","Button",PAPER)
	ui_theme.set_color("font_disabled_color","Button",Color("a1a391"))
	ui_theme.set_stylebox("normal","Button",box(Color("eee7d4"),Color("c9cbb4"),1,8))
	ui_theme.set_stylebox("hover","Button",box(Color("e1e5ce"),GREEN,2,8))
	ui_theme.set_stylebox("pressed","Button",box(GREEN,INK,1,8))
	ui_theme.set_stylebox("disabled","Button",box(Color("e6e4d8"),Color("d2d3c5"),1,8))
	ui_theme.set_stylebox("focus","Button",box(Color.TRANSPARENT,AMBER,2,8))
	ui_theme.set_color("font_color","OptionButton",INK)
	ui_theme.set_stylebox("normal","OptionButton",box(Color("eee7d4"),GREEN,1,6))
	ui_theme.set_stylebox("hover","OptionButton",box(Color("e1e5ce"),GREEN,1,6))
	ui_theme.set_stylebox("panel","PopupMenu",box(PAPER,GREEN,1,8))
	ui_theme.set_color("font_color","PopupMenu",INK)
	ui_theme.set_stylebox("panel","TooltipPanel",box(Color("14252d"),Color("b9cdbb"),2,10))
	ui_theme.set_color("font_color","TooltipLabel",Color("fff5df"))
	ui_theme.set_font_size("font_size","TooltipLabel",18)
	theme = ui_theme
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture=") or arg=="--integration": qa_mode = true
	game.new_game(170930 if qa_mode else 0)
	audio=GameAudio.new()
	add_child(audio)
	town_movement.setup(game)
	dungeon_movement.setup(game)
	for direction in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN]}:
		var action="town_"+direction
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN]}[direction]:
			var binding=InputEventKey.new()
			binding.physical_keycode=key
			InputMap.action_add_event(action,binding)
	map_frame=Control.new()
	map_frame.position=Vector2.ZERO
	map_frame.size=get_viewport_rect().size
	map_frame.clip_contents=true
	map_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(map_frame)
	var field_background=ColorRect.new()
	field_background.name="FieldBackground"
	field_background.z_index=-5
	field_background.color=Color("101c2d")
	field_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field_background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	map_frame.add_child(field_background)
	board = GameBoard.new()
	map_frame.add_child(board)
	board.town_movement=town_movement
	board.setup(game,font)
	board.audio=audio
	field_overlay=FieldOverlay.new()
	field_overlay.board=board
	field_overlay.font=font
	field_overlay.z_index=10
	map_frame.add_child(field_overlay)
	hud = Control.new()
	hud.z_index=10
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	game.changed.connect(schedule_refresh)
	game.message.connect(show_toast)
	game.battle_finished.connect(func(): audio.sfx("victory"))
	get_viewport().size_changed.connect(schedule_refresh)
	refresh()
	if not qa_mode: show_title()
	if qa_mode and not "--integration" in OS.get_cmdline_user_args(): call_deferred("capture_preview")

func box(color: Color, border: Color = Color.TRANSPARENT, width: int = 0, radius: int = 12) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(mini(radius,8))
	if color.a>0.5 and radius>=8:
		s.shadow_color=Color(0.04,0.08,0.16,0.23)
		s.shadow_size=5; s.shadow_offset=Vector2(0,3)
	s.content_margin_left = 12
	s.content_margin_right = 12
	return s

func panel(parent: Node, rect: Rect2, color: Color = PAPER, border: Color = Color("d4d4bc"), radius: int = 12) -> Panel:
	var p = Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel",box(color,border,1,radius))
	parent.add_child(p)
	return p

func label(parent: Node, text: String, pos: Vector2, font_size: int = 18, color: Color = INK, width: float = 0) -> Label:
	var l = Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width>0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size.x = width
	parent.add_child(l)
	return l

func button(parent: Node, text: String, rect: Rect2, callback: Callable, enabled: bool = true, primary: bool = false) -> Button:
	var b = SkillButton.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.disabled = not enabled
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		b.add_theme_stylebox_override("normal",box(GREEN,INK,1,8))
		b.add_theme_color_override("font_color",PAPER)
	b.pressed.connect(func():
		if audio!=null: audio.sfx("ui",true)
		callback.call())
	parent.add_child(b)
	return b

func schedule_refresh() -> void:
	save_timer = 0.8
	if not refresh_queued:
		refresh_queued = true
		call_deferred("refresh")

func refresh() -> void:
	refresh_queued=false
	var viewport=get_viewport_rect().size
	if modal_body!=null and is_instance_valid(modal_body): modal_body.position=(viewport-modal_body.size)*0.5
	map_frame.position=Vector2.ZERO
	map_frame.size=viewport
	board.view_size=viewport
	if game.mode=="battle" and (last_actor!=game.active_id or last_turn_serial!=game.turn_serial or last_mode!="battle"):
		last_actor=game.active_id; last_turn_serial=game.turn_serial
		battle_selection=game.active_id if game.current().faction=="party" else ""
		chosen_skill="move"
		board.recenter()
	if game.mode!="battle": battle_selection=""; last_actor=""; last_turn_serial=-1
	if game.mode!="explore" or (not dungeon_movement.context.is_empty() and dungeon_movement.context!=[game.world.get_instance_id(),game.current().uid]):
		dungeon_movement.cancel(); goal_cell=Vector2i(-1,-1)
	if game.mode=="battle" and chosen_skill!="move" and not game.current().has_skill(chosen_skill): chosen_skill="move"
	board.tactical_selected=battle_selection==game.active_id and game.mode=="battle"
	board.skill=chosen_skill
	town_movement.ensure_positions()
	board.refresh()
	map_frame.get_node("FieldBackground").color=Color("142b3a") if game.world.biome<3 else Color("23213a")
	if frontend==null: audio.sync_state(game)
	if game.mode=="battle" and last_mode!="battle": audio.sfx("battle_start")
	last_mode=game.mode
	# Position-only exploration updates redraw the field, without replacing every HUD node.
	var actor_state=game.current().serialize()
	actor_state.erase("cell"); actor_state.erase("town_position")
	var key=[game.expedition_plan,game.expedition_risk,hash(game.contracts),game.debt,viewport,game.mode,board.map_stamp,game.floor_number,game.combat_room,game.gold,game.potions,game.party.size(),game.pending.size(),actor_state,game.current().cell==game.world.stairs,battle_selection,chosen_skill,game.clock,game.turn_serial,animation_locked,toast_timer>0,game.log_lines.back() if not game.log_lines.is_empty() else ""]
	if game.mode=="battle": key.append(game.timeline().map(func(u): return u.serialize()))
	if hud_key==key: return
	hud_key=key; hud_builds+=1
	for child in hud.get_children(): hud.remove_child(child); child.queue_free()
	var town=game.mode=="town"
	var location="阿德勒自由市" if town else Dungeon.BIOMES[game.world.biome].name
	panel(hud,Rect2(20,18,418,77),Color("1d3345"),Color("799e9e"))
	label(hud,location,Vector2(38,29),27,PAPER)
	label(hud,"安全区 · 自由行走" if town else "第 %d 层 · %s" % [game.floor_number,"房间 %d 战斗" % (game.combat_room+1) if game.mode=="battle" else "自由探索"],Vector2(272 if town else 195,43),12 if town else 14,Color("b2c9cc"))
	label(hud,"金币 %d    药草 %d    伙伴 %d / 4" % [game.gold,game.potions,game.party.size()],Vector2(39,72),13,Color("dfc798"))
	var tracked=[]
	for id in game.contracts:
		var status=game.contracts[id]; var definition=ContractRules.definition(id)
		if status.state in ["accepted","travel","ready"]:
			tracked.append(("清剿 %d/%d"%[status.progress,definition.count] if definition.kind=="kill" else "护送至 2F")+ (" · 待交付" if status.state=="ready" else ""))
	var tracker=button(hud,"债务 %d · %s"%[game.debt," / ".join(tracked) if not tracked.is_empty() else "前往任务栏接取委托"],Rect2(20,101,418,38),func(): MercenaryUI.contracts(self))
	tracker.add_theme_font_size_override("font_size",13); tracker.clip_text=true
	button(hud,"队伍",Rect2(viewport.x-474,23,93,47),show_roster)
	button(hud,"存读档",Rect2(viewport.x-370,23,112,47),func(): show_slots(true))
	button(hud,"声音",Rect2(viewport.x-247,23,93,47),show_audio_settings)
	button(hud,"菜单",Rect2(viewport.x-143,23,119,47),show_pause)
	if not game.expedition_plan.is_empty():
		var tactic=button(hud,"战术："+ExpeditionRules.PLANS[game.expedition_plan].name+(" · 高危" if game.expedition_risk else ""),Rect2(20,193,310,33),func(): ExpeditionUI.inspect(self))
		tactic.add_theme_font_size_override("font_size",14)
	if game.mode=="battle":
		draw_bottom()
		panel(hud,Rect2(viewport.x*0.5-234,104,468,38),Color(0.13,0.2,0.2,0.9))
		label(hud,"回合自动选中 · 点击移动 / 施技 · WASD 镜头 · C 回正",Vector2(viewport.x*0.5-219,114),14,PAPER)
	else:
		var u=game.current()
		var y=viewport.y-177
		panel(hud,Rect2(20,y,350,138),Color("1d3345"),Color("799e9e"))
		var portrait=Control.new(); hud.add_child(portrait)
		portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
		portrait.draw.connect(func(): CreatureArt.draw(portrait,u,Vector2(64,y+53),1.25))
		label(hud,"%s  Lv.%d" % [u.display_name,u.level],Vector2(105,y+18),21,PAPER)
		label(hud,"HP %d/%d · %s" % [u.hp,u.max_hp(),MercenaryRules.JOBS[u.profession]],Vector2(105,y+52),14,Color("b2c9cc"))
		button(hud,"技能 / 配招",Rect2(34,y+88,151,35),func(): show_skills(u))
		button(hud,"成长 / 培养",Rect2(195,y+88,157,35),func(): ProgressionUI.training(self,u))
		var x=viewport.x-277
		panel(hud,Rect2(x,viewport.y-224,253,184),Color("1d3345"),Color("799e9e"))
		if town:
			button(hud,"任务栏 / 贷款",Rect2(x+14,viewport.y-210,224,49),func(): MercenaryUI.contracts(self),true,true)
			button(hud,"出征",Rect2(x+14,viewport.y-151,106,43),show_expeditions)
			button(hud,"营舍",Rect2(x+131,viewport.y-151,107,43),show_home)
		else:
			button(hud,"回到城镇",Rect2(x+14,viewport.y-210,224,43),retreat)
			button(hud,"药草 [Q]",Rect2(x+14,viewport.y-155,106,42),use_potion)
			button(hud,"下楼 [E]",Rect2(x+130,viewport.y-155,108,42),descend,game.current().cell==game.world.stairs)
		button(hud,"待签约佣兵 %d" % game.pending.size() if not game.pending.is_empty() else ("家系 / 遗传" if town else "委托进度"),Rect2(x+14,viewport.y-96,224,42),show_recruitment if not game.pending.is_empty() else (show_nursery if town else func(): MercenaryUI.contracts(self)))
		panel(hud,Rect2(viewport.x*0.5-295,viewport.y-29,590,24),Color(0.12,0.22,0.19,0.85))
		label(hud,"WASD 自由行走 · 点击绕障 · E 设施 · F1 手册" if town else "WASD 探索移动 · 进入敌人房间开战 · Tab 总览 · G 格线",Vector2(viewport.x*0.5-278,viewport.y-26),12,PAPER)
	toast=label(hud,"",Vector2(40,156),15,PAPER,minf(980,viewport.x-80))
	if toast_timer>0 and not game.log_lines.is_empty():
		panel(hud,Rect2(27,150,minf(1000,viewport.x-54),35),Color(0.13,0.23,0.2,0.9),Color.TRANSPARENT,7)
		hud.move_child(toast,-1); toast.text=game.log_lines[-1]

func hud_blocks_point(p: Vector2) -> bool:
	var viewport=get_viewport_rect().size
	if Rect2(20,18,418,121).has_point(p) or Rect2(viewport.x-474,18,454,58).has_point(p): return true
	if game.mode=="battle": return Rect2(viewport.x*0.5-692,viewport.y-226,1384,218).has_point(p) or Rect2(viewport.x*0.5-234,104,468,38).has_point(p)
	return Rect2(20,viewport.y-177,350,138).has_point(p) or Rect2(viewport.x-277,viewport.y-224,253,184).has_point(p)

func draw_party_card(u: UnitData, index: int) -> void:
	var y = 150+index*111
	var active = game.current()==u
	var p = panel(hud,Rect2(1090,y,322,100),Color("f8f2df") if active else Color("eae8d7"),GREEN if active else Color("d4d4bc"))
	var portrait = Control.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(portrait)
	portrait.draw.connect(func(): CreatureArt.draw(portrait,u,Vector2(42,48),1.05))
	label(p,"%s   Lv.%d" % [u.display_name,u.level],Vector2(81,12),18)
	label(p,Bloodline.compact(u.bloodline),Vector2(82,42),11,MUTED)
	panel(p,Rect2(82,70,163,7),Color("d3d7bc"),Color.TRANSPARENT,3)
	panel(p,Rect2(82,70,maxf(1,163*float(u.hp)/u.max_hp()),7),GREEN if u.alive() else AMBER,Color.TRANSPARENT,3)
	label(p,"%d/%d" % [u.hp,u.max_hp()],Vector2(250,62),12,MUTED)
	button(p,"档案",Rect2(248,10,61,31),func(): show_unit(u))
	var select_button = button(p,"%d" % (index+1),Rect2(8,70,31,24),func(): game.select_unit(index),game.mode!="battle" and u.alive())
	select_button.add_theme_font_size_override("font_size",12)

func action_keys() -> Array:
	return ["move"]+game.current().carried_skills()

func draw_bottom() -> void:
	var origin=Vector2(get_viewport_rect().size.x*0.5-692,get_viewport_rect().size.y-226)
	var dock=Control.new(); dock.position=origin; dock.mouse_filter=Control.MOUSE_FILTER_IGNORE; hud.add_child(dock)
	combat_ui=CombatHUD.new(); combat_ui.app=self; combat_ui.size=Vector2(1384,205); combat_ui.mouse_filter=Control.MOUSE_FILTER_IGNORE; dock.add_child(combat_ui)
	var actor=game.current()
	var can_act=actor.faction=="party" and not board.is_animating()
	button(dock,"档案 / 技能",Rect2(17,170,133,27),func(): show_skills(actor))
	button(dock,"药草 [Q]",Rect2(157,170,125,27),use_potion,actor.faction=="party" and game.potions>0 and actor.hp<actor.max_hp() and actor.ap>=20)
	var keys=action_keys()
	var selected=battle_selection==actor.uid
	for i in range(keys.size()):
		var id: String=keys[i]
		var cost=8 if id=="move" else GameState.SKILLS[id].cost
		var title="移动" if id=="move" else GameState.SKILLS[id].name
		if id!="move" and actor.cooldown(id)>0: title+=" [冷却%d]" % actor.cooldown(id)
		var b=button(dock,"%d  %s\n%d AP%s" % [i+1,title,cost," / 格" if id=="move" else ""],Rect2(320+i*166,126,158,53),func(): set_skill(id),can_act and selected and actor.ap>=cost and (id!="move" or not actor.moved) and (id=="move" or actor.cooldown(id)==0),chosen_skill==id and selected)
		b.add_theme_font_size_override("font_size",14)
		b.tooltip_text="移动详情" if id=="move" else GameState.SKILLS[id].name
		b.skill_id=id; b.actor=actor; b.game=game
	button(dock,"结束行动\n[空格]",Rect2(1160,126,224,53),end_turn,can_act,true)
	panel(dock,Rect2(320,187,1064,25),Color(0.13,0.2,0.2,0.91))
	label(dock,("点击 %s 恢复选择" % actor.display_name if actor.faction=="party" else "敌方正在行动") if not selected else ("本轮已移动 · 选择技能攻击 / 辅助，或结束行动" if actor.moved else "蓝色：快速回归  /  橙色斜线：行动延后 · 点击目标格移动 · 右键取消"),Vector2(335,192),13,PAPER)

func show_toast(text: String) -> void:
	if audio!=null:
		if "升至 Lv." in text: audio.sfx("level_up")
		elif "加入远征队" in text or "已安全送回家园" in text: audio.sfx("recruit")
	toast_timer = 5.0
	if toast != null and is_instance_valid(toast): toast.text = text
	schedule_refresh()

func set_skill(skill: String) -> void:
	if game.mode=="battle" and (game.current().faction!="party" or not skill in action_keys()): return
	if game.mode=="battle": battle_selection=game.active_id
	chosen_skill = skill
	goal_cell = Vector2i(-1,-1)
	town_movement.cancel()
	refresh()

func _process(delta: float) -> void:
	if game==null or frontend!=null: return
	var locked=game.mode=="battle" and board.is_animating()
	if animation_locked!=locked:
		animation_locked=locked
		schedule_refresh()
	if toast_timer>0:
		toast_timer -= delta
		if toast_timer<=0: schedule_refresh()
	if save_timer>=0:
		save_timer -= delta
		if save_timer<0 and not qa_mode:
			if active_slot>0 and not SaveSlots.write(game,active_slot) and not game.save_blocked: game.note(game.last_error)
	if modal != null:
		dungeon_movement.cancel(); goal_cell=Vector2i(-1,-1)
		return
	if game.mode=="town":
		var direction=Input.get_vector("town_left","town_right","town_up","town_down")
		if town_movement.update(delta,direction) and save_timer<0: save_timer=0.8
	elif game.mode=="battle":
		board.pan_camera(Input.get_vector("town_left","town_right","town_up","town_down"),delta)
		town_movement.cancel()
		goal_cell = Vector2i(-1,-1)
		dungeon_movement.cancel()
		if board.is_animating(): return
		if game.current()!=null and game.current().faction=="enemy":
			ai_timer += delta
			if ai_timer>0.85:
				ai_timer = 0.0
				game.enemy_turn()
		else: ai_timer = 0.0
	elif game.mode=="explore":
		goal_cell=dungeon_movement.update(delta,Input.get_vector("town_left","town_right","town_up","town_down"),goal_cell)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F11:
		toggle_fullscreen()
		return
	if frontend!=null:
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: close_modal()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE:
			if modal!=null: close_modal()
			elif game.mode=="battle": battle_selection=""; refresh()
			else: show_pause()
			goal_cell = Vector2i(-1,-1)
			return
		if modal != null: return
		if game.mode!="town" and event.keycode==KEY_TAB: board.toggle_overview(); return
		if game.mode!="town" and event.keycode==KEY_G: board.show_grid=not board.show_grid; return
		if game.mode=="battle" and board.is_animating(): return
		if event.keycode==KEY_C: board.recenter(); return
		if event.keycode==KEY_F1: show_help(); return
		if event.keycode==KEY_Q: use_potion(); return
		if event.keycode==KEY_SPACE and game.mode=="battle": end_turn(); return
		if event.keycode==KEY_E:
			if game.mode=="town": interact_town()
			else: descend()
			return
		if event.keycode>=KEY_1 and event.keycode<=KEY_6:
			var index = event.keycode-KEY_1
			if game.mode=="battle":
				if index<action_keys().size() and battle_selection==game.active_id: set_skill(action_keys()[index])
			else: game.select_unit(index)
			return
		var directions = {KEY_W:Vector2i.UP,KEY_UP:Vector2i.UP,KEY_S:Vector2i.DOWN,KEY_DOWN:Vector2i.DOWN,KEY_A:Vector2i.LEFT,KEY_LEFT:Vector2i.LEFT,KEY_D:Vector2i.RIGHT,KEY_RIGHT:Vector2i.RIGHT}
		if event.keycode in directions:
			if game.mode in ["town","battle"]: return # Held keys move town actors or battle camera.
			goal_cell = Vector2i(-1,-1)
			# The process loop polls held input; key-repeat cannot issue extra moves.
			return
	if event is InputEventMouseButton and event.pressed:
		if modal!=null: return
		if event.button_index==MOUSE_BUTTON_RIGHT:
			if game.mode=="battle": battle_selection=""; chosen_skill="move"; refresh()
			else: set_skill("move")
			return
		var view_point=map_frame.get_local_mouse_position()
		if not Rect2(Vector2.ZERO,map_frame.size).has_point(view_point): return
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			board.change_zoom(0.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -0.15)
			return
		if event.button_index!=MOUSE_BUTTON_LEFT or field_overlay.consumes_point(view_point) or hud_blocks_point(view_point): return
		var local = board.get_local_mouse_position()
		if not Rect2(0,0,1040,640).has_point(local): return
		var p = Vector2i(floori(local.x/40),floori(local.y/40))
		if game.mode=="town":
			if Rect2(112,77,176,205).has_point(local): show_home(); return
			if Rect2(672,77,176,205).has_point(local): show_shop(); return
			if Rect2(112,357,176,205).has_point(local): show_nursery(); return
			if Rect2(672,357,176,205).has_point(local): show_storage(); return
			if Rect2(436,65,168,90).has_point(local): show_expeditions(); return
			for ally in game.party:
				if ally.town_position.distance_to(local)<24: game.select_unit(game.party.find(ally)); return
			if not town_movement.go_to(local): game.note("那里无法落脚，换一处空地试试。")
			return
		if not board.visible_cells.has(p): return
		if game.mode=="battle":
			if board.is_animating(): return
			if game.current().faction!="party": return
			battle_click(p)
		else:
			var u = game.unit_at(p)
			if u!=null and u in game.party: game.select_unit(game.party.find(u)); return
			if game.world.walkable(p): goal_cell = p

func end_turn() -> void:
	if game.mode=="battle" and game.current().faction=="party" and not board.is_animating():
		chosen_skill = "move"
		game.end_turn()

func interact_town() -> void:
	match town_movement.nearby_door():
		"home": show_home()
		"shop": show_shop()
		"nursery": show_nursery()
		"storage": show_storage()
		"expeditions": show_expeditions()
		"contracts": MercenaryUI.contracts(self)
		_: game.note("走近营舍、商铺、家系馆、仓库、任务栏或出征路牌，再按 E 互动。")

func descend() -> void:
	goal_cell = Vector2i(-1,-1)
	game.descend()

func retreat() -> void:
	goal_cell = Vector2i(-1,-1)
	if game.mode=="battle":
		open_modal("紧急撤离","伙伴会全部获救，遗失随身金币的 10%。仓库内财物安全。")
		button(modal_body,"确认撤离",Rect2(30,180,250,54),func(): close_modal(); game.retreat(),true,true)
	else: game.retreat()

func use_potion() -> void:
	if not game.use_potion(game.current()): game.note("药草需用于受伤且未倒下的当前伙伴；战斗时消耗 20 AP。")
	else: audio.sfx("heal")

func manual_save() -> void:
	if active_slot>0 and SaveSlots.write(game,active_slot): audio.sfx("save"); game.note("旅途已保存到存档 %d。" % active_slot)
	else: show_toast(game.last_error)

func close_modal() -> void:
	town_movement.cancel()
	if modal!=null:
		remove_child(modal)
		modal.queue_free()
		modal = null
	goal_cell = Vector2i(-1,-1)

func open_modal(title: String, subtitle: String) -> void:
	close_modal()
	modal = Control.new()
	modal.z_index=100
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var shade = ColorRect.new()
	shade.color = Color(0.13,0.22,0.17,0.63)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	modal_body = panel(modal,Rect2((get_viewport_rect().size-Vector2(1066,772))*0.5,Vector2(1066,772)),PAPER,INK,18)
	modal_body.mouse_filter = Control.MOUSE_FILTER_STOP
	label(modal_body,title,Vector2(32,23),30)
	label(modal_body,subtitle,Vector2(33,71),15,MUTED,970)
	button(modal_body,"返回  Esc",Rect2(898,24,134,42),close_modal)

func show_expeditions() -> void:
	open_modal("五域远征 · 通行徽记","依次挑战三层迷宫与终点守望者。击败守望者并抵达楼梯，才能解锁下一区域。")
	for i in range(5):
		var data=Dungeon.BIOMES[i]
		var unlocked=game.dungeon_unlocked(i)
		var y=124+i*121
		panel(modal_body,Rect2(30,y,1006,109),Color(data.floor).lightened(0.35) if unlocked else Color("d1d3c9"),Color(data.wall))
		var tex=TextureRect.new()
		var source=load("res://assets/art_v7/title.png")
		var thumbnail=AtlasTexture.new(); thumbnail.atlas=source
		var regions=[Rect2(0.0,0.3,0.33,0.44),Rect2(0.39,0.0,0.40,0.42),Rect2(0.27,0.29,0.40,0.39),Rect2(0.72,0.0,0.28,0.40),Rect2(0.70,0.30,0.30,0.42)]
		thumbnail.region=Rect2(regions[i].position*source.get_size(),regions[i].size*source.get_size())
		tex.texture=thumbnail
		tex.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; tex.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.position=Vector2(38,y+8); tex.size=Vector2(206,93); tex.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tex.modulate=Color.WHITE if unlocked else Color("6f7b77")
		modal_body.add_child(tex)
		label(modal_body,"0%d  %s" % [i+1,data.name],Vector2(267,y+10),24)
		label(modal_body,BattleRules.WEATHER[i],Vector2(269,y+44),14,GREEN)
		label(modal_body,("已获徽记 · 可再次远征" if i in game.cleared else ("推荐 Lv.%d—%d · 三层守望者" % [1+i*3,5+i*3] if unlocked else "解锁条件：完成 "+Dungeon.BIOMES[i-1].name)),Vector2(269,y+74),14,MUTED)
		button(modal_body,"进入  →" if unlocked else "尚未解锁",Rect2(849,y+31,171,48),func(): ExpeditionUI.open(self,i),game.mode=="town" and game.pending.is_empty() and unlocked,unlocked)
	label(modal_body,"招募徽记：首通森林 +5%，首通海岛升级至 +15%（不叠加）。",Vector2(36,736),14,MUTED)

func roster_scroll(top: int = 184) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(30,top)
	scroll.size = Vector2(1006,550-(top-184))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_body.add_child(scroll)
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation",10)
	scroll.add_child(v)
	return v

func show_home() -> void:
	open_modal("每一位伙伴，都有一个家","家园床位包含出征中的伙伴。队伍最多 4 人；主角保留为队长，其余伙伴可自由换队。")
	label(modal_body,"床位  %d / %d    ·    远征队 %d / 4" % [game.roster_size(),game.capacity,game.party.size()],Vector2(33,123),20)
	button(modal_body,"扩容 +4 床位  /  %d 金币" % game.expand_cost(),Rect2(710,117,324,47),func(): game.expand_home(); show_home(),game.mode=="town" and game.gold>=game.expand_cost(),true)
	var list = roster_scroll()
	for u in game.party+game.home:
		var row = Panel.new()
		row.custom_minimum_size = Vector2(977,91)
		row.add_theme_stylebox_override("panel",box(Color("e8e7d4"),Color("d4d5bc"),1,9))
		list.add_child(row)
		var portrait = Control.new()
		row.add_child(portrait)
		portrait.draw.connect(func(): CreatureArt.draw(portrait,u,Vector2(45,46),1.05))
		label(row,u.display_name+"  /  "+Bloodline.compact(u.bloodline),Vector2(91,12),19)
		label(row,"%s · Lv.%d · 第 %d 代 · %s" % ["出征中" if u in game.party else "在家休息",u.level,u.generation,Genome.body_name(u.genes)],Vector2(91,47),14,MUTED)
		button(row,"基因档案",Rect2(663,22,132,44),func(): show_unit(u))
		var is_party = u in game.party
		button(row,"留在家园" if is_party else "加入远征队",Rect2(810,22,159,44),func():
			if is_party: game.send_home(u)
			else: game.add_to_party(u)
			show_home(),game.mode=="town" and (u!=game.party[0] if is_party else game.party.size()<4))

func show_shop() -> void:
	open_modal("旅行商店","花一点时间准备，下一段旅途就会轻松一些。")
	label(modal_body,"随身金币 %d    ·    药草 %d" % [game.gold,game.potions],Vector2(34,133),21)
	panel(modal_body,Rect2(32,193,1000,180),Color("e6e7d0"))
	label(modal_body,"一束新鲜药草",Vector2(62,220),27)
	label(modal_body,"恢复 40 点生命；探索时可随时使用。\n战斗中由当前行动者使用，消耗 20 AP。",Vector2(63,269),18,MUTED)
	button(modal_body,"购买  /  20 金币",Rect2(742,252,252,56),func(): game.buy_potion(); show_shop(),game.mode=="town" and game.gold>=20,true)
	label(modal_body,"店主的话：\n\n受伤的伙伴可以回镇免费休息。\n别忘了把多余的金币存进仓库，失败撤离时就不会遗失。",Vector2(60,440),20,MUTED)

func show_storage() -> void:
	open_modal("安心仓库","存放的金币和药草不会因远征失败而丢失。每次存取 50 金币或 1 份药草。")
	for i in range(2):
		var y = 164+i*222
		var item = "gold" if i==0 else "potion"
		panel(modal_body,Rect2(32,y,1000,186),Color("e6e7d2"))
		label(modal_body,"金币" if i==0 else "药草",Vector2(59,y+20),28)
		label(modal_body,"随身  %d        仓库  %d" % [game.gold if i==0 else game.potions,game.stored_gold if i==0 else game.stored_potions],Vector2(60,y+78),23)
		button(modal_body,"存入",Rect2(664,y+64,151,54),func(): game.transfer(item,true); show_storage(),game.mode=="town" and (game.gold>=50 if i==0 else game.potions>0))
		button(modal_body,"取出",Rect2(833,y+64,151,54),func(): game.transfer(item,false); show_storage(),game.mode=="town" and (game.stored_gold>=50 if i==0 else game.stored_potions>0),true)

func show_nursery() -> void:
	open_modal("家系馆 · 后裔推演","模拟两位成年佣兵的下一代，时间快进至成年后登记入团。后裔各继承双亲一份等位基因；职业不遗传。")
	var roster = game.party+game.home
	label(modal_body,"亲本 A",Vector2(45,153),21)
	label(modal_body,"亲本 B",Vector2(560,153),21)
	var a = OptionButton.new()
	var b = OptionButton.new()
	for field in [a,b]:
		field.position = Vector2(44 if field==a else 558,203)
		field.size = Vector2(450,52)
		for u in roster: field.add_item(u.display_name+"  /  "+Bloodline.compact(u.bloodline)+"  /  "+Genome.body_name(u.genes))
		modal_body.add_child(field)
	b.select(mini(1,roster.size()-1))
	var report = label(modal_body,"",Vector2(47,294),20,INK,957)
	report.autowrap_mode=TextServer.AUTOWRAP_ARBITRARY
	var update = func(_index = 0):
		var ua: UnitData = roster[a.selected]
		var ub: UnitData = roster[b.selected]
		var valid = ua!=ub
		report.add_theme_font_size_override("font_size",17)
		report.text = "配对%s\n\n%s × %s\n\nA 技能：%s\nB 技能：%s\n\n预期后裔血统：%s\n血统各取双亲的一半；共用基因独立重组，多种特征可同时表达。\n隐性携带可能在后代表达，每个等位基因有 2.5%% 变异概率。\n费用 60 金币；需要 1 个空床位。\n当前床位 %d / %d  ·  金币 %d" % ["可用（近亲关系会在提交时校验）" if valid else "不可用：请选择两位不同家系的成年佣兵",ua.display_name,ub.display_name,GeneSkills.summary(ua.genes),GeneSkills.summary(ub.genes),Bloodline.summary(Bloodline.inherit(ua.bloodline,ub.bloodline)),game.roster_size(),game.capacity,game.gold]
	a.item_selected.connect(update)
	b.item_selected.connect(update)
	update.call()
	button(modal_body,"推演成年后裔  /  60 金币",Rect2(589,644,417,57),func():
		var baby = game.breed(roster[a.selected],roster[b.selected])
		if baby!=null: show_unit(baby)
		else: report.text="暂时无法完成家系推演。\n请检查：不同个体、无亲子/同胞关系、金币 ≥60、家园有空床位。",game.mode=="town" and game.gold>=60 and game.roster_size()<game.capacity,true)

func show_unit(u: UnitData) -> void:
	open_modal(u.display_name+"的基因手记","外表、体态与能力，都藏在双亲留下的基因里。每一位伙伴，都有独一无二的生命故事。")
	preview_unit = u
	var art = Control.new()
	modal_body.add_child(art)
	art.draw.connect(func(): CreatureArt.draw(art,u,Vector2(188,293),3.1))
	label(modal_body,MercenaryRules.JOBS[u.profession],Vector2(54,347),24)
	label(modal_body,Bloodline.compact(u.bloodline),Vector2(51,384),15,MUTED,308)
	label(modal_body,"Lv.%d   ·   第 %d 代\n生命 %d/%d\n攻击 %d / 防御 %d / 速度 %d\n经验 %d / %d\n\n变异位点：%s" % [u.level,u.generation,u.hp,u.max_hp(),u.attack(),u.defense(),u.speed(),u.xp,u.level*25,"无" if u.mutations.is_empty() else ", ".join(u.mutations)],Vector2(51,450),16,MUTED,308)
	label(modal_body,"共用基因位点",Vector2(400,131),17)
	label(modal_body,"双亲等位基因",Vector2(727,131),17)
	label(modal_body,"表达值",Vector2(938,131),17)
	var scroll=ScrollContainer.new(); scroll.position=Vector2(394,170); scroll.size=Vector2(634,499); modal_body.add_child(scroll)
	var table=Control.new(); table.custom_minimum_size=Vector2(608,Genome.LIMITS.size()*27); scroll.add_child(table)
	var names = GeneTraits.NAMES.values()
	var i = 0
	for locus in Genome.LIMITS:
		var y = i*27
		if i%2==0: panel(table,Rect2(0,y,608,27),Color("e6e6d3"),Color.TRANSPARENT,2)
		label(table,names[i]+" / "+locus,Vector2(12,y),14)
		label(table,"%s | %s" % [u.genes[locus][0],u.genes[locus][1]],Vector2(333,y),14,MUTED)
		label(table,str(Genome.express(u.genes,locus)),Vector2(544,y),14)
		i += 1
	button(modal_body,"血统比例与共用基因",Rect2(47,600,290,41),func(): BloodlineUI.open(self,u))
	button(modal_body,"查看遗传技能池 →",Rect2(47,652,290,48),func(): show_skills(u),true,true)
	button(modal_body,"转职 / 职业训练",Rect2(47,708,290,39),func(): MercenaryUI.professions(self,u))
	label(modal_body,"护照 ID  "+u.uid+"\n父母 ID  "+("始祖谱系" if u.parents.is_empty() else "  /  ".join(u.parents)),Vector2(403,683),12,MUTED,617)

func show_skills(u: UnitData) -> void:
	ProgressionUI.skills(self,u)

func show_recruitment() -> void:
	open_modal("一段新羁绊","愿意投诚的落败佣兵可以签约。队伍满 4 人时，最后加入的伙伴送回家；床位满时可保留邀请、回镇扩容。")
	var list = roster_scroll(128)
	if game.pending.is_empty(): label(modal_body,"所有邀请已处理。准备好后继续远征吧！",Vector2(42,155),23); return
	for u in game.pending:
		var row = Panel.new()
		row.custom_minimum_size = Vector2(977,109)
		row.add_theme_stylebox_override("panel",box(Color("e6e6d0"),Color("c3c8ac"),1,9))
		list.add_child(row)
		label(row,u.display_name+" / "+Genome.body_name(u.genes)+" · %.1f%% 成功" % u.last_recruit_rate,Vector2(25,18),21)
		label(row,"将加入远征队" if game.party.size()<4 else "队伍已满，将送回家园",Vector2(26,57),15,MUTED)
		button(row,"档案",Rect2(517,30,110,46),func(): show_unit(u))
		button(row,"道别",Rect2(643,30,130,46),func(): game.release_candidate(u); show_recruitment())
		button(row,"邀请同行",Rect2(788,30,177,46),func(): game.recruit(u); show_recruitment(),game.roster_size()<game.capacity,true)

func show_help() -> void:
	open_modal("旅人手册","探索、战斗、相遇，然后一起回家。")
	button(modal_body,"战术 / 招募图鉴",Rect2(670,24,211,42),func(): ProgressionUI.tactics(self))
	var sections = [
		["01  自由探索","家园按住 WASD / 方向键自由行走，可斜向移动；点击地面自动绕障，靠近设施按 E。地下城长按方向键连续逐格行走，点击地面沿路线前进；1—4 切换领队，进入敌人所在房间开战。"],
		["02  时间轴与出征战术","每次行动 100 AP，移动每格 8 AP；超过 50 AP 回归更慢。出征可选协同追击、轻装轮替或破阵强攻；悬停目标查看额外伤害与延时。敌人身旁「协」表示可由另一位队友接力。空格结束行动。"],
		["03  技能与目标","我方回合自动选中角色，点击蓝色 / 橙色目标格移动（每轮一次）。橙色斜线表示累计消耗超过 50 AP，将延后行动；悬停预览具体时间。WASD 移动镜头，C 回正；2—5 选择技能，再点击目标。"],
		["04  队伍与家园","战斗结束点击「待邀请伙伴」。队伍最多 4 人，溢出的新伙伴送回家。所有已拥有伙伴都占一个床位；满员时先回家扩容。到家系馆推演成年后裔，在职业教官处调整培养方向。"],
		["05  视野与归途","镜头跟随当前伙伴，滚轮缩放、Tab 战术总览、G 显示格线；小地图记录已探索区域。阶梯格按 E 下楼，共 3 层。探索可免费回镇；战斗撤离损失 10% 随身金币，全灭损失 20%。"]
	]
	for i in range(sections.size()):
		var y = 129+i*118
		label(modal_body,sections[i][0],Vector2(35,y),22)
		label(modal_body,sections[i][1],Vector2(37,y+38),17,MUTED,970)

func show_journal() -> void:
	open_modal("旅途记录","把每一次相遇，写进这本小小的手记。")
	var list = roster_scroll(127)
	for i in range(game.log_lines.size()-1,-1,-1):
		var l = Label.new()
		l.text = "·  "+game.log_lines[i]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(960,38)
		l.add_theme_font_size_override("font_size",17)
		list.add_child(l)

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST: quit_game()

func quit_game() -> void:
	if game!=null and not qa_mode and active_slot>0 and not SaveSlots.write(game,active_slot):
		show_toast("保存失败，请重试后再关闭游戏。")
		return
	if audio!=null: audio.shutdown()
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()

func battle_click(cell: Vector2i) -> void:
	if game.mode!="battle" or game.current().faction!="party" or board.is_animating(): return
	var actor=game.current()
	var target=game.unit_at(cell)
	if target==actor and (battle_selection!=actor.uid or chosen_skill=="move"):
		battle_selection=actor.uid; chosen_skill="move"; audio.sfx("ui"); refresh(); return
	if battle_selection!=actor.uid:
		game.note("请先点击正在行动的 %s。" % actor.display_name)
		return
	if chosen_skill=="move":
		if game.move_to(cell):
			chosen_skill="move"
		else: game.note("请选择蓝色或橙色范围内的空格；橙色移动会延后行动，每轮仅可移动一次。")
	elif not game.cast(chosen_skill,target): game.note("目标无效：请检查射程、阵营、AP、异常状态和技能冷却。")

func show_roster() -> void:
	open_modal("远征伙伴","点击角色档案查看基因，调整技能，或安排后天训练。")
	var list=roster_scroll(130)
	for u in game.party+game.home:
		var row=Panel.new(); row.custom_minimum_size=Vector2(977,119); row.add_theme_stylebox_override("panel",box(Color("e5e7d1"))); list.add_child(row)
		label(row,"%s · Lv.%d · %s" % [u.display_name,u.level,Genome.body_name(u.genes)],Vector2(20,16),23)
		label(row,"HP %d/%d · 努力值 %d/192 · %s" % [u.hp,u.max_hp(),u.total_effort(),"出征中" if u in game.party else "在家休息"],Vector2(21,62),16,MUTED)
		button(row,"基因",Rect2(563,34,118,44),func(): show_unit(u))
		button(row,"技能配招",Rect2(691,34,127,44),func(): show_skills(u))
		button(row,"成长培养",Rect2(828,34,129,44),func(): ProgressionUI.training(self,u))

func show_audio_settings() -> void:
	open_modal("声音设置","明亮的木管、轻巧的拨弦与钟琴，为每一次出发伴奏。")
	for i in range(2):
		var y=178+i*139
		label(modal_body,"背景音乐" if i==0 else "动作与界面音效",Vector2(46,y),25)
		var slider=HSlider.new(); slider.position=Vector2(47,y+60); slider.size=Vector2(943,34); slider.min_value=0; slider.max_value=100; slider.step=1
		slider.value=(audio.music_volume if i==0 else audio.effects_volume)*100
		modal_body.add_child(slider)
		slider.value_changed.connect(func(value):
			if i==0: audio.music_volume=value/100.0
			else: audio.effects_volume=value/100.0
			audio.save_settings())
	button(modal_body,"取消静音" if audio.muted else "全部静音",Rect2(46,524,300,58),func(): audio.muted=not audio.muted; audio.save_settings(); show_audio_settings())
	button(modal_body,"试听音效",Rect2(369,524,267,58),func(): audio.sfx("heal"))
	label(modal_body,"8 段原创循环乐曲 · 12 种动作音效\n场景切换时音乐会平滑过渡，音量设置自动保存。",Vector2(48,649),18,MUTED)

func show_pause() -> void:
	open_modal("旅途菜单","休息片刻，再继续向前。")
	button(modal_body,"全屏 / 窗口 [F11]",Rect2(759,113,270,42),toggle_fullscreen)
	button(modal_body,"继续游戏",Rect2(320,175,420,62),close_modal,true,true)
	button(modal_body,"保存当前旅途",Rect2(320,255,420,57),func(): manual_save(); close_modal(),active_slot>0)
	button(modal_body,"存读档 / 另存",Rect2(320,330,420,57),func(): close_modal(); show_slots())
	button(modal_body,"基因图鉴",Rect2(320,405,420,57),func(): ProgressionUI.codex(self))
	button(modal_body,"回到标题",Rect2(320,480,420,57),func():
		close_modal(); show_title())
	if game.mode!="town": button(modal_body,"紧急撤离" if game.mode=="battle" else "回到城镇",Rect2(320,555,420,57),func(): close_modal(); retreat())
	button(modal_body,"旅人手册",Rect2(320,630,420,57),show_help)

func show_title() -> void:
	if frontend==null and active_slot>0 and not qa_mode and not SaveSlots.write(game,active_slot):
		show_toast("保存失败，请重试后再离开当前旅途。")
		return
	close_modal()
	town_movement.cancel()
	goal_cell=Vector2i(-1,-1)
	if frontend==null:
		frontend=FrontEnd.new(); frontend.app=self; add_child(frontend)
	else: frontend.show_title()
	board.set_process(false)
	hud.hide()

func toggle_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func show_slots(for_save: bool=false) -> void:
	show_title()
	if frontend!=null: frontend.show_slots(for_save)

func close_frontend() -> void:
	if frontend!=null: remove_child(frontend); frontend.queue_free(); frontend=null
	board.set_process(true)
	hud.show()
	refresh()

func create_slot(slot: int, result: Dictionary, hero_name: String) -> void:
	if result.is_empty() or SaveSlots.info(slot).exists: return
	game.new_game(int(result.seed))
	game.party[0].display_name=hero_name if not hero_name.is_empty() else "阿德勒"
	game.party[0].genes=result.genes.duplicate(true)
	game.party[0].bloodline=result.get("bloodline",Bloodline.pure(0)).duplicate()
	game.party[0].profession=int(result.get("profession",0))
	game.party[0].equipped_skills.clear(); game.party[0].ensure_loadout(); game.party[0].heal()
	game.origin_profile=result.profile; game.quiz_answers=result.answers.duplicate()
	if not SaveSlots.write(game,slot): game.note("无法创建存档，请重试。"); return
	active_slot=slot
	board.map_stamp=""
	close_frontend()
	audio.sfx("recruit")
	game.note("%s与莉泽完成了佣兵登记。前往任务栏接取工作，赚取佣金偿还继承的债务。" % game.party[0].display_name)

func load_slot(slot: int) -> void:
	if not game.load_game(SaveSlots.path(slot)):
		show_toast(game.last_error); return
	active_slot=slot
	goal_cell=Vector2i(-1,-1); battle_selection=""; last_actor=""; board.map_stamp=""
	close_frontend()
	audio.sfx("save")

func capture_preview() -> void:
	var path = "res://screenshots/town.png"
	var scene = "town"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): path=arg.trim_prefix("--capture=")
		if arg.begins_with("--preview="): scene=arg.trim_prefix("--preview=")
	if scene=="escort": ContractRules.accept(game,"escort_0")
	if scene in ["escort","forest","mountain","island","volcano","cave","battle","battle_burst","battle_move","battle_tooltip","animation","relay_combo","burst_plan"]:
		game.cleared=[0,1,2,3,4] # QA scene selection only; real new games remain locked.
		game.enter_dungeon(maxi(0,["forest","mountain","island","volcano","cave"].find(scene)),"relay" if scene=="relay_combo" else ("burst" if scene=="burst_plan" else ""))
		if scene in ["escort","battle","battle_burst","battle_move","battle_tooltip","animation","relay_combo","burst_plan"]:
			var e = game.enemies[0]
			var spots = game.world.reachable(e.cell,2).keys()
			spots.erase(e.cell)
			spots=spots.filter(func(p): return game.world.room_at(p)==game.world.room_at(e.cell) and game.unit_at(p)==null)
			for i in range(game.party.size()): game.party[i].cell=spots[i]
			game.start_battle(game.world.room_at(e.cell))
			while game.current().faction=="enemy": game.enemy_turn()
			if scene in ["battle_burst","battle_tooltip"]:
				var actor=game.current()
				actor.genes.body_a=[1,1]; actor.genes.body_b=[1,1]
				actor.equipped_skills.clear(); actor.ensure_loadout()
				actor.ap=60; actor.spent=40
				chosen_skill="delay"
	set_process(false)
	refresh()
	if game.mode=="battle": battle_selection=game.active_id; refresh()
	if scene in ["relay_combo","burst_plan"]:
		var target=game.enemies[0]
		Genome.seed_traits(target.genes,Bloodline.pure(3)); target.genes.gloss=[0,0]; target.genes.affinity=[60,60]; target.genes.pattern=[2,2]; target.genes.coat=[0,0]; target.heal()
		for member in game.party:
			member.genes.body_a=[1,1]; member.genes.body_b=[1,1]; member.equipped_skills.assign(["delay"])
		game.active_id=game.party[0].uid
		if scene=="relay_combo":
			game.cast("delay",target); game.active_id=game.party[1].uid
		else: game.current().spent=40; game.current().ap=60
		refresh(); chosen_skill="delay"; refresh()
		for i in range(240): board._process(1.0/60)
		hud_key.clear() # QA freezes the app loop; rebuild controls after settling the cast.
		refresh()
		board.set_process(false)
		board.hover=target.cell; board.pointer_screen=board.to_global(board.center(target.cell))
		combat_ui.queue_redraw()
		print("TACTIC_PREVIEW ",game.predict("delay",target))
	if scene in ["battle_move","battle_tooltip"]:
		board._process(0.016); board.set_process(false)
		var preview_point=Vector2.ZERO
		if scene=="battle_move":
			game.current().spent=35; game.current().ap=65; chosen_skill="move"; refresh()
			for cell in board.reachable:
				var point=board.to_global(board.center(cell))
				if board.move_cost(cell)>=16 and not hud_blocks_point(point) and board.visible_cells.has(cell):
					board.hover=cell; preview_point=point; break
		else:
			chosen_skill="delay"; refresh()
			for b in combat_ui.get_parent().get_children():
				if b is SkillButton and b.skill_id=="delay": preview_point=b.get_global_rect().get_center()
		await get_tree().process_frame
		var mouse=InputEventMouseMotion.new()
		mouse.position=preview_point; mouse.global_position=preview_point
		get_viewport().push_input(mouse,true)
		board.pointer_screen=preview_point
		await get_tree().create_timer(0.9).timeout
		if scene=="battle_move": print("MOVE_PREVIEW_AP ",combat_ui.preview().cost)
	if scene=="expedition_plan": ExpeditionUI.open(self,0)
	if scene=="human_gallery": HumanGallery.open_preview(self)
	if scene in ["bloodline","hybrid_creator","hybrid_genes","hybrid_nursery"]:
		var sample=MercenaryRules.sample(1,1,2)
		sample.bloodline=[0,5000,0,0,0,0,5000]; Genome.seed_traits(sample.genes,sample.bloodline)
		if scene in ["bloodline","hybrid_creator"]:
			show_title(); frontend.result_unit=sample; frontend.show_creator()
			if scene=="bloodline": BloodlineUI.open(self,sample,true,frontend.update_creator)
		elif scene=="hybrid_genes": show_unit(sample)
		else:
			game.party[0].bloodline=sample.bloodline.duplicate(); game.party[0].genes=sample.genes.duplicate(true)
			game.party[1].bloodline=[0,0,5000,5000,0,0,0]; Genome.seed_traits(game.party[1].genes,game.party[1].bloodline)
			show_nursery()
	if scene=="contracts": MercenaryUI.contracts(self)
	if scene=="professions": MercenaryUI.professions(self,game.party[0])
	if scene=="home": show_home()
	if scene=="genes": show_unit(game.party[0])
	if scene in ["parts","botanical","botanical_walk","botanical_cast","form_study","faces","faces_reactions","faces_round","faces_sharp","species","species_silhouette","species_walk","parts_editor","parts_exploded"] or scene.begins_with("species_editor_"):
		var gallery=HumanGallery.open_preview(self)
		if scene.ends_with("_walk"): gallery.action="walk"
		if scene.ends_with("_cast"): gallery.action="cast"
	if scene=="skills": show_skills(game.party[0])
	if scene=="training": ProgressionUI.training(self,game.party[0])
	if scene in ["title","slots","quiz","quiz_result","codex","creator"]:
		show_title()
		if scene=="slots": frontend.show_slots()
		if scene in ["quiz","creator"]: frontend.show_creator()
		if scene=="quiz_result": frontend.answers=[0,1,2,3,0,1,2,3,0,1]; frontend.show_result()
		if scene=="codex": ProgressionUI.codex(self)
	if scene=="nursery": show_nursery()
	if scene=="expeditions": show_expeditions()
	if scene=="tactics": ProgressionUI.tactics(self)
	if scene=="town_walk":
		town_movement.go_to(Vector2(303.5,387.25))
		for i in range(90): town_movement.update(1.0/60,Vector2.ZERO)
		print("TOWN_FREE_POSITION ",game.current().town_position)
	if scene=="animation":
		var actor=game.current()
		actor.genes.body_a=[1,1]; actor.genes.body_b=[1,1]; actor.equipped_skills.assign(["delay"])
		battle_selection=actor.uid; chosen_skill="delay"
		var target=game.enemies.filter(func(e): return e.alive() and e.uid in game.combat_ids)[0]
		game.cast("delay",target)
		board.set_process(false)
		# Exported packs are read-only: keep diagnostic frames beside the requested capture.
		var frame_dir=path.get_base_dir().path_join(path.get_file().get_basename()+"_frames")
		var frame_error=DirAccess.make_dir_recursive_absolute(frame_dir)
		if frame_error!=OK:
			push_error("Cannot create animation capture directory: "+frame_dir)
			get_tree().quit(1); return
		for i in range(24):
			board._process(1.0/24)
			await RenderingServer.frame_post_draw
			frame_error=get_viewport().get_texture().get_image().save_png(frame_dir.path_join("frame_%02d.png" % i))
			if frame_error!=OK:
				push_error("Cannot save animation frame: %d"%i)
				get_tree().quit(1); return
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screenshot = get_viewport().get_texture().get_image()
	var err = screenshot.save_png(path)
	print("PREVIEW_CAPTURE ",scene," ",err," ",path)
	audio.shutdown()
	await get_tree().create_timer(0.12).timeout
	get_tree().quit(0 if err==OK else 1)
