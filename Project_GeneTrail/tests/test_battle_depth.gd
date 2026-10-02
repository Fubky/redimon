extends SceneTree
var passed=0
var failed=0
func check(ok: bool, label: String) -> void:
 if ok: passed+=1
 else: failed+=1; push_error("DEPTH FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func fresh() -> GameState:
 var g=GameState.new(); g.new_game(1105)
 for u in g.party:
  u.genes.gloss=[0,0]; u.genes.pattern=[0,0]; u.genes.coat=[0,0]; u.genes.affinity=[0,0]
 return g
func arena() -> GameState:
 var g=fresh(); g.enter_dungeon(0)
 g.world.cells.clear(); g.world.rooms.assign([Rect2i(1,1,20,12)])
 for x in range(1,21):
  for y in range(1,13): g.world.cells[Vector2i(x,y)]=true
 g.enemies.resize(2)
 for i in range(2):
  g.party[i].cell=Vector2i(4,4+i)
  g.enemies[i].cell=Vector2i(6,4+i)
  Genome.seed_traits(g.enemies[i].genes,Bloodline.pure(3)); g.enemies[i].genes.affinity=[60,60]; g.enemies[i].genes.gloss=[0,0]; g.enemies[i].genes.pattern=[2,2]; g.enemies[i].genes.coat=[0,0]
 g.party[0].bloodline=Bloodline.pure(2); Genome.seed_traits(g.party[0].genes,g.party[0].bloodline); g.party[0].equipped_skills.assign(["ember","guard","cleanse","strike"])
 g.start_battle(0); g.active_id=g.party[0].uid; g.clock=10
 return g
func run() -> void:
 var g=fresh()
 check(g.dungeon_unlocked(0) and not g.dungeon_unlocked(1) and not g.enter_dungeon(4),"fresh campaign blocks later regions at rule layer")
 for region in range(5):
  check(g.enter_dungeon(region),"unlocked region entry %d" % region)
  for floor_index in range(3):
   g.current().cell=g.world.stairs
   if floor_index==2:
    check(not g.descend(),"living guardian seals completion")
    for e in g.enemies:
     if e.elite: e.hp=0
   check(g.descend(),"valid floor transition")
  check(region in g.cleared and g.mode=="town","clear awards persistent region badge")
  if region<4: check(g.dungeon_unlocked(region+1),"only next region unlocks")
 var roundtrip=fresh()
 check(roundtrip.restore(JSON.parse_string(JSON.stringify(g.serialize()))) and roundtrip.cleared.size()==5,"campaign roundtrip retains unlocks")
 g=arena(); var a=g.current(); var b=g.enemies[0]
 check(BattleRules.effectiveness("fire",b)==2,"fire beats leaf")
 b.genes.color=[3,3]; b.genes.gloss=[70,70]
 check(BattleRules.effectiveness("fire",b)==1,"dual leaf-water balances weakness and resistance")
 Genome.seed_traits(b.genes,Bloodline.pure(0)); b.genes.color=[5,5]
 check(BattleRules.effectiveness("normal",b)==0,"spirit secondary grants normal immunity")
 Genome.seed_traits(b.genes,Bloodline.pure(3)); b.genes.gloss=[0,0]
 var rule=GameState.SKILLS.ember
 var base=BattleRules.damage(a,b,rule,0)
 check(BattleRules.damage(a,b,rule,3)>base and BattleRules.damage(a,b,rule,2)<base,"sun and rain affect elemental damage")
 a.stages.attack=3
 check(BattleRules.stat(a,"attack")>a.attack(),"positive stages scale offense")
 a.stages.attack=-3
 check(BattleRules.stat(a,"attack")<a.attack(),"negative stages scale offense")
 a.stages.clear(); b.guard=true
 check(BattleRules.damage(a,b,rule,0)<base,"guard halves damage")
 b.guard=false
 Genome.seed_traits(b.genes,Bloodline.pure(4)); b.genes.affinity=[80,80]; b.genes.pattern=[4,4] # overwrite with legal pattern below
 b.genes.pattern=[1,1]; b.genes.coat=[3,3] # ability 2 = water absorb
 check(BattleRules.ability(b)==2 and BattleRules.effectiveness("water",b)==0,"water-absorb immunity is used by forecast")
 g=arena(); a=g.current(); b=g.enemies[0]; b.hp=500
 var ap=a.ap
 check(g.cast("ember",b) and a.ap==ap-30,"signature action executes and consumes AP")
 check(not g.cast("ember",b),"cooldown blocks repeating the same move in one action")
 var actual=500-b.hp
 check(actual>=BattleRules.damage(a,b,rule,0) or b.status=="burn","actual attack uses forecast damage path")
 g.begin_action(a)
 check(a.cooldown("ember")==0,"one-action cooldown recovers on next action")
 a.status="burn"; a.status_turns=3; a.hp=a.max_hp(); a.genes.pattern=[1,1] # disable regeneration
 var before=a.hp
 g.begin_action(a)
 check(a.hp<before and a.status_turns==2,"burn ticks and duration advances once per actor action")
 check(BattleRules.stat(a,"attack")<a.attack(),"burn weakens physical attack")
 a.equipped_skills.assign(["cleanse","guard","ember","befriend"]); a.ap=100
 check(g.cast("cleanse",a) and a.status.is_empty(),"cleanse removes status through real skill flow")
 check(g.cast("guard",a) and a.guard,"guard is an equipable tactical skill")
 a.ap=100
 check(g.cast("befriend",b) and b.marked,"befriend marks target using a skill slot and AP")
 var old=RecruitmentRules.breakdown(b,g.party[0],[]).chance
 a.cooldowns.clear(); g.cast("befriend",b)
 check(RecruitmentRules.breakdown(b,g.party[0],[]).chance==old,"repeated marks cannot stack recruitment chance")
 var data=g.serialize(); var copy=fresh()
 check(copy.restore(JSON.parse_string(JSON.stringify(data))),"v3 battle save validates")
 check(copy.current().guard and copy.current().cooldown("befriend")==1 and copy.enemies[0].marked,"guard cooldown and mark survive reload")
 data.party[0].status="invalid"
 check(not copy.valid_save(data),"invalid status is rejected")
 data=g.serialize(); data.party[0].stages={"attack":99}
 check(not copy.valid_save(data),"invalid stage is rejected")
 data=g.serialize(); data.party[0].cooldowns={"ember":-1}
 check(not copy.valid_save(data),"negative cooldown is rejected")
 data=g.serialize(); data.version=2
 for record in data.party+data.enemies:
  record.species=0
  for key in ["status","status_turns","stages","cooldowns","guard","marked","elite","recruit_rolled","last_recruit_rate"]: record.erase(key)
 check(copy.restore(JSON.parse_string(JSON.stringify(data))),"existing v2 saves migrate without deleting progress")
 check(RecruitmentRules.level_bonus(29)==0 and RecruitmentRules.level_bonus(30)==5 and RecruitmentRules.level_bonus(40)==7.5 and RecruitmentRules.level_bonus(50)==12.5 and RecruitmentRules.level_bonus(99)==24.5,"Sky reference level bonus thresholds")
 g=fresh(); a=g.party[0]
 var frequencies=[]
 for species in range(7):
  var success=0
  for trial in range(700):
   var monster=UnitData.new(); monster.uid="trial-%d-%d" % [species,trial]; monster.bloodline=Bloodline.pure(species); monster.genes=a.genes.duplicate(true); monster.faction="enemy"; monster.hp=0
   a.level=1; a.xp=0
   var count=g.pending.size()
   g.defeated(monster,a)
   if g.pending.size()>count: success+=1
   var random_state=g.rng.state; var gold=g.gold
   g.defeated(monster,a)
   check(g.rng.state==random_state and g.gold==gold,"same defeat cannot reroll or duplicate rewards")
  var observed=success/700.0
  frequencies.append(observed)
  check(absf(observed-RecruitmentRules.BASE[species]/100)<0.065 and success>0 and success<700,"sampled recruit rate matches species profile %d" % species)
  g.pending.clear()
 check(frequencies[0]>frequencies[4],"common species recruit more often than rare species")
 g=arena(); a=g.current(); b=g.enemies[0]
 b.elite=true
 check(RecruitmentRules.breakdown(b,a,[]).chance==0,"negative elite base cannot recruit without bonuses")
 a.level=99; a.genes.affinity=[100,100]; b.marked=true
 check(RecruitmentRules.breakdown(b,a,[0,1,2]).chance>0 and RecruitmentRules.breakdown(b,a,[0,1,2]).chance<100,"elite bonuses remain probabilistic")
 b.hp=0; g.defeated(b,a)
 check(not b in g.pending and b.recruit_rolled,"first-clear guardian does not recruit")
 # AI weighs weakness and can use support, instead of blindly choosing the nearest target.
 g=arena(); b=g.enemies[0]; g.active_id=b.uid; Genome.seed_traits(b.genes,Bloodline.pure(2)); b.equipped_skills.assign(["ember","guard","cleanse","strike"])
 Genome.seed_traits(g.party[0].genes,Bloodline.pure(3)); g.party[0].genes.affinity=[60,60]; g.party[0].genes.pattern=[2,2]; g.party[0].genes.coat=[0,0]; g.party[0].genes.gloss=[0,0]
 var action=g.best_ai_action(b)
 check(action.skill=="ember" and action.target==g.party[0],"AI selects super-effective ranged signature")
 b.hp=1; b.status="poison"; b.status_turns=3; b.cooldowns.ember=1
 action=g.best_ai_action(b)
 check(action.skill=="cleanse","AI considers cleansing its own status")
 print("DEPTH_TESTS: ",passed," passed; ",failed," failed. Recruit samples: ",frequencies)
 quit(1 if failed>0 else 0)
