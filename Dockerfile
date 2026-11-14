# Examora - Runtime only (build locally, deploy WAR only)
FROM tomcat:10-jdk11

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy pre-built WAR file (built on local machine, NOT on VPS)
COPY examora.war /usr/local/tomcat/webapps/ROOT.war

# Expose port
EXPOSE 8080

# Set timezone
ENV JAVA_OPTS="-Duser.timezone=Asia/Jakarta"
ENV CATALINA_OPTS="-Duser.timezone=Asia/Jakarta"

RUN echo "export CATALINA_OPTS=\"-Duser.timezone=Asia/Jakarta\"" > /usr/local/tomcat/bin/setenv.sh && \
    chmod +x /usr/local/tomcat/bin/setenv.sh

CMD ["catalina.sh", "run"]
