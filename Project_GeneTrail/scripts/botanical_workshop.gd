class_name BotanicalWorkshop
extends Control
## Living specimens use the exact same rig and genes as the world and HUD.
const NOTES=["短面宽颊 · 轻盈短爪","丰厚前胸 · 圆钝口鼻","饱满脸颊 · 梨形身体","圆头宽身 · 贴地重心","弧线头型 · 连续曲颈"]
var app
var samples: Array=[]
var elapsed=0.0
var action="idle"
var base_form=false

static func specimen(species: int) -> UnitData:
	var u=CreatureWorkshop.sample(species,0)
	u.genes.body_a=[0,0]; u.genes.body_b=[0,1]
	var values=[
		{"color":4,"coat":2,"affinity":12,"height":25,"length":34,"bone":34,"muscle":35,"ears":0,"tail":0,"face":1,"eyes":0},
		{"color":0,"coat":1,"affinity":22,"height":65,"length":58,"bone":40,"muscle":45,"ears":1,"tail":1,"face":0,"eyes":1},
		{"color":1,"coat":2,"affinity":85,"height":30,"length":25,"bone":35,"muscle":35,"ears":0,"tail":3,"face":1,"eyes":0},
		{"color":3,"coat":3,"affinity":5,"height":40,"length":55,"bone":50,"muscle":50,"ears":1,"tail":1,"face":0,"eyes":1},
		{"color":5,"coat":1,"affinity":14,"height":35,"length":40,"bone":30,"muscle":30,"ears":1,"tail":3,"face":0,"eyes":4}][species]
	for locus in values: u.genes[locus]=[values[locus],values[locus]]
	u.genes.pattern=[0,0]; u.genes.white=[38,38]; u.genes.contrast=[30,30]
	u.display_name=Genome.SPECIES[species]
	return u

static func open_preview(host) -> BotanicalWorkshop:
	host.open_modal("怪物造型室","查看完整造型与基础形体，观察头身比例、面部表情和不同的遗传组合。")
	var view=BotanicalWorkshop.new(); view.app=host
	view.position=Vector2(30,115); view.size=Vector2(1006,620)
	host.modal_body.add_child(view)
	for species in range(5):
		var u=specimen(species); view.samples.append(u); CreatureAssembly.build(u)
		var x=(species%3)*334; var y=(species/3)*274
		host.label(view,Genome.SPECIES[species],Vector2(x+20,y+16),23,host.INK)
		host.label(view,NOTES[species],Vector2(x+20,y+47),15,host.MUTED)
		host.button(view,"查看 / 调整基因",Rect2(x+17,y+228,298,31),func(): CreatureWorkshop.open_preview(host,u))
	host.label(view,"从轮廓、比例到神态",Vector2(687,304),21,host.INK,287)
	host.label(view,"每种怪物都有自己的脸型与体态。\n\n切换基础形体，查看身体本身。\n点击查看，尝试不同基因组合。",Vector2(687,346),16,host.MUTED,275)
	host.button(view,"基础形体 / 完整造型",Rect2(686,454,286,35),func(): view.base_form=not view.base_form)
	host.button(view,"面部与表情 →",Rect2(686,503,286,35),func(): FaceWorkshop.open_preview(host))
	host.button(view,"待机 / 行走",Rect2(12,571,217,43),func(): view.action="walk" if view.action=="idle" else "idle",true,true)
	host.button(view,"施法",Rect2(240,571,154,43),func(): view.action="cast")
	host.button(view,"同基因物种对照",Rect2(405,571,252,43),func(): CreatureWorkshop.open_preview(host,null,false,true))
	host.button(view,"20 种遗传形态 →",Rect2(670,571,323,43),func(): CreatureWorkshop.open_preview(host,null,true))
	return view

func _process(delta: float) -> void:
	elapsed+=delta; queue_redraw()

func _draw() -> void:
	var phase=elapsed*(9 if action=="walk" else 2)
	for i in range(6):
		var x=(i%3)*334; var y=(i/3)*274
		draw_style_box(app.box(Color("e1e6d4"),Color("bdcbb5"),1,12),Rect2(x+7,y+4,320,265))
		if i==5: continue
		CreatureArt.oval(self,Vector2(x+164,y+213),Vector2(104,12),Color(0.14,0.23,0.16,0.11),Color.TRANSPARENT,0)
		CreatureArt.draw(self,samples[i],Vector2(x+152,y+174),[3.1,3.1,2.95,3.1,2.8][i],phase,{"state":action,"phase":phase,"face_time":elapsed,"base_form":base_form,"amount":(sin(elapsed*3)+1)*0.5})
