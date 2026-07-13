# Configuration MonCV

Ce document centralise les variables de configuration du backend Spring Boot, du stack Docker local et du build Flutter.

## Conventions

- les secrets ne doivent jamais etre commits ;
- `backend/.env.example` documente les variables backend locales ;
- `.env.example` a la racine documente le flux `docker compose` ;
- le frontend Flutter utilise principalement des `--dart-define`.

## Backend Spring Boot

| Variable | Type | Requise | Default | Description |
| --- | --- | --- | --- | --- |
| `SPRING_PROFILES_ACTIVE` | string | non | `dev` | Profil actif : `dev`, `test`, `prod`. |
| `DB_URL` | string | non en dev / oui en prod | `jdbc:postgresql://localhost:5432/cvmobile` | URL JDBC PostgreSQL. |
| `DB_USERNAME` | string | non en dev / oui en prod | `postgres` | Utilisateur PostgreSQL. |
| `DB_PASSWORD` | secret string | oui hors `test` | aucun | Mot de passe PostgreSQL. |
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
| `FIREBASE_NOTIFICATIONS_ENABLED` | bool | non | `false` | Active FCM cote backend. |
| `GOOGLE_APPLICATION_CREDENTIALS` | path | requise si Firebase active | aucun | Compte de service Google. |
| `STALE_CV_DAYS` | int | non | `30` | Seuil de CV stale pour les rappels. |
| `NOTIFICATION_REMINDER_CRON` | cron | non | `0 0 9 * * *` | Cron Spring des notifications. |
| `MANAGEMENT_PROMETHEUS_ALLOWED_IP_RANGES` | csv CIDR | non | `127.0.0.1/32,::1/128` | Allowlist IP pour `/actuator/prometheus`. |
| `SENTRY_DSN` | secret string | non | vide | Active Sentry / GlitchTip backend si defini. |
| `SENTRY_ENVIRONMENT` | string | non | valeur de `SPRING_PROFILES_ACTIVE` | Nom d'environnement remonte a Sentry. |

## Flutter / build web-mobile

| Variable | Type | Requise | Default | Description |
| --- | --- | --- | --- | --- |
| `APP_ENV` | string | non | `development` | Environnement Flutter. `production` force une API HTTPS explicite. |
| `API_BASE_URL` | url | oui si `APP_ENV=production` | `http://localhost:8082/api` en web local, `http://10.0.2.2:8082/api` hors web | Base URL de l'API. |
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

## Regles d'exploitation

- profil `test` : H2, mocks et secrets non productifs ;
- profil `prod` : pas de fallback silencieux sur les secrets critiques ;
- toute nouvelle variable doit etre ajoutee dans :
  - `backend/.env.example` ou `.env.example`
  - ce document
  - le runbook si elle impacte l'ops
