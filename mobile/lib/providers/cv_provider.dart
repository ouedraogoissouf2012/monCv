import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/error/result.dart';
import '../core/usecase/usecase.dart';
import '../models/cv.dart';
import '../models/cv_style.dart';
import '../repositories/cv_repository.dart';
import '../services/connectivity_service.dart';
import '../usecases/cv/get_all_cvs_usecase.dart';
import '../usecases/cv/get_cv_by_id_usecase.dart';
import '../usecases/cv/create_cv_usecase.dart';
import '../usecases/cv/update_cv_usecase.dart';
import '../usecases/cv/delete_cv_usecase.dart';
import '../usecases/cv/duplicate_cv_usecase.dart';
import '../usecases/cv/create_variant_usecase.dart';

class CvProvider with ChangeNotifier {
  final GetAllCvsUseCase _getAllCvs;
  final GetCvByIdUseCase _getCvById;
  final CreateCvUseCase _createCv;
  final UpdateCvUseCase _updateCv;
  final DeleteCvUseCase _deleteCv;
  final DuplicateCvUseCase _duplicateCv;
  final CreateVariantUseCase _createVariant;
  final CvRepository _repository;
  final ConnectivityService _connectivity;

  late final StreamSubscription<bool> _connectivitySub;

  CvProvider({
    required GetAllCvsUseCase getAllCvs,
    required GetCvByIdUseCase getCvById,
    required CreateCvUseCase createCv,
    required UpdateCvUseCase updateCv,
    required DeleteCvUseCase deleteCv,
    required DuplicateCvUseCase duplicateCv,
    required CreateVariantUseCase createVariantUseCase,
    required CvRepository repository,
    required ConnectivityService connectivity,
  })  : _getAllCvs = getAllCvs,
        _getCvById = getCvById,
        _createCv = createCv,
        _updateCv = updateCv,
        _deleteCv = deleteCv,
        _duplicateCv = duplicateCv,
        _createVariant = createVariantUseCase,
        _repository = repository,
        _connectivity = connectivity {
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

    final result = await _getAllCvs(const NoParams());
    _isLoading = false;

    switch (result) {
      case Success(:final data):
        _cvs = data;
      case Failure(:final exception):
        _error = exception.message;
    }
    notifyListeners();
  }

  Future<void> loadCvById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getCvById(id);
    _isLoading = false;

    switch (result) {
      case Success(:final data):
        _currentCv = data;
      case Failure(:final exception):
        _error = exception.message;
    }
    notifyListeners();
  }

  Future<bool> createCv(Cv cv) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _createCv(cv);
    _isLoading = false;

    switch (result) {
      case Success(:final data):
        _cvs.add(data);
        _currentCv = data;
        notifyListeners();
        return true;
      case Failure(:final exception):
        _error = exception.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> updateCv(int id, Cv cv) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _updateCv(UpdateCvParams(id: id, cv: cv));
    _isLoading = false;

    switch (result) {
      case Success(:final data):
        final index = _cvs.indexWhere((c) => c.id == id);
        if (index != -1) _cvs[index] = data;
        _currentCv = data;
        notifyListeners();
        return true;
      case Failure(:final exception):
        _error = exception.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> deleteCv(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _deleteCv(id);
    _isLoading = false;

    switch (result) {
      case Success():
        _cvs.removeWhere((cv) => cv.id == id);
        if (_currentCv?.id == id) _currentCv = null;
        notifyListeners();
        return true;
      case Failure(:final exception):
        _error = exception.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> duplicateCv(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _duplicateCv(id);
    _isLoading = false;

    switch (result) {
      case Success(:final data):
        _cvs.add(data);
        notifyListeners();
        return true;
      case Failure(:final exception):
        _error = exception.message;
        notifyListeners();
        return false;
    }
  }

  Future<Cv?> createVariant(int cvId, String jobDescription, {String? label}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _createVariant(CreateVariantParams(
      cvId: cvId, jobDescription: jobDescription, label: label));
    _isLoading = false;

    switch (result) {
      case Success(:final data):
        _cvs.add(data);
        notifyListeners();
        return data;
      case Failure(:final exception):
        _error = exception.message;
        notifyListeners();
        return null;
    }
  }

  Future<bool> applyAiEnhancements(int cvId, Map<String, dynamic> result) async {
    final cv = _currentCv;
    if (cv == null || cv.id != cvId) return false;

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

    List<Experience> updatedExperiences = List<Experience>.from(cv.experiences);
    if (result['experiences'] != null) {
      final aiExps = result['experiences'] as List<dynamic>;
      for (int i = 0; i < aiExps.length && i < updatedExperiences.length; i++) {
        final newDesc = aiExps[i]['description'] as String?;
        if (newDesc != null && newDesc.isNotEmpty) {
          final old = updatedExperiences[i];
          updatedExperiences[i] = Experience(
            id: old.id, poste: old.poste, entreprise: old.entreprise,
            lieu: old.lieu, dateDebut: old.dateDebut, dateFin: old.dateFin,
            actuel: old.actuel, description: newDesc,
          );
        }
      }
    }

    List<Education> updatedEducations = List<Education>.from(cv.educations);
    if (result['educations'] != null) {
      final aiEdus = result['educations'] as List<dynamic>;
      for (int i = 0; i < aiEdus.length && i < updatedEducations.length; i++) {
        final newDesc = aiEdus[i]['description'] as String?;
        if (newDesc != null && newDesc.isNotEmpty) {
          final old = updatedEducations[i];
          updatedEducations[i] = Education(
            id: old.id, etablissement: old.etablissement, diplome: old.diplome,
            domaine: old.domaine, dateDebut: old.dateDebut, dateFin: old.dateFin,
            description: newDesc,
          );
        }
      }
    }

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

    List<Project> updatedProjects = List<Project>.from(cv.projects);
    if (result['projects'] != null) {
      final aiProjs = result['projects'] as List<dynamic>;
      for (int i = 0; i < aiProjs.length && i < updatedProjects.length; i++) {
        final newDesc = aiProjs[i]['description'] as String?;
        if (newDesc != null && newDesc.isNotEmpty) {
          final old = updatedProjects[i];
          updatedProjects[i] = Project(
            id: old.id, nom: old.nom, description: newDesc,
            technologies: old.technologies, lien: old.lien,
            dateDebut: old.dateDebut, dateFin: old.dateFin,
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

    _currentCv = updatedCv;
    final index = _cvs.indexWhere((c) => c.id == cvId);
    if (index != -1) _cvs[index] = updatedCv;
    notifyListeners();

    // Best-effort save
    await _repository.updateCv(cvId, updatedCv);

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
