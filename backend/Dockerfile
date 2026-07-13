# syntax=docker/dockerfile:1.7

# Stage 1 : build reproductible avec cache Maven BuildKit
FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /build

RUN apk add --no-cache maven

COPY pom.xml ./
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -B --no-transfer-progress

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -DskipTests -B --no-transfer-progress

# Stage 2 : runtime non-root
FROM eclipse-temurin:21-jre-alpine AS runtime

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

COPY --from=build --chown=app:app /build/target/cv-mobile-backend-*.jar /app/app.jar

RUN mkdir -p /app/uploads && chown app:app /app/uploads

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError -Djava.security.egd=file:/dev/./urandom"

EXPOSE 8082

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget -qO- http://localhost:8082/actuator/health/liveness > /dev/null 2>&1 || exit 1

USER app

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
