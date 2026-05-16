import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kQueueKey = 'pending_operations';

/// Operation en attente de synchronisation.
/// Stockee localement quand l'utilisateur est hors ligne.
class PendingOperation {
  final String id;
  final String type; // 'create', 'update', 'delete'
  final String? cvJson;
  final int? cvId;
  final DateTime createdAt;

  const PendingOperation({
    required this.id,
    required this.type,
    this.cvJson,
    this.cvId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'cvJson': cvJson,
    'cvId': cvId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingOperation.fromJson(Map<String, dynamic> json) => PendingOperation(
    id: json['id'] as String,
    type: json['type'] as String,
    cvJson: json['cvJson'] as String?,
    cvId: json['cvId'] as int?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// File d'attente de synchronisation persistante.
/// Stocke les operations create/update/delete quand l'utilisateur est offline.
/// Rejouee automatiquement quand la connexion revient.
class SyncQueue {
  final SharedPreferences _prefs;

  SyncQueue(this._prefs);

  /// Ajoute une operation a la file.
  Future<void> add(PendingOperation op) async {
    final ops = getAll();
    ops.add(op);
    await _save(ops);
  }

  /// Retire une operation de la file (apres sync reussie).
  Future<void> remove(String operationId) async {
    final ops = getAll();
    ops.removeWhere((op) => op.id == operationId);
    await _save(ops);
  }

  /// Retourne toutes les operations en attente.
  List<PendingOperation> getAll() {
    final raw = _prefs.getString(_kQueueKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => PendingOperation.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// True s'il y a des operations en attente.
  bool get hasPending => getAll().isNotEmpty;

  /// Nombre d'operations en attente.
  int get pendingCount => getAll().length;

  /// Vide la file (apres une sync complete).
  Future<void> clear() async {
    await _prefs.remove(_kQueueKey);
  }

  Future<void> _save(List<PendingOperation> ops) async {
    await _prefs.setString(_kQueueKey, jsonEncode(ops.map((o) => o.toJson()).toList()));
  }
}
