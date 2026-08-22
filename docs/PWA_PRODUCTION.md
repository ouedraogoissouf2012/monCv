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
  --dart-define=API_BASE_URL=/api
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
| `ALLOWED_ORIGINS` | Oui en prod | `https://app.moncv.com` | Origines PWA autorisees par CORS |
| `JWT_SECRET` | Oui en prod | secret 32+ caracteres | Signature des tokens, jamais en dur |
| `JWT_EXPIRATION` | Recommande | `3600000` | Duree courte access token web |
| `JWT_REFRESH_EXPIRATION` | Recommande | `604800000` | Duree refresh token |
| `DEEPSEEK_API_KEY` | Si IA active | valeur secrete | Cle fournisseur IA, jamais exposee au frontend |

Regles :

- En production web, `/api` est recommande : Nginx relaie l'API sur la meme origine.
- Une URL absolue reste possible mais doit commencer par `https://`.
- En production, `API_BASE_URL` ne doit pas etre vide.
- En developpement web, l'application peut encore utiliser `http://localhost:8082/api`.
- Aucun secret backend ne doit etre injecte dans le build Flutter Web.

## Confidentialite et securite PWA

- La page `/privacy` explique les donnees stockees, l'usage de l'IA, l'export et la suppression.
- Les appels IA sensibles exigent un consentement explicite dans l'interface et dans l'API (`aiConsentAccepted=true`).
- Le profil permet d'exporter les donnees utilisateur au format JSON via `/api/users/me/export`.
- `DELETE /api/users/me` supprime le compte et les CV rattaches grace au cascade JPA.
- Les logs applicatifs doivent rester techniques: ids, statuts et erreurs; ne pas journaliser contenu de CV, tokens, prompts IA, reponses IA completes ou fichiers importes.
- Le stockage token web utilise le stockage local du navigateur via `shared_preferences_web`; court terme: expiration JWT courte, HTTPS obligatoire, CORS strict. Cible entreprise: session serveur avec cookies `HttpOnly`, `Secure`, `SameSite=Lax/Strict` et rotation refresh token.
- Les endpoints `/api/auth/*`, `/api/ai/*` et `/api/cvs/public/*` ont une limite par IP en memoire. En production multi-instance, remplacer par Redis/Bucket4j.

## Configuration backend

Le backend doit autoriser le domaine de la PWA :

```bash
ALLOWED_ORIGINS=https://app.moncv.com,https://www.moncv.com
```

Le conteneur web fourni sert le bundle et relaie `/api` vers le backend. Il applique CSP,
HSTS, les protections anti-framing et une politique de cache adaptee au service worker.

Le bundle Flutter n'est versionne par aucun hash de nom de fichier : `main.dart.js` et
`flutter_bootstrap.js` gardent la meme URL d'un build a l'autre. Les reponses sont donc
servies avec `Cache-Control: no-cache`, qui conserve la copie locale mais impose une
revalidation. nginx repond `304` sans corps tant que le contenu n'a pas change, et sert
la nouvelle version des le deploiement suivant, sans delai d'expiration.

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
