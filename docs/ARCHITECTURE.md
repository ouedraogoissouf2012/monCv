# Architecture MonCV

Ce document suit une vue C4 simplifiee : contexte, conteneurs, composants.

## 1. System Context

```mermaid
flowchart LR
    User["Candidat / utilisateur MonCV"]
    Recruiter["Recruteur / destinataire du CV partage"]
    Mobile["Application Flutter MonCV"]
    Backend["API MonCV (Spring Boot)"]
    DeepSeek["Fournisseur IA DeepSeek"]
    PG["PostgreSQL"]
    Files["Stockage des uploads"]
    Push["Firebase Cloud Messaging"]

    User --> Mobile
    Recruiter --> Backend
    Mobile --> Backend
    Backend --> DeepSeek
    Backend --> PG
    Backend --> Files
    Backend --> Push
```

## 2. Container View

```mermaid
flowchart TB
    subgraph Client["Client"]
        Flutter["Flutter web/mobile"]
    end

    subgraph Platform["Plateforme MonCV"]
        Api["Spring Boot API"]
        Uploads["Uploads photo"]
        Metrics["Actuator + Prometheus metrics"]
    end

    subgraph Data["Donnees et integrations"]
        Db["PostgreSQL + Flyway"]
        Ai["DeepSeek / fallback IA"]
        Fcm["Firebase Cloud Messaging"]
        Obs["Sentry / GlitchTip / Grafana"]
    end

    Flutter --> Api
    Api --> Db
    Api --> Uploads
    Api --> Ai
    Api --> Fcm
    Api --> Metrics
    Metrics --> Obs
    Api --> Obs
```

## 3. Backend Component View

```mermaid
flowchart LR
    Controllers["Controllers REST
    auth / users / cvs / ai / uploads / notifications"]
    Security["Security
    JWT + rate limit + actuator rules"]
    Services["Domain services
    CV / PDF / DOCX / import / auth / notifications"]
    AiServices["AI services
    suggest / enhance / match / resume"]
    AiClients["AI clients
    composite / resilient / deepseek / mock"]
    Observability["Observability
    correlation ID / metrics / logs / sentry"]
    Repos["Repositories JPA"]
    Db["PostgreSQL"]

    Controllers --> Security
    Controllers --> Services
    Controllers --> AiServices
    Services --> Repos
    AiServices --> AiClients
    Services --> Observability
    AiServices --> Observability
    Repos --> Db
```

## 4. Flutter Component View

```mermaid
flowchart LR
    Screens["Screens / widgets"]
    Providers["Providers"]
    Repos["Repositories / services API"]
    Router["GoRouter"]
    Local["Storage local / secure storage"]
    Api["Backend API"]

    Screens --> Providers
    Providers --> Repos
    Screens --> Router
    Providers --> Local
    Repos --> Api
```

## 5. Flux critiques

### Creation d'un CV

1. Flutter collecte le formulaire.
2. L'API valide le `CvRequest`.
3. `CvService` persiste le CV via JPA.
4. Les metriques `cv.created.total` sont incrementees.
5. Le client recharge la liste et le detail.

### Generation IA

1. Le client appelle `/api/ai/...`.
2. Le controleur transmet l'identifiant de l'utilisateur JWT au use case.
3. Le service charge le CV par `(cvId, userId)` dans une transaction ; un CV
   absent ou tiers produit le meme `404`, sans construire ni envoyer de prompt.
4. Le backend passe ensuite seulement par `CompositeAiClient`.
5. `ResilientAiClient` applique retry / circuit breaker / timeout.
6. DeepSeek repond ou un fallback mock est utilise selon la panne.
7. Les appels sont journalises sans contenu CV brut.

### Export PDF / DOCX

1. Flutter demande un export sur `/api/cvs/{id}/pdf` ou `/docx`.
2. L'API recharge le CV complet par `(id, userId)` et retourne le meme `404`
   pour un identifiant absent ou tiers.
3. Le service de generation construit le document.
4. Le backend renvoie un binaire telechargeable.

## 6. Decisions structurantes

- Backend monolithique modulaire pour garder un cout d'operation bas.
- Flutter unique pour web et mobile afin de partager l'essentiel du produit.
- PostgreSQL comme source de verite, avec Flyway pour les migrations.
- IA encapsulee derriere des clients resilience4j pour limiter l'impact fournisseur.
- Observabilite native au backend: correlation ID, logs structures, metriques business.
