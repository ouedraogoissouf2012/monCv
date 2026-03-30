import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cv.dart';
import '../models/cv_style.dart';
import '../repositories/cv_repository.dart';
import '../services/connectivity_service.dart';

class CvProvider with ChangeNotifier {
  final CvRepository _repository;
  final ConnectivityService _connectivity;

  late final StreamSubscription<bool> _connectivitySub;

  CvProvider({
    CvRepository? repository,
    ConnectivityService? connectivity,
  })  : _repository = repository ?? HttpCvRepository(),
        _connectivity = connectivity ?? ConnectivityService() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((online) {
      _isOffline = !online;
      notifyListeners();
      if (online && _cvs.isEmpty) loadCvs();
    });
  }

  List<Cv> _cvs = [];
  Cv? _currentCv;
  bool _isLoading = false;
  String? _error;
  bool _isOffline = false;

  List<Cv> get cvs => _cvs;
  Cv? get currentCv => _currentCv;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;

  Future<void> loadCvs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cvs = await _repository.getAllCvs();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCvById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentCv = await _repository.getCvById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCv(Cv cv) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newCv = await _repository.createCv(cv);
      _cvs.add(newCv);
      _currentCv = newCv;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCv(int id, Cv cv) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedCv = await _repository.updateCv(id, cv);
      final index = _cvs.indexWhere((c) => c.id == id);
      if (index != -1) {
        _cvs[index] = updatedCv;
      }
      _currentCv = updatedCv;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCv(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteCv(id);
      _cvs.removeWhere((cv) => cv.id == id);
      if (_currentCv?.id == id) {
        _currentCv = null;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> duplicateCv(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final copy = await _repository.duplicateCv(id);
      _cvs.add(copy);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Met à jour le style du CV localement (sans appel réseau — persisté côté client).
  /// Applique les suggestions IA directement sur le CV en memoire,
  /// puis tente de sauvegarder au backend.
  Future<bool> applyAiEnhancements(int cvId, Map<String, dynamic> result) async {
    final cv = _currentCv;
    if (cv == null || cv.id != cvId) return false;

    // 1. Titre du poste + Resume professionnel
    PersonalInfo? updatedInfo = cv.personalInfo;
    if (updatedInfo != null) {
      final newTitre = result['titrePoste'] as String?;
      final newResume = result['resumeProfessionnel'] as String?;
      if ((newTitre != null && newTitre.isNotEmpty) ||
          (newResume != null && newResume.isNotEmpty)) {
        updatedInfo = PersonalInfo(
          nom: updatedInfo.nom,
          prenom: updatedInfo.prenom,
          email: updatedInfo.email,
          telephone: updatedInfo.telephone,
          adresse: updatedInfo.adresse,
          ville: updatedInfo.ville,
          codePostal: updatedInfo.codePostal,
          pays: updatedInfo.pays,
          titrePoste: (newTitre != null && newTitre.isNotEmpty) ? newTitre : updatedInfo.titrePoste,
          linkedIn: updatedInfo.linkedIn,
          portfolio: updatedInfo.portfolio,
          photoUrl: updatedInfo.photoUrl,
          resumeProfessionnel: (newResume != null && newResume.isNotEmpty) ? newResume : updatedInfo.resumeProfessionnel,
        );
      }
    }

    // 2. Experiences
    List<Experience> updatedExperiences = List<Experience>.from(cv.experiences);
    if (result['experiences'] != null) {
      final aiExps = result['experiences'] as List<dynamic>;
      for (int i = 0; i < aiExps.length && i < updatedExperiences.length; i++) {
        final aiExp = aiExps[i];
        final newDesc = aiExp['description'] as String?;
        if (newDesc != null && newDesc.isNotEmpty) {
          final old = updatedExperiences[i];
          updatedExperiences[i] = Experience(
            id: old.id,
            poste: old.poste,
            entreprise: old.entreprise,
            lieu: old.lieu,
            dateDebut: old.dateDebut,
            dateFin: old.dateFin,
            actuel: old.actuel,
            description: newDesc,
          );
        }
      }
    }

    // 3. Educations
    List<Education> updatedEducations = List<Education>.from(cv.educations);
    if (result['educations'] != null) {
      final aiEdus = result['educations'] as List<dynamic>;
      for (int i = 0; i < aiEdus.length && i < updatedEducations.length; i++) {
        final aiEdu = aiEdus[i];
        final newDesc = aiEdu['description'] as String?;
        if (newDesc != null && newDesc.isNotEmpty) {
          final old = updatedEducations[i];
          updatedEducations[i] = Education(
            id: old.id,
            etablissement: old.etablissement,
            diplome: old.diplome,
            domaine: old.domaine,
            dateDebut: old.dateDebut,
            dateFin: old.dateFin,
            description: newDesc,
          );
        }
      }
    }

    // 4. Competences (l'IA peut separer les competences en bloc)
    List<Skill> updatedSkills = List<Skill>.from(cv.skills);
    if (result['skills'] != null) {
      final aiSkills = result['skills'] as List<dynamic>;
      if (aiSkills.isNotEmpty) {
        updatedSkills = aiSkills.map((s) => Skill(
          nom: s['nom'] as String? ?? '',
          niveau: s['niveau'] as int? ?? 3,
        )).toList();
      }
    }

    // 5. Projets
    List<Project> updatedProjects = List<Project>.from(cv.projects);
    if (result['projects'] != null) {
      final aiProjs = result['projects'] as List<dynamic>;
      for (int i = 0; i < aiProjs.length && i < updatedProjects.length; i++) {
        final aiProj = aiProjs[i];
        final newDesc = aiProj['description'] as String?;
        if (newDesc != null && newDesc.isNotEmpty) {
          final old = updatedProjects[i];
          updatedProjects[i] = Project(
            id: old.id,
            nom: old.nom,
            description: newDesc,
            technologies: old.technologies,
            lien: old.lien,
            dateDebut: old.dateDebut,
            dateFin: old.dateFin,
          );
        }
      }
    }

    final updatedCv = cv.copyWith(
      personalInfo: updatedInfo,
      experiences: updatedExperiences,
      educations: updatedEducations,
      skills: updatedSkills,
      projects: updatedProjects,
    );

    // Appliquer immediatement en local
    _currentCv = updatedCv;
    final index = _cvs.indexWhere((c) => c.id == cvId);
    if (index != -1) _cvs[index] = updatedCv;
    notifyListeners();

    // Sauvegarder au backend
    try {
      await _repository.updateCv(cvId, updatedCv);
    } catch (_) {}

    return true;
  }

  void updateCvStyle(int cvId, CvStyle style) {
    if (_currentCv?.id == cvId) {
      _currentCv = _currentCv!.copyWith(style: style);
    }
    final index = _cvs.indexWhere((c) => c.id == cvId);
    if (index != -1) {
      _cvs[index] = _cvs[index].copyWith(style: style);
    }
    notifyListeners();
  }

  void setCurrentCv(Cv? cv) {
    _currentCv = cv;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }
}
