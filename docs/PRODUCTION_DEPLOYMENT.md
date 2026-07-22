# Deploiement production MonCV

Ce guide couvre la publication des images, le deploiement Compose, le rollback
et la rotation des secrets. Le contrat des variables est centralise dans
[`CONFIGURATION.md`](CONFIGURATION.md).

## Principes

- les images backend et web utilisent le meme SHA Git complet ;
- aucun secret n'est place dans la ligne de commande ou dans Git ;
- le preflight passe avant tout `pull` ou `up` ;
- seul le frontend ecoute sur la loopback de l'hote ;
- PostgreSQL et Redis restent sur un reseau Docker interne ;
- le profil `dev-tools`, qui contient Adminer, n'est jamais active.

## Prerequis

- serveur Linux avec Docker et Docker Compose compatible `!override`/`!reset` ;
- Python et `uv` pour le preflight ;
- reverse proxy installe sur l'hote pour TLS ;
- acces en lecture aux images GHCR backend et web ;
- sauvegarde PostgreSQL testee avant la premiere mise en production.

## Contrat requis

Copiez `.env.production.example` vers `.env.production`. Les champs critiques
restent volontairement vides dans l'exemple afin qu'une copie brute echoue.

| Variable | Contrainte |
| --- | --- |
| `TAG` | SHA Git complet de 40 caracteres, commun aux deux images |
| `DB_USERNAME`, `DB_PASSWORD` | Identifiants PostgreSQL dedies |
| `GOOGLE_CLIENT_ID` | Client OAuth Web autorise pour le domaine |
| `JWT_SECRET` | Secret aleatoire d'au moins 256 bits |
| `JWT_EXPIRATION` | Duree du jeton d'acces en millisecondes |
| `JWT_REFRESH_EXPIRATION` | Duree du refresh en millisecondes |
| `ALLOWED_ORIGINS` | Liste exacte d'origines HTTPS |
| `DEEPSEEK_API_KEY` | Cle du fournisseur IA |
| `PUBLIC_LINK_ENCRYPTION_KEY` | Valeur Base64 de 32 octets |
| `PUBLIC_MEDIA_ALLOWED_ORIGINS` | Liste exacte d'origines HTTPS |

Compose fixe le profil `prod`, desactive le SQL et le fallback IA, active le
rate limiting et interdit le bypass administrateur.

## Preparer et valider

```bash
cp .env.production.example .env.production
chmod 600 .env.production
# Remplir les champs vides depuis le gestionnaire de secrets.
# TAG doit correspondre exactement a: git rev-parse HEAD

uv run --locked python -m tools.deployment.compose_contract \
  --env-file .env.production
```

Le preflight rend Compose en memoire et ne journalise aucune valeur. N'envoyez
jamais la sortie de `docker compose config` vers un log : elle contient les
secrets interpoles.

## Publier les images

Depuis un checkout propre de `origin/main`, authentifie a GHCR :

```powershell
.\tools\release_local.ps1 publish
```

La commande rejoue les tests, construit et scanne les deux images, puis les
publie uniquement sous le SHA complet. Elle ne produit ni `latest`, ni tag de
version mutable. Le manifeste local se trouve sous `.release/<sha>/manifest.json`.

## Deployer

```bash
docker login ghcr.io

docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml \
  pull postgres redis backend web

docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml \
  up -d --remove-orphans postgres redis backend web

docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml ps
```

Verifiez ensuite le port loopback configure, `8080` par defaut, puis la sante
interne du backend :

```bash
curl --fail http://127.0.0.1:8080/healthz
docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml \
  exec -T backend wget -qO- http://127.0.0.1:8082/actuator/health/readiness
```

Le reverse proxy hote termine TLS et transmet vers `127.0.0.1:WEB_PORT`.
PostgreSQL, Redis et le backend ne possedent aucun port hote.

## Rollback applicatif

1. Remplacez `TAG` par le SHA complet precedemment valide.
2. Rejouez le preflight.
3. Executez `pull backend web` avec les deux fichiers Compose.
4. Executez `up -d backend web` avec le meme fichier d'environnement.
5. Verifiez `/healthz`, la readiness et les logs applicatifs.

Ne retrogradez pas PostgreSQL ou Flyway sans restauration testee. Un rollback
applicatif exige que le schema courant reste compatible avec l'ancien binaire.

## Rotation des secrets

### JWT

Generez un secret avec `openssl rand -base64 64` dans une session protegee,
mettez a jour le gestionnaire de secrets et `.env.production`, puis rejouez le
preflight et `up -d backend`. La rotation invalide toutes les sessions actives.

### Cle IA

1. Creez la nouvelle cle chez le fournisseur.
2. Mettez a jour la source de secrets et redeployez le backend.
3. Validez la readiness et un appel controle.
4. Revoquez l'ancienne cle seulement apres validation.

### Mot de passe PostgreSQL

Coordonnez le changement du role PostgreSQL et du fichier secret pour limiter
l'interruption. Validez le nouveau deploiement avant de supprimer tout ancien
role ou droit d'acces.

## Diagnostic

### Le preflight echoue

Il indique une regle sans afficher sa valeur, ou une erreur generique si
Compose ne peut pas rendre les fichiers. Verifiez les champs vides, le SHA et
les permissions `0600`; ne publiez jamais le fichier pour demander de l'aide.

### Le backend ne devient pas pret

```bash
docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml \
  logs --tail=200 backend
```

Recherchez une configuration rejetee, une connexion DB impossible ou une
migration Flyway en echec. Les valeurs sensibles doivent rester masquees.

### Verifier Flyway

```bash
docker compose --env-file .env.production \
  -f docker-compose.yml -f docker-compose.prod.yml \
  exec -T postgres sh -c \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT * FROM flyway_schema_history;"'
```

N'executez `repair` qu'apres analyse de la migration et sauvegarde verifiee.

## Observabilite

Le frontend expose `/healthz` sur la loopback. Les probes backend
`/actuator/health/liveness` et `/actuator/health/readiness` sont interrogees
depuis le reseau interne. Les logs de production sont structures en JSON et ne
doivent contenir ni jeton, ni mot de passe, ni contenu de fichier `.env`.
