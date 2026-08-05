import 'package:cv_mobile/features/auth/presentation/components/auth_background.dart';
import 'package:cv_mobile/features/auth/presentation/components/auth_feature_strip.dart';
import 'package:cv_mobile/features/auth/presentation/components/auth_form_field.dart';
import 'package:cv_mobile/features/auth/presentation/components/auth_shell.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(body: child),
      ));

  group('AuthFeatureStrip (#248 C2)', () {
    testWidgets('affiche les 3 puces de benefices', (t) async {
      await pump(t, const AuthFeatureStrip());
      expect(find.byType(AuthFeatureChip), findsNWidgets(3));
    });
  });

  group('AuthFormField (#248 C2)', () {
    testWidgets('label en MAJUSCULES par defaut', (t) async {
      await pump(
        t,
        AuthFormField(
          label: 'Email',
          icon: Icons.email,
          controller: TextEditingController(),
          hint: 'saisir',
        ),
      );
      expect(find.text('EMAIL'), findsOneWidget);
    });

    testWidgets('uppercaseLabel=false conserve la casse', (t) async {
      await pump(
        t,
        AuthFormField(
          label: 'Prénom',
          icon: Icons.person,
          controller: TextEditingController(),
          hint: 'saisir',
          uppercaseLabel: false,
        ),
      );
      expect(find.text('Prénom'), findsOneWidget);
    });

    testWidgets('onChanged remonte la saisie', (t) async {
      String? captured;
      await pump(
        t,
        AuthFormField(
          label: 'Mdp',
          icon: Icons.lock,
          controller: TextEditingController(),
          hint: 'saisir',
          onChanged: (v) => captured = v,
        ),
      );
      await t.enterText(find.byType(TextField), 'abc');
      expect(captured, 'abc');
    });

    testWidgets('affiche l erreur du validator apres soumission', (t) async {
      final formKey = GlobalKey<FormState>();
      await pump(
        t,
        Form(
          key: formKey,
          child: AuthFormField(
            label: 'Email',
            icon: Icons.email,
            controller: TextEditingController(),
            hint: 'saisir',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Champ requis' : null,
          ),
        ),
      );
      formKey.currentState!.validate();
      await t.pump();
      expect(find.text('Champ requis'), findsOneWidget);
    });
  });

  group('AuthShell (#248 C2)', () {
    testWidgets('rend le contenu centre et le fond', (t) async {
      await pump(
        t,
        const AuthShell(child: Text('carte')),
      );
      expect(find.text('carte'), findsOneWidget);
      // Les orbes par defaut (3) sont presentes.
      expect(find.byType(AuthFloatingOrb), findsNWidgets(3));
    });
  });
}
