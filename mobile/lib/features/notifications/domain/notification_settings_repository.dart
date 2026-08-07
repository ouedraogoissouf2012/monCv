import '../../../core/error/result.dart';
import '../../../models/notification_preferences.dart';

/// Port des preferences de notification (issue #258, ex-#237).
///
/// Abstrait les preferences pour que la presentation
/// ([NotificationProvider]) n'accede jamais au transport reseau directement.
/// L'implementation vit dans `data/`.
abstract interface class NotificationSettingsRepository {
  /// Charge les preferences de notification de l'utilisateur.
  Future<Result<NotificationPreferences>> getPreferences();

  /// Persiste les preferences [next] et retourne la valeur confirmee serveur.
  Future<Result<NotificationPreferences>> updatePreferences(
    NotificationPreferences next,
  );
}
