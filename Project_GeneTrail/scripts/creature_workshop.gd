class_name CreatureWorkshop
extends Control
## Read-only phenotype sandbox: all controls edit copies, never the player's roster.
var app
var unit: UnitData
var samples: Array=[]
var gallery=false
var species_focus=false
var silhouettes=false
var elapsed=0.0
var action="idle"
var exploded=false
const PRESETS=["紧凑 · 短毛","修长 · 高肩","厚重 · 蓬毛","鳞甲 · 卷尾"]
const BODY_GENES=[[[0,0],[0,0]],[[0,1],[0,1]],[[0,0],[0,1]],[[0,1],[1,1]],[[1,1],[1,1]]]
const SPECIES_NOTES=["短面宽颊 · 轻巧腰身\n柔软长尾 · 交替迈步","圆钝口鼻 · 丰厚前胸\n蓬尾短爪 · 大步奔跑","饱满脸颊 · 梨形圆臀\n收起前爪 · 双足轻跳","圆头宽身 · 贴地重心\n分趾短爪 · 贴地爬行","弧线头型 · 盘绕躯干\n连续曲颈 · 摆身滑行"]

static func clone(source: UnitData) -> UnitData:
	var result=UnitData.new(); result.genes=source.genes.duplicate(true)
	result.species=source.species; result.display_name=source.display_name
	return result

static func sample(species: int, preset: int) -> UnitData:
	var u=UnitData.new(); u.species=species; u.display_name=PRESETS[preset]
	for locus in Genome.LIMITS:
		var value=int(Genome.LIMITS[locus]/2); u.genes[locus]=[value,value]
	var values=[
		{"height":12,"length":15,"bone":20,"muscle":22,"ears":1,"tail":0,"face":1,"coat":0,"pattern":2,"white":35},
		{"height":100,"length":100,"bone":20,"muscle":15,"ears":2,"tail":2,"face":2,"coat":0,"pattern":1,"white":15},
		{"height":55,"length":65,"bone":100,"muscle":100,"ears":0,"tail":1,"face":0,"coat":2,"pattern":3,"white":65},
		{"height":40,"length":45,"bone":90,"muscle":75,"ears":2,"tail":3,"face":2,"coat":3,"pattern":0,"white":50}][preset]
	for locus in values: u.genes[locus]=[values[locus],values[locus]]
	var bodies=[0,1,4,3]
	u.genes.body_a=BODY_GENES[bodies[preset]][0].duplicate(); u.genes.body_b=BODY_GENES[bodies[preset]][1].duplicate()
	u.genes.color=[species,species]
	return u

static func open_preview(host, source: UnitData=null, comparison: bool=false, species_comparison: bool=false) -> CreatureWorkshop:
	host.open_modal("物种观察室" if species_comparison else "形态工坊","相同基因与底色，观察五种不同的身体结构。" if species_comparison else "独立部件由基因选择与拼接。这里的调整仅用于预览，不会修改伙伴或存档。")
	var view=CreatureWorkshop.new(); view.app=host; view.gallery=comparison; view.species_focus=species_comparison
	view.unit=clone(source) if source!=null else sample(0,0)
	view.position=Vector2(30,115); view.size=Vector2(1006,620)
	host.modal_body.add_child(view)
	view.build_controls()
	return view

func _process(delta: float) -> void:
	elapsed+=delta
	queue_redraw()

func build_controls() -> void:
	if species_focus:
		var shared=sample(0,0).genes.duplicate(true)
		for locus in ["height","bone","muscle","length","contrast","gloss"]: shared[locus]=[50,50]
		shared.body_a=[0,0]; shared.body_b=[0,1]
		shared.ears=[0,0]; shared.face=[0,0]; shared.color=[3,3]; shared.pattern=[0,0]; shared.white=[25,25]
		for species in range(5):
			var u=UnitData.new(); u.species=species; u.genes=shared.duplicate(true); u.display_name=Genome.SPECIES[species]
			samples.append(u); CreatureAssembly.build(u)
			app.label(self,Genome.SPECIES[species],Vector2(species*200+24,59),24,app.INK)
			app.label(self,SPECIES_NOTES[species],Vector2(species*200+22,375),15,app.MUTED,170)
			app.button(self,"查看部件",Rect2(species*200+18,449,164,37),func(): open_preview(app,u))
		app.label(self,"物种决定骨架与轮廓；基因决定各自的体型、五官、毛质和花纹。",Vector2(16,10),16,app.MUTED)
		app.button(self,"彩色 / 纯剪影",Rect2(16,541,214,43),func(): silhouettes=not silhouettes,true,true)
		app.button(self,"待机 / 行走",Rect2(242,541,208,43),func(): action="walk" if action=="idle" else "idle")
		app.button(self,"面部表情 →",Rect2(462,541,267,43),func(): FaceWorkshop.open_preview(app))
		app.button(self,"20 种基因形态 →",Rect2(742,541,247,43),func(): open_preview(app,unit,true))
	elif gallery:
		for row in range(4):
			for species in range(5):
				var u=sample(species,row); samples.append(u); CreatureAssembly.build(u)
				var x=species*200; var y=36+row*129
				app.button(self,PRESETS[row],Rect2(x+10,y+94,180,28),func(): open_preview(app,u,false))
		app.button(self,"调整当前伙伴",Rect2(736,574,256,43),func(): open_preview(app,unit,false),true,true)
		app.button(self,"五物种同色对照",Rect2(10,574,238,43),func(): open_preview(app,unit,false,true))
		app.label(self,"点击形态，逐项调整基因。",Vector2(275,585),15,app.MUTED)
	else:
		var species=OptionButton.new(); species.position=Vector2(12,0); species.size=Vector2(166,38)
		for name in Genome.SPECIES: species.add_item(name)
		species.select(unit.species); add_child(species)
		species.item_selected.connect(func(index): unit.species=index; CreatureAssembly.build(unit); queue_redraw())
		app.button(self,"20 种形态对照",Rect2(195,0,211,38),func(): open_preview(app,unit,true))
		for i in range(3):
			var mode=["idle","walk","cast"][i]
			app.button(self,["待机","行走","施法"][i],Rect2(12+i*132,442,122,36),func(): action=mode)
		app.button(self,"拼合 / 拆开部件",Rect2(12,491,386,40),func(): exploded=not exploded,true,true)
		app.button(self,"五物种对照",Rect2(12,552,186,40),func(): open_preview(app,unit,false,true))
		app.button(self,"面部表情 →",Rect2(210,552,188,40),func(): FaceWorkshop.open_preview(app,unit))
		var scroll=ScrollContainer.new(); scroll.position=Vector2(445,0); scroll.size=Vector2(558,615); add_child(scroll)
		var column=VBoxContainer.new(); column.custom_minimum_size.x=534; column.add_theme_constant_override("separation",8); scroll.add_child(column)
		var body=HBoxContainer.new(); body.custom_minimum_size=Vector2(526,36); column.add_child(body)
		var caption=Label.new(); caption.text="体型组合"; caption.custom_minimum_size.x=120; body.add_child(caption)
		var select=OptionButton.new(); select.custom_minimum_size.x=358; body.add_child(select)
		for name in ["紧凑型","小型","中型","中大型","大型"]: select.add_item(name)
		select.select(["紧凑型","小型","中型","中大型","大型"].find(Genome.body_name(unit.genes)))
		select.item_selected.connect(func(index): unit.genes.body_a=BODY_GENES[index][0].duplicate(); unit.genes.body_b=BODY_GENES[index][1].duplicate(); CreatureAssembly.build(unit))
		for locus in Genome.LIMITS:
			if locus in ["body_a","body_b"]: continue
			var row=HBoxContainer.new(); row.custom_minimum_size=Vector2(526,30); column.add_child(row)
			var name=Label.new(); name.text=GeneTraits.NAMES[locus]; name.custom_minimum_size.x=118; row.add_child(name)
			var slider=HSlider.new(); slider.custom_minimum_size=Vector2(312,26); slider.max_value=Genome.LIMITS[locus]; slider.step=1
			slider.value=Genome.express(unit.genes,locus); row.add_child(slider)
			var value=Label.new(); value.text="  %d"%slider.value; value.custom_minimum_size.x=56; row.add_child(value)
			slider.value_changed.connect(func(v): unit.genes[locus]=[int(v),int(v)]; value.text="  %d"%v; queue_redraw())
	CreatureAssembly.build(unit)

func _draw() -> void:
	var phase=elapsed*(9 if action=="walk" else 2)
	var motion={"state":action,"phase":phase,"face_time":elapsed,"amount":(sin(elapsed*3)+1)*0.5}
	if species_focus:
		for i in range(samples.size()):
			var x=i*200
			draw_style_box(app.box(Color("dce3d3"),Color("b5c5b8"),1,10),Rect2(x+7,45,186,458))
			draw_line(Vector2(x+23,350),Vector2(x+180,350),Color("bdcbbb"),1)
			CreatureArt.oval(self,Vector2(x+98,330),Vector2(64,10),Color(0.12,0.2,0.25,0.12),Color.TRANSPARENT,0)
			motion.silhouette=silhouettes
			CreatureArt.draw(self,samples[i],Vector2(x+92,285),2.25,phase,motion)
	elif gallery:
		for species in range(5):
			draw_string(app.font,Vector2(species*200+52,23),Genome.SPECIES[species],HORIZONTAL_ALIGNMENT_LEFT,-1,20,app.INK)
		for i in range(samples.size()):
			var x=(i%5)*200; var y=36+(i/5)*129
			draw_style_box(app.box(Color("dae0ce"),Color("c0cabb"),1,8),Rect2(x+7,y,186,90))
			CreatureArt.oval(self,Vector2(x+101,y+75),Vector2(40,7),Color(0.12,0.2,0.25,0.12),Color.TRANSPARENT,0)
			var fit_scale=1.06 if i in [12,14] else 1.22 # Tall, heavy forms stay inside their preview card.
			CreatureArt.draw(self,samples[i],Vector2(x+98,y+59),fit_scale,phase,motion)
	else:
		draw_style_box(app.box(Color("dce3d3"),Color("a1b5a9"),1,8),Rect2(8,51,395,373))
		CreatureArt.oval(self,Vector2(205,374),Vector2(103,17),Color(0.12,0.2,0.25,0.12),Color.TRANSPARENT,0)
		motion.explode=27 if exploded else 0
		CreatureArt.draw(self,unit,Vector2(183,304),3.7 if not exploded else 2.8,phase,motion)
		var rig=CreatureAssembly.build(unit)
		draw_string(app.font,Vector2(24,404),"%s  ·  %d 个独立部件"%[Genome.body_name(unit.genes),rig.parts.size()],HORIZONTAL_ALIGNMENT_LEFT,-1,18,app.INK)
