# Backend MonCV

## Build Docker

Construire l'image locale :

```bash
docker build -t moncv-backend:latest backend/
```

Executer le conteneur :

```bash
docker run --rm -p 8082:8082 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e JWT_SECRET=remplacer-par-un-secret-long \
  -e DB_URL=jdbc:postgresql://host.docker.internal:5432/cvmobile \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=secret \
  -e ALLOWED_ORIGINS=https://app.example.com \
  -e DEEPSEEK_API_KEY=remplacer-par-la-cle \
  moncv-backend:latest
```

Variables utiles :

- `JAVA_OPTS` pour surcharger les options JVM du conteneur
- `SERVER_PORT` pour changer le port HTTP
- `UPLOAD_DIR` pour redefinir le dossier des uploads

Par defaut, l'image expose `8082` et publie un healthcheck sur
`/actuator/health/liveness`.
