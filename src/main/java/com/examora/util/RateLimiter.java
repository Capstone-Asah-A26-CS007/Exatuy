package com.examora.util;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Rate Limiter for Login Protection
 * Prevents brute force attacks by limiting login attempts
 */
public class RateLimiter {

    // Maximum login attempts before lockout
    private static final int MAX_ATTEMPTS = 5;

    // Lockout duration in milliseconds (15 minutes)
    private static final long LOCKOUT_DURATION = 15 * 60 * 1000;

    // Attempt window in milliseconds (15 minutes)
    private static final long ATTEMPT_WINDOW = 15 * 60 * 1000;

    // Store for login attempts: key = IP or email, value = AttemptRecord
    private static final Map<String, AttemptRecord> attemptStore = new ConcurrentHashMap<>();

    // Cleanup interval (run cleanup every 100 checks)
    private static final int CLEANUP_INTERVAL = 100;
    private static AtomicInteger cleanupCounter = new AtomicInteger(0);

    /**
     * Inner class to track attempts
     */
    private static class AttemptRecord {
        int attemptCount;
        long firstAttemptTime;
        long lockoutUntil;

        AttemptRecord() {
            this.attemptCount = 0;
            this.firstAttemptTime = System.currentTimeMillis();
            this.lockoutUntil = 0;
        }

        synchronized void increment() {
            this.attemptCount++;
        }

        synchronized void reset() {
            this.attemptCount = 0;
            this.firstAttemptTime = System.currentTimeMillis();
            this.lockoutUntil = 0;
        }

        synchronized boolean isLockedOut() {
            return System.currentTimeMillis() < lockoutUntil;
        }

        synchronized long getRemainingLockoutTime() {
            long remaining = lockoutUntil - System.currentTimeMillis();
            return remaining > 0 ? remaining / 1000 : 0;
        }

        synchronized void lockout() {
            this.lockoutUntil = System.currentTimeMillis() + LOCKOUT_DURATION;
        }

        synchronized boolean isExpired() {
            // Record is expired if no attempts in the window and not locked out
            return System.currentTimeMillis() - firstAttemptTime > ATTEMPT_WINDOW && !isLockedOut();
        }
    }

    /**
     * Check if login is allowed for the given identifier (IP or email)
     * @param identifier The IP address or email to check
     * @return RateLimitResult containing status and remaining attempts
     */
    public static RateLimitResult checkLoginAllowed(String identifier) {
        if (identifier == null || identifier.isEmpty()) {
            return new RateLimitResult(true, MAX_ATTEMPTS, 0, null);
        }

        // Periodic cleanup
        if (cleanupCounter.incrementAndGet() % CLEANUP_INTERVAL == 0) {
            cleanup();
        }

        AttemptRecord record = attemptStore.computeIfAbsent(identifier, k -> new AttemptRecord());

        synchronized (record) {
            // Check if currently locked out
            if (record.isLockedOut()) {
                long remainingTime = record.getRemainingLockoutTime();
                String message = String.format("Akun terkunci. Coba lagi dalam %d menit %d detik.",
                        remainingTime / 60, remainingTime % 60);
                return new RateLimitResult(false, 0, remainingTime, message);
            }

            // Check if attempt window has expired, reset if so
            if (System.currentTimeMillis() - record.firstAttemptTime > ATTEMPT_WINDOW) {
                record.reset();
            }

            int remainingAttempts = MAX_ATTEMPTS - record.attemptCount;
            return new RateLimitResult(true, remainingAttempts, 0, null);
        }
    }

    /**
     * Record a failed login attempt
     * @param identifier The IP address or email
     * @return true if this attempt triggered a lockout
     */
    public static boolean recordFailedAttempt(String identifier) {
        if (identifier == null || identifier.isEmpty()) {
            return false;
        }

        AttemptRecord record = attemptStore.computeIfAbsent(identifier, k -> new AttemptRecord());

        synchronized (record) {
            record.increment();

            // Check if should lockout
            if (record.attemptCount >= MAX_ATTEMPTS) {
                record.lockout();
                return true;
            }

            return false;
        }
    }

    /**
     * Reset attempts after successful login
     * @param identifier The IP address or email
     */
    public static void resetAttempts(String identifier) {
        if (identifier == null || identifier.isEmpty()) {
            return;
        }

        AttemptRecord record = attemptStore.get(identifier);
        if (record != null) {
            synchronized (record) {
                record.reset();
            }
        }
    }

    /**
     * Get remaining attempts for an identifier
     * @param identifier The IP address or email
     * @return Number of remaining attempts
     */
    public static int getRemainingAttempts(String identifier) {
        if (identifier == null || identifier.isEmpty()) {
            return MAX_ATTEMPTS;
        }

        AttemptRecord record = attemptStore.get(identifier);
        if (record == null) {
            return MAX_ATTEMPTS;
        }

        synchronized (record) {
            if (record.isLockedOut()) {
                return 0;
            }
            return Math.max(0, MAX_ATTEMPTS - record.attemptCount);
        }
    }

    /**
     * Get remaining lockout time in seconds
     * @param identifier The IP address or email
     * @return Remaining lockout time in seconds, 0 if not locked
     */
    public static long getRemainingLockoutTime(String identifier) {
        if (identifier == null || identifier.isEmpty()) {
            return 0;
        }

        AttemptRecord record = attemptStore.get(identifier);
        if (record == null) {
            return 0;
        }

        return record.getRemainingLockoutTime();
    }

    /**
     * Cleanup expired records
     */
    private static void cleanup() {
        attemptStore.entrySet().removeIf(entry -> {
            AttemptRecord record = entry.getValue();
            synchronized (record) {
                return record.isExpired();
            }
        });
    }

    /**
     * Result class for rate limit check
     */
    public static class RateLimitResult {
        private final boolean allowed;
        private final int remainingAttempts;
        private final long lockoutSeconds;
        private final String message;

        public RateLimitResult(boolean allowed, int remainingAttempts, long lockoutSeconds, String message) {
            this.allowed = allowed;
            this.remainingAttempts = remainingAttempts;
            this.lockoutSeconds = lockoutSeconds;
            this.message = message;
        }

        public boolean isAllowed() {
            return allowed;
        }

        public int getRemainingAttempts() {
            return remainingAttempts;
        }

        public long getLockoutSeconds() {
            return lockoutSeconds;
        }

        public String getMessage() {
            return message;
        }
    }
}
