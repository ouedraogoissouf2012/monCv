/// Etat du sous-systeme IA renvoye par GET /api/ai/status.
class AiStatus {
  final bool available;
  final String? primaryProvider;
  final String? primaryStatus;
  final String? circuitBreakerState;
  final String? lastErrorType;
  final bool fallbackAvailable;
  final String? fallbackProvider;
  final bool fallbackInUse;
  final DateTime? lastChecked;

  const AiStatus({
    required this.available,
    this.primaryProvider,
    this.primaryStatus,
    this.circuitBreakerState,
    this.lastErrorType,
    this.fallbackAvailable = false,
    this.fallbackProvider,
    this.fallbackInUse = false,
    this.lastChecked,
  });

  const AiStatus.unknown()
      : available = true,
        primaryProvider = null,
        primaryStatus = 'UNKNOWN',
        circuitBreakerState = null,
        lastErrorType = null,
        fallbackAvailable = false,
        fallbackProvider = null,
        fallbackInUse = false,
        lastChecked = null;

  factory AiStatus.fromJson(Map<String, dynamic> json) => AiStatus(
        available: json['available'] as bool? ?? false,
        primaryProvider: json['primaryProvider'] as String?,
        primaryStatus: json['primaryStatus'] as String?,
        circuitBreakerState: json['circuitBreakerState'] as String?,
        lastErrorType:
            (json['lastError'] as Map<String, dynamic>?)?['type'] as String?,
        fallbackAvailable: json['fallbackAvailable'] as bool? ?? false,
        fallbackProvider: json['fallbackProvider'] as String?,
        fallbackInUse: json['fallbackInUse'] as bool? ?? false,
        lastChecked: (json['checkedAt'] ?? json['lastChecked']) != null
            ? DateTime.tryParse(
                (json['checkedAt'] ?? json['lastChecked']) as String,
              )
            : null,
      );

  String get disabledReason => switch (primaryStatus) {
        'KEY_INVALID' => 'Service IA mal configure',
        'CIRCUIT_OPEN' => 'Service IA temporairement indisponible',
        'RECOVERING' => 'Service IA en cours de recuperation',
        _ => 'Service IA indisponible',
      };
}
