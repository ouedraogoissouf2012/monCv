import 'dart:convert';

import '../../../core/error/result.dart';
import '../../../core/error/safe_call.dart';
import '../domain/account_repository.dart';

/// Exporte les donnees personnelles de l'utilisateur au format JSON lisible
/// (issue #250, E2, RGPD).
///
/// Delegue la recuperation au [AccountRepository] puis serialise en JSON indente
/// pret a copier. Toute erreur transport est convertie en [Result.failure] typee
/// par [safeCall] — le monolithe faisait le `try/catch` et le `JsonEncoder`
/// directement dans le widget.
class ExportAccountDataUseCase {
  const ExportAccountDataUseCase(this._repository);

  final AccountRepository _repository;

  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  Future<Result<String>> call() => safeCall(() async {
        final data = await _repository.exportData();
        return _encoder.convert(data);
      });
}
