extends SceneTree
var passed=0
var failed=0
var app

func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	if ok: passed+=1
	else: failed+=1; push_error("RUNTIME_UX FAIL: "+description)

func open_field(g: GameState) -> void:
	g.enter_dungeon(0); g.enemies.clear(); g.world.cells.clear(); g.world.loot.clear()
	g.world.rooms.assign([Rect2i(1,1,24,14)])
	for x in range(1,25):
		for y in range(1,15): g.world.cells[Vector2i(x,y)]=true
	g.world.stairs=Vector2i(23,13)
	g.party[0].cell=Vector2i(3,4); g.party[1].cell=Vector2i(3,5)

func find_skill(node: Node, id: String) -> SkillButton:
	if node is SkillButton and node.skill_id==id: return node
	for child in node.get_children():
		var found=find_skill(child,id)
		if found!=null: return found
	return null

func run() -> void:
	var endpoints=[]
	for fps in [30,60,120]:
		var sample=GameState.new(); sample.new_game(93); open_field(sample)
		var controller=DungeonMovement.new(); controller.setup(sample)
		for i in range(fps*2): controller.update(1.0/fps,Vector2.RIGHT,Vector2i(-1,-1))
		endpoints.append(sample.current().cell)
	check(endpoints[0]==endpoints[1] and endpoints[1]==endpoints[2],"held exploration cadence agrees at 30, 60 and 120 FPS")
	app=load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame
	app.set_process(false); app.board.set_process(false)
	var g: GameState=app.game
	open_field(g); app.board.map_stamp=""; app.refresh()
	var u=g.current()
	var start=u.cell
	Input.action_press("town_right")
	app._process(1.0/60)
	check(u.cell==start+Vector2i.RIGHT,"first held frame moves immediately")
	for i in range(42): app._process(1.0/60); app.board._process(1.0/60)
	Input.action_release("town_right")
	check(u.cell.x>=start.x+5,"held key continues without OS repeat")
	start=u.cell
	app._process(0.2)
	check(u.cell==start,"release stops logical movement")
	app.show_home(); Input.action_press("town_right"); app._process(0.2); Input.action_release("town_right")
	check(u.cell==start,"modal pauses held dungeon input")
	app.close_modal()
	app.goal_cell=u.cell+Vector2i(4,0)
	var goal=app.goal_cell
	var requests=app.dungeon_movement.path_requests
	for i in range(90): app._process(1.0/60); app.board._process(1.0/60)
	check(u.cell==goal and app.goal_cell.x<0,"click route completes and stops")
	check(app.dungeon_movement.path_requests==requests+1,"click route uses one path search for all steps")
	app.goal_cell=u.cell+Vector2i(3,0); app._process(0.016)
	Input.action_press("town_up"); app._process(0.016); Input.action_release("town_up")
	check(app.goal_cell.x<0 and app.dungeon_movement.route.is_empty(),"keyboard overrides click route")
	app._process(0.016)
	g.world.cells.erase(u.cell+Vector2i.RIGHT)
	start=u.cell
	for i in range(20): app.dungeon_movement.update(0.02,Vector2.RIGHT,Vector2i(-1,-1))
	check(u.cell==start,"held movement never crosses a wall")
	g.world.cells[start+Vector2i.RIGHT]=true
	# Changed signals from walking must keep the existing HUD nodes alive.
	app.refresh(); var builds=app.hud_builds
	for i in range(20): app.refresh()
	check(app.hud_builds==builds,"unchanged state does not rebuild HUD")
	u.cell+=Vector2i.DOWN; app.refresh()
	check(app.hud_builds==builds,"exploration position alone does not rebuild HUD")
	g.gold+=1; app.refresh()
	check(app.hud_builds==builds+1,"resource changes refresh HUD")
	# A bent route must animate through every corner, even on a long frame.
	app.board.display_positions[u.uid]=app.board.center(Vector2i(3,4))
	app.board.movement_routes[u.uid]=[Vector2i(4,4),Vector2i(4,3)]
	u.cell=Vector2i(4,3)
	app.board._process(0.1)
	check(is_equal_approx(app.board.unit_position(u).y,180),"animation follows first segment without cutting a corner")
	app.board._process(0.3)
	check(app.board.unit_position(u).is_equal_approx(app.board.center(u.cell)),"long frame consumes remaining route smoothly")
	# Keep one real enemy to exercise the turn-selection boundary.
	var seed_game=GameState.new(); seed_game.new_game(77); seed_game.enter_dungeon(0)
	var enemy: UnitData=seed_game.enemies[0]; enemy.cell=Vector2i(12,7); g.enemies.append(enemy)
	g.mode="battle"; g.combat_room=0; g.active_id=u.uid; g.turn_serial+=1
	g.combat_ids=[u.uid,g.party[1].uid,enemy.uid]
	u.ap=100; u.spent=0; u.moved=false
	app.refresh()
	check(app.battle_selection==u.uid and not app.board.reachable.is_empty(),"new player turn automatically shows movement range")
	app.battle_selection=""; app.refresh(); app.refresh()
	check(app.battle_selection.is_empty(),"manual cancel survives ordinary refresh")
	g.turn_serial+=1; app.refresh()
	check(app.battle_selection==u.uid,"consecutive turn by same actor selects again")
	g.active_id=enemy.uid; g.turn_serial+=1; app.refresh()
	check(app.battle_selection.is_empty() and app.board.reachable.is_empty(),"enemy turn never exposes player movement controls")
	g.active_id=u.uid; g.turn_serial+=1; app.refresh()
	var target=u.cell+Vector2i(2,0)
	u.spent=34; u.ap=66; app.refresh()
	check(app.board.move_cost(target)==16 and not app.board.is_burst_cell(target),"exactly 50 spent stays safe")
	u.spent=35; u.ap=65; app.refresh()
	check(app.board.is_burst_cell(target),"crossing 50 marks orange movement")
	check(not app.board.is_burst_cell(u.cell+Vector2i.RIGHT),"remaining safe segment keeps its own color")
	check(app.combat_ui.preview_at(target,true).cost==16,"movement preview uses same distance as range")
	check(g.return_delay(u,16)-g.return_delay(u)==70,"move warning matches scheduling penalty")
	u.spent=60; u.ap=40; app.refresh()
	check(app.board.is_burst_cell(u.cell+Vector2i.RIGHT),"already overused actor has orange movement")
	check(app.combat_ui.preview_at(Vector2i(24,14),true).cost==0,"unreachable cell has no false AP preview")
	app.board.path_to(target); requests=app.board.path_requests
	for i in range(200): app.board.path_to(target); app.combat_ui.preview_at(target,true)
	check(app.board.path_requests==requests,"idle hover and HUD do not repeat pathfinding")
	enemy.cell=target; app.refresh()
	check(app.board.path_to(target).is_empty() and app.combat_ui.preview_at(target,true).cost==0,"occupancy invalidates path and preview cache")
	# Genetic cache detects in-place gene changes, level-ups and loadout edits.
	u.genes.body_a=[0,0]; u.genes.body_b=[0,0]; u.equipped_skills.clear()
	var before=u.base_stats()
	u.genes.muscle=[100,100]
	check(u.base_stats()==GeneTraits.innate(u.bloodline,u.genes),"base cache invalidates mutated alleles")
	before.hp=-999
	check(u.base_stats().hp>0,"caller cannot corrupt base cache")
	u.level=10
	check(u.skill_pool().has("muscle_2"),"level-up invalidates learned pool")
	u.equipped_skills.assign(["guard"])
	check(u.has_skill("guard") and not u.has_skill("strike"),"loadout cache follows explicit equipment edits")
	u.equipped_skills.assign(["delay"]); u.genes.body_a=[1,1]; u.genes.body_b=[1,1]
	check(u.has_skill("delay"),"gene-based skill ownership changes immediately")
	app.refresh()
	var button=find_skill(app.hud,"delay")
	check(button!=null,"skill button supports structured tooltip")
	var tooltip=button._make_custom_tooltip(button.tooltip_text)
	root.add_child(tooltip)
	await process_frame
	var style: StyleBoxFlat=tooltip.get_theme_stylebox("panel")
	check(style.bg_color.a==1.0 and style.bg_color.srgb_to_linear().get_luminance()<0.03,"tooltip background opaque and dark")
	check(tooltip.size.x>=440 and tooltip.size.x<=500,"tooltip has a bounded readable width")
	for line in tooltip.get_child(0).get_children():
		check(line.autowrap_mode!=TextServer.AUTOWRAP_OFF and line.get_theme_font_size("font_size")>=16,"tooltip wraps and uses readable text")
		check((line.get_theme_color("font_color").srgb_to_linear().get_luminance()+0.05)/(style.bg_color.srgb_to_linear().get_luminance()+0.05)>=7.0,"tooltip text contrast exceeds 7 to 1")
	tooltip.queue_free()
	# Check that entering an enemy room interrupts a held exploration step.
	g.mode="explore"; g.active_id=""; g.party[0].cell=Vector2i(3,4); enemy.cell=Vector2i(7,4)
	app.dungeon_movement.cancel(); app.goal_cell=Vector2i(10,4)
	app._process(0.016)
	check(g.mode=="battle" and app.goal_cell.x<0 and app.dungeon_movement.route.is_empty(),"encounter interrupts remaining click path")
	print("RUNTIME_UX_TESTS: ",passed," passed; ",failed," failed.")
	app.audio.shutdown(); await create_timer(0.12).timeout
	quit(1 if failed else 0)
