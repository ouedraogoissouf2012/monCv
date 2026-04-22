# Guide de Déploiement — MonCV Backend

## Prérequis

- **Java 21** (Temurin recommandé)
- **Maven 3.9+**
- **Docker Desktop 24+** (pour le déploiement containerisé)
- **PostgreSQL 17** (si sans Docker)

---

## 1. Développement local — Sans Docker

### Setup initial

```bash
# 1. Cloner et entrer dans le projet
cd backend

# 2. Copier .env.example → .env et remplir les valeurs
cp .env.example .env
# Editer .env : mettre DEEPSEEK_API_KEY, DB_PASSWORD, etc.

# 3. Demarrer PostgreSQL (hors Docker)
# Windows : services.msc → PostgreSQL → Démarrer
# Ou créer la base manuellement : createdb cvmobile

# 4. Lancer le backend
mvn spring-boot:run
```

### Vérification du démarrage

Au démarrage, la **bannière de validation** s'affiche :

```
=== CV Mobile Startup Config ===
Profile: dev
DEEPSEEK_API_KEY ..... OK (source: dotenv, length=35)
JWT_SECRET ........... OK (source: dotenv, length=44)
DB_PASSWORD .......... OK (source: dotenv, length=5)
ALLOWED_ORIGINS ...... OK (source: application.yml, 4 origins)
================================
```

**Si un secret est MISSING** : voir la section [Troubleshooting](#troubleshooting) ci-dessous.

### Test de santé

```bash
curl http://localhost:8082/actuator/health

# Réponse attendue (profil dev, show-details: always) :
# {
#   "status": "UP",
#   "components": {
#     "db": { "status": "UP" },
#     "deepseek": {
#       "status": "UP",
#       "details": { "model": "deepseek-chat", "baseUrl": "..." }
#     },
#     "diskSpace": { "status": "UP" }
#   }
# }
```

---

## 2. Développement local — Avec Docker

### Setup

```bash
# À la racine du projet
cp backend/.env.example backend/.env
# Editer backend/.env avec vos valeurs

# Démarrer tout le stack (postgres + backend)
docker compose up -d

# Suivre les logs
docker compose logs -f backend

# Vérifier les health checks
docker compose ps
# NAME                  STATUS                    HEALTH
# cvmobile-backend     Up 30s                    healthy
# cvmobile-postgres    Up 45s                    healthy
```

### Commandes utiles

```bash
# Rebuild après modification du code
docker compose up -d --build backend

# Arrêter
docker compose down

# Arrêter et supprimer les volumes (reset DB)
docker compose down -v

# Accéder à la base postgres
docker compose exec postgres psql -U postgres -d cvmobile
```

---

## 3. Déploiement production

### Prérequis prod

- Serveur avec Docker installé (Linux recommandé)
- Un reverse proxy en amont (nginx, Caddy, Traefik) pour TLS
- Une base PostgreSQL gérée (RDS, Cloud SQL) ou sur le même serveur
- Accès au registre `ghcr.io/ouedraogoissouf2012/cv-mobile-backend`

### Variables d'environnement requises en prod

Ces variables **DOIVENT** être fournies par votre orchestrateur (Kubernetes secrets, Docker secrets, systemd EnvironmentFile, AWS SSM, etc.) :

| Variable | Description | Exemple |
|----------|-------------|---------|
| `SPRING_PROFILES_ACTIVE` | Doit être `prod` | `prod` |
| `DB_URL` | JDBC URL PostgreSQL | `jdbc:postgresql://db.host:5432/cvmobile` |
| `DB_USERNAME` | User DB | `cvmobile_app` |
| `DB_PASSWORD` | Mot de passe DB | `<strong_password>` |
| `JWT_SECRET` | Secret JWT (256+ bits) | `openssl rand -base64 64` |
| `DEEPSEEK_API_KEY` | Clé DeepSeek prod | `sk-...` |
| `ALLOWED_ORIGINS` | Origines CORS | `https://app.votredomaine.com` |

**⚠️ En prod, `AppStartupValidator` fait crash le backend si l'une de ces variables est manquante.** C'est voulu : pas de mode dégradé silencieux en prod.

### Déploiement via Docker Compose

```bash
# Sur le serveur
git pull  # ou télécharger juste docker-compose.yml + docker-compose.prod.yml

# Exporter les secrets (via votre solution de secrets management)
export SPRING_PROFILES_ACTIVE=prod
export DB_URL="jdbc:postgresql://postgres:5432/cvmobile"
export DB_PASSWORD="..."
export JWT_SECRET="..."
export DEEPSEEK_API_KEY="..."
export ALLOWED_ORIGINS="https://app.votredomaine.com"
export TAG="v1.0.0"  # tag de l'image à déployer

# Déployer
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Vérifier
curl http://localhost:8082/actuator/health/readiness
# { "status": "UP" }
```

### Publication d'une nouvelle version

```bash
# En local, tagger et pousser
git tag v1.0.1
git push origin v1.0.1

# Le workflow CI build et pousse automatiquement l'image sur GHCR :
# ghcr.io/ouedraogoissouf2012/cv-mobile-backend:v1.0.1
# ghcr.io/ouedraogoissouf2012/cv-mobile-backend:latest

# Sur le serveur
export TAG=v1.0.1
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull backend
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d backend
```

---

## 4. Rotation des secrets

### JWT_SECRET

La rotation invalide **toutes** les sessions actives (les utilisateurs devront se reconnecter).

```bash
# Générer un nouveau secret
NEW_SECRET=$(openssl rand -base64 64)

# Mettre à jour dans votre secrets manager, puis redéployer
export JWT_SECRET="$NEW_SECRET"
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d backend
```

### DEEPSEEK_API_KEY

1. Générer une nouvelle clé sur https://platform.deepseek.com/api_keys
2. Mettre à jour dans votre secrets manager
3. Redéployer le backend
4. Une fois vérifié, révoquer l'ancienne clé dans la console DeepSeek

### DB_PASSWORD

1. Changer le mot de passe sur la base : `ALTER USER cvmobile_app WITH PASSWORD 'new';`
2. Mettre à jour dans votre secrets manager
3. Redéployer

---

## 5. Troubleshooting

### "Mode hors ligne — clé DeepSeek manquante" (UI Flutter)

Cause : `DEEPSEEK_API_KEY` n'est pas chargée par le backend.

**Étape 1** : Vérifier la bannière de démarrage dans les logs backend :

```
=== CV Mobile Startup Config ===
Profile: dev
DEEPSEEK_API_KEY ..... MISSING (source: none)  ← voici le problème
```

**Étape 2** : Vérifier le health check :

```bash
curl http://localhost:8082/actuator/health
# Si "deepseek": { "status": "DOWN", "reason": "api-key-missing" }
# → la clé n'est pas chargée
```

**Étape 3** : Causes fréquentes et solutions :

| Symptôme | Cause | Solution |
|----------|-------|----------|
| `MISSING (source: none)` | `spring-dotenv` ne trouve pas `.env` | Lancez depuis `backend/` directement : `cd backend && mvn spring-boot:run` |
| `MISSING` mais `.env` existe | Fichier `.env` avec BOM UTF-8 | Re-sauvegarder en UTF-8 (pas UTF-8 BOM) via VSCode |
| `OK (source: dotenv)` mais health DOWN | Clé invalide | Vérifier la clé sur https://platform.deepseek.com |
| `OK` mais health `OUT_OF_SERVICE` | 401 de l'API DeepSeek | Clé révoquée ou expirée — régénérer |

### Le backend ne démarre pas en prod

```
IllegalStateException: Impossible de demarrer en profil 'prod' : secrets manquants [DEEPSEEK_API_KEY, JWT_SECRET]
```

**C'est voulu.** L'`AppStartupValidator` empêche le démarrage en prod sans les secrets critiques. Vérifier :

```bash
# Lister les variables passées au conteneur
docker compose -f docker-compose.yml -f docker-compose.prod.yml exec backend env | grep -E "DEEPSEEK|JWT|DB_"
```

### Erreur 500 sur `/api/cvs` après déploiement

Vérifier les migrations Flyway :

```bash
docker compose exec postgres psql -U postgres -d cvmobile -c "SELECT * FROM flyway_schema_history;"
```

Si une migration a échoué : logs backend + `repair` Flyway si nécessaire.

---

## 6. Architecture des profils

| Profil | Usage | Comportement sur secrets |
|--------|-------|--------------------------|
| `dev` | Local dev | Defaults permissifs, mode dégradé autorisé, actuator détaillé |
| `prod` | Production | **Fail-fast**, aucun default, actuator verrouillé, logs JSON |
| `test` | Tests automatisés | H2 in-memory, validator désactivé |

Contrôle via `SPRING_PROFILES_ACTIVE=<profil>` (env var) ou dans `.env`.

---

## 7. Monitoring & observabilité

### Endpoints Actuator

| Endpoint | Public | Description |
|----------|--------|-------------|
| `/actuator/health` | ✅ | Santé globale (DB + DeepSeek) |
| `/actuator/health/liveness` | ✅ | L'app répond (pour orchestrateur) |
| `/actuator/health/readiness` | ✅ | L'app + dépendances sont prêtes |
| `/actuator/info` | ✅ | Version de l'app |
| `/actuator/metrics` | 🔒 ADMIN | Métriques Micrometer |
| `/actuator/env` | 🔒 ADMIN | Variables d'environnement (dev only) |

### Logs en prod

Les logs sont en **JSON structuré** (via `logstash-logback-encoder`). Exemple :

```json
{"@timestamp":"2026-04-10T14:30:15.123Z","level":"INFO","logger":"com.cvmobile.service.CvService","message":"CV cree: id=42, userId=1","application":"cv-mobile-backend"}
```

Peut être ingéré par ELK, Datadog, Grafana Loki, etc.
