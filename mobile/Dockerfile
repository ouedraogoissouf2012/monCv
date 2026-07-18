# syntax=docker/dockerfile:1.7

FROM ghcr.io/cirruslabs/flutter:3.38.5@sha256:5d943d2f328d8e6624d56eefd1f9a71897b96e79b766dfb0f2e42c6b6498cf8d AS build

WORKDIR /build

COPY pubspec.yaml pubspec.lock ./
RUN --mount=type=cache,target=/root/.pub-cache \
    flutter pub get --enforce-lockfile

COPY . .

ARG SENTRY_DSN=
RUN --mount=type=cache,target=/root/.pub-cache \
    flutter build web --release --no-pub --no-wasm-dry-run \
      --pwa-strategy=offline-first \
      --dart-define=APP_ENV=production \
      --dart-define=API_BASE_URL=/api \
      --dart-define=SENTRY_DSN=${SENTRY_DSN}

FROM nginxinc/nginx-unprivileged:1.27.4-alpine@sha256:62a904036bfc0e4a4f2b556e34cbf17bc136b47fde8cdb4628762725f48c5782 AS runtime

COPY deploy/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY deploy/nginx/security-headers.conf /etc/nginx/security-headers.conf
COPY --from=build /build/build/web /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz >/dev/null 2>&1 || exit 1
