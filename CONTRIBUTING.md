# Contributing

## Prerequis

- Java 21
- Maven 3.9+
- Flutter stable `3.41.x`
- Python 3.12+ (garde-fous qualite)
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

`mvn verify` impose 70% de couverture lignes globale. Toute nouvelle classe
metier dans `service/` ou `controller/` doit atteindre au moins 80%. Les
exceptions legacy sont listees explicitement dans `backend/pom.xml` et doivent
etre retirees des que les tests correspondants sont ajoutes.

### Flutter

```bash
cd mobile
flutter analyze --no-fatal-infos
flutter test --coverage --concurrency=1
dart run tool/check_coverage.dart --summary=coverage/summary.md
```

Le perimetre Flutter mesure doit conserver au moins 65% de couverture lignes.
Les sources generees et exceptions legacy sont documentees dans
`mobile/tool/coverage_excludes.txt`; toute nouvelle exclusion doit etre
justifiee dans la description de la PR.

### Internationalisation Flutter

Toute nouvelle string affichee dans l'interface doit etre ajoutee dans
`mobile/lib/l10n/app_fr.arb`, puis traduite dans `app_en.arb`. Ne placez pas de
texte utilisateur directement dans les widgets. Apres une modification des
fichiers ARB, executez `flutter gen-l10n` depuis `mobile/` et commitez les
fichiers de localisation generes.

### Politique de taille des sources

```bash
python tools/quality/check_source_lines.py
python -m unittest discover -s tools/quality/tests -p "test_*.py"
```

Tout fichier Dart ou Java maintenu doit contenir au plus 300 lignes physiques.
La baseline versionnee bloque la croissance des fichiers legacy et doit etre
reduite, puis supprimee, pendant le traitement de l'issue proprietaire. Il est
interdit d'augmenter une baseline ou d'ajouter une nouvelle exception legacy.
Les trois sorties `app_localizations*.dart` sont les seules exceptions generees
et leur signature `gen-l10n` est verifiee automatiquement.

## Avant de proposer une PR

- verifier que les docs impactees sont a jour ;
- ne jamais committer de secrets ;
- lancer `pre-commit run --all-files` si `pre-commit` est configure localement ;
- lancer `python tools/quality/check_source_lines.py` ;
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
