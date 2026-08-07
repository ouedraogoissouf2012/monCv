import 'dart:async';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/public_portfolio/domain/public_portfolio_repository.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/screens/share/public_portfolio_screen.dart';
import 'package:cv_mobile/services/i_api_client.dart';
import 'package:cv_mobile/services/share_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockApiClient extends Mock implements IApiClient {}

class _MockPublicPortfolioRepository extends Mock
    implements PublicPortfolioRepository {}

void main() {
  testWidgets(
    'une ancienne requete lente ne remplace pas le nouveau portfolio',
    (tester) async {
      const firstToken = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const secondToken = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
      final first = Completer<Result<Cv>>();
      final second = Completer<Result<Cv>>();
      final repo = _MockPublicPortfolioRepository();
      when(() => repo.getPortfolio(firstToken)).thenAnswer((_) => first.future);
      when(() => repo.getPortfolio(secondToken)).thenAnswer((_) => second.future);

      await tester.pumpWidget(_app(repo, firstToken));
      await tester.pumpWidget(_app(repo, secondToken));

      second.complete(Result.success(Cv(titre: 'Portfolio recent')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Portfolio recent'), findsOneWidget);

      first.complete(Result.success(Cv(titre: 'Portfolio obsolete')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Portfolio recent'), findsOneWidget);
      expect(find.text('Portfolio obsolete'), findsNothing);
    },
  );
}

Widget _app(PublicPortfolioRepository repo, String token) {
  return MultiProvider(
    providers: [
      // ShareService n'est pas sollicite dans ce test (pas de partage/QR) ;
      // fourni avec un client mock inerte juste pour satisfaire le lookup.
      Provider<ShareService>.value(value: ShareService(_MockApiClient())),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PublicPortfolioScreen(
        key: const ValueKey('public-portfolio'),
        token: token,
        repository: repo,
      ),
    ),
  );
}
