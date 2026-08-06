import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/core/design_system/theme/app_theme_factory.dart';
import 'package:cv_mobile/core/design_system/theme/app_theme_modes.dart';
import 'package:cv_mobile/features/account/application/delete_account.dart';
import 'package:cv_mobile/features/account/application/export_account_data.dart';
import 'package:cv_mobile/features/account/domain/account_repository.dart';
import 'package:cv_mobile/features/profile/presentation/profile_screen.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/models/notification_preferences.dart';
import 'package:cv_mobile/models/user.dart';
import 'package:cv_mobile/providers/auth_provider.dart';
import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/providers/locale_provider.dart';
import 'package:cv_mobile/providers/notification_provider.dart';
import 'package:cv_mobile/providers/theme_provider.dart';

class _MockAuth extends Mock implements AuthProvider {}

class _MockCv extends Mock implements CvProvider {}

class _MockNotif extends Mock implements NotificationProvider {}

class _MockLocale extends Mock implements LocaleProvider {}

class _FakeAccountRepository implements AccountRepository {
  @override
  Future<Map<String, dynamic>> exportData() async => {'email': 'jean@x.fr'};

  @override
  Future<void> deleteAccount() async {}
}

Cv _fakeCv() => Cv(
      id: 1,
      titre: 'CV',
      educations: const [],
      experiences: const [],
      skills: const [],
      languages: const [],
    );

void main() {
  late _MockAuth auth;
  late _MockCv cv;
  late _MockNotif notif;
  late _MockLocale locale;

  User user() => User(
        id: 1,
        email: 'jean@x.fr',
        prenom: 'Jean',
        nom: 'Dupont',
        role: 'USER',
      );

  setUp(() {
    auth = _MockAuth();
    cv = _MockCv();
    notif = _MockNotif();
    locale = _MockLocale();

    when(() => auth.user).thenReturn(user());
    when(() => auth.logout()).thenAnswer((_) async {});
    when(() => cv.cvs).thenReturn(const []);
    when(() => notif.value).thenReturn(const NotificationPreferences());
    when(() => notif.isLoading).thenReturn(false);
    when(() => notif.load()).thenAnswer((_) async {});
    when(() => locale.locale).thenReturn(const Locale('fr'));
    for (final l in [auth, cv, notif, locale]) {
      when(() => l.addListener(any())).thenReturn(null);
      when(() => l.removeListener(any())).thenReturn(null);
    }
  });

  Widget app(_FakeAccountRepository repo) => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<CvProvider>.value(value: cv),
          ChangeNotifierProvider<NotificationProvider>.value(value: notif),
          ChangeNotifierProvider<LocaleProvider>.value(value: locale),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          theme: AppThemeFactory.build(AppThemeModes.minimal),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: ProfileScreen(
            exportData: ExportAccountDataUseCase(repo),
            deleteAccount: DeleteAccountUseCase(repo),
          ),
        ),
      );

  void mobile(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1.0;
  }

  testWidgets('assemble entete, stats, reglages et actions', (tester) async {
    mobile(tester);
    addTearDown(tester.view.resetPhysicalSize);
    when(() => cv.cvs).thenReturn(List.filled(3, _fakeCv()));

    await tester.pumpWidget(app(_FakeAccountRepository()));
    await tester.pumpAndSettle();

    // Entete + section info affichent le nom ; une carte statistique CV a 3.
    expect(find.text('Jean Dupont'), findsWidgets);
    expect(find.text('jean@x.fr'), findsWidgets);
    expect(find.text('3'), findsOneWidget);

    // Sections de reglages presentes + bouton de deconnexion.
    final l = AppLocalizations.of(tester.element(find.byType(ProfileScreen)))!;
    expect(find.text(l.notifications), findsOneWidget);
    expect(find.text(l.privacy), findsOneWidget);
    expect(find.text(l.logout), findsOneWidget);
  });

  testWidgets('suppression de compte : ouvre le dialog de confirmation',
      (tester) async {
    mobile(tester);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(app(_FakeAccountRepository()));
    await tester.pumpAndSettle();

    final l = AppLocalizations.of(tester.element(find.byType(ProfileScreen)))!;
    await tester.tap(find.text(l.deleteMyAccount));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(l.deleteAccountConfirm), findsOneWidget);
  });

  testWidgets('export : copie le JSON et confirme via snackbar', (tester) async {
    mobile(tester);
    addTearDown(tester.view.resetPhysicalSize);

    // Capture le contenu ecrit dans le presse-papier (canal plateforme).
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(app(_FakeAccountRepository()));
    await tester.pumpAndSettle();

    final l = AppLocalizations.of(tester.element(find.byType(ProfileScreen)))!;
    await tester.tap(find.text(l.exportMyData));
    await tester.pumpAndSettle();

    expect(find.text(l.exportCopied), findsOneWidget);
    expect(copied, contains('jean@x.fr'));
  });
}
