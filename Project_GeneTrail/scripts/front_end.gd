class_name FrontEnd
extends Control

var app
var keyart=preload("res://assets/art_v7/title.png")
var page="title"
var content: Control
var elapsed=0.0
var answers: Array=[]
var target_slot=1
var save_mode=false
var name_field: LineEdit
var result_unit: UnitData
var title_units: Array=[]
var creator_preview: Control
var creator_details: Label
var creator_talent=0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	z_index=50
	title_units=[MercenaryRules.sample(0,0,0),MercenaryRules.sample(1,1,2),MercenaryRules.sample(6,2,1)]
	show_title()

func _process(delta: float) -> void:
	elapsed+=delta
	if is_instance_valid(creator_preview): creator_preview.queue_redraw()
	if content!=null: content.position=(get_viewport_rect().size-Vector2(1440,960))*0.5
	queue_redraw()

func clear_page(next: String) -> void:
	page=next
	if content!=null: remove_child(content); content.queue_free()
	content=Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)

func _draw() -> void:
	var view=get_viewport_rect().size
	var offset=(view-Vector2(1440,960))*0.5
	var art=keyart
	# Only the unoccupied landscape is used; title creatures use the gameplay rig.
	var landscape=Rect2(0,0,art.get_width()*0.57,art.get_height())
	var factor=maxf(view.x/landscape.size.x,view.y/landscape.size.y)
	var size=landscape.size*factor
	draw_texture_rect_region(art,Rect2(Vector2(0,(view.y-size.y)*0.5),size),landscape)
	if page=="title":
		draw_texture_rect(preload("res://assets/imperial_crest.svg"),Rect2(Vector2(635,237)+offset,Vector2(96,108)),false)
		for i in range(title_units.size()):
			var point=[Vector2(805,658),Vector2(1040,710),Vector2(1287,674)][i]+offset
			CreatureArt.oval(self,point+Vector2(12,51),Vector2(92,19),Color(0.05,0.09,0.16,0.46),Color.TRANSPARENT,0)
			CreatureArt.draw(self,title_units[i],point,[3.0,2.5,2.8][i],elapsed*2,{"state":"idle","phase":elapsed*2+i})
		draw_style_box(app.box(Color(0.04,0.10,0.18,0.52),Color(0.80,0.72,0.50,0.28),1,8),Rect2(Vector2(78,118)+offset,Vector2(500,623)))
		draw_line(Vector2(116,189)+offset,Vector2(174,189)+offset,Color("efbf79"),3)
	else: draw_rect(Rect2(Vector2.ZERO,view),Color(0.94,0.95,0.86,0.92))
	for i in range(28):
		var p=Vector2(fmod(i*179.0+elapsed*(5+i%4),view.x),100+fmod(i*77.0,view.y-170)+sin(elapsed+i)*12)
		draw_circle(p,1+i%3,Color(1,0.94,0.65,0.6))
	if page=="result" and result_unit!=null: CreatureArt.draw(self,result_unit,Vector2(1062,427)+offset,3.8,elapsed*2)

func heading(title: String, subtitle: String) -> void:
	app.label(content,title,Vector2(110,88),40)
	app.label(content,subtitle,Vector2(114,151),18,app.MUTED)

func show_title() -> void:
	clear_page("title")
	app.audio.play_context("title")
	app.label(content,"FREE COMPANY  /  IMPERIAL FRONTIER",Vector2(115,160),16,Color("d6c294"))
	app.label(content,"帝国佣兵",Vector2(109,222),79,Color("0d1b30"))
	app.label(content,"帝国佣兵",Vector2(106,218),79,Color("fff2d4"))
	app.label(content,"从一张借据，写起家族的命运。",Vector2(117,330),23,Color("f6dfb5"))
	app.label(content,"神圣罗马帝国 · 自由市 · 血脉与契约",Vector2(118,382),16,Color("b4ced2"))
	title_button("进入游戏   →",Rect2(118,482,375,70),func(): show_slots(),true)
	title_button("基因图鉴",Rect2(118,568,375,62),func(): ProgressionUI.codex(app))
	title_button("声音设置",Rect2(118,646,178,50),app.show_audio_settings)
	title_button("退出游戏",Rect2(312,646,181,50),app.quit_game)
	app.label(content,"可遗传的天赋 · 可改变的职业 · 可偿还的命运",Vector2(118,852),16,Color("e8ead2"))
	app.label(content,"v0.15  /  Godot 4.7    ·    F11 全屏 / 窗口",Vector2(118,885),13,Color("d0dcc7"))

func title_button(text: String, rect: Rect2, action: Callable, primary: bool=false) -> void:
	var button=app.button(content,text,rect,action)
	button.add_theme_stylebox_override("normal",app.box(Color("e9b97b") if primary else Color("20374a"),Color("d9b27a") if primary else Color("577681"),1,6))
	button.add_theme_stylebox_override("hover",app.box(Color("ffda9c") if primary else Color("32616d"),Color("edc681"),2,6))
	button.add_theme_color_override("font_color",Color("25384b") if primary else Color("f7ecd5"))
	button.add_theme_color_override("font_hover_color",Color("25384b") if primary else Color("fff2da"))
	button.add_theme_font_size_override("font_size",23 if primary else 19)

func show_slots(for_save: bool=false) -> void:
	save_mode=for_save
	clear_page("slots")
	heading("旅途存档","选择佣兵团档案，或自定义一位负债继承人，签订新的契约。")
	for slot in range(1,SaveSlots.COUNT+1):
		var data=SaveSlots.info(slot)
		var y=211+(slot-1)*195
		app.panel(content,Rect2(112,y,1216,174),Color("f7f1df"),Color("a6b797"))
		app.label(content,"0%d" % slot,Vector2(142,y+28),39,app.GREEN)
		var title="尚未签署的佣兵契约" if not data.exists else (data.name+"  ·  Lv.%d" % data.level if data.valid else "存档无法读取")
		app.label(content,title,Vector2(237,y+22),26)
		app.label(content,"自定义血统、职业与共用基因 · 两名初始佣兵" if not data.exists else ("%s · %s · %d 位出征伙伴\n保存于 %s" % [data.profile,data.place,data.party,data.saved_at.replace("T"," ")] if data.valid else "该槽文件损坏，删除后可建立新旅途。"),Vector2(239,y+73),16,app.MUTED,710)
		if for_save:
			app.button(content,"保存到此槽",Rect2(1041,y+35,249,55),func():
				if data.exists: confirm_overwrite(slot)
				else: save_into(slot),true,true)
		else:
			app.button(content,"继续旅程" if data.exists else "新建旅程",Rect2(1041,y+35,249,55),func():
				if data.exists: app.load_slot(slot)
				else: target_slot=slot; answers.clear(); show_quiz(),not data.exists or data.valid,true)
		if data.exists: app.button(content,"删除存档",Rect2(1120,y+107,170,38),func(): confirm_delete(slot))
	app.button(content,"返回标题",Rect2(112,830,220,52),show_title)
	if app.active_slot>0:
		app.button(content,"切换到读取 / 新建" if for_save else "切换到保存 / 另存",Rect2(491,830,384,52),func(): show_slots(not for_save))
		app.button(content,"返回当前游戏",Rect2(1060,830,268,52),app.close_frontend,true,true)

func confirm_delete(slot: int) -> void:
	app.open_modal("删除第 %d 个存档？" % slot,"这会删除此槽的旅途进度及其备份，其他存档不受影响。")
	app.button(app.modal_body,"确认删除",Rect2(34,182,278,56),func():
		if SaveSlots.erase(slot):
			if app.active_slot==slot: app.active_slot=0
			app.close_modal(); show_slots(save_mode)
		else: app.show_toast("删除失败，请检查文件访问权限。"))

func confirm_overwrite(slot: int) -> void:
	app.open_modal("覆盖第 %d 个存档？" % slot,"将当前旅途保存到这个位置。旧内容将保留为该槽的上一份备份。")
	app.button(app.modal_body,"确认保存",Rect2(34,182,278,56),func(): app.close_modal(); save_into(slot),true,true)

func save_into(slot: int) -> void:
	if SaveSlots.write(app.game,slot): app.active_slot=slot; show_slots(true)
	else: app.show_toast("保存失败，当前旅途仍保留在内存中。")

func show_quiz() -> void:
	show_creator()

func show_result() -> void:
	show_creator()

func show_creator(reset: bool=false) -> void:
	clear_page("creator")
	if result_unit==null or reset:
		result_unit=MercenaryRules.sample(0,0,0)
		result_unit.display_name="阿德勒"
		for locus in ["bone","muscle","affinity","gloss","agility","length"]: result_unit.genes[locus]=[50,50]
		creator_talent=0
	heading("签下你的佣兵契约","自定义角色 · 混合血统记录来源，共用基因决定外观与天赋；职业可以后天重新学习。")
	app.panel(content,Rect2(105,201,719,579),Color("f4eddf"),Color("b4b5a4"))
	app.panel(content,Rect2(851,201,484,579),Color("283c4c"),Color("b89965"))
	app.label(content,"姓名",Vector2(128,220),17)
	name_field=LineEdit.new(); name_field.position=Vector2(201,210); name_field.size=Vector2(310,44)
	name_field.max_length=12; name_field.text=result_unit.display_name; content.add_child(name_field)
	name_field.text_changed.connect(func(value): result_unit.display_name=value)
	app.label(content,"天赋",Vector2(532,220),17)
	var talent=OptionButton.new(); talent.position=Vector2(587,211); talent.size=Vector2(210,43)
	for title in ["均衡体质","坚韧体质","以太适性","灵巧体质"]: talent.add_item(title)
	talent.select(creator_talent); content.add_child(talent)
	talent.item_selected.connect(func(index):
		creator_talent=index
		for locus in ["bone","muscle","affinity","gloss","agility","length"]: result_unit.genes[locus]=[50,50] if index==0 else [35,35]
		if index>0:
			for locus in [["bone","muscle"],["affinity","gloss"],["agility","length"]][index-1]: result_unit.genes[locus]=[90,90]
		update_creator())
	app.label(content,"血统与共用基因",Vector2(128,277),16,app.MUTED)
	app.button(content,"编辑七项血统比例与表达 →",Rect2(128,304,322,39),func(): BloodlineUI.open(app,result_unit,true,update_creator))
	creator_choice("职业",MercenaryRules.JOBS,result_unit.profession,Vector2(471,277),func(index): result_unit.profession=index; update_creator())
	var fields=[
		["color","肤色",["象牙","暖杏","麦棕","深褐","玫瑰","灰银"]],
		["contrast","发色",["墨黑","栗棕","铜金","亚麻","灰紫","银白"]],
		["coat","发型",["短碎发","侧分发","卷发","长发"]],
		["face","脸型",["柔和","圆润","棱角"]],
		["ears","耳 / 角型",["猫 / 牛角","犬 / 羊角","猫 / 鹿角"]],
		["tail","尾 / 羽型",["短尾 / 鹰羽","长尾 / 鸦羽","长尾 / 天鹅羽","长尾 / 鹰羽"]],
		["eyes","瞳色",["橄榄","琥珀","湖蓝","赤褐","紫罗兰"]],
		["white","背部表达",["低表达 · 无龙翼","高表达 · 有龙翼"]]]
	for i in range(fields.size()):
		var f=fields[i]; var value=Genome.express(result_unit.genes,f[0])
		if f[0]=="contrast": value=mini(5,value/17)
		if f[0]=="white": value=1 if value>=60 else 0
		creator_choice(f[1],f[2],value,Vector2(128+(i%2)*343,357+(i/2)*81),func(index):
			var allele=index
			if f[0]=="contrast": allele=mini(100,index*17+8)
			if f[0]=="white": allele=index*100
			result_unit.genes[f[0]]=[allele,allele]; update_creator())
	creator_choice("体型",["紧凑型","小型","中型","中大型","大型"],["紧凑型","小型","中型","中大型","大型"].find(Genome.body_name(result_unit.genes)),Vector2(128,681),func(index):
		var values=[[[0,0],[0,0]],[[0,1],[0,1]],[[1,1],[0,0]],[[1,1],[0,1]],[[1,1],[1,1]]][index]
		result_unit.genes.body_a=values[0]; result_unit.genes.body_b=values[1]; update_creator())
	creator_choice("身高",["矮","中等","高"],roundi(Genome.express(result_unit.genes,"height")/50.0),Vector2(471,681),func(index): result_unit.genes.height=[index*50,index*50]; update_creator())
	creator_preview=Control.new(); creator_preview.position=Vector2(870,229); creator_preview.size=Vector2(445,319); creator_preview.mouse_filter=Control.MOUSE_FILTER_IGNORE; content.add_child(creator_preview)
	creator_preview.draw.connect(func():
		CreatureArt.oval(creator_preview,Vector2(215,251),Vector2(104,21),Color(0.02,0.06,0.09,0.4),Color.TRANSPARENT,0)
		HumanAssembly.draw(creator_preview,result_unit,Vector2(206,203),4.2,elapsed*2,{"state":"idle","phase":elapsed*2,"face_time":elapsed}))
	creator_details=app.label(content,"",Vector2(875,551),16,Color("e4ddc8"),436)
	update_creator()
	app.label(content,"你将继承 3000 金币债务，与莉泽组成两人佣兵团。全部角色均以成年形态登场。",Vector2(111,809),17,app.MUTED)
	app.button(content,"返回存档",Rect2(110,858,210,57),show_slots)
	app.button(content,"混合血统名录",Rect2(342,858,256,57),func(): HumanGallery.open_preview(app))
	app.button(content,"以此身份进入自由市  →",Rect2(854,850,479,65),func():
		var result={"seed":Time.get_ticks_usec(),"genes":result_unit.genes.duplicate(true),"bloodline":result_unit.bloodline.duplicate(),"profession":result_unit.profession,"profile":Bloodline.summary(result_unit.bloodline)+" · "+MercenaryRules.JOBS[result_unit.profession],"answers":[]}
		app.create_slot(target_slot,result,name_field.text.strip_edges()),true,true)

func creator_choice(title: String, options: Array, selected: int, pos: Vector2, callback: Callable) -> void:
	app.label(content,title,pos,16,app.MUTED)
	var choice=OptionButton.new(); choice.position=pos+Vector2(0,27); choice.size=Vector2(322,39)
	for option in options: choice.add_item(option)
	choice.select(selected); choice.item_selected.connect(callback); content.add_child(choice)

func update_creator() -> void:
	result_unit.equipped_skills.clear(); result_unit.ensure_loadout(); result_unit.heal()
	if not is_instance_valid(creator_details): return
	var lines=MercenaryRules.JOBS[result_unit.profession]+" · "+Bloodline.compact(result_unit.bloodline)+"\n\n"
	for job in range(3): lines+=MercenaryRules.JOBS[job]+"："+MercenaryRules.aptitude_label(result_unit.genes,job)+"\n"
	var talents: PackedStringArray=[]
	for locus in Genome.expressed_traits(result_unit.genes): talents.append(GeneSkills.RULES[GeneSkills.expression_skill(result_unit.genes,locus)].name)
	lines+="\n表达天赋："+("尚未表达" if talents.is_empty() else " / ".join(talents.slice(0,3)))
	if talents.size()>3: lines+=" 等 %d 项" % talents.size()
	lines+="\n所有血统共用 25 个双等位基因位点。"
	creator_details.text=lines
