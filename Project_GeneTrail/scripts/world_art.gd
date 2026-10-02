class_name WorldArt
extends RefCounted
## Production atlases and static scene composition. Prepared once per biome.
const GROUND=preload("res://assets/art_v7/ground.png")
const PROPS=preload("res://assets/art_v7/props.png")
const BUILDINGS=preload("res://assets/art_v7/buildings.png")
const CLIFFS=preload("res://assets/art_v7/cliffs.png")
const DETAILS=preload("res://assets/art_v7/details.png")
const DETAIL_RECTS=[Rect2i(20,25,860,465),Rect2i(924,76,520,414),Rect2i(85,500,665,520),Rect2i(743,560,770,411)]
const PROP_RECTS=[Rect2i(0,0,348,346),Rect2i(350,0,274,344),Rect2i(629,81,325,263),Rect2i(955,68,299,276),Rect2i(0,350,349,289),Rect2i(365,345,254,304),Rect2i(622,360,337,285),Rect2i(963,390,289,250),Rect2i(0,640,328,310),Rect2i(332,677,293,272),Rect2i(631,645,330,304),Rect2i(967,675,287,276),Rect2i(0,952,346,302),Rect2i(355,950,274,304),Rect2i(635,960,319,294),Rect2i(1008,931,246,323)]
const BUILDING_RECTS=[Rect2i(27,9,585,580),Rect2i(646,15,608,574),Rect2i(0,606,637,574),Rect2i(653,635,601,548)]
const PALETTES=[
	[Color("1d3b38"),Color("385847"),Color("719365"),Color("adc185")],
	[Color("29374c"),Color("47576b"),Color("849598"),Color("c3c7ad")],
	[Color("174955"),Color("286d7b"),Color("5aa6a1"),Color("d9f2cc")],
	[Color("231e35"),Color("433548"),Color("775063"),Color("db9361")],
	[Color("24223f"),Color("423e63"),Color("736e9a"),Color("b8a2d3")]]
static var surfaces: Dictionary={}
static var sets: Dictionary={}
static var prop_regions: Dictionary={}
static var building_regions: Dictionary={}
static var detail_regions: Dictionary={}

static func detail(index: int) -> Texture2D:
	if not detail_regions.has(index):
		var texture=AtlasTexture.new(); texture.atlas=DETAILS; texture.region=DETAIL_RECTS[index]; texture.filter_clip=true
		detail_regions[index]=texture
	return detail_regions[index]

static func draw_detail(canvas: CanvasItem, index: int, rect: Rect2) -> void:
	canvas.draw_texture_rect(detail(index),rect,false)

static func surface(index: int) -> Texture2D:
	if not surfaces.has(index):
		var image=GROUND.get_image()
		var size=Vector2i(image.get_width()/3,image.get_height()/2)
		var crop=image.get_region(Rect2i(Vector2i(index%3,index/3)*size,size))
		crop.resize(160,160,Image.INTERPOLATE_LANCZOS)
		var base=[Color("849b6a"),Color("819190"),Color("ebd4ac"),Color("514653"),Color("555773"),Color("a49d83")][index]
		var soften=0.56 if index==0 else (0.4 if index<5 else 0.27)
		for x in range(160):
			for y in range(160): crop.set_pixel(x,y,crop.get_pixel(x,y).lerp(base,soften))
		surfaces[index]=ImageTexture.create_from_image(crop)
	return surfaces[index]

static func cutout(texture: Texture2D, index: int, columns: int, rows: int) -> AtlasTexture:
	var cell=texture.get_size()/Vector2(columns,rows)
	var bounds=Rect2i(Vector2i(Vector2(index%columns,index/columns)*cell),Vector2i(cell))
	var used=texture.get_image().get_region(bounds).get_used_rect()
	var result=AtlasTexture.new(); result.atlas=texture
	result.region=Rect2(bounds.position+used.position,used.size)
	result.filter_clip=true
	return result

static func prop(index: int) -> Texture2D:
	if not prop_regions.has(index):
		var texture=AtlasTexture.new(); texture.atlas=PROPS; texture.region=PROP_RECTS[index]; texture.filter_clip=true
		prop_regions[index]=texture
	return prop_regions[index]

static func building(index: int) -> Texture2D:
	if not building_regions.has(index):
		var texture=AtlasTexture.new(); texture.atlas=BUILDINGS; texture.region=BUILDING_RECTS[index]; texture.filter_clip=true
		building_regions[index]=texture
	return building_regions[index]

static func draw_prop(canvas: CanvasItem, index: int, foot: Vector2, height: float, color: Color=Color.WHITE) -> void:
	var texture=prop(index)
	var size=Vector2(texture.get_width()*height/texture.get_height(),height)
	canvas.draw_texture_rect(texture,Rect2(foot-Vector2(size.x/2,size.y),size),false,color)

static func tileset(biome: int) -> TileSet:
	if sets.has(biome): return sets[biome]
	var result=TileSet.new(); result.tile_size=Vector2i(40,40)
	var floor_source=TileSetAtlasSource.new()
	floor_source.texture=surface(biome); floor_source.texture_region_size=Vector2i(40,40)
	for x in range(4):
		for y in range(4): floor_source.create_tile(Vector2i(x,y))
	result.add_source(floor_source,0)
	var wall_image=Image.create(160,160,false,Image.FORMAT_RGBA8)
	var colors: Array=PALETTES[biome]
	var original=CLIFFS.get_image()
	var cap=original.get_region(Rect2i(int(biome*original.get_width()/5.0),0,int(original.get_width()/5.0),int(original.get_height()*0.45)))
	var side=original.get_region(Rect2i(int(biome*original.get_width()/5.0),int(original.get_height()*0.46),int(original.get_width()/5.0),int(original.get_height()*0.54)))
	cap.resize(160,160,Image.INTERPOLATE_LANCZOS); side.resize(160,80,Image.INTERPOLATE_LANCZOS)
	for mask in range(16):
		for x in range(40):
			for y in range(40):
				var h=absi(x*137+y*53+mask*701)
				var color: Color=colors[1]
				if biome==2:
					color=colors[0].lerp(colors[1],0.4+0.12*sin(y*TAU/40.0)+0.08*cos(x*TAU/40.0))
					if (y==12 and x>7 and x<19) or (y==30 and x>27 and x<34): color=color.lerp(colors[2],0.3)
					if ((mask&1)>0 and y<3) or ((mask&4)>0 and y>36) or ((mask&2)>0 and x>36) or ((mask&8)>0 and x<3): color=colors[3]
				else:
					var face=(mask&4)>0 and y>=22
					if face:
						color=side.get_pixel(x+(mask%4)*40,clampi((y-22)*4,0,79)).darkened(0.08)
						if y==22 or y==23: color=colors[2]
					else:
						color=cap.get_pixel(x+(mask%4)*40,y+(mask/4)*40).darkened(0.12)
					if (mask&8)>0 and x<3: color=color.lightened(0.08)
					if (mask&2)>0 and x>35: color=color.darkened(0.25)
					if (mask&1)>0 and y<3: color=colors[2]
				if h%29==0: color=color.lightened(0.06)
				wall_image.set_pixel((mask%4)*40+x,(mask/4)*40+y,color)
	var wall_source=TileSetAtlasSource.new()
	wall_source.texture=ImageTexture.create_from_image(wall_image); wall_source.texture_region_size=Vector2i(40,40)
	for x in range(4):
		for y in range(4): wall_source.create_tile(Vector2i(x,y))
	result.add_source(wall_source,1)
	sets[biome]=result
	return result

static func town_ground(canvas: CanvasItem) -> void:
	var paving=surface(5)
	for rect in [Rect2(98,277,842,105),Rect2(475,100,86,454),Rect2(158,229,87,85),Rect2(718,229,87,85),Rect2(158,360,87,196),Rect2(718,360,87,196)]:
		canvas.draw_rect(rect.grow(5),Color("647d62"))
		canvas.draw_texture_rect(paving,rect,true,Color("e9e0c8"))
	# Artwork follows the established pond and fence collision footprints.
	draw_detail(canvas,0,Rect2(328,421,136,114))
	draw_detail(canvas,3,Rect2(615,491,102,46))
	draw_detail(canvas,3,Rect2(714,491,102,46))
	for i in range(11):
		var x=46+i*95
		draw_prop(canvas,0 if i%3 else 1,Vector2(x,68),78+i%3*8)
		draw_prop(canvas,0 if i%2 else 3,Vector2(x,641),65+i%3*8)
	for p in [Vector2(45,224),Vector2(974,220),Vector2(47,450),Vector2(971,446)]: draw_prop(canvas,0,p,90)
	for p in [Vector2(308,246),Vector2(658,239),Vector2(306,526),Vector2(876,528)]: draw_prop(canvas,3,p,37)
	for p in [Vector2(326,299),Vector2(644,299),Vector2(909,393)]: draw_prop(canvas,15,p,63)
	for p in [Vector2(916,483),Vector2(922,537)]: draw_prop(canvas,7,p,34)
	# Compact wayfinding marker with a bright amber destination badge.
	canvas.draw_rect(Rect2(515,105,8,44),Color("4e4157"))
	canvas.draw_rect(Rect2(464,83,116,32),Color("26384d"))
	canvas.draw_rect(Rect2(466,85,112,2),Color("efbe76"))

static func dungeon_props(board: GameBoard, canvas: CanvasItem) -> void:
	var biome=board.state.world.biome
	var ids=[[0,1,2,3],[4,5,4,6],[8,9,6,9],[10,11,10,4],[12,13,14,5]][biome]
	for x in range(1,25):
		for y in range(1,15):
			var p=Vector2i(x,y)
			if board.state.world.walkable(p): continue
			var edge=Dungeon.DIRS.any(func(d): return board.state.world.walkable(p+d))
			var seed=absi(x*179+y*317+board.state.world.seed_value)
			if not edge or seed%3!=0: continue
			var index: int=ids[(seed/4)%4]
			var height=66.0 if index in [0,1,8] else (43.0 if index in [4,5,6,10,12,13] else 30.0)
			draw_prop(canvas,index,board.center(p)+Vector2(0,17),height)
