# Guide de lancement - MonCV

## Prerequis

| Outil | Version | Verification |
|-------|---------|-------------|
| Java JDK | 21+ | `java -version` |
| Maven | 3.9+ | `mvn -version` |
| PostgreSQL | 15+ | `psql --version` |
| Flutter | 3.x | `flutter --version` |
| Chrome | derniere | installe |

---

## Etape 1 : Base de donnees PostgreSQL

PostgreSQL doit tourner sur le port **5432** (par defaut).

```bash
# Verifier que PostgreSQL tourne
pg_isready
```

La base `cvmobile` doit exister. Si ce n'est pas le cas :

```bash
psql -U postgres -c "CREATE DATABASE cvmobile;"
```

> Config par defaut : user=`postgres`, password=`seven`, db=`cvmobile`
> Modifiable dans `backend/src/main/resources/application.yml`

---

## Etape 2 : Lancer le Backend (Spring Boot)

```bash
cd backend
mvn spring-boot:run
```

Attendre le message :
```
Started CvMobileApplication in X seconds
Tomcat started on port 8082
```

**Verification** : ouvrir http://localhost:8082/swagger-ui.html

### En cas d'erreur "Port 8082 already in use"

```powershell
# Windows PowerShell
Get-NetTCPConnection -LocalPort 8082 | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```

Puis relancer `mvn spring-boot:run`

---

## Etape 3 : Lancer le Frontend Flutter (Web)

Dans un **nouveau terminal** :

```bash
cd mobile
flutter pub get
flutter run -d chrome --web-port=3001
```

Attendre le message :
```
Flutter run key commands.
r Hot reload.
```

Chrome s'ouvre automatiquement sur http://localhost:3001

### En cas d'erreur "Port 3001 already in use"

```powershell
# Windows PowerShell
Get-NetTCPConnection -LocalPort 3001 | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```

### En cas d'erreur de build (shaders, cache)

```bash
cd mobile
flutter clean
flutter pub get
flutter run -d chrome --web-port=3001
```

---

## Etape 4 : Lancer sur Android (emulateur ou appareil)

```bash
cd mobile
flutter pub get
flutter run
```

> L'emulateur Android utilise `10.0.2.2:8082` pour acceder au backend local.
> Un appareil physique utilise l'IP LAN (ex: `192.168.1.x:8082`).

---

## Lancement rapide (tout en une commande)

### Terminal 1 - Backend
```bash
cd backend && mvn spring-boot:run
```

### Terminal 2 - Frontend Web
```bash
cd mobile && flutter run -d chrome --web-port=3001
```

---

## URLs utiles

| Service | URL |
|---------|-----|
| App Web | http://localhost:3001 |
| API Backend | http://localhost:8082/api |
| Swagger UI | http://localhost:8082/swagger-ui.html |
| API Docs | http://localhost:8082/api-docs |

---

## Comptes de test

| Email | Mot de passe |
|-------|-------------|
| issouf@moncv.com | moncv2024 |

---

## Configuration (application.yml)

| Variable | Defaut | Description |
|----------|--------|-------------|
| `DB_URL` | `jdbc:postgresql://localhost:5432/cvmobile` | URL PostgreSQL |
| `DB_USERNAME` | `postgres` | User BDD |
| `DB_PASSWORD` | `seven` | Mot de passe BDD |
| `SERVER_PORT` | `8082` | Port du backend |
| `JWT_SECRET` | (auto) | Cle JWT |
| `DEEPSEEK_API_KEY` | (configure) | Cle API DeepSeek pour l'IA |

---

## Arreter les serveurs

### Methode 1 : Ctrl+C dans chaque terminal

### Methode 2 : PowerShell
```powershell
# Arreter backend
Get-NetTCPConnection -LocalPort 8082 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }

# Arreter frontend
Get-NetTCPConnection -LocalPort 3001 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```

---

## Problemes courants

| Probleme | Solution |
|----------|----------|
| `Port already in use` | Tuer le processus (voir ci-dessus) |
| `JWT_SECRET not found` | Deja configure avec valeur par defaut |
| `SocketException` Google Font | Pas grave, police par defaut utilisee |
| `ShaderCompilerException` | `flutter clean` puis relancer |
| Backend ne demarre pas | Verifier que PostgreSQL tourne |
| `Flyway migration failed` | Verifier que la BDD `cvmobile` existe |
