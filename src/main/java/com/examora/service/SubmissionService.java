package com.examora.service;

import com.examora.dao.QuestionDAO;
import com.examora.dao.QuizDAO;
import com.examora.dao.SubmissionDAO;
import com.examora.model.Answer;
import com.examora.model.Question;
import com.examora.model.Quiz;
import com.examora.model.Submission;
import com.examora.util.ValidationUtil;

import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.*;

/**
 * Submission Service - Business logic for quiz submissions
 */
public class SubmissionService {
    private SubmissionDAO submissionDAO;
    private QuizDAO quizDAO;
    private QuestionDAO questionDAO;
    private AchievementService achievementService;

    public SubmissionService() {
        this.submissionDAO = new SubmissionDAO();
        this.quizDAO = new QuizDAO();
        this.questionDAO = new QuestionDAO();
        this.achievementService = new AchievementService();
    }

    /**
     * Start a quiz (create submission)
     */
    public Submission startQuiz(Integer quizId, Integer userId) throws ServiceException {
        return startQuiz(quizId, userId, false);
    }

    /**
     * Start a quiz (create submission) with retake support
     */
    public Submission startQuiz(Integer quizId, Integer userId, boolean isRetake) throws ServiceException {
        try {
            // Check if quiz exists and is active
            Quiz quiz = quizDAO.findById(quizId);
            if (quiz == null) {
                throw new ServiceException("Quiz tidak ditemukan");
            }
            if (!quiz.getIsActive()) {
                throw new ServiceException("Quiz belum dipublish");
            }

            // Check if quiz has expired (past deadline) - skip for retake
            if (!isRetake && quiz.isExpired()) {
                throw new ServiceException("Quiz sudah melewati deadline (" + quiz.getFormattedDeadline() + ")");
            }

            // Check if user has already submitted - skip for retake
            if (!isRetake && submissionDAO.hasSubmitted(userId, quizId)) {
                throw new ServiceException("Anda sudah mengerjakan quiz ini");
            }

            // Check if there's an in-progress submission
            Submission existing = submissionDAO.findByUserAndQuiz(userId, quizId);
            if (existing != null && existing.isInProgress()) {
                // If old submission has no question_order, generate and save it now
                if (existing.getQuestionOrder() == null || existing.getQuestionOrder().isEmpty()) {
                    boolean shuffle = quiz.getShuffleQuestions() == null || quiz.getShuffleQuestions();
                    List<Question> questions = questionDAO.findByQuizIdForExam(quizId, shuffle);
                    List<String> qIds = new ArrayList<>();
                    for (Question q : questions) {
                        qIds.add(String.valueOf(q.getId()));
                    }
                    if (shuffle) {
                        Collections.shuffle(qIds);
                    }
                    submissionDAO.saveQuestionOrder(existing.getId(), String.join(",", qIds));
                }
                return existing;
            }

            // Create new submission
            Submission submission = new Submission(quizId, userId);
            submission.setTotalQuestions(questionDAO.countByQuizId(quizId));
            submission.setIsRetake(isRetake);

            // Generate shuffled question order for this user
            boolean shuffle = quiz.getShuffleQuestions() == null || quiz.getShuffleQuestions();
            List<Question> questions = questionDAO.findByQuizIdForExam(quizId, shuffle);
            List<String> qIds = new ArrayList<>();
            for (Question q : questions) {
                qIds.add(String.valueOf(q.getId()));
            }
            if (shuffle) {
                Collections.shuffle(qIds);
            }
            submission.setQuestionOrder(String.join(",", qIds));

            return submissionDAO.create(submission);

        } catch (SQLException e) {
            throw new ServiceException("Gagal memulai quiz: " + e.getMessage(), e);
        }
    }

    /**
     * Get only the selected answer for a specific question in a submission.
     * Safe to use during exam - does not load correct_answer into memory.
     */
    public String getSavedAnswerForQuestion(Integer submissionId, Integer questionId) throws ServiceException {
        try {
            return submissionDAO.getSavedAnswerForQuestion(submissionId, questionId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil jawaban tersimpan: " + e.getMessage(), e);
        }
    }

    /**
     * Get questions for taking quiz
     */
    public List<Question> getQuestionsForExam(Integer quizId) throws ServiceException {
        try {
            Quiz quiz = quizDAO.findById(quizId);
            boolean shuffle = quiz != null && (quiz.getShuffleQuestions() == null || quiz.getShuffleQuestions());
            return questionDAO.findByQuizIdForExam(quizId, shuffle);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil soal: " + e.getMessage(), e);
        }
    }

    /**
     * Get a single question by ID without correct answer (for exam use)
     */
    public Question getQuestionById(Integer questionId) throws ServiceException {
        try {
            return questionDAO.findByIdForExam(questionId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil soal: " + e.getMessage(), e);
        }
    }

    /**
     * Reshuffle question order for an in-progress submission.
     * Called when user refreshes/reopens the quiz page so questions appear in a new random order.
     */
    public void reshuffleQuestionOrder(Integer submissionId, Integer quizId) throws ServiceException {
        try {
            Quiz quiz = quizDAO.findById(quizId);
            boolean shuffle = quiz != null && (quiz.getShuffleQuestions() == null || quiz.getShuffleQuestions());
            if (!shuffle) return; // Don't reshuffle if shuffle is disabled

            List<Question> questions = questionDAO.findByQuizIdForExam(quizId, true);
            List<String> qIds = new ArrayList<>();
            for (Question q : questions) {
                qIds.add(String.valueOf(q.getId()));
            }
            Collections.shuffle(qIds);
            submissionDAO.saveQuestionOrder(submissionId, String.join(",", qIds));
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengacak urutan soal: " + e.getMessage(), e);
        }
    }

    /**
     * Save question order for a submission (used for old submissions migration)
     */
    public void saveQuestionOrder(Integer submissionId, String questionOrder) throws ServiceException {
        try {
            submissionDAO.saveQuestionOrder(submissionId, questionOrder);
        } catch (SQLException e) {
            throw new ServiceException("Gagal menyimpan urutan soal: " + e.getMessage(), e);
        }
    }

    /**
     * Get questions for taking quiz with deterministic shuffle (same order per submission)
     */
    public List<Question> getQuestionsForExam(Integer quizId, int seed) throws ServiceException {
        try {
            return questionDAO.findByQuizIdForExam(quizId, seed);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil soal: " + e.getMessage(), e);
        }
    }

    /**
     * Get questions for taking quiz with explicit shuffle setting
     */
    public List<Question> getQuestionsForExam(Integer quizId, boolean shuffle) throws ServiceException {
        try {
            return questionDAO.findByQuizIdForExam(quizId, shuffle);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil soal: " + e.getMessage(), e);
        }
    }

    /**
     * Save an answer during exam
     */
    public void saveAnswer(Integer submissionId, Integer questionId, String selectedAnswer)
            throws ServiceException {
        // Validate inputs
        if (submissionId == null || submissionId <= 0) {
            throw new ServiceException("Submission ID tidak valid");
        }
        if (questionId == null || questionId <= 0) {
            throw new ServiceException("Question ID tidak valid");
        }
        if (!ValidationUtil.isValidAnswer(selectedAnswer)) {
            throw new ServiceException("Jawaban tidak valid (harus A, B, C, atau D)");
        }

        try {
            // Verify submission exists and is in progress
            Submission submission = submissionDAO.findById(submissionId);
            if (submission == null) {
                throw new ServiceException("Submission tidak ditemukan");
            }
            if (submission.isCompleted()) {
                throw new ServiceException("Quiz sudah selesai, tidak dapat mengubah jawaban");
            }

            // Get question and verify it belongs to the quiz
            Question question = questionDAO.findById(questionId);
            if (question == null) {
                throw new ServiceException("Pertanyaan tidak ditemukan");
            }

            // Verify question belongs to this quiz
            if (!question.getQuizId().equals(submission.getQuizId())) {
                throw new ServiceException("Pertanyaan tidak termasuk dalam quiz ini");
            }

            // Calculate correctness
            boolean isCorrect = selectedAnswer.equalsIgnoreCase(question.getCorrectAnswer());

            // Save answer (will update if exists due to unique constraint)
            Answer answer = new Answer(submissionId, questionId, selectedAnswer.toUpperCase());
            answer.setIsCorrect(isCorrect);

            submissionDAO.saveAnswer(answer);

        } catch (SQLException e) {
            throw new ServiceException("Gagal menyimpan jawaban: " + e.getMessage(), e);
        }
    }

    /**
     * Submit quiz and calculate score
     */
    public Submission submitQuiz(Integer submissionId, Integer timeSpent) throws ServiceException {
        return submitQuiz(submissionId, timeSpent, "completed");
    }

    /**
     * Submit quiz with timeout status (auto-submit when time expires)
     */
    public Submission submitQuizWithTimeout(Integer submissionId, Integer timeSpent) throws ServiceException {
        return submitQuiz(submissionId, timeSpent, "timeout");
    }

    /**
     * Internal method to submit quiz with specific status
     */
    private Submission submitQuiz(Integer submissionId, Integer timeSpent, String status) throws ServiceException {
        // Validate inputs
        if (submissionId == null || submissionId <= 0) {
            throw new ServiceException("Submission ID tidak valid");
        }
        if (timeSpent != null && timeSpent < 0) {
            timeSpent = 0; // Default to 0 if negative
        }

        try {
            Submission submission = submissionDAO.findById(submissionId);
            if (submission == null) {
                throw new ServiceException("Submission tidak ditemukan");
            }

            if (submission.isCompleted()) {
                throw new ServiceException("Quiz sudah disubmit");
            }

            // Get all answers for this submission
            List<Answer> answers = submissionDAO.getAnswers(submissionId);
            int correctCount = 0;

            // Track question statistics
            Map<Integer, Boolean> questionStats = new HashMap<>();

            for (Answer answer : answers) {
                boolean isCorrect = answer.getIsCorrect() != null && answer.getIsCorrect();
                if (isCorrect) {
                    correctCount++;
                }
                questionStats.put(answer.getQuestionId(), isCorrect);
            }

            // Get total questions from quiz
            int totalQuestions = questionDAO.countByQuizId(submission.getQuizId());
            if (totalQuestions <= 0) {
                totalQuestions = submission.getTotalQuestions();
            }

            // Calculate score (0-100)
            double score = totalQuestions > 0 ? (correctCount * 100.0 / totalQuestions) : 0;
            score = Math.min(100.0, Math.max(0.0, score)); // Ensure score is between 0-100

            // Update submission
            submission.setTotalQuestions(totalQuestions);
            submission.setCorrectAnswers(correctCount);
            submission.setScore(Math.round(score * 100.0) / 100.0); // Round to 2 decimal places
            submission.setSubmittedAt(LocalDateTime.now());
            submission.setTimeSpent(timeSpent != null ? timeSpent : 0);
            submission.setStatus(status); // "completed" or "timeout"

            if (!submissionDAO.update(submission)) {
                throw new ServiceException("Gagal mengupdate submission");
            }

            // Update question statistics (don't fail if this errors)
            try {
                questionDAO.batchUpdateStatistics(questionStats);
            } catch (SQLException e) {
                System.err.println("Error updating question statistics: " + e.getMessage());
            }

            // Set answers for display
            submission.setAnswers(answers);

            // Check and award achievements (async - don't fail submission if this fails)
            try {
                Quiz quiz = quizDAO.findById(submission.getQuizId());
                achievementService.checkAndAwardAchievements(
                    submission.getUserId(),
                    submission.getQuizId(),
                    submission.getScore(),
                    timeSpent != null ? timeSpent : 0,
                    quiz != null ? quiz.getDuration() : 0
                );
            } catch (Exception e) {
                // Log error but don't fail the submission
                System.err.println("Error checking achievements: " + e.getMessage());
            }

            return submission;

        } catch (SQLException e) {
            throw new ServiceException("Gagal submit quiz: " + e.getMessage(), e);
        }
    }

    /**
     * Get submission result
     */
    public Submission getResult(Integer submissionId) throws ServiceException {
        try {
            Submission submission = submissionDAO.findById(submissionId);
            if (submission == null) {
                throw new ServiceException("Submission tidak ditemukan");
            }

            // Get answers
            List<Answer> answers = submissionDAO.getAnswers(submissionId);
            submission.setAnswers(answers);

            return submission;
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil hasil: " + e.getMessage(), e);
        }
    }

    /**
     * Get all questions with their answer status (including unanswered)
     * Used for showing complete result review
     */
    public List<Answer> getAllQuestionsWithAnswers(Integer submissionId, Integer quizId) throws ServiceException {
        try {
            // Get all questions for the quiz (same method used for taking exam)
            List<Question> allQuestions = getQuestionsForExam(quizId, false);

            // Get existing answers
            List<Answer> existingAnswers = submissionDAO.getAnswers(submissionId);

            // Create a map of questionId -> Answer for quick lookup
            Map<Integer, Answer> answerMap = new HashMap<>();
            for (Answer ans : existingAnswers) {
                answerMap.put(ans.getQuestionId(), ans);
            }

            // Build complete list of answers (including unanswered)
            List<Answer> completeAnswers = new java.util.ArrayList<>();
            for (Question q : allQuestions) {
                Answer ans = answerMap.get(q.getId());
                if (ans == null) {
                    // Create an "unanswered" entry
                    ans = new Answer(submissionId, q.getId(), null);
                    ans.setQuestionText(q.getQuestionText());
                    ans.setImagePath(q.getImagePath());
                    ans.setCorrectAnswer(q.getCorrectAnswer());
                    ans.setIsCorrect(false);
                    // Set option texts
                    ans.setOptionA(q.getOptionA());
                    ans.setOptionB(q.getOptionB());
                    ans.setOptionC(q.getOptionC());
                    ans.setOptionD(q.getOptionD());
                    ans.setExplanation(q.getExplanation());
                }
                completeAnswers.add(ans);
            }

            return completeAnswers;
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data hasil: " + e.getMessage(), e);
        }
    }

    /**
     * Get user's submission for a quiz
     */
    public Submission getUserSubmission(Integer userId, Integer quizId) throws ServiceException {
        try {
            return submissionDAO.findByUserAndQuiz(userId, quizId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data submission: " + e.getMessage(), e);
        }
    }

    /**
     * Get all submissions for a quiz (admin)
     */
    public List<Submission> getQuizSubmissions(Integer quizId) throws ServiceException {
        try {
            return submissionDAO.findByQuizId(quizId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data submissions: " + e.getMessage(), e);
        }
    }

    /**
     * Get all submissions for a user
     */
    public List<Submission> getUserSubmissions(Integer userId) throws ServiceException {
        try {
            return submissionDAO.findByUserId(userId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data submissions: " + e.getMessage(), e);
        }
    }

    /**
     * Get all submissions (admin)
     */
    public List<Submission> getAllSubmissions() throws ServiceException {
        try {
            return submissionDAO.findAll();
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data submissions: " + e.getMessage(), e);
        }
    }

    /**
     * Get quiz statistics
     */
    public Map<String, Object> getQuizStatistics(Integer quizId) throws ServiceException {
        try {
            return submissionDAO.getStatistics(quizId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil statistik: " + e.getMessage(), e);
        }
    }

    /**
     * Check if user can take quiz
     */
    public boolean canTakeQuiz(Integer userId, Integer quizId) throws ServiceException {
        try {
            Quiz quiz = quizDAO.findById(quizId);
            if (quiz == null || !quiz.getIsActive()) {
                return false;
            }

            return !submissionDAO.hasSubmitted(userId, quizId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengecek status quiz: " + e.getMessage(), e);
        }
    }

    /**
     * Get detailed quiz results with participant list
     */
    public List<Map<String, Object>> getDetailedQuizResults(Integer quizId) throws ServiceException {
        try {
            List<Map<String, Object>> submissions = submissionDAO.getDetailedSubmissionsByQuiz(quizId);

            // Update unanswered count for each submission
            for (Map<String, Object> sub : submissions) {
                Integer submissionId = (Integer) sub.get("id");
                if (submissionId == null) continue;

                int answeredCount = submissionDAO.getAnsweredCount(submissionId);
                int totalQuestions = sub.get("totalQuestions") != null ? (Integer) sub.get("totalQuestions") : 0;
                int correctAnswers = sub.get("correctAnswers") != null ? (Integer) sub.get("correctAnswers") : 0;
                int wrongCount = answeredCount - correctAnswers;
                int unanswered = totalQuestions - answeredCount;

                sub.put("answeredCount", answeredCount);
                sub.put("wrongCount", wrongCount);
                sub.put("unanswered", unanswered);
            }

            return submissions;
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil hasil quiz: " + e.getMessage(), e);
        }
    }

    /**
     * Get submission detail with all questions and answers
     */
    public Map<String, Object> getSubmissionDetail(Integer submissionId) throws ServiceException {
        try {
            return submissionDAO.getSubmissionDetailWithAnswers(submissionId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil detail submission: " + e.getMessage(), e);
        }
    }

    /**
     * Get submissions by quiz and status
     */
    public List<Submission> getSubmissionsByQuizAndStatus(Integer quizId, String status) throws ServiceException {
        try {
            return submissionDAO.findByQuizAndStatus(quizId, status);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil submissions: " + e.getMessage(), e);
        }
    }

    /**
     * Reset timeout submissions for a quiz (delete them to allow retake)
     */
    public int resetTimeoutSubmissions(Integer quizId) throws ServiceException {
        try {
            return submissionDAO.deleteTimeoutSubmissions(quizId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mereset timeout submissions: " + e.getMessage(), e);
        }
    }

    /**
     * Get status counts for a quiz
     */
    public java.util.Map<String, Integer> getStatusCounts(Integer quizId) throws ServiceException {
        try {
            return submissionDAO.getStatusCounts(quizId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil status counts: " + e.getMessage(), e);
        }
    }


    /**
     * Reset specific timeout submissions
     */
    public int resetTimeoutSubmissionsByIds(Integer quizId, List<Integer> submissionIds) throws ServiceException {
        try {
            int count = 0;
            for (Integer submissionId : submissionIds) {
                if (submissionDAO.deleteTimeoutSubmission(submissionId, quizId)) {
                    count++;
                }
            }
            return count;
        } catch (SQLException e) {
            throw new ServiceException("Gagal mereset timeout submissions: " + e.getMessage(), e);
        }
    }

    /**
     * Get users who haven't taken the quiz yet
     */
    public List<Map<String, Object>> getUsersNotTakenQuiz(Integer quizId) throws ServiceException {
        try {
            String targetTag = submissionDAO.getQuizTargetTag(quizId);
            return submissionDAO.getUsersNotTakenQuiz(quizId, targetTag);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data users: " + e.getMessage(), e);
        }
    }

    /**
     * Get quiz target tag
     */
    public String getQuizTargetTag(Integer quizId) throws ServiceException {
        try {
            return submissionDAO.getQuizTargetTag(quizId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil target tag: " + e.getMessage(), e);
        }
    }

    /**
     * Service Exception
     */
    public static class ServiceException extends Exception {
        public ServiceException(String message) {
            super(message);
        }

        public ServiceException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    /**
     * Re-grade all submissions for a quiz based on current correct answers.
     * Called when admin changes a question's correct answer.
     * Returns number of submissions re-graded.
     */
    public int regradeSubmissionsForQuiz(Integer quizId) throws ServiceException {
        try {
            return submissionDAO.regradeSubmissionsForQuiz(quizId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal menilai ulang submissions: " + e.getMessage(), e);
        }
    }

    /**
     * Toggle a single answer's is_correct flag and recalculate the submission score.
     * This overrides any previous manual score override because the recalculated
     * value wins.
     *
     * Returns a Map combining audit data (oldIsCorrect, newIsCorrect, oldScore, newScore, etc.)
     * for the controller to log and return as JSON.
     */
    public Map<String, Object> toggleAnswerCorrectness(Integer submissionId, Integer questionId, boolean isCorrect) throws ServiceException {
        if (submissionId == null || submissionId <= 0) {
            throw new ServiceException("Submission ID tidak valid");
        }
        if (questionId == null || questionId <= 0) {
            throw new ServiceException("Question ID tidak valid");
        }

        try {
            Submission submission = submissionDAO.findById(submissionId);
            if (submission == null) {
                throw new ServiceException("Submission tidak ditemukan");
            }
            if (!submission.isCompleted()) {
                throw new ServiceException("Submission belum selesai, tidak dapat mengubah jawaban");
            }

            Boolean oldIsCorrect = submissionDAO.updateAnswerCorrectness(submissionId, questionId, isCorrect);
            if (oldIsCorrect == null) {
                throw new ServiceException("Jawaban untuk soal ini tidak ditemukan pada submission");
            }

            Map<String, Object> scoreInfo = submissionDAO.recalculateSubmissionScore(submissionId);
            if (scoreInfo == null) {
                throw new ServiceException("Gagal menghitung ulang skor submission");
            }

            Map<String, Object> result = new HashMap<>();
            result.put("submissionId", submissionId);
            result.put("questionId", questionId);
            result.put("oldIsCorrect", oldIsCorrect);
            result.put("newIsCorrect", isCorrect);
            result.putAll(scoreInfo);
            return result;
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengubah status jawaban: " + e.getMessage(), e);
        }
    }

    /**
     * Override the final score for a submission (0-100) without modifying
     * the per-question is_correct flags or correct_answers count.
     * Returns the previous score.
     */
    public double overrideScore(Integer submissionId, double newScore) throws ServiceException {
        if (submissionId == null || submissionId <= 0) {
            throw new ServiceException("Submission ID tidak valid");
        }
        if (!ValidationUtil.isValidScore(newScore)) {
            throw new ServiceException("Skor harus berada di antara 0 dan 100");
        }

        try {
            Submission submission = submissionDAO.findById(submissionId);
            if (submission == null) {
                throw new ServiceException("Submission tidak ditemukan");
            }
            if (!submission.isCompleted()) {
                throw new ServiceException("Submission belum selesai, tidak dapat meng-override skor");
            }

            double oldScore = submission.getScore();
            submissionDAO.overrideScore(submissionId, newScore);
            return oldScore;
        } catch (SQLException e) {
            throw new ServiceException("Gagal meng-override skor: " + e.getMessage(), e);
        }
    }

    /**
     * Create a manual submission for a user who never took the quiz.
     * The submission is created with status "completed" so it counts toward
     * quiz statistics. No answers are stored; the score is whatever the admin
     * inputs (0-100). This is intended for recording official scores (e.g. 0)
     * for participants who skipped the quiz entirely.
     */
    public Submission createManualSubmission(Integer userId, Integer quizId, double score) throws ServiceException {
        if (userId == null || userId <= 0) {
            throw new ServiceException("User ID tidak valid");
        }
        if (quizId == null || quizId <= 0) {
            throw new ServiceException("Quiz ID tidak valid");
        }
        if (!ValidationUtil.isValidScore(score)) {
            throw new ServiceException("Skor harus berada di antara 0 dan 100");
        }

        try {
            // Quiz must exist
            Quiz quiz = quizDAO.findById(quizId);
            if (quiz == null) {
                throw new ServiceException("Quiz tidak ditemukan");
            }

            // User must not already have a submission for this quiz
            Submission existing = submissionDAO.findByUserAndQuiz(userId, quizId);
            if (existing != null) {
                throw new ServiceException("User sudah memiliki submission");
            }

            int totalQuestions = questionDAO.countByQuizId(quizId);

            Submission submission = new Submission();
            submission.setQuizId(quizId);
            submission.setUserId(userId);
            submission.setScore(Math.round(score * 100.0) / 100.0);
            submission.setTotalQuestions(totalQuestions);
            submission.setCorrectAnswers(0);
            submission.setStartedAt(LocalDateTime.now());
            submission.setSubmittedAt(LocalDateTime.now());
            submission.setTimeSpent(0);
            submission.setStatus("completed");
            submission.setIsRetake(false);

            return submissionDAO.create(submission);
        } catch (SQLException e) {
            throw new ServiceException("Gagal membuat submission manual: " + e.getMessage(), e);
        }
    }

    /**
     * Save the manual correct-count for a user/quiz pair. If an existing
     * completed/timeout submission exists, its correctAnswers and score are
     * updated. If no submission exists, a new completed submission is created.
     * Score is recomputed as correctCount * 100 / totalQuestions.
     *
     * Does not update question_statistics or trigger achievements (manual grade).
     */
    public Submission saveCorrectCount(Integer userId, Integer quizId, Integer correctCount) throws ServiceException {
        if (userId == null || userId <= 0) {
            throw new ServiceException("User ID tidak valid");
        }
        if (quizId == null || quizId <= 0) {
            throw new ServiceException("Quiz ID tidak valid");
        }
        if (correctCount == null || correctCount < 0) {
            throw new ServiceException("Jawaban benar tidak valid");
        }

        try {
            Quiz quiz = quizDAO.findById(quizId);
            if (quiz == null) {
                throw new ServiceException("Quiz tidak ditemukan");
            }

            int totalQuestions = questionDAO.countByQuizId(quizId);
            if (correctCount > totalQuestions) {
                throw new ServiceException("Jawaban benar melebihi jumlah soal");
            }

            double score = totalQuestions > 0
                    ? Math.round(correctCount * 100.0 / totalQuestions * 100.0) / 100.0
                    : 0.0;

            Submission existing = submissionDAO.findByUserAndQuiz(userId, quizId);
            if (existing != null) {
                if (existing.isInProgress()) {
                    throw new ServiceException("Submission masih in_progress, tidak dapat dinilai manual");
                }
                existing.setCorrectAnswers(correctCount);
                existing.setScore(score);
                if (existing.getTotalQuestions() == null || existing.getTotalQuestions() <= 0) {
                    existing.setTotalQuestions(totalQuestions);
                }
                if (!submissionDAO.update(existing)) {
                    throw new ServiceException("Gagal mengupdate submission");
                }
                return existing;
            }

            Submission submission = new Submission();
            submission.setQuizId(quizId);
            submission.setUserId(userId);
            submission.setCorrectAnswers(correctCount);
            submission.setScore(score);
            submission.setTotalQuestions(totalQuestions);
            submission.setStartedAt(LocalDateTime.now());
            submission.setSubmittedAt(LocalDateTime.now());
            submission.setTimeSpent(0);
            submission.setStatus("completed");
            submission.setIsRetake(false);

            return submissionDAO.create(submission);
        } catch (SQLException e) {
            throw new ServiceException("Gagal menyimpan correct count: " + e.getMessage(), e);
        }
    }

    /**
     * Thin wrapper around the DAO for fetching all submissions eligible for
     * inline score editing (completed or timeout). Optional filters.
     */
    public List<Map<String, Object>> getEditableSubmissions(Integer quizIdFilter, String tagFilter, String search) throws ServiceException {
        try {
            return submissionDAO.getAllEditableSubmissions(quizIdFilter, tagFilter, search);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil daftar submission: " + e.getMessage(), e);
        }
    }
}
