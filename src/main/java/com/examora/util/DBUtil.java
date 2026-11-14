package com.examora.util;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;
import java.io.InputStream;
import java.util.TimeZone;

/**
 * Database Utility Class - Manages database connections using HikariCP connection pool
 * Optimized for concurrent access (130+ users)
 */
public class DBUtil {
    private static HikariDataSource dataSource;
    private static boolean initialized = false;

    // Database configuration defaults (should be overridden via environment or properties file)
    // Using Asia/Jakarta timezone for consistent date/time handling (WIB = UTC+7)
    private static final String DEFAULT_URL = "jdbc:mysql://localhost:3306/examora_db?useSSL=false&serverTimezone=Asia/Jakarta&allowPublicKeyRetrieval=true";
    private static final String DEFAULT_USERNAME = "examora_user";
    private static final String DEFAULT_PASSWORD = "change_me";

    // Connection pool configuration for 130+ concurrent users
    private static final int MAXIMUM_POOL_SIZE = 50;        // Max connections in pool
    private static final int MINIMUM_IDLE = 10;             // Min idle connections
    private static final long CONNECTION_TIMEOUT = 30000;   // 30 seconds
    private static final long IDLE_TIMEOUT = 600000;        // 10 minutes
    private static final long MAX_LIFETIME = 1800000;       // 30 minutes
    private static final long KEEPALIVE_TIME = 0;           // Disabled
    private static final int LEAK_DETECTION_THRESHOLD = 60000; // 1 minute

    static {
        // Set default timezone to Jakarta (WIB) for consistent date/time handling
        TimeZone.setDefault(TimeZone.getTimeZone("Asia/Jakarta"));
        System.out.println("DBUtil: Default timezone set to Asia/Jakarta (WIB)");
        initialize();
    }

    private static void initialize() {
        if (initialized) return;

        try {
            String url, username, password;

            // Priority 1: Environment variables (for Docker)
            String envUrl = System.getenv("DB_URL");
            String envUsername = System.getenv("DB_USERNAME");
            String envPassword = System.getenv("DB_PASSWORD");

            if (envUrl != null && !envUrl.isEmpty()) {
                url = envUrl;
                username = envUsername != null ? envUsername : DEFAULT_USERNAME;
                password = envPassword != null ? envPassword : DEFAULT_PASSWORD;
                System.out.println("DBUtil: Using environment variables for DB configuration");
            } else {
                // Priority 2: Properties file
                Properties props = new Properties();
                InputStream is = DBUtil.class.getClassLoader().getResourceAsStream("db.properties");

                if (is != null) {
                    props.load(is);
                    url = props.getProperty("db.url", DEFAULT_URL);
                    username = props.getProperty("db.username", DEFAULT_USERNAME);
                    password = props.getProperty("db.password", DEFAULT_PASSWORD);
                    is.close();
                    System.out.println("DBUtil: Using db.properties for DB configuration");
                } else {
                    // Priority 3: Default configuration
                    url = DEFAULT_URL;
                    username = DEFAULT_USERNAME;
                    password = DEFAULT_PASSWORD;
                    System.out.println("DBUtil: Using default DB configuration");
                }
            }

            // Configure HikariCP
            HikariConfig config = new HikariConfig();
            config.setJdbcUrl(url);
            config.setUsername(username);
            config.setPassword(password);
            config.setDriverClassName("com.mysql.cj.jdbc.Driver");
            config.setDriverClassName("com.mysql.cj.jdbc.Driver");

            // Connection pool settings optimized for 130+ users
            config.setMaximumPoolSize(MAXIMUM_POOL_SIZE);
            config.setMinimumIdle(MINIMUM_IDLE);
            config.setConnectionTimeout(CONNECTION_TIMEOUT);
            config.setIdleTimeout(IDLE_TIMEOUT);
            config.setMaxLifetime(MAX_LIFETIME);
            config.setKeepaliveTime(KEEPALIVE_TIME);
            config.setLeakDetectionThreshold(LEAK_DETECTION_THRESHOLD);

            // Performance optimizations
            config.addDataSourceProperty("cachePrepStmts", "true");
            config.addDataSourceProperty("prepStmtCacheSize", "250");
            config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
            config.addDataSourceProperty("useServerPrepStmts", "true");
            config.addDataSourceProperty("useLocalSessionState", "true");
            config.addDataSourceProperty("rewriteBatchedStatements", "true");
            config.addDataSourceProperty("cacheResultSetMetadata", "true");
            config.addDataSourceProperty("cacheServerConfiguration", "true");
            config.addDataSourceProperty("elideSetAutoCommits", "true");
            config.addDataSourceProperty("maintainTimeStats", "false");

            // Pool name for logging
            config.setPoolName("ExamoraPool");

            // Create data source
            dataSource = new HikariDataSource(config);
            initialized = true;

            System.out.println("DBUtil initialized with HikariCP connection pool.");
            System.out.println("  - Pool Name: " + config.getPoolName());
            System.out.println("  - Max Pool Size: " + MAXIMUM_POOL_SIZE);
            System.out.println("  - Min Idle: " + MINIMUM_IDLE);
            System.out.println("  - Database URL: " + url);

        } catch (Exception e) {
            System.err.println("DBUtil initialization error: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Failed to initialize database connection pool", e);
        }
    }

    /**
     * Set database configuration programmatically
     */
    public static void configure(String dbUrl, String dbUsername, String dbPassword) {
        // Close existing pool if any
        if (dataSource != null && !dataSource.isClosed()) {
            dataSource.close();
        }
        initialized = false;

        // Reinitialize with new config
        System.setProperty("DB_URL", dbUrl);
        System.setProperty("DB_USERNAME", dbUsername);
        System.setProperty("DB_PASSWORD", dbPassword);

        initialize();
    }

    /**
     * Get a database connection from the pool
     */
    public static Connection getConnection() throws SQLException {
        if (!initialized || dataSource == null) {
            initialize();
        }
        return dataSource.getConnection();
    }

    /**
     * Close a database connection safely (returns to pool)
     */
    public static void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                conn.close(); // Returns connection to pool
            } catch (SQLException e) {
                System.err.println("Error closing connection: " + e.getMessage());
            }
        }
    }

    /**
     * Test database connection
     */
    public static boolean testConnection() {
        try (Connection conn = getConnection()) {
            return conn != null && conn.isValid(5);
        } catch (SQLException e) {
            System.err.println("Database connection test failed: " + e.getMessage());
            return false;
        }
    }

    /**
     * Get pool statistics for monitoring
     */
    public static String getPoolStats() {
        if (dataSource == null) {
            return "Connection pool not initialized";
        }
        return String.format(
            "Pool Stats - Total: %d, Active: %d, Idle: %d, Waiting: %d",
            dataSource.getHikariPoolMXBean().getTotalConnections(),
            dataSource.getHikariPoolMXBean().getActiveConnections(),
            dataSource.getHikariPoolMXBean().getIdleConnections(),
            dataSource.getHikariPoolMXBean().getThreadsAwaitingConnection()
        );
    }

    /**
     * Shutdown the connection pool (call on application shutdown)
     */
    public static void shutdown() {
        if (dataSource != null && !dataSource.isClosed()) {
            dataSource.close();
            System.out.println("HikariCP connection pool shut down.");
        }
    }
}
