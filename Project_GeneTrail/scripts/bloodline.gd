class_name Bloodline
extends RefCounted
## Ancestry is a full distribution, independent of the expressed diploid genome.
## Integer basis points preserve a 100% total across saves and generations.
const TOTAL=10000
const COLORS=[Color("c5ad7c"),Color("77b9c4"),Color("8baf91"),Color("c99783"),Color("709fcb"),Color("a69ac4"),Color("bcb475")]

static func pure(origin: int) -> Array:
	var result=[0,0,0,0,0,0,0]; result[clampi(origin,0,6)]=TOTAL; return result

static func normalize(weights: Array) -> Array:
	var total=0.0
	for value in weights: total+=maxf(0,float(value))
	if total<=0: return pure(0)
	var result=[]; var remainders=[]; var used=0
	for i in range(7):
		var exact=maxf(0,float(weights[i]))*TOTAL/total
		result.append(floori(exact)); used+=result[i]
		remainders.append({"index":i,"fraction":exact-floor(exact)})
	remainders.sort_custom(func(a,b): return a.index<b.index if is_equal_approx(a.fraction,b.fraction) else a.fraction>b.fraction)
	for i in range(TOTAL-used): result[remainders[i%7].index]+=1
	return result

static func inherit(a: Array, b: Array) -> Array:
	var weights=[]
	for i in range(7): weights.append(int(a[i])+int(b[i]))
	return normalize(weights)

static func with_share(parts: Array, origin: int, amount: int) -> Array:
	var weights=parts.duplicate(); weights[origin]=0
	if weights.all(func(value): return value==0):
		weights.fill(1); weights[origin]=0
	var total=0
	for value in weights: total+=int(value)
	var target=clampi(amount,0,TOTAL); var available=TOTAL-target
	var result=[0,0,0,0,0,0,0]; var fractions=[]; var used=0
	for i in range(7):
		if i==origin: continue
		var exact=float(weights[i])*available/total
		result[i]=floori(exact); used+=result[i]
		fractions.append({"index":i,"fraction":exact-floor(exact)})
	fractions.sort_custom(func(a,b): return a.index<b.index if is_equal_approx(a.fraction,b.fraction) else a.fraction>b.fraction)
	for i in range(available-used): result[fractions[i].index]+=1
	result[origin]=target
	return result

static func valid(value: Variant) -> bool:
	if not value is Array or value.size()!=7: return false
	var total=0
	for part in value:
		if not MercenaryRules.is_number(part) or part!=floor(float(part)) or part<0 or part>TOTAL: return false
		total+=int(part)
	return total==TOTAL

static func legacy(d: Dictionary) -> Array:
	var pair=d.get("ancestry",[int(d.get("species",0)),int(d.get("species",0))])
	return inherit(pure(int(pair[0])),pure(int(pair[1])))

static func percent(part: int) -> String:
	return ("%d" % (part/100) if part%100==0 else "%.2f" % (part/100.0))+"%"

static func summary(parts: Array, separator: String=" · ") -> String:
	var labels: PackedStringArray=[]
	for i in range(7):
		if parts[i]>0: labels.append(Genome.SPECIES[i]+" "+percent(parts[i]))
	return separator.join(labels)

static func compact(parts: Array) -> String:
	var count=parts.filter(func(value): return value>0).size()
	return summary(parts) if count<=2 else "%d 源混合血统" % count

static func weighted(parts: Array, values: Array) -> float:
	var result=0.0
	for i in range(7): result+=float(parts[i])*float(values[i])/TOTAL
	return result
