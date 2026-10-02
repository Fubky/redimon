extends SceneTree
var passed=0
var failed=0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	if ok: passed+=1
	else: failed+=1; push_error("ART_V7 FAIL: "+description)

func run() -> void:
	# Catch opaque backgrounds and misregistered atlas cells in the actual imports.
	for texture in [WorldArt.PROPS,WorldArt.BUILDINGS,WorldArt.DETAILS]:
		var source: Image=texture.get_image()
		check(source.detect_alpha()!=Image.ALPHA_NONE,"cutout atlas has real alpha")
		check(source.get_pixel(0,0).a<0.05,"cutout atlas has transparent corners")
	for set_info in [[WorldArt.PROPS,WorldArt.PROP_RECTS],[WorldArt.BUILDINGS,WorldArt.BUILDING_RECTS],[WorldArt.DETAILS,WorldArt.DETAIL_RECTS]]:
		var bounds=Rect2i(Vector2i.ZERO,set_info[0].get_size())
		for rect in set_info[1]:
			check(bounds.encloses(rect),"prop region stays inside its source atlas")
			check(set_info[0].get_image().get_region(rect).get_used_rect().get_area()>100,"prop region contains visible artwork")
	for biome in range(5):
		var terrain=WorldArt.tileset(biome)
		check(terrain==WorldArt.tileset(biome),"biome atlas is cached")
		check(terrain.get_source(0).get_tiles_count()==16 and terrain.get_source(1).get_tiles_count()==16,"biome has floor variants and all adjacency masks")
	var app=load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame
	app.set_process(false); app.board.set_process(false)
	check(app.hud.z_index>app.board.atmosphere.z_index,"atmosphere cannot tint or cover HUD")
	check(app.board.atmosphere.mouse_filter==Control.MOUSE_FILTER_IGNORE,"fog never intercepts tactical clicks")
	app.game.enter_dungeon(0); app.refresh()
	check(app.board.fog_texture!=null,"dungeon visibility texture exists")
	check(app.board.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"world art retains crisp sampling")
	var camera=app.board.camera_center
	app.refresh()
	check(app.board.camera_center==camera,"visual refresh does not move camera")
	check(UnitMotion.glow()==UnitMotion.glow(),"skill lights reuse one texture")
	print("ART_V7_TESTS: ",passed," passed; ",failed," failed.")
	app.audio.shutdown(); await create_timer(0.12).timeout
	quit(1 if failed else 0)
