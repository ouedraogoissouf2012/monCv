import '../models/cv.dart';
import '../services/api_service.dart';

abstract class CvRepository {
  Future<List<Cv>> getAllCvs();
  Future<Cv> getCvById(int id);
  Future<Cv> createCv(Cv cv);
  Future<Cv> updateCv(int id, Cv cv);
  Future<void> deleteCv(int id);
  Future<Cv> duplicateCv(int id);
}

class HttpCvRepository implements CvRepository {
  final ApiService _api;

  HttpCvRepository({ApiService? api}) : _api = api ?? ApiService();

  @override
  Future<List<Cv>> getAllCvs() => _api.getAllCvs();

  @override
  Future<Cv> getCvById(int id) => _api.getCvById(id);

  @override
  Future<Cv> createCv(Cv cv) => _api.createCv(cv);

  @override
  Future<Cv> updateCv(int id, Cv cv) => _api.updateCv(id, cv);

  @override
  Future<void> deleteCv(int id) => _api.deleteCv(id);

  @override
  Future<Cv> duplicateCv(int id) => _api.duplicateCv(id);
}
