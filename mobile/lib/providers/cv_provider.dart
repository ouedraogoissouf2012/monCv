import 'package:flutter/foundation.dart';
import '../models/cv.dart';
import '../services/api_service.dart';

class CvProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Cv> _cvs = [];
  Cv? _currentCv;
  bool _isLoading = false;
  String? _error;

  List<Cv> get cvs => _cvs;
  Cv? get currentCv => _currentCv;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCvs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cvs = await _apiService.getAllCvs();
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
      _currentCv = await _apiService.getCvById(id);
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
      final newCv = await _apiService.createCv(cv);
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
      final updatedCv = await _apiService.updateCv(id, cv);
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
      await _apiService.deleteCv(id);
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

  void setCurrentCv(Cv? cv) {
    _currentCv = cv;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
