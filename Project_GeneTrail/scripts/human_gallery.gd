class_name HumanGallery
extends Control
var app
var samples: Array=[]
var elapsed=0.0
var action="idle"
var variant=0

static func open_preview(owner) -> HumanGallery:
	owner.open_modal("帝国佣兵 · 混合血统名录","没有固定种族。血统记录家系来源；共用基因独立表达，羽翼、鳞片、兽耳与角可以共存。")
	var view=HumanGallery.new(); view.app=owner; view.position=Vector2(28,156); view.size=Vector2(1010,554)
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE; owner.modal_body.add_child(view); view.populate()
	owner.button(owner.modal_body,"更换遗传变体",Rect2(34,108,245,38),func(): view.variant+=1; view.populate())
	owner.button(owner.modal_body,"行走",Rect2(295,108,145,38),func(): view.action="walk")
	owner.button(owner.modal_body,"施技",Rect2(451,108,145,38),func(): view.action="cast")
	owner.button(owner.modal_body,"待机",Rect2(607,108,145,38),func(): view.action="idle")
	owner.label(owner.modal_body,"血统与表达分别遗传：低占比来源也可以表现强特征。互斥部件按表达强度选择；职业装备随转职改变。",Vector2(34,731),14,owner.MUTED)
	return view

func populate() -> void:
	samples.clear()
	var origins=[[0,5000,5000,0,0,0,0],[0,5000,0,0,0,0,5000],[0,0,0,5000,0,0,5000],[0,5000,0,0,5000,0,0],[0,0,5000,0,0,5000,0],[2500,2500,0,2500,0,0,2500]]
	for i in range(origins.size()):
		var u=MercenaryRules.sample(i,i%3,variant+i)
		u.bloodline=origins[i].duplicate(); Genome.seed_traits(u.genes,u.bloodline)
		if i==5:
			for locus in ["poise","plumage","feral","horns"]: u.genes[locus]=[80,20]
		u.genes.white=[100,100] if variant%2==0 else [0,0]
		samples.append(u); HumanAssembly.build(u)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed+=delta; queue_redraw()

func _draw() -> void:
	for i in range(samples.size()):
		var x=(i%3)*337; var y=(i/3)*278; var u: UnitData=samples[i]
		draw_style_box(app.box(Color("e5e1d6"),Color("c7bfad"),1,8),Rect2(x,y,328,268))
		draw_string(app.font,Vector2(x+13,y+27),u.display_name+" · "+MercenaryRules.JOBS[u.profession],HORIZONTAL_ALIGNMENT_LEFT,-1,18,app.INK)
		var labels=Bloodline.summary(u.bloodline," / ").split(" / ")
		for n in range(labels.size()): draw_string(app.font,Vector2(x+13+(n%2)*157,y+51+(n/2)*19),labels[n],HORIZONTAL_ALIGNMENT_LEFT,-1,13,app.MUTED)
		CreatureArt.oval(self,Vector2(x+164,y+224),Vector2(47,9),Color(0.12,0.18,0.24,0.16),Color.TRANSPARENT,0)
		HumanAssembly.draw(self,u,Vector2(x+157,y+199),2.45,elapsed*3,{"state":action,"phase":elapsed*(9 if action=="walk" else 2),"face_time":elapsed})
		var left=float(x+13)
		for n in range(7):
			var width=302*u.bloodline[n]/10000.0
			draw_rect(Rect2(left,y+248,width,5),Bloodline.COLORS[n]); left+=width
