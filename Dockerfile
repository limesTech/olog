# Use Maven image to execute build.
FROM maven:3.9.11-eclipse-temurin-25 AS maven-build
RUN mkdir phoebus-olog
WORKDIR /phoebus-olog
COPY . .
RUN mvn clean install \
    -DskipTests=true \
    -Dmaven.javadoc.skip=true \
    -Dmaven.source.skip=true \
    -Pdeployable-jar

# Use smaller openjdk image for running.
FROM eclipse-temurin:25-jdk as olog
# Run commands as user 'olog'
RUN apt update && apt install -y ldap-utils
RUN useradd -ms /bin/bash olog
# Use previous maven-build image.
COPY --from=maven-build /phoebus-olog/target /olog-target
COPY --from=maven-build /phoebus-olog/target/service-olog-*-SNAPSHOT.jar /olog-target/service-olog.jar
RUN chown -R olog:olog /olog-target
# Switch to non-root user
USER olog
WORKDIR /olog-target
EXPOSE 8080 8181

ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar service-olog.jar"]
CMD []  # Empty CMD allows for easy overrides if needed
