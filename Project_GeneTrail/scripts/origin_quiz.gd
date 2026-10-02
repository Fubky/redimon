class_name OriginQuiz
extends RefCounted
## A playful character creator, not a psychological diagnosis.
const QUESTIONS=[
	["林间小路突然出现一扇陌生的门，你会……",["先推开，看看里面有什么","邀请伙伴一起去看看","观察门上的纹路与脚印","记下位置，准备周全再来"]],
	["暴雨让旅行计划泡汤了，你想做什么？",["披上斗篷，雨中也有冒险","给大家煮一锅热汤","聆听雨点，记录新的旋律","整理行囊，等待天气放晴"]],
	["朋友在岔路口犹豫，你会……",["主动选一条，承担带路责任","询问大家更喜欢哪条路","爬上高处找新的线索","对照地图，选可靠的路线"]],
	["远征结束后，你最想带回什么？",["挑战强敌获得的纪念章","和伙伴一起画的旅行手记","从没见过的奇特种子","足够大家过冬的补给"]],
	["夜晚营地传来窸窣声，你会……",["站到伙伴前面查看","轻声问是不是有人需要帮助","悄悄观察声音来自哪里","先检查营地四周是否安全"]],
	["有一天完全属于自己，你更愿意……",["攀登还没去过的山顶","陪朋友做一件小事","尝试一项陌生的手艺","在熟悉的地方慢慢散步"]],
	["同伴输掉比赛有些沮丧，你会……",["约好明天一起练习再挑战","坐在身边，听对方说说话","想个有趣的新游戏转移心情","复盘过程，找出下次能改进的点"]],
	["你在海边发现漂流瓶，里面是……",["一张通往未知岛屿的航图","一封写给远方朋友的信","一段需要解开的奇怪谜语","一份记录潮汐与星辰的笔记"]],
	["旅行队里，你最自然会承担什么？",["开路与保护大家","照顾每个人的情绪","发现捷径和有趣的东西","管理补给与安排休息"]],
	["如果能向未来的自己说一句话……",["愿你一直有出发的勇气","愿你身边总有温暖的伙伴","愿你好奇的眼睛永远闪亮","愿你以自己的步调抵达远方"]]
]
const PROFILES=["向阳的勇气","温柔的回声","追风的好奇","山石的从容"]

static func result(answers: Array) -> Dictionary:
	if answers.size()!=QUESTIONS.size() or not answers.all(func(a): return a is int and a>=0 and a<4): return {}
	var score=[0,0,0,0]
	var seed_value=73019
	for i in range(answers.size()):
		score[answers[i]]+=3
		score[(answers[i]+i+1)%4]+=1
		seed_value=(seed_value*31+answers[i]+1)%2147483647
	var lead=score.find(score.max())
	var rng=RandomNumberGenerator.new(); rng.seed=seed_value
	var genes=Genome.random_genes(rng)
	var body_pairs=[[[1,1],[1,1]],[[0,1],[1,1]],[[0,1],[0,1]],[[0,0],[0,0]]]
	genes.body_a=body_pairs[lead][0].duplicate(); genes.body_b=body_pairs[lead][1].duplicate()
	var axes={"height":0,"bone":3,"muscle":0,"length":2,"white":1,"contrast":0,"gloss":2,"affinity":1,"agility":2}
	for locus in axes:
		var desired=clampi(25+score[axes[locus]]*2,15,90)
		genes[locus]=[clampi(desired+rng.randi_range(-12,12),0,100),clampi(desired+rng.randi_range(-12,12),0,100)]
	for entry in [["color",2],["pattern",3],["coat",4],["face",5],["ears",6],["eyes",7],["tail",8]]:
		var locus: String=entry[0]
		var value=(answers[entry[1]]+answers[9])%(Genome.LIMITS[locus]+1)
		genes[locus]=[value,mini(Genome.LIMITS[locus],value+rng.randi_range(0,1))]
	return {"genes":genes,"profile":PROFILES[lead],"scores":score,"answers":answers.duplicate(),"seed":seed_value}
