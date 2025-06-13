# Use OpenJDK 17 as the base image
ARG BASE_IMAGE=eclipse-temurin:17-jdk-noble
FROM ${BASE_IMAGE}

# Set working directory
WORKDIR /app

# Copy the JAR file
COPY target/knative-color-demo-*.jar app.jar

# Expose port 8080
EXPOSE 8080

# Set environment variables
ENV JAVA_OPTS=""

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
