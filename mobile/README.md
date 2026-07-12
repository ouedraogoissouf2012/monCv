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
# Notifications push Firebase

Le code FCM est optionnel en local et s'active quand Firebase est configure :

1. Executer `flutterfire configure` dans ce dossier pour Android et iOS.
2. Activer Push Notifications et Background Modes dans Xcode, puis charger la cle APNs dans Firebase.
3. Sur le backend, definir `FIREBASE_NOTIFICATIONS_ENABLED=true` et fournir les identifiants avec `GOOGLE_APPLICATION_CREDENTIALS`.

Les fichiers `google-services.json`, `GoogleService-Info.plist` et les comptes de service sont ignores par Git. Ils ne doivent jamais etre commites.
