extends SceneTree

func _initialize() -> void:
	var f = FileAccess.open("res://build/windows/THIRD_PARTY_NOTICES.txt",FileAccess.WRITE)
	if f == null:
		quit(1)
		return
	f.store_string("Gene Trail uses Godot Engine. Original project code and vector art are separate from the engine.\n\n")
	f.store_string(Engine.get_license_text()+"\n\n")
	f.store_string("Third-party components compiled into this Godot build:\n\n")
	for item in Engine.get_copyright_info():
		f.store_string(str(item)+"\n\n")
	f.store_string("Full third-party license texts:\n\n")
	var licenses = Engine.get_license_info()
	for name in licenses:
		f.store_string(str(name)+"\n"+str(licenses[name])+"\n\n")
	f.close()
	print("THIRD_PARTY_NOTICES written from engine metadata.")
	quit()
