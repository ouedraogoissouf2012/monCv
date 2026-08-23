import 'package:get_it/get_it.dart';

import 'modules/ai_module.dart';
import 'modules/applications_module.dart';
import 'modules/auth_module.dart';
import 'modules/core_module.dart';
import 'modules/cv_module.dart';
import 'modules/notifications_module.dart';

/// Instance globale du service locator.
final sl = GetIt.instance;

/// Initialise toutes les dependances.
/// Doit etre appele dans main() avant runApp().
///
/// Les enregistrements sont repartis par domaine sous `modules/` (issue #524) :
/// ajouter une fonctionnalite touche un seul module, et aucun fichier ne croit
/// indefiniment. Ce conteneur ne fait plus qu'orchestrer.
///
/// L'ordre d'appel n'a pas d'importance entre modules : hormis
/// [SharedPreferences], enregistre de maniere anticipee par le module socle,
/// toutes les dependances sont paresseuses et ne se resolvent qu'a la demande.
/// Elles peuvent donc se referencer d'un module a l'autre.
Future<void> initDependencies() async {
  await registerCoreModule(sl);
  registerAuthModule(sl);
  registerAiModule(sl);
  registerCvModule(sl);
  registerNotificationsModule(sl);
  registerApplicationsModule(sl);
}
