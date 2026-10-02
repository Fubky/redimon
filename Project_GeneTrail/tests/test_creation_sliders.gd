extends SceneTree
var passed=0
var failed=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, what: String) -> void:
	if ok: passed+=1
	else: failed+=1; push_error("SLIDER FAIL: "+what)
func part_ids(u: UnitData) -> Array: return HumanAssembly.build(u).parts.map(func(p): return p.id)
func run() -> void:
	var equal=Bloodline.normalize([1,1,1,1,1,1,1])
	for basis in [Bloodline.pure(0),equal,[2000,3000,0,5000,0,0,0]]:
		var original=basis.duplicate()
		for origin in range(7):
			for target in [0,1,3333,5000,9999,10000]:
				var parts=Bloodline.with_share(basis,origin,target)
				check(Bloodline.valid(parts) and parts[origin]==target,"editing a share retains exact 100% total and target")
		check(basis==original,"redistribution never mutates the drag anchor")
	check(Bloodline.with_share([2000,3000,0,5000,0,0,0],3,2000)==[3200,4800,0,2000,0,0,0],"other bloodlines retain their relative proportions")
	var app=load("res://scenes/main.tscn").instantiate(); root.add_child(app); await process_frame
	app.set_process(false); app.show_title(); app.frontend.show_creator()
	var unit: UnitData=app.frontend.result_unit; var genes=unit.genes.duplicate(true)
	var editor=BloodlineUI.open(app,unit,true,app.frontend.update_creator); await process_frame
	check(editor.sliders.size()==7 and editor.auto_traits.button_pressed,"seven actual sliders and automatic traits by default")
	for i in range(1,7):
		editor.sliders[i].value=100
		var ids=part_ids(editor.draft)
		var trait_present=[ids.any(func(id): return id.begins_with("bird_wing")),"scales_face" in ids,"claw_hand" in ids,"fish_tail" in ids,"snake_tail" in ids,ids.any(func(id): return id.begins_with("horns_"))][i-1]
		check(editor.draft.bloodline==Bloodline.pure(i) and trait_present,"each origin expresses its real assembled parts immediately")
		check(GeneSkills.expression_skill(editor.draft.genes,Genome.TRAITS[i]) in editor.draft.skill_pool(),"slider synchronizes unlocked skills")
	check(unit.genes==genes and unit.bloodline==Bloodline.pure(0),"preview leaves source untouched until applying")
	app.close_modal(); await process_frame
	editor=BloodlineUI.open(app,unit,true,app.frontend.update_creator); await process_frame
	editor.sliders[1].value=50; editor.start_drag(6)
	editor.sliders[6].value=100; editor.sliders[6].value=50
	check(editor.draft.bloodline==[2500,2500,0,0,0,0,5000],"drag back from 100% restores other origins instead of losing their ratio")
	editor.drag_basis.clear()
	check("horns_0" in part_ids(editor.draft) and "bird_wing_0" in part_ids(editor.draft),"minority mixed lineage still has visible founder traits")
	for locus in genes:
		if not locus in Genome.TRAITS: check(editor.draft.genes[locus]==genes[locus],"bloodline drag preserves body and appearance gene: "+locus)
	editor.expressions[2].value=100
	check(not editor.auto_traits.button_pressed,"manual trait edit clearly changes to free gene mode")
	editor.sliders[1].value=0
	check(editor.draft.genes.scales==[100,100] and editor.draft.genes.plumage[0]>=40,"free gene mode does not overwrite customized genes")
	editor.auto_traits.button_pressed=true
	check(editor.draft.genes.scales==[0,0] and editor.draft.genes.plumage==[0,0],"turning automatic mode back on resynchronizes and removes zero-origin traits")
	# Exercise a real native slider press, drag and release, not only its value signal.
	var slider=editor.sliders[3]; var rect=slider.get_global_rect()
	var start=rect.position+Vector2(8,rect.size.y/2); var finish=rect.position+Vector2(rect.size.x*0.75,rect.size.y/2)
	var press=InputEventMouseButton.new(); press.button_index=MOUSE_BUTTON_LEFT; press.pressed=true; press.position=start
	root.push_input(press,true); await process_frame
	var move=InputEventMouseMotion.new(); move.position=finish; move.relative=finish-start; move.button_mask=MOUSE_BUTTON_MASK_LEFT
	root.push_input(move,true); await process_frame
	var release=InputEventMouseButton.new(); release.button_index=MOUSE_BUTTON_LEFT; release.position=finish; release.pressed=false
	root.push_input(release,true); await process_frame
	check(editor.draft.bloodline[3]>6000 and editor.draft.bloodline[3]<9000 and Bloodline.valid(editor.draft.bloodline),"native pointer drag updates bloodline and all other slider values")
	check("claw_hand" in part_ids(editor.draft),"real pointer drag updates preview anatomy")
	var expected=editor.draft.genes.duplicate(true); var ancestry=editor.draft.bloodline.duplicate()
	editor.apply_changes(); await process_frame
	check(unit.genes==expected and unit.bloodline==ancestry and unit.hp==unit.max_hp(),"apply updates creator, stats and genome together")
	check(app.frontend.creator_details.text.contains("表达天赋"),"creator detail refreshes after applying")
	editor=BloodlineUI.open(app,unit); await process_frame
	check(editor.sliders.all(func(s): return not s.editable) and editor.auto_traits==null,"owned character ancestry remains read only")
	editor.adjust_origin(0,100); editor.apply_changes()
	check(unit.genes==expected and unit.bloodline==ancestry,"read-only inspection cannot modify saved character")
	app.close_modal(); app.audio.shutdown(); await create_timer(0.12).timeout
	print("SLIDER_TESTS: ",passed," passed; ",failed," failed.")
	quit(1 if failed else 0)
