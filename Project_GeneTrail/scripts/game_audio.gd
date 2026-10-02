class_name GameAudio
extends Node

var music: Array[AudioStreamPlayer]=[]
var effects: Array[AudioStreamPlayer]=[]
var context=""
var active=0
var music_volume=0.65
var effects_volume=0.75
var muted=false
var step_clock=0.0
var streams: Dictionary={}

func _ready() -> void:
	for bus_name in ["Music","Effects"]:
		if AudioServer.get_bus_index(bus_name)<0:
			AudioServer.add_bus(); AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
	for i in range(2):
		var player=AudioStreamPlayer.new(); player.bus="Music"; player.volume_db=-60; add_child(player); music.append(player)
	for i in range(8):
		var player=AudioStreamPlayer.new(); player.bus="Effects"; add_child(player); effects.append(player)
	var config=ConfigFile.new()
	if config.load("user://audio.cfg")==OK:
		music_volume=clampf(float(config.get_value("audio","music",0.65)),0,1)
		effects_volume=clampf(float(config.get_value("audio","effects",0.75)),0,1)
		muted=bool(config.get_value("audio","muted",false))
	apply_volume()

func apply_volume() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),linear_to_db(maxf(0.0001,music_volume)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"),linear_to_db(maxf(0.0001,effects_volume)))
	for bus in ["Music","Effects"]: AudioServer.set_bus_mute(AudioServer.get_bus_index(bus),muted)

func save_settings() -> void:
	apply_volume()
	var config=ConfigFile.new()
	config.set_value("audio","music",music_volume); config.set_value("audio","effects",effects_volume); config.set_value("audio","muted",muted)
	config.save("user://audio.cfg")

func stream(name: String) -> AudioStreamWAV:
	if not streams.has(name): streams[name]=load("res://assets/audio/"+name+".wav")
	return streams[name]

func play_context(next: String) -> void:
	if next==context or music.is_empty(): return
	context=next
	active=1-active
	var song=stream(next)
	if song==null: return
	song.loop_mode=AudioStreamWAV.LOOP_FORWARD
	song.loop_begin=0
	song.loop_end=roundi(song.get_length()*song.mix_rate)
	music[active].stop()
	music[active].stream=song
	music[active].volume_db=-45
	music[active].play()

func sync_state(state: GameState) -> void:
	play_context("town" if state.mode=="town" else ("battle" if state.mode=="battle" else Dungeon.BIOMES[state.world.biome].kind))

func sfx(name: String, quiet: bool=false) -> void:
	if effects.is_empty(): return
	var player=effects[0]
	for candidate in effects:
		if not candidate.playing: player=candidate; break
	player.stop()
	player.stream=stream("sfx_"+name)
	player.volume_db=-13 if quiet else -4
	player.play()

func footstep(moving: bool, delta: float) -> void:
	step_clock+=delta
	if moving and step_clock>0.26: step_clock=0; sfx("step",true)

func _process(delta: float) -> void:
	for i in range(music.size()):
		music[i].volume_db=move_toward(music[i].volume_db,-5 if i==active else -60,delta*48)
		if i!=active and music[i].volume_db<=-59 and music[i].playing: music[i].stop()

func shutdown() -> void:
	for player in music+effects:
		if is_instance_valid(player): player.stop(); player.stream=null
	streams.clear()

func _exit_tree() -> void:
	shutdown()
