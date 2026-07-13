# Configuration du backend MonCV

Le backend lit sa configuration depuis les variables d'environnement Spring Boot. En local, copiez
`backend/.env.example` vers `backend/.env`. Le fichier `.env` est ignore par Git et ne doit jamais etre
committe.

En production, injectez les secrets avec le gestionnaire de secrets de l'orchestrateur. Ne placez pas
de secret de production dans une image Docker, un fichier versionne ou une variable du frontend.

## Variables obligatoires

| Variable | Dev | Prod | Description |
| --- | --- | --- | --- |
| `DB_PASSWORD` | Requise | Requise | Mot de passe PostgreSQL. Aucun default n'est accepte. |
| `JWT_SECRET` | Default dev-only | Requise | Signature JWT, 64 caracteres minimum et entropie superieure a 4 bits par caractere. |
| `ALLOWED_ORIGINS` | Default localhost | Requise | Origines CORS, separees par des virgules. |
| `DEEPSEEK_API_KEY` | Optionnelle | Requise | Cle de l'API DeepSeek. Le mode degrade est disponible en dev. |

Le profil `test` utilise H2, une cle JWT fixe non productive et des mocks. Il n'exige pas ces variables.

## Base de donnees

| Variable | Default | Description |
| --- | --- | --- |
| `DB_URL` | `jdbc:postgresql://localhost:5432/cvmobile` | URL JDBC PostgreSQL. |
| `DB_USERNAME` | `postgres` | Utilisateur PostgreSQL. |
| `DB_PASSWORD` | Aucun | Mot de passe PostgreSQL obligatoire hors profil `test`. |

## Application et serveur

| Variable | Default | Description |
| --- | --- | --- |
| `SPRING_PROFILES_ACTIVE` | `dev` | Profil actif : `dev`, `prod` ou `test`. |
| `SERVER_PORT` | `8082` | Port HTTP du backend. |
| `UPLOAD_DIR` | `${user.home}/cv-uploads/photos` | Repertoire des photos chargees. |
| `SHOW_SQL` | `false` | Affiche les requetes Hibernate en developpement. Toujours `false` en prod. |
| `ALLOWED_ORIGINS` | Localhost en dev, aucun en prod | Liste CORS separee par des virgules. |

## Authentification JWT

| Variable | Default | Description |
| --- | --- | --- |
| `JWT_SECRET` | Cle dev-only en profil `dev`, aucun en prod | Secret de signature JWT. |
| `JWT_EXPIRATION` | `86400000` | Duree du jeton d'acces en millisecondes, soit 24 heures. |
| `JWT_REFRESH_EXPIRATION` | `604800000` | Duree du refresh token en millisecondes, soit 7 jours. |

Generez un secret de production sans l'afficher dans les logs :

```bash
openssl rand -base64 64
```

## Intelligence artificielle

| Variable | Default | Description |
| --- | --- | --- |
| `DEEPSEEK_API_KEY` | Vide en dev, aucun en prod | Cle API du fournisseur DeepSeek. |
| `AI_MODEL` | `deepseek-chat` | Modele DeepSeek utilise. |
| `DEEPSEEK_BASE_URL` | `https://api.deepseek.com/v1` | URL de base du fournisseur. |
| `AI_FALLBACK_ENABLED` | `true` | Active le fournisseur de secours local. |

## Notifications

| Variable | Default | Description |
| --- | --- | --- |
| `FIREBASE_NOTIFICATIONS_ENABLED` | `false` | Active Firebase Cloud Messaging. |
| `GOOGLE_APPLICATION_CREDENTIALS` | Aucun | Chemin du compte de service Google, requis si Firebase est active. |
| `STALE_CV_DAYS` | `30` | Age d'un CV avant rappel. |
| `NOTIFICATION_REMINDER_CRON` | `0 0 9 * * *` | Planification Spring des rappels. |

## Monitoring

| Variable | Default | Description |
| --- | --- | --- |
| `MANAGEMENT_PROMETHEUS_ALLOWED_IP_RANGES` | `127.0.0.1/32,::1/128` | CIDR autorises pour `/actuator/prometheus`. |

Les probes `/actuator/health/liveness` et `/actuator/health/readiness` sont publiques. Les autres
endpoints Actuator exigent un administrateur, sauf Prometheus qui est controle par cette allowlist.

## Echec au demarrage

`AppStartupValidator` s'execute pendant l'initialisation du contexte Spring. Le demarrage est refuse :

- dans tout profil non-test lorsque `DB_PASSWORD` est absent ou vide ;
- en production lorsque `JWT_SECRET`, `ALLOWED_ORIGINS` ou `DEEPSEEK_API_KEY` est aussi absent ou vide.

Le validateur journalise le nom et la source des variables, jamais leur valeur.
