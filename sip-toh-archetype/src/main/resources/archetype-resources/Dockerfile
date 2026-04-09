FROM eclipse-temurin:${javaVersion}-jre-alpine AS runtime

WORKDIR /app

COPY target/${artifactId}-*.jar app.jar

EXPOSE 8080

ENV JAVA_OPTS="-XX:+UseZGC -XX:MaxRAMPercentage=75.0"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
