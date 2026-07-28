/// Etat type d'une operation CV, remplacant les booleans concurrents
/// (`isLoading` / `error` / `isOffline`) qui pouvaient se contredire.
///
/// Un seul [CvOperationState] decrit l'etat courant a un instant donne, ce qui
/// rend impossibles les combinaisons incoherentes (ex. `loading` ET `failure`
/// simultanes). Type scelle : le compilateur force le traitement exhaustif.
///
/// Issue #240 (decomposition de `CvProvider`, etats types).
sealed class CvOperationState {
  const CvOperationState();

  /// Aucune operation en cours, aucune erreur.
  const factory CvOperationState.idle() = CvIdle;

  /// Une operation est en cours.
  const factory CvOperationState.loading() = CvLoading;

  /// L'operation a reussi.
  const factory CvOperationState.success() = CvSuccess;

  /// L'operation a echoue avec un message sur pour l'utilisateur et un code
  /// stable pour le traitement programmatique.
  const factory CvOperationState.failure(String message, {String? code}) =
      CvFailure;

  /// L'appareil est hors ligne ; les lectures servent le cache.
  const factory CvOperationState.offline() = CvOffline;

  /// Des mutations locales attendent d'etre rejouees vers le backend.
  const factory CvOperationState.pendingSync(int count) = CvPendingSync;

  bool get isLoading => this is CvLoading;
  bool get isFailure => this is CvFailure;
  bool get isOffline => this is CvOffline;
  bool get isPendingSync => this is CvPendingSync;

  /// Message d'erreur si l'etat est [CvFailure], sinon `null`.
  String? get errorMessage => switch (this) {
        CvFailure(:final message) => message,
        _ => null,
      };
}

final class CvIdle extends CvOperationState {
  const CvIdle();
}

final class CvLoading extends CvOperationState {
  const CvLoading();
}

final class CvSuccess extends CvOperationState {
  const CvSuccess();
}

final class CvFailure extends CvOperationState {
  final String message;
  final String? code;
  const CvFailure(this.message, {this.code});
}

final class CvOffline extends CvOperationState {
  const CvOffline();
}

final class CvPendingSync extends CvOperationState {
  final int count;
  const CvPendingSync(this.count);
}
