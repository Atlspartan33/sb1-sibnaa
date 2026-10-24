import os,sys
root=sys.argv[1]
maps=[('src/shared',['ReplicatedStorage','Shared']),('src/server',['ServerScriptService','Server']),('src/client',['StarterPlayer','StarterPlayerScripts','Client'])]
out=['return {']
for sub,base in maps:
    for dp,dn,fn in os.walk(os.path.join(root,sub)):
        for f in sorted(fn):
            if not f.endswith('.luau'): continue
            rel=os.path.relpath(os.path.join(dp,f),os.path.join(root,sub)).split(os.sep)
            name=rel[-1][:-5]; cls='ModuleScript'
            if name.endswith('.server'): name=name[:-7]; cls='Script'
            elif name.endswith('.client'): name=name[:-7]; cls='LocalScript'
            path=base+rel[:-1]+[name]
            src=open(os.path.join(dp,f)).read()
            assert ']=====]' not in src
            out.append('{path={'+','.join('"%s"'%x for x in path)+'},class="%s",source=[=====[\n%s]=====]},'%(cls,src))
out.append('}')
open('project.luau','w').write('\n'.join(out))
