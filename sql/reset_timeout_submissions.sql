-- Reset Timeout Submissions for Quiz
-- This script allows participants with 'timeout' status to retake a quiz
-- Run this when you've updated quiz duration and want to allow timeout users to retake

-- For Quiz ID 6 specifically:
-- Step 1: View all timeout submissions for quiz 6
SELECT
    s.id as submission_id,
    s.user_id,
    u.name as user_name,
    u.email as user_email,
    s.status,
    s.score,
    s.started_at,
    q.title as quiz_title,
    q.duration as quiz_duration
FROM submissions s
JOIN users u ON s.user_id = u.id
JOIN quiz q ON s.quiz_id = q.id
WHERE s.quiz_id = 6 AND s.status = 'timeout';

-- Step 2: Delete answers for timeout submissions on quiz 6
DELETE a FROM answers a
INNER JOIN submissions s ON a.submission_id = s.id
WHERE s.quiz_id = 6 AND s.status = 'timeout';

-- Step 3: Delete timeout submissions on quiz 6 (allows retake)
DELETE FROM submissions
WHERE quiz_id = 6 AND status = 'timeout';

-- Verify: Check remaining submissions for quiz 6
SELECT
    s.id,
    u.name,
    s.status,
    s.score
FROM submissions s
JOIN users u ON s.user_id = u.id
WHERE s.quiz_id = 6;

-- ============================================
-- Generic version for any quiz (replace :quiz_id)
-- ============================================

-- View timeout submissions for a specific quiz
-- SELECT s.id, s.user_id, u.name, u.email, s.status, s.score
-- FROM submissions s
-- JOIN users u ON s.user_id = u.id
-- WHERE s.quiz_id = :quiz_id AND s.status = 'timeout';

-- Delete answers for timeout submissions
-- DELETE a FROM answers a
-- INNER JOIN submissions s ON a.submission_id = s.id
-- WHERE s.quiz_id = :quiz_id AND s.status = 'timeout';

-- Delete timeout submissions
-- DELETE FROM submissions
-- WHERE quiz_id = :quiz_id AND status = 'timeout';
