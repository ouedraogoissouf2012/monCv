# Strategie de tests

## Niveaux

### Tests unitaires

Les tests unitaires isolent une classe avec JUnit et Mockito. Ils ne demarrent
ni Spring ni une base de donnees. `AuthControllerTest` et `CvControllerTest`
appartiennent a cette categorie : leurs services sont simules et leurs contrats
HTTP sont couverts separement par les tests d'integration.

```bash
cd backend
mvn -Dtest='!*IntegrationTest,!FlywayMigrationsTest' test
```

### Tests d'integration

Les classes du package `com.cvmobile.integration` utilisent un PostgreSQL 17
Testcontainers partage. `PostgresIntegrationTest` fournit le conteneur, injecte
les proprietes JDBC avec `@DynamicPropertySource` et demande a Flyway
d'appliquer les migrations avant chaque test.

Le schema Hibernate est valide, jamais cree automatiquement. H2 n'est pas
utilise : contraintes, types et migrations sont donc verifies sur le meme
moteur majeur qu'en production.

```bash
cd backend
mvn -Dtest='*IntegrationTest,FlywayMigrationsTest' test
```

Docker doit etre actif. Pour autoriser Testcontainers a retrouver le meme
conteneur entre plusieurs executions locales, ajouter dans
`~/.testcontainers.properties` :

```properties
testcontainers.reuse.enable=true
```

Cette option est locale et ne doit pas etre imposee dans le depot. Le conteneur
reste unique entre toutes les classes. Sans reuse, Ryuk le nettoie a la fin de
la JVM; avec reuse, il peut survivre a plusieurs executions et le socle de test
reinitialise alors le schema avant la suite.

### Tests E2E

Les tests E2E exercent l'application Flutter contre le backend reel. Le smoke
web CI demarre PostgreSQL, le backend et Flutter Web avant d'executer
`mobile/test/e2e/cv_smoke_web_test.dart`.

## Commande de reference

```bash
cd backend
mvn verify
```

Cette commande execute les tests, genere le rapport Jacoco et applique les
seuils de couverture. Les migrations Flyway restent incrementales; un test de
contrat les rejoue dans un schema PostgreSQL vierge et valide leurs checksums.
