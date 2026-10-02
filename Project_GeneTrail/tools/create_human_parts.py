"""Original, independently articulated vector parts. No complete character image."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
PARTS={}
def part(name,content):
    PARTS[name]='<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="-64 -64 128 128"><g stroke="%INK%" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">'+content+'</g></svg>'
def path(d,fill,extra=''): return f'<path d="{d}" fill="{fill}" {extra}/>'
def ellipse(x,y,rx,ry,fill,extra=''): return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" {extra}/>'
part('cape',path('M -13 -17 Q -22 -10 -22 17 L -6 24 1 19 10 23 20 17 Q 19 -8 12 -17 Z','%CLOTH_DARK%')+path('M -12 -11 L -13 16 M 11 -10 L 12 14 M 0 -6 L 2 18','none','stroke="%CLOTH%"'))
part('knight_torso',path('M -6 -19 L 6 -19 10 -15 16 -12 13 6 16 18 4 21 0 18 -5 21 -15 17 -13 4 -16 -12 -9 -15 Z','%METAL%')+path('M -12 -11 L 0 -5 12 -11 9 6 0 11 -9 6 Z','%METAL_LIGHT%')+path('M 0 -4 L 0 10 M -10 1 L -3 3 M 3 3 L 10 1','none','stroke="%METAL_DARK%"')+path('M -12 7 L 12 7 13 12 -13 12 Z','%LEATHER%')+path('M -3 7 L 3 7 3 12 -3 12 Z','%GOLD%')+path('M -5 13 L 5 13 6 22 0 25 -6 22 Z','%CLOTH%')+path('M -3 -20 L 3 -20 5 -15 -5 -15 Z','%SKIN%'))
part('mage_torso',path('M -6 -20 L 6 -20 9 -15 14 -13 10 2 19 28 Q 0 34 -19 28 L -10 2 -14 -13 -9 -15 Z','%CLOTH%')+path('M -6 -16 L 0 -3 7 -16 3 8 10 29 4 30 -2 8 Z','%GOLD%')+path('M -11 6 Q 0 10 11 6 L 12 10 Q 0 15 -12 10 Z','%LEATHER%')+ellipse(0,10,3,3,'%GEM%')+path('M -10 16 L -13 26 M 0 18 L 0 29 M 10 16 L 14 26','none','stroke="%CLOTH_DARK%"')+path('M -5 -21 L 5 -21 5 -16 0 -8 -5 -16 Z','%SKIN%'))
part('ranger_torso',path('M -6 -20 L 6 -20 8 -16 15 -12 12 6 14 18 3 21 0 17 -4 21 -14 18 -11 4 -15 -12 -8 -16 Z','%LEATHER%')+path('M -8 -15 L 0 -7 8 -15 5 -4 0 -2 -6 -5 Z','%CLOTH%')+path('M -11 -13 L 12 7 10 11 -14 -8 Z','%CLOTH_DARK%')+path('M -12 8 L 12 8 13 12 -12 12 Z','%GOLD%')+path('M -4 9 L 2 9 2 12 -4 12 Z','%LEATHER_DARK%')+path('M 6 12 L 13 12 13 18 6 18 Z','%LEATHER_DARK%')+path('M -4 -21 L 4 -21 4 -15 0 -9 -4 -15 Z','%SKIN%'))
for job in ['knight','mage','ranger']:
    fill={'knight':'%METAL%','mage':'%CLOTH%','ranger':'%LEATHER%'}[job]
    part(job+'_arm',path('M -5 -6 Q 0 -11 6 -5 L 6 10 3 18 -4 18 -6 9 Z',fill)+path('M -5 4 L 5 4 M -4 13 L 4 13','none','stroke="%METAL_DARK%"' if job=='knight' else 'stroke="%GOLD%"')+(path('M -6 -5 Q 0 -12 7 -4 L 7 1 -6 1 Z','%METAL_LIGHT%') if job=='knight' else ''))
    part(job+'_leg',path('M -5 -5 L 5 -5 5 11 3 19 -4 19 -6 9 Z','%METAL_DARK%' if job=='knight' else '%CLOTH_DARK%')+path('M -4 7 L 4 7 3 13 -4 13 Z',fill))
    part(job+'_boot',path('M -4 -7 L 4 -7 5 1 Q 11 1 10 7 L -5 7 -6 1 Z','%METAL%' if job=='knight' else '%LEATHER_DARK%')+path('M -4 -2 L 4 -2 M -4 5 L 8 5','none','stroke="%GOLD%"' if job=='knight' else 'stroke="%LEATHER%"'))
part('hand',path('M -3 -4 L 3 -4 4 0 Q 7 2 4 4 L 2 7 Q -4 8 -5 3 Z','%SKIN%')+path('M -2 2 L -1 5 M 1 2 L 2 5','none','stroke="%SKIN_SHADE%" stroke-width="0.8"'))
part('claw_hand',path('M -3 -4 L 3 -4 5 3 4 8 1 5 -1 9 -2 5 -5 7 -5 0 Z','%SKIN%')+path('M -5 5 L -6 8 M -1 6 L -1 10 M 4 5 L 5 9','none','stroke="%IVORY%"'))
for face in range(3):
    jaw=['Q 11 11 0 14 Q -11 11 -13 3','Q 12 13 0 13 Q -12 13 -13 3','L 9 9 0 15 -9 9 -13 3'][face]
    part('head_'+str(face),ellipse(-13,0,3,4,'%SKIN%')+ellipse(13,0,3,4,'%SKIN%')+path('M -13 3 L -13 -7 Q -11 -16 0 -16 Q 12 -15 13 -7 L 13 3 '+jaw+' Z','%SKIN%')+path('M -12 1 Q -9 9 0 12 L 0 14 Q -11 11 -13 3 Z','%SKIN_SHADE%','stroke="none"')+path('M 0 1 L -1 5 2 5','none','stroke="%SKIN_SHADE%" stroke-width="1"'))
for expression in ['calm','focus','happy','hurt','sleep','surprise']:
    content=''
    for x in [-6,6]:
        if expression in ['happy','sleep','hurt']:
            content+=path(f'M {x-3} -1 Q {x} {(-4 if expression=="happy" else 2)} {x+3} -1','none','stroke-width="1.3"')
        else:
            content+=ellipse(x,0,3.7,2.7 if expression!='surprise' else 3.7,'%IVORY%')+ellipse(x+0.6,0,1.9,2.4,'%EYE%','stroke="none"')+ellipse(x+0.9,0,0.8,1.9,'%INK%','stroke="none"')+ellipse(x+0.1,-0.9,0.7,0.7,'#ffffff','stroke="none"')
        content+=path(f'M {x-3} -5 L {x+3} {(-3 if expression=="focus" and x<0 else -5)}','none','stroke="%HAIR%" stroke-width="1.5"')
    content+=path('M -3 8 Q 0 10 3 8' if expression=='happy' else ('M -2 8 Q 0 5 3 8' if expression=='hurt' else 'M -2 8 Q 0 9 2 8'),'none','stroke="#854f50" stroke-width="0.9"')
    if expression=='surprise': content+=ellipse(0,8,1.6,2.1,'#854f50','stroke="none"')
    part('face_'+expression,content)
hair=[
 'M -14 1 L -15 -9 Q -12 -22 2 -20 L 15 -13 14 3 10 -2 9 -11 3 -7 2 -13 -3 -8 -4 -13 -10 -7 -10 2 Z',
 'M -14 4 Q -20 -18 0 -21 Q 21 -19 14 7 L 11 -4 8 -12 Q 0 -6 -9 -6 L -10 6 -12 13 -17 8 Z',
 'M -13 0 Q -19 -5 -15 -10 Q -17 -18 -9 -18 Q -8 -25 0 -20 Q 8 -26 12 -18 Q 21 -17 17 -9 Q 20 -1 13 3 L 10 -8 Q 3 -6 0 -13 Q -6 -6 -10 -8 Z',
 'M -14 4 L -15 -12 Q -10 -23 1 -21 Q 15 -19 16 -10 L 14 9 12 22 5 23 9 5 9 -11 Q 1 -5 -7 -8 L -9 4 -8 19 -14 22 -17 14 Z']
for i,p in enumerate(hair): part('hair_'+str(i),path(p,'%HAIR%')+path('M -11 -13 Q -4 -19 6 -16','none','stroke="%HAIR_LIGHT%" stroke-width="1.6"'))
part('hat_knight',path('M -16 -3 L -15 -16 Q 0 -27 15 -16 L 16 -3 12 4 11 -11 Q 0 -17 -11 -11 L -12 4 Z','%METAL%')+path('M -15 -15 Q 0 -26 15 -15 L 12 -11 Q 0 -17 -12 -11 Z','%METAL_LIGHT%')+path('M -2 -24 L 2 -24 3 -12 -3 -12 Z','%GOLD%')+path('M 2 -23 Q 6 -36 14 -29 Q 9 -28 8 -19 Z','%CLOTH%'))
part('hat_mage',path('M -21 -10 Q -10 -15 10 -15 Q 23 -12 24 -8 Q 6 -2 -20 -5 Z','%CLOTH_DARK%')+path('M -12 -13 L -3 -34 Q 5 -41 15 -35 L 8 -31 10 -12 Z','%CLOTH%')+path('M -11 -16 L 9 -15 10 -11 -12 -12 Z','%GOLD%')+ellipse(1,-14,2.8,2.8,'%GEM%'))
part('hat_ranger',path('M -15 -4 Q -20 -21 -3 -27 Q 11 -28 16 -16 L 15 0 11 -8 Q 5 -20 -8 -11 L -11 3 Z','%CLOTH%')+path('M -6 -23 Q 6 -28 12 -15','none','stroke="%GOLD%"')+path('M 12 -17 Q 20 -34 25 -30 Q 24 -19 14 -12 Z','%IVORY%'))
for variant,color in enumerate(['%FEATHER%','%FEATHER%','%FEATHER%']):
    d='M -4 9 Q -3 -6 9 -18 Q 25 -35 40 -38 L 30 -19 42 -28 31 -9 38 -15 27 3 17 11 3 16 Z'
    if variant==1: d='M -4 9 Q -2 -8 15 -17 L 42 -26 34 -13 45 -18 31 -2 41 -7 28 7 12 13 3 16 Z'
    if variant==2: d='M -4 9 Q -10 -16 14 -36 Q 23 -37 19 -25 L 29 -33 24 -16 34 -21 Q 29 2 12 13 Z'
    part('bird_wing_'+str(variant),path(d,color)+''.join(path(f'M {x} {-22+x/2} Q {x-5} 2 2 11','none','stroke="%METAL_DARK%" stroke-width="0.8"') for x in [10,18,26]))
part('dragon_wing',path('M -3 10 L 1 -13 30 -33 23 -16 38 -2 Q 26 -6 23 11 Q 14 0 5 17 Z','%SCALES%')+path('M 2 -12 L 23 -16 23 10 M 2 -12 L 6 15 M 23 -16 L 30 -33','none','stroke="%GOLD%"')+path('M 2 -11 L 20 -15 21 4 Z','%SKIN_SHADE%'))
part('lizard_tail',path('M -6 -7 Q 13 -12 24 7 Q 33 24 43 10 Q 43 35 24 27 Q 10 23 5 9 L -7 8 Z','%SCALES%')+path('M 5 4 Q 21 24 31 25','none','stroke="%GOLD%" stroke-width="2"')+path('M 14 -2 L 16 -9 22 4 28 4 26 13','%METAL_DARK%'))
part('cat_tail',path('M -3 -4 Q 24 20 25 -2 Q 20 -18 27 -18 Q 36 -12 32 4 Q 28 29 -6 4 Z','%HAIR%')+path('M 24 -9 Q 29 -15 29 -11','none','stroke="%IVORY%" stroke-width="5"'))
part('dog_tail',path('M -4 -6 Q 18 10 23 -10 Q 26 -18 31 -12 Q 42 12 24 19 L 18 15 16 19 Q 6 14 -4 4 Z','%HAIR%')+path('M 25 -8 Q 34 6 26 9 L 23 6 Z','%IVORY%','stroke="none"'))
part('cat_ears',path('M -14 -6 L -20 -21 Q -8 -22 -6 -14 M 6 -14 Q 12 -23 21 -22 L 16 -5','%HAIR%')+path('M -15 -10 L -17 -17 -10 -14 M 10 -14 L 18 -18 15 -10','%SKIN_SHADE%','stroke="none"'))
part('dog_ears',path('M -11 -15 Q -26 -20 -25 -1 L -20 8 -14 -5 Z M 11 -15 Q 27 -20 25 1 L 20 8 14 -5 Z','%HAIR%')+path('M -21 -9 L -20 1 M 21 -9 L 20 1','none','stroke="%SKIN_SHADE%" stroke-width="3"'))
for i,d in enumerate([
 'M -8 -10 Q -22 -8 -23 -28 Q -20 -18 -11 -19 Z M 8 -10 Q 23 -8 24 -28 Q 20 -18 11 -19 Z',
 'M -9 -10 Q -25 -6 -24 -22 Q -23 -33 -15 -25 Q -11 -20 -18 -16 L -15 -14 Q -9 -17 -10 -23 Q -7 -17 -9 -10 Z M 9 -10 Q 25 -6 24 -22 Q 23 -33 15 -25 Q 11 -20 18 -16 L 15 -14 Q 9 -17 10 -23 Q 7 -17 9 -10 Z',
 'M -9 -11 L -12 -24 -21 -30 -20 -35 -16 -29 -15 -41 -12 -38 -11 -29 -5 -35 -5 -30 -8 -23 -5 -12 Z M 9 -11 L 12 -24 21 -30 20 -35 16 -29 15 -41 12 -38 11 -29 5 -35 5 -30 8 -23 5 -12 Z']): part('horns_'+str(i),path(d,'%IVORY%')+path('M -12 -15 L -9 -17 M 9 -17 L 12 -15','none','stroke="%GOLD%"'))
part('fish_tail',path('M -12 -14 L 12 -14 Q 17 -1 10 11 Q 8 22 23 22 L 37 15 Q 36 26 25 28 Q 27 34 18 38 Q 23 27 15 28 Q -12 27 -14 8 Z','%SCALES%')+path('M -7 -10 Q -7 14 9 20 Q -2 21 -8 10 Z','%IVORY%','opacity="0.5" stroke="none"')+path('M 21 25 L 33 20 M 21 26 L 21 33 M 4 -8 Q 8 -4 12 -8 M 1 -1 Q 5 3 9 -1 M 0 6 Q 4 10 8 6','none','stroke="%GOLD%" stroke-width="0.8"'))
part('snake_tail',path('M -12 -14 L 12 -14 Q 15 1 3 11 Q 30 3 31 17 Q 31 29 2 29 Q -32 29 -29 17 Q -28 7 -7 10 Q -18 0 -12 -14 Z','%SCALES%')+path('M -7 -12 Q -9 1 0 8 L 2 12 Q -21 10 -22 18 Q -17 26 4 23 Q 23 24 24 17','none','stroke="%IVORY%" stroke-width="3"')+path('M -14 18 L -9 15 -4 18 -9 21 Z M 8 17 L 13 14 18 17 13 20 Z','%METAL_DARK%','stroke="none"'))
part('scales_face',path('M -13 0 L -9 1 -11 4 Z M 10 2 L 14 0 12 5 Z M -12 5 L -8 6 -10 9 Z M 10 6 L 13 5 11 9 Z','%SCALES%','stroke="none"'))
part('sword',path('M -2 6 L -3 -26 0 -34 3 -26 2 6 Z','%METAL_LIGHT%')+path('M 0 -28 L 0 5','none','stroke="%METAL_DARK%"')+path('M -7 6 L 7 6 7 9 -7 9 Z','%GOLD%')+path('M -2 9 L 2 9 2 20 -2 20 Z','%LEATHER%')+ellipse(0,20,3,2,'%GOLD%'))
part('staff',path('M -2 -26 L 2 -26 2 29 -2 29 Z','%LEATHER%')+path('M -2 -16 Q -13 -22 -7 -34 Q 0 -42 8 -33 Q 15 -22 2 -16 Z','%GOLD%')+ellipse(0,-28,5,7,'%GEM%')+path('M -3 -30 L -1 -34','none','stroke="#ffffff"'))
part('bow',path('M -2 -30 Q 25 0 -2 29 Q 12 0 -2 -30 Z','%LEATHER%')+path('M -2 -30 L -2 29','none','stroke="%IVORY%" stroke-width="0.8"')+path('M 8 -4 L 10 5','none','stroke="%GOLD%" stroke-width="3"'))
palette={'INK':'#293445','SKIN':'#e4b996','SKIN_SHADE':'#bd886d','CLOTH':'#476a81','CLOTH_DARK':'#293d57','METAL':'#94aabb','METAL_LIGHT':'#d6e3df','METAL_DARK':'#56707e','GOLD':'#d8b36d','LEATHER':'#8c634d','LEATHER_DARK':'#493f40','IVORY':'#f8eacd','GEM':'#8ed6cf','HAIR':'#5c4140','HAIR_LIGHT':'#967461','EYE':'#699f9b','SCALES':'#779b92','FEATHER':'#c5b698'}
out=ROOT/'assets/human_parts'; out.mkdir(exist_ok=True)
for name,svg in PARTS.items():
    for key,color in palette.items(): svg=svg.replace('%'+key+'%',color)
    (out/(name+'.svg')).write_text(svg,encoding='utf-8')
(ROOT/'scripts/human_part_library.gd').write_text('class_name HumanPartLibrary\nextends RefCounted\n## Independent humanoid parts; generated by tools/create_human_parts.py.\nconst SVG='+json.dumps(PARTS,ensure_ascii=False,indent=1)+'\n',encoding='utf-8')
print('Generated',len(PARTS),'modular human parts')
