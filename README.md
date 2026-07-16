# MonCV

[![CI](https://github.com/ouedraogoissouf2012/monCv/actions/workflows/ci.yml/badge.svg)](https://github.com/ouedraogoissouf2012/monCv/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/ouedraogoissouf2012/monCv/graph/badge.svg)](https://codecov.io/gh/ouedraogoissouf2012/monCv)
![Version](https://img.shields.io/badge/version-1.0.0-brightgreen)

MonCV est une plateforme de creation, adaptation et export de CV avec :

- un backend Spring Boot pour l'API, l'authentification, l'IA et la generation documentaire ;
- une application Flutter pour le web et le mobile ;
- un socle Docker local pour developper rapidement avec PostgreSQL.

## Demarrage rapide

### Backend local

```bash
cd backend
cp .env.example .env
mvn spring-boot:run
```

Sous Windows avec PostgreSQL et Redis lances dans Docker, utilisez la tache
VS Code `Backend local (PostgreSQL Docker)` ou :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_backend_local.ps1
```

Ce lanceur charge le fichier `.env`, puis utilise `localhost:5436` pour joindre
PostgreSQL et `localhost:6379` pour Redis. Le port dedie `5436` evite les
conflits avec un PostgreSQL natif sur `5432` et les noms DNS internes Docker
`postgres` et `redis` ne sont jamais transmis au processus Java local. Dans un
worktree sans secrets, il reutilise automatiquement le `.env` d'un autre
worktree du meme depot.

### Stack Docker locale

```bash
cp .env.example .env
docker compose up -d
```

### Flutter web local

```bash
cd mobile
flutter pub get
flutter run -d chrome --web-port=3001
```

Acces utiles :

- API : `http://localhost:8082`
- Swagger UI : `http://localhost:8082/swagger-ui.html`
- Health readiness : `http://localhost:8082/actuator/health/readiness`
- Adminer : `http://localhost:8081`

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Configuration](docs/CONFIGURATION.md)
- [Runbook](docs/RUNBOOK.md)
- [Security](docs/SECURITY.md)
- [Testing](docs/TESTING.md)
- [Database](docs/DATABASE.md)
- [API](docs/API.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)
- [Deployment detaille](DEPLOYMENT.md)
- [Guide de lancement](GUIDE_LANCEMENT.md)

## Repo layout

```text
backend/   API Spring Boot + PostgreSQL + Flyway + Resilience4j
mobile/    App Flutter web/mobile
docs/      Documentation technique et operationnelle
ops/       Artefacts ops (ex: dashboard Grafana)
```

## Qualite et securite

- tests backend et Flutter executes via GitHub Actions quand la CI est disponible ;
- scan secrets via `security.yml` + Gitleaks ;
- logs structures, correlation ID, metriques Prometheus et dashboard Grafana ;
- tracking d'erreurs Sentry/GlitchTip active uniquement si les DSN sont fournis.

## Versionnement

- migrations Flyway strictement incrementales ;
- merge sur `main` apres validation locale ou CI selon disponibilite ;
- historique des changements dans [CHANGELOG.md](CHANGELOG.md).
