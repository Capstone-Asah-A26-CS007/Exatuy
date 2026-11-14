package com.examora.service;

import com.examora.dao.QuestionDAO;
import com.examora.dao.QuizDAO;
import com.examora.dao.SubmissionDAO;
import com.examora.dao.QuizExemptionDAO;
import com.examora.model.Question;
import com.examora.model.Quiz;
import com.examora.model.Submission;
import com.examora.model.QuizExemption;
import com.examora.model.Answer;
import com.examora.util.ValidationUtil;

import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Quiz Service - Business logic for quiz operations
 */
public class QuizService {
    private QuizDAO quizDAO;
    private QuestionDAO questionDAO;
    private SubmissionDAO submissionDAO;
    private QuizExemptionDAO quizExemptionDAO;

    public QuizService() {
        this.quizDAO = new QuizDAO();
        this.questionDAO = new QuestionDAO();
        this.submissionDAO = new SubmissionDAO();
        this.quizExemptionDAO = new QuizExemptionDAO();
    }

    /**
     * Create a new quiz
     */
    public Quiz createQuiz(String title, String description, Integer duration, Integer createdBy)
            throws ServiceException {
        return createQuiz(title, description, duration, createdBy, null, null, null);
    }

    /**
     * Create a new quiz with deadline
     */
    public Quiz createQuiz(String title, String description, Integer duration, Integer createdBy, LocalDateTime deadline)
            throws ServiceException {
        return createQuiz(title, description, duration, createdBy, deadline, null, null);
    }

    /**
     * Create a new quiz with deadline and target tag
     */
    public Quiz createQuiz(String title, String description, Integer duration, Integer createdBy,
                          LocalDateTime deadline, String targetTag)
            throws ServiceException {
        return createQuiz(title, description, duration, createdBy, deadline, targetTag, null, true, true);
    }

    /**
     * Create a new quiz with deadline, target tag, and start time
     */
    public Quiz createQuiz(String title, String description, Integer duration, Integer createdBy,
                          LocalDateTime deadline, String targetTag, LocalDateTime startTime)
            throws ServiceException {
        return createQuiz(title, description, duration, createdBy, deadline, targetTag, startTime, true, true);
    }

    /**
     * Create a new quiz with all options
     */
    public Quiz createQuiz(String title, String description, Integer duration, Integer createdBy,
                          LocalDateTime deadline, String targetTag, LocalDateTime startTime,
                          Boolean shuffleQuestions, Boolean showReview)
            throws ServiceException {
        // Validate inputs
        if (ValidationUtil.isEmpty(title)) {
            throw new ServiceException("Judul quiz tidak boleh kosong");
        }
        if (duration == null || duration <= 0) {
            throw new ServiceException("Durasi harus lebih dari 0 menit");
        }
        if (deadline != null && deadline.isBefore(LocalDateTime.now())) {
            throw new ServiceException("Deadline tidak boleh di waktu yang sudah lewat");
        }
        if (startTime != null && deadline != null && startTime.isAfter(deadline)) {
            throw new ServiceException("Waktu mulai tidak boleh setelah deadline");
        }

        try {
            Quiz quiz = new Quiz(title, description, duration, createdBy);
            quiz.setDeadline(deadline);
            quiz.setStartTime(startTime);
            quiz.setTargetTag(targetTag);
            quiz.setShuffleQuestions(shuffleQuestions != null ? shuffleQuestions : true);
            quiz.setShowReview(showReview != null ? showReview : true);
            return quizDAO.create(quiz);
        } catch (SQLException e) {
            throw new ServiceException("Gagal membuat quiz: " + e.getMessage(), e);
        }
    }

    /**
     * Get quiz by ID
     */
    public Quiz getQuizById(Integer id) throws ServiceException {
        try {
            Quiz quiz = quizDAO.findById(id);
            if (quiz == null) {
                throw new ServiceException("Quiz tidak ditemukan");
            }
            return quiz;
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data quiz: " + e.getMessage(), e);
        }
    }

    /**
     * Get all quizzes
     */
    public List<Quiz> getAllQuizzes() throws ServiceException {
        try {
            return quizDAO.findAll();
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data quizzes: " + e.getMessage(), e);
        }
    }

    /**
     * Get active quizzes
     */
    public List<Quiz> getActiveQuizzes() throws ServiceException {
        try {
            return quizDAO.findActive();
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data quizzes: " + e.getMessage(), e);
        }
    }

    /**
     * Get active quizzes for a specific tag
     */
    public List<Quiz> getActiveQuizzesByTag(String userTag) throws ServiceException {
        try {
            return quizDAO.findActiveByTag(userTag);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data quizzes: " + e.getMessage(), e);
        }
    }

    /**
     * Get expired quizzes for a specific tag
     */
    public List<Quiz> getExpiredQuizzesByTag(String userTag) throws ServiceException {
        try {
            return quizDAO.findExpiredByTag(userTag);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data quizzes kadaluarsa: " + e.getMessage(), e);
        }
    }

    /**
     * Get quizzes by creator
     */
    public List<Quiz> getQuizzesByCreator(Integer createdBy) throws ServiceException {
        try {
            return quizDAO.findByCreator(createdBy);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data quizzes: " + e.getMessage(), e);
        }
    }

    /**
     * Update quiz
     */
    public Quiz updateQuiz(Integer id, String title, String description, Integer duration)
            throws ServiceException {
        return updateQuiz(id, title, description, duration, null, null, null);
    }

    /**
     * Update quiz with deadline
     */
    public Quiz updateQuiz(Integer id, String title, String description, Integer duration, LocalDateTime deadline)
            throws ServiceException {
        return updateQuiz(id, title, description, duration, deadline, null, null);
    }

    /**
     * Update quiz with deadline and target tag
     */
    public Quiz updateQuiz(Integer id, String title, String description, Integer duration,
                          LocalDateTime deadline, String targetTag)
            throws ServiceException {
        return updateQuiz(id, title, description, duration, deadline, targetTag, null, true, true, null);
    }

    /**
     * Update quiz with deadline, target tag, and start time
     */
    public Quiz updateQuiz(Integer id, String title, String description, Integer duration,
                          LocalDateTime deadline, String targetTag, LocalDateTime startTime)
            throws ServiceException {
        return updateQuiz(id, title, description, duration, deadline, targetTag, startTime, true, true, null);
    }

    /**
     * Update quiz with all options
     */
    public Quiz updateQuiz(Integer id, String title, String description, Integer duration,
                          LocalDateTime deadline, String targetTag, LocalDateTime startTime,
                          Boolean shuffleQuestions, Boolean showReview)
            throws ServiceException {
        return updateQuiz(id, title, description, duration, deadline, targetTag, startTime, shuffleQuestions, showReview, null);
    }

    /**
     * Update quiz with all options including exemption time
     */
    public Quiz updateQuiz(Integer id, String title, String description, Integer duration,
                          LocalDateTime deadline, String targetTag, LocalDateTime startTime,
                          Boolean shuffleQuestions, Boolean showReview, Integer exemptionTime)
            throws ServiceException {
        if (ValidationUtil.isEmpty(title)) {
            throw new ServiceException("Judul quiz tidak boleh kosong");
        }
        if (duration == null || duration <= 0) {
            throw new ServiceException("Durasi harus lebih dari 0 menit");
        }
        if (deadline != null && deadline.isBefore(LocalDateTime.now())) {
            throw new ServiceException("Deadline tidak boleh di waktu yang sudah lewat");
        }
        if (startTime != null && deadline != null && startTime.isAfter(deadline)) {
            throw new ServiceException("Waktu mulai tidak boleh setelah deadline");
        }

        try {
            Quiz quiz = quizDAO.findById(id);
            if (quiz == null) {
                throw new ServiceException("Quiz tidak ditemukan");
            }

            quiz.setTitle(title);
            quiz.setDescription(description);
            quiz.setDuration(duration);
            quiz.setDeadline(deadline);
            quiz.setStartTime(startTime);
            quiz.setTargetTag(targetTag);
            quiz.setShuffleQuestions(shuffleQuestions != null ? shuffleQuestions : true);
            quiz.setShowReview(showReview != null ? showReview : true);
            quiz.setExemptionTime(exemptionTime);

            if (!quizDAO.updateWithTargetTag(quiz)) {
                throw new ServiceException("Gagal mengupdate quiz");
            }

            return quiz;
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengupdate quiz: " + e.getMessage(), e);
        }
    }

    /**
     * Publish quiz
     */
    public void publishQuiz(Integer id) throws ServiceException {
        try {
            Quiz quiz = quizDAO.findById(id);
            if (quiz == null) {
                throw new ServiceException("Quiz tidak ditemukan");
            }

            // Check if quiz has questions
            int questionCount = questionDAO.countByQuizId(id);
            if (questionCount == 0) {
                throw new ServiceException("Quiz harus memiliki minimal 1 soal sebelum dipublish");
            }

            if (!quizDAO.updateStatus(id, true)) {
                throw new ServiceException("Gagal mempublish quiz");
            }
        } catch (SQLException e) {
            throw new ServiceException("Gagal mempublish quiz: " + e.getMessage(), e);
        }
    }

    /**
     * Unpublish quiz
     */
    public void unpublishQuiz(Integer id) throws ServiceException {
        try {
            if (!quizDAO.updateStatus(id, false)) {
                throw new ServiceException("Gagal unpublish quiz");
            }
        } catch (SQLException e) {
            throw new ServiceException("Gagal unpublish quiz: " + e.getMessage(), e);
        }
    }

    /**
     * Delete quiz
     */
    public void deleteQuiz(Integer id) throws ServiceException {
        try {
            // Check if quiz has submissions
            int submissionCount = submissionDAO.countByQuizId(id);
            if (submissionCount > 0) {
                throw new ServiceException("Quiz tidak dapat dihapus karena sudah ada yang mengerjakan");
            }

            if (!quizDAO.delete(id)) {
                throw new ServiceException("Gagal menghapus quiz");
            }
        } catch (SQLException e) {
            throw new ServiceException("Gagal menghapus quiz: " + e.getMessage(), e);
        }
    }

    /**
     * Add question to quiz
     */
    public Question addQuestion(Integer quizId, String questionText, String imagePath, String optionA, String optionB,
                                String optionC, String optionD, String correctAnswer)
            throws ServiceException {
        return addQuestion(quizId, questionText, imagePath, optionA, optionB, optionC, optionD, correctAnswer, null, null);
    }

    /**
     * Add question to quiz with category and explanation
     */
    public Question addQuestion(Integer quizId, String questionText, String imagePath, String optionA, String optionB,
                                String optionC, String optionD, String correctAnswer, Integer categoryId, String explanation)
            throws ServiceException {
        // Validate inputs
        if (ValidationUtil.isEmpty(questionText)) {
            throw new ServiceException("Pertanyaan tidak boleh kosong");
        }
        if (ValidationUtil.isEmpty(optionA) || ValidationUtil.isEmpty(optionB) ||
            ValidationUtil.isEmpty(optionC) || ValidationUtil.isEmpty(optionD)) {
            throw new ServiceException("Semua opsi jawaban harus diisi");
        }
        if (!ValidationUtil.isValidAnswer(correctAnswer)) {
            throw new ServiceException("Jawaban benar harus A, B, C, atau D");
        }

        try {
            // Check if quiz exists
            Quiz quiz = quizDAO.findById(quizId);
            if (quiz == null) {
                throw new ServiceException("Quiz tidak ditemukan");
            }

            // Get next order number
            int order = questionDAO.countByQuizId(quizId);

            Question question = new Question(quizId, questionText, optionA, optionB, optionC, optionD, correctAnswer.toUpperCase());
            question.setImagePath(imagePath);
            question.setQuestionOrder(order);
            question.setCategoryId(categoryId);
            question.setExplanation(explanation);

            return questionDAO.create(question);
        } catch (SQLException e) {
            throw new ServiceException("Gagal menambah pertanyaan: " + e.getMessage(), e);
        }
    }

    /**
     * Get questions for a quiz
     */
    public List<Question> getQuestions(Integer quizId) throws ServiceException {
        try {
            return questionDAO.findByQuizId(quizId);
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengambil data pertanyaan: " + e.getMessage(), e);
        }
    }

    /**
     * Update question
     */
    public Question updateQuestion(Integer questionId, String questionText, String imagePath, String optionA,
                                   String optionB, String optionC, String optionD, String correctAnswer)
            throws ServiceException {
        return updateQuestion(questionId, questionText, imagePath, optionA, optionB, optionC, optionD, correctAnswer, null, null);
    }

    /**
     * Update question with category and explanation
     */
    public Question updateQuestion(Integer questionId, String questionText, String imagePath, String optionA,
                                   String optionB, String optionC, String optionD, String correctAnswer,
                                   Integer categoryId, String explanation)
            throws ServiceException {
        if (ValidationUtil.isEmpty(questionText)) {
            throw new ServiceException("Pertanyaan tidak boleh kosong");
        }
        if (ValidationUtil.isEmpty(optionA) || ValidationUtil.isEmpty(optionB) ||
            ValidationUtil.isEmpty(optionC) || ValidationUtil.isEmpty(optionD)) {
            throw new ServiceException("Semua opsi jawaban harus diisi");
        }
        if (!ValidationUtil.isValidAnswer(correctAnswer)) {
            throw new ServiceException("Jawaban benar harus A, B, C, atau D");
        }

        try {
            Question question = questionDAO.findById(questionId);
            if (question == null) {
                throw new ServiceException("Pertanyaan tidak ditemukan");
            }

            // Detect if correct answer or options changed (affects existing submissions)
            String oldCorrectAnswer = question.getCorrectAnswer();
            String oldOptionA = question.getOptionA();
            String oldOptionB = question.getOptionB();
            String oldOptionC = question.getOptionC();
            String oldOptionD = question.getOptionD();

            boolean answerChanged = !oldCorrectAnswer.equalsIgnoreCase(correctAnswer);
            boolean optionsChanged = (oldOptionA == null ? optionA != null : !oldOptionA.equals(optionA)) ||
                                     (oldOptionB == null ? optionB != null : !oldOptionB.equals(optionB)) ||
                                     (oldOptionC == null ? optionC != null : !oldOptionC.equals(optionC)) ||
                                     (oldOptionD == null ? optionD != null : !oldOptionD.equals(optionD));

            question.setQuestionText(questionText);
            // Only update image path if a new one is provided
            if (imagePath != null) {
                question.setImagePath(imagePath);
            }
            question.setOptionA(optionA);
            question.setOptionB(optionB);
            question.setOptionC(optionC);
            question.setOptionD(optionD);
            question.setCorrectAnswer(correctAnswer.toUpperCase());
            question.setCategoryId(categoryId);
            question.setExplanation(explanation);

            if (!questionDAO.update(question)) {
                throw new ServiceException("Gagal mengupdate pertanyaan");
            }

            // Re-grade existing submissions if correct answer changed
            if (answerChanged) {
                try {
                    SubmissionService submissionService = new SubmissionService();
                    int regraded = submissionService.regradeSubmissionsForQuiz(question.getQuizId());
                    System.out.println("Re-graded " + regraded + " submissions for quiz " + question.getQuizId() +
                                       " after correct answer change on question " + questionId);
                } catch (Exception e) {
                    System.err.println("Warning: Failed to re-grade submissions after question update: " + e.getMessage());
                }
            }

            return question;
        } catch (SQLException e) {
            throw new ServiceException("Gagal mengupdate pertanyaan: " + e.getMessage(), e);
        }
    }

    /**
     * Delete question
     */
    public void deleteQuestion(Integer questionId) throws ServiceException {
        try {
            if (!questionDAO.delete(questionId)) {
                throw new ServiceException("Gagal menghapus pertanyaan");
            }
        } catch (SQLException e) {
            throw new ServiceException("Gagal menghapus pertanyaan: " + e.getMessage(), e);
        }
    }

    /**
     * Auto-create perfect score submissions for exempted users
     * This is called when a quiz is published to ensure exempted users get 100% automatically
     * Time spent is random between 10-20 minutes (600-1200 seconds) per user
     */
    public void createAutoSubmissionsForExemptedUsers(Integer quizId) throws ServiceException {
        try {
            // Check if quiz exists
            Quiz quiz = quizDAO.findById(quizId);
            if (quiz == null) {
                throw new ServiceException("Quiz tidak ditemukan");
            }

            // Get all questions for this quiz
            List<Question> questions = questionDAO.getCorrectAnswers(quizId);
            if (questions == null || questions.isEmpty()) {
                throw new ServiceException("Quiz tidak memiliki soal");
            }

            // Get all exempted users for this quiz
            List<QuizExemption> exemptions = quizExemptionDAO.findByQuizId(quizId);
            if (exemptions == null || exemptions.isEmpty()) {
                return; // No exempted users
            }

            // Random time between 10-20 minutes (600-1200 seconds) for each user
            java.util.Random random = new java.util.Random();

            // For each exempted user, create a submission with perfect score
            for (QuizExemption exemption : exemptions) {
                Integer userId = exemption.getUserId();

                // Check if user already has a submission
                if (submissionDAO.hasSubmitted(userId, quizId)) {
                    continue; // Skip users who already have a submission
                }

                // Random 10-20 minutes per user
                int timeSpent = 600 + random.nextInt(601); // 600 + random(0-600) = 600-1200 seconds

                // Create submission with perfect score
                Submission submission = new Submission(quizId, userId);
                submission.setScore(100.0);
                submission.setTotalQuestions(questions.size());
                submission.setCorrectAnswers(questions.size());
                submission.setStatus("completed");
                submission.setTimeSpent(timeSpent);
                submission.setStartedAt(LocalDateTime.now());
                submission.setSubmittedAt(LocalDateTime.now());

                submission = submissionDAO.create(submission);

                // Create answers for all questions (all correct)
                for (Question question : questions) {
                    Answer answer = new Answer(submission.getId(), question.getId(), question.getCorrectAnswer());
                    answer.setIsCorrect(true);
                    submissionDAO.saveAnswer(answer);
                }
            }
        } catch (SQLException e) {
            throw new ServiceException("Gagal membuat auto-submission untuk peserta dikecualikan: " + e.getMessage(), e);
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
}
