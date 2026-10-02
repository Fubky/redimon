"""Species art direction in joint-centred SVG paths. No complete character artwork."""

def refine_species_parts(add, path, ellipse, parts):
    # Replace shared silhouettes with species anatomy. Genes still choose their variants.
    for key in list(parts):
        if key.startswith(('body_', 'limb_', 'eyes_', 'coat_')) or key in ('crest','fin'):
            del parts[key]

    bodies = [
      {
       'lean':'M 20 39 Q 20 23 34 22 Q 46 29 56 26 Q 75 16 77 37 Q 80 55 66 62 Q 51 58 35 66 Q 15 70 16 53 Z',
       'round':'M 21 31 Q 36 18 57 23 Q 77 19 78 42 Q 84 66 58 73 Q 30 80 17 61 Q 10 47 21 31 Z',
       'heavy':'M 17 34 Q 23 18 39 23 Q 51 30 62 19 Q 81 14 84 39 Q 90 63 62 67 L 30 74 Q 12 64 15 48 Z',
       'long':'M 11 41 Q 13 28 29 29 Q 44 34 62 26 Q 78 18 85 37 Q 88 56 72 62 L 31 70 Q 9 70 8 53 Z'},
      {
       'lean':'M 14 39 Q 18 28 36 31 L 51 32 Q 56 13 71 19 L 79 26 L 86 26 L 81 35 Q 86 51 72 62 L 61 66 L 52 60 L 29 63 Q 10 62 14 39 Z',
       'round':'M 17 34 Q 32 24 50 28 Q 62 10 75 20 L 81 29 L 87 28 L 82 39 Q 89 67 62 72 Q 33 75 18 63 L 11 49 Z',
       'heavy':'M 13 35 Q 30 26 47 28 Q 56 9 72 15 L 84 26 L 89 25 L 84 37 Q 94 60 74 73 L 61 78 L 51 66 L 24 67 Q 8 58 13 35 Z',
       'long':'M 8 38 Q 21 27 41 30 L 55 30 Q 63 12 77 23 L 87 29 L 83 37 Q 91 58 77 67 L 66 69 L 56 59 L 24 65 Q 6 64 8 38 Z'},
      {
       'lean':'M 35 18 Q 52 9 64 25 L 67 43 Q 84 66 63 79 Q 36 89 20 73 Q 9 57 24 43 Z',
       'round':'M 35 17 Q 54 8 66 27 L 70 42 Q 91 63 70 81 Q 42 93 19 77 Q 5 60 21 41 Z',
       'heavy':'M 32 17 Q 55 5 70 27 L 73 41 Q 94 63 74 83 Q 42 94 16 76 Q 3 59 19 39 Z',
       'long':'M 34 12 Q 52 2 65 21 L 67 46 Q 81 68 60 83 Q 32 90 19 73 Q 12 58 26 39 Z'},
      {
       'lean':'M 13 44 L 20 33 Q 37 30 48 35 L 63 28 Q 80 29 84 44 L 80 57 L 62 63 L 41 57 L 24 63 L 12 55 Z',
       'round':'M 12 41 Q 25 28 44 32 L 62 28 Q 85 30 87 49 L 76 65 L 54 70 L 29 66 Q 10 61 12 41 Z',
       'heavy':'M 9 41 L 22 28 L 44 32 L 63 24 L 83 35 L 91 53 L 78 69 L 58 73 L 39 67 L 18 68 L 8 56 Z',
       'long':'M 7 45 L 20 34 L 40 39 L 59 31 Q 82 28 90 44 L 85 58 L 65 64 L 43 59 L 20 66 L 8 57 Z'},
      {'coil':'M 17 43 Q 13 27 33 24 Q 53 18 67 31 Q 88 31 88 54 Q 92 77 61 84 Q 34 91 14 77 Q 1 61 17 43 Z'}
    ]
    for species, forms in enumerate(bodies):
        for kind,shape in forms.items():
            detail=''
            if species==0:
                detail=path('M 24 31 Q 30 27 36 29 M 23 37 L 27 34 M 64 29 L 69 31','none','%LIGHT%',1.7)
                detail+=path('M 22 57 Q 26 62 32 61','none','%SHADOW%',1)
            elif species==1:
                detail=path('M 62 24 L 58 36 L 64 33 L 61 47 L 70 42 L 65 60 L 76 51','%LIGHT%')
                detail+=path('M 18 41 Q 25 35 39 37 M 23 44 L 31 41','none','%LIGHT%',1.4)
            elif species==2:
                detail=path('M 28 51 Q 44 40 52 57 Q 59 74 42 78','none','%SHADOW%',1.3)
                detail+=path('M 27 53 Q 23 63 30 68 M 29 48 L 34 45 L 39 46','none','%LIGHT%',1.5)
            elif species==3:
                for x,y in [(27,41),(39,46),(55,41),(68,45),(49,57)]:
                    detail+=path(f'M {x-5} {y} l 5 -4 6 3 -5 5 Z','%SHADOW%')
                    detail+=path(f'M {x-4} {y-1} l 4 -2 4 2','none','%LIGHT%',0.9)
            else:
                detail=path('M 17 59 Q 28 41 54 42 Q 82 40 77 58 Q 72 70 47 68 Q 24 66 24 77 Q 54 87 77 72','none','%INK%',1.6)
                detail+=path('M 23 48 Q 48 31 69 44 M 16 72 Q 33 86 62 78','none','%LIGHT%',2.4)
                detail+=path('M 31 60 Q 45 66 65 61 Q 48 78 25 73 Z','%CREAM%')
                for x in range(30,66,7): detail+=path(f'M {x} 65 l 1 8','none','%SHADOW%',0.8)
            add(f'body_{species}_{kind}',shape,detail,True)

    from creature_faces import create_faces
    create_faces(add, path, ellipse, parts)

    # Keep the accepted ear variants, but restore unambiguous mammal/reptile outlines.
    mouse_ears=[
     ('M 36 54 Q 12 47 12 26 Q 12 8 31 8 Q 51 7 62 29 L 63 49 Z','M 34 45 Q 22 38 22 25 Q 25 15 37 21 Q 49 29 51 42 Z'),
     ('M 34 53 Q 15 46 17 29 Q 21 16 34 20 Q 50 22 60 44 L 57 53 Z','M 34 44 Q 26 36 29 29 Q 39 25 50 44 Z'),
     ('M 34 54 Q 9 29 19 10 Q 35 -1 51 20 L 61 48 Z','M 36 44 Q 23 25 29 15 Q 40 16 50 40 Z')]
    for variant,(shape,inner) in enumerate(mouse_ears): add(f'ear_2_{variant}',shape,path(inner,'%INNER%')+path('M 23 27 Q 23 16 33 17','none','%LIGHT%',1))
    for variant,(shape,inner) in enumerate([
     ('M 39 53 Q 21 49 7 18 Q 29 15 42 34 L 53 16 L 61 52 Z','M 15 24 L 41 44 M 39 32 L 45 45'),
     ('M 37 53 Q 13 48 12 25 Q 40 18 58 45 L 61 54 Z','M 21 31 L 48 47 M 29 28 L 43 42'),
     ('M 37 54 L 25 38 L 19 7 L 36 17 L 48 36 L 61 52 Z','M 28 18 L 45 47')]):
        add(f'ear_3_{variant}',shape,path(inner,'none','%ACCENT%',1.6))
    for variant,(shape,inner) in enumerate([
     ('M 42 52 Q 21 53 6 29 L 13 15 Q 37 16 58 48 Z','M 15 24 L 47 47 M 12 31 L 42 49'),
     ('M 38 53 Q 8 51 10 26 Q 26 18 48 35 L 61 52 Z','M 19 31 L 48 48 M 17 39 L 39 49'),
     ('M 37 54 Q 20 31 24 9 Q 30 3 36 5 Q 31 26 56 47 L 59 54 Z','M 29 18 Q 32 39 46 47')]):
        add(f'ear_4_{variant}',shape,path(inner,'none','%ACCENT%',1.3))

    tails=[
     ['M 65 54 Q 30 69 18 53 Q 4 34 17 23 Q 26 20 28 27 Q 16 36 28 47 Q 38 55 65 42 Z',
      'M 66 54 Q 37 69 20 56 L 13 57 L 15 51 L 8 45 L 14 42 Q 6 26 21 18 Q 28 16 31 23 Q 20 33 28 43 Q 41 52 65 41 Z',
      'M 65 55 Q 35 54 20 34 Q 8 17 18 6 Q 24 3 27 10 Q 21 21 32 34 Q 43 44 65 40 Z',
      'M 66 54 Q 28 65 14 46 Q 6 30 20 20 Q 37 10 46 28 Q 51 43 38 46 Q 29 45 30 37 Q 39 35 34 29 Q 27 23 22 34 Q 19 50 65 41 Z'],
     ['M 67 56 L 48 65 Q 23 72 11 57 L 4 57 L 10 50 L 3 45 L 9 41 L 6 32 L 22 37 Q 42 46 64 42 Z',
      'M 65 55 Q 39 78 17 67 L 8 70 L 13 59 L 4 59 L 8 48 L 2 42 L 11 37 Q 19 18 44 19 L 36 28 L 47 29 L 37 38 Q 50 43 66 40 Z',
      'M 66 55 Q 36 59 16 43 L 7 46 L 12 36 L 4 32 L 11 28 L 8 17 Q 29 10 37 26 L 31 29 Q 43 40 66 42 Z',
      'M 66 54 Q 35 72 14 51 L 5 54 L 12 42 L 6 34 L 17 32 Q 16 10 39 11 Q 61 14 53 34 L 43 38 L 43 27 Q 40 19 30 25 Q 21 43 65 41 Z'],
     ['M 65 51 Q 35 64 18 53 Q 4 44 12 36 Q 17 35 17 40 Q 12 48 32 51 Q 45 52 65 44 Z',
      'M 65 51 Q 39 67 19 56 Q 2 48 8 33 Q 13 23 26 29 Q 28 32 24 34 Q 11 30 14 41 Q 19 57 65 44 Z',
      'M 65 51 Q 25 59 11 35 Q 6 21 14 17 Q 18 17 17 21 Q 12 34 33 43 L 65 44 Z',
      'M 65 51 Q 31 64 14 48 Q 4 38 14 27 Q 26 18 35 30 Q 42 42 31 45 Q 25 44 29 40 Q 34 38 29 33 Q 24 27 19 33 Q 9 49 65 44 Z'],
     ['M 66 58 Q 46 62 33 51 Q 20 62 7 55 L 18 43 L 6 34 Q 24 26 37 40 Q 47 46 66 40 Z',
      'M 66 58 Q 48 59 34 50 L 22 62 L 4 54 L 15 44 L 3 35 L 17 29 L 17 20 L 37 28 L 41 39 L 67 40 Z',
      'M 66 57 Q 32 55 16 31 L 5 27 L 9 14 L 23 17 L 28 31 Q 44 43 66 40 Z',
      'M 66 57 Q 21 65 12 42 Q 8 19 31 19 Q 51 24 43 41 L 32 46 L 29 39 Q 36 32 29 30 Q 21 30 25 40 Q 31 52 66 40 Z'],
     ['M 65 54 Q 31 70 11 57 Q 2 48 8 38 Q 18 56 37 50 L 65 42 Z',
      'M 66 55 Q 39 68 19 59 L 4 45 L 11 30 L 18 40 L 29 35 L 34 46 L 66 41 Z',
      'M 65 53 Q 27 55 12 30 Q 7 16 13 7 Q 14 27 34 36 L 65 41 Z',
      'M 65 55 Q 26 65 10 45 Q 2 25 22 17 Q 47 11 49 31 Q 50 44 35 44 Q 24 41 30 33 Q 40 38 39 30 Q 34 18 22 29 Q 9 44 38 49 L 65 41 Z']]
    for species,variants in enumerate(tails):
        for variant,shape in enumerate(variants):
            if species==2:
                detail='<g opacity="0.5">'+path(shape,'%INNER%')+'</g>'
                detail+=path('M 17 45 Q 24 52 35 54','none','%CREAM%',1)
            elif species==3:
                detail=path('M 13 41 Q 34 42 43 47 M 18 32 L 29 41 L 21 50 M 27 27 L 36 41','none','%LIGHT%',1.4)
            elif species==4:
                detail=path('M 13 45 Q 31 59 53 48','none','%CREAM%',2)
            else:
                detail=path('M 3 10 L 24 8 Q 20 25 29 37 L 21 42 L 27 47 L 19 54 L 6 58 Z','%CREAM%')
                detail+=path('M 31 52 Q 45 58 57 49','none','%LIGHT%',1.5)
            add(f'tail_{species}_{variant}',shape,detail,species!=2)

    # Fore and hind limbs no longer share boot-shaped geometry.
    limbs=[
     ['M 42 39 Q 54 37 55 48 L 52 70 Q 66 74 63 81 Q 51 85 39 81 Q 34 76 40 70 Z',
      'M 38 39 Q 56 32 61 48 Q 63 57 53 63 L 50 71 Q 66 74 62 81 L 38 81 Q 32 77 38 69 L 36 57 Z'],
     ['M 43 37 Q 57 36 57 49 L 52 65 L 52 74 Q 69 76 63 83 L 40 83 L 37 78 L 42 68 Z',
      'M 34 40 Q 53 29 64 47 Q 66 57 52 63 L 57 69 L 52 75 Q 68 78 61 84 L 38 84 Q 31 80 41 73 L 42 69 L 30 57 Z'],
     ['M 42 40 Q 55 36 59 47 Q 63 54 56 60 L 51 65 L 40 64 Q 34 59 42 54 Z',
      'M 35 41 Q 50 32 60 44 Q 65 56 54 64 L 60 73 Q 84 76 79 83 Q 63 91 37 85 Q 29 78 39 68 Q 23 58 35 41 Z'],
     ['M 40 40 Q 53 35 59 45 L 53 57 L 65 63 L 69 72 L 85 74 L 85 79 L 76 79 L 83 84 L 78 87 L 67 80 L 60 84 L 56 80 L 62 75 L 53 68 L 40 62 Q 32 53 40 40 Z',
      'M 37 41 Q 56 29 64 45 Q 69 55 58 62 L 51 66 L 62 73 L 81 76 L 80 81 L 69 81 L 77 87 L 70 89 L 58 83 L 48 86 L 43 81 L 48 75 L 36 66 L 29 55 Z']]
    for species,forms in enumerate(limbs):
        for index,shape in enumerate(forms):
            if species<2:
                detail=path('M 36 73 Q 49 68 67 73 L 68 88 L 31 88 Z','%CREAM%')
                detail+=path('M 46 76 L 46 80 M 54 76 L 54 80','none','%SHADOW%',0.75)
                detail+=path('M 43 48 L 43 61','none','%LIGHT%',1.4)
            elif species==2:
                detail=path('M 30 74 Q 58 70 84 77 L 84 90 L 27 90 Z','%INNER%') if index else ellipse(47,60,7,4,'%INNER%')
                detail+=path('M 61 79 L 62 85 M 69 78 L 71 84','none','%SHADOW%',0.7) if index else ''
            else:
                detail=path('M 44 43 l 5 -4 6 3 -5 4 Z M 48 51 l 5 -3 4 4 -4 3 Z','%SHADOW%')
                detail+=path('M 72 77 L 82 77 M 70 82 L 77 86','none','%CREAM%',1.7)
            # Leave the shoulder open: the top fill merges into the torso behind it.
            outline=None
            if index==0:
                outline=[
                    'M 55 51 L 52 70 Q 66 74 63 81 Q 51 85 39 81 Q 34 76 40 70 L 41 53',
                    'M 56 52 L 52 65 L 52 74 Q 69 76 63 83 L 40 83 L 37 78 L 42 68 L 42 54',
                    'M 59 47 Q 63 54 56 60 L 51 65 L 40 64 Q 34 59 42 54',
                    'M 59 45 L 53 57 L 65 63 L 69 72 L 85 74 L 85 79 L 76 79 L 83 84 L 78 87 L 67 80 L 60 84 L 56 80 L 62 75 L 53 68 L 40 62 Q 32 53 40 44'][species]
            add(f'limb_{species}_{"fore" if index==0 else "hind"}',shape,detail,outline=outline)

    # Species-specific coats preserve the four accepted coat options.
    coat_shapes=[
      ['M 20 41 L 22 25 L 34 30 L 42 19 L 49 30 L 63 20 L 64 39 L 77 44 L 66 56 L 59 73 L 49 64 L 32 72 L 28 58 L 16 55 Z',
       'M 17 34 Q 18 22 31 23 Q 40 12 50 24 Q 66 13 72 29 Q 85 34 77 46 Q 88 57 71 62 Q 65 80 48 69 Q 28 81 25 61 Q 9 56 17 44 Z',
       'M 16 40 L 28 27 L 40 35 L 52 22 L 67 30 L 78 47 L 64 65 L 48 70 L 29 64 Z'],
      ['M 29 40 L 33 15 L 47 25 L 60 9 L 68 26 L 81 23 L 76 43 L 90 47 L 78 61 L 70 85 L 56 72 L 40 79 L 37 62 L 22 57 Z',
       'M 24 37 Q 21 19 38 21 Q 42 4 58 19 Q 76 5 82 28 Q 96 35 80 48 Q 94 65 76 72 Q 73 91 56 80 Q 34 91 33 68 Q 12 61 24 46 Z',
       'M 24 39 L 38 22 L 48 30 L 58 12 L 71 28 L 83 30 L 77 50 L 87 57 L 66 79 L 43 74 L 30 58 Z'],
      ['M 18 37 L 22 21 L 36 24 L 44 12 L 57 22 L 70 17 L 76 35 L 86 45 L 75 58 L 71 80 L 51 86 L 31 81 L 15 64 Z',
       'M 17 36 Q 7 20 26 20 Q 33 6 46 17 Q 60 3 69 21 Q 85 16 84 38 Q 97 48 82 63 Q 88 82 64 85 Q 40 96 22 80 Q 6 79 11 58 Q 1 47 17 36 Z',
       'M 13 40 L 24 23 L 45 20 L 67 22 L 83 43 L 79 69 L 63 84 L 35 87 L 17 73 Z'],
      ['M 11 40 L 17 18 L 33 30 L 41 8 L 54 28 L 65 11 L 72 32 L 85 25 L 80 48 L 66 66 L 45 67 L 21 61 Z',
       'M 10 35 Q 15 18 28 24 Q 36 7 49 23 Q 62 9 71 29 Q 90 21 86 42 L 78 64 L 60 77 L 35 71 L 14 60 Z',
       'M 6 40 L 16 19 L 30 29 L 42 8 L 55 29 L 69 14 L 77 33 L 88 27 L 91 50 L 76 70 L 49 76 L 22 70 L 7 55 Z'],
      ['M 9 39 L 17 23 L 33 29 L 43 17 L 57 27 L 76 22 L 89 41 L 89 64 L 69 85 L 44 90 L 17 82 L 5 60 Z',
       'M 9 34 Q 15 18 32 26 Q 42 10 58 26 Q 81 16 88 38 Q 99 61 78 80 Q 56 97 29 86 Q 1 82 4 58 Z',
       'M 8 41 L 14 22 L 34 29 L 46 17 L 60 28 L 81 24 L 91 48 L 88 69 L 68 87 L 41 90 L 17 82 L 5 64 Z']]
    for species,forms in enumerate(coat_shapes):
        for coat,shape in enumerate(forms,1):
            detail=path('M 22 39 L 34 30 L 46 38 L 59 27 L 72 41','none','%LIGHT%',1.5)
            add(f'coat_{species}_{coat}',shape,detail)
    add('mane_dog','M 30 33 L 36 23 L 48 31 L 66 26 L 63 44 L 76 42 L 67 55 L 71 63 L 60 62 L 54 82 L 43 70 L 35 76 L 35 61 L 23 63 L 29 48 L 20 43 Z',path('M 35 37 L 42 48 L 39 53 L 49 57 L 53 74 L 60 50 L 54 46 L 59 33 Z','%CREAM%'))
    add('bib_cat','M 30 40 L 38 30 L 50 38 L 66 34 L 63 48 L 70 51 L 58 61 L 54 74 L 43 63 L 33 65 L 36 53 L 26 50 Z',path('M 36 39 L 46 45 L 55 41 L 53 60 L 48 66 L 43 56 Z','%CREAM%'))
    add('crest_lizard','M 18 52 Q 3 31 12 13 Q 32 17 36 37 Q 36 9 53 6 Q 64 22 52 43 Q 72 22 88 30 Q 88 50 63 59 Z',path('M 16 24 L 35 48 M 49 17 L 43 50 M 78 37 L 51 53','none','%ACCENT%',1.5))
    add('neck_snake','M 26 78 Q 8 58 26 42 Q 38 32 31 12 L 51 10 Q 65 39 49 52 Q 33 65 55 74 L 67 73 L 64 88 L 46 90 Z',path('M 38 12 Q 53 35 35 48 Q 19 68 48 83 L 59 82','none','%CREAM%',11)+path('M 39 22 L 48 19 M 40 33 L 52 31 M 35 43 L 47 46 M 27 55 L 39 59 M 29 68 L 39 67 M 38 79 L 44 73','none','%SHADOW%',0.85),outline='M 46 90 L 26 78 Q 8 58 26 42 Q 38 32 31 12 M 51 10 Q 65 39 49 52 Q 33 65 55 74 L 67 73')
    add('fin_snake','M 47 47 L 34 28 Q 17 16 8 27 L 15 49 L 34 62 L 57 53 Z',path('M 17 28 L 44 49 M 15 39 L 40 52 M 24 51 L 40 54','none','%ACCENT%',1.2))
    add('crown_snake','M 36 53 Q 20 27 40 14 Q 35 33 55 37 Q 60 35 68 23 Q 76 49 58 57 Z',path('M 37 28 Q 41 45 62 43','none','%CREAM%',2.3))

