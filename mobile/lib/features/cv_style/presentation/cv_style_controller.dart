import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../../models/cv_style.dart';

/// Sauvegarde un style et renvoie un [Result] (succes/echec typé).
typedef SaveCvStyle = Future<Result<void>> Function(CvStyle style);

/// Etat de la sauvegarde du style (issue #247, B2).
enum StyleSaveStatus { idle, saving, saved, error }

/// Controleur d'edition du style d'un CV avec autosave robuste (issue #247, B2).
///
/// - **Debounce** : les changements rapides (tap template/couleur/police)
///   ne declenchent qu'une seule sauvegarde apres [debounce].
/// - **Last-write-wins** : seule la derniere selection est envoyee ; les
///   reponses perimees sont ignorees (compteur de generation).
/// - **Retry** : jusqu'a [maxRetries] tentatives sur echec.
/// - **Rollback** : si l'echec est definitif, l'etat affiche revient au dernier
///   style REELLEMENT sauvegarde, mais la selection en cours n'est PAS perdue
///   (elle reste dans [style], reproposable via retry manuel).
///
/// Le [Timer] est injecte via [scheduleDebounce] pour etre testable sans
/// attendre le temps reel.
class CvStyleController extends ChangeNotifier {
  CvStyleController({
    required CvStyle initial,
    required SaveCvStyle save,
    Duration debounce = const Duration(milliseconds: 400),
    int maxRetries = 2,
    Timer Function(Duration, void Function())? scheduleDebounce,
  })  : _style = initial,
        _savedStyle = initial,
        _save = save,
        _debounce = debounce,
        _maxRetries = maxRetries,
        _schedule = scheduleDebounce ?? Timer.new;

  final SaveCvStyle _save;
  final Duration _debounce;
  final int _maxRetries;
  final Timer Function(Duration, void Function()) _schedule;

  CvStyle _style;
  CvStyle _savedStyle;
  StyleSaveStatus _status = StyleSaveStatus.idle;
  Timer? _timer;
  int _generation = 0;

  /// Style actuellement selectionne (optimiste, peut ne pas etre encore sauve).
  CvStyle get style => _style;

  /// Dernier style REELLEMENT persiste (cible d'un eventuel rollback visuel).
  CvStyle get savedStyle => _savedStyle;

  StyleSaveStatus get status => _status;
  bool get saving => _status == StyleSaveStatus.saving;
  bool get hasError => _status == StyleSaveStatus.error;

  /// Applique une nouvelle selection (maj optimiste) et programme une
  /// sauvegarde debounced. Sans effet si le style est inchange.
  void select(CvStyle next) {
    if (next == _style) return;
    _style = next;
    notifyListeners();
    _timer?.cancel();
    _timer = _schedule(_debounce, _flush);
  }

  /// Force une sauvegarde immediate (ex. retry manuel apres erreur).
  Future<void> saveNow() async {
    _timer?.cancel();
    await _flush();
  }

  Future<void> _flush() async {
    final target = _style;
    if (target == _savedStyle) {
      _setStatus(StyleSaveStatus.idle);
      return;
    }
    final generation = ++_generation;
    _setStatus(StyleSaveStatus.saving);

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      final result = await _save(target);
      // Une selection plus recente a ete faite : abandonner ce cycle.
      if (generation != _generation) return;
      if (result is Success<void>) {
        _savedStyle = target;
        _setStatus(StyleSaveStatus.saved);
        return;
      }
    }
    // Echec definitif : rollback visuel vers le dernier style sauvegarde.
    // La selection [_style] reste intacte (retry manuel possible).
    if (generation == _generation) _setStatus(StyleSaveStatus.error);
  }

  void _setStatus(StyleSaveStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
