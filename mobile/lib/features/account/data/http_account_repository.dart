import '../../../services/i_api_client.dart';
import '../domain/account_repository.dart';

/// Implementation HTTP du [AccountRepository] (issue #250, E2).
///
/// Adaptateur mince sur [IApiClient] : traduit le port du domaine vers les
/// appels transport. Les erreurs remontent telles quelles et sont enveloppees
/// en [Result] par les use cases (`safeCall`).
class HttpAccountRepository implements AccountRepository {
  const HttpAccountRepository(this._api);

  final IApiClient _api;

  @override
  Future<Map<String, dynamic>> exportData() => _api.exportUserData();

  @override
  Future<void> deleteAccount() => _api.deleteAccount();
}
