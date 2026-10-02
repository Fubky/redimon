extends SceneTree
var passed=0
var failed=0

func check(ok: bool, description: String) -> void:
	if ok: passed+=1
	else: failed+=1; push_error("CONTROL FAIL: "+description)

func fresh() -> GameState:
	var game=GameState.new()
	game.new_game(9017)
	return game

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game=fresh()
	var motion=TownMovement.new()
	motion.setup(game)
	var origin=game.current().town_position
	motion.update(0.05,Vector2.RIGHT)
	check(game.current().town_position.distance_to(origin+Vector2(9,0))<0.01,"continuous movement travels 9 pixels, not one cell")
	check(fposmod(game.current().town_position.x,40)!=20,"position is not snapped to a tile center")
	game.current().town_position=origin
	motion.update(0.05,Vector2(1,1))
	check(absf(game.current().town_position.distance_to(origin)-9)<0.01,"diagonal speed normalized")
	var first=TownMovement.slide(Vector2(200,300),Vector2(0,-300))
	check(first.y>=259 and TownMovement.can_stand(first),"large step cannot tunnel through a building")
	var slide=TownMovement.slide(Vector2(200,262),Vector2(32,-32))
	check(slide.x>220 and slide.y>=259,"diagonal motion slides along wall")
	check(not TownMovement.can_stand(Vector2(395,480)),"pond blocks walking")
	check(not TownMovement.can_stand(Vector2(700,514)),"fence blocks walking")
	check(not TownMovement.can_stand(Vector2(30,340)),"town boundary blocks walking")
	check(not motion.go_to(Vector2(200,200)),"clicking inside building refuses target")
	game.current().town_position=Vector2(315,480)
	var destination=Vector2(485,483)
	check(motion.go_to(destination) and motion.route.size()>1,"click-to-walk computes a non-grid detour around pond")
	for i in range(300):
		motion.update(1.0/60,Vector2.ZERO)
		check(TownMovement.can_stand(game.current().town_position),"auto movement stays out of obstacles")
	check(game.current().town_position.distance_to(destination)<1,"click-to-walk reaches exact arbitrary target")
	check(motion.route.is_empty(),"arrival clears path")
	for ally in game.party: check(TownMovement.can_stand(ally.town_position),"followers remain outside obstacles")
	check(motion.go_to(Vector2(500,380)),"second click route works")
	motion.cancel()
	var paused=game.current().town_position
	motion.update(0.1,Vector2.ZERO)
	check(game.current().town_position==paused,"cancel prevents continued automatic movement")
	game.current().town_position=Vector2(201,276)
	check(motion.nearby_door()=="home","nearby interaction identifies home")
	game.current().town_position=Vector2(761,556)
	check(motion.nearby_door()=="storage","nearby interaction identifies storage")
	game.current().town_position=Vector2(465.25,341.75)
	var saved=game.serialize()
	var restored=fresh()
	check(restored.restore(JSON.parse_string(JSON.stringify(saved))),"new save roundtrip")
	check(restored.current().town_position.is_equal_approx(Vector2(465.25,341.75)),"fractional position preserved")
	for u in saved.party+saved.home+saved.enemies+saved.pending: u.erase("town_position")
	saved.world.erase("explored")
	check(restored.restore(saved),"version 1 save without new fields still loads")
	check(restored.current().town_position==Vector2(restored.current().cell)*40+Vector2(20,20),"legacy grid position migrates to continuous position")
	var a=fresh()
	var b=fresh()
	var ma=TownMovement.new(); ma.setup(a)
	var mb=TownMovement.new(); mb.setup(b)
	for i in range(30): ma.update(1.0/30,Vector2.RIGHT)
	for i in range(120): mb.update(1.0/120,Vector2.RIGHT)
	check(a.current().town_position.distance_to(b.current().town_position)<0.05,"movement independent of 30/120 FPS")
	# Exercise the actual app's continuous polling, modal pause, camera and fog.
	var app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.board.set_process(false)
	origin=app.game.current().town_position
	Input.action_press("town_right")
	app._process(0.1)
	Input.action_release("town_right")
	check(app.game.current().town_position.x>origin.x+17,"held input drives continuous movement in main loop")
	app.show_home()
	origin=app.game.current().town_position
	Input.action_press("town_right")
	app._process(0.1)
	Input.action_release("town_right")
	check(app.game.current().town_position==origin,"modal pauses movement")
	app.close_modal()
	app.game.current().town_position=Vector2(201,276)
	app.interact_town()
	check(app.modal!=null,"nearby interaction opens facility")
	app.close_modal()
	app.game.cleared=[0,1,2]
	app.game.enter_dungeon(3)
	app.refresh()
	await create_timer(0.04).timeout
	app.board._process(0.016)
	check(app.board.scale.x>1.5,"dungeon uses close follow camera")
	check(not app.board.visible_cells.is_empty() and app.board.visible_cells.size()<416,"visibility only reveals local terrain")
	var far=Vector2i(24,14)
	check(not app.board.visible_cells.has(far),"far unseen tile hidden")
	var explored_before=app.game.world.explored.size()
	var old_cell=app.game.current().cell
	for u in app.game.party: u.cell=app.game.world.stairs
	app.board.refresh()
	check(app.game.world.explored.size()>explored_before,"exploration accumulates")
	check(app.game.world.explored.has(old_cell),"explored rooms remain remembered")
	check(not app.board.visible_cells.has(old_cell),"old rooms leave current visibility")
	saved=app.game.serialize()
	check(restored.restore(JSON.parse_string(JSON.stringify(saved))) and restored.world.explored==app.game.world.explored,"exploration map persists through save")
	for amount in [-1.0,0.5,4.0]:
		app.board.change_zoom(amount)
		app.board.update_camera(1.0)
		var p=app.board.center(app.game.current().cell)
		check(app.board.to_local(app.board.to_global(p)).distance_to(p)<0.01,"world-screen coordinate roundtrip under zoom")
		check(app.board.position.x<=0.01 and app.board.position.y<=0.01,"camera remains within map")
	app.board.toggle_overview()
	app.board.update_camera(1.0)
	check(app.board.scale.x*1040<=app.board.view_size.x+0.1 and app.board.scale.y*640<=app.board.view_size.y+0.1,"Tab overview fits the whole floor")
	app.game.return_town()
	await create_timer(0.04).timeout
	app.game.enter_dungeon(0)
	app.game.mode="battle"
	app.game.active_id=app.game.party[0].uid
	app.refresh()
	await create_timer(0.04).timeout
	app.board._process(0.016)
	var actor=app.game.current()
	var destinations=app.game.move_range(actor).keys()
	var target=destinations[-1]
	check(app.game.move_to(target) and app.board.is_animating(),"battle move queues route animation")
	for i in range(100):
		app.board._process(1.0/60)
		await create_timer(0.002).timeout
		var p: Vector2=app.board.unit_position(actor)
		check(app.game.world.walkable(Vector2i(floori(p.x/40),floori(p.y/40))),"animated route never crosses a wall")
	check(not app.board.is_animating() and app.board.unit_position(actor).distance_to(app.board.center(target))<0.1,"route animation reaches committed cell")
	app.game.return_town()
	await create_timer(0.04).timeout
	app.refresh()
	await create_timer(0.04).timeout
	app.board._process(0.016)
	check(not app.board.manual_camera and app.board.scale.x*1040>=app.board.view_size.x and app.board.scale.y*640>=app.board.view_size.y,"returning home resets camera and covers viewport")
	check(app.board.reachable.is_empty(),"town has no tactical cell overlays")
	print("CONTROL_TESTS: ",passed," passed; ",failed," failed.")
	app.audio.shutdown()
	await create_timer(0.12).timeout
	quit(1 if failed>0 else 0)
