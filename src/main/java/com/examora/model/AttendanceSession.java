package com.examora.model;

import java.sql.Date;
import java.sql.Time;
import java.text.SimpleDateFormat;
import java.time.ZoneId;
import java.time.ZonedDateTime;

public class AttendanceSession {
    private int id;
    private String sessionName;
    private String sessionCode;
    private Date sessionDate;
    private Time startTime;
    private Time endTime;
    private String targetTag;
    private int createdBy;
    private String createdByName;
    private String status;
    private int lateThreshold;

    // Jakarta timezone (WIB)
    private static final ZoneId JAKARTA_ZONE = ZoneId.of("Asia/Jakarta");

    public AttendanceSession() {}

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getSessionName() {
        return sessionName;
    }

    public void setSessionName(String sessionName) {
        this.sessionName = sessionName;
    }

    public String getSessionCode() {
        return sessionCode;
    }

    public void setSessionCode(String sessionCode) {
        this.sessionCode = sessionCode;
    }

    public Date getSessionDate() {
        return sessionDate;
    }

    public void setSessionDate(Date sessionDate) {
        this.sessionDate = sessionDate;
    }

    public Time getStartTime() {
        return startTime;
    }

    public void setStartTime(Time startTime) {
        this.startTime = startTime;
    }

    public Time getEndTime() {
        return endTime;
    }

    public void setEndTime(Time endTime) {
        this.endTime = endTime;
    }

    public String getTargetTag() {
        return targetTag;
    }

    public void setTargetTag(String targetTag) {
        this.targetTag = targetTag;
    }

    public int getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(int createdBy) {
        this.createdBy = createdBy;
    }

    public String getCreatedByName() {
        return createdByName;
    }

    public void setCreatedByName(String createdByName) {
        this.createdByName = createdByName;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public int getLateThreshold() {
        return lateThreshold;
    }

    public void setLateThreshold(int lateThreshold) {
        this.lateThreshold = lateThreshold;
    }

    // Helper methods
    public boolean isActive() {
        return "active".equals(status);
    }

    public boolean isOpenForAttendance() {
        if (!isActive()) return false;

        // Get current time in Jakarta timezone
        ZonedDateTime jakartaNow = ZonedDateTime.now(JAKARTA_ZONE);

        // Build session start and end time in Jakarta timezone
        ZonedDateTime sessionStart = sessionDate.toLocalDate()
                .atTime(startTime.toLocalTime())
                .atZone(JAKARTA_ZONE);

        ZonedDateTime sessionEnd = sessionDate.toLocalDate()
                .atTime(endTime.toLocalTime())
                .atZone(JAKARTA_ZONE);

        // Check if current Jakarta time is within session time range
        return !jakartaNow.isBefore(sessionStart) && !jakartaNow.isAfter(sessionEnd);
    }

    public boolean isVisibleToTag(String userTag) {
        if (targetTag == null || targetTag.isEmpty()) {
            return true; // No tag restriction
        }
        return targetTag.equals(userTag);
    }

    public String getFormattedDateTime() {
        SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy");
        SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm");
        return dateFormat.format(sessionDate) + " " + timeFormat.format(startTime) + " - " + timeFormat.format(endTime);
    }

    public String getStatusBadgeClass() {
        switch (status) {
            case "active":
                return "bg-success";
            case "closed":
                return "bg-secondary";
            case "scheduled":
            default:
                return "bg-warning text-dark";
        }
    }

    public String getStatusLabel() {
        switch (status) {
            case "active":
                return "Aktif";
            case "closed":
                return "Ditutup";
            case "scheduled":
            default:
                return "Terjadwal";
        }
    }
}
