"""Original score and sound design for Gene Trail; numpy + stdlib only.
No downloaded samples, soundfonts or melodies. Reproducible stereo PCM assets.
"""
from pathlib import Path
import wave, json
import numpy as np

OUT=Path(__file__).resolve().parents[1]/'assets'/'audio'
OUT.mkdir(parents=True,exist_ok=True)
RATE=22050
rng=np.random.default_rng(73040)

def tone(midi,duration,kind='flute'):
    t=np.arange(max(1,int(duration*RATE)))/RATE
    freq=440*2**((midi-69)/12)
    phase=2*np.pi*freq*t+0.016*np.sin(2*np.pi*5*t)
    if kind=='bell':
        sound=np.sin(phase)*np.exp(-t*3)+.35*np.sin(phase*2.01)*np.exp(-t*7)+.16*np.sin(phase*3.98)*np.exp(-t*12)
    elif kind=='pluck':
        sound=(np.sin(phase)+.35*np.sin(2*phase)+.13*np.sin(3*phase))*np.exp(-t*7)
    elif kind=='bass':
        sound=(np.sin(phase)+.22*np.sin(2*phase))*np.exp(-t*1.4)
    elif kind=='pad':
        sound=(np.sin(phase)+.3*np.sin(phase*1.003)+.14*np.sin(2*phase))*np.sin(np.pi*np.minimum(t/duration,1))**.55
    else:
        sound=(np.sin(phase)+.20*np.sin(2*phase)+.08*np.sin(3*phase))*np.exp(-t*.65)
        noise=rng.normal(0,.013,len(t)); sound+=np.convolve(noise,np.ones(7)/7,mode='same')
    env=np.minimum(1,t/.018)*np.minimum(1,(duration-t)/.055)
    return sound*np.clip(env,0,1)

def place(buf,mono,start,volume=.1,pan=0,wrap=False):
    offset=int(start*RATE)
    stereo=np.stack([mono*np.sqrt((1-pan)/2),mono*np.sqrt((1+pan)/2)],axis=1)*volume
    if wrap:
        idx=(offset+np.arange(len(mono)))%len(buf)
        np.add.at(buf,idx,stereo)
    elif offset<len(buf):
        count=min(len(stereo),len(buf)-offset); buf[offset:offset+count]+=stereo[:count]

def write(name,buf,loop=False):
    # A little stereo room; wrap the reverb tail for seamless musical loops.
    dry=buf.copy()
    for delay,gain in [(0.137,.14),(.263,.10),(.397,.06)]:
        n=int(delay*RATE)
        if loop: buf+=np.roll(dry[:,::-1],n,axis=0)*gain
        elif n<len(buf): buf[n:]+=dry[:-n,::-1]*gain
    peak=np.max(np.abs(buf))
    buf*=min(1,.82/max(.001,peak))
    # Boundary clicks are removed without a long gap at the loop seam.
    fade=min(96,len(buf)//4)
    buf[:fade]*=np.linspace(0,1,fade)[:,None]
    buf[-fade:]*=np.linspace(1,0,fade)[:,None]
    pcm=(np.clip(buf,-1,1)*32767).astype('<i2')
    with wave.open(str(OUT/(name+'.wav')),'wb') as file:
        file.setnchannels(2); file.setsampwidth(2); file.setframerate(RATE); file.writeframes(pcm.tobytes())
    return {'file':name+'.wav','seconds':round(len(buf)/RATE,3),'peak':round(float(np.max(abs(buf))),4),'rms':round(float(np.sqrt(np.mean(buf**2))),4)}

# Newly composed scale-degree phrases; each region has its own melodic shape.
TRACKS={
 'title':(92,60,[0,2,4,7,9],[0,2,3,2,1,0,1,3,4,3,2,1,2,0,1,0],'flute'),
 'town':(104,62,[0,2,4,7,9],[2,1,0,1,3,4,3,2,1,3,2,0,1,2,1,0],'bell'),
 'forest':(112,67,[0,2,4,7,9],[0,1,3,2,4,3,1,2,0,2,1,3,2,1,4,3],'flute'),
 'mountain':(98,60,[0,2,4,5,7,9,11],[0,4,2,3,4,6,5,4,2,3,1,4,2,0,1,0],'flute'),
 'island':(108,65,[0,2,4,7,9],[2,3,4,2,0,1,3,1,4,3,2,1,0,2,1,0],'pluck'),
 'volcano':(118,57,[0,2,3,5,7,8,10],[0,2,4,3,2,0,1,2,4,6,5,3,4,2,1,0],'flute'),
 'cave':(84,62,[0,2,3,7,10],[0,3,2,1,4,2,3,0,1,2,4,3,2,1,3,0],'bell'),
 'battle':(138,62,[0,2,3,5,7,9,10],[0,2,4,2,3,4,6,5,4,2,3,1,2,0,1,4],'flute'),
}
report=[]
for name,(bpm,key,scale,motif,lead) in TRACKS.items():
    beat=60/bpm; bars=16; duration=bars*4*beat
    buf=np.zeros((int(duration*RATE),2),dtype=np.float64)
    roots=[0,3,4,0,5,3,4,0] if len(scale)>5 else [0,2,3,0,4,2,3,0]
    for bar in range(bars):
        root=roots[bar%8]%len(scale)
        chord=[key+scale[(root+i)%len(scale)] for i in [0,2,4]]
        for k,midi in enumerate(chord): place(buf,tone(midi,beat*4,'pad'),bar*4*beat,.045,[-.55,0,.55][k],True)
        for b in [0,2]: place(buf,tone(key-12+scale[root],beat*1.75,'bass'),(bar*4+b)*beat,.14,-.1,True)
        for eighth in range(8):
            midi=chord[(eighth+bar)%3]+12
            place(buf,tone(midi,beat*.75,'pluck'),(bar*4+eighth*.5)*beat,.055,(-.55 if eighth%2==0 else .55),True)
        for n in range(4):
            degree=motif[(bar*2+n)%len(motif)]
            if bar>=8 and n==3: degree=(degree+1)%len(scale)
            length=beat*(.45 if name=='battle' else (.7 if n<3 else 1.1))
            midi=key+12+scale[degree]+(12 if bar in [7,15] and n==0 else 0)
            place(buf,tone(midi,length,lead),(bar*4+n)*beat,.16,.08,True)
            if name=='battle': place(buf,tone(midi-12,beat*.3,'pluck'),(bar*4+n+.5)*beat,.12,-.3,True)
        if name not in ['title','cave']:
            for b in range(4):
                t=np.arange(int(RATE*.08))/RATE
                click=rng.normal(0,.25,len(t))*np.exp(-t*70)+np.sin(2*np.pi*160*t)*np.exp(-t*50)
                place(buf,click,(bar*4+b)*beat,.065 if b%2 else .1,.3,True)
    report.append(write(name,buf,True))

SFX={'ui':([79,84],.09,'bell'),'step':([44],.07,'pluck'),'hit':([49,44],.09,'pluck'),
     'cast':([67,74,79],.13,'bell'),'heal':([72,76,79,84],.14,'bell'),
     'delay':([79,75,70,63],.12,'bell'),'battle_start':([62,69,74,77],.16,'flute'),
     'defeat':([62,57,50],.18,'bass'),'victory':([67,71,74,79,83,86],.18,'bell'),
     'level_up':([60,64,67,72,76,79,84],.12,'bell'),'save':([72,79,84],.12,'bell'),
     'recruit':([67,72,76,79,84],.15,'flute')}
for name,(notes,dur,kind) in SFX.items():
    buf=np.zeros((int((len(notes)*dur+.45)*RATE),2))
    for i,note in enumerate(notes): place(buf,tone(note,dur*2,kind),i*dur,.3)
    report.append(write('sfx_'+name,buf))
(OUT/'manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('Created',len(report),'original audio assets. Total music:',round(sum(t['seconds'] for t in report[:8]),1),'seconds')
