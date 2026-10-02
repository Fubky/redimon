from pathlib import Path
p=Path('scripts/board.gd');s=p.read_text(encoding='utf-8-sig').replace('res://assets/%s.svg','res://assets/art_v5/%s.svg');s=s.replace('atlas.texture = load("res://assets/%s_%s.svg" % ["tiles" if state.mode=="town" else "field",theme_name])','atlas.texture = load("res://assets/tiles_town.svg" if state.mode=="town" else "res://assets/art_v5/field_%s.svg" % theme_name)');s=s.replace('atlas.texture_region_size = Vector2i(40,40)','atlas.texture_region_size = Vector2i(40,40) if state.mode=="town" else Vector2i(80,80)');s=s.replace('for i in range(6 if state.mode=="town" else 24): atlas.create_tile(Vector2i(i%8,i/8))','''for i in range(6 if state.mode=="town" else 24):
		atlas.create_tile(Vector2i(i%8,i/8))
		if state.mode!="town": atlas.get_tile_data(Vector2i(i%8,i/8),0).texture_origin=Vector2i.ZERO''')
# Tile atlas physical region must match logical 40px; keep high-resolution SVG source vector scale at import 1x.
s=s.replace('Vector2i(40,40) if state.mode=="town" else Vector2i(80,80)','Vector2i(40,40)')
s=s.replace('Color(0.27,0.66,0.97,0.30)','Color(0.27,0.66,0.97,0.14)');s=s.replace('motion.draw_fx(self,unit_position)','EnvironmentArt.ambient(self)\n\tmotion.draw_fx(self,unit_position)');s=s.replace('func draw_town() -> void:', 'func draw_town() -> void:\n\tEnvironmentArt.garden(self)');s=s.replace('if u.faction=="enemy": draw_circle(c+Vector2(15,-19),3,Color("b26452"))','''if u.faction=="enemy": draw_circle(c+Vector2(15,-19),3,Color("b26452"))
		if state.mode=="battle":
			var kinds=BattleRules.types(u)
			for i in range(kinds.size()):
				draw_style_box(_style(Color(BattleRules.COLORS[kinds[i]]).darkened(0.3),Color.TRANSPARENT,0,3),Rect2(c+Vector2(-15+i*17,27),Vector2(15,12)))
				draw_string(font,c+Vector2(-13+i*17,36),BattleRules.TYPES[kinds[i]].left(1),HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("fff7dc"))
			if not u.status.is_empty(): plaque(BattleRules.STATUS_NAMES[u.status],c+Vector2(0,-47),54)
			if u.guard: draw_arc(c,23,PI,TAU,24,Color("a6e6db"),2,true)''');p.write_text(s,encoding='utf-8')
# SVG uses a 1:1 atlas grid; vector paths remain resolution independent in editor.
for p in Path('assets/art_v5').glob('field_*.svg'):
 s=p.read_text().replace('width="640" height="240"','width="320" height="120"');p.write_text(s)
p=Path('scripts/creature_art.gd');s=p.read_text(encoding='utf-8-sig');s=s.replace('canvas.draw_colored_polygon(points,color)\n\tcanvas.draw_polyline(points,outline,width,true)','''canvas.draw_colored_polygon(points,color)
	if color.a>0.5 and radii.x>4 and radii.y>5:
		var light=center-radii*Vector2(0.25,0.3)
		for i in range(32):
			canvas.draw_polygon(PackedVector2Array([light,points[i],points[i+1]]),PackedColorArray([color.lightened(0.18),color.darkened(0.13),color.darkened(0.13)]))
	canvas.draw_polyline(points,outline,width*0.65,true)''',1);s=s.replace('var ink = Color("3d4940")','var ink = Color("3e4d49")');s=s.replace('canvas.draw_circle(Vector2(0,-1+bob),1.7,ink)','''for x in [-10,10]:
		oval(canvas,Vector2(x,-1+bob),Vector2(2.8,1.8),Color(0.87,0.53,0.44,0.28),Color.TRANSPARENT,0)
	canvas.draw_circle(Vector2(0,-1+bob),1.5,ink)''');s=s.replace('Color("799881"),ink)','Color("739f8c"),ink)\n\t\tpolygon(canvas,[Vector2(8,9),Vector2(17,13),Vector2(12,17),Vector2(7,11)],Color("82b29b"),ink)\n\t\tcanvas.draw_circle(Vector2(-5,9),1.5,Color("f1d597"))');p.write_text(s,encoding='utf-8')
