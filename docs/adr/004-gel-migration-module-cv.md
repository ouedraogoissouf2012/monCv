# ADR 004 — Gel de la migration du module CV et read-model JPA assumé

## Statut

Accepté

## Date

2026-08-23

## Contexte

L'[ADR 003](003-backend-modular-monolith.md) a choisi une organisation en monolithe
modulaire ports/adapters. Le module `com.cvmobile.cv` a été créé dans ce cadre, et la
migration s'est arrêtée à mi-parcours.

État constaté par lecture du code le 2026-08-23 (`main` = `8fc6279`) :

**Ce qui est migré** — module `cv/` avec `domain/model`, `application/usecase`,
`application/port/out`, `adapter/in/web`, `adapter/out/persistence`, et cinq use cases :
`CreateCvUseCase`, `UpdateCvUseCase`, `DeleteCvUseCase`, `DuplicateCvUseCase`,
`CvTrashUseCase`. Autrement dit : le CRUD.

**Ce qui ne l'est pas** — `CvController` injecte simultanément ces use cases et
`com.cvmobile.service.cv.ICvService` (12 méthodes, dont 7 encore appelées). Restent dans
l'organisation historique :

| Domaine fonctionnel | Service | Lignes |
| --- | --- | --- |
| Variantes de CV | `CvVariantService` | 196 |
| Accès public / partage | `PublicCvAccessService` | 151 |
| Jetons de partage | `CvShareService` | 93 |
| Migration de jetons | `PublicShareTokenMigrationService` | 45 |
| Recherche, propriété | `CvFinder`, `CvOwnershipService` | 62 |

Soit environ **550 lignes de logique métier**, plus l'import de CV et la lecture servant
aux exports PDF/DOCX.

**La lecture web** passe par `CvResponseAssembler` (`cv/adapter/in/web/`), qui dépend
directement de `CvRepository` et `CvMapper` — donc de la couche de persistance historique.
Le fichier documente ce choix et le qualifie de « dette tracée (#255) ».

**Le problème réel** n'est aucun de ces points pris isolément : c'est que les epics **#231
et #255 sont fermés** alors que le code référence encore des tranches `255-C+` et `255-E`
qui n'existent plus comme issues. Un lecteur ne peut pas savoir si la migration est
terminée, abandonnée, ou en attente. C'est l'objet de l'issue #503.

## Décision

**La migration du module CV est gelée en l'état.** Elle n'est ni « en cours » ni
« inachevée » : la frontière décrite ci-dessous est la cible, et elle est atteinte.

### 1. Le read-model JPA est un choix assumé, pas une dette

`CvResponseAssembler` construit la réponse web depuis l'entité JPA plutôt que depuis
l'agrégat de domaine. Ce n'est pas une entorse à l'hexagonal : c'est une séparation
lecture/écriture (CQRS allégé), où l'écriture passe par le domaine et ses invariants,
tandis que la lecture emprunte un chemin direct.

La justification est explicite dans le code et reste valable : le domaine CV ne modélise
**volontairement pas** les jetons de partage public, les horodatages ni le nombre de
variantes. Ce sont des préoccupations de présentation et d'infrastructure, pas des règles
métier. Les faire entrer dans l'agrégat l'alourdirait sans rien protéger.

La mention « dette tracée (#255) » dans `CvResponseAssembler` doit donc être lue comme la
description d'un choix, non comme un travail en retard.

### 2. La frontière entre les deux mondes est figée

| Responsabilité | Propriétaire |
| --- | --- |
| Créer, modifier, supprimer, dupliquer, corbeille | Use cases du module `cv/` |
| Lecture web (`CvResponse`) | `CvResponseAssembler`, via JPA |
| Variantes, partage public, jetons | `service/cv/*` historique |
| Import de CV, exports PDF/DOCX | Services historiques |

### 3. Règle pour l'avenir : l'ancien monde ne grossit plus

- Toute **nouvelle** fonctionnalité CV s'implémente dans le module `cv/`, en use case.
- Aucune méthode nouvelle n'est ajoutée à `ICvService`.
- Une modification d'un service historique reste permise pour corriger un défaut, mais pas
  pour y loger une capacité nouvelle.

Cette règle repose aujourd'hui sur la revue humaine. Elle n'est pas automatisée : voir
« Conséquences ».

### 4. Les valeurs par défaut du style ont le domaine pour source unique

`CvStyle.DEFAULT_TEMPLATE_ID`, `DEFAULT_PRIMARY_COLOR` et `DEFAULT_FONT_FAMILY` passent en
`public`. L'entité `model/Cv` et `PublicCvMapper` les reprennent au lieu de les redéclarer.

Ces trois valeurs étaient dupliquées à l'identique dans trois fichiers : une évolution du
style par défaut n'en aurait corrigé qu'une partie, en silence. La dépendance introduite va
de la persistance et du web **vers** le domaine, jamais l'inverse : elle est conforme à
l'ADR 003.

## Alternatives écartées

**Terminer la migration.** Porter variantes, partage, import et read-model dans le module
`cv/` représente environ 550 lignes de logique métier plus leurs tests, soit plusieurs PR
successives pour rester sous la limite de 500 lignes ajoutées. Ces fonctionnalités sont en
production et couvertes par des tests écrits contre l'implémentation actuelle : le rapport
entre le risque de régression et le gain structurel ne le justifie pas aujourd'hui. Cette
option reste ouverte si un besoin métier impose de faire évoluer ces domaines en
profondeur.

**Supprimer le module `cv/` et revenir aux services historiques.** Écartée : le CRUD migré
fonctionne, il est couvert, et il constitue le point d'entrée naturel des évolutions
futures. Revenir en arrière coûterait autant que d'avancer, sans bénéfice.

**Modéliser jetons de partage et horodatages dans l'agrégat de domaine** pour supprimer le
read-model JPA. Écartée : cela ferait entrer des préoccupations d'infrastructure dans le
domaine, précisément ce que l'ADR 003 cherche à éviter.

## Conséquences

**Positives**

- Un lecteur sait désormais ce qui est intentionnel et ce qui ne l'est pas.
- La question « quel monde dois-je utiliser ? » a une réponse écrite.
- Les valeurs par défaut du style ne peuvent plus diverger.

**Négatives, assumées**

- Deux organisations coexistent durablement dans `CvController`. Le coût cognitif décrit
  par #503 demeure ; il est accepté au profit de la stabilité.
- Trois représentations du CV subsistent : entité JPA (209 lignes), modèle de domaine
  (284), DTO web (153). C'est le prix de l'architecture hexagonale choisie en ADR 003, pas
  un défaut à corriger.

**Reste à faire, hors périmètre de cet ADR**

- La règle « l'ancien monde ne grossit plus » n'est pas automatisée. Un garde d'architecture
  la rendrait exécutoire plutôt que déclarative.
- Les règles de validation du style (listes de modèles et de polices autorisés, borne ARGB)
  vivent dans `PublicCvMapper` et non dans le domaine. `CvStyle` valide la présence des
  champs, pas leur appartenance à un ensemble.

## Références

- Issue #503 — décision demandée
- [ADR 003](003-backend-modular-monolith.md) — monolithe modulaire ports/adapters
- Epics #231 et #255 — fermés ; les tranches `255-C+` / `255-E` citées dans le code ne
  correspondent à aucune issue ouverte
