<!-- Merci pour votre PR ! Remplissez les sections ci-dessous. -->

## Résumé
<!-- 1-3 phrases : que fait ce PR et pourquoi. -->

## Issue liée
<!-- Closes #XXX (obligatoire pour les corrections / features). Si pas d'issue, expliquer pourquoi. -->
Closes #

## Type de changement
<!-- Cocher les cases pertinentes -->
- [ ] 🐛 Bug fix (changement non-breaking qui corrige un bug)
- [ ] ✨ Feature (changement non-breaking qui ajoute une fonctionnalité)
- [ ] 💥 Breaking change (fix ou feature qui change le comportement existant)
- [ ] ♻️ Refactor (pas de changement de comportement)
- [ ] 🔒 Sécurité
- [ ] 📚 Documentation
- [ ] 🧪 Tests
- [ ] 🚀 Performance / observabilité

## Critères d'acceptation
<!-- Recopier la checklist de l'issue liée. Cocher au fur et à mesure. -->
- [ ] ...

## Tests
- [ ] Tests unitaires ajoutés / mis à jour
- [ ] Tests d'intégration ajoutés / mis à jour si pertinent
- [ ] `mvn verify` passe localement (backend)
- [ ] `flutter analyze` ne renvoie aucune erreur (mobile)
- [ ] `flutter test` passe (mobile)
- [ ] Smoke test manuel décrit ci-dessous

### Plan de test manuel
<!-- Steps pour reproduire / valider en local. Ex:
1. docker compose up
2. curl localhost:8082/api/ai/status
3. Importer un CV PDF dans l'app web
-->

## Sécurité
- [ ] Pas de secret commité (vérifié avec `gitleaks` local)
- [ ] Pas de PII loguée
- [ ] Validation des entrées utilisateur (si applicable)
- [ ] CORS / CSRF / Auth checkés (si endpoint nouveau)

## Captures (UI changes)
<!-- Avant / Après si changement visuel -->

## Notes pour le reviewer
<!-- Points d'attention particuliers, décisions architecturales, alternatives écartées -->

🤖 Generated with [Claude Code](https://claude.com/claude-code)
