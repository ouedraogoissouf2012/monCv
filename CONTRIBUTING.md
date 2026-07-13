# Contributing

## Prerequis

- Java 21
- Maven 3.9+
- Flutter stable `3.41.x`
- Docker Desktop
- PostgreSQL local ou `docker compose`

## Setup local

### Backend

```bash
cd backend
cp .env.example .env
mvn spring-boot:run
```

### Flutter

```bash
cd mobile
flutter pub get
flutter run -d chrome --web-port=3001
```

### Stack complete Docker

```bash
cp .env.example .env
docker compose up -d
```

## Tests

### Backend

```bash
cd backend
mvn verify
```

### Flutter

```bash
cd mobile
flutter analyze --no-fatal-infos
flutter test --concurrency=1
```

## Avant de proposer une PR

- verifier que les docs impactees sont a jour ;
- ne jamais committer de secrets ;
- lancer `pre-commit run --all-files` si `pre-commit` est configure localement ;
- garder les changements limites a l'issue traitee.

## Convention de branches

- `feat/issue-XXX-...`
- `fix/issue-XXX-...`
- `docs/issue-XXX-...`

## PR checklist

- resume clair du changement
- preuve de validation locale ou CI
- impact config / migration / securite documente
- capture ou exemple API si le comportement visible change

## Documentation a tenir a jour

- `docs/CONFIGURATION.md` pour toute nouvelle variable
- `docs/DATABASE.md` pour toute migration Flyway
- `docs/RUNBOOK.md` pour toute nouvelle procedure ops
- `CHANGELOG.md` pour tout changement notable
