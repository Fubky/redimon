class_name FaceWorkshop
extends Control
## The same facial parts used in gameplay, enlarged for comparison; no roster writes.
const GROUPS=[["calm","focus","happy"],["hurt","surprise","sleep"]]
const NAMES={"calm":"日常 · 好奇","focus":"战斗 · 专注","happy":"恢复 · 开心","hurt":"受击 · 忍痛","surprise":"惊讶","sleep":"休息 · 闭眼"}
var app
var samples: Array=[]
var group=0
var elapsed=0.0

static func open_preview(host, source: UnitData=null) -> FaceWorkshop:
	host.open_modal("面部表情室","脸型与瞳色由基因决定，眉眼与嘴部随行动切换。这里的预览不会修改伙伴。")
	var view=FaceWorkshop.new(); view.app=host
	view.position=Vector2(30,115); view.size=Vector2(1006,620)
	host.modal_body.add_child(view)
	for species in range(5):
		var u=CreatureWorkshop.clone(source) if source!=null else CreatureWorkshop.sample(species,0)
		u.species=species
		if source==null:
			u.genes.face=[0,0]; u.genes.ears=[0,0]; u.genes.pattern=[0,0]; u.genes.white=[25,25]
			u.genes.color=[species,species]; u.genes.eyes=[species,species]
		view.samples.append(u); CreatureAssembly.build(u)
	view.build_controls()
	return view

func build_controls() -> void:
	app.button(self,"日常 / 战斗 / 恢复",Rect2(8,568,237,40),func(): group=0,true,true)
	app.button(self,"受击 / 惊讶 / 休息",Rect2(254,568,237,40),func(): group=1)
	var face=OptionButton.new(); face.position=Vector2(511,568); face.size=Vector2(228,40)
	for name in ["脸型：灵动","脸型：圆润","脸型：锐利"]: face.add_item(name)
	face.select(Genome.express(samples[0].genes,"face")); add_child(face)
	face.item_selected.connect(func(index):
		for u in samples: u.genes.face=[index,index]; CreatureAssembly.build(u)
		queue_redraw())
	app.button(self,"返回形态工坊",Rect2(755,568,238,40),func(): CreatureWorkshop.open_preview(app,null,true))

func _process(delta: float) -> void:
	elapsed+=delta
	queue_redraw()

func _draw() -> void:
	for col in range(5):
		var x=col*200
		draw_string(app.font,Vector2(x+51,24),Genome.SPECIES[col],HORIZONTAL_ALIGNMENT_LEFT,-1,20,app.INK)
		for row in range(3):
			var y=37+row*173
			var mood: String=GROUPS[group][row]
			draw_style_box(app.box(Color("dce3d3"),Color("b4c5b9"),1,9),Rect2(x+7,y,186,162))
			CreatureAssembly.draw_portrait(self,samples[col],Vector2(x+100,y+82),1.48,elapsed*2,{"expression":mood,"blink":false,"face_time":elapsed})
			draw_string(app.font,Vector2(x+35,y+147),NAMES[mood],HORIZONTAL_ALIGNMENT_LEFT,156,15,app.MUTED)
