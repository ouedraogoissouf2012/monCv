import '../../../core/error/result.dart';
import '../domain/job_application.dart';
import '../domain/job_application_status.dart';

/// Etat IMMUABLE de la liste des candidatures (issue #246, A4).
///
/// Aucun champ mutable public (le [JobApplicationProvider] legacy exposait
/// `items`, `filter`, `loading`, `error` en clair). Toute evolution passe par
/// [copyWith] ; les vues lisent des getters.
class ApplicationListState {
  final List<JobApplication> items;
  final JobApplicationStatus? filter;
  final bool loading;
  final AppException? error;

  const ApplicationListState({
    this.items = const [],
    this.filter,
    this.loading = false,
    this.error,
  });

  /// Candidatures dont la relance est due, evaluees a l'instant [now]
  /// (horloge injectee — cf. [JobApplication.isFollowUpDue]).
  List<JobApplication> dueItems(DateTime now) =>
      items.where((item) => item.isFollowUpDue(now)).toList();

  ApplicationListState copyWith({
    List<JobApplication>? items,
    JobApplicationStatus? filter,
    bool clearFilter = false,
    bool? loading,
    AppException? error,
    bool clearError = false,
  }) =>
      ApplicationListState(
        items: items ?? this.items,
        filter: clearFilter ? null : (filter ?? this.filter),
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}
