# MonCV - Deploiement PWA production

Ce guide decrit comment publier le frontend Flutter Web comme Progressive Web App installable, sans passer par le Play Store au lancement.

## Principe

- Le frontend Flutter est compile en bundle web statique.
- Le bundle doit etre servi en HTTPS.
- Le backend Spring Boot reste une API separee.
- Le frontend doit connaitre l'URL publique du backend via `API_BASE_URL`.
- En production, le fallback vers `localhost` est bloque par `APP_ENV=production`.

## Build local de verification

Depuis le dossier `mobile` :

```bash
flutter pub get
flutter build web --release \
  --pwa-strategy=offline-first \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.votre-domaine.com/api
```

Le bundle est genere dans :

```text
mobile/build/web
```

Si le chemin local contient des espaces ou accents et que Flutter echoue pendant la compilation des shaders, generer vers un dossier neutre :

```bash
flutter build web --release \
  --pwa-strategy=offline-first \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.votre-domaine.com/api \
  -o C:\tmp\moncv-web-build
```

## Variables frontend

| Variable | Obligatoire | Exemple | Role |
|----------|-------------|---------|------|
| `APP_ENV` | Oui en prod | `production` | Active les garde-fous production |
| `API_BASE_URL` | Oui en prod | `https://api.moncv.com/api` | URL publique de l'API |

Regles :

- En production, `API_BASE_URL` doit commencer par `https://`.
- En production, `API_BASE_URL` ne doit pas etre vide.
- En developpement web, l'application peut encore utiliser `http://localhost:8082/api`.

## Configuration backend

Le backend doit autoriser le domaine de la PWA :

```bash
ALLOWED_ORIGINS=https://app.moncv.com,https://www.moncv.com
```

Le backend doit aussi etre servi en HTTPS, par exemple derriere un reverse proxy ou une plateforme cloud.

## Fichiers PWA attendus

Apres le build, verifier la presence de :

```text
index.html
manifest.json
flutter_bootstrap.js
flutter_service_worker.js
main.dart.js
assets/
icons/
```

Le manifest doit conserver :

- `display: standalone`
- `start_url`
- icones 192 et 512 px
- icones maskable
- `prefer_related_applications: false`

## Verification navigateur

Checklist minimale :

- Ouvrir l'application en HTTPS.
- Verifier que l'API appelee est l'URL de production, pas `localhost`.
- Dans Chrome DevTools > Application, verifier le manifest.
- Dans Chrome DevTools > Application, verifier le service worker.
- Lancer Lighthouse et verifier la section PWA.
- Sur Android Chrome, verifier l'installation depuis le menu du navigateur.
- Sur desktop Chrome/Edge, verifier l'icone d'installation dans la barre d'adresse.

## Limites iOS

Sur iPhone, l'installation passe par Safari avec "Ajouter a l'ecran d'accueil". L'experience est utile pour un MVP, mais certaines capacites PWA peuvent rester plus limitees que sur Android/Chrome.

## CI

La CI compile un bundle web PWA avec :

```bash
flutter build web --release --no-pub --pwa-strategy=offline-first \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.moncv.example/api \
  -o build/web-pwa
```

Cette URL est reservee au test de compilation. Elle doit etre remplacee par le domaine reel lors du deploiement.
