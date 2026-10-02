class_name TownMovement
extends RefCounted
## Continuous circle movement and a small visibility graph; no grid snapping.
const SPEED = 180.0
const RADIUS = 11.0
const BOUNDS = Rect2(40,40,960,560)
const BLOCKERS = [Rect2(139,149,129,99),Rect2(699,149,129,99),Rect2(139,429,129,99),Rect2(699,429,129,99),Rect2(340,427,116,105),Rect2(606,507,206,17),Rect2(511,87,18,62),Rect2(555,245,63,39)]
const DOORS = {"home":Vector2(201,276),"shop":Vector2(761,276),"nursery":Vector2(201,556),"storage":Vector2(761,556),"expeditions":Vector2(521,167),"contracts":Vector2(585,297)}
var state: GameState
var route: Array[Vector2] = []
var destination = Vector2(-1,-1)
var leader_id: String = ""
var nodes: Array[Vector2] = []
var links: Dictionary = {}
var follower_routes: Dictionary = {}
var follower_timers: Dictionary = {}

func setup(game: GameState) -> void:
	state = game
	for rect in BLOCKERS:
		var r: Rect2 = rect.grow(RADIUS+3)
		for p in [r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]:
			if can_stand(p): nodes.append(p)
	for i in range(nodes.size()):
		links[i] = {}
		for j in range(i):
			if clear_line(nodes[i],nodes[j]):
				links[i][j] = nodes[i].distance_to(nodes[j])
				links[j][i] = links[i][j]
	ensure_positions()

static func can_stand(p: Vector2) -> bool:
	if not BOUNDS.grow(-RADIUS).has_point(p): return false
	for r in BLOCKERS:
		var closest = Vector2(clampf(p.x,r.position.x,r.end.x),clampf(p.y,r.position.y,r.end.y))
		if closest.distance_squared_to(p)<RADIUS*RADIUS: return false
	return true

static func clear_line(a: Vector2, b: Vector2) -> bool:
	var steps = maxi(1,ceili(a.distance_to(b)/5.0))
	for i in range(steps+1):
		if not can_stand(a.lerp(b,float(i)/steps)): return false
	return true

func ensure_positions() -> void:
	if state.mode != "town": return
	for u in state.party:
		if not can_stand(u.town_position):
			var candidate = Vector2(u.cell)*40+Vector2(20,20)
			u.town_position = candidate if can_stand(candidate) else Vector2(460+state.party.find(u)*40,340)

func cancel() -> void:
	route.clear()
	destination = Vector2(-1,-1)

func find_route(a: Vector2, b: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if not can_stand(a) or not can_stand(b): return result
	if clear_line(a,b): result.append(b); return result
	var points = nodes.duplicate()
	var edges = links.duplicate(true)
	var start = points.size()
	points.append(a)
	var finish = points.size()
	points.append(b)
	edges[start] = {}; edges[finish] = {}
	for i in range(nodes.size()):
		for end in [start,finish]:
			if clear_line(points[i],points[end]):
				edges[i][end] = points[i].distance_to(points[end])
				edges[end][i] = edges[i][end]
	var costs = {start:0.0}
	var previous = {}
	var visited = {}
	while true:
		var nearest = -1
		var best = INF
		for i in costs:
			if not visited.has(i) and costs[i]<best: nearest=i; best=costs[i]
		if nearest==-1: return result
		if nearest==finish: break
		visited[nearest]=true
		for next in edges[nearest]:
			var cost = best+edges[nearest][next]
			if cost<costs.get(next,INF): costs[next]=cost; previous[next]=nearest
	var cursor = finish
	while cursor!=start:
		result.push_front(points[cursor])
		cursor=previous[cursor]
	return result

func go_to(p: Vector2) -> bool:
	if state.mode!="town": return false
	ensure_positions()
	leader_id=state.current().uid
	route=find_route(state.current().town_position,p)
	destination=p if not route.is_empty() else Vector2(-1,-1)
	return not route.is_empty()

static func slide(p: Vector2, motion: Vector2) -> Vector2:
	# Substeps prevent crossing thin colliders during a slow frame.
	var count = maxi(1,ceili(motion.length()/4.0))
	var step = motion/count
	for i in range(count):
		if can_stand(p+step): p+=step
		else:
			if can_stand(p+Vector2(step.x,0)): p.x+=step.x
			if can_stand(p+Vector2(0,step.y)): p.y+=step.y
	return p

func follow_path(p: Vector2, path: Array, distance: float) -> Vector2:
	while not path.is_empty() and distance>0.001:
		var offset: Vector2 = path[0]-p
		if offset.length()<0.8: path.pop_front(); continue
		var move = minf(distance,offset.length())
		var next = slide(p,offset.normalized()*move)
		if next.distance_to(p)<0.001: break
		p=next
		distance-=move
	return p

func update(delta: float, direction: Vector2) -> bool:
	if state.mode!="town": cancel(); return false
	ensure_positions()
	var leader = state.current()
	if leader.uid!=leader_id:
		cancel(); follower_routes.clear(); leader_id=leader.uid
	var before = leader.town_position
	if direction.length_squared()>0.01:
		cancel()
		leader.town_position=slide(before,direction.normalized()*SPEED*delta)
	elif not route.is_empty():
		leader.town_position=follow_path(before,route,SPEED*delta)
		if route.is_empty(): destination=Vector2(-1,-1)
	var moved = before.distance_to(leader.town_position)>0.001
	var previous = leader
	for ally in state.party:
		if ally==leader: continue
		var pos = ally.town_position
		var distance = pos.distance_to(previous.town_position)
		if distance>43:
			var timer = follower_timers.get(ally.uid,0.0)-delta
			var path = follower_routes.get(ally.uid,[])
			if clear_line(pos,previous.town_position):
				ally.town_position=slide(pos,pos.direction_to(previous.town_position)*minf(SPEED*1.15*delta,distance-40))
			elif timer<=0:
				path=find_route(pos,previous.town_position)
				timer=0.4
			if not path.is_empty() and not clear_line(ally.town_position,previous.town_position):
				ally.town_position=follow_path(pos,path,SPEED*1.15*delta)
			follower_routes[ally.uid]=path
			follower_timers[ally.uid]=timer
		moved=moved or pos.distance_to(ally.town_position)>0.001
		previous=ally
	for u in state.party: u.cell=Vector2i(floori(u.town_position.x/40),floori(u.town_position.y/40))
	return moved

func nearby_door() -> String:
	if state.mode!="town": return ""
	var nearest = ""
	var distance = 100.0
	for key in DOORS:
		var d = state.current().town_position.distance_to(DOORS[key])
		if d<distance: distance=d; nearest=key
	return nearest
