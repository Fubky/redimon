"""Silhouette and proportion pass. Anatomy is designed before decorative layers."""


def refine_forms(add, path, ellipse, parts):
    # The upper contour flows into the head; the underside stays broad and simple.
    bodies=[
        ['M 20 35 C 25 22 43 21 61 26 C 76 26 83 36 81 50 C 82 64 70 74 52 75 C 31 76 16 67 15 53 Q 13 43 20 35 Z',
         'M 16 34 C 23 18 50 18 70 28 C 85 33 88 55 79 67 C 67 84 32 85 18 71 C 6 58 7 44 16 34 Z',
         'M 13 33 C 24 16 49 20 70 25 C 88 27 93 56 81 73 C 67 87 29 85 15 70 C 5 58 5 45 13 33 Z',
         'M 12 37 C 21 27 39 31 59 25 C 77 20 90 35 87 53 C 85 70 67 72 44 73 C 22 80 8 67 8 51 Q 7 43 12 37 Z'],
        ['M 17 35 Q 30 28 45 30 C 53 30 55 20 66 21 C 85 22 90 42 82 61 C 77 77 58 80 43 71 Q 19 72 13 55 Q 10 44 17 35 Z',
         'M 14 34 Q 30 24 44 29 Q 52 18 67 20 C 87 22 94 47 83 67 C 74 84 50 84 31 75 C 11 73 4 48 14 34 Z',
         'M 11 32 Q 26 22 43 27 Q 52 15 67 17 C 89 21 97 48 85 70 C 75 88 49 86 27 77 C 8 70 2 47 11 32 Z',
         'M 10 38 Q 23 28 42 31 Q 52 33 59 23 Q 74 15 85 29 C 97 46 89 71 73 74 Q 62 77 53 69 Q 20 78 10 64 Q 2 52 10 38 Z'],
        ['M 31 27 C 35 18 56 16 64 31 Q 68 45 72 52 C 91 73 67 88 45 86 C 21 86 11 72 19 54 Q 24 43 31 27 Z',
         'M 29 27 C 34 16 55 16 63 29 Q 73 42 76 56 C 92 81 68 91 45 89 C 19 90 5 75 16 52 Q 23 37 29 27 Z',
         'M 27 25 C 36 13 57 17 66 30 Q 77 43 78 56 C 96 82 69 93 42 90 C 15 91 4 72 15 51 Q 20 38 27 25 Z',
         'M 33 18 Q 49 6 62 22 Q 70 38 70 53 C 90 80 64 88 45 85 C 20 85 11 71 22 48 Z'],
        ['M 15 38 Q 28 23 46 30 Q 63 23 78 36 C 93 46 88 66 74 72 Q 54 81 32 72 C 13 74 4 52 15 38 Z',
         'M 13 34 Q 28 20 47 28 Q 66 21 81 37 C 96 52 88 74 72 79 Q 48 87 27 76 Q 5 68 8 49 Z',
         'M 9 37 Q 25 17 47 25 Q 69 18 85 37 C 99 55 90 77 69 82 Q 44 88 21 74 Q 2 64 9 37 Z',
         'M 7 41 Q 23 30 44 34 Q 62 23 82 36 C 95 43 96 61 79 70 Q 58 81 40 70 Q 21 79 9 63 Q 2 55 7 41 Z'],
        ['M 19 40 C 13 26 32 21 46 26 Q 55 28 64 34 C 84 30 93 42 91 57 C 94 78 71 89 46 88 C 17 89 1 75 7 56 Q 10 46 19 40 Z']]
    for species,forms in enumerate(bodies):
        for kind,shape in zip(['coil'] if species==4 else ['lean','round','heavy','long'],forms):
            detail=''
            if species==4:
                detail=path('M 17 60 C 23 47 51 42 68 48 Q 89 57 65 67 C 47 75 27 66 21 76','none','%INK%',1.5)
                detail+=path('M 23 74 Q 44 79 66 68 Q 51 86 26 79 Z','%CREAM%')
            add(f'body_{species}_{kind}',shape,detail,True)

    # Limbs are tapered from a broad, unoutlined shoulder into a rounded foot.
    limbs=[
        ['M 33 30 Q 47 23 60 36 Q 63 46 54 61 L 57 68 Q 74 73 65 84 Q 52 91 37 84 Q 31 80 38 69 L 35 57 Q 24 44 33 30 Z',
         'M 34 34 Q 55 26 64 45 Q 65 58 51 65 L 54 72 Q 73 77 63 86 Q 48 92 30 84 Q 26 79 37 70 Q 21 50 34 34 Z'],
        ['M 33 27 Q 50 22 60 38 Q 59 52 53 65 L 56 72 Q 75 78 64 86 Q 51 91 36 84 Q 32 81 39 71 L 37 59 Q 26 42 33 27 Z',
         'M 31 33 Q 51 22 65 40 Q 71 54 55 64 L 53 72 Q 72 78 64 86 Q 49 91 30 85 Q 26 79 39 69 Q 20 51 31 33 Z'],
        ['M 37 32 Q 52 28 60 44 Q 65 59 54 65 Q 44 69 36 61 Q 29 55 35 49 Z',
         'M 33 37 Q 55 27 64 48 Q 67 61 52 69 Q 79 71 79 80 Q 74 93 45 88 Q 25 86 31 76 L 38 68 Q 21 55 33 37 Z'],
        ['M 34 31 Q 51 23 59 39 Q 63 50 55 59 L 59 65 Q 72 62 73 68 Q 71 73 64 74 Q 82 74 81 80 Q 80 86 64 83 Q 74 91 67 92 Q 57 91 48 80 L 37 69 Q 25 50 34 31 Z',
         'M 31 35 Q 51 22 64 40 Q 74 55 59 66 L 57 71 Q 76 67 76 75 Q 71 80 63 79 Q 79 82 74 88 Q 68 90 55 84 Q 63 94 54 94 Q 43 87 36 73 Q 19 54 31 35 Z']]
    for species,forms in enumerate(limbs):
        for index,shape in enumerate(forms):
            foot=path('M 27 73 Q 47 65 73 76 L 80 95 L 24 95 Z','%CREAM%') if species<3 else ''
            foot+=path('M 47 82 L 47 85 M 56 82 L 56 85','none','%SHADOW%',1.0) if species<2 else ''
            # Masked proximal edges blend into the torso even while the leg rotates.
            outline=shape if index else ['M 58 47 L 54 61 L 57 68 Q 74 73 65 84 Q 52 91 37 84 Q 31 80 38 69 L 35 57',
                'M 58 49 L 53 65 L 56 72 Q 75 78 64 86 Q 51 91 36 84 Q 32 81 39 71 L 37 59',
                'M 60 44 Q 65 59 54 65 Q 44 69 36 61 Q 29 55 35 49',
                'M 61 48 Q 59 54 55 59 L 59 65 Q 72 62 73 68 Q 71 73 64 74 Q 82 74 81 80 Q 80 86 64 83 Q 74 91 67 92 Q 57 91 48 80 L 37 69'][species]
            add(f'limb_{species}_{"fore" if index==0 else "hind"}',shape,foot,outline=outline)

    # Ears use one outer shape, an inset crescent and an open root behind the skull.
    ears=[
        [('M 27 54 L 22 13 Q 24 5 31 11 Q 56 24 66 45 L 59 57 Z','M 34 43 L 29 19 Q 46 28 55 43 Q 43 38 34 43 Z'),
         ('M 28 53 Q 16 23 29 16 Q 47 14 65 39 Q 73 54 56 53 L 45 44 L 36 55 Z','M 29 25 Q 41 18 56 41 L 43 41 L 37 49 Z'),
         ('M 29 54 Q 27 26 38 7 Q 42 2 48 10 Q 64 26 66 47 L 57 58 Z','M 40 43 Q 37 28 44 15 Q 54 25 58 44 Z')],
        [('M 28 53 Q 13 27 19 11 Q 23 5 31 13 Q 53 26 65 44 L 59 55 Z','M 34 42 Q 24 25 26 19 Q 44 29 54 43 Z'),
         ('M 47 39 Q 20 18 15 36 Q 8 60 23 81 Q 32 88 42 77 Q 47 60 60 48 Z','M 37 41 Q 23 29 22 44 Q 17 60 29 73 Q 36 76 36 61 Z'),
         ('M 28 53 Q 18 21 29 5 Q 33 2 38 9 Q 58 27 65 48 L 59 56 Z','M 35 42 L 32 17 Q 47 29 55 44 Z')],
        [('M 29 54 C 7 51 6 22 24 13 C 44 3 66 14 66 33 Q 64 50 51 57 Z','M 30 45 C 14 41 17 23 29 22 Q 52 16 55 33 Q 54 44 44 49 Z'),
         ('M 28 54 Q 6 47 13 25 Q 21 10 40 17 Q 62 14 65 35 Q 65 49 51 57 Z','M 29 44 Q 18 37 24 29 Q 38 19 50 30 Q 57 44 44 49 Z'),
         ('M 28 54 C 5 44 8 6 27 5 C 49 4 71 37 53 56 Z','M 31 44 Q 14 23 28 16 Q 45 21 49 44 Z')],
        [('M 32 54 Q 13 42 17 22 Q 40 25 57 47 L 54 57 Z','M 27 34 L 48 49 L 31 45 Z'),
         ('M 30 54 Q 10 42 11 26 Q 23 21 31 33 Q 39 17 48 25 Q 59 39 56 51 Z','M 22 34 L 43 49 L 38 31 Z'),
         ('M 30 53 Q 12 35 22 12 Q 43 16 57 44 L 53 57 Z','M 29 25 L 47 48 L 33 42 Z')],
        [('M 31 55 Q 10 46 13 26 Q 39 27 55 48 L 52 57 Z','M 24 35 Q 35 39 47 50 L 30 46 Z'),
         ('M 32 54 Q 7 41 13 23 Q 37 18 58 46 L 52 57 Z','M 23 32 Q 41 37 49 49 L 31 43 Z'),
         ('M 32 54 Q 8 36 21 9 Q 40 24 57 46 L 52 57 Z','M 27 25 Q 37 42 48 50 L 31 43 Z')]]
    for species,forms in enumerate(ears):
        for index,(shape,inside) in enumerate(forms):
            add(f'ear_{species}_{index}',shape,path(inside,'%INNER%' if species<3 else '%ACCENT%'))

    # A single S gesture, without narrow disconnected rings around the throat.
    neck='M 26 81 C 8 63 18 46 32 33 Q 42 23 31 8 L 54 8 Q 65 24 52 40 C 35 56 31 65 55 73 L 67 73 L 65 88 Q 45 93 26 81 Z'
    detail=path('M 41 8 Q 55 25 39 40 C 21 59 28 74 51 81 L 60 81','none','%CREAM%',11)
    detail+=path('M 39 29 L 50 31 M 31 43 L 42 46 M 27 59 L 38 60 M 34 73 L 42 69','none','%SHADOW%',0.9)
    add('neck_snake',neck,detail,outline='M 45 89 Q 20 86 17 67 C 11 48 47 30 31 8 M 54 8 Q 65 24 52 40 C 35 56 31 65 55 73 L 67 73')

    tails=[
        'M 66 56 C 38 72 14 63 10 43 Q 4 25 19 19 Q 29 17 31 25 Q 18 32 25 43 Q 35 58 65 40 Z',
        'M 66 57 C 42 77 12 69 7 46 Q 3 23 23 15 Q 33 13 38 23 L 29 29 Q 15 43 34 48 Q 46 53 66 39 Z',
        'M 66 56 Q 30 56 16 35 Q 3 14 19 6 Q 27 3 31 11 Q 22 21 34 35 Q 48 43 66 39 Z',
        'M 66 56 Q 25 72 10 47 C 0 28 15 9 34 13 Q 56 17 49 38 Q 43 52 31 42 Q 26 35 36 34 Q 42 25 32 24 Q 17 25 22 40 Q 31 55 66 39 Z']
    for variant,shape in enumerate(tails):
        tip=path('M 1 5 L 34 4 Q 27 16 34 25 Q 21 34 27 44 L 9 50 L 0 33 Z','%CREAM%')
        add(f'tail_0_{variant}',shape,tip,True)

    from creature_portraits import create_portraits
    create_portraits(add,path,ellipse,parts)
