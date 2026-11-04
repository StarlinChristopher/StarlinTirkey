# syntax=docker/dockerfile:1.7
FROM dhi.io/maven:3.10.0-jdk17-alpine3.22-dev AS build
WORKDIR /build

# Cache dependency resolution independently from application source changes.
COPY pom.xml ./
RUN --mount=type=cache,target=/root/.m2 mvn -B -ntp dependency:go-offline

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B -ntp verify

FROM dhi.io/eclipse-temurin:17-alpine AS runtime
WORKDIR /app
COPY --from=build --chown=65532:65532 /build/target/app-1.0.0.jar /app/app.jar
COPY --chown=65532:65532 src/main/resources/web/ /app/web/
USER 65532:65532
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 CMD ["java", "-cp", "/app/app.jar", "com.example.app.HealthCheck"]
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-Djava.io.tmpdir=/tmp", "-jar", "/app/app.jar"]
