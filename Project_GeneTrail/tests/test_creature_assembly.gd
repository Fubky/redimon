extends SceneTree
var passed=0
var failed=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: passed+=1
	else: failed+=1; push_error("ASSEMBLY FAIL: "+label)
func run() -> void:
	var u=MercenaryRules.sample(0)
	check(HumanPartLibrary.SVG.size()>=49,"independent human parts available")
	for id in HumanPartLibrary.SVG:
		var image=HumanAssembly.part_texture(id,u.genes).get_image()
		check(image.detect_alpha()!=Image.ALPHA_NONE and image.get_pixel(0,0).a==0,"transparent native part: "+id)
		check(image.get_used_rect().get_area()>12,"non-empty part: "+id)
	for race in range(7):
		for job in range(3):
			for variant in range(4):
				u=MercenaryRules.sample(race,job,variant)
				var rig=HumanAssembly.build(u); var ids=rig.parts.map(func(p): return p.id)
				check(rig.parts.size()>=12,"human assembled from separate pieces")
				check(HumanAssembly.build(u)==rig,"unchanged appearance reuses rig")
				check(ids.has(["knight","mage","ranger"][job]+"_torso"),"profession controls outfit")
				check(ids.has(["sword","staff","bow"][job]),"profession controls animated weapon")
				if race in [4,5]:
					check(ids.has("fish_tail" if race==4 else "snake_tail") and not ids.has(["knight","mage","ranger"][job]+"_leg"),"aquatic and serpent lower bodies replace legs")
				if race==2: check(ids.has("lizard_tail") and ids.has("scales_face"),"dragon has tail and skin texture")
				if race==3: check(ids.has("claw_hand") and (ids.has("cat_ears") or ids.has("dog_ears")),"beast retains human face with ears and claws")
				if race==6: check(ids.any(func(id): return id.begins_with("horns_")),"horn phenotype is attached")
				for state in ["idle","walk","attack","cast","hurt","heal","faint"]:
					var joints=HumanAssembly.pose(rig,0.8,{"state":state,"amount":0.8})
					check(rig.parts.all(func(p): return joints.has(p.joint)),"every part has an animation joint")
				var idle=HumanAssembly.pose(rig,0.8,{"state":"idle"})
				var walk=HumanAssembly.pose(rig,0.8,{"state":"walk"})
				var cast=HumanAssembly.pose(rig,0.8,{"state":"cast","amount":1.0})
				check(walk.arm_r!=idle.arm_r and cast.weapon!=idle.weapon,"walk and skill visibly animate independent limbs")
				var builds=HumanAssembly.texture_builds
				for phase in range(30): HumanAssembly.pose(rig,phase*0.12,{"state":"walk"})
				check(builds==HumanAssembly.texture_builds,"animation does not rasterize SVG")
				check(rig.faces.size()==6,"six cached human expressions")
	u=MercenaryRules.sample(2)
	u.genes.white=[0,0]; var low=HumanAssembly.build(u).parts.map(func(p): return p.id)
	u.genes.white=[100,100]; var high=HumanAssembly.build(u).parts.map(func(p): return p.id)
	check(not "dragon_wing" in low and "dragon_wing" in high,"only high inherited expression produces dragon wings")
	for id in ["head_0","face_calm","dragon_wing","bird_wing_0","bird_wing_1","bird_wing_2"]:
		check(HumanAssembly.part_texture(id,u.genes,0)==HumanAssembly.part_texture(id,u.genes,1),"changing career does not change inherited face or wings: "+id)
	check(HumanAssembly.rigs.size()<=HumanAssembly.CACHE_LIMIT and HumanAssembly.textures.size()<=HumanAssembly.PART_CACHE_LIMIT,"art caches remain bounded")
	var app=load("res://scenes/main.tscn").instantiate(); root.add_child(app); await process_frame
	app.set_process(false)
	var view=HumanGallery.open_preview(app); await process_frame
	check(view.samples.size()==6,"visible gallery covers six hybrids and all professions")
	view.variant=1; view.populate(); view.action="walk"; await process_frame
	check(view.samples.size()==6,"gallery recombines alternate parts")
	app.close_modal(); app.show_title(); app.frontend.show_creator(); await process_frame
	check(app.frontend.page=="creator" and app.frontend.result_unit!=null,"human creator replaces quiz")
	app.audio.shutdown(); await create_timer(0.12).timeout
	print("ASSEMBLY_TESTS: ",passed," passed; ",failed," failed.")
	quit(1 if failed else 0)
