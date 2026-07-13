# API MonCV

## Swagger

- Dev local : [http://localhost:8082/swagger-ui.html](http://localhost:8082/swagger-ui.html)
- OpenAPI JSON : [http://localhost:8082/api-docs](http://localhost:8082/api-docs)

En profil `prod`, Swagger est desactive.

## Authentification

L'API utilise un bearer token JWT pour les endpoints proteges.

Exemple d'en-tete :

```bash
Authorization: Bearer <access_token>
```

## Endpoints principaux

### Auth

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`

### Utilisateur

- `GET /api/users/me`
- `PUT /api/users/me`
- `GET /api/users/me/export`
- `DELETE /api/users/me`

### CV

- `GET /api/cvs`
- `GET /api/cvs/{id}`
- `POST /api/cvs`
- `PUT /api/cvs/{id}`
- `DELETE /api/cvs/{id}`
- `POST /api/cvs/{id}/duplicate`
- `POST /api/cvs/{id}/share`
- `GET /api/cvs/public/{token}`
- `POST /api/cvs/{id}/variant`
- `GET /api/cvs/{id}/variants`
- `GET /api/cvs/{id}/pdf`
- `GET /api/cvs/{id}/docx`
- `POST /api/cvs/import`

### IA

- `GET /api/ai/status`
- `POST /api/ai/suggest`
- `POST /api/ai/generate-resume`
- `POST /api/ai/enhance-cv`
- `POST /api/ai/match-job`

### Uploads

- `POST /api/uploads/photo`
- `GET /api/uploads/photos/{filename}`

### Notifications

- `POST /api/notifications/devices`
- `DELETE /api/notifications/devices`
- `GET /api/notifications/preferences`
- `PUT /api/notifications/preferences`

## Exemples curl

### Login

```bash
curl -X POST http://localhost:8082/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo@example.com",
    "password": "motdepasse"
  }'
```

### Creer un CV

```bash
curl -X POST http://localhost:8082/api/cvs \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "titre": "Developpeur Backend Java",
    "resume": "Ingenieur logiciel oriente API et production.",
    "competences": [],
    "experiences": [],
    "formations": []
  }'
```

### Export PDF

```bash
curl -L "http://localhost:8082/api/cvs/1/pdf?template=MODERNE" \
  -H "Authorization: Bearer <token>" \
  -o cv.pdf
```

### Etat IA

```bash
curl http://localhost:8082/api/ai/status \
  -H "Authorization: Bearer <token>"
```

## Correlation ID

Chaque reponse HTTP expose `X-Correlation-Id`. En cas d'erreur prod, conservez cette valeur pour retrouver rapidement les logs associes.
