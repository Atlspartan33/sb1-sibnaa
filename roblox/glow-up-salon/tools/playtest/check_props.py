import json,re,sys,glob
api=json.load(open(sys.argv[1]))
classes={c['Name']:c for c in api['Classes']}
def props(cn):
    out=set()
    while cn and cn in classes:
        c=classes[cn]
        for m in c['Members']:
            if m['MemberType']=='Property': out.add(m['Name'])
        cn=c.get('Superclass')
    return out
def table_keys(src,i):
    # src[i]=='{'
    depth=0;keys=[];j=i;tok=''
    while j<len(src):
        ch=src[j]
        if ch in '{([': depth+=1
        elif ch in '})]':
            depth-=1
            if depth==0: break
        elif depth==1:
            m=re.match(r'[\s,]*([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)',src[j:])
            if m and (src[j-1] in '{,\n\t ' ):
                # ensure at depth1 start of a field
                keys.append(m.group(1)); j+=m.end(); continue
        j+=1
    return keys
bad=0
for f in glob.glob(sys.argv[2]+'/**/*.luau',recursive=True):
    src=open(f).read()
    for m in re.finditer(r'new\("(\w+)",\s*\{',src):
        cn=m.group(1); ks=table_keys(src,m.end()-1); ps=props(cn)
        for k in ks:
            if k not in ps: print(f,cn,k); bad+=1
    for m in re.finditer(r'Theme\.button\(\{',src):
        ks=table_keys(src,m.end()-1); ps=props('TextButton')|{'Color','MaxText'}
        for k in ks:
            if k not in ps: print(f,'button',k); bad+=1
print("bad",bad)
sys.exit(1 if bad else 0)
