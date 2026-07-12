# syntax=docker/dockerfile:1.7

# ============================================================
# Stage 1 : Build avec Maven
# ============================================================
FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /build

# Cache des dependances (layer separe pour docker cache)
COPY pom.xml ./
RUN mvn dependency:go-offline -B --no-transfer-progress

# Build
COPY src ./src
RUN mvn clean package -DskipTests -B --no-transfer-progress

# ============================================================
# Stage 2 : Runtime minimal
# ============================================================
FROM eclipse-temurin:21-jre-alpine AS runtime

# Utilisateur non-root (securite)
RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

# Copier le JAR
COPY --from=build --chown=app:app /build/target/cv-mobile-backend-*.jar /app/app.jar

# Creer le volume uploads
RUN mkdir -p /app/uploads && chown app:app /app/uploads

EXPOSE 8082

# Health check interne (utilise par docker, orchestrateurs)
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget -qO- http://localhost:8082/actuator/health/liveness > /dev/null 2>&1 || exit 1

USER app

# JVM args adaptes au conteneur
ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-XX:+ExitOnOutOfMemoryError", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-jar", "/app/app.jar"]
