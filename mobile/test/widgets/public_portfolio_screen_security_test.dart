import 'dart:async';

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

void main() {
  testWidgets(
    'une ancienne requete lente ne remplace pas le nouveau portfolio',
    (tester) async {
      const firstToken = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const secondToken = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
      final first = Completer<Cv>();
      final second = Completer<Cv>();
      final api = _MockApiClient();
      when(() => api.getPublicCv(firstToken)).thenAnswer((_) => first.future);
      when(() => api.getPublicCv(secondToken)).thenAnswer((_) => second.future);

      await tester.pumpWidget(_app(api, firstToken));
      await tester.pumpWidget(_app(api, secondToken));

      second.complete(Cv(titre: 'Portfolio recent'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Portfolio recent'), findsOneWidget);

      first.complete(Cv(titre: 'Portfolio obsolete'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Portfolio recent'), findsOneWidget);
      expect(find.text('Portfolio obsolete'), findsNothing);
    },
  );
}

Widget _app(IApiClient api, String token) {
  return MultiProvider(
    providers: [
      Provider<IApiClient>.value(value: api),
      Provider<ShareService>.value(value: ShareService(api)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PublicPortfolioScreen(
        key: const ValueKey('public-portfolio'),
        token: token,
      ),
    ),
  );
}
