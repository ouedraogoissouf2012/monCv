import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../application/delete_application.dart';
import '../application/list_applications.dart';
import '../application/save_application.dart';
import '../domain/job_application.dart';
import '../domain/job_application_status.dart';
import 'application_list_state.dart';

/// Orchestration de la liste des candidatures (issue #246, A4).
///
/// Remplace [JobApplicationProvider] : plus de dependance transport (les use
/// cases sont injectes), etat IMMUABLE ([ApplicationListState]), erreurs TYPEES
/// (fin de `e.toString().replaceFirst`), horloge injectee pour les relances.
class ApplicationListController extends ChangeNotifier {
  ApplicationListController({
    required ListApplicationsUseCase listApplications,
    required SaveApplicationUseCase saveApplication,
    required DeleteApplicationUseCase deleteApplication,
    DateTime Function()? clock,
  })  : _list = listApplications,
        _save = saveApplication,
        _delete = deleteApplication,
        _clock = clock ?? DateTime.now;

  final ListApplicationsUseCase _list;
  final SaveApplicationUseCase _save;
  final DeleteApplicationUseCase _delete;
  final DateTime Function() _clock;

  ApplicationListState _state = const ApplicationListState();
  ApplicationListState get state => _state;

  /// Candidatures a relancer, evaluees a l'heure courante (horloge injectee).
  List<JobApplication> get dueItems => _state.dueItems(_clock());

  void _emit(ApplicationListState next) {
    _state = next;
    notifyListeners();
  }

  /// Charge la liste (optionnellement filtree). Rejouable : l'erreur precedente
  /// est effacee. Le filtre est conserve dans l'etat meme en cas d'echec.
  Future<void> load({JobApplicationStatus? status}) async {
    _emit(_state.copyWith(
      loading: true,
      clearError: true,
      filter: status,
      clearFilter: status == null,
    ));

    final outcome = await _list(ListApplicationsParams(status: status));
    switch (outcome) {
      case Success(:final data):
        _emit(_state.copyWith(items: data, loading: false));
      case Failure(:final exception):
        _emit(_state.copyWith(loading: false, error: exception));
    }
  }

  /// Enregistre une candidature (create ou update) puis recharge la liste avec
  /// le filtre courant. Retourne `true` si l'operation a reussi.
  Future<bool> save(JobApplication application) async {
    final outcome = await _save(application);
    switch (outcome) {
      case Success():
        await load(status: _state.filter);
        return true;
      case Failure(:final exception):
        _emit(_state.copyWith(error: exception));
        return false;
    }
  }

  /// Supprime une candidature. En cas de succes, la retire de l'etat sans
  /// rechargement reseau. Retourne `true` si l'operation a reussi.
  Future<bool> delete(int id) async {
    final outcome = await _delete(id);
    switch (outcome) {
      case Success():
        _emit(_state.copyWith(
          items: _state.items.where((item) => item.id != id).toList(),
        ));
        return true;
      case Failure(:final exception):
        _emit(_state.copyWith(error: exception));
        return false;
    }
  }
}
