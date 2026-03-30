import json, urllib.request

# Login
login_data = json.dumps({"email": "issouf@moncv.com", "password": "moncv2024"}).encode()
req = urllib.request.Request("http://localhost:8082/api/auth/login", data=login_data, headers={"Content-Type": "application/json"})
token = json.loads(urllib.request.urlopen(req).read())["accessToken"]

# Get CV
req = urllib.request.Request("http://localhost:8082/api/cvs/2", headers={"Authorization": f"Bearer {token}"})
raw = urllib.request.urlopen(req).read()
cv = json.loads(raw)

def fix(s):
    if not s or not isinstance(s, str):
        return s
    for _ in range(3):
        try:
            fixed = s.encode('latin1').decode('utf-8')
            if fixed != s:
                s = fixed
            else:
                break
        except (UnicodeDecodeError, UnicodeEncodeError):
            break
    return s

def fix_obj(o):
    if isinstance(o, str): return fix(o)
    if isinstance(o, dict): return {k: fix_obj(v) for k, v in o.items()}
    if isinstance(o, list): return [fix_obj(i) for i in o]
    return o

cv_fixed = fix_obj(cv)
for k in ['publicToken', 'createdAt', 'updatedAt', 'id']:
    cv_fixed.pop(k, None)

# Write to file to inspect
with open('cv_before.json', 'w', encoding='utf-8') as f:
    json.dump(cv, f, ensure_ascii=False, indent=2)
with open('cv_after.json', 'w', encoding='utf-8') as f:
    json.dump(cv_fixed, f, ensure_ascii=False, indent=2)

print("Written cv_before.json and cv_after.json")
print("Check the files to see if encoding was fixed")

# PUT the fixed version
data = json.dumps(cv_fixed, ensure_ascii=False).encode('utf-8')
req = urllib.request.Request(
    "http://localhost:8082/api/cvs/2",
    data=data,
    headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json; charset=utf-8"},
    method="PUT"
)
resp = json.loads(urllib.request.urlopen(req).read())
with open('cv_result.json', 'w', encoding='utf-8') as f:
    json.dump(resp, f, ensure_ascii=False, indent=2)
print("Written cv_result.json")
print("DONE")
