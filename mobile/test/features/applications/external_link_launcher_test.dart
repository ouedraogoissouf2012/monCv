import 'package:cv_mobile/features/applications/domain/external_link_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExternalLinkPolicy.validate - securite (#246 A3)', () {
    test('accepte http et https absolus avec hote', () {
      expect(ExternalLinkPolicy.validate('https://acme.example/job'), isNotNull);
      expect(ExternalLinkPolicy.validate('http://acme.example'), isNotNull);
    });

    test('trim les espaces autour', () {
      expect(ExternalLinkPolicy.validate('  https://acme.example  '), isNotNull);
    });

    test('rejette null et vide', () {
      expect(ExternalLinkPolicy.validate(null), isNull);
      expect(ExternalLinkPolicy.validate(''), isNull);
      expect(ExternalLinkPolicy.validate('   '), isNull);
    });

    test('rejette les schemas dangereux (javascript, file, data)', () {
      expect(ExternalLinkPolicy.validate('javascript:alert(1)'), isNull);
      expect(ExternalLinkPolicy.validate('file:///etc/passwd'), isNull);
      expect(ExternalLinkPolicy.validate('data:text/html,<script>'), isNull);
    });

    test('rejette une URL relative ou sans hote', () {
      expect(ExternalLinkPolicy.validate('acme.example/job'), isNull);
      expect(ExternalLinkPolicy.validate('/chemin/relatif'), isNull);
      expect(ExternalLinkPolicy.validate('https://'), isNull);
    });

    test('scheme insensible a la casse', () {
      expect(ExternalLinkPolicy.validate('HTTPS://acme.example'), isNotNull);
    });
  });

  group('ExternalLinkLauncher via double (#246 A3)', () {
    test('URL invalide -> invalidUrl, sans tenter d ouverture', () async {
      final launcher = _FakeLauncher(willLaunch: true);
      final result = await launcher.open('javascript:alert(1)');
      expect(result, LinkLaunchResult.invalidUrl);
      expect(launcher.attempted, isFalse);
    });

    test('URL valide + ouverture ok -> success', () async {
      final launcher = _FakeLauncher(willLaunch: true);
      final result = await launcher.open('https://acme.example');
      expect(result, LinkLaunchResult.success);
      expect(launcher.attempted, isTrue);
    });

    test('URL valide + ouverture impossible -> couldNotLaunch', () async {
      final launcher = _FakeLauncher(willLaunch: false);
      final result = await launcher.open('https://acme.example');
      expect(result, LinkLaunchResult.couldNotLaunch);
    });
  });
}

/// Double de [ExternalLinkLauncher] : reutilise la vraie validation de
/// [ExternalLinkPolicy], ne simule que l'ouverture (pas de plugin en test).
class _FakeLauncher implements ExternalLinkLauncher {
  _FakeLauncher({required this.willLaunch});

  final bool willLaunch;
  bool attempted = false;

  @override
  Future<LinkLaunchResult> open(String? url) async {
    final uri = ExternalLinkPolicy.validate(url);
    if (uri == null) return LinkLaunchResult.invalidUrl;
    attempted = true;
    return willLaunch
        ? LinkLaunchResult.success
        : LinkLaunchResult.couldNotLaunch;
  }
}
