/*
# stage-1
FROM amazoncorretto:11-alpine-jdk as builder
RUN mkdir -p /app/source
COPY . /app/source
WORKDIR /app/source
RUN ./mvnw package
# ENTRYPOINT ["java", "-jar", "./target/datastore-0.0.4.jar"]

#stage-2
FROM amazoncorretto:11-alpine-jdk
COPY --from=builder /app/source/target/*.jar /app/app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
*/

# stage-1 (build)
FROM amazoncorretto:11-alpine-jdk as builder

RUN mkdir -p /app/source
COPY . /app/source
WORKDIR /app/source

# Fix permission issue
RUN chmod +x mvnw

# Build application
RUN ./mvnw clean package -DskipTests


# stage-2 (runtime)
FROM amazoncorretto:11-alpine-jdk

WORKDIR /app

COPY --from=builder /app/source/target/*.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
