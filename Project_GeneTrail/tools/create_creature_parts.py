"""Build editable SVG body parts and their embedded runtime source library.

These are independent joint-centred vector parts, never complete character poses.
Run from any directory. Godot loads the embedded SVG strings in exported builds.
"""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'creature_parts_v12'
OUT.mkdir(parents=True, exist_ok=True)
parts = {}

def path(d, fill, stroke='none', width=2.0):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"/>'

def ellipse(cx, cy, rx, ry, fill, stroke='none', width=1.5):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'

def add(name, silhouette, detail='', patterned=False, outline=None, material='skin'):
    defs = f'<clipPath id="shape">{path(silhouette,"white")}</clipPath>'
    defs += '<linearGradient id="volume" x1="0" y1="0" x2="0.35" y2="1"><stop stop-color="%LIGHT%"/><stop offset="0.23" stop-color="%BASE%"/><stop offset="1" stop-color="%BASE%"/></linearGradient>'
    defs += '<linearGradient id="ivory" x1="0" y1="0" x2="0.5" y2="1"><stop stop-color="#fff7de"/><stop offset="0.52" stop-color="%CREAM%"/><stop offset="1" stop-color="%BASE%"/></linearGradient>'
    paint = path(silhouette,'url(#volume)')
    shade = path('M 0 67 Q 30 85 59 71 Q 85 62 96 37 L 96 96 L 0 96 Z','%SHADOW%')
    shine = ''
    paint += '<g clip-path="url(#shape)">'+shade+shine
    if patterned: paint += '%PATTERN%%WHITE%'
    paint += detail.replace('fill="%CREAM%"','fill="url(#ivory)"')+'</g>'
    paint += path(outline if outline else silhouette,'none','%INK%',1.8)
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><defs>{defs}</defs>{paint}</svg>'
    if material in ('leaf','bloom'):
        prefix = material.upper()
        for token,replacement in [('BASE',prefix),('SHADOW',prefix+'_SHADE'),('LIGHT',prefix+'_LIGHT')]:
            svg=svg.replace('%'+token+'%','%'+replacement+'%')
    parts[name] = svg

# Cat and dog ears retain the accepted three inherited variants.
ears = [[('M 34 52 L 29 12 Q 32 6 38 15 L 62 44 L 62 54 Z', 'M 38 45 L 34 20 L 54 44 Z'), ('M 33 50 L 28 17 Q 42 16 58 31 L 66 47 L 53 43 L 42 52 Z', 'M 34 24 L 57 37 L 47 42 Z'), ('M 34 52 L 39 4 Q 44 1 48 9 L 63 43 L 57 56 Z', 'M 42 42 L 44 14 L 54 42 Z')], [('M 33 52 L 26 13 Q 33 4 40 16 L 64 43 L 59 56 Z', 'M 36 43 L 32 21 L 53 43 Z'), ('M 36 39 Q 19 35 20 56 Q 21 80 38 84 Q 54 76 58 51 L 59 40 Z', 'M 33 47 Q 25 58 36 73 Q 46 64 47 47 Z'), ('M 34 50 L 34 4 L 43 10 L 65 46 L 60 55 Z', 'M 40 39 L 39 16 L 54 42 Z')]]
for species, variants in enumerate(ears):
    for variant, (shape, inside) in enumerate(variants):
        add(f"ear_{species}_{variant}", shape, path(inside, "%INNER%"))

add('charm_bud','M 40 40 Q 58 30 60 45 Q 62 59 46 62 Q 38 53 40 40 Z',path('M 45 44 L 52 55 L 57 40 Z','%ACCENT%'))
add('charm_gem','M 48 27 L 66 43 L 60 66 L 41 69 L 29 48 Z',path('M 48 33 L 59 46 L 50 59 L 37 48 Z','%ACCENT%')+path('M 48 35 L 44 45 L 39 47','none','%CREAM%',2))
add('charm_ribbon','M 43 45 L 27 33 L 26 59 L 42 54 L 41 77 L 53 66 L 61 72 L 56 52 L 76 56 L 68 32 L 52 44 Z',path('M 31 39 L 45 47 L 48 58 L 54 47 L 67 40 L 69 51 L 52 50 L 50 66 L 47 52 L 32 54 Z','%ACCENT%'))

from creature_species_shapes import refine_species_parts
refine_species_parts(add, path, ellipse, parts)
from creature_botanical import refine_botanical_parts
refine_botanical_parts(add, path, ellipse, parts)
from creature_form_refinement import refine_forms
refine_forms(add, path, ellipse, parts)

preview_colors={'BASE':'#eee5cf','SHADOW':'#bec7b9','LIGHT':'#faf6e7','INK':'#414d44','CREAM':'#f8f5e9','INNER':'#dcaeab','ACCENT':'#b9c985','EYE':'#88a775','LEAF':'#a0be80','LEAF_SHADE':'#75945f','LEAF_LIGHT':'#cad79e','BLOOM':'#dda2ae','BLOOM_SHADE':'#b97f94','BLOOM_LIGHT':'#f1c8c8','SEED':'#efda94','PATTERN':'','WHITE':''}
for name,svg in parts.items():
    for token,value in preview_colors.items(): svg=svg.replace('%'+token+'%',value)
    (OUT/(name+'.svg')).write_text(svg,encoding='utf-8')

library='class_name CreaturePartLibrary\nextends RefCounted\n## Generated from tools/create_creature_parts.py; independent, joint-centred SVG parts.\nconst SVG = '+json.dumps(parts,ensure_ascii=False,indent=1)+'\n'
(ROOT/'scripts/creature_part_library.gd').write_text(library,encoding='utf-8')
(OUT/'manifest.json').write_text(json.dumps({'size':96,'pivot':[48,48],'count':len(parts),'parts':list(parts)},indent=2),encoding='utf-8')
print(f'Created {len(parts)} independently editable SVG parts and embedded runtime library.')
