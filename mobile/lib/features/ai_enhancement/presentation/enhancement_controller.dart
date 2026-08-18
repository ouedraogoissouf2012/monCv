import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../features/cv/presentation/cv_presentation_model.dart';
import '../../ai/application/enhance_cv_usecase.dart';
import '../../ai/domain/entities/enhanced_cv.dart';
import '../application/build_enhancement_diff.dart';
import '../domain/enhancement_change.dart';
import '../domain/enhancement_level.dart';

/// Etat et orchestration du flow d'amelioration IA d'un CV (issue #244).
///
/// Porte consentement, niveau, chargement, erreur TYPEE, resultat et diff —
/// tout ce que le State monolithique de `ai_enhance_sheet.dart` gerait avec
/// des `Map<String, dynamic>` et un appel transport direct. Ici :
/// - l'appel passe par [EnhanceCvUseCase] (port AiRepository, jamais le
///   transport) et retourne l'entite typee [EnhancedCv] ;
/// - le diff avant/apres est construit par [BuildEnhancementDiff] (pur) ;
/// - une erreur IA typee est aussi propagee via [onAiError] (injecte par la
///   vue pour rafraichir le statut IA global, sans que le controller ne
///   connaisse de Provider).
class EnhancementController extends ChangeNotifier {
  EnhancementController({
    required Cv cv,
    required EnhanceCvUseCase enhanceCv,
    BuildEnhancementDiff buildDiff = const BuildEnhancementDiff(),
    this.proofreadOnly = false,
    EnhancementLevel initialLevel = EnhancementLevel.medium,
    this.onAiError,
  })  : _cv = cv,
        _enhanceCv = enhanceCv,
        _buildDiff = proofreadOnly
            ? const BuildEnhancementDiff(proofread: true)
            : buildDiff,
        _level = proofreadOnly ? EnhancementLevel.lite : initialLevel;

  final Cv _cv;
  final EnhanceCvUseCase _enhanceCv;
  final BuildEnhancementDiff _buildDiff;

  /// Mode relecture : niveau verrouille sur LITE.
  final bool proofreadOnly;

  /// Notifie la vue d'une erreur IA typee (ex. pour AiStatusProvider).
  final void Function(AiException error)? onAiError;

  EnhancementLevel _level;
  bool _disposed = false;
  bool _consentAccepted = false;
  bool _loading = false;
  AppException? _error;
  EnhancedCv? _result;
  List<EnhancementChange> _changes = const [];

  EnhancementLevel get level => _level;
  bool get consentAccepted => _consentAccepted;
  bool get loading => _loading;

  /// Erreur typee du dernier appel (null si aucun / succes).
  AppException? get error => _error;

  /// Resultat typee du dernier appel reussi.
  EnhancedCv? get result => _result;

  /// Diff avant/apres du dernier resultat (vide tant qu'aucun succes).
  List<EnhancementChange> get changes => _changes;

  /// L'amelioration est lancable : consentement donne, pas d'appel en cours,
  /// et le CV est persiste (id non null, exige par le contrat backend).
  bool get canEnhance => _consentAccepted && !_loading && _cv.id != null;

  /// Change le niveau. Sans effet en mode relecture (verrouille LITE) ou
  /// pendant un chargement.
  void selectLevel(EnhancementLevel level) {
    if (proofreadOnly || _loading || level == _level) return;
    _level = level;
    notifyListeners();
  }

  void setConsent(bool accepted) {
    if (accepted == _consentAccepted) return;
    _consentAccepted = accepted;
    notifyListeners();
  }

  /// Lance l'amelioration via le use case. Sans effet si [canEnhance] est
  /// faux. Rejouable apres echec (retry) : l'erreur precedente est effacee.
  Future<void> enhance() async {
    if (!canEnhance) return;
    _loading = true;
    _error = null;
    _result = null;
    _changes = const [];
    notifyListeners();

    final outcome = await _enhanceCv(EnhanceCvParams(
        cvId: _cv.id!,
        level: _level.backendId,
        consentAccepted: _consentAccepted));

    if (_disposed) return;

    switch (outcome) {
      case Success(:final data):
        _result = data;
        _changes = _buildDiff(_cv, data);
      case Failure(:final exception):
        _error = exception;
        if (exception is AiException) onAiError?.call(exception);
    }
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
