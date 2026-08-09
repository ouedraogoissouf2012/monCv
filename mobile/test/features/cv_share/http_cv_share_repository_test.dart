import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/data/cv_network_codec.dart';
import 'package:cv_mobile/features/cv_share/data/http_cv_share_repository.dart';
import 'package:cv_mobile/services/i_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements IApiClient {}

void main() {
  late _MockApiClient api;
  late HttpCvShareRepository repo;

  setUp(() {
    api = _MockApiClient();
    repo = HttpCvShareRepository(api);
  });

  test('generateLink délègue et enveloppe le CV dans Result.success', () async {
    when(() => api.generateShareLink(7))
        .thenAnswer((_) async => cvFromNetworkJson({'titre': 'Partage'}));

    final result = await repo.generateLink(7);

    expect(result.getOrThrow().titre, 'Partage');
    verify(() => api.generateShareLink(7)).called(1);
  });

  test('regenerateLink délègue à regenerateShareLink', () async {
    when(() => api.regenerateShareLink(7))
        .thenAnswer((_) async => cvFromNetworkJson({'titre': 'Nouveau'}));

    final result = await repo.regenerateLink(7);

    expect(result.getOrThrow().titre, 'Nouveau');
  });

  test('deactivateLink délègue à deactivateShareLink', () async {
    when(() => api.deactivateShareLink(7))
        .thenAnswer((_) async => cvFromNetworkJson({'titre': 'Off'}));

    final result = await repo.deactivateLink(7);

    expect(result.isSuccess, isTrue);
    verify(() => api.deactivateShareLink(7)).called(1);
  });

  test('updateSettings propage contact/downloads au client', () async {
    when(() => api.updateShareSettings(7,
            contactEnabled: false, downloadsEnabled: false))
        .thenAnswer((_) async => cvFromNetworkJson({'titre': 'Reglages'}));

    final result = await repo.updateSettings(
      7,
      contactEnabled: false,
      downloadsEnabled: false,
    );

    expect(result.getOrThrow().titre, 'Reglages');
    verify(() => api.updateShareSettings(7,
        contactEnabled: false, downloadsEnabled: false)).called(1);
  });

  test('un échec réseau devient un Result.failure typé', () async {
    when(() => api.generateShareLink(7))
        .thenAnswer((_) async => throw const NetworkException());

    final result = await repo.generateLink(7);

    expect((result as Failure).exception, isA<NetworkException>());
  });
}
