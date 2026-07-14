import 'package:flutter/foundation.dart';
import '../models/job_application.dart';
import '../services/api_service.dart';

class JobApplicationProvider extends ChangeNotifier {
  final ApiService api;
  JobApplicationProvider(this.api);

  List<JobApplication> items = [];
  JobApplicationStatus? filter;
  bool loading = false;
  String? error;

  List<JobApplication> get dueItems => items.where((item) => item.followUpDue).toList();

  Future<void> load({JobApplicationStatus? status}) async {
    loading = true;
    error = null;
    filter = status;
    notifyListeners();
    try {
      items = await api.getJobApplications(status: status);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> save(JobApplication value) async {
    error = null;
    try {
      if (value.id == null) {
        await api.createJobApplication(value);
      } else {
        await api.updateJobApplication(value);
      }
      await load(status: filter);
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await api.deleteJobApplication(id);
      items.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
