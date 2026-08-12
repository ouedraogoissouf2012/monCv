// Teste la facade AiCvService @Deprecated (transitoire, migree par #245).
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:cv_mobile/features/ai/compat/ai_service_facade.dart';
import 'package:cv_mobile/features/ai/data/ai_remote_data_source.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/models/user.dart';
import 'package:cv_mobile/repositories/auth_repository.dart';
import 'package:cv_mobile/services/api_service.dart';
import 'package:cv_mobile/services/i_api_client.dart';
import 'package:cv_mobile/services/share_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements IApiClient {}

class MockAiRemoteDataSource extends Mock implements AiRemoteDataSource {}

void main() {
  late MockApiClient api;

  setUp(() => api = MockApiClient());

  test('La facade AiCvService delegue au data source typé', () async {
    final dataSource = MockAiRemoteDataSource();
    when(() => dataSource.generateResume('Développeur', 'Dart', '3 ans'))
        .thenAnswer((_) async => 'Résumé généré');

    final result = await AiCvService(dataSource).generateResume(
      titrePoste: 'Développeur',
      competences: 'Dart',
      experience: '3 ans',
    );

    expect(result, 'Résumé généré');
    verify(() => dataSource.generateResume('Développeur', 'Dart', '3 ans'))
        .called(1);
  });

  test('ShareService utilise le client injecté pour créer le lien', () async {
    when(() => api.generateShareLink(42)).thenAnswer(
      (_) async => Cv(id: 42, titre: 'CV test', shareToken: 'public-token'),
    );

    final url = await ShareService(api).generateShareLink(42);

    expect(url, contains('/#/public/cv/public-token'));
    verify(() => api.generateShareLink(42)).called(1);
  });

  test('HttpAuthRepository utilise le client injecté', () async {
    final response = AuthResponse(
      accessToken: 'access',
      refreshToken: 'refresh',
      tokenType: 'Bearer',
      expiresIn: 3600,
      user: User(id: 1, email: 'test@example.com', role: 'USER'),
    );
    when(() => api.login(email: 'test@example.com', password: 'secret'))
        .thenAnswer((_) async => response);

    final result = await HttpAuthRepository(api: api).login(
      email: 'test@example.com',
      password: 'secret',
    );

    expect(result.isSuccess, isTrue);
    verify(() => api.login(email: 'test@example.com', password: 'secret'))
        .called(1);
  });

  test('ApiService ne possède plus de singleton manuel', () {
    expect(identical(ApiService(), ApiService()), isFalse);
  });
}
