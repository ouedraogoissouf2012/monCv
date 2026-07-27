import 'package:cv_mobile/features/cv/domain/value_objects/cv_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CvId', () {
    test('deux CvId de meme valeur sont egaux', () {
      expect(const CvId(42), const CvId(42));
      expect(const CvId(42).hashCode, const CvId(42).hashCode);
    });

    test('deux CvId de valeurs differentes ne sont pas egaux', () {
      expect(const CvId(1) == const CvId(2), isFalse);
    });

    test('isTemporary vrai pour une valeur negative (id offline)', () {
      expect(const CvId(-1).isTemporary, isTrue);
      expect(const CvId(-99).isTemporary, isTrue);
    });

    test('isTemporary faux pour une valeur positive (id persiste)', () {
      expect(const CvId(1).isTemporary, isFalse);
      expect(const CvId(1000).isTemporary, isFalse);
    });

    test('isTemporary faux pour zero', () {
      // 0 n'est pas un id temporaire : la convention offline utilise le
      // strictement negatif (cf. CvProvider._tempIdCounter demarre a -1).
      expect(const CvId(0).isTemporary, isFalse);
    });

    test('toString expose la valeur pour le debug', () {
      expect(const CvId(7).toString(), contains('7'));
    });
  });
}
