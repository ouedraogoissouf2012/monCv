import 'package:flutter/foundation.dart';

import '../../../features/cv/presentation/cv_presentation_model.dart';
import '../application/state/cv_operation_state.dart';

/// Source unique de verite de l'etat CV partagee par les controllers
/// (liste, detail, edition, style) — issue #240, decomposition de `CvProvider`.
///
/// Le store ne contient AUCUNE logique metier ni I/O : il ne detient que
/// l'etat (`cvs`, `currentCv`, [CvOperationState], connectivite) et les
/// mutations atomiques de cet etat. Les controllers orchestrent les use cases
/// puis appliquent le resultat via ce store, garantissant qu'il n'existe
/// qu'une seule copie de `_cvs` / `_currentCv` (pas de desynchronisation).
class CvStore extends ChangeNotifier {
  List<Cv> _cvs = const [];
  Cv? _currentCv;
  CvOperationState _state = const CvOperationState.idle();
  bool _isOffline = false;

  List<Cv> get cvs => List.unmodifiable(_cvs);
  Cv? get currentCv => _currentCv;
  CvOperationState get state => _state;
  bool get isOffline => _isOffline;

  void setState(CvOperationState next) {
    _state = next;
    notifyListeners();
  }

  void setOffline(bool offline) {
    if (_isOffline == offline) return;
    _isOffline = offline;
    notifyListeners();
  }

  /// Remplace la liste complete et passe l'etat en succes.
  void setCvs(List<Cv> cvs) {
    _cvs = List.of(cvs);
    if (_currentCv?.id != null) {
      for (final cv in _cvs) {
        if (cv.id == _currentCv!.id) {
          _currentCv = cv;
          break;
        }
      }
    }
    _state = const CvOperationState.success();
    notifyListeners();
  }

  void setCurrentCv(Cv? cv) {
    _currentCv = cv;
    notifyListeners();
  }

  /// Ajoute un CV a la liste (et le rend courant si demande).
  void addCv(Cv cv, {bool makeCurrent = false}) {
    _cvs = [..._cvs, cv];
    if (makeCurrent) _currentCv = cv;
    notifyListeners();
  }

  /// Remplace un CV par son id partout ou il apparait (liste + courant).
  void replaceCv(int id, Cv cv) {
    _cvs = [
      for (final c in _cvs)
        if (c.id == id) cv else c,
    ];
    if (_currentCv?.id == id) _currentCv = cv;
    notifyListeners();
  }

  /// Retire un CV par son id (liste + courant si c'etait lui).
  void removeCv(int id) {
    _cvs = [
      for (final c in _cvs)
        if (c.id != id) c,
    ];
    if (_currentCv?.id == id) _currentCv = null;
    notifyListeners();
  }
}
