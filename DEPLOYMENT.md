# Guide de developpement MonCV

Ce guide couvre uniquement l'execution locale. Pour publier, deployer, faire un
rollback ou tourner les secrets, consultez
[`docs/PRODUCTION_DEPLOYMENT.md`](docs/PRODUCTION_DEPLOYMENT.md).

## Prerequis

- Java 21 et Maven 3.9+
- Flutter 3.38.5 et Dart associe
- PostgreSQL 17 et Redis 7 pour une execution sans Docker
- Docker avec Docker Compose pour le stack conteneurise

## Backend sans Docker

```bash
cd backend
cp .env.example .env
# Remplir DB_PASSWORD, GOOGLE_CLIENT_ID et les valeurs locales requises.
mvn spring-boot:run
```

Le fichier `backend/.env` est reserve au developpement et ignore par Git. Le
backend utilise PostgreSQL sur le port configure et Redis sur
`redis://localhost:6379` par defaut.

Verifiez le demarrage :

```bash
curl --fail http://localhost:8082/actuator/health
```

Les logs indiquent si une configuration est absente, mais ne doivent jamais
contenir la valeur d'un secret.

## Stack local avec Docker

Depuis la racine du depot :

```bash
cp .env.example .env
# Remplir les valeurs locales dans .env.
docker compose up -d postgres redis backend
docker compose ps
docker compose logs -f backend
```

Le backend est disponible sur `http://localhost:8082`. Adminer reste optionnel :

```bash
docker compose up -d adminer
```

Commandes courantes :

```bash
# Reconstruire le backend apres une modification.
docker compose up -d --build backend

# Ouvrir une session PostgreSQL.
docker compose exec postgres psql -U postgres -d cvmobile

# Arreter le stack sans supprimer les donnees.
docker compose down

# Reset local destructif des volumes de developpement uniquement.
docker compose down -v
```

Ne lancez jamais `down -v` sur un environnement contenant des donnees utiles.

## Frontend Flutter local

```bash
cd mobile
flutter pub get --enforce-lockfile
flutter run -d chrome --web-port=3005 \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://localhost:8082/api
```

## Depannage local

### La cle IA n'est pas chargee

1. Lancez Maven depuis `backend/` pour que `backend/.env` soit charge.
2. Verifiez que le fichier est en UTF-8 sans BOM.
3. Controlez le statut via `/actuator/health` sans afficher la cle.
4. Si le fournisseur renvoie 401, remplacez la cle revoquee.

### Le backend ne joint pas PostgreSQL

```bash
docker compose ps postgres
docker compose logs --tail=100 postgres
```

Verifiez `DB_URL`, `DB_USERNAME` et `DB_PASSWORD` dans le fichier local. Ne
copiez pas leur valeur dans un ticket ou un journal partage.

### Une migration Flyway echoue

```bash
docker compose exec postgres psql -U postgres -d cvmobile \
  -c "SELECT * FROM flyway_schema_history;"
```

Analysez la migration en echec avant toute commande `repair`. La procedure de
production et les controles de rollback sont documentes separement.
