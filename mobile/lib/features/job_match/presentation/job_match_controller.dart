import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../ai/application/match_job_usecase.dart';
import '../../ai/domain/entities/job_match.dart';
import '../domain/job_score_snapshot.dart';

/// Etat et orchestration du flow d'analyse CV / offre (issue #245).
///
/// Porte l'offre saisie, sa validation, le consentement, le chargement,
/// l'erreur TYPEE, le rapport typé [JobMatch] et l'historique de scores. L'appel
/// passe par [MatchJobUseCase] (port AiRepository) — plus d'`IApiClient`, plus
/// de `Map<String, dynamic>`. Aucune dependance a un Provider : les erreurs IA
/// typees remontent via [onAiError], injecte par la vue.
class JobMatchController extends ChangeNotifier {
  JobMatchController({
    required int cvId,
    required MatchJobUseCase matchJob,
    this.onAiError,
    DateTime Function()? clock,
    JobScoreHistory? history,
  })  : _cvId = cvId,
        _matchJob = matchJob,
        _clock = clock ?? DateTime.now,
        _history = history ?? JobScoreHistory();

  /// Longueur minimale d'une offre exploitable (reproduit le monolithe).
  static const int minJobDescriptionLength = 20;

  final int _cvId;
  final MatchJobUseCase _matchJob;
  final DateTime Function() _clock;
  final JobScoreHistory _history;

  /// Notifie la vue d'une erreur IA typee (ex. pour AiStatusProvider).
  final void Function(AiException error)? onAiError;

  String _jobDescription = '';
  bool _consentAccepted = false;
  bool _loading = false;
  AppException? _error;
  JobMatch? _report;

  String get jobDescription => _jobDescription;
  bool get consentAccepted => _consentAccepted;
  bool get loading => _loading;
  AppException? get error => _error;
  JobMatch? get report => _report;
  List<JobScoreSnapshot> get history => _history.entries;

  /// L'offre est exploitable : au moins [minJobDescriptionLength] caracteres
  /// significatifs.
  bool get isJobDescriptionValid =>
      _jobDescription.trim().length >= minJobDescriptionLength;

  /// L'analyse est lancable : offre valide, consentement, pas d'appel en cours.
  bool get canAnalyze =>
      isJobDescriptionValid && _consentAccepted && !_loading;

  void setJobDescription(String value) {
    if (value == _jobDescription) return;
    _jobDescription = value;
    notifyListeners();
  }

  void setConsent(bool accepted) {
    if (accepted == _consentAccepted) return;
    _consentAccepted = accepted;
    notifyListeners();
  }

  /// Lance l'analyse via le use case. Sans effet si [canAnalyze] est faux.
  /// Rejouable (retry) : l'erreur precedente est effacee, un nouveau score est
  /// ajoute a l'historique en cas de succes.
  Future<void> analyze() async {
    if (!canAnalyze) return;
    _loading = true;
    _error = null;
    _report = null;
    notifyListeners();

    final outcome = await _matchJob(MatchJobParams(
      cvId: _cvId,
      jobDescription: _jobDescription.trim(),
    ));

    switch (outcome) {
      case Success(:final data):
        _report = data;
        _history.record(data.score, _clock());
      case Failure(:final exception):
        _error = exception;
        if (exception is AiException) onAiError?.call(exception);
    }
    _loading = false;
    notifyListeners();
  }
}
