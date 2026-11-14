# Exatuy — Dependency清单 (Java/Maven)
# Diperoleh otomatis dari pom.xml. Simpan sebagai referensi.
#
# Versi di bawah ini adalah yang sudah diverifikasi berhasil build WAR dan jalan di Tomcat 10 + MySQL 8.

# === Core runtime ===
jakarta.servlet:jakarta.servlet-api:6.0.0              # Servlet API (provided by Tomcat)
jakarta.servlet.jsp:jakarta.servlet.jsp-api:3.1.0      # JSP API
jakarta.el:jakarta.el-api:5.0.0                        # Expression Language
com.mysql:mysql-connector-j:8.2.0                      # JDBC driver MySQL 8
org.glassfish.web:jakarta.servlet.jsp.jstl:3.0.1       # JSTL implementation
jakarta.servlet.jsp.jstl:jakarta.servlet.jsp.jstl-api:3.0.0

# === Crypto / security ===
org.mindrot:jbcrypt:0.4                                # BCrypt password hashing

# === Data / JSON / CSV ===
com.google.code.gson:gson:2.10.1                       # JSON parsing
org.apache.commons:commons-lang3:3.14.0                # String/collection utilities
org.apache.commons:commons-csv:1.10.0                  # CSV import/export

# === Connection pooling & logging ===
com.zaxxer:HikariCP:5.1.0                              # Connection pool
org.slf4j:slf4j-simple:2.0.9                           # Simple logger (HikariCP)

# === Reporting ===
com.itextpdf:itextpdf:5.5.13.3                         # PDF generation (export quiz results)

# === Email ===
com.sun.mail:jakarta.mail:2.0.1                        # Jakarta Mail API

# === Real-time (WebSocket, provided by Tomcat) ===
jakarta.websocket:jakarta.websocket-api:2.1.0
jakarta.websocket:jakarta.websocket-client-api:2.1.0

# === Test ===
org.junit.jupiter:junit-jupiter:5.10.1                 # Unit tests
org.mockito:mockito-core:5.8.0                         # Test mocks

# === Build plugins (Maven) ===
org.apache.maven.plugins:maven-compiler-plugin:3.11.0
org.apache.maven.plugins:maven-war-plugin:3.4.0
org.apache.maven.plugins:maven-surefire-plugin:3.2.2
org.codehaus.cargo:cargo-maven3-plugin:1.10.10
