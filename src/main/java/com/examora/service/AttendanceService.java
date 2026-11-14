package com.examora.service;

import com.examora.dao.AttendanceDAO;
import com.examora.model.AttendanceSession;
import com.examora.model.AttendanceRecord;

import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Calendar;
import java.util.List;
import java.util.Random;
import java.util.concurrent.atomic.AtomicInteger;

public class AttendanceService {
    private AttendanceDAO attendanceDAO;
    private static final Object codeGenerationLock = new Object();
    private static final AtomicInteger codeCounter = new AtomicInteger(0);

    // Jakarta timezone (WIB)
    private static final ZoneId JAKARTA_ZONE = ZoneId.of("Asia/Jakarta");

    public AttendanceService() {
        this.attendanceDAO = new AttendanceDAO();
    }

    // Get current time in Jakarta timezone
    private Timestamp getCurrentJakartaTime() {
        // Get current time in Jakarta timezone and convert to Timestamp
        // This ensures the attendance time is correctly recorded in UTC+7
        java.time.ZonedDateTime jakartaNow = java.time.ZonedDateTime.now(JAKARTA_ZONE);
        return Timestamp.from(jakartaNow.toInstant());
    }

    // Generate 6-character unique code with thread safety
    public String generateSessionCode() throws SQLException {
        String chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        Random random = new Random();
        String code;
        int attempts = 0;
        final int MAX_ATTEMPTS = 10;

        // Synchronize to prevent race condition
        synchronized (codeGenerationLock) {
            do {
                StringBuilder sb = new StringBuilder();
                // Add a counter component to reduce collision probability
                int counter = codeCounter.getAndIncrement() % 100;
                for (int i = 0; i < 4; i++) {
                    sb.append(chars.charAt(random.nextInt(chars.length())));
                }
                // Add counter as last 2 characters for uniqueness
                sb.append(chars.charAt(counter / 10));
                sb.append(chars.charAt(counter % 10));

                code = sb.toString();
                attempts++;

                if (attempts >= MAX_ATTEMPTS) {
                    // Fallback: use timestamp-based code if too many collisions
                    long timestamp = System.currentTimeMillis() % 1000000;
                    code = String.format("%06d", timestamp).replace('0', 'A')
                            .replace('1', 'B').replace('2', 'C').replace('3', 'D')
                            .replace('4', 'E').replace('5', 'F').replace('6', 'G')
                            .replace('7', 'H').replace('8', 'J').replace('9', 'K');
                    break;
                }
            } while (attendanceDAO.findSessionByCode(code) != null);
        }

        return code;
    }

    // Create session with validation
    public AttendanceSession createSession(String sessionName, java.sql.Date sessionDate,
                                           java.sql.Time startTime, java.sql.Time endTime,
                                           String targetTag, int createdBy, int lateThreshold) throws SQLException {

        // Validate input
        if (sessionName == null || sessionName.trim().isEmpty()) {
            throw new IllegalArgumentException("Nama sesi tidak boleh kosong");
        }

        if (sessionDate == null) {
            throw new IllegalArgumentException("Tanggal sesi tidak boleh kosong");
        }

        if (startTime == null || endTime == null) {
            throw new IllegalArgumentException("Waktu mulai dan selesai tidak boleh kosong");
        }

        if (!endTime.after(startTime)) {
            throw new IllegalArgumentException("Waktu selesai harus setelah waktu mulai");
        }

        // Create session
        AttendanceSession session = new AttendanceSession();
        session.setSessionName(sessionName.trim());
        session.setSessionCode(generateSessionCode());
        session.setSessionDate(sessionDate);
        session.setStartTime(startTime);
        session.setEndTime(endTime);
        session.setTargetTag((targetTag == null || targetTag.trim().isEmpty()) ? null : targetTag.trim());
        session.setCreatedBy(createdBy);
        session.setStatus("scheduled");
        session.setLateThreshold(lateThreshold);

        if (!attendanceDAO.createSession(session)) {
            throw new SQLException("Gagal membuat sesi absensi");
        }

        return session;
    }

    // Mark attendance with validation
    public AttendanceRecord markAttendance(String sessionCode, int userId, String userTag) throws SQLException {
        // Find session by code
        AttendanceSession session = attendanceDAO.findSessionByCode(sessionCode);
        if (session == null) {
            throw new IllegalArgumentException("Kode sesi tidak ditemukan");
        }

        // Check if session is active
        if (!session.isActive()) {
            throw new IllegalStateException("Sesi absensi tidak aktif");
        }

        // Check tag restriction
        if (!session.isVisibleToTag(userTag)) {
            throw new SecurityException("Anda tidak memiliki akses ke sesi ini");
        }

        // Check if already attended
        AttendanceRecord existingRecord = attendanceDAO.findRecordBySessionAndUser(session.getId(), userId);
        if (existingRecord != null) {
            throw new IllegalStateException("Anda sudah melakukan absensi untuk sesi ini");
        }

        // Get current time in Jakarta timezone
        Timestamp now = getCurrentJakartaTime();

        // Determine status (present or late)
        String status = "present";

        // Get current date/time in Jakarta timezone
        ZonedDateTime jakartaNow = ZonedDateTime.now(JAKARTA_ZONE);

        // Build the late deadline time in Jakarta timezone
        ZonedDateTime lateDeadline = session.getSessionDate().toLocalDate()
                .atTime(session.getStartTime().toLocalTime())
                .plusMinutes(session.getLateThreshold())
                .atZone(JAKARTA_ZONE);

        if (jakartaNow.isAfter(lateDeadline)) {
            status = "late";
        }

        // Create record
        AttendanceRecord record = new AttendanceRecord();
        record.setSessionId(session.getId());
        record.setUserId(userId);
        record.setAttendanceTime(now);
        record.setStatus(status);
        record.setNotes(null);

        if (!attendanceDAO.createRecord(record)) {
            throw new SQLException("Gagal mencatat absensi");
        }

        // Set session name for display
        record.setSessionName(session.getSessionName());

        return record;
    }

    // Get session by ID
    public AttendanceSession getSessionById(int id) throws SQLException {
        return attendanceDAO.findSessionById(id);
    }

    // Get session by code
    public AttendanceSession getSessionByCode(String code) throws SQLException {
        return attendanceDAO.findSessionByCode(code);
    }

    // Get all sessions
    public List<AttendanceSession> getAllSessions() throws SQLException {
        return attendanceDAO.findAllSessions();
    }

    // Get active sessions for a tag
    public List<AttendanceSession> getActiveSessionsForTag(String userTag) throws SQLException {
        return attendanceDAO.findActiveSessionsByTag(userTag);
    }

    // Update session status
    public boolean updateSessionStatus(int sessionId, String status) throws SQLException {
        if (!status.equals("scheduled") && !status.equals("active") && !status.equals("closed")) {
            throw new IllegalArgumentException("Status tidak valid");
        }
        return attendanceDAO.updateSessionStatus(sessionId, status);
    }

    // Update session details
    public boolean updateSession(int sessionId, String sessionName, java.sql.Date sessionDate,
                                  java.sql.Time startTime, java.sql.Time endTime,
                                  String targetTag, int lateThreshold) throws SQLException {
        // Validate input
        if (sessionName == null || sessionName.trim().isEmpty()) {
            throw new IllegalArgumentException("Nama sesi tidak boleh kosong");
        }

        if (sessionDate == null) {
            throw new IllegalArgumentException("Tanggal sesi tidak boleh kosong");
        }

        if (startTime == null || endTime == null) {
            throw new IllegalArgumentException("Waktu mulai dan selesai tidak boleh kosong");
        }

        if (!endTime.after(startTime)) {
            throw new IllegalArgumentException("Waktu selesai harus setelah waktu mulai");
        }

        // Get existing session
        AttendanceSession session = attendanceDAO.findSessionById(sessionId);
        if (session == null) {
            throw new IllegalArgumentException("Sesi tidak ditemukan");
        }

        // Update session fields
        session.setSessionName(sessionName.trim());
        session.setSessionDate(sessionDate);
        session.setStartTime(startTime);
        session.setEndTime(endTime);
        session.setTargetTag((targetTag == null || targetTag.trim().isEmpty()) ? null : targetTag.trim());
        session.setLateThreshold(lateThreshold);

        return attendanceDAO.updateSession(session);
    }

    // Delete session
    public boolean deleteSession(int sessionId) throws SQLException {
        return attendanceDAO.deleteSession(sessionId);
    }

    // Get user attendance history
    public List<AttendanceRecord> getUserAttendanceHistory(int userId) throws SQLException {
        return attendanceDAO.findRecordsByUser(userId);
    }

    // Get session records
    public List<AttendanceRecord> getSessionRecords(int sessionId) throws SQLException {
        return attendanceDAO.findRecordsBySession(sessionId);
    }

    // Get detailed records for export
    public List<AttendanceRecord> getDetailedRecordsForExport(int sessionId) throws SQLException {
        return attendanceDAO.getDetailedRecordsBySession(sessionId);
    }

    // Get session statistics
    public int[] getSessionStatistics(int sessionId) throws SQLException {
        return attendanceDAO.getSessionStatistics(sessionId);
    }

    // Update record status
    public boolean updateRecordStatus(int recordId, String status, String notes) throws SQLException {
        if (!status.equals("present") && !status.equals("late") && !status.equals("absent")) {
            throw new IllegalArgumentException("Status tidak valid");
        }
        return attendanceDAO.updateRecordStatus(recordId, status, notes);
    }
}
