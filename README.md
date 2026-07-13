# MonCV

MonCV contient un backend Spring Boot et une application Flutter pour creer,
adapter et exporter des CV.

## Profils Spring Boot

Le backend utilise `SPRING_PROFILES_ACTIVE` pour choisir sa configuration :

- `dev` : developpement local, Swagger actif, logs plus verbeux
- `test` : tests automatises, H2 en memoire, aucun secret de prod requis
- `prod` : production, secrets obligatoires, Swagger desactive

Exemples :

```bash
cd backend
SPRING_PROFILES_ACTIVE=dev ./mvnw spring-boot:run
SPRING_PROFILES_ACTIVE=test ./mvnw test
SPRING_PROFILES_ACTIVE=prod java -jar target/*.jar
```

Les variables attendues sont documentees dans [backend/.env.example](backend/.env.example).

## Docker local

Pour lancer un environnement dev complet :

```bash
cp .env.example .env
cp docker-compose.override.yml.example docker-compose.override.yml
docker compose up -d
```

Acces utiles :

- Backend : `http://localhost:8082`
- Liveness : `http://localhost:8082/actuator/health/liveness`
- Adminer : `http://localhost:8081`

## Deploiement

La CI backend execute les tests avec le profil `test`.
Les deploiements doivent toujours injecter `SPRING_PROFILES_ACTIVE=prod` avec
les secrets via l'orchestrateur ou le gestionnaire de secrets.
