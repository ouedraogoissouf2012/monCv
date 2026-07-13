# Database

## Politique de versioning Flyway

- Les migrations suivent une sequence strictement incrementale: `V1`, `V2`, `V3`, etc.
- Aucun trou de version n'est autorise.
- Une migration deja poussee ou appliquee en environnement partage est immuable.
- Si une version doit etre reservee ou annulee, on cree un placeholder explicite plutot que de laisser un gap silencieux.
- `outOfOrder` reste desactive par defaut: l'ordre des migrations doit rester predictible.

## Etat actuel

Les migrations presentes dans `backend/src/main/resources/db/migration` sont:

- `V1__init_schema.sql`
- `V2__add_certifications_projects.sql`
- `V3__add_public_token_to_cvs.sql`
- `V4__enlarge_text_columns.sql`
- `V5__add_cv_style_columns.sql`
- `V6__add_cv_variants.sql`
- `V7__index_parent_cv_id.sql`
- `V8__add_cv_view_analytics.sql`
- `V9__add_push_notifications.sql`

Le gap historique entre `V4` et `V6` n'existe plus: `V5__add_cv_style_columns.sql` a ete ajoutee avant mise en production.

## Verification locale

Pour verifier l'ordre des migrations sur une base PostgreSQL vierge:

```bash
mvn flyway:info \
  -Dflyway.url=jdbc:postgresql://localhost:5432/cvmobile \
  -Dflyway.user=postgres \
  -Dflyway.password=...
```

Pour inspecter l'historique applique:

```bash
SELECT * FROM flyway_schema_history ORDER BY installed_rank;
```
