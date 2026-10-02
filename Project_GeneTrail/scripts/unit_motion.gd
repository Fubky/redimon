class_name UnitMotion
extends RefCounted
## Sprite pose selection, movement offsets and elemental effects shared by all creatures.
var tracks: Dictionary={}
var actions: Array=[]
var current: Dictionary={}
var clock=0.0
var audio: GameAudio
static var glow_texture: GradientTexture2D

static func glow() -> Texture2D:
	if glow_texture==null:
		var gradient=Gradient.new()
		gradient.set_color(0,Color(1,1,1,0.65)); gradient.set_color(1,Color(1,1,1,0))
		glow_texture=GradientTexture2D.new(); glow_texture.gradient=gradient
		glow_texture.width=64; glow_texture.height=64
		glow_texture.fill=GradientTexture2D.FILL_RADIAL
		glow_texture.fill_from=Vector2(0.5,0.5); glow_texture.fill_to=Vector2(1,0.5)
	return glow_texture

func enqueue(actor: UnitData, target: UnitData, skill: String) -> void:
	if actor==null or target==null: return
	actions.append({"actor":actor,"target":target,"skill":skill,"age":0.0,"duration":0.82})

func busy() -> bool: return not current.is_empty() or not actions.is_empty()

func update(units: Array, position_of: Callable, moving_route: bool, delta: float) -> void:
	clock+=delta
	for u in units:
		var p: Vector2=position_of.call(u)
		if not tracks.has(u.uid): tracks[u.uid]={"position":p,"phase":0.0,"moving":false,"facing":1.0}
		var track=tracks[u.uid]
		var velocity=p-track.position
		track.moving=velocity.length()>0.05
		if absf(velocity.x)>0.05: track.facing=signf(velocity.x)
		track.phase+=delta*(16 if track.moving else 2)
		track.position=p
	if current.is_empty() and not actions.is_empty() and not moving_route:
		current=actions.pop_front()
		if audio!=null:
			var rule=GameState.SKILLS[current.skill]
			audio.sfx("heal" if rule.has("heal") else ("delay" if rule.has("shift") else ("cast" if rule.range>1 else "hit")))
	if not current.is_empty():
		current.age+=delta
		if current.age>=current.duration:
			if not current.target.alive() and audio!=null: audio.sfx("defeat",true)
			current={}

func pose(u: UnitData) -> Dictionary:
	var track=tracks.get(u.uid,{"phase":clock*2,"moving":false,"facing":1.0})
	var result={"state":"walk" if track.moving else "idle","phase":track.phase,"face_time":clock,"facing":track.facing,"amount":0.0,"offset":Vector2.ZERO}
	if current.is_empty(): return result
	var t=clampf(current.age/current.duration,0,1)
	var rule=GameState.SKILLS[current.skill]
	if u==current.actor:
		result.state="cast" if rule.range>2 or rule.target!="enemy" or rule.get("damage_type","")=="magic" else "attack"
		result.amount=sin(t*PI)
		var direction=Vector2(current.target.cell-current.actor.cell).normalized()
		if direction.x!=0: result.facing=signf(direction.x)
		result.offset=direction*sin(t*PI)*8 if result.state=="attack" else Vector2(0,-sin(t*PI)*3)
	if u==current.target and t>0.35:
		result.state="heal" if rule.has("heal") or rule.target!="enemy" else ("hurt" if u.alive() else "faint")
		result.amount=sin((t-0.35)/0.65*PI)
		if result.state=="hurt": result.offset=Vector2(sin(t*48)*2.8,0)
	return result

func should_draw(u: UnitData) -> bool:
	return u.alive() or (not current.is_empty() and u==current.target)

func draw_fx(canvas: CanvasItem, position_of: Callable) -> void:
	if current.is_empty(): return
	var t=clampf(current.age/current.duration,0,1)
	var a: Vector2=position_of.call(current.actor)
	var b: Vector2=position_of.call(current.target)
	var rule=GameState.SKILLS[current.skill]
	var color=Color("bde9c2") if rule.target!="enemy" else Color(BattleRules.COLORS[rule.get("element","normal")]).lightened(0.15)
	var element: String=rule.get("element","normal")
	var intensity=sin(t*PI)
	# One cached radial texture supplies a soft pool of light beneath the impact.
	canvas.draw_texture_rect(glow(),Rect2(b-Vector2(42,28),Vector2(84,56)),false,Color(color,intensity*0.65))
	if t<0.5:
		canvas.draw_arc(a,12+t*13,PI*0.05,PI*1.9,28,Color(color,intensity*0.7),1.5,true)
	if rule.target=="enemy" and rule.range<=1 and t>0.2 and t<0.75:
		var slash=(t-0.2)/0.55
		for i in range(3):
			var start=b+Vector2(-19+i*8,-20+slash*9)
			canvas.draw_line(start,start+Vector2(14,27)*sin(slash*PI),Color("fff0cc",sin(slash*PI)),3-i*0.5,true)
	if rule.target=="enemy" and rule.range>1 and t<0.62:
		var p=a.lerp(b,clampf(t/0.62,0,1))-Vector2(0,sin(t/0.62*PI)*16)
		for i in range(5):
			var trail=maxf(0,t/0.62-i*0.055)
			var q=a.lerp(b,trail)-Vector2(0,sin(trail*PI)*16)
			canvas.draw_circle(q,5-i*0.7,Color(color,0.65-i*0.11))
		canvas.draw_circle(p,10,Color(color,0.09))
		canvas.draw_circle(p,7,Color(color,0.18))
		canvas.draw_circle(p,5,color)
		canvas.draw_circle(p,2,Color.WHITE)
	if t>0.28:
		var progress=(t-0.28)/0.72
		color.a=1.0-progress
		canvas.draw_arc(b,6+progress*26,0,TAU,32,color,2.5,true)
		for i in range(8):
			var p=b+Vector2.from_angle(i*TAU/8.0+progress)*(8+progress*22)
			if rule.has("heal"):
				p.y-=progress*20
				canvas.draw_line(p-Vector2(3,0),p+Vector2(3,0),color,2)
				canvas.draw_line(p-Vector2(0,3),p+Vector2(0,3),color,2)
			else: canvas.draw_line(p,p+Vector2.from_angle(i*TAU/8.0)*7,color,2,true)
		if rule.has("shift"):
			canvas.draw_arc(b,17,0,TAU,32,color,1.5,true)
			canvas.draw_line(b,b+Vector2.from_angle(t*TAU*2)*13,color,2,true)
			for tick in range(12):
				var direction=Vector2.from_angle(tick*TAU/12.0-PI/2)
				canvas.draw_line(b+direction*20,b+direction*(24 if tick%3==0 else 22),color,1.5,true)
		# Elements have different readable silhouettes, in addition to their color.
		for i in range(6):
			var direction=Vector2.from_angle(i*TAU/6.0+0.35)
			var point=b+direction*(8+progress*29)
			match element:
				"fire":
					point.y-=progress*15
					canvas.draw_colored_polygon(PackedVector2Array([point+Vector2(-3,3),point+Vector2(0,-7),point+Vector2(3,3)]),color)
				"water":
					canvas.draw_arc(point,3+progress*2,0,TAU,12,color,1.5,true)
				"stone":
					canvas.draw_rect(Rect2(point-Vector2(3,3),Vector2(6,6)),color)
				"leaf":
					canvas.draw_colored_polygon(PackedVector2Array([point-direction*5,point+direction.orthogonal()*3,point+direction*5,point-direction.orthogonal()*3]),color)
				"wind":
					canvas.draw_arc(b,16+progress*24+i*2,i*1.0,i*1.0+0.6,10,color,1,true)
				"frost","spirit":
					canvas.draw_line(point-Vector2(0,4),point+Vector2(0,4),color,2)
					canvas.draw_line(point-Vector2(4,0),point+Vector2(4,0),color,2)
