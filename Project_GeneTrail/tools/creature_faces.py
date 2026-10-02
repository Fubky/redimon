"""Original modular faces: clean eye silhouettes, species muzzles and readable emotion.

Heads contain skin and noses only. Eyes and mouths stay independent animated parts.
"""
STATES = ('calm', 'focus', 'happy', 'hurt', 'sleep', 'surprise')


def create_faces(add, path, ellipse, parts):
    heads = [
        ['M 22 31 Q 26 19 43 20 Q 64 19 71 37 Q 74 43 79 47 Q 82 51 73 55 Q 69 68 49 70 Q 29 70 20 58 Q 14 49 22 40 Z',
         'M 21 37 Q 23 22 44 24 Q 65 23 73 42 Q 86 49 77 57 Q 66 76 43 74 Q 23 73 17 60 Q 12 49 21 37 Z',
         'M 20 29 Q 29 18 42 18 Q 57 17 65 29 L 71 41 Q 80 44 81 49 L 74 55 Q 67 64 48 71 Q 30 68 20 57 Q 16 52 24 44 Z'],
        ['M 18 33 Q 24 19 40 21 Q 56 21 62 40 L 80 43 Q 92 44 89 54 Q 85 65 65 63 Q 54 76 36 70 Q 16 67 17 56 Q 11 46 18 33 Z',
         'M 18 37 Q 20 23 39 24 Q 58 24 62 44 L 82 46 Q 94 49 85 60 Q 75 66 65 64 Q 56 75 36 72 L 26 68 L 19 60 L 22 52 Z',
         'M 16 30 Q 30 17 41 20 Q 50 20 56 30 L 65 40 L 86 44 Q 94 48 88 56 Q 80 63 63 63 Q 56 72 50 74 Q 31 72 21 62 Q 14 54 14 49 Z'],
        ['M 21 31 Q 29 20 43 22 Q 59 21 65 39 L 72 45 Q 86 48 80 57 L 68 62 Q 53 75 34 70 Q 14 68 14 50 Q 13 39 21 31 Z',
         'M 19 37 Q 22 22 43 25 Q 60 25 65 41 L 76 47 Q 87 53 76 62 L 65 64 Q 47 81 26 69 Q 10 64 12 47 Z',
         'M 23 28 Q 39 16 54 26 Q 63 31 66 43 L 78 48 L 83 55 L 72 63 L 62 66 L 42 74 L 23 65 Q 11 56 16 42 Z'],
        ['M 16 32 Q 24 19 40 24 Q 50 25 54 32 Q 61 28 69 37 L 80 38 Q 94 40 93 48 Q 93 59 72 63 Q 47 69 25 57 L 14 48 L 12 39 Z',
         'M 14 37 Q 21 22 40 27 Q 49 28 54 33 Q 63 28 70 40 L 81 42 Q 96 44 89 57 Q 75 68 51 65 L 28 62 Q 12 57 12 45 Z',
         'M 13 32 L 28 21 Q 43 23 51 32 L 60 38 L 86 37 L 94 46 L 86 57 L 64 64 L 40 61 L 19 54 L 10 42 Z'],
        ['M 20 33 Q 27 19 41 20 Q 54 20 64 34 L 83 37 Q 93 39 93 46 L 84 56 Q 62 66 38 59 L 20 51 L 16 42 Z',
         'M 19 38 Q 23 23 41 26 Q 56 26 65 38 L 82 41 Q 95 45 85 56 Q 70 65 50 64 L 32 59 Q 15 53 16 45 Z',
         'M 15 34 L 35 18 Q 52 21 61 30 L 69 36 L 87 38 L 94 46 L 82 57 Q 60 63 39 58 L 18 51 L 12 43 Z']]

    for species, forms in enumerate(heads):
        for face, shape in enumerate(forms):
            # Broad calm areas keep the eyes readable even with inherited markings.
            if species == 0:
                detail = path('M 29 49 Q 41 45 52 53 Q 62 48 71 53 L 70 61 Q 54 71 38 62 Z', '%CREAM%')
                detail += path('M 54 52 Q 58 50 62 52 Q 62 55 58 56 Q 54 55 54 52 Z', '%INK%')
                detail += path('M 55 52 L 59 52', 'none', '%INNER%', 1.1)
                detail += ellipse(29,55,4.4,2.1,'%INNER%')
                detail += path('M 22 53 L 28 55 M 22 58 L 28 58', 'none', '%SHADOW%', 0.9)
                detail += path('M 27 32 Q 31 26 39 26', 'none', '%LIGHT%', 1.7)
            elif species == 1:
                detail = path('M 39 49 Q 48 43 59 47 L 79 47 L 88 49 L 83 59 Q 69 65 58 58 L 48 66 L 36 61 Z', '%CREAM%')
                detail += path('M 80 43 Q 88 42 89 47 Q 86 52 81 50 L 78 47 Z', '%INK%')
                detail += ellipse(82,45,2.1,0.85,'%LIGHT%')
                detail += path('M 27 28 Q 32 23 39 25 L 44 30 L 35 32 Z', '%LIGHT%')
                detail += path('M 24 53 L 31 57 L 26 59', 'none', '%SHADOW%', 0.8)
            elif species == 2:
                detail = path('M 19 49 Q 34 47 48 54 Q 62 46 75 51 L 77 59 Q 59 72 40 68 Q 22 65 19 56 Z', '%CREAM%')
                detail += ellipse(76,49,3.4,2.6,'%INNER%','%INK%',0.9)
                detail += ellipse(75,48,1.1,0.65,'#fff4df')
                detail += ellipse(24,54,5,2.7,'%INNER%')
                detail += path('M 17 54 L 23 56 M 17 59 L 24 59', 'none','%SHADOW%',0.85)
                detail += path('M 23 35 Q 26 29 32 28','none','%LIGHT%',1.6)
            elif species == 3:
                detail = path('M 22 49 Q 43 55 61 53 L 90 46 Q 88 60 67 63 Q 40 65 22 54 Z', '%CREAM%')
                detail += ellipse(83,43,1.3,0.8,'%INK%')
                detail += path('M 23 29 L 30 24 L 36 28 L 30 32 Z','%ACCENT%')
                detail += path('M 19 46 L 24 49 M 24 52 L 29 54','none','%SHADOW%',0.8)
            else:
                detail = path('M 21 48 Q 42 51 58 51 Q 78 49 89 44 L 83 55 Q 65 63 41 57 Z','%CREAM%')
                detail += ellipse(85,42,1.1,0.7,'%INK%')
                detail += path('M 32 27 Q 34 20 41 22 Q 36 24 39 30 Q 35 31 32 27 Z','%CREAM%')
                detail += path('M 20 41 L 24 38 L 28 42 L 24 44 Z','%LIGHT%')
            add(f'head_{species}_{face}',shape,detail,True)

    # A larger near eye and smaller far eye establish a clear three-quarter view.
    positions = [
        [(37,42,8.8,11.4),(63,41,6.2,9.5)],
        [(38,40,8.5,9.2),(58,39,5.4,7.6)],
        [(36,42,9.1,11.6),(60,41,5.9,9.0)],
        [(37,39,9.0,8.6),(61,40,5.3,6.7)],
        [(41,38,8.8,8.7),(64,39,5.0,6.5)]]
    for species, eyes in enumerate(positions):
        for face in range(3):
            for state in STATES:
                painting = ''; defs = ''
                for side,(cx,cy,rx,ry) in enumerate(eyes):
                    ry *= [0.84,0.92,0.78][face]
                    rx *= [0.79,0.87,0.76][face]
                    # Half-lids, happy arcs and squeezed eyes are drawn, not squashed irises.
                    if state in ('happy','hurt','sleep'):
                        if state=='happy':
                            line=f'M {cx-rx} {cy+2} Q {cx} {cy-ry*0.8} {cx+rx} {cy+1}'
                        elif state=='hurt':
                            sign=1 if side==0 else -1
                            line=f'M {cx-sign*rx} {cy-ry*0.6} L {cx+sign*rx*0.4} {cy} L {cx-sign*rx} {cy+ry*0.65}'
                        else: line=f'M {cx-rx} {cy-1} Q {cx} {cy+ry*0.7} {cx+rx} {cy-1}'
                        painting+=path(line,'none','%INK%',1.8)
                        if state=='happy': painting+=ellipse(cx,cy+ry*0.7,rx*0.57,1.6,'#e89989')
                        if state=='hurt': painting+=path(f'M {cx-rx*0.7} {cy-ry-2} l {rx*1.2} -1','none','%INK%',1.3)
                        continue
                    if state=='surprise':
                        ry*=1.12
                        shape=f'M {cx-rx} {cy} C {cx-rx} {cy-ry*1.4} {cx+rx} {cy-ry*1.4} {cx+rx} {cy} C {cx+rx} {cy+ry*1.3} {cx-rx} {cy+ry*1.3} {cx-rx} {cy} Z'
                    else:
                        tilt = (3.0 if side==0 else -3.0) if state=='focus' else (1.2 if species in (1,3,4) else -0.4)
                        top = cy-ry*(0.64 if state=='focus' else 0.98)
                        shape=f'M {cx-rx} {cy-ry*0.28-tilt} Q {cx-rx*0.25} {top-2} {cx+rx} {cy-ry*0.43+tilt} Q {cx+rx*1.12} {cy+ry*0.65} {cx+rx*0.13} {cy+ry} Q {cx-rx*0.9} {cy+ry*1.02} {cx-rx} {cy-ry*0.28-tilt} Z'
                    defs+=f'<clipPath id="eye{side}">{path(shape,"white")}</clipPath>'
                    painting+=path(shape,'#fff9ea','%INK%',1.25)
                    iris_x=cx+rx*0.21; iris_y=cy+ry*0.08
                    iris_rx=rx*(0.57 if state=='surprise' else 0.77)
                    painting+=f'<g clip-path="url(#eye{side})">'
                    painting+=ellipse(iris_x,iris_y,iris_rx,ry*1.02,'%EYE%')
                    pupil_width=iris_rx*(0.38 if species==4 else 0.49)
                    painting+=ellipse(iris_x+0.2,iris_y-ry*0.1,pupil_width,ry*0.75,'%INK%')
                    painting+=ellipse(iris_x-iris_rx*0.29,iris_y-ry*0.43,iris_rx*0.30,ry*0.21,'#fffdf4')
                    painting+='</g>'
                    # Upper lid carries most of the weight; no heavy pale ring around the eye.
                    painting+=path(shape.split(' Q ',2)[0]+' Q '+shape.split(' Q ',2)[1] if state!='surprise' else f'M {cx-rx} {cy-2} Q {cx} {cy-ry*1.65} {cx+rx} {cy-2}','none','%INK%',1.65)
                    if state=='focus' and not (species in (3,4) and side==1):
                        painting+=path(f'M {cx-rx*0.7} {cy-ry-3} L {cx+rx*0.7} {cy-ry-1 if side==0 else cy-ry-5}','none','%INK%',1.55)
                    elif state=='surprise' and not (species in (3,4) and side==1):
                        painting+=path(f'M {cx-rx*0.6} {cy-ry-4} Q {cx} {cy-ry-7} {cx+rx*0.6} {cy-ry-4}','none','%INK%',1.25)
                parts[f'eyes_{species}_{face}_{state}']=f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><defs>{defs}</defs>{painting}</svg>'

        # Mouth placement follows each species' snout; no fixed smile is painted on heads.
        cx,cy,span=[(58,60,8.5),(71,56,10),(63,60,8),(69,56,15),(70,54,14)][species]
        for state in STATES:
            ink='%INK%'; mouth=''
            if state=='calm':
                if species==0:
                    mouth=path('M 58 56 L 58 59 Q 54 64 50 60 M 58 59 Q 62 64 66 59','none',ink,1.25)
                else: mouth=path(f'M {cx-span} {cy-1} Q {cx} {cy+5} {cx+span} {cy-2}','none',ink,1.35)
                if species==2: mouth+=path('M 59 61 L 59 65 Q 62 67 65 64 L 65 61 Z','#fffdf0',ink,0.65)
            elif state=='focus':
                mouth=path(f'M {cx-span*0.8} {cy+1} Q {cx} {cy+2} {cx+span} {cy-2}','none',ink,1.55)
                if species in (0,1,3,4): mouth+=path(f'M {cx+span*0.35} {cy+1} l 3 0 -1.8 3 Z','#fffdf0',ink,0.65)
            elif state=='happy':
                depth=[5.0,5.1,5.5,4.5,4.2][species]
                mouth=path(f'M {cx-span*0.75} {cy-2} Q {cx} {cy+1} {cx+span*0.8} {cy-2} Q {cx+span*0.65} {cy+depth} {cx} {cy+depth} Q {cx-span*0.65} {cy+depth} {cx-span*0.75} {cy-2} Z','#4c3046',ink,1.2)
                mouth+=path(f'M {cx-span*0.35} {cy+depth*0.7} Q {cx} {cy+depth*0.2} {cx+span*0.38} {cy+depth*0.7} Q {cx} {cy+depth*1.08} {cx-span*0.35} {cy+depth*0.7} Z','#ee968f')
                if species==2: mouth+=path(f'M {cx-3} {cy} l 5 0 -0.8 4 -4 0 Z','#fffdf0')
            elif state=='hurt':
                mouth=path(f'M {cx-span*0.6} {cy+4} Q {cx} {cy-3} {cx+span*0.7} {cy+3}','none',ink,1.6)
            elif state=='sleep':
                mouth=path(f'M {cx-4} {cy+1} Q {cx} {cy+3} {cx+4} {cy}','none',ink,1.25)
            else:
                mouth=ellipse(cx,cy+2,3.7 if species<3 else 4.8,4.3,'#4c3046',ink,1.2)
                mouth+=ellipse(cx,cy+4,2,1.2,'#ee968f')
            parts[f'mouth_{species}_{state}']=f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">{mouth}</svg>'
