class_name CombatHUD
extends Control
## All positions on the rail represent real ticks. Portraits fan out only to
## prevent overlap; connectors retain the precise scheduling position.
var app
const DARK=Color("17273a")
const LIGHT=Color("f5edd9")
const MUTED=Color("9fbac8")
const ALLY=Color("9bdcce")
const ENEMY=Color("e59080")
const GOLD=Color("f1c77a")
var redraw_key: Array=[]

func _process(_delta: float) -> void:
	var prediction=preview()
	var key=[app.board.preview_revision,app.chosen_skill,app.battle_selection,prediction.cost,prediction.target,prediction.shift,app.game.clock]
	if key!=redraw_key:
		redraw_key=key
		queue_redraw()

func text_at(value: String, p: Vector2, size_px: int=14, color: Color=LIGHT) -> void:
	draw_string(app.font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)

func preview() -> Dictionary:
	var point: Vector2=app.board.pointer_screen
	var over_map=Rect2(Vector2.ZERO,app.map_frame.size).has_point(point) and not app.field_overlay.consumes_point(point) and not app.hud_blocks_point(point)
	return preview_at(app.board.hover,over_map)

func preview_at(cell: Vector2i, over_map: bool) -> Dictionary:
	var g: GameState=app.game
	var actor=g.current()
	var result={"cost":0,"target":null,"shift":0}
	if actor==null or actor.faction!="party" or app.battle_selection!=actor.uid: return result
	var id: String=app.chosen_skill
	if id=="move":
		if not actor.moved and over_map and app.board.visible_cells.has(cell) and g.unit_at(cell)==null:
			result.cost=maxi(0,app.board.move_cost(cell))
	elif actor.has_skill(id) and actor.ap>=GameState.SKILLS[id].cost:
		result.cost=GameState.SKILLS[id].cost
		var target=g.unit_at(cell) if over_map and app.board.visible_cells.has(cell) else null
		if g.can_cast(id,target):
			result.target=target
			result.shift=GameState.SKILLS[id].get("shift",0)+g.predict(id,target).bonus_shift
	return result

func diamond(p: Vector2, color: Color, hollow: bool=false) -> void:
	var points=PackedVector2Array([p+Vector2(0,-6),p+Vector2(6,0),p+Vector2(0,6),p+Vector2(-6,0),p+Vector2(0,-6)])
	if hollow: draw_polyline(points,color,1.5,true)
	else: draw_colored_polygon(points,color)

func _draw() -> void:
	if app==null or app.game.mode!="battle": return
	var g: GameState=app.game
	var u=g.current()
	if u==null: return
	var prediction=preview()
	var cost: int=prediction.cost
	var burst=u.spent+cost>50
	var preview_color=GameBoard.BURST_MOVE if burst else GameBoard.SAFE_MOVE
	draw_style_box(app.box(DARK,Color("53625b"),1,10),Rect2(0,0,302,205))
	draw_style_box(app.box(DARK,Color("53625b"),1,10),Rect2(320,0,1064,118))
	draw_circle(Vector2(43,40),29,Color("43564e"))
	CreatureArt.draw(self,u,Vector2(43,51),0.92)
	text_at(u.display_name+"   Lv.%d" % u.level,Vector2(81,25),19)
	text_at("%s · %s" % [MercenaryRules.JOBS[u.profession],"我方行动" if u.faction=="party" else "敌方行动"],Vector2(81,45),12,ALLY if u.faction=="party" else ENEMY)
	text_at(BattleRules.info(u),Vector2(81,64),10,MUTED)
	text_at("HP",Vector2(18,85),12,ALLY)
	draw_style_box(app.box(Color("111d20"),Color.TRANSPARENT,0,3),Rect2(47,75,234,12))
	draw_style_box(app.box(ALLY,Color.TRANSPARENT,0,3),Rect2(47,75,234*float(u.hp)/u.max_hp(),12))
	text_at("%d / %d" % [u.hp,u.max_hp()],Vector2(129,85),11,DARK)
	text_at("AP",Vector2(18,117),16,GOLD)
	text_at(str(u.ap),Vector2(53,120),32)
	text_at("/ 100",Vector2(117,117),13,MUTED)
	text_at("爆发 · 长延迟" if u.spent>50 else "快速回归",Vector2(178,115),13,ENEMY if u.spent>50 else ALLY)
	for i in range(10):
		var segment=Rect2(18+i*26.5,130,23.5,10)
		draw_rect(segment,Color("45504e"))
		segment.size.x*=clampf((u.ap-i*10)/10.0,0,1)
		draw_rect(segment,ENEMY if i<5 else ALLY)
	if cost>0:
		var safe_cost=mini(cost,maxi(0,50-u.spent))
		var burst_cost=cost-safe_cost
		if safe_cost>0: draw_rect(Rect2(18+(u.ap-safe_cost)*2.65,128,safe_cost*2.65,14),Color(GameBoard.SAFE_MOVE,0.6))
		if burst_cost>0: draw_rect(Rect2(18+(u.ap-cost)*2.65,128,burst_cost*2.65,14),Color(GameBoard.BURST_MOVE,0.85))
		draw_rect(Rect2(18+(u.ap-cost)*2.65,128,cost*2.65,14),preview_color,false,1.5)
	draw_line(Vector2(149,126),Vector2(149,143),LIGHT,1)
	text_at("50",Vector2(141,152),10,MUTED)
	text_at("预览 %d AP → 剩余 %d · 回归 +%d" % [cost,u.ap-cost,g.return_delay(u,cost)] if cost>0 else "已用 %d AP · 结束后回归 +%d 刻" % [u.spent,g.return_delay(u)],Vector2(18,166),12,preview_color if cost>0 else MUTED)
	if cost>0 and app.chosen_skill=="move":
		draw_style_box(app.box(DARK,preview_color,2,8),Rect2(320,-83,900,68))
		text_at("移动 %d 格 · 消耗 %d AP · 剩余 %d AP" % [cost/8,cost,u.ap-cost],Vector2(338,-57),19,LIGHT)
		var warning="安全移动：累计消耗不超过 50 AP，保持快速回归。"
		if burst:
			warning="超过 50 AP：下次行动额外延后 %d 刻；预计从现在起 +%d 刻回归。" % [g.return_delay(u,cost)-g.return_delay(u),g.return_delay(u,cost)] if u.spent<=50 else "已处于爆发区：此次移动后，预计从现在起 +%d 刻回归。" % g.return_delay(u,cost)
		text_at(warning,Vector2(338,-32),16,preview_color)
	# Timeline header, real-time rail and adaptive scale.
	text_at(BattleRules.WEATHER[g.world.biome],Vector2(338,-10),12,MUTED)
	text_at("行动时间轴",Vector2(338,23),16)
	text_at("T +%d   /   从左向右行动" % g.clock,Vector2(456,23),12,MUTED)
	text_at("%s +%d 刻%s" % ["预计回归" if cost>0 else "结束后回归",g.return_delay(u,cost)," · 爆发" if burst else " · 常规"],Vector2(1065,23),13,GOLD if not burst else ENEMY)
	var ordered=g.timeline()
	var horizon=160
	for actor in ordered: horizon=maxi(horizon,maxi(0,actor.ready_at-g.clock)+20)
	if prediction.target!=null: horizon=maxi(horizon,prediction.target.ready_at-g.clock+prediction.shift+20)
	horizon=ceili(horizon/40.0)*40
	var left=350.0
	var width=994.0
	var rail_y=94.0
	draw_line(Vector2(left,rail_y),Vector2(left+width,rail_y),MUTED,1.5)
	for tick in range(0,horizon+1,horizon/8):
		var x=left+width*tick/horizon
		draw_line(Vector2(x,rail_y-4),Vector2(x,rail_y+4),MUTED,1)
		text_at("现在" if tick==0 else "+%d" % tick,Vector2(x-10,112),10,MUTED)
	var positions: Array[float]=[]
	for i in range(ordered.size()):
		var tick=0 if ordered[i]==u else maxi(0,ordered[i].ready_at-g.clock)
		var x=left+width*tick/horizon
		positions.append(maxf(x,positions[-1]+62 if i>0 else left))
	for i in range(positions.size()-1,-1,-1):
		positions[i]=minf(positions[i],left+width if i==positions.size()-1 else positions[i+1]-62)
	for i in range(ordered.size()):
		var actor: UnitData=ordered[i]
		var tick=0 if actor==u else maxi(0,actor.ready_at-g.clock)
		var x=left+width*tick/horizon
		var px=positions[i]
		var color=ALLY if actor.faction=="party" else ENEMY
		draw_line(Vector2(px,77),Vector2(x,rail_y),color,1,true)
		diamond(Vector2(x,rail_y),color)
		draw_circle(Vector2(px,48),20,Color("3b4b47"))
		draw_arc(Vector2(px,48),20,0,TAU,32,GOLD if actor==u else color,2,true)
		CreatureArt.draw(self,actor,Vector2(px,59),0.62)
		text_at(actor.display_name.left(3)+" · "+str(tick),Vector2(px-28,79),10,LIGHT if actor==u else color)
	# Ghost marker is the active actor's NEXT turn, not its current portrait.
	var return_x=left+width*g.return_delay(u,cost)/horizon
	draw_dashed_line(Vector2(return_x,32),Vector2(return_x,100),preview_color,1,4)
	diamond(Vector2(return_x,rail_y),preview_color,true)
	if prediction.target!=null and prediction.shift!=0:
		var target: UnitData=prediction.target
		var from_x=left+width*maxi(0,target.ready_at-g.clock)/horizon
		var to_tick=maxi(1,target.ready_at-g.clock+prediction.shift)
		var to_x=left+width*to_tick/horizon
		draw_dashed_line(Vector2(from_x,87),Vector2(to_x,87),GOLD,2,4)
		diamond(Vector2(to_x,rail_y),GOLD,true)
		text_at("%s %+d" % [target.display_name,prediction.shift],Vector2(735,23),13,GOLD)

	if prediction.target!=null:
		var info=g.predict(app.chosen_skill,prediction.target)
		if not info.is_empty():
			var target: UnitData=prediction.target
			var panel_y=-108.0
			draw_style_box(app.box(DARK,GOLD,1,8),Rect2(320,panel_y,880,94))
			text_at(target.display_name+" · "+BattleRules.info(target),Vector2(336,panel_y+23),14)
			text_at("预计伤害 %d · 克制 ×%.2f · 命中 %d%% · 招募 %.1f%%" % [info.damage,info.effect,info.accuracy,info.rate],Vector2(336,panel_y+48),15,GOLD)
			var hint=""
			if not info.tactic.is_empty(): hint=info.tactic+"！伤害加成已计入 · 额外延后 %d 刻" % info.bonus_shift
			elif g.expedition_plan=="relay" and target.faction=="enemy" and GameState.SKILLS[app.chosen_skill].has("power") and info.effect>0: hint="该敌人本轮已触发协同" if target.combo_used else ("已有协同标记，换另一位队友命中可触发追击" if not target.combo_from.is_empty() else "直接伤害命中后留下协同标记，供另一位队友接力")
			elif g.expedition_plan=="burst": hint="本回合强攻已使用" if u.burst_used else "累计消耗超过 50 AP 后的首次有效直接伤害可触发强攻"
			elif g.expedition_plan=="tempo": hint="消耗 1—50 AP 后结束：最多提前 12 刻回归；空过无加速"
			text_at(hint,Vector2(336,panel_y+74),14,ALLY)
