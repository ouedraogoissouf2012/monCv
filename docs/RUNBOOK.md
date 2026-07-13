# Runbook MonCV

## 1. Lancement local

### Backend seul

```bash
cd backend
cp .env.example .env
mvn spring-boot:run
```

### Flutter web

```bash
cd mobile
flutter pub get
flutter run -d chrome --web-port=3001
```

### Stack Docker complete

```bash
cp .env.example .env
docker compose up -d
docker compose ps
```

Services attendus :

- backend : `http://localhost:8082`
- postgres : `localhost:5432`
- adminer : `http://localhost:8081`

## 2. Deploiement production

Reference detaillee : `DEPLOYMENT.md`.

Sequence recommande :

1. verifier la branche / tag a deployer ;
2. confirmer les secrets requis (`DB_PASSWORD`, `JWT_SECRET`, `ALLOWED_ORIGINS`, `DEEPSEEK_API_KEY`) ;
3. lancer la pipeline CI si disponible ;
4. construire et publier l'image backend ;
5. deployer le backend avec `SPRING_PROFILES_ACTIVE=prod` ;
6. verifier `health/readiness`, logs, metriques et Swagger desactive ;
7. deployer le build Flutter web/PWA avec les bons `--dart-define`.

## 3. Rollback

### Backend

1. identifier la derniere image saine ;
2. redeployer cette image ;
3. verifier readiness + liveness ;
4. surveiller les erreurs et le trafic.

### Flutter web

1. republier le bundle precedent ;
2. verifier que `API_BASE_URL` et `APP_ENV` sont coherents ;
3. tester login + liste CV + export PDF.

## 4. Circuit breaker IA

Inspection :

```bash
curl -H "Authorization: Bearer <admin-token>" \
  http://localhost:8082/actuator/circuitbreakers
```

Controle d'un breaker :

```bash
curl -H "Authorization: Bearer <admin-token>" \
  http://localhost:8082/actuator/circuitbreakers/ai-deepseek
```

Remise en etat operationnel :

- attendre la fin de `wait-duration-in-open-state` si la panne fournisseur est externe ;
- si l'ecriture Actuator est active dans l'environnement cible, utiliser l'endpoint
  `/actuator/circuitbreakers/ai-deepseek/state` selon la politique ops locale ;
- sinon, redemarrer proprement le backend apres verification que le fournisseur IA est revenu.

## 5. Lecture des logs

Chercher le `X-Correlation-Id` renvoye au client, puis filtrer les logs avec cette valeur.

Exemples :

### Loki

```text
{app="moncv-backend"} |= "correlationId=abc-123"
```

### CloudWatch Logs Insights

```text
fields @timestamp, @message
| filter @message like /abc-123/
| sort @timestamp desc
```

En `prod`, les logs backend sont structures JSON.

## 6. Procedures incident

### PostgreSQL indisponible

Symptomes :

- `/actuator/health/readiness` DOWN
- erreurs JDBC / Hikari
- creation ou lecture CV en echec

Actions :

1. verifier la sante du service PostgreSQL ;
2. verifier connectivite reseau + credentials ;
3. verifier l'etat Flyway au demarrage ;
4. rollback applicatif seulement si la panne est liee au dernier deploy.

### Fournisseur IA indisponible

Symptomes :

- erreurs `AI_PROVIDER_DOWN`, `AI_TIMEOUT`, `AI_QUOTA_EXCEEDED`
- circuit breaker ouvert

Actions :

1. verifier `/api/ai/status` ;
2. verifier la cle et le quota du fournisseur ;
3. observer le fallback mock si active ;
4. remettre en route le circuit breaker une fois la cause levee.

### CV non generable en PDF / DOCX

Symptomes :

- erreur `PDF_GENERATION_ERROR`
- export DOCX vide ou 500

Actions :

1. rejouer avec un CV simple ;
2. verifier les logs par correlation ID ;
3. verifier presence des champs obligatoires / donnees importees ;
4. verifier que l'upload photo n'introduit pas un contenu invalide.

## 7. Contacts on-call

- Owner produit / depot : `@ouedraogoissouf2012`
- Escalade backend : mainteneur Spring Boot du sprint courant
- Escalade mobile : mainteneur Flutter du sprint courant

Avant mise en production multi-personnes, remplacer ces lignes par une rotation formelle et des contacts hors GitHub.
