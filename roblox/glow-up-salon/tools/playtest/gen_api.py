# Turns Roblox's API dump into api.luau, which the fake engine uses to check every
# property, event and enum the game touches.
import json, sys

api = json.load(open(sys.argv[1]))
q = lambda s: '"' + s.replace('"', '\\"') + '"'
out = ["return {"]
callbacks = [f"{c['Name']}.{m['Name']}" for c in api["Classes"] for m in c["Members"] if m["MemberType"] == "Callback"]
out.append("callbacks={" + ",".join(f"[{q(x)}]=true" for x in callbacks) + "},")
out.append("classes = {")
for c in api["Classes"]:
    props, events, methods = [], [], []
    for m in c["Members"]:
        mt = m["MemberType"]
        if mt == "Property":
            vt = m["ValueType"]
            props.append(f"[{q(m['Name'])}]={{{q(vt['Category'])},{q(vt['Name'])}}}")
        elif mt == "Event":
            events.append(f"[{q(m['Name'])}]=true")
        elif mt in ("Function", "YieldFunction"):
            methods.append(f"[{q(m['Name'])}]=true")
    tags = c.get("Tags") or []
    creatable = "false" if "NotCreatable" in tags or "Service" in tags else "true"
    out.append(f"[{q(c['Name'])}]={{super={q(c['Superclass'])},creatable={creatable},props={{{','.join(props)}}},events={{{','.join(events)}}},methods={{{','.join(methods)}}}}},")
out.append("},enums={")
for e in api["Enums"]:
    out.append(f"[{q(e['Name'])}]={{{','.join('[' + q(i['Name']) + ']=' + str(i['Value']) for i in e['Items'])}}},")
out.append("}}")
open("api.luau", "w").write("\n".join(out))
