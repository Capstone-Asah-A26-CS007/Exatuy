package com.examora.dao;

import com.examora.model.Answer;
import com.examora.model.Submission;
import com.examora.util.DBUtil;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Submission Data Access Object - Handles database operations for submissions
 */
public class SubmissionDAO {

    /**
     * Create a new submission
     */
    public Submission create(Submission submission) throws SQLException {
        String sql = "INSERT INTO submissions (quiz_id, user_id, score, total_questions, correct_answers, started_at, submitted_at, time_spent, question_order, status, is_retake) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            stmt.setInt(1, submission.getQuizId());
            stmt.setInt(2, submission.getUserId());
            stmt.setDouble(3, submission.getScore());
            stmt.setInt(4, submission.getTotalQuestions());
            stmt.setInt(5, submission.getCorrectAnswers());
            stmt.setTimestamp(6, Timestamp.valueOf(submission.getStartedAt()));
            stmt.setTimestamp(7, submission.getSubmittedAt() != null ? Timestamp.valueOf(submission.getSubmittedAt()) : null);
            stmt.setInt(8, submission.getTimeSpent() != null ? submission.getTimeSpent() : 0);
            stmt.setString(9, submission.getQuestionOrder());
            stmt.setString(10, submission.getStatus());
            stmt.setBoolean(11, submission.getIsRetake() != null ? submission.getIsRetake() : false);

            int affectedRows = stmt.executeUpdate();

            if (affectedRows == 0) {
                throw new SQLException("Creating submission failed, no rows affected.");
            }

            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    submission.setId(generatedKeys.getInt(1));
                } else {
                    throw new SQLException("Creating submission failed, no ID obtained.");
                }
            }

            return submission;
        }
    }

    /**
     * Find submission by ID
     */
    public Submission findById(Integer id) throws SQLException {
        String sql = "SELECT s.*, u.name as user_name, u.tag as user_tag, q.title as quiz_title " +
                     "FROM submissions s " +
                     "LEFT JOIN users u ON s.user_id = u.id " +
                     "LEFT JOIN quiz q ON s.quiz_id = q.id " +
                     "WHERE s.id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToSubmission(rs);
                }
            }
        }
        return null;
    }

    /**
     * Find submission by user and quiz
     */
    public Submission findByUserAndQuiz(Integer userId, Integer quizId) throws SQLException {
        String sql = "SELECT s.*, u.name as user_name, u.tag as user_tag, q.title as quiz_title " +
                     "FROM submissions s " +
                     "LEFT JOIN users u ON s.user_id = u.id " +
                     "LEFT JOIN quiz q ON s.quiz_id = q.id " +
                     "WHERE s.user_id = ? AND s.quiz_id = ? " +
                     "ORDER BY CASE s.status WHEN 'in_progress' THEN 0 WHEN 'timeout' THEN 1 WHEN 'completed' THEN 2 ELSE 3 END, s.id DESC";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);
            stmt.setInt(2, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToSubmission(rs);
                }
            }
        }
        return null;
    }

    /**
     * Get all submissions for a quiz
     */
    public List<Submission> findByQuizId(Integer quizId) throws SQLException {
        String sql = "SELECT s.*, u.name as user_name, u.tag as user_tag, q.title as quiz_title " +
                     "FROM submissions s " +
                     "LEFT JOIN users u ON s.user_id = u.id " +
                     "LEFT JOIN quiz q ON s.quiz_id = q.id " +
                     "WHERE s.quiz_id = ? " +
                     "ORDER BY s.submitted_at DESC";
        List<Submission> submissions = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    submissions.add(mapResultSetToSubmission(rs));
                }
            }
        }
        return submissions;
    }

    /**
     * Get all submissions for a user
     */
    public List<Submission> findByUserId(Integer userId) throws SQLException {
        String sql = "SELECT s.*, u.name as user_name, u.tag as user_tag, q.title as quiz_title " +
                     "FROM submissions s " +
                     "LEFT JOIN users u ON s.user_id = u.id " +
                     "LEFT JOIN quiz q ON s.quiz_id = q.id " +
                     "WHERE s.user_id = ? " +
                     "ORDER BY s.submitted_at DESC";
        List<Submission> submissions = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    submissions.add(mapResultSetToSubmission(rs));
                }
            }
        }
        return submissions;
    }

    /**
     * Get all submissions
     */
    public List<Submission> findAll() throws SQLException {
        String sql = "SELECT s.*, u.name as user_name, u.tag as user_tag, q.title as quiz_title " +
                     "FROM submissions s " +
                     "LEFT JOIN users u ON s.user_id = u.id " +
                     "LEFT JOIN quiz q ON s.quiz_id = q.id " +
                     "ORDER BY s.submitted_at DESC";
        List<Submission> submissions = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                submissions.add(mapResultSetToSubmission(rs));
            }
        }
        return submissions;
    }

    /**
     * Update submission (for completing)
     */
    public boolean update(Submission submission) throws SQLException {
        String sql = "UPDATE submissions SET score = ?, total_questions = ?, correct_answers = ?, submitted_at = ?, time_spent = ?, status = ? WHERE id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setDouble(1, submission.getScore());
            stmt.setInt(2, submission.getTotalQuestions());
            stmt.setInt(3, submission.getCorrectAnswers());
            stmt.setTimestamp(4, submission.getSubmittedAt() != null ? Timestamp.valueOf(submission.getSubmittedAt()) : null);
            stmt.setInt(5, submission.getTimeSpent() != null ? submission.getTimeSpent() : 0);
            stmt.setString(6, submission.getStatus());
            stmt.setInt(7, submission.getId());

            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Save an answer
     */
    public boolean saveAnswer(Answer answer) throws SQLException {
        String sql = "INSERT INTO answers (submission_id, question_id, selected_answer, is_correct) VALUES (?, ?, ?, ?) " +
                     "ON DUPLICATE KEY UPDATE selected_answer = VALUES(selected_answer), is_correct = VALUES(is_correct)";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, answer.getSubmissionId());
            stmt.setInt(2, answer.getQuestionId());
            stmt.setString(3, answer.getSelectedAnswer());
            stmt.setBoolean(4, answer.getIsCorrect());

            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Get answers for a submission
     */
    public List<Answer> getAnswers(Integer submissionId) throws SQLException {
        String sql = "SELECT a.*, q.question_text, q.image_path, q.correct_answer, " +
                     "q.option_a, q.option_b, q.option_c, q.option_d, q.explanation " +
                     "FROM answers a " +
                     "LEFT JOIN questions q ON a.question_id = q.id " +
                     "WHERE a.submission_id = ?";
        List<Answer> answers = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, submissionId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Answer answer = new Answer();
                    answer.setId(rs.getInt("id"));
                    answer.setSubmissionId(rs.getInt("submission_id"));
                    answer.setQuestionId(rs.getInt("question_id"));
                    answer.setSelectedAnswer(rs.getString("selected_answer"));
                    answer.setIsCorrect(rs.getBoolean("is_correct"));
                    answer.setQuestionText(rs.getString("question_text"));
                    answer.setImagePath(rs.getString("image_path"));
                    answer.setCorrectAnswer(rs.getString("correct_answer"));
                    answer.setOptionA(rs.getString("option_a"));
                    answer.setOptionB(rs.getString("option_b"));
                    answer.setOptionC(rs.getString("option_c"));
                    answer.setOptionD(rs.getString("option_d"));
                    answer.setExplanation(rs.getString("explanation"));

                    Timestamp answeredAt = rs.getTimestamp("answered_at");
                    if (answeredAt != null) {
                        answer.setAnsweredAt(answeredAt.toLocalDateTime());
                    }

                    answers.add(answer);
                }
            }
        }
        return answers;
    }

    /**
     * Get only the selected_answer for a specific question in a submission.
     * Does NOT join questions table, so correct_answer is never loaded into memory.
     */
    public String getSavedAnswerForQuestion(Integer submissionId, Integer questionId) throws SQLException {
        String sql = "SELECT selected_answer FROM answers WHERE submission_id = ? AND question_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, submissionId);
            stmt.setInt(2, questionId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("selected_answer");
                }
            }
        }
        return null;
    }

    /**
     * Get submission statistics for a quiz
     */
    public Map<String, Object> getStatistics(Integer quizId) throws SQLException {
        Map<String, Object> stats = new HashMap<>();

        // Initialize default values
        stats.put("totalSubmissions", 0);
        stats.put("averageScore", 0.0);
        stats.put("highestScore", 0.0);
        stats.put("lowestScore", 0.0);
        stats.put("averageTimeSpent", 0);
        stats.put("minTimeSpent", 0);
        stats.put("maxTimeSpent", 0);
        stats.put("timeoutCount", 0);
        stats.put("notTakenCount", 0);

        // Get quiz info first to determine target users
        String quizInfoSql = "SELECT title, target_tag, duration FROM quiz WHERE id = ?";
        String targetTag = null;
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(quizInfoSql)) {
            stmt.setInt(1, quizId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    targetTag = rs.getString("target_tag");
                }
            }
        }

        // Count total expected users based on target tag
        int totalExpectedUsers = 0;
        String expectedUsersSql;
        if (targetTag != null && !targetTag.isEmpty()) {
            // Count users with specific tag
            expectedUsersSql = "SELECT COUNT(*) FROM users WHERE tag = ? AND role = 'peserta'";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(expectedUsersSql)) {
                stmt.setString(1, targetTag);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        totalExpectedUsers = rs.getInt(1);
                    }
                }
            }
        } else {
            // Count all peserta users
            expectedUsersSql = "SELECT COUNT(*) FROM users WHERE role = 'peserta'";
            try (Connection conn = DBUtil.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(expectedUsersSql)) {
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        totalExpectedUsers = rs.getInt(1);
                    }
                }
            }
        }

        // Basic statistics for completed submissions only
        String basicSql = "SELECT COUNT(*) as total, AVG(score) as avg_score, MAX(score) as max_score, MIN(score) as min_score, " +
                          "AVG(time_spent) as avg_time, MIN(time_spent) as min_time, MAX(time_spent) as max_time " +
                          "FROM submissions WHERE quiz_id = ? AND status = 'completed'";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(basicSql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    stats.put("totalSubmissions", rs.getInt("total"));
                    stats.put("averageScore", rs.getDouble("avg_score"));
                    stats.put("highestScore", rs.getDouble("max_score"));
                    stats.put("lowestScore", rs.getDouble("min_score"));
                    stats.put("averageTimeSpent", rs.getInt("avg_time"));
                    stats.put("minTimeSpent", rs.getInt("min_time"));
                    stats.put("maxTimeSpent", rs.getInt("max_time"));
                }
            }
        }

        // Get timeout count
        String timeoutSql = "SELECT COUNT(*) as timeout_count FROM submissions WHERE quiz_id = ? AND status = 'timeout'";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(timeoutSql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    stats.put("timeoutCount", rs.getInt("timeout_count"));
                }
            }
        }

        // Calculate not taken count
        int completedCount = (Integer) stats.get("totalSubmissions");
        int timeoutCount = (Integer) stats.get("timeoutCount");
        int notTakenCount = Math.max(0, totalExpectedUsers - completedCount - timeoutCount);
        stats.put("notTakenCount", notTakenCount);
        stats.put("totalExpectedUsers", totalExpectedUsers);

        // Score distribution - initialize defaults
        stats.put("scoreRange0_40", 0);
        stats.put("scoreRange41_60", 0);
        stats.put("scoreRange61_75", 0);
        stats.put("scoreRange76_85", 0);
        stats.put("scoreRange86_100", 0);
        stats.put("passedCount", 0);
        stats.put("failedCount", 0);
        stats.put("passRate", 0.0);

        // Score distribution for completed submissions
        String distSql = "SELECT " +
                         "SUM(CASE WHEN score BETWEEN 0 AND 40 THEN 1 ELSE 0 END) as range_0_40, " +
                         "SUM(CASE WHEN score BETWEEN 41 AND 60 THEN 1 ELSE 0 END) as range_41_60, " +
                         "SUM(CASE WHEN score BETWEEN 61 AND 75 THEN 1 ELSE 0 END) as range_61_75, " +
                         "SUM(CASE WHEN score BETWEEN 76 AND 85 THEN 1 ELSE 0 END) as range_76_85, " +
                         "SUM(CASE WHEN score BETWEEN 86 AND 100 THEN 1 ELSE 0 END) as range_86_100, " +
                         "SUM(CASE WHEN score >= 60 THEN 1 ELSE 0 END) as passed, " +
                         "SUM(CASE WHEN score < 60 THEN 1 ELSE 0 END) as failed " +
                         "FROM submissions WHERE quiz_id = ? AND status = 'completed'";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(distSql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    int passed = rs.getInt("passed");
                    int failed = rs.getInt("failed");

                    stats.put("scoreRange0_40", rs.getInt("range_0_40"));
                    stats.put("scoreRange41_60", rs.getInt("range_41_60"));
                    stats.put("scoreRange61_75", rs.getInt("range_61_75"));
                    stats.put("scoreRange76_85", rs.getInt("range_76_85"));
                    stats.put("scoreRange86_100", rs.getInt("range_86_100"));
                    stats.put("passedCount", passed);
                    // Include timeout and not taken in failed count
                    stats.put("failedCount", failed + timeoutCount + notTakenCount);

                    // Calculate pass rate (passed / total expected users)
                    double passRate = (totalExpectedUsers > 0) ? (passed * 100.0 / totalExpectedUsers) : 0;
                    stats.put("passRate", passRate);
                }
            }
        }

        return stats;
    }

    /**
     * Count submissions by quiz
     */
    public int countByQuizId(Integer quizId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM submissions WHERE quiz_id = ? AND status = 'completed'";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    /**
     * Check if user has already submitted a quiz
     */
    public boolean hasSubmitted(Integer userId, Integer quizId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM submissions WHERE user_id = ? AND quiz_id = ? AND status IN ('completed', 'timeout')";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);
            stmt.setInt(2, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        }
        return false;
    }

    /**
     * Get detailed submissions with answers for a quiz
     * Returns list of maps containing submission info and user details
     */
    public List<Map<String, Object>> getDetailedSubmissionsByQuiz(Integer quizId) throws SQLException {
        String sql = "SELECT s.*, u.name as user_name, u.email as user_email, u.tag as user_tag, q.title as quiz_title, " +
                     "(SELECT COUNT(*) FROM answers a WHERE a.submission_id = s.id) as answered_count " +
                     "FROM submissions s " +
                     "LEFT JOIN users u ON s.user_id = u.id " +
                     "LEFT JOIN quiz q ON s.quiz_id = q.id " +
                     "WHERE s.quiz_id = ? AND s.status = 'completed' " +
                     "ORDER BY s.score DESC, s.time_spent ASC";
        List<Map<String, Object>> detailedSubmissions = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                int rank = 1;
                while (rs.next()) {
                    Map<String, Object> detail = new HashMap<>();
                    detail.put("id", rs.getInt("id"));
                    detail.put("quizId", rs.getInt("quiz_id"));
                    detail.put("userId", rs.getInt("user_id"));
                    detail.put("score", rs.getDouble("score"));
                    detail.put("totalQuestions", rs.getInt("total_questions"));
                    detail.put("correctAnswers", rs.getInt("correct_answers"));
                    detail.put("timeSpent", rs.getInt("time_spent"));
                    detail.put("status", rs.getString("status"));
                    detail.put("userName", rs.getString("user_name"));
                    detail.put("userEmail", rs.getString("user_email"));
                    detail.put("userTag", rs.getString("user_tag"));
                    detail.put("quizTitle", rs.getString("quiz_title"));
                    detail.put("rank", rank++);

                    Timestamp submittedAt = rs.getTimestamp("submitted_at");
                    if (submittedAt != null) {
                        detail.put("submittedAt", submittedAt.toLocalDateTime());
                    }

                    // Calculate unanswered and wrong questions correctly
                    int totalQuestions = rs.getInt("total_questions");
                    int correctAnswers = rs.getInt("correct_answers");
                    int answeredCount = rs.getInt("answered_count");

                    // Unanswered = total - answered
                    int unanswered = totalQuestions - answeredCount;
                    // Wrong = answered - correct
                    int wrongCount = answeredCount - correctAnswers;

                    detail.put("unanswered", unanswered);
                    detail.put("wrongCount", wrongCount);

                    detailedSubmissions.add(detail);
                }
            }
        }
        return detailedSubmissions;
    }

    /**
     * Get submission with all questions and answers for detailed view
     */
    public Map<String, Object> getSubmissionDetailWithAnswers(Integer submissionId) throws SQLException {
        Map<String, Object> result = new HashMap<>();

        // Get submission info
        Submission submission = findById(submissionId);
        if (submission == null) {
            return null;
        }

        result.put("submission", submission);

        // Get all questions for this quiz with user's answers
        String sql = "SELECT q.id, q.question_text, q.image_path, q.option_a, q.option_b, q.option_c, q.option_d, " +
                     "q.correct_answer, q.question_order, a.selected_answer, a.is_correct " +
                     "FROM questions q " +
                     "LEFT JOIN answers a ON q.id = a.question_id AND a.submission_id = ? " +
                     "WHERE q.quiz_id = ? " +
                     "ORDER BY q.question_order, q.id";

        List<Map<String, Object>> questionsWithAnswers = new ArrayList<>();
        int correctCount = 0;
        int wrongCount = 0;
        int unansweredCount = 0;

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, submissionId);
            stmt.setInt(2, submission.getQuizId());

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> qa = new HashMap<>();
                    qa.put("questionId", rs.getInt("id"));
                    qa.put("questionText", rs.getString("question_text"));
                    qa.put("imagePath", rs.getString("image_path"));
                    qa.put("optionA", rs.getString("option_a"));
                    qa.put("optionB", rs.getString("option_b"));
                    qa.put("optionC", rs.getString("option_c"));
                    qa.put("optionD", rs.getString("option_d"));
                    qa.put("correctAnswer", rs.getString("correct_answer"));
                    qa.put("questionOrder", rs.getInt("question_order"));

                    String selectedAnswer = rs.getString("selected_answer");
                    Boolean isCorrect = rs.getBoolean("is_correct");

                    qa.put("selectedAnswer", selectedAnswer);
                    qa.put("isCorrect", isCorrect);
                    qa.put("answered", selectedAnswer != null);

                    if (selectedAnswer == null) {
                        unansweredCount++;
                    } else if (isCorrect != null && isCorrect) {
                        correctCount++;
                    } else {
                        wrongCount++;
                    }

                    questionsWithAnswers.add(qa);
                }
            }
        }

        result.put("questions", questionsWithAnswers);
        result.put("correctCount", correctCount);
        result.put("wrongCount", wrongCount);
        result.put("unansweredCount", unansweredCount);

        return result;
    }

    /**
     * Get unanswered count for a submission (actual count from answers table)
     */
    public int getAnsweredCount(Integer submissionId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM answers WHERE submission_id = ?";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, submissionId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    /**
     * Save question order for a submission
     */
    public void saveQuestionOrder(Integer submissionId, String questionOrder) throws SQLException {
        String sql = "UPDATE submissions SET question_order = ? WHERE id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, questionOrder);
            stmt.setInt(2, submissionId);
            stmt.executeUpdate();
        }
    }

    /**
     * Map ResultSet to Submission object
     */
    private Submission mapResultSetToSubmission(ResultSet rs) throws SQLException {
        Submission submission = new Submission();
        submission.setId(rs.getInt("id"));
        submission.setQuizId(rs.getInt("quiz_id"));
        submission.setUserId(rs.getInt("user_id"));
        submission.setScore(rs.getDouble("score"));
        submission.setTotalQuestions(rs.getInt("total_questions"));
        submission.setCorrectAnswers(rs.getInt("correct_answers"));

        Timestamp startedAt = rs.getTimestamp("started_at");
        if (startedAt != null) {
            submission.setStartedAt(startedAt.toLocalDateTime());
        }

        Timestamp submittedAt = rs.getTimestamp("submitted_at");
        if (submittedAt != null) {
            submission.setSubmittedAt(submittedAt.toLocalDateTime());
        }

        submission.setTimeSpent(rs.getInt("time_spent"));
        submission.setQuestionOrder(rs.getString("question_order"));
        submission.setStatus(rs.getString("status"));
        submission.setIsRetake(rs.getBoolean("is_retake"));
        submission.setUserName(rs.getString("user_name"));
        submission.setUserTag(rs.getString("user_tag"));
        submission.setQuizTitle(rs.getString("quiz_title"));

        submission.setAccumulatedPauseSeconds(rs.getInt("accumulated_pause_seconds"));
        Timestamp lastActivityAt = rs.getTimestamp("last_activity_at");
        if (lastActivityAt != null) {
            submission.setLastActivityAt(lastActivityAt.toLocalDateTime());
        }

        return submission;
    }

    /**
     * Count completed submissions by user
     */
    public int countCompletedByUserId(Integer userId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM submissions WHERE user_id = ? AND status = 'completed'";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    /**
     * Count perfect scores by user
     */
    public int countPerfectScoresByUserId(Integer userId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM submissions WHERE user_id = ? AND score = 100 AND status = 'completed'";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, userId);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    /**
     * Delete all answers
     */
    public int deleteAllAnswers() throws SQLException {
        String sql = "DELETE FROM answers";

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement()) {
            return stmt.executeUpdate(sql);
        }
    }

    /**
     * Delete all submissions
     */
    public int deleteAllSubmissions() throws SQLException {
        String sql = "DELETE FROM submissions";

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement()) {
            return stmt.executeUpdate(sql);
        }
    }

    /**
     * Count all submissions
     */
    public int countAll() throws SQLException {
        String sql = "SELECT COUNT(*) FROM submissions";

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        }
        return 0;
    }

    /**
     * Count all answers
     */
    public int countAllAnswers() throws SQLException {
        String sql = "SELECT COUNT(*) FROM answers";

        try (Connection conn = DBUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        }
        return 0;
    }

    /**
     * Delete submission by ID (for retake)
     * Also deletes associated answers
     */
    public boolean deleteSubmission(Integer submissionId) throws SQLException {
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // First delete all answers for this submission
            String deleteAnswersSql = "DELETE FROM answers WHERE submission_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(deleteAnswersSql)) {
                stmt.setInt(1, submissionId);
                stmt.executeUpdate();
            }

            // Then delete the submission
            String deleteSubmissionSql = "DELETE FROM submissions WHERE id = ?";
            int result = 0;
            try (PreparedStatement stmt = conn.prepareStatement(deleteSubmissionSql)) {
                stmt.setInt(1, submissionId);
                result = stmt.executeUpdate();
            }

            conn.commit();
            return result > 0;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { }
            }
            throw e;
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException e) { }
            }
        }
    }

    /**
     * Delete submission by user and quiz (for retake)
     */
    public boolean deleteByUserAndQuiz(Integer userId, Integer quizId) throws SQLException {
        // Get submission ID first
        Submission submission = findByUserAndQuiz(userId, quizId);
        if (submission == null) {
            return false;
        }
        return deleteSubmission(submission.getId());
    }

    /**
     * Batch delete submissions for retake
     */
    public int batchDeleteForRetake(List<Integer> submissionIds) throws SQLException {
        int deletedCount = 0;
        for (Integer submissionId : submissionIds) {
            if (deleteSubmission(submissionId)) {
                deletedCount++;
            }
        }
        return deletedCount;
    }

    /**
     * Find submissions by quiz and status
     */
    public List<Submission> findByQuizAndStatus(Integer quizId, String status) throws SQLException {
        String sql = "SELECT s.*, u.name as user_name, u.email as user_email, u.tag as user_tag, q.title as quiz_title " +
                     "FROM submissions s " +
                     "LEFT JOIN users u ON s.user_id = u.id " +
                     "LEFT JOIN quiz q ON s.quiz_id = q.id " +
                     "WHERE s.quiz_id = ? AND s.status = ? " +
                     "ORDER BY s.submitted_at DESC";
        List<Submission> submissions = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);
            stmt.setString(2, status);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Submission submission = mapResultSetToSubmission(rs);
                    submissions.add(submission);
                }
            }
        }
        return submissions;
    }

    /**
     * Delete all timeout submissions for a quiz (allows retake)
     * Returns number of submissions deleted
     */
    public int deleteTimeoutSubmissions(Integer quizId) throws SQLException {
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // First delete all answers for timeout submissions
            String deleteAnswersSql = "DELETE a FROM answers a " +
                                      "INNER JOIN submissions s ON a.submission_id = s.id " +
                                      "WHERE s.quiz_id = ? AND s.status = 'timeout'";
            try (PreparedStatement stmt = conn.prepareStatement(deleteAnswersSql)) {
                stmt.setInt(1, quizId);
                stmt.executeUpdate();
            }

            // Then delete the timeout submissions
            String deleteSubmissionsSql = "DELETE FROM submissions WHERE quiz_id = ? AND status = 'timeout'";
            int result = 0;
            try (PreparedStatement stmt = conn.prepareStatement(deleteSubmissionsSql)) {
                stmt.setInt(1, quizId);
                result = stmt.executeUpdate();
            }

            conn.commit();
            return result;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { }
            }
            throw e;
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException e) { }
            }
        }
    }

    /**
     * Delete specific timeout submission for retake
     */
    public boolean deleteTimeoutSubmission(Integer submissionId, Integer quizId) throws SQLException {
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // Verify it's a timeout submission for this quiz
            String checkSql = "SELECT id FROM submissions WHERE id = ? AND quiz_id = ? AND status = 'timeout'";
            try (PreparedStatement stmt = conn.prepareStatement(checkSql)) {
                stmt.setInt(1, submissionId);
                stmt.setInt(2, quizId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        return false; // Not a timeout submission or wrong quiz
                    }
                }
            }

            // Delete answers
            String deleteAnswersSql = "DELETE FROM answers WHERE submission_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(deleteAnswersSql)) {
                stmt.setInt(1, submissionId);
                stmt.executeUpdate();
            }

            // Delete submission
            String deleteSubmissionSql = "DELETE FROM submissions WHERE id = ?";
            int result = 0;
            try (PreparedStatement stmt = conn.prepareStatement(deleteSubmissionSql)) {
                stmt.setInt(1, submissionId);
                result = stmt.executeUpdate();
            }

            conn.commit();
            return result > 0;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { }
            }
            throw e;
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException e) { }
            }
        }
    }

    /**
     * Delete specific submission by ID (allows retake for any submission)
     * This deletes both completed and timeout submissions
     */
    public boolean deleteSubmissionById(Integer submissionId, Integer quizId) throws SQLException {
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // Verify it's a submission for this quiz
            String checkSql = "SELECT id FROM submissions WHERE id = ? AND quiz_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(checkSql)) {
                stmt.setInt(1, submissionId);
                stmt.setInt(2, quizId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        return false; // Submission not found or wrong quiz
                    }
                }
            }

            // First delete all answers for this submission
            String deleteAnswersSql = "DELETE FROM answers WHERE submission_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(deleteAnswersSql)) {
                stmt.setInt(1, submissionId);
                stmt.executeUpdate();
            }

            // Delete submission
            String deleteSubmissionSql = "DELETE FROM submissions WHERE id = ?";
            int result = 0;
            try (PreparedStatement stmt = conn.prepareStatement(deleteSubmissionSql)) {
                stmt.setInt(1, submissionId);
                result = stmt.executeUpdate();
            }

            conn.commit();
            return result > 0;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { }
            }
            throw e;
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException e) { }
            }
        }
    }

    /**
     * Get status counts for a quiz (completed, timeout, in_progress)
     */
    public Map<String, Integer> getStatusCounts(Integer quizId) throws SQLException {
        String sql = "SELECT status, COUNT(*) as count FROM submissions WHERE quiz_id = ? GROUP BY status";
        Map<String, Integer> counts = new HashMap<>();
        counts.put("completed", 0);
        counts.put("timeout", 0);
        counts.put("in_progress", 0);

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    String status = rs.getString("status");
                    int count = rs.getInt("count");
                    if (counts.containsKey(status)) {
                        counts.put(status, count);
                    }
                }
            }
        }
        return counts;
    }

    /**
     * Get all submissions for a quiz (all statuses) with user details
     */
    public List<Map<String, Object>> getAllSubmissionsByQuiz(Integer quizId) throws SQLException {
        String sql = "SELECT s.*, u.name as user_name, u.email as user_email, u.tag as user_tag, q.title as quiz_title, " +
                     "(SELECT COUNT(*) FROM answers a WHERE a.submission_id = s.id) as answered_count " +
                     "FROM submissions s " +
                     "LEFT JOIN users u ON s.user_id = u.id " +
                     "LEFT JOIN quiz q ON s.quiz_id = q.id " +
                     "WHERE s.quiz_id = ? " +
                     "ORDER BY " +
                     "CASE s.status " +
                     "  WHEN 'in_progress' THEN 1 " +
                     "  WHEN 'timeout' THEN 2 " +
                     "  WHEN 'completed' THEN 3 " +
                     "END, " +
                     "s.score DESC, s.submitted_at DESC";
        List<Map<String, Object>> detailedSubmissions = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, quizId);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> detail = new HashMap<>();
                    detail.put("id", rs.getInt("id"));
                    detail.put("quizId", rs.getInt("quiz_id"));
                    detail.put("userId", rs.getInt("user_id"));
                    detail.put("score", rs.getDouble("score"));
                    detail.put("totalQuestions", rs.getInt("total_questions"));
                    detail.put("correctAnswers", rs.getInt("correct_answers"));
                    detail.put("timeSpent", rs.getInt("time_spent"));
                    detail.put("status", rs.getString("status"));
                    detail.put("userName", rs.getString("user_name"));
                    detail.put("userEmail", rs.getString("user_email"));
                    detail.put("userTag", rs.getString("user_tag"));
                    detail.put("quizTitle", rs.getString("quiz_title"));
                    detail.put("answeredCount", rs.getInt("answered_count"));

                    Timestamp startedAt = rs.getTimestamp("started_at");
                    if (startedAt != null) {
                        detail.put("startedAt", startedAt.toLocalDateTime());
                    }

                    Timestamp submittedAt = rs.getTimestamp("submitted_at");
                    if (submittedAt != null) {
                        detail.put("submittedAt", submittedAt.toLocalDateTime());
                    }

                    // Calculate unanswered and wrong questions
                    int totalQuestions = rs.getInt("total_questions");
                    int correctAnswers = rs.getInt("correct_answers");
                    int answeredCount = rs.getInt("answered_count");
                    int unanswered = totalQuestions - answeredCount;
                    int wrongCount = answeredCount - correctAnswers;

                    detail.put("unanswered", unanswered);
                    detail.put("wrongCount", wrongCount);

                    detailedSubmissions.add(detail);
                }
            }
        }
        return detailedSubmissions;
    }

    /**
     * Get users who haven't taken the quiz yet
     */
    public List<Map<String, Object>> getUsersNotTakenQuiz(Integer quizId, String targetTag) throws SQLException {
        List<Map<String, Object>> users = new ArrayList<>();

        StringBuilder sql = new StringBuilder(
            "SELECT u.id, u.name, u.email, u.tag, q.title as quiz_title " +
            "FROM users u " +
            "LEFT JOIN quiz q ON q.id = ? " +
            "WHERE u.role = 'peserta' " +
            "AND u.id NOT IN (SELECT s.user_id FROM submissions s WHERE s.quiz_id = ?) "
        );

        if (targetTag != null && !targetTag.isEmpty()) {
            // Handle multiple tags separated by comma
            String[] tags = targetTag.split(",");
            sql.append("AND u.tag IN (");
            for (int i = 0; i < tags.length; i++) {
                if (i > 0) sql.append(",");
                sql.append("?");
            }
            sql.append(") ");
        }

        sql.append("ORDER BY u.name");

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {

            int paramIndex = 1;
            stmt.setInt(paramIndex++, quizId);
            stmt.setInt(paramIndex++, quizId);

            if (targetTag != null && !targetTag.isEmpty()) {
                String[] tags = targetTag.split(",");
                for (String tag : tags) {
                    stmt.setString(paramIndex++, tag.trim());
                }
            }

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> user = new HashMap<>();
                    user.put("userId", rs.getInt("id"));
                    user.put("userName", rs.getString("name"));
                    user.put("userEmail", rs.getString("email"));
                    user.put("userTag", rs.getString("tag"));
                    user.put("quizTitle", rs.getString("quiz_title"));
                    user.put("status", "not_taken");
                    users.add(user);
                }
            }
        }
        return users;
    }

    /**
     * Get quiz target tag
     */
    public String getQuizTargetTag(Integer quizId) throws SQLException {
        String sql = "SELECT target_tag FROM quiz WHERE id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, quizId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("target_tag");
                }
            }
        }
        return null;
    }

    /**
     * Re-grade all submissions for a quiz based on current correct answers.
     * 1. Update is_correct for all answers by comparing selected_answer with question's correct_answer
     * 2. Recalculate score, correct_answers, total_questions for each submission
     * Returns number of submissions updated.
     */
    public int regradeSubmissionsForQuiz(Integer quizId) throws SQLException {
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // Step 1: Update is_correct for all answers for this quiz
            String updateAnswersSql = "UPDATE answers a " +
                    "INNER JOIN questions q ON a.question_id = q.id " +
                    "INNER JOIN submissions s ON a.submission_id = s.id " +
                    "SET a.is_correct = (a.selected_answer = q.correct_answer) " +
                    "WHERE s.quiz_id = ? AND s.status IN ('completed', 'timeout')";
            try (PreparedStatement stmt = conn.prepareStatement(updateAnswersSql)) {
                stmt.setInt(1, quizId);
                stmt.executeUpdate();
            }

            // Step 2: Get total questions count for this quiz
            int totalQuestions = 0;
            String countSql = "SELECT COUNT(*) FROM questions WHERE quiz_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(countSql)) {
                stmt.setInt(1, quizId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        totalQuestions = rs.getInt(1);
                    }
                }
            }

            // Step 3: Recalculate score and correct_answers for each submission
            // Build updated values using a subquery
            String updateSubmissionsSql = "UPDATE submissions s SET " +
                    "s.correct_answers = (" +
                    "  SELECT COUNT(*) FROM answers a " +
                    "  INNER JOIN questions q ON a.question_id = q.id " +
                    "  WHERE a.submission_id = s.id AND a.is_correct = 1" +
                    "), " +
                    "s.total_questions = ?, " +
                    "s.score = ROUND((" +
                    "  SELECT COUNT(*) FROM answers a " +
                    "  INNER JOIN questions q ON a.question_id = q.id " +
                    "  WHERE a.submission_id = s.id AND a.is_correct = 1" +
                    ") * 100.0 / ? , 2) " +
                    "WHERE s.quiz_id = ? AND s.status IN ('completed', 'timeout')";

            int updatedCount;
            try (PreparedStatement stmt = conn.prepareStatement(updateSubmissionsSql)) {
                stmt.setInt(1, totalQuestions);
                stmt.setInt(2, totalQuestions > 0 ? totalQuestions : 1); // avoid division by zero
                stmt.setInt(3, quizId);
                updatedCount = stmt.executeUpdate();
            }

            conn.commit();
            return updatedCount;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { }
            }
            throw e;
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException e) { }
            }
        }
    }

    /**
     * Get scores for building a transcript matrix.
     * Joins submissions + users + quiz. Filters: optional set of quizIds,
     * optional user tag filter, optional specific userId filter.
     * Only completed/timeout submissions are returned.
     *
     * Each row contains: userId, userName, userEmail, userTag, quizId, quizTitle, score, status, submittedAt.
     */
    public List<Map<String, Object>> getTranscriptScores(List<Integer> quizIds, String tagFilter, Integer userIdFilter) throws SQLException {
        // LEFT JOIN from users so that peserta who never took any quiz (or none
        // of the selected quizzes) still appear in the transcript/export with
        // NULL score columns. Only completed/timeout submissions are joined;
        // quizIds filter is part of the join condition so it doesn't drop users.
        StringBuilder sql = new StringBuilder(
            "SELECT u.id AS user_id, u.name AS user_name, u.email AS user_email, u.tag AS user_tag, " +
            "s.quiz_id, q.title AS quiz_title, s.score, s.status, s.submitted_at " +
            "FROM users u " +
            "LEFT JOIN submissions s ON s.user_id = u.id " +
                "AND s.status IN ('completed','timeout') "
        );

        List<Object> params = new ArrayList<>();

        if (quizIds != null && !quizIds.isEmpty()) {
            sql.append("AND s.quiz_id IN (");
            for (int i = 0; i < quizIds.size(); i++) {
                if (i > 0) sql.append(",");
                sql.append("?");
                params.add(quizIds.get(i));
            }
            sql.append(") ");
        }

        sql.append("LEFT JOIN quiz q ON q.id = s.quiz_id ");
        sql.append("WHERE u.role = 'peserta' ");

        if (tagFilter != null && !tagFilter.trim().isEmpty()) {
            sql.append("AND u.tag = ? ");
            params.add(tagFilter.trim());
        }

        if (userIdFilter != null) {
            sql.append("AND u.id = ? ");
            params.add(userIdFilter);
        }

        sql.append("ORDER BY u.name ASC, u.id ASC, q.title ASC, s.submitted_at DESC");

        List<Map<String, Object>> rows = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {

            for (int i = 0; i < params.size(); i++) {
                Object p = params.get(i);
                if (p instanceof Integer) {
                    stmt.setInt(i + 1, (Integer) p);
                } else {
                    stmt.setString(i + 1, (String) p);
                }
            }

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("userId", rs.getInt("user_id"));
                    row.put("userName", rs.getString("user_name"));
                    row.put("userEmail", rs.getString("user_email"));
                    row.put("userTag", rs.getString("user_tag"));

                    // For LEFT JOIN misses (peserta with no matching submission),
                    // quiz_id/score/etc will be NULL — keep them null so the
                    // caller can distinguish "no attempt" from "score 0".
                    int quizId = rs.getInt("quiz_id");
                    if (rs.wasNull()) {
                        row.put("quizId", null);
                        row.put("quizTitle", null);
                        row.put("score", null);
                        row.put("status", null);
                        row.put("submittedAt", null);
                    } else {
                        row.put("quizId", quizId);
                        row.put("quizTitle", rs.getString("quiz_title"));
                        row.put("score", rs.getDouble("score"));
                        row.put("status", rs.getString("status"));
                        Timestamp submittedAt = rs.getTimestamp("submitted_at");
                        if (submittedAt != null) {
                            row.put("submittedAt", submittedAt.toLocalDateTime());
                        }
                    }

                    rows.add(row);
                }
            }
        }
        return rows;
    }

    /**
     * Update the is_correct flag for a single answer (submission + question pair).
     * Returns the previous is_correct value for audit, or null if the answer was not found.
     * Transactional with rollback on error.
     */
    public Boolean updateAnswerCorrectness(Integer submissionId, Integer questionId, boolean isCorrect) throws SQLException {
        Connection conn = null;
        Boolean oldValue = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // Step 1: Read the old value for audit
            String selectSql = "SELECT is_correct FROM answers WHERE submission_id = ? AND question_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(selectSql)) {
                stmt.setInt(1, submissionId);
                stmt.setInt(2, questionId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        oldValue = rs.getBoolean("is_correct");
                    } else {
                        // Answer not found (e.g. user did not answer this question)
                        conn.rollback();
                        return null;
                    }
                }
            }

            // Step 2: Apply the update
            String updateSql = "UPDATE answers SET is_correct = ? WHERE submission_id = ? AND question_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(updateSql)) {
                stmt.setBoolean(1, isCorrect);
                stmt.setInt(2, submissionId);
                stmt.setInt(3, questionId);
                stmt.executeUpdate();
            }

            conn.commit();
            return oldValue;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { }
            }
            throw e;
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException e) { }
            }
        }
    }

    /**
     * Recalculate score and correct_answers for a submission based on the current
     * set of is_correct values in the answers table.
     * Returns a Map with: oldScore, oldCorrectAnswers, newScore, newCorrectAnswers, totalQuestions.
     */
    public Map<String, Object> recalculateSubmissionScore(Integer submissionId) throws SQLException {
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false);

            // Step 1: Read current submission totals
            double oldScore = 0.0;
            int oldCorrect = 0;
            int totalQuestions = 0;
            String selectSql = "SELECT total_questions, score, correct_answers FROM submissions WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(selectSql)) {
                stmt.setInt(1, submissionId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        totalQuestions = rs.getInt("total_questions");
                        oldScore = rs.getDouble("score");
                        oldCorrect = rs.getInt("correct_answers");
                    } else {
                        conn.rollback();
                        return null;
                    }
                }
            }

            // Step 2: Count currently-correct answers
            int correctCount = 0;
            String countSql = "SELECT COUNT(*) FROM answers WHERE submission_id = ? AND is_correct = 1";
            try (PreparedStatement stmt = conn.prepareStatement(countSql)) {
                stmt.setInt(1, submissionId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        correctCount = rs.getInt(1);
                    }
                }
            }

            // Step 3: Recalculate score with the same formula used in submitQuiz / regrade
            int divisor = totalQuestions > 0 ? totalQuestions : 1;
            double newScore = Math.round(correctCount * 100.0 / divisor * 100.0) / 100.0;

            // Step 4: Persist
            String updateSql = "UPDATE submissions SET score = ?, correct_answers = ? WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(updateSql)) {
                stmt.setDouble(1, newScore);
                stmt.setInt(2, correctCount);
                stmt.setInt(3, submissionId);
                stmt.executeUpdate();
            }

            conn.commit();

            Map<String, Object> result = new HashMap<>();
            result.put("oldScore", oldScore);
            result.put("oldCorrectAnswers", oldCorrect);
            result.put("newScore", newScore);
            result.put("newCorrectAnswers", correctCount);
            result.put("totalQuestions", totalQuestions);
            return result;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { }
            }
            throw e;
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException e) { }
            }
        }
    }

    /**
     * Override the score for a submission without touching is_correct / correct_answers.
     * Returns true if the row was updated.
     */
    public boolean overrideScore(Integer submissionId, double newScore) throws SQLException {
        String sql = "UPDATE submissions SET score = ? WHERE id = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setDouble(1, newScore);
            stmt.setInt(2, submissionId);
            return stmt.executeUpdate() > 0;
        }
    }

    /**
     * Get all submissions that are eligible for inline score editing
     * (status completed or timeout). Optionally filter by quizId, user tag,
     * and/or a name/email search term.
     */
    public List<Map<String, Object>> getAllEditableSubmissions(Integer quizIdFilter, String tagFilter, String search) throws SQLException {
        StringBuilder sql = new StringBuilder(
            "SELECT s.id, s.quiz_id, s.user_id, s.score, s.total_questions, s.correct_answers, " +
            "s.submitted_at, s.time_spent, s.status, " +
            "u.name AS user_name, u.email AS user_email, u.tag AS user_tag, " +
            "q.title AS quiz_title " +
            "FROM submissions s " +
            "INNER JOIN users u ON s.user_id = u.id " +
            "INNER JOIN quiz q ON s.quiz_id = q.id " +
            "WHERE s.status IN ('completed','timeout') "
        );

        List<Object> params = new ArrayList<>();
        if (quizIdFilter != null) {
            sql.append("AND s.quiz_id = ? ");
            params.add(quizIdFilter);
        }
        if (tagFilter != null && !tagFilter.trim().isEmpty()) {
            sql.append("AND u.tag = ? ");
            params.add(tagFilter.trim());
        }
        if (search != null && !search.trim().isEmpty()) {
            sql.append("AND (u.name LIKE ? OR u.email LIKE ?) ");
            String like = "%" + search.trim() + "%";
            params.add(like);
            params.add(like);
        }
        sql.append("ORDER BY s.submitted_at DESC");

        List<Map<String, Object>> rows = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                Object p = params.get(i);
                if (p instanceof Integer) {
                    stmt.setInt(i + 1, (Integer) p);
                } else {
                    stmt.setString(i + 1, (String) p);
                }
            }

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("id", rs.getInt("id"));
                    row.put("quizId", rs.getInt("quiz_id"));
                    row.put("userId", rs.getInt("user_id"));
                    row.put("score", rs.getDouble("score"));
                    row.put("totalQuestions", rs.getInt("total_questions"));
                    row.put("correctAnswers", rs.getInt("correct_answers"));
                    row.put("timeSpent", rs.getInt("time_spent"));
                    row.put("status", rs.getString("status"));
                    row.put("userName", rs.getString("user_name"));
                    row.put("userEmail", rs.getString("user_email"));
                    row.put("userTag", rs.getString("user_tag"));
                    row.put("quizTitle", rs.getString("quiz_title"));

                    Timestamp submittedAt = rs.getTimestamp("submitted_at");
                    if (submittedAt != null) {
                        row.put("submittedAt", submittedAt.toLocalDateTime());
                    }

                    rows.add(row);
                }
            }
        }
        return rows;
    }

    /**
     * Update activity tracking for pause-aware timer.
     * If user was away for > threshold seconds, that gap is counted as pause time.
     * When last_activity_at is NULL (old submissions), falls back to started_at.
     */
    public void updateActivity(Integer submissionId, int pauseThresholdSeconds) throws SQLException {
        String selectSql = "SELECT started_at, last_activity_at, accumulated_pause_seconds FROM submissions WHERE id = ?";
        LocalDateTime now = LocalDateTime.now();

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement selectStmt = conn.prepareStatement(selectSql)) {

            selectStmt.setInt(1, submissionId);

            try (ResultSet rs = selectStmt.executeQuery()) {
                if (rs.next()) {
                    Timestamp lastActivity = rs.getTimestamp("last_activity_at");
                    Timestamp startedAt = rs.getTimestamp("started_at");
                    int currentPause = rs.getInt("accumulated_pause_seconds");

                    int additionalPause = 0;
                    // Determine reference point: last_activity_at if available, else started_at
                    LocalDateTime reference = null;
                    if (lastActivity != null) {
                        reference = lastActivity.toLocalDateTime();
                    } else if (startedAt != null) {
                        reference = startedAt.toLocalDateTime();
                    }

                    if (reference != null) {
                        long gapSeconds = java.time.Duration.between(reference, now).getSeconds();
                        if (gapSeconds > pauseThresholdSeconds) {
                            additionalPause = (int) (gapSeconds - pauseThresholdSeconds);
                        }
                    }

                    String updateSql = "UPDATE submissions SET last_activity_at = ?, accumulated_pause_seconds = ? WHERE id = ?";
                    try (PreparedStatement updateStmt = conn.prepareStatement(updateSql)) {
                        updateStmt.setTimestamp(1, Timestamp.valueOf(now));
                        updateStmt.setInt(2, currentPause + additionalPause);
                        updateStmt.setInt(3, submissionId);
                        updateStmt.executeUpdate();
                    }
                }
            }
        }
    }
}
