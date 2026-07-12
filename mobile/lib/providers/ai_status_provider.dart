import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Etat du sous-systeme IA (correspond au JSON renvoye par GET /api/ai/status).
class AiStatus {
  final bool available;
  final String? primaryProvider;
  final String? primaryStatus;
  final bool fallbackAvailable;
  final String? fallbackProvider;
  final DateTime? lastChecked;

  const AiStatus({
    required this.available,
    this.primaryProvider,
    this.primaryStatus,
    this.fallbackAvailable = false,
    this.fallbackProvider,
    this.lastChecked,
  });

  /// Status inconnu (avant le premier fetch ou apres une erreur).
  /// On considere l'IA disponible par defaut pour ne pas griser les boutons
  /// abusivement au premier chargement ; c'est l'appel IA reel qui dira la verite.
  const AiStatus.unknown()
      : available = true,
        primaryProvider = null,
        primaryStatus = 'UNKNOWN',
        fallbackAvailable = false,
        fallbackProvider = null,
        lastChecked = null;

  factory AiStatus.fromJson(Map<String, dynamic> json) => AiStatus(
        available: json['available'] as bool? ?? false,
        primaryProvider: json['primaryProvider'] as String?,
        primaryStatus: json['primaryStatus'] as String?,
        fallbackAvailable: json['fallbackAvailable'] as bool? ?? false,
        fallbackProvider: json['fallbackProvider'] as String?,
        lastChecked: json['lastChecked'] != null
            ? DateTime.tryParse(json['lastChecked'] as String)
            : null,
      );

  /// Message court pour le tooltip quand l'IA est indisponible.
  String get disabledReason => switch (primaryStatus) {
        'KEY_INVALID' => 'Service IA mal configure',
        'CIRCUIT_OPEN' => 'Service IA temporairement indisponible',
        'RECOVERING' => 'Service IA en cours de recuperation',
        _ => 'Service IA indisponible',
      };
}

/// Etat global du sous-systeme IA, consomme par les widgets pour
/// adapter l'UI (boutons desactives + tooltip si indisponible).
class AiStatusProvider extends ChangeNotifier {
  AiStatus _status = const AiStatus.unknown();
  final ApiService _api;

  AiStatusProvider({ApiService? api}) : _api = api ?? ApiService();

  AiStatus get status => _status;
  bool get canUseAi => _status.available;

  /// Rafraichit le status depuis le backend.
  /// Utilise au demarrage + apres chaque echec d'appel IA.
  Future<void> refresh() async {
    try {
      final json = await _api.getAiStatus();
      _status = AiStatus.fromJson(json);
    } catch (_) {
      // En cas d'erreur reseau ou 401, on garde le dernier status connu.
      // On ne met PAS "unavailable" car l'IA peut etre up (c'est /status qui a echoue).
    }
    notifyListeners();
  }
}
