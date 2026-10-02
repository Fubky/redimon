"""Designed head volumes and layered eyes; all facial overlays remain swappable."""
STATES=('calm','focus','happy','hurt','sleep','surprise')


def create_portraits(add,path,ellipse,parts):
    heads=[
        ['M 17 39 C 15 24 28 14 46 17 C 64 12 78 25 79 40 Q 81 45 88 49 L 81 56 Q 86 60 78 69 C 67 84 30 87 16 72 Q 10 65 12 61 L 19 58 L 10 53 Q 16 48 17 39 Z',
         'M 15 40 C 13 23 31 14 49 18 C 68 15 81 30 80 45 L 88 52 L 82 58 C 90 74 67 86 48 85 C 26 88 7 76 12 61 L 19 57 L 10 52 Q 15 48 15 40 Z',
         'M 16 34 Q 26 16 46 17 Q 65 12 77 30 L 79 41 L 89 47 L 81 55 L 86 59 Q 70 78 48 82 Q 24 79 12 67 L 19 59 L 9 53 L 17 44 Z'],
        ['M 15 34 C 15 20 29 12 46 17 C 62 12 75 28 74 41 L 84 48 Q 95 49 91 60 Q 85 74 68 74 C 54 86 24 86 13 69 L 18 57 L 11 52 Q 13 44 15 34 Z',
         'M 13 38 C 12 22 31 16 49 20 C 67 16 77 32 75 46 L 87 51 Q 97 58 86 69 Q 80 76 66 76 C 45 93 15 81 11 68 L 17 57 Q 11 52 13 38 Z',
         'M 15 31 Q 27 13 45 16 Q 63 11 73 29 L 76 41 L 88 47 Q 96 53 90 63 Q 83 72 68 73 L 51 85 Q 28 82 13 68 L 18 57 L 9 52 L 15 42 Z'],
        ['M 16 36 C 18 18 36 15 50 19 C 67 16 78 31 77 45 Q 88 48 89 58 C 91 74 66 85 43 84 C 18 85 6 75 10 58 Q 9 45 16 36 Z',
         'M 14 38 C 18 19 38 16 54 22 C 70 20 78 33 77 47 Q 92 49 91 62 C 89 78 63 89 42 86 C 18 89 5 73 8 58 Q 8 45 14 38 Z',
         'M 17 32 Q 32 14 50 19 Q 69 17 77 35 L 78 47 Q 92 53 88 63 Q 74 80 46 84 Q 19 82 9 67 L 14 53 Q 10 42 17 32 Z'],
        ['M 12 37 C 17 21 33 17 49 23 Q 64 18 75 34 L 82 44 Q 94 47 92 60 C 89 76 65 82 44 77 C 23 78 9 67 8 53 Q 7 44 12 37 Z',
         'M 12 39 C 17 22 38 20 52 27 Q 69 23 77 39 L 85 47 Q 97 51 91 65 Q 83 81 56 81 C 31 84 8 72 7 55 Q 7 46 12 39 Z',
         'M 10 34 Q 26 16 43 21 L 56 26 Q 68 20 77 36 L 89 45 Q 99 54 89 66 Q 70 81 43 76 Q 20 77 8 60 L 7 48 Z'],
        ['M 15 37 C 23 20 36 16 54 22 Q 70 19 80 37 L 90 45 Q 98 55 84 64 Q 59 76 35 66 Q 15 63 10 51 Q 9 44 15 37 Z',
         'M 14 39 C 22 23 40 20 55 26 Q 71 24 81 41 L 91 49 Q 97 61 82 67 Q 54 81 31 68 Q 11 63 9 51 Z',
         'M 12 34 L 32 17 Q 47 13 61 25 L 75 30 L 88 42 Q 98 48 91 57 L 81 65 Q 56 73 33 65 L 11 55 L 8 45 Z']]
    for species,forms in enumerate(heads):
        for face,shape in enumerate(forms):
            if species==0:
                detail=path('M 12 61 Q 28 54 41 64 Q 51 67 60 61 Q 70 63 85 54 Q 89 80 48 85 Q 21 83 12 69 Z','%CREAM%')
                detail+=path('M 57 59 Q 61 56 65 59 Q 66 63 61 65 Q 57 64 57 59 Z','%INK%')
                detail+=path('M 58 59 L 61 59','none','%INNER%',1.1)
                detail+=path('M 22 65 L 29 66 M 19 70 L 26 71','none','%SHADOW%',0.85)
            elif species==1:
                detail=path('M 13 62 Q 29 56 43 65 Q 54 65 60 54 Q 70 47 87 50 Q 98 59 85 70 Q 78 78 64 74 Q 52 90 31 79 Q 17 74 13 62 Z','%CREAM%')
                detail+=path('M 76 51 Q 83 48 88 52 Q 89 59 82 61 Q 76 60 75 55 Z','%INK%')
                detail+=path('M 79 52 Q 82 51 85 53','none','%LIGHT%',1.2)
            elif species==2:
                detail=path('M 9 58 Q 27 52 41 64 Q 50 67 59 60 Q 72 51 89 56 Q 95 77 53 87 Q 20 89 9 71 Z','%CREAM%')
                detail+=ellipse(78,57,4,3,'%INNER%','%INK%',1.1)
                detail+=ellipse(77,56,1.3,0.7,'%LIGHT%')
                detail+=ellipse(24,64,5,2.5,'%INNER%')
            elif species==3:
                detail=path('M 8 56 Q 32 65 54 62 Q 76 66 94 54 Q 94 79 57 80 Q 19 81 8 62 Z','%CREAM%')
                detail+=ellipse(82,53,1.2,1,'%INK%')
                detail+=ellipse(24,62,2.2,1.8,'%ACCENT%')+ellipse(30,64,1.5,1.3,'%ACCENT%')
            else:
                detail=path('M 11 52 Q 28 59 45 56 Q 65 63 94 47 Q 100 65 63 72 Q 28 73 11 58 Z','%CREAM%')
                detail+=ellipse(85,48,1.2,0.8,'%INK%')
                detail+=path('M 37 26 Q 43 17 49 25 Q 43 25 45 33 Q 40 33 37 26 Z','%CREAM%')
            # The eye region is intentionally quiet; inherited markings remain on the torso.
            add(f'head_{species}_{face}',shape,detail)

    eyes=[[(38,47,10.0,12.5),(69,44,6.0,10.5)],
          [(35,44,9.5,11.7),(64,43,5.8,9.4)],
          [(37,47,9.2,11.7),(68,44,6.3,9.9)],
          [(37,46,11.7,9.5),(69,46,6.5,8.4)],
          [(40,44,10.8,9.2),(72,43,5.8,7.9)]]
    for species,pair in enumerate(eyes):
        for face in range(3):
            for state in STATES:
                paint=''; defs=''
                for side,(cx,cy,rx,ry) in enumerate(pair):
                    rx*=[1,1.05,0.96][face]; ry*=[1,1.07,0.88][face]
                    if state in ['sleep','hurt','happy']:
                        if state=='sleep': line=f'M {cx-rx} {cy} Q {cx} {cy+ry*0.6} {cx+rx} {cy-2}'
                        elif state=='happy': line=f'M {cx-rx} {cy+3} Q {cx-1} {cy-ry} {cx+rx} {cy+1}'
                        else:
                            sign=1 if side==0 else -1
                            line=f'M {cx-sign*rx} {cy-ry*0.6} L {cx+sign*rx*0.4} {cy} L {cx-sign*rx} {cy+ry*0.65}'
                        paint+=path(line,'none','%INK%',2.35)
                        if state=='happy': paint+=ellipse(cx-1,cy+ry*0.7,rx*0.48,1.6,'#df9c8d')
                        if state=='hurt': paint+=path(f'M {cx-rx*0.8} {cy-ry-4} l {rx*1.4} -1','none','%INK%',1.5)
                        continue
                    focus=state=='focus'
                    top=cy-ry*(0.63 if focus else (0.80 if species>=3 else 1.0))
                    tilt=3.5 if focus else (1.5 if face==2 else -0.5)
                    if side: tilt*=-0.55
                    shape=f'M {cx-rx} {cy-ry*0.4-tilt} Q {cx-rx*0.4} {top-4} {cx+rx} {top+3+tilt} C {cx+rx*1.25} {cy+ry*0.5} {cx+rx*0.35} {cy+ry*1.1} {cx-rx*0.18} {cy+ry} Q {cx-rx*1.13} {cy+ry*0.96} {cx-rx} {cy-ry*0.4-tilt} Z'
                    if species==2 and state=='calm':
                        shape=f'M {cx-rx} {cy} C {cx-rx} {cy-ry*1.4} {cx+rx} {cy-ry*1.4} {cx+rx} {cy} C {cx+rx} {cy+ry*1.3} {cx-rx} {cy+ry*1.3} {cx-rx} {cy} Z'
                    if state=='surprise':
                        shape=f'M {cx-rx} {cy} C {cx-rx} {cy-ry*1.5} {cx+rx} {cy-ry*1.5} {cx+rx} {cy} C {cx+rx} {cy+ry*1.4} {cx-rx} {cy+ry*1.4} {cx-rx} {cy} Z'
                    defs+=f'<clipPath id="e{side}">{path(shape,"white")}</clipPath>'
                    paint+=path(shape,'#fff9e9','%INK%',1.5)
                    ix=cx+rx*0.16; iris=rx*(0.65 if state=='surprise' else 0.87)
                    paint+=f'<g clip-path="url(#e{side})">'
                    paint+=ellipse(ix,cy,iris,ry*1.04,'%INK%')
                    paint+=ellipse(ix,cy+ry*0.35,iris*0.84,ry*0.64,'%EYE%')
                    paint+=ellipse(ix+0.2,cy-ry*0.16,iris*(0.36 if species==4 else (0.73 if species==2 else 0.60)),ry*0.83,'%INK%')
                    paint+=ellipse(ix-iris*0.30,cy-ry*0.42,iris*(0.24 if species>=3 else 0.31),ry*0.24,'#fffaf0')
                    paint+='</g>'
                    upper=f'M {cx-rx} {cy-ry*0.4-tilt} Q {cx-rx*0.4} {top-4} {cx+rx} {top+3+tilt}'
                    if state=='surprise' or (species==2 and state=='calm'): upper=f'M {cx-rx} {cy-2} Q {cx} {cy-ry*1.7} {cx+rx} {cy-2}'
                    paint+=path(upper,'none','%INK%',2.45)
                    if focus: paint+=path(f'M {cx-rx*0.9} {top-7-tilt*0.7} Q {cx} {top-5} {cx+rx*0.8} {top-4+tilt*0.5}','none','%INK%',1.7)
                    elif state=='surprise': paint+=path(f'M {cx-rx*0.6} {top-5} Q {cx} {top-9} {cx+rx*0.6} {top-5}','none','%INK%',1.5)
                parts[f'eyes_{species}_{face}_{state}']=f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><defs>{defs}</defs>{paint}</svg>'

        cx,cy,span=[(61,70,8),(75,68,9),(69,69,8),(67,67,12),(70,62,11)][species]
        for state in STATES:
            if state=='calm':
                mouth=path(f'M {cx-span} {cy-2} Q {cx} {cy+3} {cx+span} {cy-3}','none','%INK%',1.65)
                if species==0: mouth=path('M 61 64 L 61 67 Q 57 72 52 68 M 61 67 Q 67 72 71 66','none','%INK%',1.65)
                if species==2: mouth+=path('M 64 69 L 64 74 Q 67 76 70 73 L 70 69 Z','#fff9e9','%INK%',0.85)
            elif state=='focus':
                mouth=path(f'M {cx-span*0.75} {cy} Q {cx} {cy+1} {cx+span} {cy-3}','none','%INK%',1.7)
                if species!=2: mouth+=path(f'M {cx+span*0.25} {cy} l 4 -1 -2 4 Z','#fff9e9','%INK%',0.65)
            elif state=='happy':
                mouth=path(f'M {cx-span} {cy-4} Q {cx} {cy} {cx+span} {cy-4} Q {cx+span*0.7} {cy+7} {cx} {cy+7} Q {cx-span*0.7} {cy+7} {cx-span} {cy-4} Z','#643d54','%INK%',1.5)
                mouth+=path(f'M {cx-span*0.6} {cy+4} Q {cx} {cy} {cx+span*0.6} {cy+4} Q {cx} {cy+8} {cx-span*0.6} {cy+4} Z','#eaa395')
                if species==2: mouth+=path(f'M {cx-4} {cy-3} l 6 1 -0.6 5 -4.8 0 Z','#fff9e9')
            elif state=='hurt': mouth=path(f'M {cx-span*0.7} {cy+1} Q {cx} {cy-5} {cx+span*0.7} {cy+1}','none','%INK%',1.85)
            elif state=='sleep': mouth=path(f'M {cx-4} {cy} Q {cx} {cy+2} {cx+4} {cy-1}','none','%INK%',1.5)
            else: mouth=ellipse(cx,cy+1,4,4.6,'#643d54','%INK%',1.3)+ellipse(cx,cy+3,2.4,1.4,'#eaa395')
            parts[f'mouth_{species}_{state}']=f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">{mouth}</svg>'
