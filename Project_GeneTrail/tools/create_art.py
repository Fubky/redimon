"""Original vector assets, reproducible without external packages."""
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1] / 'assets'
ROOT.mkdir(exist_ok=True)
palettes = {
    'forest': ('#bac99c', '#648168', '#95ab78'),
    'mountain': ('#ccc8ac', '#87918b', '#b8bca1'),
    'island': ('#e8d7ac', '#79b1b8', '#a7d3cf'),
    'volcano': ('#b69a87', '#655f69', '#e99b70'),
    'cave': ('#aeacc0', '#6d718b', '#a7d3c9'),
    'town': ('#d4d5ac', '#759078', '#adc08f'),
}
for name, (floor, wall, detail) in palettes.items():
    r = random.Random(name)
    s = ['<svg xmlns="http://www.w3.org/2000/svg" width="240" height="40" viewBox="0 0 240 40">']
    for tile in range(6):
        s += [f'<g transform="translate({tile*40},0)"><rect width="40" height="40" fill="{floor if tile<3 else wall}"/>']
        for _ in range(20):
            x,y = r.randrange(2,38),r.randrange(2,38)
            s += [f'<path d="M{x} {y}l{r.randrange(1,4)} 1" stroke="#fff8dc" opacity=".13" stroke-width="1"/>']
        if tile < 3:
            if name != 'town':
                s += ['<path d="M1 39H39V1" fill="none" stroke="#354b43" opacity=".07"/>']
            if tile == 1:
                s += [f'<path d="M8 31l-2-5m2 5 3-7m17-12-2-4m2 4 3-6" stroke="{wall}" opacity=".45" fill="none" stroke-linecap="round"/>']
            if tile == 2:
                s += ['<ellipse cx="26" cy="28" rx="4" ry="2" fill="#f2e6c2" opacity=".65"/><circle cx="11" cy="13" r="1.4" fill="#f7e9ad"/>']
        elif name in ('forest','town'):
            s += [f'<path d="M18 37V21" stroke="#5e6550" stroke-width="5"/><path d="M5 24Q0 13 11 12Q8 1 21 4Q32 0 34 14Q44 24 32 29L13 30Z" fill="{detail}" stroke="#4c6857" stroke-width="2"/><path d="M10 16Q15 9 23 10M22 21l7-4" stroke="#c5d4a0" opacity=".6" fill="none" stroke-width="2"/>']
        elif name == 'island':
            s += ['<path d="M2 13Q10 9 18 13T38 13M-5 30Q5 24 15 29T42 29" fill="none" stroke="#d1e3d2" opacity=".65" stroke-width="2"/>']
        elif name == 'volcano':
            s += [f'<path d="M-2 31L12 22 16 4 21-2M12 22l18 7 12-3" stroke="{detail}" fill="none" stroke-width="3"/><path d="M3 9L9 5 14 12" fill="#807781"/>']
        elif name == 'cave':
            s += [f'<path d="M11 31L8 15 17 5 24 19 18 33Z" fill="{detail}" stroke="#52667a" stroke-width="2"/><path d="M17 6L17 30M18 33L27 15 34 25 29 34Z" stroke="#d9e2df" fill="#98b7c6" stroke-width="1"/>']
        else:
            s += ['<path d="M3 31L9 11 22 5 35 18 37 32Z" fill="#a9ada0" stroke="#68776f" stroke-width="2"/><path d="M9 11L20 18 22 5M20 18L35 18M20 18L16 32" stroke="#79887d" fill="none" stroke-width="2"/>']
        s += ['</g>']
    s += ['</svg>']
    (ROOT/f'tiles_{name}.svg').write_text(''.join(s),encoding='utf-8')

buildings = {
    'home': ('#c78362','#eed7af','<path d="M48 113V81q16-16 32 0v32" fill="#718675" stroke="#465c50" stroke-width="3"/><path d="M57 51q7-12 14 0-7 12-14 0" fill="#e7c477"/>'),
    'shop': ('#769b88','#f0ddb4','<path d="M25 71H103L96 90H31Z" fill="#e5af68" stroke="#465c50" stroke-width="3"/><path d="M41 72L43 88M60 72v17M79 72l-1 17" stroke="#fff1cc" stroke-width="9"/><rect x="40" y="95" width="48" height="18" rx="2" fill="#8b7660"/>'),
    'nursery': ('#b09aa9','#eed9bc','<path d="M40 104Q28 84 45 77Q44 60 59 69Q71 48 82 72Q103 74 93 94Q92 111 70 108Z" fill="#93ae81" stroke="#4b6555" stroke-width="3"/><path d="M64 108V82m0 17 15-14m-15 9-15-9" stroke="#4b6555" fill="none" stroke-width="3"/>'),
    'storage': ('#8e9ca7','#e2d5b6','<path d="M39 81H88V113H39Z" fill="#b79265" stroke="#596457" stroke-width="3"/><path d="M39 83l49 29m0-29-49 29M64 82v29" stroke="#7d745b" stroke-width="3"/>'),
}
for name,(roof,body,detail) in buildings.items():
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="160" height="160" viewBox="-16 -10 160 160">
    <ellipse cx="65" cy="127" rx="64" ry="12" fill="#5a6652" opacity=".15"/>
    <path d="M14 58L63 26 113 57 110 121Q64 132 18 121Z" fill="{body}" stroke="#4b5d4d" stroke-width="4" stroke-linejoin="round"/>
    <path d="M2 62L61 9 124 61 109 69 62 33 17 69Z" fill="{roof}" stroke="#4b5d4d" stroke-width="4" stroke-linejoin="round"/>
    <path d="M17 54L61 18 108 54M29 52L61 26" fill="none" stroke="#fff0d2" opacity=".25" stroke-width="2"/>
    <path d="M26 117H102M26 121H99" stroke="#b8ae8b" stroke-width="2" opacity=".7"/>{detail}
    <path d="M6 117q-12-12-3-16 8 0 8 16m108 4q-4-19 6-20 8 4-2 20" fill="#8ca37a" stroke="#5e765d" stroke-width="2"/>
    </svg>'''
    (ROOT/f'{name}.svg').write_text(svg,encoding='utf-8')
print('Created six tile atlases and four town buildings.')
from create_battle_art import generate
generate(ROOT)
