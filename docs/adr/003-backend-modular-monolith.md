# ADR 003 — Backend en monolithe modulaire ports/adapters

## Statut

Accepté

## Date

2026-07-27

## Contexte

Le backend (`backend/src/main/java/com/cvmobile/`) est organisé par **couches
techniques globales** (`controller`, `service`, `repository`, `model`, `dto`,
`mapper`, `security`, `config`). Cette organisation fonctionne, mais laisse le
domaine métier couplé au framework, ce qui empêche des tests de domaine purs et
rend risquées les évolutions de persistance ou de couche web.

Violations confirmées par lecture du code (2026-07-27) :

- **`User implements UserDetails`** (`model/User.java:25`) : l'entité de domaine
  dépend d'un type Spring Security.
- **Les ports fichier/import exposent `MultipartFile`** (type Spring MVC) —
  `service/file/IFileStorageService.java`, `service/import_/ICvImportService.java`
  et leurs implémentations. Un port applicatif fuit ainsi un type de la couche
  web.
- **Les 13 entités de `model/` sont annotées `@Entity`** : le modèle métier est
  indissociable de JPA.
- Des façades PDF instancient une implémentation avec `new`, hors container
  Spring (traité par #255).

À noter (correction par rapport à l'énoncé de #231/#255) : **`CvController`
n'importe plus de repository** — cette violation, citée dans les issues, a été
corrigée depuis leur rédaction. Vérifié : aucun import `*Repository` dans
`controller/CvController.java`. La règle CI la préviendra néanmoins pour l'avenir.

## Décision

Le backend **reste un monolithe** (pas de microservices), mais devient
**modulaire** en ports/adapters, par fonctionnalité :

```text
com.cvmobile.<feature>/
  domain/          # modèle et politiques métier — sans Spring ni JPA
  application/     # use cases, commandes, requêtes, ports (interfaces)
  adapter/in/web/  # controllers et DTO HTTP
  adapter/out/     # persistence (JPA), IA, fichiers, notifications
```

Règles de frontière :

1. Un **controller** ne dépend **jamais** d'un repository (il passe par un use
   case / port applicatif).
2. Le **domaine** ne dépend **ni** de Spring, **ni** de JPA, **ni** d'un type
   web (`MultipartFile`, `ResponseEntity`, etc.).
3. Un **adapter** n'est jamais importé par le domaine (dépendances vers
   l'intérieur uniquement).
4. Les entités de persistance JPA vivent dans `adapter/out/persistence`,
   distinctes des entités de domaine.

Les frontières transactionnelles sont portées par la couche `application`
(use cases `@Transactional`), pas par les controllers ni le domaine.

**Migration incrémentale** : façades temporaires explicitement dépréciées et
datées; aucun déplacement massif de packages dans cette issue.

## Conséquences

**Bénéfices**
- Domaine testable sans contexte Spring ni base de données.
- Évolutions de persistance/web confinées aux adapters.
- Les frontières deviennent vérifiables automatiquement (ArchUnit).

**Coûts assumés**
- Séparation entité de domaine ↔ entité JPA (mapping supplémentaire, #254/#255).
- `User` devra cesser d'implémenter `UserDetails` : un adapter Security portera
  cette responsabilité.
- Les ports fichier/import devront remplacer `MultipartFile` par une abstraction
  (flux + métadonnées) neutre.

**Ce que ça interdit**
- Un controller important un repository (vérifié en CI).
- Le domaine important Spring/JPA/un type web (vérifié en CI).

## Alternatives écartées

- **Microservices** : coût opérationnel disproportionné pour l'équipe et le
  produit; le monolithe modulaire garde des frontières testables sans
  distribution.
- **Rester en couches techniques globales** : conserve le couplage
  domaine↔framework, c'est le problème à résoudre.
- **Migration big-bang** : risque de régression et PRs non révisables.

## Garde-fou associé

Des tests **ArchUnit** (gratuit, standard Java) feront échouer `mvn verify` si :
un controller importe un repository, le domaine dépend de Spring/JPA, ou un
adapter est importé par le domaine. Les violations actuelles
(`User`/`UserDetails`, `MultipartFile` dans les ports, `@Entity` sur le modèle)
sont gelées dans une allowlist décroissante (propriétaire + justification +
issue), jamais augmentée. Livré dans une PR dédiée de #235.
