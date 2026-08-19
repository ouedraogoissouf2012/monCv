import 'package:cv_mobile/utils/strict_date_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StrictDateInput', () {
    test('refuse un mois 23 avant l annee', () {
      expect(
        StrictDateInput.rejectReason('3023', minYear: 1927, maxYear: 2026),
        contains('12 mois'),
      );
    });

    test('refuse le premier chiffre de mois 3', () {
      expect(
        StrictDateInput.rejectReason('303', minYear: 1927, maxYear: 2026),
        contains('12 mois'),
      );
    });

    test('accepte 15/03/2010', () {
      expect(
        StrictDateInput.rejectReason('15032010', minYear: 1927, maxYear: 2016),
        isNull,
      );
      expect(StrictDateInput.parse('15/03/2010'), DateTime(2010, 3, 15));
    });

    test('annee de naissance trop recente', () {
      expect(
        StrictDateInput.rejectReason('01012020',
            minYear: 1927, maxYear: StrictDateInput.maxBirthYear(DateTime(2026))),
        contains('2016'),
      );
    });

    test('masque jj/mm/aaaa', () {
      expect(StrictDateInput.mask('1503'), '15/03');
      expect(StrictDateInput.mask('15032010'), '15/03/2010');
    });
  });
}
