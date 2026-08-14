# Configuration MonCV

Ce document centralise les variables de configuration du backend Spring Boot, du stack Docker local et du build Flutter.

## Conventions

- les secrets ne doivent jamais etre commits ;
- `backend/.env.example` documente les variables backend locales ;
- `.env.example` a la racine documente le flux `docker compose` ;
- `.env.production.example` est le contrat Compose de production sans secret ;
- `.env`, `.env.production` et les autres `.env.*` reels sont ignores par Git ;
- le frontend Flutter utilise principalement des `--dart-define`.

## Backend Spring Boot

| Variable | Type | Requise | Default | Description |
| --- | --- | --- | --- | --- |
| `SPRING_PROFILES_ACTIVE` | string | non | `dev` | Profil actif : `dev`, `test`, `prod`. |
| `DB_URL` | string | non en dev / oui en prod | `jdbc:postgresql://localhost:5432/cvmobile` | URL JDBC PostgreSQL. |
| `DB_USERNAME` | string | non en dev / oui en prod | `postgres` | Utilisateur PostgreSQL. |
| `DB_PASSWORD` | secret string | oui hors `test` | aucun | Mot de passe PostgreSQL. |
| `GOOGLE_CLIENT_ID` | string | oui en prod | vide en dev | Identifiant OAuth Web Google. |
| `JWT_SECRET` | secret string | oui en prod | aucun en prod, valeur locale en dev | Secret JWT. |
| `JWT_EXPIRATION` | long | non | `86400000` | Duree du token d'acces en ms. |
| `JWT_REFRESH_EXPIRATION` | long | non | `604800000` | Duree du refresh token en ms. |
| `ALLOWED_ORIGINS` | csv string | oui en prod | aucun en prod | Origines CORS autorisees. |
| `SERVER_PORT` | int | non | `8082` | Port HTTP du backend. |
| `SHOW_SQL` | bool | non | `false` | Active l'affichage SQL en dev si branche. |
| `UPLOAD_DIR` | path | non | `${user.home}/cv-uploads/photos` | Dossier de stockage des photos. |
| `DEEPSEEK_API_KEY` | secret string | oui en prod | vide en dev | Cle API du fournisseur IA. |
| `AI_MODEL` | string | non | `deepseek-chat` | Modele IA. |
| `DEEPSEEK_BASE_URL` | url | non | `https://api.deepseek.com/v1` | Base URL du fournisseur. |
| `AI_FALLBACK_ENABLED` | bool | non | `true` | Active le fallback mock/local. |
| `RATE_LIMIT_ENABLED` | bool | non | `false` direct, `true` avec Compose | Active la limitation de debit. |
| `RATE_LIMIT_ADMIN_BYPASS` | bool | non | `true` | Autorise le bypass administrateur hors production. |
| `RATE_LIMIT_REDIS_URL` | URI | non | `redis://localhost:6379` | Stockage partage des compteurs. |
| `FIREBASE_NOTIFICATIONS_ENABLED` | bool | non | `false` | Active FCM cote backend. |
| `GOOGLE_APPLICATION_CREDENTIALS` | path | requise si Firebase active | aucun | Compte de service Google. |
| `STALE_CV_DAYS` | int | non | `30` | Seuil de CV stale pour les rappels. |
| `NOTIFICATION_REMINDER_CRON` | cron | non | `0 0 9 * * *` | Cron Spring des notifications. |
| `MANAGEMENT_PROMETHEUS_ALLOWED_IP_RANGES` | csv CIDR | non | `127.0.0.1/32,::1/128` | Allowlist IP pour `/actuator/prometheus`. |
| `PUBLIC_LINK_ENCRYPTION_KEY` | secret Base64 | oui en prod | aucun | Cle AES-256-GCM de recuperation des liens publics. |
| `PUBLIC_MEDIA_ALLOWED_ORIGINS` | csv URL | oui en prod | aucun | Origines historiques autorisees pour les photos de CV. |
| `SENTRY_DSN` | secret string | non | vide | Active Sentry / GlitchTip backend si defini. |
| `SENTRY_ENVIRONMENT` | string | non | valeur de `SPRING_PROFILES_ACTIVE` | Nom d'environnement remonte a Sentry. |

Generez `PUBLIC_LINK_ENCRYPTION_KEY` avec `openssl rand -base64 32` ou, sous PowerShell :

```powershell
[Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
```

## Flutter / build web-mobile

| Variable | Type | Requise | Default | Description |
| --- | --- | --- | --- | --- |
| `APP_ENV` | string | non | `development` | Environnement Flutter. `production` force une API HTTPS explicite. |
| `API_BASE_URL` | url/path | oui si `APP_ENV=production` | `http://localhost:8082/api` en web local, `http://10.0.2.2:8082/api` hors web | URL HTTPS ou chemin web same-origin `/api`. |
| `SENTRY_DSN` | secret string | non | vide | Active `sentry_flutter` si fournie au build. |

Exemple :

```bash
flutter build web --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.example.com/api \
  --dart-define=SENTRY_DSN=https://public@example.ingest.sentry.io/1
```

## Docker Compose local

Le `.env` racine sert surtout au `docker compose` local.

Variables attendues :

- `SPRING_PROFILES_ACTIVE`
- `DB_URL`
- `DB_USERNAME`
- `DB_PASSWORD`
- `GOOGLE_CLIENT_ID`
- `JWT_SECRET`
- `JWT_EXPIRATION`
- `JWT_REFRESH_EXPIRATION`
- `ALLOWED_ORIGINS`
- `SERVER_PORT`
- `SHOW_SQL`
- `DEEPSEEK_API_KEY`
- `AI_MODEL`
- `DEEPSEEK_BASE_URL`
- `AI_FALLBACK_ENABLED`
- `UPLOAD_DIR`
- `FIREBASE_NOTIFICATIONS_ENABLED`
- `GOOGLE_APPLICATION_CREDENTIALS`
- `STALE_CV_DAYS`
- `NOTIFICATION_REMINDER_CRON`
- `MANAGEMENT_PROMETHEUS_ALLOWED_IP_RANGES`
- `PUBLIC_LINK_ENCRYPTION_KEY`
- `PUBLIC_MEDIA_ALLOWED_ORIGINS`
- `SENTRY_DSN`
- `SENTRY_ENVIRONMENT`

## Docker Compose production

Copiez `.env.production.example` vers `.env.production`, remplissez les champs
vides et limitez sa lecture au compte de deploiement. Sous Linux/macOS :

```bash
chmod 600 .env.production
```

Le contrat exige avant demarrage :

- `TAG`, SHA Git complet de 40 caracteres en minuscules ;
- `DB_USERNAME`, `DB_PASSWORD` et `GOOGLE_CLIENT_ID` ;
- `JWT_SECRET`, `JWT_EXPIRATION` et `JWT_REFRESH_EXPIRATION` ;
- `ALLOWED_ORIGINS` et `DEEPSEEK_API_KEY` ;
- `PUBLIC_LINK_ENCRYPTION_KEY` et `PUBLIC_MEDIA_ALLOWED_ORIGINS`.

`SPRING_PROFILES_ACTIVE=prod`, `SHOW_SQL=false`, `AI_FALLBACK_ENABLED=false`,
`RATE_LIMIT_ENABLED=true` et `RATE_LIMIT_ADMIN_BYPASS=false` sont fixes dans
`docker-compose.prod.yml` et ne sont pas configurables par le fichier secret.

Validez le fichier sans afficher le rendu Compose, qui contient les secrets :

```bash
uv run --locked python -m tools.deployment.compose_contract \
  --env-file .env.production
```

Le preflight ne renvoie jamais les valeurs : il indique la regle violee ou une
erreur generique si Compose refuse le rendu. Il verifie aussi les ports, les
reseaux, le profil Adminer et l'alignement des images backend/web.

Au demarrage, le backend applique une seconde barriere lorsque `prod` est
actif :

- `prod` doit etre le seul profil actif ;
- les origines CORS et media doivent etre des origines HTTPS strictes ;
- les placeholders, valeurs locales et secrets de faible diversite sont refuses ;
- la cle publique doit decoder exactement 32 octets et ne pas etre la cle locale ;
- l'URL fournisseur doit etre absolue, HTTPS et sans credentials ;
- le fallback IA et le bypass administrateur sont interdits, le rate limiting
  est obligatoire.

Une erreur ne contient que les noms de variables invalides, jamais leurs
valeurs, longueurs ou sources.

## Verification et runbook des secrets (production)

### Matrice de couverture

Pour chaque `${VAR}` interpolee dans `docker-compose.prod.yml`, cette table
recoupe sa presence dans `.env.production.example` et sa regle de validation
dans `ProductionConfigurationPolicy`, plus les deux preflights. Chaque cellule
cite `fichier:ligne` verifiables. Verdict `OK` = couverte a au moins une couche
bloquante ; toute absence est signalee explicitement.

| `${VAR}` (compose prod) | Garde compose | `.env.production.example` | `ProductionConfigurationPolicy` (boot) | Preflights (`compose_contract.py` presence / `check-prod-readiness.sh` sanite) | Verdict |
| --- | --- | --- | --- | --- | --- |
| `TAG` | `:?` SHA 40 (`prod.yml:26,60`) | `TAG=""` (`example:6`) | hors perimetre app | `contract.py:19-22,86-93` (regex + egalite images) / `readiness.sh:118-126` | **OK** |
| `WEB_PORT` | `:-8080` (`prod.yml:75`) | `WEB_PORT=8080` (`example:9`) | hors perimetre app | plage 1-65535 `readiness.sh:237-244` | **OK** |
| `DB_USERNAME` | `:?` (`prod.yml:12,36`) | `example:12` | `validDatabaseUser` (`policy:42-43`) | `contract.py:25,81-82` / `readiness.sh:128-137` | **OK** |
| `DB_PASSWORD` | `:?` (`prod.yml:13,37`) | `example:13` | `validSecret(16)` (`policy:40-41`) | `contract.py:26,83-84` / `readiness.sh:219` | **OK** |
| `GOOGLE_CLIENT_ID` | `:?` (`prod.yml:38`) | `example:16` | `validGoogleClient` (`policy:44-45`) | `contract.py:27` / `readiness.sh:220` | **OK** |
| `JWT_SECRET` | `:?` (`prod.yml:39`) | commentaire seul, **pas de cle** (`example:18`) | `validSecret(64)` (`policy:38-39`) | `contract.py:28` / `readiness.sh:221` | **OK** (note 1) |
| `JWT_EXPIRATION` | `:?` (`prod.yml:40`) | `=900000` (`example:19`) | hors perimetre app | `contract.py:29` / `readiness.sh:222` | **OK** |
| `JWT_REFRESH_EXPIRATION` | `:?` (`prod.yml:41`) | `=604800000` (`example:20`) | hors perimetre app | `contract.py:30` / `readiness.sh:223` | **OK** |
| `ALLOWED_ORIGINS` | `:?` (`prod.yml:42`) | `example:23` | `validOrigins` HTTPS strict (`policy:46-47`) | `contract.py:31` / `readiness.sh:224` | **OK** |
| `DEEPSEEK_API_KEY` | `:?` (`prod.yml:44`) | `example:26` | `validSecret(16)` (`policy:36-37`) | `contract.py:32` / `readiness.sh:225` | **OK** |
| `DEEPSEEK_BASE_URL` | `:-` https (`prod.yml:45`) | `example:27` | `validHttpsUri` (`policy:52-53`) | `contract.py:33` / `readiness.sh:230` (warn) | **OK** |
| `PUBLIC_LINK_ENCRYPTION_KEY` | `:?` (`prod.yml:50`) | `example:31` | `validEncryptionKey` Base64-32o (`policy:50-51`) | `contract.py:35` / `readiness.sh:226` | **OK** |
| `PUBLIC_MEDIA_ALLOWED_ORIGINS` | `:?` (`prod.yml:51`) | `example:32` | `validOrigins` (`policy:48-49`) | `contract.py:36` / `readiness.sh:227` | **OK** |
| `SENTRY_DSN` | `:-` vide (`prod.yml:52`) | `example:35` | optionnel | warn si vide `readiness.sh:231-236` | **OK** (optionnel) |

**Note 1 — `JWT_SECRET`.** L'exemple ne porte qu'un commentaire d'instruction
(`# Add the required JWT_SECRET after: openssl rand -base64 64`,
`.env.production.example:18`) au lieu d'une cle vide `JWT_SECRET=` comme les
autres secrets. C'est **non bloquant** : une valeur absente echoue bruyamment a
trois couches — garde compose `:?` (`docker-compose.prod.yml:39`), presence dans
le merge rendu par `compose_contract.py` (`REQUIRED_BACKEND_ENV`, ligne 28),
`check-prod-readiness.sh` (`readiness.sh:221`), puis le gate de boot
`ProductionConfigurationPolicy` (`policy:38-39`). C'est en revanche une
incoherence de forme avec le reste de l'exemple. Fichier hors du perimetre
d'edition de cette PR -> signale a l'orchestration.

**Flags fixes hors fichier secret.** `SPRING_PROFILES_ACTIVE`, `SHOW_SQL`,
`AI_FALLBACK_ENABLED`, `RATE_LIMIT_ENABLED`, `RATE_LIMIT_ADMIN_BYPASS`,
`RATE_LIMIT_REDIS_URL`, `DB_URL` et `SENTRY_ENVIRONMENT` sont codes en dur dans
`docker-compose.prod.yml` (`prod.yml:34-53`), pas fournis par l'operateur. Ils
sont valides par `compose_contract.py` (`SECURE_FLAGS`, lignes 38-44) et, pour
le profil et les booleens, par `ProductionConfigurationPolicy`. Ils sont donc
volontairement absents de la matrice operateur ci-dessus.

### Runbook de gestion des secrets

- **Provenance.** Les valeurs reelles sont posees par l'operateur depuis le
  gestionnaire de secrets de l'organisation (coffre type Vault, SOPS, secrets de
  l'orchestrateur). Ce depot ne contient jamais de valeur reelle : seulement le
  contrat (`.env.production.example`) et les regles de validation. Generation des
  valeurs cryptographiques : `JWT_SECRET` via `openssl rand -base64 64` ;
  `PUBLIC_LINK_ENCRYPTION_KEY` via `openssl rand -base64 32` (equivalent
  PowerShell plus haut) ; `DB_PASSWORD` et `DEEPSEEK_API_KEY` depuis leur source
  d'autorite respective.
- **Injection.** Deux modes exclusifs, jamais en clair sur la ligne de commande :
  (a) fichier `--env-file .env.production` en `0600`, lu uniquement pour
  l'interpolation `${VAR}` — aucun `env_file` n'est monte dans les conteneurs
  (`docker-compose.prod.yml:29`) ; (b) variables exportees dans l'environnement
  du process de deploiement par l'orchestrateur. `check-prod-readiness.sh` sans
  `--env` verifie ce second mode (variables du shell courant).
- **Rotation.** Procedures par secret (JWT, cle IA, mot de passe PostgreSQL)
  documentees dans
  [`PRODUCTION_DEPLOYMENT.md`](PRODUCTION_DEPLOYMENT.md#rotation-des-secrets) —
  non dupliquees ici.
- **Acces.** Lecture de `.env.production` restreinte au compte de deploiement
  (proprietaire, `0600` impose par `compose_contract.py:203-207`). Le
  gestionnaire de secrets applique le moindre privilege et l'audit d'acces. Tout
  depart d'un porteur de secret declenche une rotation.

### Checklist operateur pre-prod

Avant deploiement :

- [ ] Chaque variable requise de la matrice est posee depuis le gestionnaire de
  secrets, sans placeholder ni valeur d'exemple.
- [ ] `JWT_SECRET` ajoute explicitement (absent de l'exemple, cf. note 1),
  >= 64 caracteres, forte diversite.
- [ ] `TAG` = SHA Git complet 40 hex, identique backend/web, deja publie sur GHCR.
- [ ] `.env.production` en `0600`, proprietaire = compte de deploiement, jamais
  commite (ignore par Git, verifie avec `gitleaks`).
- [ ] Origines `ALLOWED_ORIGINS` / `PUBLIC_MEDIA_ALLOWED_ORIGINS` = HTTPS reelles
  (ni `*`, ni `http`, ni `localhost`, ni `example.com`).
- [ ] Sanite des valeurs :
  `sh tools/deployment/check-prod-readiness.sh --env .env.production` -> 0 FAIL.
- [ ] Contrat structurel :
  `uv run --locked python -m tools.deployment.compose_contract --env-file .env.production`
  -> valide.
- [ ] Aucune sortie de `docker compose config` journalisee : elle contient les
  secrets interpoles.

Apres deploiement :

- [ ] `sh tools/deployment/check-prod-readiness.sh --health <url>` -> readiness
  et liveness `UP`. Le boot reussi en profil `prod` reste le gate d'autorite.

### Outillage de verification (rappel)

| Outil | Perimetre | Docker requis |
| --- | --- | --- |
| `tools/deployment/compose_contract.py` | structure Compose + presence des vars + SHA/ports/reseaux/flags surs | oui (`uv` + `docker`) |
| `tools/deployment/check-prod-readiness.sh --env` | sanite des valeurs (longueur, placeholder, HTTPS, Base64-32, regex) | non |
| `tools/deployment/check-prod-readiness.sh --health` | probes actuator readiness/liveness d'une app deployee | non (`curl`) |
| `ProductionConfigurationPolicy` (boot) | gate d'autorite : refuse le demarrage `prod` si la config est invalide | — |

Les deux preflights et le gate sont complementaires, pas redondants : le premier
verifie la structure et la presence, le second la qualite des valeurs sans
docker, le troisieme est la barriere definitive au demarrage.

## Regles d'exploitation

- profil `test` : PostgreSQL 17 Testcontainers, mocks et secrets non productifs ;
- profil `prod` : pas de fallback silencieux sur les secrets critiques ;
- le deploiement Compose exige `TAG` avec le SHA Git complet des deux images ;
- Adminer exige explicitement le profil `dev-tools`, qui ne doit jamais etre active en production ;
- toute nouvelle variable doit etre ajoutee dans :
  - le fichier exemple correspondant au mode d'execution
  - ce document
  - le runbook si elle impacte l'ops
