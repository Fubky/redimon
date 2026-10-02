class_name GameBoard
extends Node2D

var state: GameState
var tiles: TileMapLayer
var font: Font
var reachable: Dictionary = {}
var hover = Vector2i(-1,-1)
var skill: String = "move"
var animation_time: float = 0.0
var floating: Array = []
var buildings: Dictionary = {}
var map_stamp: String = ""
var display_positions: Dictionary = {}
var movement_routes: Dictionary = {}
var visible_cells: Dictionary = {}
var town_movement: TownMovement
var view_size = Vector2(1040,640)
var zoom_level = 1.85
var overview = false
var show_grid = false
var camera_center = Vector2(520,320)
var camera_snap = true
var pointer_inside = false
var pointer_screen=Vector2(-1,-1)
var tactical_selected=false
var manual_camera=false
var camera_actor=""
var motion=UnitMotion.new()
var audio: GameAudio
var scenery: Node2D
var visibility_key: Array=[]
var range_key: Array=[]
var skill_cells: Array[Vector2i]=[]
var preview_revision=0
var path_key: Array=[]
var cached_path: Array[Vector2i]=[]
var path_requests=0
var style_cache: Dictionary={}
var atmosphere: ColorRect
var fog_texture: ImageTexture
const TOWN_BUILDINGS=[Vector2(201,250),Vector2(761,250),Vector2(201,530),Vector2(761,530)]
const INK = Color("354e42")
const SAFE_MOVE=Color("82cfff")
const BURST_MOVE=Color("ffad68")

func setup(game: GameState, ui_font: Font) -> void:
	state = game
	font = ui_font
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	tiles = TileMapLayer.new()
	tiles.name = "TerrainTileMapLayer"
	tiles.z_index = -1
	add_child(tiles)
	scenery=Node2D.new()
	scenery.name="CachedScenery"
	scenery.z_index=-1
	add_child(scenery)
	scenery.draw.connect(draw_scenery)
	for i in range(4): buildings[["home","shop","nursery","storage"][i]]=WorldArt.building(i)
	atmosphere=ColorRect.new(); atmosphere.size=Vector2(1040,640)
	atmosphere.mouse_filter=Control.MOUSE_FILTER_IGNORE; atmosphere.z_index=2
	var shader=ShaderMaterial.new(); shader.shader=preload("res://assets/art_v7/atmosphere.gdshader")
	atmosphere.material=shader; add_child(atmosphere)
	state.effect.connect(func(cell,text,good): floating.append({"cell":cell,"text":text,"good":good,"age":0.0}))
	state.action_performed.connect(func(actor,target,id): motion.enqueue(state.by_id(actor),state.by_id(target),id))
	state.movement_path.connect(func(id,path):
		if not display_positions.has(id): display_positions[id]=center(state.by_id(id).cell)
		if state.mode=="explore" and movement_routes.has(id): movement_routes[id].append_array(path)
		else: movement_routes[id]=path.duplicate())
	refresh()

func refresh() -> void:
	var stamp = "%s-%s-%s" % [state.mode=="town",state.world.seed_value,state.world.biome]
	if stamp != map_stamp:
		map_stamp = stamp
		display_positions.clear()
		movement_routes.clear()
		camera_snap=true
		manual_camera=false
		motion.actions.clear(); motion.current={}; motion.tracks.clear()
		overview=false
		build_tiles()
		scenery.queue_redraw()
		atmosphere.material.set_shader_parameter("town",state.mode=="town")
		atmosphere.material.set_shader_parameter("fog_color",[Color("122839"),Color("1e2b46"),Color("153e51"),Color("251e36"),Color("201e3e")][state.world.biome])
		atmosphere.material.set_shader_parameter("daylight",0.1 if state.world.biome>=3 and state.mode!="town" else 1.0)
		# Compile each visible phenotype once during map setup, never while walking.
		for unit in state.field_units(): HumanAssembly.build(unit)
	update_visibility()
	var u = state.current()
	var key=[state.world.get_instance_id(),state.mode,state.combat_room,skill,tactical_selected,state.party.map(func(a): return [a.uid,a.cell,a.alive()]),state.enemies.map(func(a): return [a.uid,a.cell,a.alive()])]
	if u!=null: key.append([u.uid,u.cell,u.ap,u.spent,u.moved,u.movement(),hash(u.genes),u.level,hash(u.equipped_skills)])
	if key!=range_key:
		range_key=key; preview_revision+=1; path_key.clear()
		reachable.clear(); skill_cells.clear()
		if state.mode == "battle" and u != null and u.faction == "party" and tactical_selected:
			if skill == "move" and not u.moved: reachable=state.move_range(u)
			elif skill in GameState.SKILLS and u.has_skill(skill):
				for p in state.world.cells:
					if state.distance(p,u.cell)<=GameState.SKILLS[skill].range and state.world.sight(u.cell,p): skill_cells.append(p)
	queue_redraw()

func move_cost(cell: Vector2i) -> int:
	return int(reachable[cell])*8 if reachable.has(cell) else -1

func is_burst_cell(cell: Vector2i) -> bool:
	return move_cost(cell)>0 and state.current().spent+move_cost(cell)>50

func path_to(cell: Vector2i) -> Array[Vector2i]:
	var key=[preview_revision,cell]
	if key!=path_key:
		path_key=key; cached_path.clear()
		var u=state.current()
		if u!=null and visible_cells.has(cell) and (state.mode!="battle" or move_cost(cell)>0):
			path_requests+=1
			cached_path=state.world.path(u.cell,cell,state.battle_blocked(u) if state.mode=="battle" else state.occupied(u))
	return cached_path

func build_tiles() -> void:
	tiles.clear()
	tiles.tile_set=WorldArt.tileset(0 if state.mode=="town" else state.world.biome)
	for x in range(Dungeon.WIDTH):
		for y in range(Dungeon.HEIGHT):
			var p = Vector2i(x,y)
			var walkable = state.world.walkable(p)
			if state.mode == "town" and x>0 and y>0 and x<25 and y<15: walkable = true
			if walkable:
				tiles.set_cell(p,0,Vector2i(x%4,y%4))
			else:
				var mask=0
				var dirs=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
				for i in range(4):
					if state.world.walkable(p+dirs[i]): mask|=1<<i
				tiles.set_cell(p,1,Vector2i(mask%4,mask/4))

func update_visibility() -> void:
	var key=[state.world.get_instance_id(),state.mode=="town",state.party.map(func(u): return [u.uid,u.cell,u.alive()])]
	if key==visibility_key: return
	visibility_key=key
	visible_cells.clear()
	if state.mode=="town": return
	for ally in state.party:
		if not ally.alive(): continue
		for x in range(maxi(0,ally.cell.x-7),mini(Dungeon.WIDTH,ally.cell.x+8)):
			for y in range(maxi(0,ally.cell.y-7),mini(Dungeon.HEIGHT,ally.cell.y+8)):
				var p=Vector2i(x,y)
				if Vector2(p-ally.cell).length()<=7.5 and state.world.sight(ally.cell,p):
					visible_cells[p]=true
					state.world.explored[p]=true
	var image=Image.create(26,16,false,Image.FORMAT_RGBA8)
	for x in range(26):
		for y in range(16):
			var p=Vector2i(x,y)
			var value=1.0 if visible_cells.has(p) else (0.12 if state.world.explored.has(p) else 0.0)
			image.set_pixel(x,y,Color(value,value,value,1))
	if fog_texture==null: fog_texture=ImageTexture.create_from_image(image)
	else: fog_texture.update(image)
	atmosphere.material.set_shader_parameter("visibility",fog_texture)

func unit_position(u: UnitData) -> Vector2:
	return u.town_position if state.mode=="town" else display_positions.get(u.uid,center(u.cell))

func is_animating() -> bool:
	return motion.busy() or movement_routes.values().any(func(route): return not route.is_empty())

func change_zoom(amount: float) -> void:
	if state.mode=="town": return
	overview=false
	zoom_level=clampf(zoom_level+amount,1.3,2.4)

func toggle_overview() -> void:
	if state.mode!="town": overview=not overview

func pan_camera(direction: Vector2, delta: float) -> void:
	if direction.is_zero_approx(): return
	manual_camera=true
	camera_center+=direction.normalized()*420*delta/scale.x

func recenter() -> void:
	manual_camera=false
	camera_snap=true

func update_camera(delta: float) -> void:
	var covering=maxf(view_size.x/1040.0,view_size.y/640.0)
	var zoom=covering if state.mode=="town" else maxf(covering,zoom_level)
	if overview: zoom=minf(view_size.x/1040.0,view_size.y/640.0)
	scale=Vector2.ONE*zoom
	if state.mode=="battle" and camera_actor!=state.active_id:
		camera_actor=state.active_id
		manual_camera=false
		camera_snap=true
	var target=camera_center if manual_camera and state.mode=="battle" else unit_position(state.current())
	# Keep the actor above the combat HUD, which floats over the full scene.
	if state.mode=="battle" and not manual_camera: target.y+=65/zoom
	var half=view_size/(2*zoom)
	var minimum=half.min(Vector2(520,320))
	var maximum=Vector2(1040,640)-minimum
	if state.mode=="battle" and not overview:
		minimum=Vector2.ZERO
		maximum=Vector2(1040,640)
	target=target.clamp(minimum,maximum)
	if camera_snap: camera_center=target; camera_snap=false
	else: camera_center=camera_center.lerp(target,1.0-exp(-delta*9))
	camera_center=camera_center.clamp(minimum,maximum)
	position=view_size*0.5-camera_center*zoom

func _process(delta: float) -> void:
	animation_time += delta
	if state != null:
		for u in state.field_units():
			var target = center(u.cell)
			var route = movement_routes.get(u.uid,[])
			var old: Vector2 = display_positions.get(u.uid,target)
			if not route.is_empty():
				var travel=delta*(40.0/DungeonMovement.STEP_SECONDS if state.mode=="explore" else 260.0)
				while not route.is_empty() and travel>0:
					var next=center(route[0])
					var distance=old.distance_to(next)
					old=old.move_toward(next,travel)
					travel=maxf(0,travel-distance)
					if old.distance_to(next)<0.01: route.pop_front()
				display_positions[u.uid]=old
			else: display_positions[u.uid] = old.move_toward(target,delta*40.0/DungeonMovement.STEP_SECONDS)
		update_camera(delta)
		motion.audio=audio
		motion.update(state.field_units(),unit_position,movement_routes.values().any(func(route): return not route.is_empty()),delta)
		if audio!=null and state.current()!=null:
			audio.footstep(motion.tracks.get(state.current().uid,{}).get("moving",false),delta)
	for f in floating: f.age += delta
	floating = floating.filter(func(f): return f.age<1.7)
	pointer_screen=get_parent().get_local_mouse_position()
	var p=transform.affine_inverse()*pointer_screen
	pointer_inside = Rect2(Vector2.ZERO,view_size).has_point(pointer_screen)
	hover = Vector2i(floori(p.x/40),floori(p.y/40))
	if not pointer_inside: hover=Vector2i(-1,-1)
	queue_redraw()

func center(p: Vector2i) -> Vector2: return Vector2(p)*40+Vector2(20,20)

func plaque(text: String, p: Vector2, width: float) -> void:
	draw_plaque(self,text,p,width)

func draw_plaque(canvas: CanvasItem, text: String, p: Vector2, width: float) -> void:
	canvas.draw_style_box(_style(Color("1d3345"),Color("97b4aa"),1,4),Rect2(p-Vector2(width/2,17),Vector2(width,28)))
	canvas.draw_line(p+Vector2(-width/2+8,-16),p+Vector2(-width/2+29,-16),Color("f0bc70"),2)
	canvas.draw_string(font,p-Vector2(width/2-10,-2),text,HORIZONTAL_ALIGNMENT_CENTER,width-20,14,Color("f7ebcd"))

func _style(color: Color, border: Color, line: int, radius: int) -> StyleBoxFlat:
	var key=[color,border,line,radius]
	if style_cache.has(key): return style_cache[key]
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(line)
	s.set_corner_radius_all(radius)
	style_cache[key]=s
	return s

func _draw() -> void:
	if state == null: return
	if state.mode != "town":
		for p in state.world.loot:
			if not visible_cells.has(p): continue
			var c = center(p)
			WorldArt.draw_detail(self,1,Rect2(c-Vector2(18,23),Vector2(36,29)))
		if visible_cells.has(state.world.stairs):
			var stairs = center(state.world.stairs)
			WorldArt.draw_detail(self,2,Rect2(stairs-Vector2(21,22),Vector2(42,37)))
	var active = state.current()
	for p in reachable:
		if not visible_cells.has(p): continue
		var burst=is_burst_cell(p)
		var tint=BURST_MOVE if burst else SAFE_MOVE
		draw_rect(Rect2(Vector2(p)*40,Vector2(40,40)),Color(tint,0.24 if burst else 0.14))
		if burst:
			draw_line(center(p)+Vector2(-6,6),center(p)+Vector2(6,-6),Color(tint,0.7),1.5,true)
		if show_grid: draw_rect(Rect2(Vector2(p)*40+Vector2(1,1),Vector2(38,38)),Color(0.87,0.94,0.77,0.22),false,0.7)
		for direction in Dungeon.DIRS:
			if not reachable.has(p+direction) or is_burst_cell(p+direction)!=burst:
				var c=center(p)+Vector2(direction)*19
				var tangent=Vector2(-direction.y,direction.x)*19
				draw_line(c-tangent,c+tangent,tint,1.6,true)
	for p in skill_cells:
		draw_rect(Rect2(Vector2(p)*40+Vector2(3,3),Vector2(34,34)),Color(0.96,0.76,0.38,0.22))
	if state.mode!="town" and state.world.walkable(hover) and visible_cells.has(hover):
		draw_style_box(_style(Color(1,1,0.9,0.14),Color("fff3cd"),2,6),Rect2(Vector2(hover)*40+Vector2(1,1),Vector2(38,38)))
		if active != null and skill == "move" and (state.mode!="battle" or tactical_selected and not active.moved):
			var path=path_to(hover)
			for i in range(path.size()):
				var burst=state.mode=="battle" and active.spent+(i+1)*8>50
				draw_circle(center(path[i]),3.0,BURST_MOVE if burst else SAFE_MOVE)
	var units = state.field_units()
	units.sort_custom(func(a,b): return unit_position(a).y<unit_position(b).y)
	var building_index=0
	for u in units:
		if state.mode=="town":
			while building_index<4 and TOWN_BUILDINGS[building_index].y<=unit_position(u).y:
				draw_town_building(building_index); building_index+=1
		if state.mode!="town" and u.faction=="enemy" and not visible_cells.has(u.cell): continue
		if not motion.should_draw(u):
			if u.faction=="party":
				draw_line(center(u.cell)-Vector2(6,6),center(u.cell)+Vector2(6,6),Color("b05f53"),3)
				draw_line(center(u.cell)+Vector2(-6,6),center(u.cell)+Vector2(6,-6),Color("b05f53"),3)
			continue
		var c: Vector2 = unit_position(u)
		var ring = Color("e6c36b") if u.faction=="escort" else (Color("628f76") if u.faction=="party" else Color("b16f5b"))
		CreatureArt.oval(self,c+Vector2(3,12),Vector2(18,7),Color(0.06,0.09,0.17,0.35),Color.TRANSPARENT,0)
		draw_arc(c+Vector2(0,10),17,0.1,PI-0.1,28,Color(ring,0.6),1.3,true)
		if u==active:
			draw_arc(c+Vector2(0,7),18,0,TAU,48,Color("fff1a3"),1.8,true)
			CreatureArt.polygon(self,[c+Vector2(-3,-57),c+Vector2(3,-57),c+Vector2(0,-52)],Color("ffe79c"),Color("745d3f"))
		CreatureArt.draw(self,u,c,1.02 if state.mode!="town" else 1.12,animation_time*2+u.cell.x,motion.pose(u))
		if state.mode=="battle" or u.hp<u.max_hp():
			draw_rect(Rect2(c+Vector2(-15,22),Vector2(30,3)),Color("22363b"))
			draw_rect(Rect2(c+Vector2(-15,22),Vector2(30*float(u.hp)/u.max_hp(),3)),ring.lightened(0.25))
		if u.faction=="escort":
			draw_style_box(_style(Color("243449"),Color("c6a4f1"),1,3),Rect2(c+Vector2(17,4),Vector2(13,14)))
			draw_string(font,c+Vector2(19,15),"护",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e6d2ff"))
		if u.faction=="enemy": draw_circle(c+Vector2(15,-19),3,Color("b26452"))
		if state.mode=="battle":
			if u.faction=="enemy" and not u.combo_from.is_empty() and not u.combo_used:
				draw_circle(c+Vector2(-24,-11),9,Color("193c48"))
				draw_arc(c+Vector2(-24,-11),9,0,TAU,24,Color("8fe3de"),1.2,true)
				draw_string(font,c+Vector2(-30,-7),"协",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("c7fff2"))
			var kinds=BattleRules.types(u)
			for i in range(kinds.size()):
				draw_style_box(_style(Color(BattleRules.COLORS[kinds[i]]).darkened(0.3),Color.TRANSPARENT,0,3),Rect2(c+Vector2(-15+i*17,27),Vector2(15,12)))
				draw_string(font,c+Vector2(-13+i*17,36),BattleRules.TYPES[kinds[i]].left(1),HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("fff7dc"))
			if not u.status.is_empty(): plaque(BattleRules.STATUS_NAMES[u.status],c+Vector2(0,-47),54)
			if u.guard: draw_arc(c,23,PI,TAU,24,Color("a6e6db"),2,true)
		if hover==u.cell and state.mode!="town":
			plaque("%s  %d/%d" % [u.display_name,u.hp,u.max_hp()],c-Vector2(0,40),164)
	if state.mode=="town":
		while building_index<4: draw_town_building(building_index); building_index+=1
	if state.mode=="town" and town_movement!=null:
		if town_movement.destination.x>=0:
			draw_arc(town_movement.destination,9,0,TAU,24,Color("fff3c7"),2,true)
		var door=town_movement.nearby_door()
		if not door.is_empty(): plaque("E  "+{"home":"佣兵营舍","shop":"商店","nursery":"家系馆","storage":"仓库","expeditions":"远征","contracts":"任务栏"}[door],unit_position(active)+Vector2(0,-57),128)
	EnvironmentArt.ambient(self)
	motion.draw_fx(self,unit_position)
	for f in floating:
		var impact=center(f.cell)
		var fade=clampf(1.0-f.age/0.6,0,1)
		if fade>0:
			var color=Color("c1f0c3") if f.good else Color("ffe3a0")
			color.a=fade
			draw_arc(impact,8+f.age*40,0,TAU,24,color,1.8,true)
			for i in range(6):
				var dir=Vector2.from_angle(TAU*i/6.0)
				draw_line(impact+dir*(8+f.age*25),impact+dir*(14+f.age*35),color,1.6,true)
		var c = center(f.cell)-Vector2(40,25+f.age*25)
		draw_string_outline(font,c,f.text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,2,Color("22313c"))
		draw_string(font,c,f.text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f5ffe0") if f.good else Color("fff1bc"))

func draw_fog() -> void:
	for x in range(Dungeon.WIDTH):
		for y in range(Dungeon.HEIGHT):
			var p=Vector2i(x,y)
			if visible_cells.has(p): continue
			var color=Color("101c2d")
			color.a=0.68 if state.world.explored.has(p) else 0.98
			draw_rect(Rect2(Vector2(p)*40,Vector2(40,40)),color)

func draw_scenery() -> void:
	if state.mode=="town": draw_town(scenery)
	else:
		for p in state.world.cells:
			var origin=Vector2(p)*40
			if not state.world.walkable(p+Vector2i.UP): scenery.draw_rect(Rect2(origin,Vector2(40,6)),Color(0.04,0.10,0.13,0.26))
			if not state.world.walkable(p+Vector2i.LEFT): scenery.draw_rect(Rect2(origin,Vector2(4,40)),Color(0.04,0.10,0.13,0.15))
		WorldArt.dungeon_props(self,scenery)

func draw_town_building(index: int) -> void:
	var texture=WorldArt.building(index)
	var height=204.0 if index!=2 else 196.0
	var size=Vector2(texture.get_width()*height/texture.get_height(),height)
	draw_texture_rect(texture,Rect2(TOWN_BUILDINGS[index]-Vector2(size.x/2,size.y),size),false)
	var names=["佣兵营舍","行军商铺","家系馆","公会仓库"]
	draw_plaque(self,names[index],TOWN_BUILDINGS[index]+Vector2(0,21),128)

func draw_town(canvas: CanvasItem) -> void:
	WorldArt.town_ground(canvas)
	for x in [300,659]:
		canvas.draw_line(Vector2(x,174),Vector2(x,272),Color("483f3d"),3)
		canvas.draw_texture_rect(preload("res://assets/imperial_crest.svg"),Rect2(x,177,37,42),false)
	# Imperial notice board and guild colours are part of the field, not a screen overlay.
	canvas.draw_rect(Rect2(555,245,63,39),Color("4d3d35"))
	canvas.draw_rect(Rect2(558,248,57,31),Color("947453"))
	for i in range(3):
		canvas.draw_rect(Rect2(562+i*17,252,13,22),Color("eee0bb"))
		canvas.draw_line(Vector2(565+i*17,259),Vector2(571+i*17,259),Color("796651"),1)
	canvas.draw_line(Vector2(561,284),Vector2(561,295),Color("4d3d35"),4)
	canvas.draw_line(Vector2(612,284),Vector2(612,295),Color("4d3d35"),4)
	draw_plaque(canvas,"佣兵任务栏",Vector2(586,235),108)
	canvas.draw_string(font,Vector2(474,105),"远征出发 →",HORIZONTAL_ALIGNMENT_CENTER,95,14,Color("f7daa3"))
