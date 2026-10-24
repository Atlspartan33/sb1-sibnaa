import json,sys,os,html,subprocess
MAIN = __name__=='__main__'
shots=[]
outdir=sys.argv[2] if MAIN else '.'
if MAIN: os.makedirs(outdir,exist_ok=True)
for line in (open(sys.argv[1]) if MAIN else []):
    if line.startswith('@@SHOT '):
        _,name,data=line.rstrip('\n').split(' ',2)
        shots.append((name,json.loads(data)))
def rgba(hexc,t):
    r,g,b=int(hexc[1:3],16),int(hexc[3:5],16),int(hexc[5:7],16)
    return f"rgba({r},{g},{b},{1-t:.3f})"
def node(n):
    st=[f"left:{n['x']:.1f}px",f"top:{n['y']:.1f}px",f"width:{max(0,n['w']):.1f}px",f"height:{max(0,n['h']):.1f}px",f"z-index:{int(n['z'])}"]
    if n.get('rot'): st.append(f"transform:rotate({n['rot']}deg)")
    if n.get('grad'):
        g=n['grad']; stops=','.join(f"{c['c']} {c['t']*100:.0f}%" for c in g['cols'])
        st.append(f"background:linear-gradient({(g['rot']+90)}deg,{stops})")
        if n['bt']>0: st.append(f"opacity:{1-n['bt']:.2f}") if not n['kids'] else None
    else:
        st.append(f"background:{rgba(n['bg'],n['bt'])}")
    if n.get('radius'): st.append(f"border-radius:{n['radius']:.1f}px")
    if n.get('stroke') and n['stroke']['t']<1:
        s=n['stroke']; st.append(f"outline:{s['thick']}px solid {rgba(s['color'],s['t'])};outline-offset:0px")
        if n.get('radius'): st.append(f"box-shadow:0 0 0 {s['thick']}px {rgba(s['color'],s['t'])};outline:none")
    if n.get('clip'): st.append("overflow:hidden")
    inner=''
    if 'text' in n:
        cls='txt scaled' if n['scaled'] else 'txt'
        fs=n['size'] if not n['scaled'] else n.get('maxText',100)
        align={'Left':'flex-start','Right':'flex-end'}.get(n['xa'],'center')
        inner=f"<div class='{cls}' data-max='{fs}' style='color:{rgba(n['tc'],n['tt'])};font-size:{fs}px;justify-content:{align};text-align:{ {'flex-start':'left','flex-end':'right'}.get(align,'center') }'>{html.escape(n['text'])}</div>"
    kids=''.join(node(k) for k in n['kids'])
    return f"<div class='g' style='{';'.join(st)}'>{inner}{kids}</div>"
FIT='''<script>
document.fonts.ready.then(()=>{for(const el of document.querySelectorAll('.txt.scaled')){let hi=parseFloat(el.dataset.max),lo=1;const box=el.parentElement;
for(let i=0;i<14;i++){const mid=(hi+lo)/2;el.style.fontSize=mid+'px';if(el.scrollHeight<=box.clientHeight+1&&el.scrollWidth<=box.clientWidth+1)lo=mid;else hi=mid}el.style.fontSize=lo+'px'}document.body.dataset.done=1})</script>'''
def page(d, background=None):
    body=''.join(f"<div class='g' style='left:0;top:0;width:{d['w']}px;height:{d['h']}px;z-index:{g['order']}'>{''.join(node(k) for k in g['kids'])}</div>" for g in d['guis'])
    bg = background or d.get('background','linear-gradient(#cfe8ff,#f6e7ff)')
    return f'''<html><head><link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@600&display=block" rel="stylesheet"><style>
body{{margin:0;width:{d['w']}px;height:{d['h']}px;position:relative;overflow:hidden;background:{bg};font-family:Fredoka,'Noto Color Emoji',sans-serif}}
.g{{position:absolute;box-sizing:border-box}} .txt{{position:absolute;inset:0;display:flex;align-items:center;white-space:pre-wrap;line-height:1.05;overflow:hidden;word-break:break-word}}
</style></head><body>{body}{FIT}</body></html>'''
pages=[]
for name,d in shots:
    bg=d.get('bg','#b9d9b0')
    body=''.join(f"<div class='g' style='left:0;top:0;width:{d['w']}px;height:{d['h']}px;z-index:{g['order']}'>{''.join(node(k) for k in g['kids'])}</div>" for g in d['guis'])
    page=f'''<html><head><link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@600&display=block" rel="stylesheet"><style>
body{{margin:0;width:{d['w']}px;height:{d['h']}px;position:relative;overflow:hidden;background:{d.get('background','linear-gradient(#cfe8ff,#f6e7ff)')};font-family:Fredoka,'Noto Color Emoji',sans-serif}}
.g{{position:absolute;box-sizing:border-box}} .txt{{position:absolute;inset:0;display:flex;align-items:center;white-space:pre-wrap;line-height:1.05;overflow:hidden;word-break:break-word}}
</style></head><body>{body}{FIT}</body></html>'''
    f=os.path.join(outdir,name+'.html'); open(f,'w').write(page); pages.append((f,os.path.join(outdir,name+'.png'),d['w'],d['h']))
if MAIN: json.dump(pages,open(os.path.join(outdir,'pages.json'),'w'))
if MAIN: subprocess.run(['node',os.path.join(os.path.dirname(os.path.abspath(__file__)),'shots.cjs'),os.path.join(outdir,'pages.json')],check=True)
if MAIN: print('\n'.join(p[1] for p in pages))
