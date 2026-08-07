import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/public_portfolio/data/http_public_portfolio_repository.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/services/i_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements IApiClient {}

void main() {
  late _MockApiClient api;
  late HttpPublicPortfolioRepository repo;

  setUp(() {
    api = _MockApiClient();
    repo = HttpPublicPortfolioRepository(api);
  });

  test('getPortfolio succès enveloppe le CV dans Result.success', () async {
    when(() => api.getPublicCv('tok')).thenAnswer((_) async => Cv(titre: 'Public'));

    final result = await repo.getPortfolio('tok');

    expect(result.getOrThrow().titre, 'Public');
  });

  test('getPortfolio échec réseau devient un Result.failure typé', () async {
    // Le client renvoie un Future en erreur (comportement async reel), que
    // toResult() convertit en Result.failure.
    when(() => api.getPublicCv('tok'))
        .thenAnswer((_) async => throw const NetworkException());

    final result = await repo.getPortfolio('tok');

    expect((result as Failure).exception, isA<NetworkException>());
  });

  test('download succès enveloppe les octets', () async {
    when(() => api.downloadPublicCv('tok', 'pdf'))
        .thenAnswer((_) async => [1, 2, 3]);

    final result = await repo.download('tok', 'pdf');

    expect(result.getOrThrow(), [1, 2, 3]);
  });

  test('trackShare est best-effort : une erreur reseau est absorbee', () async {
    when(() => api.trackPublicShare('tok')).thenThrow(const NetworkException());

    // Ne doit jamais lever malgre l'echec du transport.
    await repo.trackShare('tok');

    verify(() => api.trackPublicShare('tok')).called(1);
  });
}
