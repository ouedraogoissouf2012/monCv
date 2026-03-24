# MonCV Redesign UI — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter Android/iOS, introduire 3 thèmes sélectionnables et refaire entièrement l'UI de MonCV avec un design moderne et professionnel.

**Architecture:** `ThemeProvider` gère le thème actif (persisté via `SharedPreferences`). `AppScaffold` encapsule la navigation (bottom nav mobile / sidebar web). Tous les écrans sont redesignés et utilisent les widgets réutilisables `CvCard`, `StatsBadge` et `ThemeSelector`.

**Tech Stack:** Flutter 3.x, go_router v13, Provider, SharedPreferences, mocktail (tests), Poppins (Google Fonts)

---

## Fichiers créés / modifiés

| Action | Fichier | Rôle |
|--------|---------|------|
| Créer | `mobile/lib/providers/theme_provider.dart` | Enum `AppTheme`, `ThemeProvider`, persistance |
| Créer | `mobile/lib/utils/app_theme.dart` | 3 `ThemeData` (minimal, vibrant, premium) |
| Créer | `mobile/lib/widgets/app_scaffold.dart` | Scaffold universel : bottom nav (mobile) + sidebar (web) |
| Créer | `mobile/lib/widgets/cv_card.dart` | Carte CV riche avec stats |
| Créer | `mobile/lib/widgets/stats_badge.dart` | Badge icône + chiffre + label |
| Créer | `mobile/lib/widgets/theme_selector.dart` | 3 cards de sélection de thème |
| Créer | `mobile/lib/screens/profile/profile_screen.dart` | Profil utilisateur + sélecteur thème |
| Modifier | `mobile/lib/main.dart` | Ajouter ThemeProvider, Consumer thème |
| Modifier | `mobile/lib/router.dart` | Ajouter route `/profile` |
| Modifier | `mobile/lib/screens/landing/landing_screen.dart` | Redesign + go_router |
| Modifier | `mobile/lib/screens/auth/login_screen.dart` | Redesign |
| Modifier | `mobile/lib/screens/auth/register_screen.dart` | Redesign |
| Modifier | `mobile/lib/screens/home/home_screen.dart` | Utiliser AppScaffold + CvCard |
| Modifier | `mobile/lib/screens/cv/cv_detail_screen.dart` | Redesign sections dépliables |
| Modifier | `mobile/lib/screens/cv/cv_form_screen.dart` | Scroll continu + sticky save button |
| Créer | `mobile/test/widgets/cv_card_test.dart` | Tests widget CvCard |
| Créer | `mobile/test/widgets/app_scaffold_test.dart` | Tests widget AppScaffold |
| Créer | `mobile/test/widgets/theme_selector_test.dart` | Tests widget ThemeSelector |

---

## Task 1 : Ajouter les plateformes Android et iOS

**Files:**
- Run: `cd mobile && flutter create --platforms android,ios .`

- [ ] **Step 1 : Générer les dossiers Android et iOS**

```bash
cd "c:/Users/USER PC/Documents/propre à moi/creqteCVmobil/mobile"
flutter create --platforms android,ios .
```

Répondre `y` si demandé pour écraser des fichiers existants.

- [ ] **Step 2 : Vérifier les dossiers générés**

```bash
ls android/ && ls ios/
```

Attendu : les deux dossiers existent.

- [ ] **Step 3 : Vérifier la permission INTERNET dans AndroidManifest**

Ouvrir `android/app/src/main/AndroidManifest.xml`. Vérifier que cette ligne est présente dans `<manifest>` :

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Si absente, l'ajouter juste avant `<application>`.

- [ ] **Step 4 : Vérifier que flutter analyze passe**

```bash
cd "c:/Users/USER PC/Documents/propre à moi/creqteCVmobil/mobile"
flutter analyze
```

Attendu : 0 erreur.

- [ ] **Step 5 : Commit**

```bash
git add mobile/android/ mobile/ios/ mobile/linux/ mobile/windows/ mobile/macos/ mobile/.gitignore mobile/.metadata
git commit -m "feat: ajouter support Android et iOS"
```

---

## Task 2 : ThemeProvider + définition des 3 thèmes

**Files:**
- Create: `mobile/lib/providers/theme_provider.dart`
- Create: `mobile/lib/utils/app_theme.dart`

- [ ] **Step 1 : Créer `theme_provider.dart`**

```dart
// mobile/lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { minimal, vibrant, premium }

class ThemeProvider with ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.minimal;

  AppThemeMode get mode => _mode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('app_theme') ?? 'minimal';
    _mode = AppThemeMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppThemeMode.minimal,
    );
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', mode.name);
  }
}
```

- [ ] **Step 2 : Créer `app_theme.dart`**

```dart
// mobile/lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class AppThemes {
  static ThemeData get(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.vibrant:
        return _vibrant;
      case AppThemeMode.premium:
        return _premium;
      case AppThemeMode.minimal:
      default:
        return _minimal;
    }
  }

  // ── MINIMAL ──────────────────────────────────────────────
  static final ThemeData _minimal = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF3B82F6),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1E293B),
      error: Color(0xFFEF4444),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF1E293B),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black12,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  // ── VIBRANT ──────────────────────────────────────────────
  static final ThemeData _vibrant = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF667EEA),
      secondary: Color(0xFF764BA2),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1A2E),
      error: Color(0xFFEF4444),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F0FF),
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF5F0FF),
      foregroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEDE9FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  // ── PREMIUM ──────────────────────────────────────────────
  static final ThemeData _premium = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFD700),
      secondary: Color(0xFFFFA500),
      surface: Color(0xFF1A1D2E),
      onSurface: Color(0xFFE0E0E0),
      error: Color(0xFFEF4444),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F1117),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F1117),
      foregroundColor: Color(0xFFE0E0E0),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1D2E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x26FFD700), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: const Color(0xFF0F1117),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF252840),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x33FFD700)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
```

- [ ] **Step 3 : Commit**

```bash
git add mobile/lib/providers/theme_provider.dart mobile/lib/utils/app_theme.dart
git commit -m "feat: ajouter ThemeProvider et les 3 ThemeData (minimal, vibrant, premium)"
```

---

## Task 3 : Connecter le thème à main.dart

**Files:**
- Modify: `mobile/lib/main.dart`

- [ ] **Step 1 : Réécrire main.dart**

```dart
// mobile/lib/main.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cv_provider.dart';
import 'providers/theme_provider.dart';
import 'router.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRouter.create(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => CvProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'MonCV',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppThemes.get(themeProvider.mode),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2 : Vérifier flutter analyze**

```bash
cd "c:/Users/USER PC/Documents/propre à moi/creqteCVmobil/mobile"
flutter analyze
```

Attendu : 0 erreur.

- [ ] **Step 3 : Commit**

```bash
git add mobile/lib/main.dart
git commit -m "feat: connecter ThemeProvider à MaterialApp.router"
```

---

## Task 4 : AppScaffold (bottom nav mobile + sidebar web)

**Files:**
- Create: `mobile/lib/widgets/app_scaffold.dart`

- [ ] **Step 1 : Créer `app_scaffold.dart`**

```dart
// mobile/lib/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/responsive.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.push('/cvs/create');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              currentIndex: currentIndex,
              onTap: (i) => _onNavTap(context, i),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Scaffold(
                appBar: title != null
                    ? AppBar(
                        title: Text(title!),
                        actions: actions,
                        automaticallyImplyLeading: false,
                      )
                    : null,
                body: body,
                floatingActionButton: floatingActionButton,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              actions: actions,
              automaticallyImplyLeading: false,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        onTap: (i) => _onNavTap(context, i),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _Sidebar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      (Icons.description_outlined, Icons.description, 'Mes CVs'),
      (Icons.add_circle_outline, Icons.add_circle, 'Nouveau'),
      (Icons.person_outline, Icons.person, 'Profil'),
    ];

    return Container(
      width: 200,
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.description_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'MonCV',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isSelected = currentIndex == i;
            return _SidebarItem(
              icon: isSelected ? item.$2 : item.$1,
              label: item.$3,
              isSelected: isSelected,
              onTap: () => onTap(i),
            );
          }),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Mes CVs',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: 'Nouveau',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
```

- [ ] **Step 2 : flutter analyze**

```bash
flutter analyze
```

- [ ] **Step 3 : Commit**

```bash
git add mobile/lib/widgets/app_scaffold.dart
git commit -m "feat: créer AppScaffold avec bottom nav (mobile) et sidebar (web)"
```

---

## Task 5 : Widgets réutilisables (StatsBadge, CvCard, ThemeSelector)

**Files:**
- Create: `mobile/lib/widgets/stats_badge.dart`
- Create: `mobile/lib/widgets/cv_card.dart`
- Create: `mobile/lib/widgets/theme_selector.dart`

- [ ] **Step 1 : Créer `stats_badge.dart`**

```dart
// mobile/lib/widgets/stats_badge.dart
import 'package:flutter/material.dart';

class StatsBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const StatsBadge({
    super.key,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2 : Créer `cv_card.dart`**

```dart
// mobile/lib/widgets/cv_card.dart
import 'package:flutter/material.dart';
import '../models/cv.dart';
import 'stats_badge.dart';

class CvCard extends StatelessWidget {
  final Cv cv;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDownloadPdf;

  const CvCard({
    super.key,
    required this.cv,
    required this.onTap,
    required this.onEdit,
    required this.onDownloadPdf,
  });

  bool get _isComplete =>
      cv.personalInfo != null &&
      (cv.experiences.isNotEmpty || cv.educations.isNotEmpty);

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header : titre + badge statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cv.titre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isComplete
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isComplete ? 'Complet' : 'Incomplet',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _isComplete
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Date
              Text(
                _formatDate(cv.updatedAt ?? cv.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
              ),
              const SizedBox(height: 12),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatsBadge(
                    count: cv.experiences.length,
                    label: 'Exp.',
                    color: colorScheme.primary,
                  ),
                  StatsBadge(
                    count: cv.skills.length,
                    label: 'Compét.',
                    color: colorScheme.secondary,
                  ),
                  StatsBadge(
                    count: cv.educations.length,
                    label: 'Formations',
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Divider
              Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.1)),
              const SizedBox(height: 10),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Voir'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onDownloadPdf,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                    child: const Text('PDF'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3 : Créer `theme_selector.dart`**

```dart
// mobile/lib/widgets/theme_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final themes = [
      (
        AppThemeMode.minimal,
        'Minimal',
        const Color(0xFF2563EB),
        const Color(0xFFF8FAFC),
        Icons.wb_sunny_outlined,
      ),
      (
        AppThemeMode.vibrant,
        'Vibrant',
        const Color(0xFF667EEA),
        const Color(0xFFF5F0FF),
        Icons.palette_outlined,
      ),
      (
        AppThemeMode.premium,
        'Premium',
        const Color(0xFFFFD700),
        const Color(0xFF0F1117),
        Icons.stars_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thème',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: themes.map((t) {
            final isSelected = themeProvider.mode == t.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ThemeCard(
                  mode: t.$1,
                  label: t.$2,
                  primary: t.$3,
                  background: t.$4,
                  icon: t.$5,
                  isSelected: isSelected,
                  onTap: () => context.read<ThemeProvider>().setTheme(t.$1),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppThemeMode mode;
  final String label;
  final Color primary;
  final Color background;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.mode,
    required this.label,
    required this.primary,
    required this.background,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8)]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.normal,
                color: primary,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primary, size: 14),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4 : flutter analyze**

```bash
flutter analyze
```

- [ ] **Step 5 : Commit**

```bash
git add mobile/lib/widgets/stats_badge.dart mobile/lib/widgets/cv_card.dart mobile/lib/widgets/theme_selector.dart
git commit -m "feat: créer widgets réutilisables (StatsBadge, CvCard, ThemeSelector)"
```

---

## Task 6 : ProfileScreen + route /profile

**Files:**
- Create: `mobile/lib/screens/profile/profile_screen.dart`
- Modify: `mobile/lib/router.dart`

- [ ] **Step 1 : Créer le dossier et le fichier**

```dart
// mobile/lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/theme_selector.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      currentIndex: 2,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Avatar + nom
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primary.withOpacity(0.15),
                    child: Text(
                      _initials(user?.fullName),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Utilisateur',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Infos
            _SectionTitle('Informations'),
            const SizedBox(height: 12),
            _InfoTile(icon: Icons.person_outline, label: 'Nom complet', value: user?.fullName ?? '—'),
            _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '—'),
            const SizedBox(height: 32),
            // Thème
            _SectionTitle('Apparence'),
            const SizedBox(height: 12),
            const ThemeSelector(),
            const SizedBox(height: 40),
            // Déconnexion
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Se déconnecter',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            letterSpacing: 0.8,
          ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      )),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2 : Ajouter la route `/profile` dans router.dart**

Dans `mobile/lib/router.dart`, ajouter l'import et la route :

```dart
// Ajouter l'import en haut du fichier :
import 'screens/profile/profile_screen.dart';

// Ajouter dans la liste routes[] :
GoRoute(
  path: '/profile',
  builder: (context, state) => const ProfileScreen(),
),
```

- [ ] **Step 3 : flutter analyze**

```bash
flutter analyze
```

- [ ] **Step 4 : Commit**

```bash
git add mobile/lib/screens/profile/profile_screen.dart mobile/lib/router.dart
git commit -m "feat: créer ProfileScreen avec sélecteur de thème et route /profile"
```

---

## Task 7 : Redesign LandingScreen

**Files:**
- Modify: `mobile/lib/screens/landing/landing_screen.dart`

- [ ] **Step 1 : Réécrire landing_screen.dart**

```dart
// mobile/lib/screens/landing/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/responsive.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar transparente
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Icon(Icons.description_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('MonCV',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Connexion'),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Créer un compte'),
                ),
              ),
            ],
          ),
          // Contenu
          SliverToBoxAdapter(
            child: Column(
              children: [
                _HeroSection(),
                _FeaturesSection(),
                _CtaSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Responsive.isDesktop(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: isDesktop ? 80 : 48,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.description_outlined,
                size: 44, color: colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Créez votre CV\nprofessionnel',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              'Concevez, personnalisez et exportez votre CV en PDF en quelques minutes. Simple, rapide et professionnel.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    height: 1.6,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => GoRouter.of(context).go('/register'),
                icon: const Icon(Icons.add),
                label: const Text('Commencer gratuitement'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                ),
              ),
              OutlinedButton(
                onPressed: () => GoRouter.of(context).go('/login'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                ),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = Responsive.isDesktop(context);

    final features = [
      (Icons.edit_note_outlined, 'Créez facilement',
          'Remplissez vos informations guidé par une interface intuitive.'),
      (Icons.picture_as_pdf_outlined, 'Exportez en PDF',
          'Générez un PDF professionnel d\'un simple clic.'),
      (Icons.devices_outlined, 'Accédez partout',
          'Web, mobile, tablette — votre CV toujours avec vous.'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: 48,
      ),
      child: Column(
        children: [
          Text(
            'Tout ce dont vous avez besoin',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          isDesktop
              ? Row(
                  children: features
                      .map((f) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: _FeatureCard(
                                  icon: f.$1, title: f.$2, desc: f.$3),
                            ),
                          ))
                      .toList(),
                )
              : Column(
                  children: features
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FeatureCard(
                                icon: f.$1, title: f.$2, desc: f.$3),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(desc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      height: 1.5,
                    )),
          ],
        ),
      ),
    );
  }
}

class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Prêt à créer votre CV ?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Rejoignez des milliers de professionnels qui font confiance à MonCV.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colorScheme.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text('Créer mon CV gratuitement',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2 : Commit**

```bash
git add mobile/lib/screens/landing/landing_screen.dart
git commit -m "feat: redesign LandingScreen avec hero, features et CTA"
```

---

## Task 8 : Redesign LoginScreen + RegisterScreen

**Files:**
- Modify: `mobile/lib/screens/auth/login_screen.dart`
- Modify: `mobile/lib/screens/auth/register_screen.dart`

- [ ] **Step 1 : Réécrire login_screen.dart**

```dart
// mobile/lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/responsive_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erreur de connexion'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CenteredFormLayout(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  // Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.description_outlined,
                          size: 40, color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'MonCV',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bon retour !',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 40),
                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  // Mot de passe
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 24),
                  // Bouton
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => FilledButton(
                      onPressed: auth.isLoading ? null : _login,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : const Text('Se connecter',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Lien inscription
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Pas encore de compte ?',
                          style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6))),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Créer un compte'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2 : Réécrire register_screen.dart**

```dart
// mobile/lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/responsive_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      prenom: _prenomCtrl.text.trim(),
      nom: _nomCtrl.text.trim(),
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erreur d\'inscription'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CenteredFormLayout(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.person_add_outlined,
                          size: 32, color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Créer un compte',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rejoignez MonCV gratuitement',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _prenomCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Prénom'),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Requis' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _nomCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Nom'),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Requis' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      if (v.length < 6) return 'Minimum 6 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => FilledButton(
                      onPressed: auth.isLoading ? null : _register,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : const Text('Créer mon compte',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Déjà un compte ?',
                          style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6))),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Se connecter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3 : flutter analyze**

```bash
flutter analyze
```

- [ ] **Step 4 : Commit**

```bash
git add mobile/lib/screens/auth/login_screen.dart mobile/lib/screens/auth/register_screen.dart
git commit -m "feat: redesign LoginScreen et RegisterScreen"
```

---

## Task 9 : Redesign HomeScreen

**Files:**
- Modify: `mobile/lib/screens/home/home_screen.dart`

- [ ] **Step 1 : Réécrire home_screen.dart**

```dart
// mobile/lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cv_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cv_card.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CvProvider>().loadCvs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      currentIndex: 0,
      title: 'Mes CVs',
      actions: isDesktop
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () => context.push('/cvs/create'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau CV'),
                ),
              ),
            ]
          : null,
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/cvs/create'),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau CV'),
            ),
      body: Consumer<CvProvider>(
        builder: (context, cvProvider, _) {
          if (cvProvider.isLoading && cvProvider.cvs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (cvProvider.cvs.isEmpty) {
            return _EmptyState();
          }
          final crossAxisCount = isDesktop
              ? (MediaQuery.of(context).size.width > 1200 ? 3 : 2)
              : 1;
          return GridView.builder(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.4,
            ),
            itemCount: cvProvider.cvs.length,
            itemBuilder: (context, index) {
              final cv = cvProvider.cvs[index];
              return CvCard(
                cv: cv,
                onTap: () => context.push('/cvs/${cv.id}'),
                onEdit: () => context.push('/cvs/${cv.id}/edit', extra: cv),
                onDownloadPdf: () => _downloadPdf(context, cv.id!),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context, int cvId) async {
    try {
      final apiService = ApiService();
      await apiService.downloadCvPdf(cvId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur téléchargement PDF: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.description_outlined,
                  size: 50, color: colorScheme.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun CV pour l\'instant',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre premier CV professionnel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/cvs/create'),
              icon: const Icon(Icons.add),
              label: const Text('Créer mon premier CV'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2 : Vérifier que `ApiService.downloadCvPdf` existe**

Ouvrir `mobile/lib/services/api_service.dart` et vérifier qu'une méthode `downloadCvPdf(int id)` existe. Le pattern existant dans ce fichier appelle `GET /cvs/{id}/pdf` et écrit le fichier localement via `path_provider` + `open_file`. Utiliser ce même pattern dans `_downloadPdf`. Si la méthode est nommée différemment, adapter l'appel.

- [ ] **Step 3 : flutter analyze**

```bash
flutter analyze
```

- [ ] **Step 4 : Commit**

```bash
git add mobile/lib/screens/home/home_screen.dart
git commit -m "feat: redesign HomeScreen avec grille CvCard et AppScaffold"
```

---

## Task 10 : Redesign CvDetailScreen

**Files:**
- Modify: `mobile/lib/screens/cv/cv_detail_screen.dart`

- [ ] **Step 1 : Refactoriser cv_detail_screen.dart**

Ouvrir `mobile/lib/screens/cv/cv_detail_screen.dart` et faire les changements suivants :

1. Remplacer l'`AppBar` classique par un `SliverAppBar` avec `expandedHeight: 180` et un fond en gradient du thème actif
2. Entourer le `Scaffold` d'un `AppScaffold` avec `currentIndex: 0`
3. Remplacer les anciennes sections par des `ExpansionTile` (sections dépliables) :
   - Infos personnelles
   - Expériences
   - Formations
   - Compétences
   - Langues
4. Ajouter un `FloatingActionButton` avec icône `edit` qui navigue vers `/cvs/${cv.id}/edit`
5. Ajouter un bouton `Télécharger PDF` dans la top bar ou en bas

Structure cible :

```dart
Scaffold(
  body: CustomScrollView(
    slivers: [
      SliverAppBar(
        expandedHeight: 180,
        flexibleSpace: FlexibleSpaceBar(
          title: Text(cv.titre),
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      SliverToBoxAdapter(
        child: Column(children: [
          _buildExpansionSection('Infos personnelles', Icons.person_outline, ...),
          _buildExpansionSection('Expériences', Icons.work_outline, ...),
          // etc.
        ]),
      ),
    ],
  ),
  floatingActionButton: FloatingActionButton(
    onPressed: () => context.push('/cvs/${cv.id}/edit', extra: cv),
    child: const Icon(Icons.edit),
  ),
)
```

- [ ] **Step 2 : flutter analyze**

```bash
flutter analyze
```

- [ ] **Step 3 : Commit**

```bash
git add mobile/lib/screens/cv/cv_detail_screen.dart
git commit -m "feat: redesign CvDetailScreen avec SliverAppBar et sections dépliables"
```

---

## Task 11 : Redesign CvFormScreen (scroll continu)

**Files:**
- Modify: `mobile/lib/screens/cv/cv_form_screen.dart`
- Note: les fichiers `mobile/lib/screens/cv/sections/*.dart` (`PersonalInfoSection`, `ExperienceSection`, `EducationSection`, `SkillsSection`, `LanguagesSection`) sont utilisés **tels quels** sans modification — il suffit de les importer dans le nouveau layout.

- [ ] **Step 1 : Mettre à jour cv_form_screen.dart**

Remplacer le layout actuel par :
- `Scaffold` avec `AppBar` (titre `'Nouveau CV'` ou `'Modifier le CV'`)
- `body` : `SingleChildScrollView` contenant toutes les sections dans des `Card` avec `ExpansionTile`
- Bouton `Enregistrer` collé en bas avec `BottomAppBar` ou `Padding` sticky

Structure cible :

```dart
Scaffold(
  appBar: AppBar(title: Text(cv == null ? 'Nouveau CV' : 'Modifier le CV')),
  body: Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _SectionCard(title: 'Informations personnelles', icon: Icons.person_outline, child: PersonalInfoSection(...)),
            _SectionCard(title: 'Expériences', icon: Icons.work_outline, child: ExperienceSection(...)),
            _SectionCard(title: 'Formations', icon: Icons.school_outlined, child: EducationSection(...)),
            _SectionCard(title: 'Compétences', icon: Icons.star_outline, child: SkillsSection(...)),
            _SectionCard(title: 'Langues', icon: Icons.language_outlined, child: LanguagesSection(...)),
          ]),
        ),
      ),
      // Sticky save button
      Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : _save,
            child: Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    ],
  ),
)
```

Widget helper `_SectionCard` :

```dart
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        initiallyExpanded: true,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: child),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2 : flutter analyze**

```bash
flutter analyze
```

- [ ] **Step 3 : Commit**

```bash
git add mobile/lib/screens/cv/cv_form_screen.dart
git commit -m "feat: redesign CvFormScreen avec scroll continu et bouton sticky"
```

---

## Task 12 : Tests de non-régression

**Files:**
- Create: `mobile/test/widgets/cv_card_test.dart`
- Create: `mobile/test/widgets/app_scaffold_test.dart`
- Create: `mobile/test/widgets/theme_selector_test.dart`

- [ ] **Step 1 : Créer `cv_card_test.dart`**

```dart
// mobile/test/widgets/cv_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/widgets/cv_card.dart';

void main() {
  group('CvCard', () {
    final cv = Cv(
      id: 1,
      titre: 'CV Test',
      personalInfo: PersonalInfo(nom: 'Doe', prenom: 'John', email: 'j@d.com'),
      experiences: [
        Experience(
          poste: 'Dev',
          entreprise: 'ACME',
          dateDebut: '2020-01',
          dateFin: null,
          enPoste: true,
          description: '',
        )
      ],
      educations: [],
      skills: [],
      languages: [],
    );

    testWidgets('affiche le titre du CV', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CvCard(
            cv: cv,
            onTap: () {},
            onEdit: () {},
            onDownloadPdf: () {},
          ),
        ),
      ));
      expect(find.text('CV Test'), findsOneWidget);
    });

    testWidgets('affiche le badge Complet quand personalInfo + exp', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CvCard(
            cv: cv,
            onTap: () {},
            onEdit: () {},
            onDownloadPdf: () {},
          ),
        ),
      ));
      expect(find.text('Complet'), findsOneWidget);
    });

    testWidgets('affiche le badge Incomplet sans expériences ni formations', (tester) async {
      final incomplet = Cv(id: 2, titre: 'Vide', experiences: [], educations: []);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CvCard(
            cv: incomplet,
            onTap: () {},
            onEdit: () {},
            onDownloadPdf: () {},
          ),
        ),
      ));
      expect(find.text('Incomplet'), findsOneWidget);
    });

    testWidgets('affiche le bon nombre d\'expériences dans les stats', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CvCard(
            cv: cv,
            onTap: () {},
            onEdit: () {},
            onDownloadPdf: () {},
          ),
        ),
      ));
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('appelle onTap quand on tape sur Voir', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CvCard(
            cv: cv,
            onTap: () => tapped = true,
            onEdit: () {},
            onDownloadPdf: () {},
          ),
        ),
      ));
      await tester.tap(find.text('Voir'));
      expect(tapped, isTrue);
    });
  });
}
```

- [ ] **Step 2 : Créer `app_scaffold_test.dart`**

```dart
// mobile/test/widgets/app_scaffold_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cv_mobile/widgets/app_scaffold.dart';

Widget _wrap(Widget child) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => child),
    GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('Home'))),
    GoRoute(path: '/profile', builder: (_, __) => const Scaffold(body: Text('Profile'))),
    GoRoute(path: '/cvs/create', builder: (_, __) => const Scaffold(body: Text('Create'))),
  ]);
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('AppScaffold', () {
    testWidgets('affiche NavigationBar sur mobile', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap(
        const AppScaffold(currentIndex: 0, body: Text('Content')),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3 : Créer `theme_selector_test.dart`**

```dart
// mobile/test/widgets/theme_selector_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cv_mobile/providers/theme_provider.dart';
import 'package:cv_mobile/widgets/theme_selector.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: child,
      ),
    ),
  );
}

void main() {
  group('ThemeSelector', () {
    testWidgets('affiche 3 options de thème', (tester) async {
      await tester.pumpWidget(_wrap(const ThemeSelector()));
      await tester.pump();
      expect(find.text('Minimal'), findsOneWidget);
      expect(find.text('Vibrant'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 4 : Lancer les tests**

```bash
cd "c:/Users/USER PC/Documents/propre à moi/creqteCVmobil/mobile"
flutter test test/widgets/cv_card_test.dart test/widgets/app_scaffold_test.dart test/widgets/theme_selector_test.dart
```

Attendu : tous les tests passent.

- [ ] **Step 5 : Lancer tous les tests existants**

```bash
flutter test
```

Attendu : 0 régression.

- [ ] **Step 6 : flutter analyze final**

```bash
flutter analyze
```

Attendu : 0 erreur.

- [ ] **Step 7 : Commit final**

```bash
git add mobile/test/widgets/cv_card_test.dart mobile/test/widgets/app_scaffold_test.dart mobile/test/widgets/theme_selector_test.dart
git commit -m "test: ajouter tests widgets CvCard, AppScaffold et ThemeSelector"
```

---

## Critères de validation finale

- [ ] `flutter analyze` : 0 erreur
- [ ] `flutter test` : 0 régression
- [ ] Dossiers `android/` et `ios/` présents dans `mobile/`
- [ ] 3 thèmes s'appliquent instantanément depuis ProfileScreen
- [ ] Bottom nav visible sur mobile (< 600px)
- [ ] Sidebar visible sur web/desktop (≥ 600px)
- [ ] `CvCard` affiche stats et badge Complet/Incomplet correctement
- [ ] Landing page utilise go_router (`context.go`) plus `Navigator.push`
