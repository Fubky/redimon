class_name HumanAssembly
extends RefCounted
## All portraits and poses share an articulated paper doll, never a complete image.
const CACHE_LIMIT=96
const PART_CACHE_LIMIT=768
const EXPRESSIONS=["calm","focus","happy","hurt","sleep","surprise"]
const SKIN=["efd0af","dab08b","b98362","805640","e2c4bc","acaba6"]
const HAIR=["352e35","674539","ae7946","cfb684","86818e","d5d1c5"]
const EYE_COLORS=["8b9e5b","b5884e","5c9dab","a06c69","8c75ad"]
const CLOTH=["43667c","715573","566d55"]
const BODY_SIZE={"紧凑型":0.91,"小型":0.95,"中型":1.0,"中大型":1.06,"大型":1.12}
static var rigs: Dictionary={}
static var rig_order: Array=[]
static var textures: Dictionary={}
static var texture_order: Array=[]
static var texture_builds=0

static func palette(g: Dictionary, job: int=0) -> Dictionary:
	var skin=Color(SKIN[Genome.express(g,"color")]); var hair=Color(HAIR[mini(5,Genome.express(g,"contrast")/17)])
	var cloth=Color(CLOTH[job]); var scales=Color(["729992","8b8d6a","7a90a5","bd916e"][Genome.express(g,"tail")])
	return {"FEATHER":["bfa47d","454e60","e9e3cf","bfa47d"][Genome.express(g,"tail")],"INK":"293445","SKIN":skin.to_html(false),"SKIN_SHADE":skin.darkened(0.17).to_html(false),"CLOTH":cloth.to_html(false),"CLOTH_DARK":cloth.darkened(0.3).to_html(false),"METAL":"94aabb","METAL_LIGHT":"d6e3df","METAL_DARK":"56707e","GOLD":"d8b36d","LEATHER":"8c634d","LEATHER_DARK":"493f40","IVORY":"f8eacd","GEM":"8ed6cf","HAIR":hair.to_html(false),"HAIR_LIGHT":hair.lightened(0.23).to_html(false),"EYE":EYE_COLORS[Genome.express(g,"eyes")],"SCALES":scales.to_html(false)}

static func part_texture(id: String, g: Dictionary, job: int=0) -> Texture2D:
	var colors=palette(g,job); var source: String=HumanPartLibrary.SVG[id]; var key=id
	for token in colors:
		if source.contains("%"+token+"%"):
			source=source.replace("%"+token+"%","#"+colors[token]); key+="/"+colors[token]
	if textures.has(key): return textures[key]
	var image=Image.new(); var error=image.load_svg_from_string(source,2.0)
	assert(error==OK,"Invalid humanoid part: "+id)
	var texture=ImageTexture.create_from_image(image)
	textures[key]=texture; texture_order.append(key); texture_builds+=1
	if texture_order.size()>PART_CACHE_LIMIT: textures.erase(texture_order.pop_front())
	return texture

static func attachment(id: String, joint: String, u: UnitData, offset: Vector2=Vector2.ZERO, scale: Vector2=Vector2.ONE) -> Dictionary:
	return {"id":id,"joint":joint,"texture":part_texture(id,u.genes,u.profession),"offset":offset,"size":scale}

static func build(u: UnitData) -> Dictionary:
	var key=[u.profession,hash(u.genes)]
	if rigs.has(key): return rigs[key]
	var g=u.genes; var job=["knight","mage","ranger"][u.profession]; var parts=[]
	var tail=Genome.express(g,"tail"); var ear=Genome.express(g,"ears")
	var expressed=Genome.expressed_traits(g)
	var bird="plumage" in expressed
	var dragon="scales" in expressed
	var beast="feral" in expressed
	var fish="fins" in expressed
	var snake="coils" in expressed
	var dragon_wing=dragon and Genome.express(g,"white")>=60
	if bird or dragon_wing:
		var wing="bird_wing_%d"%(tail%3) if bird and (not dragon_wing or Genome.express(g,"plumage")>=Genome.express(g,"scales")) else "dragon_wing"
		parts.append(attachment(wing,"wing_l",u,Vector2.ZERO,Vector2(-1,1))); parts.append(attachment(wing,"wing_r",u))
	else: parts.append(attachment("cape","body",u,Vector2(0,-3)))
	if not fish and not snake:
		if dragon and (not beast or Genome.express(g,"scales")>=Genome.express(g,"feral")): parts.append(attachment("lizard_tail","tail",u))
		elif beast: parts.append(attachment("cat_tail" if ear!=1 else "dog_tail","tail",u))
	if fish or snake: parts.append(attachment("fish_tail" if fish and (not snake or Genome.express(g,"fins")>=Genome.express(g,"coils")) else "snake_tail","lower",u))
	else:
		for side in ["l","r"]:
			parts.append(attachment(job+"_leg","leg_"+side,u)); parts.append(attachment(job+"_boot","foot_"+side,u))
	parts.append(attachment(job+"_arm","arm_l",u)); parts.append(attachment("claw_hand" if beast else "hand","hand_l",u))
	parts.append(attachment(job+"_torso","body",u)); parts.append(attachment("head_%d"%Genome.express(g,"face"),"head",u))
	if dragon: parts.append(attachment("scales_face","head",u))
	parts.append(attachment("hair_%d"%Genome.express(g,"coat"),"head",u)); parts.append(attachment("face_calm","face",u))
	parts.append(attachment("hat_"+job,"hat",u))
	if beast: parts.append(attachment("cat_ears" if ear!=1 else "dog_ears","head",u,Vector2(0,-5)))
	if "horns" in expressed: parts.append(attachment("horns_%d"%ear,"head",u,Vector2(0,-3)))
	parts.append(attachment(job+"_arm","arm_r",u)); parts.append(attachment(["sword","staff","bow"][u.profession],"weapon",u))
	parts.append(attachment("claw_hand" if beast else "hand","hand_r",u))
	var faces={}
	for mood in EXPRESSIONS: faces[mood]=part_texture("face_"+mood,g,u.profession)
	var result={"parts":parts,"faces":faces,"traits":expressed,"scale":BODY_SIZE[Genome.body_name(g)],"width":0.9+Genome.express(g,"muscle")/500.0,"height":0.94+Genome.express(g,"height")/800.0,"head_scale":0.97+Genome.express(g,"bone")/1600.0}
	rigs[key]=result; rig_order.append(key)
	if rig_order.size()>CACHE_LIMIT: rigs.erase(rig_order.pop_front())
	return result

static func pose(d: Dictionary, phase: float, motion: Dictionary={}) -> Dictionary:
	phase=motion.get("phase",phase)
	var state=motion.get("state","idle"); var amount=float(motion.get("amount",0.0))
	if state in ["attack","cast"] and amount==0: amount=(sin(phase*2)+1)*0.5
	var stride=sin(phase)*0.34 if state=="walk" else 0.0
	var bob=absf(sin(phase))*1.5 if state=="walk" else sin(phase)*0.5
	var joints={}
	for e in [["body",Vector2(0,-34),0.0],["lower",Vector2(0,-7),stride*0.1],["tail",Vector2(-5,-15),sin(phase)*0.09],["head",Vector2(0,-64),sin(phase*0.5)*0.02],["face",Vector2(0,-64),sin(phase*0.5)*0.02],["hat",Vector2(0,-66),sin(phase*0.5)*0.02],["wing_l",Vector2(-9,-47),-sin(phase)*0.06],["wing_r",Vector2(9,-47),sin(phase)*0.06]]:
		joints[e[0]]=Transform2D(e[2],e[1]+Vector2(0,bob))
	for side in ["l","r"]:
		var sign=-1.0 if side=="l" else 1.0; var swing=stride*sign
		var arm_angle=-swing+(amount*-0.95 if side=="r" and state in ["cast","attack"] else 0.0)
		var shoulder=Vector2(sign*17,-43)+Vector2(0,bob)
		joints["arm_"+side]=Transform2D(arm_angle,shoulder)
		var palm=shoulder+Vector2(0,20).rotated(arm_angle)
		joints["hand_"+side]=Transform2D(arm_angle,palm)
		joints["leg_"+side]=Transform2D(swing,Vector2(sign*7,-13)+Vector2(0,bob))
		joints["foot_"+side]=Transform2D(swing*0.3,Vector2(sign*7,-13)+Vector2(0,17).rotated(swing)+Vector2(0,bob))
		if side=="r": joints.weapon=Transform2D(arm_angle+0.12-amount*0.25,palm+Vector2(2,-10).rotated(arm_angle))
	return joints

static func draw(canvas: CanvasItem, u: UnitData, center: Vector2, scale_factor: float=1.0, phase: float=0.0, motion: Dictionary={}) -> void:
	var d=build(u); var joints=pose(d,phase,motion); var scale=0.57*scale_factor*d.scale
	var root=Transform2D(0,Vector2(scale*float(motion.get("facing",1.0))*d.width,scale*d.height),0,center+Vector2(0,7*scale_factor)+motion.get("offset",Vector2.ZERO))
	var mood=motion.get("expression","calm")
	if motion.get("state","") in ["cast","attack"]: mood="focus"
	if motion.get("state","")=="hurt": mood="hurt"
	if motion.get("state","")=="heal": mood="happy"
	if u.status=="sleep" or (motion.get("blink",true) and fmod(float(motion.get("face_time",phase))+(hash(u.uid)%13)*0.47,5.6)>5.43): mood="sleep"
	for p in d.parts:
		var transform: Transform2D=root*joints[p.joint]*Transform2D(0,p.size,0,p.offset)
		if p.joint in ["head","face","hat"]: transform=transform.scaled_local(Vector2.ONE*d.head_scale)
		canvas.draw_set_transform_matrix(transform)
		var color=Color.BLACK if motion.get("silhouette",false) else Color.WHITE
		if motion.get("state","")=="hurt": color=Color(1,0.72,0.72)
		if motion.get("state","")=="faint": color.a=0.4
		canvas.draw_texture_rect(d.faces.get(mood,p.texture) if p.joint=="face" else p.texture,Rect2(-64,-64,128,128),false,color)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

static func draw_portrait(canvas: CanvasItem, u: UnitData, center: Vector2, scale_factor: float=1.0, phase: float=0.0, motion: Dictionary={}) -> void:
	var d=build(u); var mood=motion.get("expression","calm")
	for p in d.parts:
		if not p.joint in ["head","face","hat"]: continue
		canvas.draw_set_transform(center+p.offset*scale_factor,0,Vector2.ONE*scale_factor)
		canvas.draw_texture_rect(d.faces.get(mood,p.texture) if p.joint=="face" else p.texture,Rect2(-64,-64,128,128),false)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
