# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace

# Copy parent POM and shared libs first for caching
COPY pom.xml .
COPY libs/common-web/pom.xml libs/common-web/pom.xml
COPY libs/common-events/pom.xml libs/common-events/pom.xml
COPY libs/common-observability/pom.xml libs/common-observability/pom.xml
COPY services/registry-service/pom.xml services/registry-service/pom.xml
COPY services/gateway-service/pom.xml services/gateway-service/pom.xml
COPY services/catalog-service/pom.xml services/catalog-service/pom.xml
COPY services/inventory-service/pom.xml services/inventory-service/pom.xml
COPY services/cart-service/pom.xml services/cart-service/pom.xml
COPY services/order-service/pom.xml services/order-service/pom.xml
COPY services/payment-service/pom.xml services/payment-service/pom.xml
COPY services/customer-service/pom.xml services/customer-service/pom.xml
COPY services/shipping-service/pom.xml services/shipping-service/pom.xml
COPY services/search-service/pom.xml services/search-service/pom.xml
COPY services/notification-service/pom.xml services/notification-service/pom.xml

# Download dependencies (cached layer)
RUN mvn dependency:go-offline -pl services/registry-service -am -B

# Copy source code
COPY libs/ libs/
COPY services/registry-service/ services/registry-service/

# Build
RUN mvn -pl services/registry-service -am package -DskipTests -B

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
