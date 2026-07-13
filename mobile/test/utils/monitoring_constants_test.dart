import 'package:cv_mobile/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sentry reste desactive par defaut', () {
    expect(MonitoringConstants.sentryEnabled, isFalse);
    expect(MonitoringConstants.sentryDsn, isEmpty);
  });
}
