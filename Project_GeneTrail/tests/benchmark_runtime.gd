extends SceneTree
## Reproducible local benchmark; no save writes and no FPS assertion on CI.
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var app=load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.audio.muted=true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	for scene in ["town","battle"]:
		if scene=="battle":
			ContractRules.accept(app.game,"escort_0")
			app.game.enter_dungeon(0)
			var target=app.game.enemies[0]
			var room=app.game.world.room_at(target.cell)
			var spots=app.game.world.reachable(target.cell,3).keys().filter(func(cell): return app.game.world.room_at(cell)==room and app.game.unit_at(cell)==null)
			for i in range(app.game.party.size()): app.game.party[i].cell=spots[i]
			app.game.start_battle(room); app.game.active_id=app.game.party[0].uid
			app.refresh(); app.battle_selection=app.game.active_id; app.refresh()
			for i in range(600):
				app.board._process(1.0/60)
				if not app.board.is_animating(): break

		for i in range(30): await process_frame
		var samples: Array[float]=[]
		for i in range(180):
			var start=Time.get_ticks_usec()
			await process_frame
			samples.append((Time.get_ticks_usec()-start)/1000.0)
		samples.sort()
		var total=0.0
		for value in samples: total+=value
		print("BENCH ",scene," frame_ms mean=",snappedf(total/samples.size(),0.01)," p95=",snappedf(samples[170],0.01))
	var u=app.game.current()
	var start=Time.get_ticks_usec()
	for i in range(2000):
		u.max_hp(); u.attack(); u.has_skill("attack")
	print("BENCH unit_queries_2000_ms=",(Time.get_ticks_usec()-start)/1000.0)
	start=Time.get_ticks_usec()
	for i in range(100): app.refresh()
	print("BENCH unchanged_refresh_100_ms=",(Time.get_ticks_usec()-start)/1000.0)
	app.audio.shutdown()
	await create_timer(0.12).timeout
	quit()
