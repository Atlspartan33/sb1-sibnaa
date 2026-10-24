import json,sys,os,subprocess,base64
sys.argv_backup=sys.argv; 
import importlib.util
spec=importlib.util.spec_from_file_location('r2d',os.path.join(os.path.dirname(os.path.abspath(__file__)),'render.py'))
saved=sys.argv; sys.argv=['x']; r2d=importlib.util.module_from_spec(spec); spec.loader.exec_module(r2d); sys.argv=saved
src,outdir=sys.argv[1],sys.argv[2]; os.makedirs(outdir,exist_ok=True)
worlds=[]
for line in open(src):
    if line.startswith('@@WORLD '):
        _,name,data=line.rstrip('\n').split(' ',2); worlds.append((name,json.loads(data)))
guijobs=[]
for name,w in worlds:
    for kind in ('billboards','surfaces'):
        for i,b in enumerate(w[kind]):
            d=json.loads(b['gui']) if isinstance(b['gui'],str) else b['gui']
            f=os.path.join(outdir,f'{name}_{kind}{i}.html'); open(f,'w').write(r2d.page(d,'transparent'))
            b['png']=f[:-5]+'.png'; guijobs.append([f,b['png'],max(1,int(d['w'])),max(1,int(d['h']))])
json.dump(guijobs,open(os.path.join(outdir,'guijobs.json'),'w'))
subprocess.run(['node',os.path.join(os.path.dirname(os.path.abspath(__file__)),'shots_t.cjs'),os.path.join(outdir,'guijobs.json')],check=True)
def b64(p): return 'data:image/png;base64,'+base64.b64encode(open(p,'rb').read()).decode()
pages=[]
for name,w in worlds:
    for kind in ('billboards','surfaces'):
        for b in w[kind]: b['img']=b64(b['png']); b.pop('gui',None)
    page=f'''<html><head><style>body{{margin:0}}</style>
<script type="importmap">{{"imports":{{"three":"https://unpkg.com/three@0.160.0/build/three.module.js","three/addons/":"https://unpkg.com/three@0.160.0/examples/jsm/"}}}}</script></head><body>
<script type="module">
import * as THREE from 'three';
import {{EffectComposer}} from 'three/addons/postprocessing/EffectComposer.js';
import {{RenderPass}} from 'three/addons/postprocessing/RenderPass.js';
import {{UnrealBloomPass}} from 'three/addons/postprocessing/UnrealBloomPass.js';
import {{OutputPass}} from 'three/addons/postprocessing/OutputPass.js';
const W={json.dumps(w)};
const renderer=new THREE.WebGLRenderer({{antialias:true}}); renderer.setSize(1280,720); renderer.toneMapping=THREE.ACESFilmicToneMapping; renderer.toneMappingExposure=1.1;
document.body.appendChild(renderer.domElement);
const scene=new THREE.Scene(); scene.background=new THREE.Color(0xc9e0ff); scene.fog=new THREE.Fog(0xffd6ec,90,260);
scene.add(new THREE.HemisphereLight(0xfff4ff,0xffd8ec,1.6));
const sun=new THREE.DirectionalLight(0xffffff,1.6); sun.position.set(30,80,40); scene.add(sun);
function mat4(cf){{const m=new THREE.Matrix4();m.set(cf[3],cf[4],cf[5],cf[0],cf[6],cf[7],cf[8],cf[1],cf[9],cf[10],cf[11],cf[2],0,0,0,1);return m}}
let lights=0;
for(const p of W.parts){{ if(p.t>=1) continue;
  let g; const [x,y,z]=p.size;
  if(p.shape==='Ball') g=new THREE.SphereGeometry(x/2,24,16);
  else if(p.shape==='Cylinder'){{g=new THREE.CylinderGeometry(y/2,y/2,x,28); g.rotateZ(Math.PI/2);}}
  else g=new THREE.BoxGeometry(x,y,z);
  const col=new THREE.Color(p.color);
  const m=new THREE.MeshStandardMaterial({{color:col,roughness:p.mat==='Marble'?0.25:0.6,metalness:p.refl>0.1?0.3:0.0}});
  if(p.mat==='Neon'){{m.emissive=col;m.emissiveIntensity=1.6}}
  if(p.mat==='Glass'){{m.transparent=true;m.opacity=0.55}}
  if(p.t>0){{m.transparent=true;m.opacity=1-p.t}}
  const mesh=new THREE.Mesh(g,m); mesh.matrixAutoUpdate=false; mesh.matrix.copy(mat4(p.cf)); scene.add(mesh);
  if(p.light && lights<12){{const l=new THREE.PointLight(p.light.color,25,p.light.range*1.5); l.position.set(p.cf[0],p.cf[1]+1,p.cf[2]); scene.add(l); lights++}}
}}
const loader=new THREE.TextureLoader(); const pending=[];
function tex(src){{return new Promise(r=>loader.load(src,t=>{{t.colorSpace=THREE.SRGBColorSpace;r(t)}}))}}
for(const b of W.billboards){{pending.push(tex(b.img).then(t=>{{const s=new THREE.Sprite(new THREE.SpriteMaterial({{map:t,transparent:true}})); s.position.set(...b.pos); s.scale.set(b.size[0],b.size[1],1); scene.add(s)}}))}}
for(const s of W.surfaces){{pending.push(tex(s.img).then(t=>{{
  const [x,y,z]=s.size; let w=x,h=y,local=new THREE.Matrix4();
  if(s.face==='Back') local.makeTranslation(0,0,z/2+0.03);
  else if(s.face==='Front') local.makeRotationY(Math.PI).premultiply(new THREE.Matrix4().makeTranslation(0,0,-z/2-0.03));
  else if(s.face==='Top'){{w=x;h=z;local.makeRotationX(-Math.PI/2).premultiply(new THREE.Matrix4().makeTranslation(0,y/2+0.03,0))}}
  const mesh=new THREE.Mesh(new THREE.PlaneGeometry(w,h),new THREE.MeshBasicMaterial({{map:t,transparent:true,toneMapped:false}}));
  mesh.matrixAutoUpdate=false; mesh.matrix.copy(mat4(s.cf).multiply(local)); scene.add(mesh)}}))}}
const cam=new THREE.PerspectiveCamera(70,1280/720,0.1,1000); const c=W.camera;
cam.position.set(c[0],c[1],c[2]); cam.quaternion.setFromRotationMatrix(mat4(c));
const comp=new EffectComposer(renderer); comp.addPass(new RenderPass(scene,cam));
comp.addPass(new UnrealBloomPass(new THREE.Vector2(1280,720),0.45,0.6,0.85)); comp.addPass(new OutputPass());
Promise.all(pending).then(()=>{{comp.render();document.body.dataset.done=1}});
</script></body></html>'''
    f=os.path.join(outdir,name+'.html'); open(f,'w').write(page); pages.append([f,os.path.join(outdir,name+'.png'),1280,720])
json.dump(pages,open(os.path.join(outdir,'pages3d.json'),'w'))
subprocess.run(['node',os.path.join(os.path.dirname(os.path.abspath(__file__)),'shots.cjs'),os.path.join(outdir,'pages3d.json')],check=True)
print('\n'.join(p[1] for p in pages))
