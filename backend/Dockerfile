# syntax=docker/dockerfile:1.7

# Stage 1 : build reproductible avec cache Maven BuildKit
FROM maven:3.9.16-eclipse-temurin-25-alpine@sha256:72e2d64836e659d053a573ac9ebab05b78ae78fa7bb69b7452a7cb877b465fc7 AS build

WORKDIR /build

RUN apk upgrade --no-cache

COPY pom.xml ./
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -B --no-transfer-progress

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -DskipTests -B --no-transfer-progress

# Stage 2 : runtime non-root
FROM eclipse-temurin:25-jre-alpine@sha256:28db6fdf60e38945e43d840c0333aeaec66c15943070104f7586fd3c9d1665b0 AS runtime

RUN apk upgrade --no-cache \
    && addgroup -S app \
    && adduser -S app -G app

WORKDIR /app

COPY --from=build --chown=app:app /build/target/cv-mobile-backend-*.jar /app/app.jar

RUN mkdir -p /app/uploads && chown app:app /app/uploads

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8082

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget -qO- http://localhost:8082/actuator/health/liveness > /dev/null 2>&1 || exit 1

USER app

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
