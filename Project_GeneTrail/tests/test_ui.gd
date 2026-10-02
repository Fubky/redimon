extends SceneTree
var app
var passed=0
var failed=0
func _initialize() -> void: call_deferred("run")
func check(value: bool, description: String) -> void:
	if value: passed+=1
	else: failed+=1; push_error("UI FAIL: "+description)
func find_button(node: Node, caption: String) -> Button:
	if node is Button and node.text==caption: return node
	for child in node.get_children():
		var found=find_button(child,caption)
		if found!=null: return found
	return null
func find_choice(node: Node, first: String) -> OptionButton:
	if node is OptionButton and node.item_count>0 and node.get_item_text(0)==first: return node
	for child in node.get_children():
		var found=find_choice(child,first)
		if found!=null: return found
	return null
func click(caption: String) -> void:
	var b=find_button(app,caption)
	check(b!=null,"button exists: "+caption)
	if b!=null:
		check(not b.disabled,"button enabled: "+caption)
		if not b.disabled: b.pressed.emit()
	await process_frame
	await process_frame
func key(code: int) -> void:
	var event=InputEventKey.new(); event.keycode=code; event.pressed=true
	app._unhandled_input(event)
	await process_frame

func run() -> void:
	for slot in range(1,4): SaveSlots.erase(slot)
	app=load("res://scenes/main.tscn").instantiate(); root.add_child(app)
	await process_frame
	app.set_process(false)
	check(app.game.party.size()==2 and app.game.home.is_empty(),"two-unit new game with empty home")
	check(app.map_frame.position==Vector2.ZERO and app.map_frame.size==app.get_viewport_rect().size,"scene occupies entire viewport")
	app.show_title()
	await click("基因图鉴")
	check(app.modal!=null,"title codex opens")
	await click("返回  Esc")
	await click("进入游戏   →")
	check(app.frontend.page=="slots","enter game opens save/load slots")
	await click("新建旅程")
	check(app.frontend.page=="creator","empty slot starts custom character creator")
	await click("编辑七项血统比例与表达 →")
	var editor: BloodlineUI=app.modal_body.get_children().filter(func(n): return n is BloodlineUI)[0]
	editor.sliders[1].value=50
	check(editor.draft.genes.plumage==[70,70] and editor.phenotype.text.contains("羽翼"),"bloodline slider automatically generates and previews wings")
	editor.expressions[6].value=100 # Horn expression is allowed without horn ancestry.
	check(app.frontend.result_unit.bloodline==Bloodline.pure(0) and app.frontend.result_unit.genes.horns==[0,0],"editor changes remain a draft until applied")
	await click("返回  Esc")
	check(app.frontend.result_unit.bloodline==Bloodline.pure(0),"cancel discards draft ancestry")
	await click("编辑七项血统比例与表达 →")
	editor=app.modal_body.get_children().filter(func(n): return n is BloodlineUI)[0]
	editor.sliders[1].value=50
	check(editor.expressions[0].value==70 and editor.expressions[1].value==70 and editor.expressions[6].value==0,"sliders synchronize trait fields without an extra generate action")
	editor.expressions[6].value=100
	await click("应用血统与基因")
	find_choice(app.frontend,"骑士").item_selected.emit(2)
	find_choice(app.frontend,"均衡体质").item_selected.emit(2)
	check(app.frontend.result_unit.genes.affinity==[90,90] and app.frontend.result_unit.genes.gloss==[90,90],"talent control writes inheritable genes")
	check(MercenaryRules.aptitude(app.frontend.result_unit.genes,1)<MercenaryRules.aptitude(app.frontend.result_unit.genes,2),"talent control changes actual career difficulty")
	var expected=app.frontend.result_unit.genes.duplicate(true)
	app.frontend.name_field.text="测试佣兵"
	await click("以此身份进入自由市  →")
	check(app.frontend==null and app.active_slot==1 and app.game.party[0].genes==expected,"creation applies exact custom genes")
	check(app.game.party[0].bloodline==[5000,5000,0,0,0,0,0] and app.game.party[0].profession==2 and app.game.party[0].genes.horns==[100,100],"creation persists mixed ancestry, independent trait genes and career")
	check(SaveSlots.info(1).valid and not SaveSlots.info(2).exists,"new game persists only its selected slot")
	await click("任务栏 / 贷款")
	await click("接受委托")
	check(app.game.contracts.has("kill_0"),"board accepts actual kill contract")
	await click("接受委托")
	check(app.game.contracts.has("escort_0"),"board accepts actual escort contract")
	await click("返回  Esc")
	MercenaryUI.professions(app,app.game.party[0])
	await click("转为此职业")
	check(app.game.party[0].profession==0 and "knight_cut" in app.game.party[0].carried_skills(),"profession button changes job and loadout")
	await click("返回  Esc")
	await click("技能 / 配招")
	var u=app.game.party[0]
	var count=u.carried_skills().size()
	await click("卸下")
	check(u.carried_skills().size()==count-1,"loadout button unequips")
	await click("携带")
	check(u.carried_skills().size()==4,"loadout button equips without exceeding four")
	await click("返回  Esc")
	await click("成长 / 培养")
	await click("训练 +4 / 20 金币")
	check(u.effort.hp==4 and app.game.gold==160,"training UI consumes gold and changes EVs")
	await click("返回  Esc")
	await click("家系 / 遗传")
	await click("推演成年后裔  /  60 金币")
	check(app.game.home.size()==1 and app.preview_unit.parents.size()==2,"breeding still creates inherited newborn")
	await click("返回  Esc")
	app.show_shop()
	await click("购买  /  20 金币")
	check(app.game.potions==6 and app.game.gold==80,"shop UI")
	app.show_storage()
	await click("存入")
	check(app.game.gold==30 and app.game.stored_gold==50,"storage UI")
	await click("返回  Esc")
	app.manual_save()
	app.game.gold=999
	app.show_slots()
	await click("继续旅程")
	check(app.game.gold==30 and app.game.party[0].effort.hp==4,"slot load restores resources and effort")
	await click("出征")
	await click("进入  →")
	var risk=app.modal_body.get_children().filter(func(n): return n is CheckButton)[0]
	risk.button_pressed=true
	await click("选择轻装轮替")
	check(app.modal_body.get_children().filter(func(n): return n is CheckButton)[0].button_pressed,"changing tactics preserves risk toggle")
	await click("选择破阵强攻")
	await click("选择协同追击")
	app.modal_body.get_children().filter(func(n): return n is CheckButton)[0].button_pressed=false
	await click("按此战术出征  →")
	check(app.game.mode=="explore" and app.game.expedition_plan=="relay" and not app.game.expedition_risk,"expedition selector applies chosen tactics and risk")
	await click("战术：协同追击")
	check(app.modal!=null,"current expedition doctrine can be inspected without changing it")
	await click("返回  Esc")
	var foe=app.game.enemies[0]
	var room=app.game.world.room_at(foe.cell)
	var spots=app.game.world.reachable(foe.cell,3).keys().filter(func(p): return app.game.world.room_at(p)==room and app.game.unit_at(p)==null)
	for i in range(app.game.party.size()): app.game.party[i].cell=spots[i]
	app.game.start_battle(room); app.game.active_id=app.game.party[0].uid
	for i in range(600):
		app.board._process(1.0/60)
		if not app.board.is_animating(): break
	app.refresh(); app.board._process(0.1)
	u=app.game.current()
	check(not app.board.reachable.is_empty() and app.battle_selection==u.uid,"entering player turn automatically selects actor and movement")
	app.battle_click(u.cell)
	check(not app.board.reachable.is_empty() and app.battle_selection==u.uid,"click unit exposes movement range and action UI")
	var origin=u.cell
	await key(KEY_D)
	check(u.cell==origin,"battle direction key does not move unit")
	var old_camera=app.board.camera_center
	Input.action_press("town_right"); app._process(0.2); Input.action_release("town_right")
	app.board.update_camera(0)
	check(app.board.camera_center.x>old_camera.x and u.cell==origin,"held battle direction pans camera only")
	var targets=app.game.move_range(u).keys(); targets.erase(u.cell)
	app.battle_click(targets[0])
	check(u.cell==targets[0] and u.moved and app.board.is_animating(),"click destination commits movement and queues animation")
	for i in range(180): app.board._process(1.0/60)
	check(not app.board.is_animating(),"movement animation finishes")
	app.refresh()
	check(app.board.reachable.is_empty(),"used movement no longer exposes blue cells")
	var old_id=app.game.active_id
	await click("结束行动\n[空格]")
	check(app.game.active_id!=old_id and app.battle_selection==(app.game.active_id if app.game.current().faction=="party" else ""),"next player actor auto-selects; enemy does not")
	while app.game.current().faction=="enemy":
		app.game.enemy_turn()
		for i in range(200): app.board._process(1.0/60)
	app.game.current().genes.body_a=[1,1]; app.game.current().genes.body_b=[1,1]
	app.game.current().equipped_skills.assign(["delay"])
	app.refresh(); app.set_skill("delay")
	u=app.game.current(); u.ap=60; u.spent=40
	app.refresh()
	check(app.combat_ui.preview_at(foe.cell,true).cost==35,"AP HUD previews carried skill cost")
	check(app.game.return_delay(u,35)-app.game.return_delay(u,0)==70,"AP preview crosses burst boundary")
	app.game.return_town(); app.refresh()
	app.show_audio_settings()
	await click("全部静音")
	check(app.audio.muted,"audio settings can mute")
	await click("取消静音")
	check(not app.audio.muted,"audio settings can unmute")
	await click("返回  Esc")
	app.show_slots()
	await click("删除存档")
	await click("确认删除")
	check(not SaveSlots.info(1).exists and app.active_slot==0,"slot deletion removes its data and prevents recreation by autosave")
	print("UI_TESTS: ",passed," passed; ",failed," failed.")
	app.audio.shutdown()
	await create_timer(0.12).timeout
	quit(1 if failed>0 else 0)
