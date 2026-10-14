# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace

# Copy parent POM and shared libs first for caching
COPY pom.xml .
COPY libs/ libs/

# Install shared libs to local Maven repository
RUN mvn -f libs/common-web/pom.xml install -DskipTests -B && \
    mvn -f libs/common-events/pom.xml install -DskipTests -B && \
    mvn -f libs/common-observability/pom.xml install -DskipTests -B

# Copy own POM and download dependencies (cached layer)
COPY services/registry-service/pom.xml services/registry-service/pom.xml
RUN mvn -f services/registry-service/pom.xml dependency:go-offline -B

# Copy source code
COPY services/registry-service/ services/registry-service/

# Build
RUN mvn -f services/registry-service/pom.xml package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# Create non-root user
RUN groupadd -r electrocart && useradd -r -g electrocart electrocart

# Copy jar
COPY --from=build /workspace/services/registry-service/target/*.jar app.jar

# Switch to non-root user
RUN chown -R electrocart:electrocart /app
USER electrocart

EXPOSE 8761

ENTRYPOINT ["java", "-jar", "app.jar"]