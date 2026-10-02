class_name DungeonMovement
extends RefCounted
## Held input repeats independently of OS key-repeat. A click plans one route.
const STEP_SECONDS=0.14
var game: GameState
var goal=Vector2i(-1,-1)
var route: Array[Vector2i]=[]
var cooldown=0.0
var context: Array=[]
var path_requests=0
var previous_direction=Vector2i.ZERO

func setup(state: GameState) -> void: game=state

func cancel() -> void:
	goal=Vector2i(-1,-1); route.clear(); cooldown=0.0
	previous_direction=Vector2i.ZERO

func update(delta: float, direction: Vector2, destination: Vector2i) -> Vector2i:
	if game.mode!="explore" or game.current()==null:
		cancel(); return goal
	var actor=game.current()
	var key=[game.world.get_instance_id(),actor.uid]
	if key!=context:
		cancel(); context=key
	var axis=Vector2i.ZERO
	if not direction.is_zero_approx():
		axis=Vector2i(signi(int(direction.x*100)),0) if absf(direction.x)>=absf(direction.y) else Vector2i(0,signi(int(direction.y*100)))
	cooldown=maxf(-STEP_SECONDS,cooldown-minf(delta,STEP_SECONDS))
	if axis!=Vector2i.ZERO:
		goal=Vector2i(-1,-1); route.clear()
		if previous_direction==Vector2i.ZERO: cooldown=0
		previous_direction=axis
		if cooldown<=0:
			game.move_to(actor.cell+axis)
			cooldown+=STEP_SECONDS
	else:
		previous_direction=Vector2i.ZERO
		if destination!=goal:
			goal=destination; route.clear(); cooldown=0
			if goal.x>=0:
				path_requests+=1
				route=game.world.path(actor.cell,goal,game.occupied(actor))
		if goal.x>=0 and cooldown<=0:
			if route.is_empty() or game.distance(actor.cell,route[0])!=1:
				cancel()
			elif game.move_to(route[0]):
				route.pop_front(); cooldown+=STEP_SECONDS
				if route.is_empty(): goal=Vector2i(-1,-1)
			else: cancel() # Do not endlessly retry a newly occupied destination.
	if game.mode!="explore": cancel()
	return goal
