class_name EnvironmentArt
extends RefCounted

static func ambient(board: GameBoard) -> void:
 var t=board.animation_time
 var town=board.state.mode=="town"
 var biome=0 if town else board.state.world.biome
 # Sparse animated pollen, embers, drizzle or crystal motes; reveal only explored ground.
 for i in range(42):
  var p=Vector2(fposmod(i*137.3+t*(4+i%3),1040),fposmod(i*81.7-t*(5+i%4),640))
  var cell=Vector2i(p/40)
  if not town and not board.visible_cells.has(cell): continue
  var color=[Color("efe2a0"),Color("e7dfc4"),Color("b8e8e1"),Color("eea86e"),Color("bcc0ed")][biome]
  color.a=0.25+0.25*sin(t+i)
  if biome==2:
   board.draw_line(p,p+Vector2(-3,9),color,0.7,true)
  else:
   board.draw_circle(p,1.3+i%2,color)
   board.draw_circle(p,3.5,Color(color,0.05))
static func garden(board: CanvasItem) -> void:
 # Canopy clusters frame the town without obstructing doors or walking routes.
 for i in range(14):
  var p=Vector2(25+i*76,32 if i%2==0 else 610)
  board.draw_circle(p+Vector2(6,13),26,Color(0.1,0.25,0.21,0.15))
  for j in range(5):
   var q=p+Vector2.from_angle(j*1.3)*12
   CreatureArt.oval(board,q,Vector2(16,14),Color("729571").lightened(j*0.024),Color("476951"),0.8)
 for i in range(25):
  var p=Vector2(50+fmod(i*173.0,930),240+sin(i*4.0)*170)
  if Rect2(310,270,340,120).has_point(p): continue
  board.draw_line(p,p+Vector2(0,7),Color("67885c"),1,true)
  for j in range(5): board.draw_circle(p+Vector2.from_angle(j*TAU/5)*2,1.6,Color("e4c498") if i%2 else Color("dcad9b"))
  board.draw_circle(p,1,Color("f8e6ae"))
