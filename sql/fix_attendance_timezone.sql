-- Fix attendance records with future timestamps
-- This script adjusts attendance times that are in the future to match the expected UTC+7 timezone

-- First, let's see the current state
SELECT
    ar.id,
    ar.user_id,
    u.name,
    ar.attendance_time as original_utc,
    CONVERT_TZ(ar.attendance_time, 'UTC', 'Asia/Jakarta') as original_jakarta,
    DATE_SUB(CONVERT_TZ(ar.attendance_time, 'UTC', 'Asia/Jakarta'), INTERVAL 7 HOUR) as adjusted_jakarta,
    ar.status
FROM attendance_records ar
JOIN users u ON ar.user_id = u.id
WHERE ar.attendance_time > NOW()
ORDER BY ar.attendance_time ASC;

-- Fix the timestamps by subtracting 7 hours to convert from incorrectly stored Jakarta time to UTC
UPDATE attendance_records
SET attendance_time = DATE_SUB(attendance_time, INTERVAL 7 HOUR)
WHERE attendance_time > NOW();

-- Verify the fix
SELECT
    ar.id,
    ar.user_id,
    u.name,
    ar.attendance_time as fixed_utc,
    CONVERT_TZ(ar.attendance_time, 'UTC', 'Asia/Jakarta') as fixed_jakarta,
    ar.status
FROM attendance_records ar
JOIN users u ON ar.user_id = u.id
WHERE ar.session_id = 3
ORDER BY ar.attendance_time DESC
LIMIT 10;
