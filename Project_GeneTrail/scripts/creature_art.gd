class_name CreatureArt
extends RefCounted
## Shared genetic sprite renderer and geometric effect helpers.
static var circle: PackedVector2Array=make_circle()

static func make_circle() -> PackedVector2Array:
	var result=PackedVector2Array()
	for i in range(32): result.append(Vector2.from_angle(TAU*i/32.0))
	return result

static func oval(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color, outline: Color, width: float = 2.0) -> void:
	var points = PackedVector2Array()
	var colors=PackedColorArray()
	var shaded=color.a>0.5 and radii.x>4 and radii.y>5
	for direction in circle:
		points.append(center+direction*radii)
		var light=-(direction.x*0.3+direction.y)*0.16
		colors.append((color.lightened(light) if light>0 else color.darkened(-light)) if shaded else color)
	# One interpolated polygon replaces 32 separate triangle draw commands.
	canvas.draw_polygon(points,colors)
	if width>0 and outline.a>0:
		points.append(points[0])
		canvas.draw_polyline(points,outline,width*0.65,true)

static func polygon(canvas: CanvasItem, points: Array, color: Color, ink: Color) -> void:
	var p = PackedVector2Array(points)
	canvas.draw_colored_polygon(p,color)
	p.append(p[0])
	canvas.draw_polyline(p,ink,2.0,true)

static func draw(canvas: CanvasItem, u: UnitData, center: Vector2, scale_factor: float = 1.0, phase: float = 0.0, motion: Dictionary = {}) -> void:
	HumanAssembly.draw(canvas,u,center,scale_factor,phase,motion)
