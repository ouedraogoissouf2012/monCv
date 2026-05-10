# Charte d'ingénierie — MonCV

> **Statut** : règles obligatoires.
> **Dernière révision** : 2026-05-08.
> **À réviser quand** : un anti-pattern récurrent apparaît, un nouveau membre rejoint l'équipe, ou tous les 6 mois minimum.

Ce document définit **comment on travaille** sur MonCV. Chaque contributeur (humain ou agent IA) doit le respecter à la lettre. Si une règle n'a plus de sens, on la modifie *par PR*, on ne la contourne pas.

---

## 1. Le mantra

> Code prêt à être audité demain. Code que 100 000 utilisateurs vont utiliser dans 10 ans.
>
> On est payé pour la fiabilité, pas pour la vitesse.

En cas de doute entre rapide et propre : **propre**. Toujours.

---

## 2. Hiérarchie des priorités (stricte)

Quand deux principes entrent en conflit, le rang supérieur l'emporte.

1. **Sécurité** — pas de fuite, pas de vuln, pas de PII en clair
2. **Correction** — le code fait ce qu'il prétend faire
3. **Lisibilité** — un nouveau dev comprend en 5 minutes
4. **Robustesse** — gestion d'erreurs, validation, fallback
5. **Maintenabilité** — modulaire, testable, sans dette
6. **Performance** — raisonnable d'abord, optimale ensuite
7. **Vélocité** — la moins importante

Si tu sacrifies un rang inférieur pour un rang supérieur, c'est OK. L'inverse jamais.

---

## 3. Workflow obligatoire pour toute modification non-triviale

**Définition "non-triviale"** : tout sauf typo dans un commentaire, renommage trivial, ou mise à jour `pubspec`/`pom` sans changement comportemental.

### 3.1 Phase 1 — Analyse (avant tout code)

Pour chaque tâche, écrire ces 4 sections (dans la PR description, le plan, ou un message à l'utilisateur) :

```markdown
## Étape 1 — Analyse
- **Objectif** : qu'est-ce qu'on essaie de résoudre, en 1 phrase
- **Contraintes** : sécurité, perf, métier, deadline
- **Risques** : ce qui peut mal tourner
- **Stratégie retenue** : approche choisie, alternatives écartées + pourquoi
```

Si la demande est ambiguë : **reformuler avant de coder**. Une question vaut mieux qu'un sprint refait.

### 3.2 Phase 2 — Workflow multi-agent (revue interne)

Pour toute PR non-triviale, **6 perspectives doivent passer** avant merge. Pour les agents IA : invoquer 6 sous-agents en parallèle. Pour les humains : passer mentalement par chacune avec un checklist.

| Rôle | Ce qu'il vérifie | Question pivot |
|------|------------------|----------------|
| **Planificateur** | Le besoin, les contraintes, les alternatives | "On résout vraiment le bon problème ?" |
| **Codeur** | Implémentation, lisibilité, nommage | "Un junior comprend en 5 min ?" |
| **Testeur** | Coverage ≥80% sur le nouveau code, tests utiles, edge cases | "Si je casse une ligne, un test échoue ?" |
| **Sécurité** | OWASP, secrets, validation entrées, auth, logs | "Que peut faire un attaquant ?" |
| **Architecte** | Couches, dépendances, séparation responsabilités | "Cette modif viole-t-elle la direction des dépendances ?" |
| **SOLID/DRY** | God classes, duplication, magic values, abstractions | "Si je change cette règle métier, combien d'endroits à toucher ?" |

**Règle non négociable** : si l'un des 6 trouve un problème **bloquant**, on ne merge pas. Le rôle "Sécurité" a un veto absolu.

### 3.3 Phase 3 — Vérification avant claim

> **Règle d'or** : ne jamais affirmer "fait", "testé", "vérifié", "passe", "fonctionne" sans avoir lancé la commande qui le prouve, vu sa sortie, et copié l'évidence.

Anti-patterns interdits (vécus dans ce projet) :
- "Les tests passent" → sans avoir lancé `mvn verify` / `flutter test`
- "Le fichier est à la ligne X" → sans avoir lu le fichier dans la session courante
- "Cette PR couvre Y" → sans avoir lu son diff
- "L'agent a audité Z" → sans avoir vu le rapport de l'agent

Si tu n'as pas l'évidence, tu écris "à vérifier" ou "non vérifié". Jamais de bluff.

---

## 4. Critères production-grade — checklist par PR

Chaque PR non-triviale doit cocher l'intégralité de cette liste avant merge :

### 4.1 Architecture & code
- [ ] Aucun fichier nouveau > 300 lignes (sauf justification écrite dans la PR)
- [ ] Aucune duplication de logique > 5 lignes (extraire en fonction/composant)
- [ ] Couches respectées : controller → service → repository → domain (jamais l'inverse)
- [ ] Interfaces utilisées pour les services métier (pas couplage à l'implémentation)
- [ ] Pas de magic numbers > 1 (sauf 0/1/-1) — utiliser `@ConfigurationProperties` ou constantes nommées
- [ ] Nommage explicite : un nom = une intention claire
- [ ] Commentaires uniquement sur le **pourquoi** non-évident, pas sur le **quoi**

### 4.2 Gestion d'erreurs
- [ ] Aucun `catch (Exception)` ou `catch (RuntimeException)` qui avale silencieusement
- [ ] Exceptions typées, pas génériques (`AiKeyInvalidException`, pas `RuntimeException`)
- [ ] Tous les chemins d'erreur testés
- [ ] Pas de `try { ... } catch (e) { return null }` ou équivalent (Result/Either typé)
- [ ] Messages d'erreur user-facing distincts des messages logs (pas de `ex.getMessage()` brut au client)

### 4.3 Validation
- [ ] Toutes les entrées utilisateur validées au boundary (controller / écran)
- [ ] Bean Validation (`@Valid`, `@NotBlank`, `@Size`) côté backend
- [ ] Validation côté Flutter (form validators) **et** backend (jamais l'un sans l'autre)
- [ ] Limites explicites (taille fichier, longueur string, ranges)

### 4.4 Sécurité
- [ ] Aucun secret en dur (clés API, mots de passe, JWT) — vérifier avec `gitleaks`
- [ ] Aucun secret dans les logs ou les exceptions exposées au client
- [ ] CORS / CSRF / Auth vérifiés sur tout nouvel endpoint
- [ ] Injections (SQL, command, LDAP, path traversal) impossibles par construction
- [ ] PII anonymisée dans les logs (RGPD)
- [ ] Pas d'élévation de privilèges (un user normal ne peut pas accéder à un endpoint admin)

### 4.5 Logs & observabilité
- [ ] Logs structurés (pas de `println` / `print` en prod)
- [ ] Niveaux corrects : ERROR pour bugs, WARN pour anomalies récupérables, INFO pour événements clés, DEBUG pour dev
- [ ] Correlation ID propagé sur les chemins critiques
- [ ] Pas de log dans une boucle chaude (perf)
- [ ] Pas de log de PII

### 4.6 Tests
- [ ] **≥ 80% de coverage sur le nouveau code** (mesuré, pas estimé)
- [ ] Au moins 1 test par chemin d'erreur ajouté
- [ ] Au moins 1 test par cas limite (vide, null, max, min)
- [ ] Tests d'intégration pour tout nouveau endpoint
- [ ] **Tests utiles** : aucun test `assertNotNull(x)` seul, aucun `expect(x, isA<X>())` seul
- [ ] Tests **isolés** : pas d'ordre d'exécution implicite
- [ ] Pas de mock de la base en intégration (Testcontainers ou H2 acceptable, mock interdit)

### 4.7 Performance
- [ ] Pas de N+1 query (utiliser `@EntityGraph`, `JOIN FETCH`, ou `findAllById`)
- [ ] Pagination sur tout endpoint qui retourne une liste
- [ ] Pas de calcul O(n²) sur des collections de taille non bornée
- [ ] Cache côté Flutter quand pertinent (provider state, pas refetch en boucle)

### 4.8 Documentation
- [ ] Si l'API publique change : mise à jour OpenAPI / commentaire JavaDoc
- [ ] Si une décision architecturale est prise : ADR dans `docs/adr/NNN-titre.md`
- [ ] PR description explique le **pourquoi**, pas seulement le **quoi**
- [ ] Issue liée référencée (`Closes #XXX`)

### 4.9 Cleanup
- [ ] Aucun TODO/FIXME ajouté sans issue tracker associée
- [ ] Aucun code commenté laissé en place
- [ ] Aucun import inutilisé
- [ ] Aucun fichier généré commité (`.dart_tool`, `target/`, `node_modules`)

---

## 5. Anti-patterns interdits (avec exemples)

### 5.1 `catch (Exception)` silencieux

❌ **Interdit**
```java
try {
    return aiClient.enhance(cv);
} catch (Exception e) {
    return buildFallback(cv);  // on perd la vraie erreur
}
```

✅ **Acceptable**
```java
try {
    return aiClient.enhance(cv);
} catch (AiProviderDownException e) {
    log.warn("AI provider down, using fallback", e);
    return buildFallback(cv);
}
// AiKeyInvalidException, AiQuotaExceededException : propagent
```

### 5.2 Magic numbers

❌ **Interdit**
```java
if (cv.getCompetences().size() > 10) { ... }
```

✅ **Acceptable**
```java
@ConfigurationProperties("cv.quality")
record CvQualityProperties(int maxCompetencesDisplayed) { }

if (cv.getCompetences().size() > properties.maxCompetencesDisplayed()) { ... }
```

### 5.3 Hardcoding de couleurs

❌ **Interdit** dans un widget
```dart
Container(color: Color(0xFF2563EB))
```

✅ **Acceptable**
```dart
Container(color: Theme.of(context).colorScheme.primary)
// ou : Container(color: AppColors.brandPrimary)
```

### 5.4 Singleton manuel quand DI dispo

❌ **Interdit**
```dart
class ApiService {
  static final _instance = ApiService._();
  factory ApiService() => _instance;
}
// puis dans un widget :
ApiService().getCvs();
```

✅ **Acceptable**
```dart
// injection_container.dart
sl.registerLazySingleton<ApiService>(() => ApiService(sl()));
// dans le widget :
final api = sl<ApiService>();  // ou via Provider/Consumer
```

### 5.5 Strings UI hardcodées

❌ **Interdit**
```dart
Text('Bienvenue sur votre tableau de bord')
```

✅ **Acceptable**
```dart
Text(AppLocalizations.of(context).dashboardWelcome)
```

### 5.6 Secrets dans le code

❌ **Interdit absolu** — bloque le merge
```yaml
api-key: ${DEEPSEEK_API_KEY:sk-real-key-here}
```

✅ **Acceptable**
```yaml
api-key: ${DEEPSEEK_API_KEY:}  # default vide, validé au boot
```

### 5.7 Information disclosure dans les exceptions

❌ **Interdit**
```java
@ExceptionHandler(RuntimeException.class)
public ResponseEntity<?> handleRuntime(RuntimeException ex) {
    return badRequest().body(ex.getMessage());  // expose stack interne
}
```

✅ **Acceptable**
```java
@ExceptionHandler(RuntimeException.class)
public ResponseEntity<?> handleRuntime(RuntimeException ex) {
    String correlationId = MDC.get("correlationId");
    log.error("Unhandled [correlationId={}]", correlationId, ex);
    return internalServerError().body(Map.of(
        "code", "INTERNAL_ERROR",
        "message", "Une erreur s'est produite. Contactez le support.",
        "correlationId", correlationId
    ));
}
```

---

## 6. Refus & push-back constructif

> Une **bonne** demande utilisateur peut produire un **mauvais** code. C'est ton rôle de le détecter et proposer mieux.

### 6.1 Quand pousser back
- La demande est techniquement mauvaise (perf, sécu, maintenabilité)
- Une solution scalable plus simple existe
- L'implémentation va casser autre chose
- Le scope est mal défini ou trop vaste pour une seule PR

### 6.2 Comment pousser back
1. **Acquiescer le besoin** : "Je comprends que tu veux X parce que Y"
2. **Pointer le risque** : "Le problème avec l'approche A, c'est [risque concret]"
3. **Proposer mieux** : "Je propose B : [bénéfice]. Tradeoff : [coût honnête]"
4. **Laisser décider** : "Tu valides B ou tu préfères A pour [raison] ?"

### 6.3 Quand NE PAS pousser back
- Préférence stylistique
- Choix d'outils équivalents
- Décisions produit (couleur, label, copy)

---

## 7. Décisions architecturales — ADR

Toute décision **non triviale et non locale** (qui affecte plusieurs fichiers ou la roadmap future) doit être documentée dans `docs/adr/NNN-titre.md`.

**Format imposé** :
```markdown
# ADR NNN — Titre court de la décision

## Statut
Proposé / Accepté / Déprécié / Remplacé par ADR XXX

## Date
2026-05-08

## Contexte
Quel problème on essaie de résoudre. Quel était l'état avant.

## Décision
Ce qu'on a choisi. En 2-3 phrases max.

## Conséquences
- Bénéfices concrets
- Coûts assumés
- Ce que ça nous interdit dans le futur

## Alternatives écartées
- A : pourquoi non
- B : pourquoi non
```

Exemples de ce qui mérite une ADR :
- Choix Provider vs Riverpod
- Choix Resilience4j config (retry count, CB threshold)
- Choix d'un fournisseur tiers (Sentry vs GlitchTip)
- Stratégie de versioning Flyway

---

## 8. Workflow Git / GitHub

### 8.1 Branches
- Pas de commit direct sur `main`
- Format de nom : `<type>/<scope>-<short-description>`
- Types : `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `sec`, `perf`
- Exemples : `feat/cv-export-docx`, `fix/import-web-bytes`, `sec/jwt-fail-fast`

### 8.2 Commits
- Format conventional commits : `<type>(<scope>): <description>`
- Description : impératif présent, minuscule, < 70 caractères
- Body : pourquoi (pas quoi), wrappé à 72 cols
- Co-authored-by : si paire-programming ou IA

### 8.3 PRs
- Issue liée obligatoire (`Closes #XXX`) sauf chore trivial
- PR template rempli (`/.github/PULL_REQUEST_TEMPLATE.md`)
- Pas de PR > 500 lignes ajoutées (split en plusieurs PRs séquentielles)
- 1 PR = 1 sujet (pas de "feat: A + bonus B")
- Review obligatoire avant merge en prod (auto-merge interdit sur `main`)
- Une PR ouverte > 7 jours doit être soit mergée soit fermée (pas de cimetière)

### 8.4 Issues
- Une issue = un livrable
- Critères d'acceptation explicites (checklist cochable)
- Priorité explicite : `priority:P0-critical` / `P1-high` / `P2-medium` / `P3-low`
- Labels surface : `backend` / `mobile` / `web` / `devops` / `documentation`

---

## 9. Pré-commit & pré-PR — checklist mécanique

### 9.1 Pré-commit (avant `git commit`)
- [ ] `mvn verify` passe (backend) **OU** `flutter analyze && flutter test` passe (mobile)
- [ ] `gitleaks detect` passe (zéro fuite)
- [ ] `git diff --cached` relu manuellement (pas de fichier indésirable)
- [ ] Aucun fichier > 300 lignes ajouté/modifié sans justification écrite

### 9.2 Pré-PR (avant `gh pr create`)
- [ ] Tous les checks pré-commit
- [ ] Tests automatisés ajoutés (≥80% coverage nouveau code)
- [ ] Smoke test manuel décrit dans la PR description
- [ ] Captures d'écran si UI
- [ ] Documentation mise à jour si API publique change
- [ ] CHANGELOG.md mis à jour si breaking change

### 9.3 Pré-merge (avant `gh pr merge`)
- [ ] CI verte
- [ ] Au moins 1 review approbative (humain ou multi-agent)
- [ ] Coverage non régressif (Codecov / lcov)
- [ ] Aucun conflit avec `main`
- [ ] PR description finalisée

---

## 10. Comportements interdits — récapitulatif

| Comportement | Conséquence |
|--------------|-------------|
| Bluffer sur un test/audit non fait | Reset de confiance, retour analyse |
| Citer un `fichier:ligne` non vérifié dans la session | À corriger en PR ou supprimer |
| Créer une issue sans vérifier l'existant | Issue close `duplicate` |
| Recommander un outil enterprise sans justification | Demander rétrojustification ou retirer |
| Merger sans review multi-agent | PR à reverter immédiatement |
| Skip un hook (`--no-verify`) sans accord explicite | Commit à reset |
| Force-push sur `main` | Reset + post-mortem |
| Commit avec un secret | Rotation immédiate + filter-repo |

---

## 11. Méta — quand modifier cette charte

Cette charte n'est pas figée. **Mais on ne la contourne pas, on l'amende**.

**Procédure** :
1. Ouvrir une issue `[CHARTER]` avec proposition + justification
2. Ouvrir une PR qui modifie ce fichier
3. Discussion + decision
4. Merger → effective immédiatement

**Triggers naturels d'amendement** :
- Une règle est régulièrement contournée → soit on la supprime, soit on la renforce
- Un nouvel anti-pattern apparaît → on l'ajoute en section 5
- L'équipe grandit → ajouter règles de coordination

---

## 12. Référence rapide — la vérification en 5 questions

Avant chaque action, je me pose ces questions. Si une réponse est "non", je m'arrête et corrige.

1. **Ai-je vérifié l'existant** (issues, PRs, code) avant de proposer du nouveau ?
2. **Ai-je l'évidence concrète** de mes claims (commande lancée, fichier lu, sortie vue) ?
3. **Ai-je passé les 6 perspectives** (planificateur, codeur, testeur, sécurité, architecte, SOLID/DRY) ?
4. **Mon code passerait-il l'audit demain** sans me faire honte ?
5. **Si 100k users utilisent ça dans 10 ans**, qu'est-ce qui va casser en premier ?

---

*Cette charte engage tout contributeur — humain ou agent IA — sur le projet MonCV.*
*En cas de violation : le code est rejeté, peu importe le statut du contributeur.*
