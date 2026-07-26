# Runbook MonCV

## 1. Lancement local

### Backend seul

```bash
cd backend
cp .env.example .env
mvn spring-boot:run
```

### Flutter web

```bash
cd mobile
flutter pub get
flutter run -d chrome --web-port=3001
```

### Stack Docker complete

```bash
cp .env.example .env
docker compose up -d
docker compose ps
```

Services attendus :

- backend : `http://localhost:8082`
- postgres : `localhost:5432`
- adminer : `http://localhost:8081`

## 2. Deploiement production

Reference detaillee : `DEPLOYMENT.md`.

Sequence recommande :

1. verifier la branche / tag a deployer ;
2. confirmer les secrets requis (`DB_PASSWORD`, `JWT_SECRET`, `ALLOWED_ORIGINS`, `DEEPSEEK_API_KEY`) ;
3. lancer la pipeline CI si disponible ;
4. construire et publier l'image backend ;
5. deployer le backend avec `SPRING_PROFILES_ACTIVE=prod` ;
6. verifier `health/readiness`, logs, metriques et Swagger desactive ;
7. deployer le build Flutter web/PWA avec les bons `--dart-define`.

## 3. Rollback

### Backend

1. identifier la derniere image saine ;
2. redeployer cette image ;
3. verifier readiness + liveness ;
4. surveiller les erreurs et le trafic.

### Flutter web

1. republier le bundle precedent ;
2. verifier que `API_BASE_URL` et `APP_ENV` sont coherents ;
3. tester login + liste CV + export PDF.

## 4. Circuit breaker IA

Inspection :

```bash
curl -H "Authorization: Bearer <admin-token>" \
  http://localhost:8082/actuator/circuitbreakers
```

Controle d'un breaker :

```bash
curl -H "Authorization: Bearer <admin-token>" \
  http://localhost:8082/actuator/circuitbreakers/ai-deepseek
```

Remise en etat operationnel :

- attendre la fin de `wait-duration-in-open-state` si la panne fournisseur est externe ;
- si l'ecriture Actuator est active dans l'environnement cible, utiliser l'endpoint
  `/actuator/circuitbreakers/ai-deepseek/state` selon la politique ops locale ;
- sinon, redemarrer proprement le backend apres verification que le fournisseur IA est revenu.

## 5. Lecture des logs

Chercher le `X-Correlation-Id` renvoye au client, puis filtrer les logs avec cette valeur.

Exemples :

### Loki

```text
{app="moncv-backend"} |= "correlationId=abc-123"
```

### CloudWatch Logs Insights

```text
fields @timestamp, @message
| filter @message like /abc-123/
| sort @timestamp desc
```

En `prod`, les logs backend sont structures JSON.

## 6. Procedures incident

### PostgreSQL indisponible

Symptomes :

- `/actuator/health/readiness` DOWN
- erreurs JDBC / Hikari
- creation ou lecture CV en echec

Actions :

1. verifier la sante du service PostgreSQL ;
2. verifier connectivite reseau + credentials ;
3. verifier l'etat Flyway au demarrage ;
4. rollback applicatif seulement si la panne est liee au dernier deploy.

### Fournisseur IA indisponible

Symptomes :

- erreurs `AI_PROVIDER_DOWN`, `AI_TIMEOUT`, `AI_QUOTA_EXCEEDED`
- circuit breaker ouvert

Actions :

1. verifier `/api/ai/status` ;
2. verifier la cle et le quota du fournisseur ;
3. observer le fallback mock si active ;
4. remettre en route le circuit breaker une fois la cause levee.

### CV non generable en PDF / DOCX

Symptomes :

- erreur `PDF_GENERATION_ERROR`
- export DOCX vide ou 500

Actions :

1. rejouer avec un CV simple ;
2. verifier les logs par correlation ID ;
3. verifier presence des champs obligatoires / donnees importees ;
4. verifier que l'upload photo n'introduit pas un contenu invalide.

## 7. Contacts on-call

- Owner produit / depot : `@ouedraogoissouf2012`
- Escalade backend : mainteneur Spring Boot du sprint courant
- Escalade mobile : mainteneur Flutter du sprint courant

Avant mise en production multi-personnes, remplacer ces lignes par une rotation formelle et des contacts hors GitHub.

## 8. Securite des workflows CI

### Modele de menace et frontieres de confiance

Une branche interne, un fork et chaque fichier de la PR sont consideres non fiables,
y compris les manifests Maven/Flutter, scripts, Dockerfile et workflows modifies.
Les jobs qui compilent, testent ou analysent ce contenu declarent uniquement
'contents: read'; ils ne recoivent ni secret de production, ni OIDC, ni droit
d'ecriture. Tous leurs checkouts utilisent 'persist-credentials: false'.

Les operations privilegiees utilisent une definition chargee depuis la branche par
defaut via 'workflow_run' :

- `ci-reports.yml` ne checkout aucun code; ses jobs Codecov n'executent aucune
  commande issue du candidat et le commentaire passe par un controle du SHA puis
  un resume LCOV borne ;
- 'ci.yml' appelle 'container-verify.yml' apres les tests backend/frontend; le
  workflow reutilisable scanne les deux images sans permission d'ecriture ;
- 'publish.yml' attend le succes complet de 'ci.yml', telecharge les images verifiees
  sur 'main', refuse un SHA devenu obsolete, puis autorise uniquement 'docker load',
  'tag' et 'push' ; ses executions sont serialisees pour proteger le tag 'latest' ;
- sur un tag 'v*', 'ci.yml' appelle 'release-apk.yml' seulement apres le smoke test
  et le scan des conteneurs ;
- 'source-policy.yml' utilise 'pull_request_target' uniquement pour traiter la PR
  comme des donnees avec le script de la base. Il n'execute aucun script, hook ou
  gestionnaire de dependances venant de 'candidate/'.

'tools/ci/check_workflow_security.py', execute depuis la base de confiance, bloque
les permissions inattendues, les contextes 'secrets', les actions non verifiees et
l'execution candidate sous 'pull_request_target'. 'CODEOWNERS' designe un responsable
pour '/.github/workflows/' et '/tools/ci/'; la protection de 'main' doit exiger sa
revue pour rendre cette responsabilite obligatoire.

### Inventaire secrets et permissions

| Workflow / job | Entree non fiable executee | Secret ou capacite | Permissions |
|---|---|---|---|
| 'ci.yml / source-policy' | scripts Python de la revision | aucun | 'contents: read' |
| 'ci.yml / backend' | Maven et tests | JWT public 'MonCV-CI-ONLY-*' | 'contents: read' |
| 'ci.yml / frontend' | Flutter, Dart et tests | aucun | 'contents: read' |
| 'ci.yml / web-smoke' | backend et Flutter | DB locale 'test', JWT public 'MonCV-SMOKE-ONLY-*' | 'contents: read' |
| 'container-verify.yml / docker-verify' | Dockerfiles et images | aucun | 'contents: read' |
| 'security.yml / gitleaks' | contenu Git analyse comme donnees | 'github.token' en lecture | 'contents: read' |
| 'source-policy.yml' (3 jobs) | donnees JSON/ARB/YAML seulement | aucun | 'contents: read' |
| 'ci-reports.yml / backend-codecov' | artefact Jacoco seulement | OIDC Codecov | 'actions: read', 'contents: read', 'id-token: write' |
| 'ci-reports.yml / frontend-codecov' | artefact LCOV seulement | OIDC Codecov | 'actions: read', 'contents: read', 'id-token: write' |
| 'ci-reports.yml / flutter-coverage-comment' | resume Markdown seulement | 'github.token' borne a la PR | 'actions: read', 'contents: read', 'pull-requests: write' |
| 'publish.yml / docker-publish' | archive des deux images deja scannees | 'github.token' ephemere | 'actions: read', 'contents: read', 'packages: write' |
| 'release-apk.yml / build-apk' | revision d'un tag release | aucun | 'contents: read' |

Les deux JWT CI sont des valeurs deterministes, publiques et marquees non-production.
Aucune expression 'secrets.*' n'est admise dans les workflows. Les secrets de
production restent dans le systeme de deploiement ou un environnement GitHub
protege qui n'est jamais reference par un job PR.

### Actions epinglees et verification

Chaque 'uses:' pointe vers un SHA complet verifie avec
'git ls-remote https://github.com/OWNER/REPO.git refs/tags/TAG refs/tags/TAG^{}'.
Pour un tag annote, le SHA apres '^{}' est utilise.
La version Flutter est definie une seule fois dans 'mobile/.fvmrc'; CI, APK,
validation locale et image Docker doivent respecter cette valeur exacte.

| Action | Tag documente | SHA execute |
|---|---|---|
| actions/checkout | v4.3.1 | 34e114876b0b11c390a56381ad16ebd13914f8d5 |
| actions/setup-python | v5.6.0 | a26af69be951a213d495a4c3e4e4022e16d87065 |
| actions/setup-java | v4.8.0 | c1e323688fd81a25caa38c78aa6df2d33d3e20d9 |
| actions/upload-artifact | v4.6.2 | ea165f8d65b6e75b540449e92b4886f43607fa02 |
| astral-sh/setup-uv | v6.8.0 | d0cc045d04ccac9d8b7881df0226f9e82c39688e |
| actions/download-artifact | v4.3.0 | d3f86a106a0bac45b974a628896c90dbdf5c8093 |
| codecov/codecov-action | v5.5.5 | 0fb7174895f61a3b6b78fc075e0cd60383518dac |
| subosito/flutter-action | v2.23.0 | 1a449444c387b1966244ae4d4f8c696479add0b2 |
| marocchino/sticky-pull-request-comment | v3.0.5 | 5770ad5eb8f42dd2c4f34da00c94c5381e49af88 |
| docker/setup-buildx-action | v3.12.0 | 8d2750c68a42422c14e847fe6c8ac0403b4cbd6f |
| docker/build-push-action | v5.4.0 | ca052bb54ab0790a636c9b5f226502c73d547a25 |
| aquasecurity/trivy-action | v0.36.0 | ed142fd0673e97e23eac54620cfb913e5ce36c25 |
| docker/login-action | v3.7.0 | c94ce9fb468520275223c153574b00df6fe4bcc9 |
| gitleaks/gitleaks-action | v2.3.9 | ff98106e4c7b2bc287b24eaf42907196329070c7 |

### Test adversarial

Validation locale :

~~~bash
python -m unittest discover -s tools/ci/tests -p "test_*.py"
python -m tools.ci.check_workflow_security
~~~

La suite cree des workflows hostiles temporaires qui tentent de lire
`${{ secrets.JWT_SECRET }}`, d'obtenir `id-token: write`, une permission d'ecriture
ou d'executer `candidate/steal.py`. Chacun doit etre refuse. Pour un test GitHub,
ouvrir une PR jetable avec un probe dans un job sans JWT et verifier que
`JWT_SECRET`, `ACTIONS_ID_TOKEN_REQUEST_URL` et `ACTIONS_ID_TOKEN_REQUEST_TOKEN`
sont vides. Dans les jobs backend et smoke, seul le JWT public marque
`NOT-PRODUCTION` peut etre present; les deux variables OIDC restent vides. Toute
tentative d'ajouter `secrets.*` ou `id-token: write` doit faire echouer
`Trusted CI security policy`. Ne jamais afficher ni exfiltrer une valeur.

Les workflows de confiance 'ci-reports.yml', 'publish.yml' et 'source-policy.yml'
sont figes par empreinte SHA-256 normalisee. Pour les faire evoluer, utiliser deux PR :

1. ajouter d'abord l'empreinte du futur fichier a la politique, sans changer le
   workflow ;
2. apres fusion, modifier le workflow et retirer l'ancienne empreinte.

La politique de la branche de base valide ainsi chaque transition avant qu'un
workflow disposant d'OIDC ou d'une permission d'ecriture puisse changer.

### Rotation apres exposition ou doute

1. Suspendre les publications et inventorier les noms avec
   'gh secret list --repo ouedraogoissouf2012/monCv', sans afficher les valeurs.
2. Si 'JWT_SECRET' existe encore comme secret du depot, faire tourner d'abord la cle
   dans le systeme de deploiement, invalider les sessions, puis supprimer la copie CI
   avec 'gh secret delete JWT_SECRET --repo ouedraogoissouf2012/monCv'.
3. Faire tourner 'DB_PASSWORD', 'DEEPSEEK_API_KEY', PAT et cle Codecov eventuels chez
   leurs fournisseurs; supprimer 'CODECOV_TOKEN' car les uploads utilisent OIDC.
4. Revoquer toute relation OIDC suspecte. La relation retablie doit accepter seulement
   le depot attendu et le workflow de confiance sur 'refs/heads/main', jamais une
   reference 'refs/pull/*'.
5. Examiner les runs, logs et artefacts de la fenetre d'exposition, supprimer les
   artefacts sensibles, puis relancer Gitleaks et les validations CI.
6. 'github.token' est ephemere et ne se fait pas tourner; revoquer en revanche tout PAT
   persistant trouve dans un secret, un log ou un artefact.
