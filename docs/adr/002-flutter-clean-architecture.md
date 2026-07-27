# ADR 002 — Cible Clean Architecture pour l'application Flutter

## Statut

Accepté

## Date

2026-07-27

## Contexte

L'application Flutter (`mobile/`) est organisée **par type de fichier** :
`lib/{screens, widgets, providers, usecases, repositories, services, models,
data, core, pdf}`. Une base de Clean Architecture existe déjà (type scellé
`Result<T>`, contrat `UseCase<T, Params>`, repositories renvoyant des `Result`),
mais elle est appliquée de façon **incohérente**, ce qui laisse fuiter les
détails d'infrastructure jusque dans la présentation.

Violations confirmées par lecture du code (2026-07-27) :

- **La présentation importe le transport HTTP.** 12 fichiers de
  `screens/`, `widgets/` et `providers/` importent directement `IApiClient` /
  `api_service.dart` (ex. `screens/home/home_screen.dart`,
  `screens/profile/profile_screen.dart`, `widgets/ai_enhance_sheet.dart`,
  `providers/notification_provider.dart`).
- **Les use cases IA court-circuitent la couche repository.** Les 4 use cases
  `usecases/ai/*` (`enhance_cv`, `generate_resume`, `match_job`,
  `suggest_bullets`) dépendent directement de `IApiClient` au lieu d'un port de
  domaine.
- **Trois providers** (`ai_status_provider`, `job_application_provider`,
  `notification_provider`) reçoivent `IApiClient` sans use case ni repository
  intermédiaire.
- `models/cv.dart` mélange entités de domaine, sérialisation JSON, `copyWith`,
  métadonnées publiques et calcul de complétion (traité par #238).

Sans cible écrite et règles exécutables, les refactors fichier par fichier
créeront une seconde architecture à côté de l'ancienne au lieu de la remplacer.

## Décision

Migrer progressivement vers une **Clean Architecture par fonctionnalité**. La
direction des dépendances pointe **toujours vers le domaine**, jamais vers
Flutter, HTTP ou le stockage.

```text
lib/core/                      # infra transverse (Result, erreurs, DI, réseau)
lib/features/<feature>/
  domain/          # entités, value objects, ports purs — zéro Flutter/HTTP
  application/     # use cases et états applicatifs
  data/            # DTO, mappers, data sources, adapters de repository
  presentation/    # controllers (ChangeNotifier) et widgets
```

Règles de frontière :

1. `presentation` **n'importe jamais** `data`, un data source, `package:http`,
   `dio`, `services/` de transport ou un mécanisme de stockage. Il ne parle
   qu'à `application` et `domain`.
2. `domain` n'importe **ni** Flutter, **ni** HTTP, **ni** JSON.
3. Les use cases dépendent de **ports** (interfaces du domaine), pas de
   `IApiClient`.
4. Aucun `Map<String, dynamic>` ne franchit la frontière `data → application`.

**Stratégie d'état** : `provider` (package) reste pour l'injection de scope UI
et `ChangeNotifier`; `get_it` reste le service locator pour câbler
services/repositories/use cases. Pas de migration vers un autre framework d'état
dans ce chantier (voir Alternatives).

**Migration incrémentale** : chaque feature migre derrière une **façade de
compatibilité** explicitement `@Deprecated`, ≤ 100 lignes, avec une issue et une
date de suppression. Aucun big-bang.

## Conséquences

**Bénéfices**
- Un widget ne peut plus déclencher un appel réseau ou un accès stockage.
- Le domaine devient testable sans Flutter ni serveur.
- Les évolutions de contrat HTTP restent confinées à `data/`.

**Coûts assumés**
- Réorganisation de `lib/` par feature (plusieurs PR séquentielles, #237→#251).
- Maintien temporaire de façades dépréciées le temps de la migration.

**Ce que ça interdit**
- Importer un transport/data source depuis `presentation` (vérifié en CI).
- Ajouter une nouvelle dépendance directe `presentation → IApiClient`.

## Alternatives écartées

- **Réorganisation uniquement par type** (`screens/services/models`) : conserve
  les couplages transverses actuels — c'est précisément le problème.
- **Changer de framework d'état** (Riverpod/Bloc) : hors périmètre; le couple
  `provider` + `get_it` fonctionne et le sujet ici est la frontière, pas l'outil
  d'état.
- **Migration big-bang** : PRs non révisables, risque de régression élevé.

## Garde-fou associé

Une règle `custom_lint` (100 % open-source) fera échouer `flutter analyze` si un
fichier de `presentation` importe `data`, un data source, HTTP ou le stockage.
Les 12 violations actuelles sont gelées dans une allowlist décroissante
(propriétaire + justification + issue de suppression), jamais augmentée. Livrée
dans une PR dédiée de #235.
