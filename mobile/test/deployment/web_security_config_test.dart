import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le conteneur web reste non privilegie et utilise une API same-origin',
      () {
    final dockerfile = File('Dockerfile').readAsStringSync();
    final compose = File('../docker-compose.prod.yml').readAsStringSync();

    expect(dockerfile, contains('nginxinc/nginx-unprivileged'));
    expect(dockerfile, contains('--dart-define=API_BASE_URL=/api'));
    expect(compose, contains('cap_drop:'));
    expect(compose, contains('no-new-privileges:true'));
    expect(compose, contains('ports: []'));
  });

  test('nginx impose CSP, HSTS, anti-framing et proxy same-origin', () {
    final headers =
        File('deploy/nginx/security-headers.conf').readAsStringSync();
    final nginx = File('deploy/nginx/default.conf').readAsStringSync();

    expect(headers, contains("default-src 'self'"));
    expect(headers, contains("frame-ancestors 'none'"));
    expect(headers, contains('Strict-Transport-Security'));
    expect(headers, contains('X-Content-Type-Options "nosniff"'));
    expect(headers, isNot(contains("connect-src 'self' https:;")));
    expect(nginx, contains('proxy_pass http://backend:8082;'));
    expect(nginx, contains('client_max_body_size 10m;'));
  });
}
