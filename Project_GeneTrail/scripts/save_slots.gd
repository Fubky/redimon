class_name SaveSlots
extends RefCounted
const COUNT=3

static func path(slot: int) -> String:
	return "user://slots/slot_%02d.json" % clampi(slot,1,COUNT)

static func info(slot: int) -> Dictionary:
	var file=path(slot)
	if not FileAccess.file_exists(file): return {"exists":false,"valid":false}
	var data=JSON.parse_string(FileAccess.get_file_as_string(file))
	var state=GameState.new()
	if not state.valid_save(data): return {"exists":true,"valid":false}
	return {"exists":true,"valid":true,"name":data.party[0].name,"level":int(data.party[0].level),"party":data.party.size(),"place":"阿德勒自由市" if data.mode=="town" else Dungeon.BIOMES[int(data.world.biome)].name,"profile":data.get("origin_profile","负债继承人"),"saved_at":data.get("saved_at",""),"data":data}

static func write(state: GameState, slot: int) -> bool:
	if slot<1 or slot>COUNT or state.save_blocked: return false
	DirAccess.make_dir_recursive_absolute("user://slots")
	return state.save_game(path(slot))

static func erase(slot: int) -> bool:
	if slot<1 or slot>COUNT: return false
	for suffix in ["",".bak",".tmp"]:
		var file=path(slot)+suffix
		if FileAccess.file_exists(file) and DirAccess.remove_absolute(file)!=OK: return false
	return true
