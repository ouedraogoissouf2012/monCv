# MonCV Mobile

Application Flutter de creation, optimisation et export de CV professionnels.

## Lancement local web

```bash
flutter pub get
flutter run -d chrome --web-port=3001
```

Par defaut, le web local appelle :

```text
http://localhost:8082/api
```

## Build PWA production

```bash
flutter build web --release \
  --pwa-strategy=offline-first \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.votre-domaine.com/api
```

En production, `APP_ENV=production` bloque le fallback vers `localhost`. `API_BASE_URL` doit etre fourni et commencer par `https://`.

Voir aussi : `../docs/PWA_PRODUCTION.md`.
