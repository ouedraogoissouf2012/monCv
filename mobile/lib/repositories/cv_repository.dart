import '../core/error/result.dart';
import '../core/error/safe_call.dart';
import '../models/cv.dart';
import '../services/api_service.dart';

abstract class CvRepository {
  Future<Result<List<Cv>>> getAllCvs();
  Future<Result<Cv>> getCvById(int id);
  Future<Result<Cv>> createCv(Cv cv);
  Future<Result<Cv>> updateCv(int id, Cv cv);
  Future<Result<void>> deleteCv(int id);
  Future<Result<Cv>> duplicateCv(int id);
  Future<Result<Cv>> createVariant(int cvId, String jobDescription, {String? label});
}

class HttpCvRepository implements CvRepository {
  final ApiService _api;

  HttpCvRepository({ApiService? api}) : _api = api ?? ApiService();

  @override
  Future<Result<List<Cv>>> getAllCvs() => safeCall(() => _api.getAllCvs());

  @override
  Future<Result<Cv>> getCvById(int id) => safeCall(() => _api.getCvById(id));

  @override
  Future<Result<Cv>> createCv(Cv cv) => safeCall(() => _api.createCv(cv));

  @override
  Future<Result<Cv>> updateCv(int id, Cv cv) => safeCall(() => _api.updateCv(id, cv));

  @override
  Future<Result<void>> deleteCv(int id) => safeCall(() => _api.deleteCv(id));

  @override
  Future<Result<Cv>> duplicateCv(int id) => safeCall(() => _api.duplicateCv(id));

  @override
  Future<Result<Cv>> createVariant(int cvId, String jobDescription, {String? label}) =>
      safeCall(() => _api.createVariant(cvId, jobDescription, label: label));
}
