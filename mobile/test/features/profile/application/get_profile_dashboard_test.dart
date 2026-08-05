import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/features/profile/application/get_profile_dashboard.dart';

void main() {
  group('GetProfileDashboard (#250 E3)', () {
    test('cvCount reporte, telechargements/partages inconnus par defaut', () {
      final dashboard = const GetProfileDashboard()(cvCount: 4);

      expect(dashboard.cvCount, 4);
      expect(dashboard.cvCountLabel, '4');
      expect(dashboard.downloads, isNull);
      expect(dashboard.shares, isNull);
      expect(dashboard.downloadsLabel, ProfileDashboard.unknown);
      expect(dashboard.sharesLabel, ProfileDashboard.unknown);
    });

    test('compteurs fournis : labels numeriques', () {
      final dashboard =
          const GetProfileDashboard()(cvCount: 0, downloads: 12, shares: 3);

      expect(dashboard.cvCountLabel, '0');
      expect(dashboard.downloadsLabel, '12');
      expect(dashboard.sharesLabel, '3');
    });

    test('zero est un compteur connu, distinct de inconnu', () {
      final dashboard = const GetProfileDashboard()(cvCount: 1, downloads: 0);

      expect(dashboard.downloadsLabel, '0');
      expect(dashboard.downloadsLabel, isNot(ProfileDashboard.unknown));
    });
  });
}
