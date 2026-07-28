import 'package:flutter/foundation.dart';
import '../core/error/result.dart';
import '../core/usecase/usecase.dart';
import '../features/ai/application/get_ai_status_usecase.dart';
import '../models/ai_status.dart';

export '../models/ai_status.dart';

/// Etat global du sous-systeme IA, consomme par les widgets pour
/// adapter l'UI (boutons desactives + tooltip si indisponible).
class AiStatusProvider extends ChangeNotifier {
  AiStatus _status;
  final GetAiStatusUseCase _getAiStatus;
  String? _lastFailureReason;
  DateTime? _retryAfter;

  AiStatusProvider({
    required GetAiStatusUseCase getAiStatus,
    AiStatus? initialStatus,
  })  : _getAiStatus = getAiStatus,
        _status = initialStatus ?? const AiStatus.unknown();

  AiStatus get status => _status;
  bool get available =>
      _status.available && !_quotaDelayActive && _lastFailureReason == null;
  bool get canUseAi => available;
  DateTime? get retryAfter => _retryAfter;
  String? get unavailableReason {
    if (_quotaDelayActive) {
      final remaining = _retryAfter!.difference(DateTime.now());
      final minutes = (remaining.inSeconds / 60).ceil();
      return "Limite d'usage atteinte. Reessayez dans $minutes min.";
    }
    return _lastFailureReason ??
        (_status.available ? null : _status.disabledReason);
  }

  bool get _quotaDelayActive =>
      _retryAfter != null && _retryAfter!.isAfter(DateTime.now());

  void recordError(AiException error) {
    _lastFailureReason = error.message;
    _retryAfter =
        error.retryAfter == null ? null : DateTime.now().add(error.retryAfter!);
    notifyListeners();
  }

  void clearExpiredRetry() {
    if (_retryAfter != null && !_quotaDelayActive) {
      _retryAfter = null;
      _lastFailureReason = null;
      notifyListeners();
    }
  }

  /// Rafraichit le status depuis le backend.
  /// Utilise au demarrage + apres chaque echec d'appel IA.
  Future<void> refresh() async {
    final result = await _getAiStatus(const NoParams());
    switch (result) {
      case Success(:final data):
        _status = data;
        if (!_quotaDelayActive) {
          _lastFailureReason = null;
          _retryAfter = null;
        }
      case Failure():
        // Erreur reseau ou 401 : on garde le dernier status connu. On ne met
        // PAS "unavailable" car l'IA peut etre up (c'est /status qui a echoue).
        break;
    }
    notifyListeners();
  }
}
