# MonCV — Redesign UI & Support Android/iOS

**Date:** 2026-03-24
**Statut:** Approuvé par l'utilisateur

---

## Contexte

L'application MonCV est une app Flutter qui permet de créer et gérer des CVs professionnels. Elle tourne actuellement uniquement sur Flutter Web. L'objectif est :

1. Ajouter le support Android et iOS (`flutter create --platforms android,ios .`)
2. Refaire entièrement l'UI avec un design moderne, inspiré des meilleures apps existantes (Linear, Canva, Stripe)
3. Introduire un système de 3 thèmes sélectionnables par l'utilisateur

---

## Architecture existante (à conserver)

- **Backend** : Spring Boot sur port 8082, API REST, JWT, PostgreSQL
- **Flutter** : go_router v13, Provider, `TokenStorage` (web/mobile), `ApiService`
- **Navigation** : go_router avec redirects auth (`/landing`, `/login`, `/register`, `/home`, `/cvs/*`)
- **Tests** : mocktail, tests unitaires providers + widgets

---

## Design System

### 3 Thèmes

| Thème | Identifiant | Ambiance |
|-------|-------------|----------|
| Moderne & Minimal | `minimal` | Fond blanc `#FFFFFF`, primaire `#1976D2`, texte `#1A1A2E`, ombres légères |
| Vibrant & Dynamique | `vibrant` | Dégradé `#667eea → #764ba2`, fond `#F5F0FF`, accents violets |
| Premium & Élégant | `premium` | Fond `#0F1117`, surface `#1A1D2E`, or `#FFD700`, texte blanc |

**Stockage du thème** : `SharedPreferences` (clé `app_theme`), chargé au démarrage via `ThemeProvider`.

### Typographie
- Police : **Poppins** (déjà intégrée)
- Hiérarchie : `headlineLarge` (28px bold), `titleLarge` (20px semibold), `bodyMedium` (14px), `labelSmall` (11px)

### Espacements & Rayons
- Padding standard : 16px / 24px
- Border radius cartes : 16px
- Border radius boutons : 12px
- Ombres cartes : `BoxShadow(blurRadius: 16, color: Colors.black.withOpacity(0.08))`

---

## Navigation

### Mobile (< 600px) — Bottom Navigation Bar
3 onglets :
- `CVs` (index 0) — icône `description_outlined` → `/home`
- `Nouveau` (index 1) — bouton central FAB-style → `/cvs/create`
- `Profil` (index 2) — icône `person_outline` → `/profile`

### Web/Tablette (≥ 600px) — Sidebar fixe
Largeur 200px, items verticaux avec icône + label :
- Mes CVs
- Nouveau CV
- Profil

---

## Écrans et composants

### 1. `LandingScreen` (web uniquement, `/landing`)
- Hero section : titre, sous-titre, 2 CTA (`Se connecter`, `Créer un compte`)
- Section features : 3 cards (Créer, Exporter PDF, Accéder partout)
- Navbar : logo + liens auth
- Footer minimal

### 2. `LoginScreen` et `RegisterScreen`
- Layout centré avec `CenteredFormLayout` (max 440px)
- Logo + nom app en haut
- Champs avec icônes, validation inline
- Bouton principal full-width
- Lien de navigation (login ↔ register)

### 3. `HomeScreen` — Liste des CVs
- AppBar ou sidebar selon plateforme
- **Carte CV (option C — riche)** :
  - Header : titre du CV + badge statut (`Complet` vert / `Incomplet` orange)
  - Date de modification
  - Row stats : `X exp.` | `X compétences` | `X formations`
  - Actions : `Voir` (primary) · `PDF` · `Modifier` (icône)
- Mobile : liste verticale, 1 colonne
- Web : grille 2-3 colonnes selon largeur
- FAB mobile / bouton AppBar web : `+ Nouveau CV`
- État vide : illustration + message + CTA

### 4. `ProfileScreen` (`/profile`)
- Infos utilisateur (nom, prénom, email)
- **Sélecteur de thème** : 3 cards cliquables avec preview couleur + nom
- Bouton déconnexion

### 5. `CvDetailScreen`
- Sections dépliables : Infos personnelles, Expériences, Formations, Compétences, Langues
- Bouton flottant `Modifier`
- Bouton `Télécharger PDF`

### 6. `CvFormScreen`
- Formulaire multi-étapes (stepper) ou scroll continu
- Sections : Infos perso → Expériences → Formations → Compétences → Langues
- Validation par section avant navigation

---

## Nouveaux fichiers à créer

| Fichier | Rôle |
|---------|------|
| `lib/providers/theme_provider.dart` | Gestion thème actif + persistance |
| `lib/utils/app_theme.dart` | Définition des 3 ThemeData |
| `lib/widgets/cv_card.dart` | Carte CV riche (option C) |
| `lib/widgets/theme_selector.dart` | Widget sélecteur de thème |
| `lib/widgets/stats_badge.dart` | Badge stat (icône + chiffre + label) |
| `lib/screens/profile/profile_screen.dart` | Écran profil + thème |
| `lib/widgets/app_scaffold.dart` | Scaffold avec bottom nav (mobile) ou sidebar (web) |

---

## Fichiers à modifier

| Fichier | Changement |
|---------|-----------|
| `lib/main.dart` | Ajouter `ThemeProvider`, connecter `theme` de `MaterialApp.router` |
| `lib/router.dart` | Ajouter route `/profile` |
| `lib/utils/constants.dart` | Étendre `AppColors` pour les 3 thèmes |
| `lib/screens/home/home_screen.dart` | Utiliser `AppScaffold` + `CvCard` |
| `lib/screens/landing/landing_screen.dart` | Redesign complet |
| `lib/screens/auth/login_screen.dart` | Redesign |
| `lib/screens/auth/register_screen.dart` | Redesign |
| `lib/screens/cv/cv_detail_screen.dart` | Redesign avec sections dépliables |
| `lib/screens/cv/cv_form_screen.dart` | Ajouter stepper ou scroll continu |
| `mobile/pubspec.yaml` | Ajouter `shared_preferences` si absent |

---

## Support Android/iOS

Commande d'initialisation :
```bash
cd mobile && flutter create --platforms android,ios .
```

Permissions Android (`AndroidManifest.xml`) :
- `INTERNET` (déjà nécessaire pour l'API)

Permissions iOS (`Info.plist`) :
- Aucune permission spéciale requise pour cette app

---

## Séquence d'implémentation

1. Ajouter les plateformes Android/iOS
2. Créer `ThemeProvider` + `app_theme.dart` (3 ThemeData)
3. Connecter le thème à `main.dart`
4. Créer `AppScaffold` (bottom nav mobile + sidebar web)
5. Créer widgets réutilisables (`CvCard`, `StatsBadge`, `ThemeSelector`)
6. Créer `ProfileScreen`
7. Redesign `LandingScreen`
8. Redesign `LoginScreen` + `RegisterScreen`
9. Redesign `HomeScreen`
10. Redesign `CvDetailScreen`
11. Redesign `CvFormScreen`
12. Connecter router (`/profile`)
13. Tests de non-régression

---

## Critères de succès

- `flutter analyze` : 0 erreur
- Les 3 thèmes s'appliquent instantanément et persistent entre sessions
- Navigation bottom nav (mobile) + sidebar (web) fonctionnelle
- Cartes CV affichent stats correctes depuis le modèle `Cv`
- Android et iOS configurés (compilables)
- Aucune régression sur les tests existants
