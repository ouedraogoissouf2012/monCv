import 'package:connectivity_plus/connectivity_plus.dart';

/// Service de connectivite reseau.
///
/// Cycle de vie gere par la DI (issue #240) : plus de singleton manuel
/// `static final _instance`. [Connectivity] est injectable pour les tests.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
