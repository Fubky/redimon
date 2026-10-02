"""Soft organic anatomy and separate, inherited botanical growth organs.

No complete animal illustrations: all paths use the existing joint-centred part rig.
"""


def refine_botanical_parts(add, path, ellipse, parts):
    bodies=[
        {'lean':'M 19 42 Q 20 24 37 24 Q 52 29 66 25 Q 81 27 80 46 Q 81 66 61 68 Q 47 64 33 70 Q 16 67 16 53 Z',
         'round':'M 17 38 Q 23 19 46 21 Q 72 18 81 39 Q 90 60 70 73 Q 44 84 23 70 Q 10 59 17 38 Z',
         'heavy':'M 13 38 Q 21 18 46 22 Q 70 16 84 37 Q 94 62 72 75 Q 47 83 25 74 Q 8 66 13 38 Z',
         'long':'M 9 43 Q 14 27 30 30 Q 47 34 66 27 Q 82 24 88 43 Q 92 62 72 69 L 32 74 Q 8 72 8 54 Z'},
        {'lean':'M 14 41 Q 19 28 37 31 Q 48 35 56 24 Q 70 17 79 31 Q 91 49 76 66 Q 67 73 54 65 L 30 66 Q 10 64 14 41 Z',
         'round':'M 15 38 Q 29 23 48 29 Q 61 17 76 27 Q 88 37 86 56 Q 84 75 61 77 Q 35 77 19 66 Q 9 54 15 38 Z',
         'heavy':'M 12 38 Q 25 22 48 28 Q 59 14 75 23 Q 91 32 91 55 Q 91 76 68 81 Q 48 77 25 73 Q 8 64 12 38 Z',
         'long':'M 8 42 Q 18 28 37 31 Q 51 34 60 24 Q 74 19 84 34 Q 94 49 84 65 Q 76 75 59 66 L 30 70 Q 7 69 8 42 Z'},
        {'lean':'M 32 25 Q 45 11 61 24 Q 67 33 67 45 Q 86 67 65 82 Q 43 91 23 79 Q 9 66 22 45 Z',
         'round':'M 31 23 Q 48 11 64 26 Q 73 36 74 48 Q 94 70 72 85 Q 48 94 24 81 Q 8 68 18 47 Z',
         'heavy':'M 29 23 Q 49 10 67 26 Q 77 37 77 49 Q 95 72 72 87 Q 45 95 20 82 Q 6 69 17 47 Z',
         'long':'M 32 18 Q 48 5 63 23 Q 68 38 68 49 Q 85 72 61 85 Q 34 91 20 74 Q 10 60 24 40 Z'},
        {'lean':'M 10 44 Q 20 29 40 35 Q 53 39 64 32 Q 83 30 90 47 Q 92 60 75 65 Q 57 70 43 63 Q 25 71 13 60 Q 8 53 10 44 Z',
         'round':'M 10 40 Q 23 26 44 32 Q 61 25 79 35 Q 92 42 88 58 Q 84 72 58 73 Q 31 75 17 65 Q 8 56 10 40 Z',
         'heavy':'M 8 41 Q 23 24 45 31 Q 63 23 82 36 Q 95 48 89 64 Q 78 79 53 77 Q 29 78 14 65 Q 6 57 8 41 Z',
         'long':'M 6 45 Q 16 33 36 37 Q 50 40 65 32 Q 85 33 92 46 Q 96 61 76 68 Q 58 74 43 65 Q 25 74 10 63 Z'},
        {'coil':'M 18 43 Q 11 27 32 24 Q 53 20 67 32 Q 88 31 90 53 Q 95 77 62 85 Q 31 93 13 76 Q 1 61 18 43 Z'}]
    for species, forms in enumerate(bodies):
        for kind, shape in forms.items():
            detail=''
            if species==2: detail=path('M 29 55 Q 46 47 51 62 Q 55 75 41 79','none','%SHADOW%',1)
            elif species==4:
                detail=path('M 19 59 Q 30 44 55 44 Q 80 42 78 57 Q 73 69 48 69 Q 25 67 23 76','none','%INK%',1.25)
                detail+=path('M 28 61 Q 45 69 66 61 Q 49 80 24 73 Z','%CREAM%')
                detail+=path('M 35 66 L 36 74 M 45 67 L 46 73 M 56 65 L 56 71','none','%SHADOW%',0.7)
            add(f'body_{species}_{kind}',shape,detail,True)

    # Rounded paws, not boots or jagged armour. Forelimb roots remain unoutlined.
    for species in (0,1):
        fore='M 41 39 Q 54 35 57 47 L 54 68 Q 69 75 62 82 Q 51 87 38 81 Q 35 77 40 69 Z'
        hind='M 36 39 Q 55 31 62 47 Q 65 59 53 64 L 52 70 Q 68 75 61 83 Q 49 87 35 82 Q 31 77 39 67 Q 29 54 36 39 Z'
        if species==1:
            fore='M 43 37 Q 56 34 58 48 L 54 68 L 54 75 Q 69 77 62 84 Q 51 88 39 83 Q 36 79 42 71 Z'
            hind='M 34 40 Q 53 30 63 46 Q 66 57 53 64 L 56 71 Q 68 78 61 85 Q 47 89 35 83 Q 34 78 43 71 Q 29 57 34 40 Z'
        for kind,shape in [('fore',fore),('hind',hind)]:
            detail=path('M 36 73 Q 51 68 67 75 L 70 90 L 29 90 Z','%CREAM%')
            detail+=path('M 47 79 L 47 82 M 54 79 L 54 82','none','%SHADOW%',0.7)
            outline=shape if kind=='hind' else ('M 57 49 L 54 68 Q 69 75 62 82 Q 51 87 38 81 Q 35 77 40 69 L 42 52' if species==0 else 'M 58 49 L 54 68 L 54 75 Q 69 77 62 84 Q 51 88 39 83 Q 36 79 42 71 L 43 53')
            add(f'limb_{species}_{kind}',shape,detail,outline=outline)

    # Broad leaves provide large, readable colour masses; one vein per leaf is enough.
    leaf_forms=[
        'M 48 69 Q 21 70 13 42 Q 30 36 42 51 Q 24 28 36 12 Q 56 20 55 43 Q 64 18 84 22 Q 87 49 62 58 Q 78 57 88 70 Q 63 81 48 69 Z',
        'M 47 73 Q 18 77 7 52 Q 27 41 43 57 Q 15 40 22 19 Q 47 18 52 47 Q 52 13 75 9 Q 92 36 64 58 Q 89 43 93 62 Q 79 81 47 73 Z',
        'M 49 75 Q 15 79 7 55 Q 18 43 36 51 Q 10 31 24 12 Q 49 19 49 45 Q 50 15 71 9 Q 90 28 72 49 Q 88 40 94 53 Q 91 77 67 75 Z',
        'M 15 51 Q 13 23 36 17 Q 52 32 47 50 Q 51 19 75 15 Q 92 37 75 58 Q 91 60 91 73 Q 68 85 48 69 Q 28 85 9 71 Q 7 59 15 51 Z']
    for species in range(5):
        for coat in range(1,4):
            shape=leaf_forms[(coat+species)%4]
            add(f'coat_{species}_{coat}',shape,'',material='leaf')

    # Canopies use different organ placement and silhouettes for each species.
    canopies=[
        ['M 22 59 Q 15 39 24 25 Q 46 29 49 50 Q 59 30 76 30 Q 80 51 61 60 Q 40 70 22 59 Z',
         'M 17 60 Q 5 43 14 26 Q 31 24 45 45 Q 37 19 54 12 Q 72 28 62 48 Q 79 28 91 42 Q 88 65 63 68 Q 32 78 17 60 Z',
         'M 11 62 Q 1 41 14 27 Q 29 27 37 38 Q 29 15 48 10 Q 65 20 61 41 Q 70 16 87 24 Q 95 47 75 58 Q 90 59 90 70 Q 61 80 39 74 Q 17 77 11 62 Z',
         'M 14 60 Q 10 35 30 18 Q 47 25 46 50 Q 49 19 71 14 Q 89 40 72 59 Q 57 75 34 70 Q 20 72 14 60 Z'],
        ['M 24 28 Q 39 18 50 34 Q 61 18 74 29 Q 80 51 62 64 Q 64 79 50 87 Q 34 75 33 61 Q 17 47 24 28 Z',
         'M 22 24 Q 37 15 48 28 Q 59 16 72 26 Q 81 44 66 59 Q 64 74 52 85 Q 36 76 33 61 Q 14 48 22 24 Z',
         'M 17 24 Q 31 12 46 26 Q 60 9 78 25 Q 89 43 73 60 Q 80 70 66 77 Q 64 87 52 90 Q 37 80 33 68 Q 11 55 17 24 Z',
         'M 22 27 Q 42 13 49 39 Q 60 14 76 24 Q 85 48 64 63 Q 69 80 51 88 Q 34 77 35 62 Q 15 48 22 27 Z'],
        ['M 14 59 Q 17 35 37 28 Q 46 14 60 22 Q 81 26 84 50 Q 72 62 57 60 Q 39 74 14 59 Z',
         'M 9 57 Q 13 34 33 28 Q 45 9 60 18 Q 85 17 88 46 Q 94 56 80 65 Q 60 57 49 68 Q 25 72 9 57 Z',
         'M 6 53 Q 8 33 27 27 Q 26 12 43 12 Q 55 2 65 15 Q 83 14 89 33 Q 97 50 86 63 Q 70 57 56 69 Q 41 64 25 73 Q 11 67 6 53 Z',
         'M 9 54 Q 16 27 43 20 Q 69 10 87 34 Q 99 57 79 69 Q 65 57 51 69 Q 28 78 9 54 Z'],
        ['M 18 64 Q 9 35 25 19 Q 45 25 46 50 Q 58 26 77 30 Q 89 50 70 64 Q 43 76 18 64 Z',
         'M 12 64 Q 1 36 18 22 Q 41 23 44 48 Q 34 17 53 8 Q 70 21 63 46 Q 78 20 91 36 Q 94 63 67 71 Q 32 81 12 64 Z',
         'M 12 63 Q 2 45 12 29 Q 31 24 40 47 Q 27 13 48 6 Q 70 16 58 46 Q 77 14 91 30 Q 95 55 77 61 Q 88 65 88 76 Q 61 82 43 72 Q 27 81 12 63 Z',
         'M 12 63 Q 0 37 22 22 Q 43 31 44 49 Q 38 16 59 8 Q 80 31 65 52 Q 79 31 94 40 Q 96 70 70 78 Q 44 80 12 63 Z'],
        ['M 44 70 Q 17 61 11 35 Q 30 27 42 42 Q 57 24 77 30 Q 83 56 60 68 Z',
         'M 45 72 Q 17 71 8 44 Q 13 29 28 34 Q 21 16 34 10 Q 53 23 51 43 Q 63 16 80 20 Q 92 43 70 62 Q 65 77 45 72 Z',
         'M 47 73 Q 18 78 5 52 Q 3 30 22 31 Q 13 8 31 7 Q 50 15 49 41 Q 58 10 78 14 Q 94 28 78 48 Q 96 53 78 70 Q 65 82 47 73 Z',
         'M 46 73 Q 12 69 7 41 Q 27 24 41 45 Q 29 19 48 9 Q 67 24 59 44 Q 76 24 91 34 Q 95 62 73 75 Z']]
    for species,forms in enumerate(canopies):
        for coat,shape in enumerate(forms):
            detail=''
            if species in (0,3): detail=path('M 26 32 Q 37 50 48 63 M 73 39 Q 61 57 48 63','none','%SHADOW%',0.9)
            elif species==1: detail=path('M 32 32 Q 43 58 51 76 M 67 33 Q 57 59 51 76','none','%SHADOW%',0.9)
            elif species==2:
                detail=path('M 19 51 Q 40 30 64 32 M 36 47 L 45 33 M 55 41 L 62 32','none','%SHADOW%',0.8)
                detail+=ellipse(28,45,2.4,1.5,'%SEED%')+ellipse(53,29,2.1,1.4,'%SEED%')
            else: detail=path('M 21 39 Q 29 57 47 66 M 76 34 Q 64 55 53 64','none','%SHADOW%',0.9)
            add(f'growth_{species}_{coat}',shape,detail,material='leaf')

    # Natural collars replace hard-edged bibs and jewelry; existing gene ids stay stable.
    add('bib_cat','M 22 34 Q 39 23 48 46 Q 59 23 75 34 Q 78 55 56 65 Q 51 77 46 73 Q 31 68 24 55 Z',path('M 30 37 Q 39 52 48 62 M 67 37 Q 58 54 51 61','none','%SHADOW%',0.8),material='leaf')
    add('mane_dog','M 20 29 Q 37 13 49 39 Q 62 12 79 30 Q 82 55 65 64 Q 62 84 48 88 Q 35 81 32 64 Q 15 49 20 29 Z',path('M 29 34 Q 37 58 48 77 M 70 34 Q 62 62 50 77','none','%SHADOW%',0.9),material='leaf')
    add('crest_lizard',canopies[3][1],'',material='leaf')
    add('fin_snake','M 50 61 Q 16 67 9 36 Q 15 25 30 29 Q 50 36 57 54 Z',path('M 19 35 L 46 54','none','%SHADOW%',0.9),material='leaf')
    add('crown_snake','M 48 63 Q 28 59 26 42 Q 25 31 40 39 Q 32 18 48 9 Q 63 22 57 39 Q 75 29 74 45 Q 67 61 48 63 Z',path('M 48 20 L 49 48','none','%SHADOW%',0.8),material='bloom')
    flower='M 46 42 Q 26 35 30 20 Q 34 8 47 22 Q 57 4 66 17 Q 72 29 58 41 Q 81 35 84 50 Q 82 64 61 57 Q 75 75 61 84 Q 48 88 45 66 Q 34 85 22 73 Q 13 60 35 53 Q 15 51 18 39 Q 22 29 46 42 Z'
    detail=ellipse(49,49,7,6,'%SEED%','%INK%',0.8)+path('M 46 47 L 46 50 M 51 46 L 52 49 M 49 52 L 52 52','none','%SHADOW%',0.7)
    add('charm_bud',flower,detail,material='bloom')
    add('charm_gem','M 47 66 Q 23 57 26 36 Q 28 22 43 30 Q 44 8 59 12 Q 75 20 60 38 Q 81 28 87 43 Q 87 61 62 61 Q 61 78 47 80 Z',ellipse(54,47,6,5,'%SEED%','%INK%',0.8),material='bloom')
    add('charm_ribbon','M 43 66 Q 24 57 24 39 Q 35 24 50 39 Q 63 22 77 33 Q 80 56 60 68 Q 51 80 43 66 Z',path('M 33 40 Q 49 59 69 39 Q 69 61 52 68 Q 34 62 33 40 Z','%SEED%')+path('M 51 41 L 52 67','none','%SHADOW%',0.8),material='bloom')

    # Ear variants still differ in silhouette, with rounded tips and fewer hard corners.
    ear_shapes=[
        [('M 33 52 L 28 19 Q 27 9 34 12 Q 52 21 63 44 L 59 55 Z','M 38 44 L 34 23 Q 47 29 54 43 Z'),
         ('M 32 51 Q 23 22 32 19 Q 48 19 61 34 Q 72 48 58 49 L 46 47 L 40 54 Z','M 34 27 Q 49 27 57 41 L 45 45 Z'),
         ('M 34 52 L 38 10 Q 42 2 47 10 Q 59 26 63 46 L 57 56 Z','M 43 42 L 44 18 Q 52 26 55 42 Z')],
        [('M 32 52 L 27 21 Q 24 10 33 12 Q 49 22 63 43 Q 65 52 57 57 Z','M 38 43 L 33 24 Q 47 31 54 43 Z'),
         ('M 36 38 Q 19 36 20 54 Q 20 77 36 81 Q 50 78 56 52 L 58 40 Z','M 33 46 Q 26 59 36 70 Q 45 62 47 46 Z'),
         ('M 34 51 L 34 12 Q 35 5 41 11 Q 58 30 64 46 L 59 56 Z','M 41 40 L 40 21 Q 49 29 55 43 Z')]]
    for species,forms in enumerate(ear_shapes):
        for variant,(shape,inner) in enumerate(forms): add(f'ear_{species}_{variant}',shape,path(inner,'%INNER%'))

    # Soft brush tails and fleshy leaf fins retain four inherited silhouettes each.
    tails={1:[
        'M 66 56 Q 36 71 16 59 Q 4 51 6 36 Q 17 27 27 40 Q 40 48 66 41 Z',
        'M 66 56 Q 41 77 18 67 Q 2 59 5 40 Q 12 19 39 18 Q 48 22 36 31 Q 23 43 66 40 Z',
        'M 66 55 Q 38 63 16 45 Q 4 36 7 22 Q 16 11 29 20 Q 38 28 33 35 Q 43 43 66 41 Z',
        'M 66 55 Q 36 72 15 53 Q 4 40 15 22 Q 32 4 47 16 Q 61 27 48 39 Q 39 45 39 34 Q 44 24 34 24 Q 17 26 25 42 Q 39 52 66 40 Z'],
        3:[
        'M 66 58 Q 46 62 33 52 Q 18 64 7 55 Q 5 48 18 44 Q 4 41 7 33 Q 21 24 36 39 Q 49 46 66 40 Z',
        'M 66 58 Q 48 59 35 50 Q 26 66 12 60 Q 0 55 12 44 Q 0 38 6 31 Q 11 28 19 32 Q 14 17 24 19 Q 39 23 41 39 L 67 40 Z',
        'M 66 57 Q 31 56 14 31 Q 3 23 8 16 Q 17 11 23 20 Q 28 36 45 40 L 66 40 Z',
        'M 66 57 Q 23 67 12 43 Q 6 21 28 19 Q 49 21 45 38 Q 43 47 34 46 Q 27 43 32 38 Q 37 31 29 30 Q 19 31 25 42 Q 32 52 66 40 Z']}
    for species,forms in tails.items():
        for variant,shape in enumerate(forms):
            detail=path('M 9 39 Q 28 44 42 49','none','%LIGHT%',1.1)
            if species==1: detail+=path('M 0 10 L 24 12 Q 19 29 31 40 Q 17 42 18 57 L 1 60 Z','%CREAM%')
            add(f'tail_{species}_{variant}',shape,detail,species==1,material='leaf' if species==3 else 'skin')
