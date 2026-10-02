"""Editable vector terrain upgrade. Uses original tiles' layout, new layered shapes."""
from pathlib import Path
from random import Random
root=Path(__file__).resolve().parents[1]/'assets/art_v5'
root.mkdir(exist_ok=True)
palettes={'forest':('#8aab74','#698754','#203f38','#3b7054','#a7c681'),'mountain':('#b9b299','#938e7f','#303b48','#637583','#c5cfc1'),'island':('#ebd8a4','#cfba8e','#226777','#3d9baf','#b1e9df'),'volcano':('#876964','#624d55','#302b3d','#664d5f','#e4a779'),'cave':('#847f9e','#645e7f','#282c48','#555879','#b3bae0')}
for name,(floor,shade,dark,wall,light) in palettes.items():
 p=['<svg xmlns="http://www.w3.org/2000/svg" width="320" height="120" viewBox="0 0 320 120"><defs>',f'<linearGradient id="g" x2="40%" y2="100%"><stop stop-color="{floor}"/><stop offset="1" stop-color="{shade}"/></linearGradient>',f'<radialGradient id="leaf"><stop stop-color="{light}"/><stop offset=".5" stop-color="{wall}"/><stop offset="1" stop-color="{dark}"/></radialGradient>','<linearGradient id="gem"><stop stop-color="#e2fbf8"/><stop offset=".45" stop-color="#a8b6e6"/><stop offset="1" stop-color="#7866b2"/></linearGradient><clipPath id="tileclip"><rect width="40" height="40"/></clipPath></defs>']
 for tile in range(24):
  r=Random(5071+tile)
  p.append(f'<g transform="translate({tile%8*40},{tile//8*40})" clip-path="url(#tileclip)">')
  if tile<8:
   p.append('<path d="M0 0H40V40H0Z" fill="url(#g)"/>')
   for i in range(13):
    x,y=r.randrange(40),r.randrange(40)
    p.append(f'<ellipse cx="{x}" cy="{y}" rx="{r.randrange(2,7)}" ry="1.5" fill="{light}" opacity=".12"/>')
   if name in ['mountain','volcano','cave']:
    for i in range(3):
     x,y=r.randrange(30),r.randrange(30)
     p.append(f'<path d="M{x} {y}l9 -2 6 3-3 6-11-1Z" fill="{floor}" stroke="{dark}" stroke-opacity=".22" stroke-width=".5"/>')
   if name=='forest':
    for i in range(5):
     x,y=r.randrange(4,38),r.randrange(7,37)
     p.append(f'<path d="M{x} {y}q-4-7-3-4l3 3 1-8 1 8 4-4-3 5Z" fill="{shade}"/>')
    if tile in [1,4]:
     for x,y in [(8,14),(12,17),(9,20)]:p.append(f'<circle cx="{x}" cy="{y}" r="1.2" fill="#f1dd9b"/><circle cx="{x+.3}" cy="{y-.3}" r=".4" fill="#fff6cf"/>')
   if name=='island':p.append('<path d="M4 28q8-4 16-1M25 10l4-2" fill="none" stroke="#fff0c9" opacity=".5" stroke-width=".8"/>')
   if name=='volcano' and tile%3==0:p.append('<path d="M0 18l11 3 7-6 6 2 16-8" fill="none" stroke="#d79069" opacity=".65" stroke-width="1"/>')
  else:
   mask=tile-8
   p.append(f'<rect width="40" height="40" fill="{dark}"/>')
   if name=='island':
    p.append(f'<rect width="40" height="40" fill="{wall}" opacity=".4"/>')
    for y in [7,21,35]:p.append(f'<path d="M-4 {y}q10-3 20 0t26 0" fill="none" stroke="{light}" opacity=".3" stroke-width="1"/>')
   elif name=='forest':
    p.append('<ellipse cx="21" cy="28" rx="20" ry="11" fill="#142f2b"/>')
    for x,y,rad in [(9,11,11),(26,10,13),(10,24,11),(27,22,13),(18,12,12)]:
     p.append(f'<circle cx="{x}" cy="{y}" r="{rad}" fill="url(#leaf)"/><path d="M{x-5} {y-2}q2-6 8-5" fill="none" stroke="{light}" stroke-width=".8" opacity=".6"/>')
   else:
    for x,y in [(1,0),(21,-3),(-4,21),(20,19)]:
     p.append(f'<path d="M{x} {y+7}l8-6 13 4 2 16-14 6-10-5Z" fill="{wall}" stroke="{dark}" stroke-width="1.8"/><path d="M{x+3} {y+7}l7-3 10 4-7 6Z" fill="{light}" opacity=".28"/>')
    if name=='volcano':p.append('<path d="M-2 18l12 4 9-6 10 13 12-2" fill="none" stroke="#eb8253" opacity=".8" stroke-width="1.5"/>')
    if name=='cave' and tile%3==0:p.append('<path d="M15 30l-4-17 6-9 6 13-3 14ZM25 30l-2-10 5-7 5 12-4 7Z" fill="url(#gem)" stroke="#d2edeb" stroke-width=".7"/>')
   if mask&4:p.append(f'<path d="M0 35q10 4 20 0t20 0v5H0Z" fill="{dark}" opacity=".6"/><path d="M1 35q9 4 19 0t19 0" fill="none" stroke="{light}" opacity=".45" stroke-width="1.1"/>')
  p.append('</g>')
 p.append('</svg>');(root/f'field_{name}.svg').write_text(''.join(p),encoding='utf-8')
# Architectural sprites retain exact original footprints/doors, but add roofs, timber and glazing.
for kind,roof in [('home','#af705d'),('shop','#d4aa63'),('nursery','#719d89'),('storage','#778ba0')]:
 p=['<svg xmlns="http://www.w3.org/2000/svg" width="352" height="352" viewBox="0 0 176 176"><defs>',f'<linearGradient id="roof" x2=".3" y2="1"><stop stop-color="{roof}"/><stop offset="1" stop-color="#3e5750"/></linearGradient>','<linearGradient id="wall" x2=".8" y2="1"><stop stop-color="#f4e6bb"/><stop offset="1" stop-color="#c4bc99"/></linearGradient><linearGradient id="glass" x2=".6" y2="1"><stop stop-color="#d8eee1"/><stop offset="1" stop-color="#658f86"/></linearGradient></defs>', '<ellipse cx="90" cy="152" rx="75" ry="15" fill="#1f423c" opacity=".22"/><path d="M26 76H147V149Q83 161 26 146Z" fill="url(#wall)" stroke="#4f5e4c" stroke-width="2"/>','<path d="M116 28h17v39h-17Z" fill="#8a7d67" stroke="#49594f" stroke-width="2"/><path d="M114 26h22v7h-22Z" fill="#c4b391"/>','<path d="M13 81L85 24l77 58-14 14-63-41-57 39Z" fill="url(#roof)" stroke="#435448" stroke-width="3"/>']
 for y in [47,57,67,77]:p.append(f'<path d="M{82-(y-26)*1.1} {y+4}L85 {y-17}l{(y-26)*1.18} 23" fill="none" stroke="#e8c98b" opacity=".36" stroke-width="1.4"/>')
 for x in [30,78,143]:p.append(f'<path d="M{x} 91v55" stroke="#806f4f" stroke-width="5"/>')
 p+=['<path d="M33 110h108M29 143h113" stroke="#8a7857" stroke-width="4"/>','<path d="M69 148v-34q17-23 34 0v34Z" fill="#6d7c64" stroke="#4f5e4c" stroke-width="3"/><path d="M75 146v-30q10-13 21 0v30" fill="none" stroke="#9baf87" stroke-width="1.6"/><circle cx="94" cy="132" r="2" fill="#ecdba0"/>']
 for x in [40,114]:
  p.append(f'<rect x="{x}" y="92" width="25" height="26" rx="5" fill="url(#glass)" stroke="#647460" stroke-width="3"/><path d="M{x+12} 93v24M{x} 105h25" stroke="#e8dfb6" stroke-width="2"/><rect x="{x-4}" y="117" width="32" height="7" rx="2" fill="#9d7756"/>')
  for j in range(5):p.append(f'<circle cx="{x+j*5}" cy="115" r="3.6" fill="{["#8ca572","#e1ba8b","#76967b"][j%3]}"/>')
 if kind=='nursery':p.append('<path d="M19 83L87 32l61 49v65H25Z" fill="url(#glass)" opacity=".55"/><path d="M21 83L87 34l62 49M87 35v112M44 68v77M120 62v84M22 108h126" fill="none" stroke="#e0e8c7" stroke-width="3"/>')
 if kind=='shop':p.append('<path d="M26 88h119l11 18H16Z" fill="#e6d3a1" stroke="#816e4d" stroke-width="2"/>')
 for x in [35,130]:p.append(f'<path d="M{x} 78v13" stroke="#41574b" stroke-width="2"/><rect x="{x-4}" y="86" width="9" height="13" rx="3" fill="#f2d99a" stroke="#5b6250" stroke-width="1.5"/>')
 p.append('<path d="M61 152h49l8 10H54Z" fill="#c1b69b" stroke="#8c967d" stroke-width="1.5"/></svg>');(root/f'{kind}.svg').write_text(''.join(p),encoding='utf-8')
