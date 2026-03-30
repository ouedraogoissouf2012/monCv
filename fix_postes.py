import json, urllib.request

# Login
login_data = json.dumps({"email": "issouf@moncv.com", "password": "moncv2024"}).encode()
req = urllib.request.Request("http://localhost:8082/api/auth/login", data=login_data, headers={"Content-Type": "application/json"})
token = json.loads(urllib.request.urlopen(req).read())["accessToken"]

# Get CV
req = urllib.request.Request("http://localhost:8082/api/cvs/2", headers={"Authorization": f"Bearer {token}"})
cv = json.loads(urllib.request.urlopen(req).read())

# Fix les postes manuellement
for e in cv['experiences']:
    if 'DIGIT' in (e.get('poste') or ''):
        e['poste'] = 'Développeur Web'
    if 'nsia' in (e.get('poste') or '').lower():
        e['poste'] = 'Stagiaire Développeur Web'

for k in ['publicToken', 'createdAt', 'updatedAt', 'id']:
    cv.pop(k, None)

# PUT
data = json.dumps(cv, ensure_ascii=False).encode('utf-8')
req = urllib.request.Request(
    "http://localhost:8082/api/cvs/2",
    data=data,
    headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json; charset=utf-8"},
    method="PUT"
)
resp = json.loads(urllib.request.urlopen(req).read())
for e in resp.get('experiences', []):
    print(f"poste: {e['poste']}")
print("DONE - postes corriges")
