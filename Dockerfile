# Stage 1 - Build
FROM amazoncorretto:11-alpine-jdk as builder

WORKDIR /app
COPY . .

# Give permission to mvnw
RUN chmod +x mvnw

# Build the application
RUN ./mvnw clean package -DskipTests


# Stage 2 - Run
FROM amazoncorretto:11-alpine-jdk

WORKDIR /app

# Copy jar from builder stage
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
