"""Eight seamless ground variations and sixteen neighbor-aware cliff edges per biome."""
from pathlib import Path
from random import Random

PALETTES = {
    'forest': ('#8b9e62','#687c4c','#233e35','#527957','#a5b781'),
    'mountain': ('#bd9a61','#8f7248','#293f50','#638096','#b8c4b7'),
    'island': ('#d9be83','#b8985c','#244f63','#38899b','#b7e2d3'),
    'volcano': ('#bd703d','#894933','#292e41','#56627b','#a7a5a6'),
    'cave': ('#8a8299','#686578','#202f49','#546b90','#9bbdcb'),
}

def generate(root):
    for name,(ground,earth,dark,rock,light) in PALETTES.items():
        parts=['<svg xmlns="http://www.w3.org/2000/svg" width="320" height="120" viewBox="0 0 320 120">']
        for tile in range(24):
            rng=Random(2907+tile+sum(map(ord,name)))
            parts += [f'<g transform="translate({tile%8*40},{tile//8*40})">']
            if tile<8:
                parts += [f'<rect width="40" height="40" fill="{ground}"/>']
                for _ in range(11):
                    x,y=rng.randrange(0,36),rng.randrange(0,36)
                    w,h=rng.randrange(3,12),rng.randrange(2,6)
                    parts += [f'<path d="M{x} {y}l{w*.7:.1f} -1 3 {h*.5:.1f} -2 {h} -{w} -1Z" fill="{earth}" opacity="{rng.uniform(.12,.29):.2f}"/>']
                for _ in range(75):
                    x,y=rng.randrange(40),rng.randrange(40)
                    parts += [f'<rect x="{x}" y="{y}" width="{rng.choice([.7,1,1.6])}" height=".7" fill="{rng.choice([light,earth,"#f4d8a1"])}" opacity=".25"/>']
                if tile in (2,5):
                    parts += [f'<path d="M9 25l4-3 7 1 2 3-8 1Z" fill="{earth}" opacity=".45"/><path d="M10 23l4-3 6 2-2 2Z" fill="{light}" opacity=".42"/>']
                if name=='forest' and tile in (1,3,7):
                    parts += ['<path d="M26 30l-4-5 4 2 2-8 2 8 6-4-5 7Z" fill="#567348" opacity=".8"/>']
                if name=='volcano' and tile==6:
                    parts += ['<path d="M7 17l6-4 5 3 5-1" fill="none" stroke="#edb364" stroke-width=".8" opacity=".55"/>']
            else:
                mask=tile-8 # N=1, E=2, S=4, W=8: walkable neighbors.
                parts += [f'<rect width="40" height="40" fill="{dark}"/>']
                if mask:
                    left=6 if mask&8 else 0
                    right=34 if mask&2 else 40
                    top=5 if mask&1 else 0
                    bottom=29 if mask&4 else 40
                    parts += [f'<path d="M{left} {top+3}L{left+6} {top}H{right-5}L{right} {top+4}V{bottom-2}L{right-4} {bottom+5}H{left+4}L{left} {bottom}Z" fill="{rock}"/>']
                    for _ in range(8):
                        x=rng.randrange(left+1,max(left+2,right-7))
                        y=rng.randrange(top+1,max(top+2,bottom-6))
                        parts += [f'<path d="M{x} {y+5}l2-5 6-1 3 4-2 5-7 1Z" fill="{light}" opacity=".24"/><path d="M{x+2} {y}l6-1 3 4" fill="none" stroke="{light}" opacity=".34" stroke-width=".9"/>']
                    edges=[]
                    if mask&1: edges.append(f'M{left} {top+3}l6-3H{right-5}l5 4')
                    if mask&2: edges.append(f'M{right} {top+4}v{bottom-top-7}l-4 6')
                    if mask&8: edges.append(f'M{left+1} {top+5}v{bottom-top-6}l4 5')
                    if mask&4:
                        parts += [f'<path d="M{left+3} {bottom}H{right-4}l-3 7H{left+5}Z" fill="{dark}"/><path d="M{left+4} {bottom}H{right-5}" stroke="{light}" stroke-width="2" opacity=".8"/>']
                        for x in range(left+5,right-4,7):
                            parts += [f'<path d="M{x} {bottom+1}v5" stroke="{rock}" stroke-width="3"/>']
                    for edge in edges:
                        parts += [f'<path d="{edge}" fill="none" stroke="{light}" stroke-width="1.7" opacity=".78"/>']
                    if name=='forest':
                        parts += [f'<path d="M{left+3} {top+8}q8-10 13-3t10 0l-3 7-15 1Z" fill="#69894e" opacity=".75"/>']
                    if name=='cave' and mask%3==0:
                        parts += ['<path d="M15 21l-2-10 5-4 4 10-4 6Z" fill="#8dd3cc" stroke="#bce1d7" stroke-width="1"/>']
                    if name=='island':
                        parts += [f'<path d="M{left} {bottom+3}q8-3 15 0t18 0" fill="none" stroke="#dbecda" stroke-width="1.8" opacity=".7"/>']
            parts += ['</g>']
        parts += ['</svg>']
        (root/f'field_{name}.svg').write_text(''.join(parts),encoding='utf-8')

if __name__=='__main__':
    generate(Path(__file__).resolve().parents[1]/'assets')
    print('Five neighbor-aware battlefield atlases created.')
