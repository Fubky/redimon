class_name CreatureAssembly
extends RefCounted
## A phenotype is a rig of independently swappable textures, never a whole-unit image.
const CACHE_LIMIT=96
const PART_CACHE_LIMIT=512
const BODY_TYPES={"紧凑型":"round","小型":"lean","中型":"lean","中大型":"heavy","大型":"heavy"}
const BODY_SIZE={"紧凑型":0.78,"小型":0.87,"中型":1.0,"中大型":1.12,"大型":1.28}
const EYE_COLORS=["b5d66a","f8bc62","8eddf1","ec8d75","c9a0ed"]
const LEAF_COLORS=["91ae70","83aa85","a6b97b","77aa97","a8bd7b","91aaa0"]
const BLOOM_COLORS=["e5a7a2","e8bd98","dba5bd","eed39a","dfa8b5","bab4d7"]
const EXPRESSIONS=["calm","focus","happy","hurt","sleep","surprise"]
## Species establish anatomy; inherited alleles still control the same variation ranges.
const FORMS=[
	{"body":Vector2(1.0,1.04),"legs":Vector2(1.08,0.82),"head":Vector2(14,-26),"skull":Vector2(0.95,0.92),"ears":Vector2(0.80,0.78),"ear_near":Vector2(-18,-23),"ear_far":Vector2(18,-25),"tail":Vector2(-25,3),"front":Vector2(17,12),"hind":Vector2(-18,13)},
	{"body":Vector2(1.02,1.09),"legs":Vector2(1.04,0.97),"head":Vector2(19,-26),"skull":Vector2(0.98,0.98),"ears":Vector2(0.72,0.70),"ear_near":Vector2(-20,-24),"ear_far":Vector2(13,-27),"tail":Vector2(-27,-2),"front":Vector2(18,12),"hind":Vector2(-20,13)},
	{"body":Vector2(0.84,0.92),"legs":Vector2(0.88,0.78),"head":Vector2(8,-25),"skull":Vector2(0.85,0.85),"ears":Vector2(0.72,0.75),"ear_near":Vector2(-21,-26),"ear_far":Vector2(14,-28),"tail":Vector2(-23,17),"front":Vector2(18,8),"hind":Vector2(-9,26)},
	{"body":Vector2(1.06,0.92),"legs":Vector2(1.0,0.70),"head":Vector2(24,-14),"skull":Vector2(0.96,0.89),"ears":Vector2(0.46,0.42),"ear_near":Vector2(-24,-8),"ear_far":Vector2(2,-22),"tail":Vector2(-28,1),"front":Vector2(18,12),"hind":Vector2(-21,13)},
	{"body":Vector2(1.02,0.81),"legs":Vector2.ONE,"head":Vector2(-4,-32),"skull":Vector2(0.94,0.91),"ears":Vector2(0.46,0.43),"ear_near":Vector2(-24,-10),"ear_far":Vector2(4,-24),"tail":Vector2(-24,11),"front":Vector2.ZERO,"hind":Vector2(-24,0)}]
static var rigs: Dictionary={}
static var rig_order: Array=[]
static var textures: Dictionary={}
static var texture_order: Array=[]
static var texture_builds=0

static func palette(g: Dictionary) -> Dictionary:
	var color_gene=Genome.express(g,"color")
	var base: Color=Genome.COLORS[color_gene].lerp(Color("f7f2df"),0.22)
	var contrast=Genome.express(g,"contrast")/100.0
	var gloss=Genome.express(g,"gloss")/100.0
	var leaf=Color(LEAF_COLORS[color_gene])
	var bloom=Color(BLOOM_COLORS[color_gene]).lerp(Color("efc8ae"),Genome.express(g,"affinity")/500.0)
	return {"BASE":base.to_html(false),"SHADOW":base.lerp(Color("6d7696"),0.17+contrast*0.16).to_html(false),"LIGHT":base.lerp(Color("fffaed"),0.20+gloss*0.35).to_html(false),"INK":"343747","CREAM":"fff1d9","INNER":base.lerp(Color("dcaeab"),0.7).to_html(false),"ACCENT":leaf.lightened(0.1).to_html(false),"EYE":EYE_COLORS[Genome.express(g,"eyes")],"LEAF":leaf.to_html(false),"LEAF_SHADE":leaf.lerp(Color("56745b"),0.38).to_html(false),"LEAF_LIGHT":leaf.lerp(Color("e3e8b2"),0.42).to_html(false),"BLOOM":bloom.to_html(false),"BLOOM_SHADE":bloom.lerp(Color("a17b91"),0.38).to_html(false),"BLOOM_LIGHT":bloom.lerp(Color("fff1da"),0.4).to_html(false),"SEED":"efda94"}

static func markings(g: Dictionary, colors: Dictionary) -> String:
	var type=Genome.express(g,"pattern")
	var strength=0.10+Genome.express(g,"contrast")/400.0
	var result='<g fill="#%s" opacity="%.2f">' % [colors.INK,strength]
	if type==1:
		for i in range(5): result+='<path d="M %d 14 l 9 -3 -6 24 -7 5 Z"/>' % (17+i*15)
	elif type==2:
		for p in [Vector2(26,33),Vector2(53,23),Vector2(73,41),Vector2(26,58),Vector2(50,49),Vector2(65,65)]:
			result+='<ellipse cx="%d" cy="%d" rx="5" ry="4"/>' % [p.x,p.y]
	elif type==3:
		result+='<path d="M 10 18 Q 41 5 48 25 Q 52 47 27 49 L 5 40 Z M 60 59 Q 85 34 92 58 L 86 90 L 56 86 Z"/>'
	return result+'</g>'

static func part_texture(id: String, g: Dictionary) -> Texture2D:
	var colors=palette(g)
	var white=Genome.express(g,"white")
	var key=[id,hash(colors),Genome.express(g,"pattern"),Genome.express(g,"contrast"),white]
	# Facial overlays have no skin markings: share them across unrelated body colors.
	if id.begins_with("eyes_"): key=[id,colors.EYE]
	if id.begins_with("mouth_"): key=[id]
	if textures.has(key): return textures[key]
	var svg: String=CreaturePartLibrary.SVG[id]
	for color in colors: svg=svg.replace("%"+color+"%","#"+colors[color])
	svg=svg.replace("%PATTERN%",markings(g,colors))
	var patch=''
	if white>12:
		patch='<ellipse cx="50" cy="76" rx="%.1f" ry="%.1f" fill="url(#ivory)"/>' % [10+white*0.24,6+white*0.32]
	svg=svg.replace("%WHITE%",patch)
	var image=Image.new()
	var error=image.load_svg_from_string(svg,1.5)
	assert(error==OK,"Invalid body part: "+id)
	var texture=ImageTexture.create_from_image(image)
	textures[key]=texture; texture_order.append(key); texture_builds+=1
	if texture_order.size()>PART_CACHE_LIMIT: textures.erase(texture_order.pop_front())
	return texture

static func attachment(id: String, joint: String, g: Dictionary, size: Vector2=Vector2.ONE, pivot: Vector2=Vector2(48,48), shade: float=1.0) -> Dictionary:
	return {"id":id,"joint":joint,"texture":part_texture(id,g),"size":size,"pivot":pivot,"shade":shade}

static func build(u: UnitData) -> Dictionary:
	var key=[u.species,hash(u.genes)]
	if rigs.has(key): return rigs[key]
	var g=u.genes
	var species=u.species
	var form: Dictionary=FORMS[species]
	var body_name=Genome.body_name(g)
	var length=Genome.express(g,"length")/100.0
	var bone=Genome.express(g,"bone")/100.0
	var muscle=Genome.express(g,"muscle")/100.0
	var height=Genome.express(g,"height")/100.0
	var ear=Genome.express(g,"ears")
	var face=Genome.express(g,"face")
	var tail=Genome.express(g,"tail")
	var coat=Genome.express(g,"coat")
	var torso: String=BODY_TYPES[body_name]
	if length>0.7 and body_name not in ["大型","紧凑型"]: torso="long"
	if species==2 and body_name!="小型": torso="round"
	if species==4: torso="coil"
	var body_scale=Vector2(0.80+length*0.36+muscle*0.16,0.78+muscle*0.28+bone*0.14)
	body_scale*=form.body
	var legs=Vector2(0.64+bone*0.34+muscle*0.14,0.43+height*0.43)
	legs*=form.legs
	var body_y=-30*legs.y-11*body_scale.y
	if species==2: body_y-=9
	if species==4: body_y=-19
	var d={"body":torso,"scale":float(BODY_SIZE[body_name]),"body_scale":body_scale,"leg_scale":legs,"body_y":body_y,"head_offset":form.head*(body_scale if species!=4 else Vector2.ONE),"form":form,"parts":[],"ear":ear,"face":face,"tail":tail,"coat":coat,"species":species,"agility":Genome.express(g,"agility"),"affinity":Genome.express(g,"affinity"),"signature":key}
	var pieces: Array=d.parts
	pieces.append(attachment("tail_%d_%d" % [species,tail],"tail",g,Vector2(0.8+length*0.35,0.85+bone*0.22),Vector2(64,48)))
	if species!=4:
		pieces.append(attachment("limb_%d_hind"%species,"hind_far",g,legs*0.88,Vector2(48,48),0.88))
		pieces.append(attachment("limb_%d_fore"%species,"fore_far",g,legs*0.88,Vector2(48,48),0.88))
	else:
		pieces.append(attachment("fin_snake","hind_far",g,Vector2(0.8,0.65),Vector2(48,48),0.86))
	# Limbs start underneath the torso so their shoulder/hip roots have no cutout seam.
	if species!=4:
		pieces.append(attachment("limb_%d_hind"%species,"hind_near",g,legs))
	pieces.append(attachment("body_%d_%s"%[species,torso],"body",g,body_scale))
	# One large inherited plant organ per species; fewer overlapping small ornaments.
	var growth_size=[body_scale*Vector2(0.50,0.47),Vector2(0.62,0.70),body_scale*Vector2(0.50,0.45),body_scale*Vector2(0.45,0.45),Vector2(0.54,0.58)][species]
	pieces.append(attachment("growth_%d_%d"%[species,coat],"growth",g,growth_size))
	if species==4:
		pieces.append(attachment("neck_snake","neck",g,Vector2(0.9,0.9)))
	elif species==2:
		pieces.append(attachment("limb_2_fore","fore_near",g,Vector2(0.85+muscle*0.18,0.86+height*0.15)))
	else:
		pieces.append(attachment("limb_%d_fore"%species,"fore_near",g,legs))
	if species==0: pieces.append(attachment("bib_cat","chest",g,Vector2(0.35,0.40)))
	# Ears sit behind the head and have their own pivots and motion.
	pieces.append(attachment("ear_%d_%d"%[species,ear],"ear_far",g,form.ears*0.82,Vector2(48,48),0.88))
	pieces.append(attachment("ear_%d_%d"%[species,ear],"ear_near",g,form.ears))
	pieces.append(attachment("head_%d_%d"%[species,face],"head",g,form.skull))
	pieces.append(attachment("eyes_%d_%d_calm"%[species,face],"eyes",g,form.skull))
	pieces.append(attachment("mouth_%d_calm"%species,"mouth",g,form.skull))
	var flower_size=[0.25,0.22,0.22,0.20,0.23][species]
	pieces.append(attachment(["charm_bud","charm_gem","charm_ribbon"][mini(2,d.affinity/34)],"charm",g,Vector2.ONE*flower_size))
	if species==4: pieces.append(attachment("crown_snake","crest",g,Vector2(0.23+bone*0.09,0.21+muscle*0.09)))
	# Prewarm every expression with the rig, never rasterize an SVG on a skill frame.
	d.expressions={}
	for mood in EXPRESSIONS:
		d.expressions[mood]={"eyes":part_texture("eyes_%d_%d_%s"%[species,face,mood],g),"mouth":part_texture("mouth_%d_%s"%[species,mood],g)}
	rigs[key]=d; rig_order.append(key)
	if rig_order.size()>CACHE_LIMIT: rigs.erase(rig_order.pop_front())
	return d

static func joint(angle: float, offset: Vector2, size: Vector2=Vector2.ONE) -> Transform2D:
	return Transform2D(angle,size,0,offset)

static func face_expression(motion: Dictionary) -> String:
	var requested: String=motion.get("expression","")
	if requested in EXPRESSIONS: return requested
	match motion.get("state","idle"):
		"attack","cast": return "focus"
		"heal": return "happy"
		"hurt": return "hurt"
		"faint": return "sleep"
	return "calm"

static func facial_textures(d: Dictionary, phase: float, motion: Dictionary) -> Dictionary:
	var mood=face_expression(motion)
	var eye=mood
	var time: float=motion.get("face_time",phase*0.5)
	if mood in ["calm","focus"] and motion.get("blink",true) and fposmod(time+d.species*0.71,5.4)>5.28: eye="sleep"
	return {"eyes":d.expressions[eye].eyes,"mouth":d.expressions[mood].mouth}

static func pose(d: Dictionary, phase: float, motion: Dictionary={}) -> Dictionary:
	var state: String=motion.get("state","idle")
	var walking=state=="walk"
	var step=phase*(0.72+d.agility/220.0)
	var effort: float=motion.get("amount",0.65 if state in ["cast","attack"] else 0.0)
	var breath=sin(phase*1.1)*0.015
	var rise=absf(sin(step))*2.8 if walking else sin(phase)*0.5
	if d.species==2 and walking: rise=absf(sin(step))*5.0
	if d.species==3: rise*=0.4
	if d.species==4: rise=sin(step)*0.7
	var lean=-0.12*effort if state=="attack" else 0.0
	var sway=sin(step)*0.025 if walking else 0.0
	var result={}
	result.body=joint(lean+sway,Vector2(0,d.body_y-rise),Vector2(1-breath,1+breath))
	result.coat=result.body
	result.tail=result.body*joint(-0.18+sin(step*0.63)*0.18,d.form.tail*d.body_scale)
	for id in ["hind_far","fore_far","hind_near","fore_near"]:
		var front=id.begins_with("fore")
		var far=id.ends_with("far")
		var beat=step+(PI if front!=far else 0.0)
		if d.species==2: beat=step+(0.25 if far else 0.0)
		var angle=sin(beat)*(0.48 if walking else 0.02)
		if d.species==3: angle*=0.65
		if d.species==2 and front: angle=-0.3+sin(step)*0.09
		var lift=maxf(0,sin(beat))*4 if walking else 0.0
		if state=="cast" and front: angle=-1.0*effort
		if state=="attack" and front: angle=-0.75*effort
		var offset: Vector2=(d.form.front if front else d.form.hind)*d.body_scale+Vector2(4 if far else -3,-lift-(3 if far else 0))
		result[id]=result.body*joint(angle,offset)
	result.neck=result.body*joint(sin(step)*0.065-0.18*effort,Vector2(2,-24))
	var nod=-0.16*effort if state=="cast" else (0.12*effort if state=="hurt" else sin(step)*0.025)
	result.head=(result.neck if d.species==4 else result.body)*joint(nod,d.head_offset)
	result.ear_far=result.head*joint(0.3+sin(step+1)*0.065,d.form.ear_far)
	result.ear_near=result.head*joint(-0.22+sin(step)*0.07,d.form.ear_near)
	result.eyes=result.head
	result.mouth=result.head
	result.chest=result.body*joint(nod*0.35,Vector2(19,-4)*d.body_scale)
	var growth_offset=[Vector2(-16,-7),Vector2(18,-4),Vector2(-13,-5),Vector2(-16,-5),Vector2(-7,-8)][d.species]
	result.growth=(result.neck if d.species==4 else result.body)*joint(sin(step*0.72)*0.045,growth_offset*(Vector2.ONE if d.species==4 else d.body_scale))
	result.crest=result.body*joint(sin(step)*0.035,Vector2(-3,-15)) if d.species==3 else result.head*joint(0,Vector2(-11,-17))
	if d.species in [0,2,4]:
		result.charm=result.head*joint(sin(step)*0.04,[Vector2(-24,18),Vector2.ZERO,Vector2(-26,17),Vector2.ZERO,Vector2(-27,13)][d.species])
	else:
		result.charm=result.growth*joint(sin(step)*0.05,Vector2(-10,-1))
	return result

static func draw(canvas: CanvasItem, u: UnitData, center: Vector2, scale_factor: float, phase: float, motion: Dictionary) -> void:
	render(canvas,u,center,scale_factor,phase,motion,false)

static func draw_portrait(canvas: CanvasItem, u: UnitData, center: Vector2, scale_factor: float, phase: float, motion: Dictionary={}) -> void:
	render(canvas,u,center,scale_factor,phase,motion,true)

static func render(canvas: CanvasItem, u: UnitData, center: Vector2, scale_factor: float, phase: float, motion: Dictionary, portrait: bool) -> void:
	var d=build(u)
	phase=motion.get("phase",phase)
	var joints=pose(d,phase,motion)
	var face=facial_textures(d,phase,motion)
	var state: String=motion.get("state","idle")
	var facing: float=motion.get("facing",1.0)
	var size=0.45*scale_factor*d.scale
	# HUD portraits fit a fixed frame; world rigs retain inherited overall body size.
	if motion.is_empty(): size*=minf(1.0,1.05/d.scale)
	var opacity=0.62 if state=="faint" else 1.0
	var root=joint(0.7 if state=="faint" else 0.0,center+Vector2(0,13*scale_factor)+motion.get("offset",Vector2.ZERO),Vector2(facing*size,size))
	if portrait: root=joint(0,center,Vector2(facing*scale_factor,scale_factor))*joints.head.affine_inverse()
	var explode: float=motion.get("explode",0.0)
	for part in d.parts:
		if motion.get("base_form",false) and part.joint in ["growth","charm","chest","crest"]: continue
		if portrait and part.joint not in ["head","eyes","mouth","ear_near","ear_far"] and not (part.joint=="crest" and d.species==4) and not (part.joint=="charm" and d.species in [0,2,4]): continue
		var local: Transform2D=joints[part.joint]
		if explode>0:
			var outward=(local.origin-Vector2(0,d.body_y)).normalized()
			local.origin+=outward*explode
		var transform=root*local*joint(0,Vector2.ZERO,part.size)
		canvas.draw_set_transform_matrix(transform)
		var tint=Color(part.shade,part.shade,part.shade,opacity)
		if state=="hurt": tint=Color(1.5,0.64,0.57,opacity)
		if state=="heal": tint=Color(0.75,1.25,1.0,opacity)
		if motion.get("silhouette",false): tint=Color.BLACK
		canvas.draw_texture_rect(face.get(part.joint,part.texture),Rect2(-part.pivot,Vector2(96,96)),false,tint)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
