class_name FieldOverlay
extends Node2D
## Screen-space HUD stays fixed while the dungeon camera follows a unit.
var board: GameBoard
var font: Font
var redraw_key: Array=[]
var MAP_RECT: Rect2:
	get: return Rect2(board.view_size.x-215,103,191,154)

func _process(_delta: float) -> void:
	var key=[board.preview_revision,board.state.world.explored.size(),board.position.round(),board.scale,board.view_size,board.state.mode,board.state.active_id]
	if key!=redraw_key:
		redraw_key=key
		queue_redraw()

func consumes_point(p: Vector2) -> bool:
	return board.state.mode!="town" and MAP_RECT.has_point(p)

func _draw() -> void:
	if board==null or board.state.mode=="town": return
	var game=board.state
	var current=game.current()
	var dark=Color("142833")
	dark.a=0.91
	draw_style_box(board._style(dark,Color("627d81"),1,7),MAP_RECT)
	draw_string(font,MAP_RECT.position+Vector2(13,23),"探索地图",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("d9dec5"))
	var origin=MAP_RECT.position+Vector2(24,38)
	var step=5.5
	for p in game.world.explored:
		var color=Color("799386") if game.world.walkable(p) else Color("374e5c")
		if not board.visible_cells.has(p): color=color.darkened(0.4)
		draw_rect(Rect2(origin+Vector2(p)*step,Vector2.ONE*(step-0.5)),color)
	if game.world.explored.has(game.world.stairs):
		draw_rect(Rect2(origin+Vector2(game.world.stairs)*step,Vector2.ONE*step),Color("f9cf74"))
	for u in game.field_units():
		if not u.alive() or (u.faction=="enemy" and not board.visible_cells.has(u.cell)): continue
		var color=Color("c6a4f1") if u.faction=="escort" else (Color("ffc468") if u==current else (Color("aee8dd") if u.faction=="party" else Color("e77e6a")))
		draw_circle(origin+(Vector2(u.cell)+Vector2.ONE*0.5)*step,2.5,color)
	var camera_rect = Rect2((-board.position/board.scale.x)/40*step,board.view_size/board.scale.x/40*step)
	camera_rect.position+=origin
	draw_rect(camera_rect,Color(0.82,0.92,0.91,0.4),false,0.8)
	draw_string(font,MAP_RECT.position+Vector2(15,143),"黄当前 · 青队友 · 红敌 · 紫护送",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("b9cbbb"))
