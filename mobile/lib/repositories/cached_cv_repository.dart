import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/error/result.dart';
import '../models/cv.dart';
import 'cv_repository.dart';

const _kCacheKey = 'cached_cvs';

class CachedCvRepository implements CvRepository {
  final CvRepository _remote;
  final SharedPreferences _prefs;

  CachedCvRepository({required CvRepository remote, required SharedPreferences prefs})
      : _remote = remote,
        _prefs = prefs;

  // ── Cache helpers ──────────────────────────────────────────────

  List<Cv>? _readCache() {
    final raw = _prefs.getString(_kCacheKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Cv.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _writeCache(List<Cv> cvs) async {
    await _prefs.setString(_kCacheKey, jsonEncode(cvs.map((c) => c.toJson()).toList()));
  }

  Future<void> clearCache() async {
    await _prefs.remove(_kCacheKey);
  }

  // ── CvRepository ──────────────────────────────────────────────

  @override
  Future<Result<List<Cv>>> getAllCvs() async {
    final result = await _remote.getAllCvs();
    switch (result) {
      case Success(:final data):
        await _writeCache(data);
        return result;
      case Failure():
        final cached = _readCache();
        if (cached != null) return Result.success(cached);
        return result;
    }
  }

  @override
  Future<Result<Cv>> getCvById(int id) => _remote.getCvById(id);

  @override
  Future<Result<Cv>> createCv(Cv cv) async {
    final result = await _remote.createCv(cv);
    if (result case Success(:final data)) {
      final cached = _readCache();
      if (cached != null) await _writeCache([...cached, data]);
    }
    return result;
  }

  @override
  Future<Result<Cv>> updateCv(int id, Cv cv) async {
    final result = await _remote.updateCv(id, cv);
    if (result case Success(:final data)) {
      final cached = _readCache();
      if (cached != null) {
        await _writeCache([for (final c in cached) c.id == id ? data : c]);
      }
    }
    return result;
  }

  @override
  Future<Result<void>> deleteCv(int id) async {
    final result = await _remote.deleteCv(id);
    if (result.isSuccess) {
      final cached = _readCache();
      if (cached != null) {
        await _writeCache(cached.where((c) => c.id != id).toList());
      }
    }
    return result;
  }

  @override
  Future<Result<Cv>> duplicateCv(int id) async {
    final result = await _remote.duplicateCv(id);
    if (result case Success(:final data)) {
      final cached = _readCache();
      if (cached != null) await _writeCache([...cached, data]);
    }
    return result;
  }

  @override
  Future<Result<Cv>> createVariant(int cvId, String jobDescription, {String? label}) async {
    final result = await _remote.createVariant(cvId, jobDescription, label: label);
    if (result case Success(:final data)) {
      final cached = _readCache();
      if (cached != null) await _writeCache([...cached, data]);
    }
    return result;
  }
}
