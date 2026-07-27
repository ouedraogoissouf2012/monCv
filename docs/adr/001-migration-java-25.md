# ADR 001 — Migration du runtime backend de Java 21 vers Java 25

## Statut

Accepté

## Date

2026-07-27

## Contexte

Le backend MonCV ciblait Java 21 (LTS, GA septembre 2023), aligné sur le pom
Maven, les workflows CI (`ci.yml`, `release-apk.yml`), l'image Docker de runtime
et la documentation (`CONTRIBUTING.md`, `DEPLOYMENT.md`).

Java 25 est la nouvelle version LTS de la plateforme, disponible en General
Availability depuis le **16 septembre 2025**, avec un support long terme d'au
moins huit ans. Rester sur Java 21 revient à accumuler une dette de plateforme :
la fenêtre de support de 21 se réduit à mesure que 25 devient la cible LTS de
référence de l'écosystème Spring/Temurin.

Un outil de modernisation (`appmod/java-upgrade`) a produit un plan de migration
(`backend/.github/modernize/java-upgrade/20260727144142/plan.md`) et a commencé à
appliquer les changements dans le working tree, mais de façon **incohérente et
incomplète** :

- l'image Docker de runtime était passée en `eclipse-temurin:25-jre-alpine`
  **sans digest**, supprimant l'épinglage SHA-256 mis en place par le
  durcissement supply-chain (issue #262) — régression de sécurité directe ;
- le stage de build du Dockerfile restait en Temurin 21 ;
- dans `ci.yml`, seul le job `web-smoke` passait en 25, le job `backend` restait
  en 21 ;
- le `pom.xml` oscillait entre 21 et 25 selon les éditions manuelles.

Cette ADR formalise la décision et fige un état **cohérent et sécurisé**.

## Décision

Migrer l'ensemble du backend vers **Java 25 (LTS)**, en une seule opération
cohérente couvrant build, CI, runtime conteneurisé et documentation. Toutes les
images Docker restent **épinglées par digest SHA-256**, conformément à la
politique supply-chain existante.

Cibles retenues :

| Élément | Valeur |
| --- | --- |
| `backend/pom.xml` `<java.version>` | `25` |
| `ci.yml` / `release-apk.yml` `setup-java` | `25` (distribution `temurin`) |
| Image build | `maven:3.9.16-eclipse-temurin-25-alpine@sha256:72e2d64836e659d053a573ac9ebab05b78ae78fa7bb69b7452a7cb877b465fc7` |
| Image runtime | `eclipse-temurin:25-jre-alpine@sha256:28db6fdf60e38945e43d840c0333aeaec66c15943070104f7586fd3c9d1665b0` |

Spring Boot (ligne 3.5.x au runtime) est déjà compatible ; aucun changement de
code applicatif n'est requis (cf. plan, section *Source Code Changes*).

## Conséquences

**Bénéfices**

- Runtime aligné sur la LTS courante, avec ~8 ans de support en amont.
- Cohérence totale build ↔ CI ↔ runtime ↔ docs : plus de configuration
  Java à moitié migrée.
- Régression supply-chain corrigée : les deux stages Docker sont re-épinglés
  par digest.

**Coûts assumés**

- Tout contributeur doit installer un **JDK 25 local** ; les JDK 21/24 ne
  compilent pas une cible `release 25` (`error: release version 25 not
  supported`).
- Les digests devront être bumpés lors des mises à jour de sécurité des images
  de base (procédure de transition déjà en place pour les images épinglées).

**Ce que ça nous interdit**

- Revenir à Java 21 sans nouvelle ADR (rétrogradation = décision non-locale).
- Introduire un tag Docker mutable pour l'image de base : le digest reste
  obligatoire.

## Alternatives écartées

- **Rester sur Java 21** : reporte la dette de plateforme ; la fenêtre de
  support LTS se réduit et l'écosystème bascule vers 25.
- **Passer par Java 24 (non-LTS)** : le JDK 24 est disponible localement mais
  n'est pas LTS ; il ne sert que de secours éventuel de validation, pas de
  cible de production.
- **Laisser l'outil finir seul la migration** : il avait déjà introduit une
  régression de sécurité (digest perdu) et un état incohérent ; une
  décision tracée et une application manuelle contrôlée étaient nécessaires.

## Vérification

- `mvn -q -DskipTests compile` et `mvn -q test` doivent passer avec un JDK 25
  local (étape à valider après installation du JDK 25).
- L'auditeur de sécurité des workflows (`tools/ci/check_workflow_security.py`)
  doit rester vert : les actions et images demeurent épinglées.
- Aucune référence résiduelle à Java 21 dans `pom.xml`, les workflows, le
  Dockerfile ou les docs de prérequis.
