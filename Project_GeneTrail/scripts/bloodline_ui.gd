class_name BloodlineUI
extends Control

var app
var source: UnitData
var draft: UnitData
var editable=false
var changed: Callable
var sliders: Array[HSlider]=[]
var percentages: Array[Label]=[]
var expressions: Array[SpinBox]=[]
var auto_traits: CheckButton
var preview: Control
var phenotype: Label
var mode_hint: Label
var elapsed=0.0
var drag_basis: Dictionary={}
var ratio_memory: Dictionary={}

static func open(owner, unit: UnitData, can_edit: bool=false, on_changed: Callable=Callable()) -> BloodlineUI:
	owner.open_modal("血统与共用基因", "拖动血统分配来源；创建时自动同步初始性状。后代依然从双亲各继承一份共用基因。" if can_edit else "七项血统合计 100%。基因独立重组，任何血统都能携带全部共用位点。")
	var view=BloodlineUI.new()
	view.app=owner; view.source=unit; view.draft=UnitData.deserialize(unit.serialize())
	view.editable=can_edit; view.changed=on_changed
	view.size=Vector2(1066,772); view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	owner.modal_body.add_child(view); view.build_ui()
	return view

func build_ui() -> void:
	app.label(self,"家系来源",Vector2(40,130),23)
	app.label(self,"合计 100%",Vector2(410,138),16,app.GREEN)
	app.label(self,"拖动一条，其余按比例联动；可用方向键微调。" if editable else "来源影响基础属性与招募基础率。",Vector2(40,172),14,app.MUTED)
	for i in range(7):
		var y=210+i*54
		app.panel(self,Rect2(39,y,477,47),Color("e7e5d8"))
		app.panel(self,Rect2(39,y,5,47),Bloodline.COLORS[i],Color.TRANSPARENT)
		app.label(self,Genome.SPECIES[i],Vector2(54,y+12),17)
		var slider=HSlider.new(); slider.name="BloodlineSlider%d" % i
		slider.position=Vector2(142,y+5); slider.size=Vector2(273,37)
		slider.min_value=0; slider.max_value=100; slider.step=0.01; slider.scrollable=false; slider.editable=editable
		slider.value=draft.bloodline[i]/100.0
		slider.tooltip_text=Genome.SPECIES[i]+"血统；拖动后其他来源自动分配剩余比例。"
		var track=app.box(Color("b7c1ba"),Color.TRANSPARENT,0,4)
		track.content_margin_top=3; track.content_margin_bottom=3
		var fill=track.duplicate(); fill.bg_color=Bloodline.COLORS[i].darkened(0.18)
		slider.add_theme_stylebox_override("slider",track)
		slider.add_theme_stylebox_override("grabber_area",fill); slider.add_theme_stylebox_override("grabber_area_highlight",fill)
		add_child(slider); sliders.append(slider)
		var percent=app.label(self,"",Vector2(424,y+12),16,app.INK)
		percent.size.x=82; percent.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; percentages.append(percent)
		slider.drag_started.connect(func(): start_drag(i))
		slider.drag_ended.connect(func(_moved): drag_basis.erase(i))
		slider.value_changed.connect(func(amount): adjust_origin(i,amount))
	app.panel(self,Rect2(551,127,476,256),Color("283c4c"),Color("b89965"))
	app.label(self,"实时性状预览",Vector2(570,142),18,Color("f0e5d0"))
	preview=Control.new(); preview.position=Vector2(570,169); preview.size=Vector2(437,183)
	preview.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(preview)
	preview.draw.connect(func():
		CreatureArt.oval(preview,Vector2(218,160),Vector2(66,12),Color(0.02,0.06,0.09,0.4),Color.TRANSPARENT,0)
		HumanAssembly.draw(preview,draft,Vector2(214,138),2.55,elapsed*2,{"state":"idle","phase":elapsed*2,"face_time":elapsed}))
	phenotype=app.label(self,"",Vector2(570,355),14,Color("e4ddc8"))
	app.label(self,"共用性状 · 手动调整可覆盖自动结果" if editable else "共用性状 · 当前表达",Vector2(552,400),17)
	for i in range(7):
		var x=552+(i%2)*244; var y=435+(i/2)*47; var locus=Genome.TRAITS[i]
		app.label(self,GeneTraits.NAMES[locus],Vector2(x,y+7),14,app.MUTED)
		var expression=SpinBox.new(); expression.name="TraitExpression%d" % i
		expression.position=Vector2(x+104,y); expression.size=Vector2(126,36)
		expression.min_value=0; expression.max_value=100; expression.step=1; expression.editable=editable
		add_child(expression); expressions.append(expression)
		expression.value_changed.connect(func(amount):
			if not editable: return
			auto_traits.set_pressed_no_signal(false)
			draft.genes[locus]=[int(amount),int(amount)]
			refresh_values())
	if editable:
		auto_traits=CheckButton.new(); auto_traits.name="AutoInitialTraits"
		auto_traits.position=Vector2(38,605); auto_traits.size=Vector2(479,42)
		auto_traits.text="随血统自动生成初始性状"; auto_traits.button_pressed=true
		auto_traits.add_theme_font_size_override("font_size",17); add_child(auto_traits)
		auto_traits.toggled.connect(func(enabled):
			if enabled: Genome.seed_creator_traits(draft.genes,draft.bloodline)
			refresh_values())
		mode_hint=app.label(self,"",Vector2(42,659),15,app.MUTED)
		app.button(self,"应用血统与基因",Rect2(552,711,475,43),apply_changes,true,true)
	else:
		app.label(self,"比例精度 0.01% · 双亲各贡献一半来源。\n未表达的基因也可以继续传给后代。",Vector2(42,613),15,app.MUTED)
	app.label(self,"表达 ≥40 显现性状并解锁对应技能。\n同部位取较强表达；龙翼还需背部 ≥60。",Vector2(552,643),14,app.MUTED)
	refresh_values()

func start_drag(origin: int) -> void:
	var basis=draft.bloodline.duplicate()
	if other_total(basis,origin)==0 and ratio_memory.has(origin): basis=ratio_memory[origin].duplicate()
	drag_basis[origin]=basis

func other_total(parts: Array, origin: int) -> int:
	return Bloodline.TOTAL-int(parts[origin])

func adjust_origin(origin: int, amount: float) -> void:
	if not editable: return
	var basis: Array=drag_basis.get(origin,draft.bloodline)
	if other_total(basis,origin)>0: ratio_memory[origin]=basis.duplicate()
	elif ratio_memory.has(origin): basis=ratio_memory[origin]
	draft.bloodline=Bloodline.with_share(basis,origin,roundi(amount*100))
	if auto_traits.button_pressed: Genome.seed_creator_traits(draft.genes,draft.bloodline)
	refresh_values()

func refresh_values() -> void:
	for i in range(7):
		sliders[i].set_value_no_signal(draft.bloodline[i]/100.0)
		percentages[i].text=Bloodline.percent(draft.bloodline[i])
		var locus=Genome.TRAITS[i]; var value=Genome.express(draft.genes,locus)
		expressions[i].set_value_no_signal(value)
		expressions[i].tooltip_text="等位基因：%s | %s。表达 ≥40 生效；所有血统均可自由配置。" % draft.genes[locus]
		if editable: expressions[i].get_line_edit().add_theme_color_override("font_color",app.GREEN if value>=Genome.TRAIT_THRESHOLD else app.MUTED)
	var parts=HumanAssembly.build(draft).parts.map(func(p): return p.id)
	var visible: PackedStringArray=[]
	if parts.any(func(id): return id.begins_with("bird_wing")): visible.append("羽翼")
	for item in [["dragon_wing","龙翼"],["scales_face","鳞片"],["claw_hand","兽耳爪"],["fish_tail","鱼尾"],["snake_tail","蛇尾"]]:
		if item[0] in parts: visible.append(item[1])
	if parts.any(func(id): return id.begins_with("horns_")): visible.append("角冠")
	phenotype.text="当前外观："+("人类体态" if visible.is_empty() else " / ".join(visible))
	if editable:
		mode_hint.text="自动模式：非零来源会生成可见初始性状。\n也可单独调整右侧基因，切换为自由模式。\n返回 / Esc 取消，应用后写入创建角色。" if auto_traits.button_pressed else "自由模式：拖动血统将保留手动基因。\n打开自动开关，即可重新同步性状。\n后代仍按双亲等位基因重组。"
	preview.queue_redraw()

func apply_changes() -> void:
	if not editable: return
	source.bloodline=draft.bloodline.duplicate(); source.genes=draft.genes.duplicate(true)
	app.close_modal()
	if changed.is_valid(): changed.call()

func _process(delta: float) -> void:
	elapsed+=delta
	if is_instance_valid(preview): preview.queue_redraw()
