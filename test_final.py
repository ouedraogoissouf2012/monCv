import json, urllib.request, re

BASE = 'http://localhost:8082/api'
login_data = json.dumps({"email": "issouf@moncv.com", "password": "moncv2024"}).encode()
req = urllib.request.Request(f"{BASE}/auth/login", data=login_data, headers={"Content-Type": "application/json"})
token = json.loads(urllib.request.urlopen(req).read())["accessToken"]
H = {"Authorization": f"Bearer {token}", "Content-Type": "application/json; charset=utf-8"}

print("=== 1. CREATION ===")
cv = {
    "titre": "Developpeur Full Stack",
    "personalInfo": {
        "prenom": "Issouf", "nom": "Ouedraogo",
        "email": "issouf.ouedraogo@gmail.com", "telephone": "+225 07 44 21 01 12",
        "ville": "Abidjan", "pays": "Cote d'Ivoire",
        "titrePoste": "Developpeur Full Stack Java et Angular",
        "resumeProfessionnel": "Developpeur Full Stack avec 2 ans d'experience. Specialise Java/Spring Boot et Angular. Livre 5 projets clients en Agile chez DIGIT AFRICAN.",
        "linkedIn": "linkedin.com/in/issouf-ouedraogo",
        "portfolio": "github.com/issouf-ouedraogo"
    },
    "experiences": [
        {"poste": "Developpeur Web Full Stack", "entreprise": "DIGIT AFRICAN", "lieu": "Abidjan",
         "dateDebut": "2024-06-01", "actuel": True,
         "description": "- Conception et developpement de 5 applications web avec Java Spring Boot et Angular\n- Collaboration equipe Agile de 4 developpeurs, 100% des sprints livres\n- Optimisation requetes SQL PostgreSQL, temps de reponse reduit de 30%\n- Pipeline CI/CD avec Docker, temps de deploiement reduit de 50%"},
        {"poste": "Stagiaire Developpeur Web", "entreprise": "NSIA Banque", "lieu": "Abidjan",
         "dateDebut": "2023-09-01", "dateFin": "2024-05-31", "actuel": False,
         "description": "- Developpement de 3 interfaces utilisateur internes avec Angular et TypeScript\n- Resolution de 45 tickets de bugs, reduisant les incidents de production de 20%\n- Implementation de 5 nouvelles fonctionnalites en respectant les normes de securite bancaire"}
    ],
    "educations": [
        {"diplome": "Licence Informatique", "etablissement": "Universite Aube Nouvelle de Bobo-Dioulasso",
         "domaine": "Genie Logiciel", "dateDebut": "2020-10-01", "dateFin": "2023-07-15",
         "description": "Specialite developpement logiciel. Projet de fin d'etudes: application de gestion RH avec Java EE."}
    ],
    "skills": [
        {"nom": "Java", "niveau": 4}, {"nom": "Spring Boot", "niveau": 4},
        {"nom": "Angular", "niveau": 4}, {"nom": "TypeScript", "niveau": 3},
        {"nom": "PostgreSQL", "niveau": 3}, {"nom": "Flutter", "niveau": 3},
        {"nom": "Docker", "niveau": 2}, {"nom": "Git", "niveau": 4},
        {"nom": "CI/CD", "niveau": 3}, {"nom": "API REST", "niveau": 4}
    ],
    "languages": [{"langue": "Francais", "niveau": "C2"}, {"langue": "Anglais", "niveau": "B2"}],
    "certifications": [{"nom": "AWS Cloud Practitioner", "organisme": "Amazon Web Services", "dateObtention": "2025-03-15"}],
    "projects": [
        {"nom": "MonCV", "description": "Application web et mobile de creation de CV professionnels avec IA integree. 6 templates personnalisables, export PDF et DOCX, score ATS. Utilise par 500+ utilisateurs.", "technologies": "Flutter, Spring Boot, PostgreSQL"}
    ]
}

data = json.dumps(cv).encode('utf-8')
req = urllib.request.Request(f"{BASE}/cvs", data=data, headers=H, method='POST')
resp = json.loads(urllib.request.urlopen(req).read())
cv_id = resp['id']
print(f"CV cree: id={cv_id}")

print("\n=== 2. IA MAX ===")
enh_data = json.dumps({"cvId": cv_id, "level": "MAX"}).encode()
req = urllib.request.Request(f"{BASE}/ai/enhance-cv", data=enh_data, headers=H, method='POST')
enh = json.loads(urllib.request.urlopen(req).read())
print(f"aiGenerated: {enh.get('aiGenerated')}")

print("\n=== 3. APPLIQUER ===")
req = urllib.request.Request(f"{BASE}/cvs/{cv_id}", headers=H)
cur = json.loads(urllib.request.urlopen(req).read())
if enh.get('resumeProfessionnel'): cur['personalInfo']['resumeProfessionnel'] = enh['resumeProfessionnel']
if enh.get('titrePoste'): cur['personalInfo']['titrePoste'] = enh['titrePoste']
if enh.get('experiences'):
    for i, ai in enumerate(enh['experiences']):
        if i < len(cur['experiences']) and ai.get('description'):
            cur['experiences'][i]['description'] = ai['description']
if enh.get('skills') and len(enh['skills']) > 0:
    cur['skills'] = [{'nom': s['nom'], 'niveau': s.get('niveau', 3)} for s in enh['skills']]
for k in ['publicToken', 'createdAt', 'updatedAt', 'id']: cur.pop(k, None)
data = json.dumps(cur, ensure_ascii=False).encode('utf-8')
req = urllib.request.Request(f"{BASE}/cvs/{cv_id}", data=data, headers=H, method='PUT')
final = json.loads(urllib.request.urlopen(req).read())
print("OK")

print("\n" + "="*60)
print("AUDIT FINAL")
print("="*60)
pi = final.get('personalInfo', {})
resume = pi.get('resumeProfessionnel', '')
exps = final.get('experiences', [])
skills = final.get('skills', [])
langs = final.get('languages', [])
all_text = resume + ' ' + ' '.join(e.get('description', '') or '' for e in exps)
ok, pb = [], []

# Checks
if '**' in all_text: pb.append('Markdown **')
else: ok.append('Pas de markdown')

pls = [p for p in ['Conçus','Développés','Résolus','Implémentés','Optimisés'] if p in all_text]
if pls: pb.append(f'Pluriels: {pls}')
else: ok.append('Singulier correct')

if any(f'{n} ans' in resume for n in [5,6,7,8,10]): pb.append('Annees inventees')
else: ok.append('Annees coherentes')

cls = [c for c in ['motivé','dynamique','passionné','rigoureux','approche orientée','expérience avérée'] if c in all_text.lower()]
if cls: pb.append(f'Cliches: {cls}')
else: ok.append('Pas de cliches')

sn = [s.get('nom','') for s in skills]
if any('CI/CD' in n for n in sn): ok.append('CI/CD intact')
elif 'CI' in sn and 'CD' in sn: pb.append('CI/CD coupe')

if len(skills) <= 12: ok.append(f'{len(skills)} skills')
else: pb.append(f'{len(skills)} skills (trop)')

for i, e in enumerate(exps):
    d = e.get('description', '')
    if d and re.search(r'\d', d): ok.append(f'Exp{i+1}: chiffres OK')
    elif d: pb.append(f'Exp{i+1}: pas de chiffre')

# Repetition titre
for i, e in enumerate(exps):
    d = (e.get('description', '') or '').strip()
    fl = d.split('\n')[0] if d else ''
    if fl and not fl.startswith('-') and (e.get('poste','').lower() in fl.lower() or e.get('entreprise','').lower() in fl.lower()):
        pb.append(f'Exp{i+1}: repetition titre')

if pi.get('linkedIn') or pi.get('portfolio'): ok.append('LinkedIn/GitHub saisi')
else: pb.append('LinkedIn/GitHub manquant')

# Titre court
titre = pi.get('titrePoste', '')
if len(titre.split()) > 6: pb.append(f'Titre trop long: "{titre}"')
else: ok.append(f'Titre OK: "{titre}"')

print(f"\nTITRE: {titre}")
print(f"\nRESUME:\n{resume[:250]}")
print(f"\nEXP 1 (debut):\n{exps[0].get('description','')[:200] if exps else 'N/A'}")
print(f"\nSKILLS: {sn}")
print(f"\nLANGUES: {[(l.get('langue'),l.get('niveau')) for l in langs]}")
print(f"\nLINKEDIN: {pi.get('linkedIn','')}")
print(f"GITHUB: {pi.get('portfolio','')}")

print(f"\n{'='*60}")
for o in ok: print(f'  [OK] {o}')
for p in pb: print(f'  [XX] {p}')
score = int(len(ok) / max(1, len(ok) + len(pb)) * 100)
print(f"\nSCORE: {score}% ({len(ok)} ok / {len(pb)} pb)")
print(f"\n>>> CV #{cv_id} — http://localhost:3001 <<<")
