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
| `RATE_LIMIT_ENABLED` | bool | non | `true` | Active la limitation de debit. |
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

## Regles d'exploitation

- profil `test` : PostgreSQL 17 Testcontainers, mocks et secrets non productifs ;
- profil `prod` : pas de fallback silencieux sur les secrets critiques ;
- le deploiement Compose exige `TAG` avec le SHA Git complet des deux images ;
- Adminer exige explicitement le profil `dev-tools`, qui ne doit jamais etre active en production ;
- toute nouvelle variable doit etre ajoutee dans :
  - le fichier exemple correspondant au mode d'execution
  - ce document
  - le runbook si elle impacte l'ops
