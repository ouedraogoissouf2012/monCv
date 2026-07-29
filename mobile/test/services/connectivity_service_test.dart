import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cv_mobile/services/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('ConnectivityService - sans singleton manuel (#240, C5)', () {
    test('deux instances sont distinctes (plus de singleton)', () {
      final a = ConnectivityService();
      final b = ConnectivityService();
      expect(identical(a, b), isFalse);
    });

    test('isConnected true quand au moins un reseau est actif', () async {
      final conn = _MockConnectivity();
      when(() => conn.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      final service = ConnectivityService(connectivity: conn);

      expect(await service.isConnected(), isTrue);
    });

    test('isConnected false quand aucun reseau', () async {
      final conn = _MockConnectivity();
      when(() => conn.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      final service = ConnectivityService(connectivity: conn);

      expect(await service.isConnected(), isFalse);
    });
  });
}
