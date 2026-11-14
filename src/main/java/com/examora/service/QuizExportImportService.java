package com.examora.service;

import com.examora.model.Question;
import com.examora.model.Quiz;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.csv.CSVRecord;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Service for importing and exporting complete quizzes (metadata + questions) as CSV
 */
public class QuizExportImportService {
    private QuizService quizService;

    // CSV Headers for questions section
    private static final String[] QUESTION_HEADERS = {
        "question_text", "option_a", "option_b", "option_c", "option_d",
        "correct_answer", "category", "explanation"
    };

    public QuizExportImportService() {
        this.quizService = new QuizService();
    }

    /**
     * Export a quiz with all its questions to CSV format
     */
    public String exportQuizToCSV(Quiz quiz, List<Question> questions) {
        StringWriter writer = new StringWriter();

        try {
            // Line 1: Quiz metadata with #QUIZ# prefix
            CSVPrinter metaPrinter = new CSVPrinter(writer, CSVFormat.DEFAULT);
            metaPrinter.printRecord(
                "#QUIZ#",
                quiz.getTitle() != null ? quiz.getTitle() : "",
                quiz.getDescription() != null ? quiz.getDescription() : "",
                quiz.getDuration(),
                quiz.getTargetTag() != null ? quiz.getTargetTag() : "",
                quiz.getShuffleQuestions() != null ? quiz.getShuffleQuestions() : true,
                quiz.getShowReview() != null ? quiz.getShowReview() : true
            );
            metaPrinter.flush();

            // Line 2+: Question header and data
            try (CSVPrinter csvPrinter = new CSVPrinter(writer, CSVFormat.DEFAULT
                 .withHeader(QUESTION_HEADERS))) {

                for (Question question : questions) {
                    csvPrinter.printRecord(
                        question.getQuestionText(),
                        question.getOptionA(),
                        question.getOptionB(),
                        question.getOptionC(),
                        question.getOptionD(),
                        question.getCorrectAnswer(),
                        "",
                        question.getExplanation() != null ? question.getExplanation() : ""
                    );
                }
            }

        } catch (IOException e) {
            return "Error generating CSV: " + e.getMessage();
        }

        return writer.toString();
    }

    /**
     * Import a complete quiz (metadata + questions) from CSV
     * CSV first line starts with #QUIZ# containing quiz metadata
     */
    public QuizImportResult importQuizFromCSV(InputStream input, Integer createdBy) {
        QuizImportResult result = new QuizImportResult();

        try (BufferedReader reader = new BufferedReader(new InputStreamReader(input, StandardCharsets.UTF_8))) {
            // Read first line for quiz metadata
            String firstLine = reader.readLine();
            if (firstLine == null || firstLine.trim().isEmpty()) {
                result.addError("File CSV kosong");
                return result;
            }

            // Remove BOM and any invisible leading characters
            firstLine = cleanLine(firstLine);

            if (!firstLine.contains("#QUIZ#")) {
                result.addError("Baris pertama harus dimulai dengan #QUIZ#");
                return result;
            }

            // Parse the first line as CSV to extract quiz metadata
            CSVParser metaParser = CSVParser.parse(firstLine, CSVFormat.DEFAULT);
            CSVRecord metaRecord = metaParser.getRecords().get(0);

            String firstField = metaRecord.get(0).trim();
            if (!"#QUIZ#".equals(firstField)) {
                result.addError("Baris pertama harus dimulai dengan #QUIZ#");
                return result;
            }

            String title = metaRecord.size() > 1 ? metaRecord.get(1).trim() : "";
            String description = metaRecord.size() > 2 ? metaRecord.get(2).trim() : "";
            int duration = 30;
            try {
                duration = metaRecord.size() > 3 ? Integer.parseInt(metaRecord.get(3).trim()) : 30;
            } catch (NumberFormatException e) {
                result.addError("Durasi tidak valid, menggunakan default 30 menit");
            }
            String targetTag = metaRecord.size() > 4 ? metaRecord.get(4).trim() : null;
            boolean shuffleQuestions = true;
            if (metaRecord.size() > 5) {
                shuffleQuestions = parseBoolean(metaRecord.get(5).trim(), true);
            }
            boolean showReview = true;
            if (metaRecord.size() > 6) {
                showReview = parseBoolean(metaRecord.get(6).trim(), true);
            }

            if (title.isEmpty()) {
                result.addError("Judul quiz tidak boleh kosong");
                return result;
            }

            // Create the quiz
            Quiz quiz = quizService.createQuiz(
                title, description, duration, createdBy,
                null,
                (targetTag != null && targetTag.isEmpty()) ? null : targetTag,
                null,
                shuffleQuestions, showReview
            );
            result.setQuizTitle(title);
            result.incrementQuizCount();

            // Read remaining lines for questions
            StringBuilder remainingLines = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                // Clean each line from BOM and invisible characters
                line = cleanLine(line);
                if (!line.isEmpty()) {
                    remainingLines.append(line).append("\n");
                }
            }

            String questionText = remainingLines.toString();
            if (questionText.trim().isEmpty()) {
                result.addError("Tidak ada soal ditemukan setelah baris #QUIZ#");
                return result;
            }

            importQuestions(questionText, quiz.getId(), result);

        } catch (IOException e) {
            result.addError("Error membaca file CSV: " + e.getMessage());
        } catch (QuizService.ServiceException e) {
            result.addError("Gagal membuat quiz: " + e.getMessage());
        } catch (Exception e) {
            result.addError("Error: " + e.getMessage());
        }

        return result;
    }

    /**
     * Import questions only (no #QUIZ# row) — quiz metadata provided as parameters
     */
    public QuizImportResult importQuestionsOnly(InputStream input, Integer createdBy,
            String title, String description, int duration, String targetTag) {
        QuizImportResult result = new QuizImportResult();

        try {
            if (title == null || title.trim().isEmpty()) {
                result.addError("Judul quiz tidak boleh kosong");
                return result;
            }

            // Create the quiz
            Quiz quiz = quizService.createQuiz(
                title.trim(), description, duration, createdBy,
                null,
                (targetTag != null && targetTag.isEmpty()) ? null : targetTag,
                null,
                true, true
            );
            result.setQuizTitle(title.trim());
            result.incrementQuizCount();

            // Read all lines as questions
            StringBuilder allLines = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(input, StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    line = cleanLine(line);
                    if (!line.isEmpty()) {
                        allLines.append(line).append("\n");
                    }
                }
            }

            importQuestions(allLines.toString(), quiz.getId(), result);

        } catch (IOException e) {
            result.addError("Error membaca file CSV: " + e.getMessage());
        } catch (QuizService.ServiceException e) {
            result.addError("Gagal membuat quiz: " + e.getMessage());
        } catch (Exception e) {
            result.addError("Error: " + e.getMessage());
        }

        return result;
    }

    /**
     * Parse and import question rows from CSV text for a given quiz ID
     */
    private void importQuestions(String csvText, Integer quizId, QuizImportResult result) throws SQLException {
        if (csvText.trim().isEmpty()) return;

        try {
            // Try with header first (standard format)
            importQuestionsWithHeader(csvText, quizId, result);
        } catch (Exception headerError) {
            // Header parsing failed — try without header (raw positional format)
            try {
                importQuestionsWithoutHeader(csvText, quizId, result);
            } catch (Exception e) {
                result.addError("Gagal membaca soal: " + e.getMessage());
            }
        }
    }

    /**
     * Import questions with first row as header (standard CSV format)
     */
    private void importQuestionsWithHeader(String csvText, Integer quizId, QuizImportResult result) throws Exception {
        try (CSVParser csvParser = new CSVParser(
                new StringReader(csvText),
                CSVFormat.DEFAULT
                    .withFirstRecordAsHeader()
                    .withIgnoreHeaderCase()
                    .withTrim())) {

            // Check if the header contains expected columns
            boolean hasQuestionText = csvParser.getHeaderMap().containsKey("question_text");
            boolean hasCorrectAnswer = csvParser.getHeaderMap().containsKey("correct_answer");

            if (!hasQuestionText || !hasCorrectAnswer) {
                throw new Exception("Header tidak ditemukan — kolom question_text atau correct_answer tidak ada");
            }

            for (CSVRecord record : csvParser) {
                try {
                    String questionText = record.get("question_text");
                    String optionA = record.get("option_a");
                    String optionB = record.get("option_b");
                    String optionC = record.get("option_c");
                    String optionD = record.get("option_d");
                    String correctAnswer = record.get("correct_answer");

                    if (questionText == null || questionText.trim().isEmpty()) {
                        result.addError("Baris " + record.getRecordNumber() + ": Teks pertanyaan kosong, dilewati");
                        continue;
                    }
                    if (optionA == null || optionA.trim().isEmpty() ||
                        optionB == null || optionB.trim().isEmpty() ||
                        optionC == null || optionC.trim().isEmpty() ||
                        optionD == null || optionD.trim().isEmpty()) {
                        result.addError("Baris " + record.getRecordNumber() + ": Opsi jawaban tidak lengkap, dilewati");
                        continue;
                    }
                    if (correctAnswer == null || correctAnswer.trim().isEmpty()) {
                        result.addError("Baris " + record.getRecordNumber() + ": Jawaban benar kosong, dilewati");
                        continue;
                    }

                    correctAnswer = correctAnswer.toUpperCase().trim();
                    if (!correctAnswer.matches("[ABCD]")) {
                        result.addError("Baris " + record.getRecordNumber() + ": Jawaban benar harus A/B/C/D, dilewati");
                        continue;
                    }

                    String explanation = null;
                    if (record.isMapped("explanation")) {
                        explanation = record.get("explanation");
                        if (explanation != null && explanation.trim().isEmpty()) {
                            explanation = null;
                        }
                    }

                    quizService.addQuestion(
                        quizId,
                        questionText.trim(),
                        null,
                        optionA.trim(),
                        optionB.trim(),
                        optionC.trim(),
                        optionD.trim(),
                        correctAnswer,
                        null,
                        explanation != null ? explanation.trim() : null
                    );
                    result.incrementQuestionCount();

                } catch (Exception e) {
                    result.addError("Baris " + record.getRecordNumber() + ": " + e.getMessage());
                }
            }
        }
    }

    /**
     * Import questions without header row (positional format)
     * Column order: question_text, option_a, option_b, option_c, option_d, correct_answer, [category], [explanation]
     */
    private void importQuestionsWithoutHeader(String csvText, Integer quizId, QuizImportResult result) throws Exception {
        try (CSVParser csvParser = new CSVParser(
                new StringReader(csvText),
                CSVFormat.DEFAULT.withTrim())) {

            for (CSVRecord record : csvParser) {
                try {
                    if (record.size() < 6) {
                        result.addError("Baris " + record.getRecordNumber() + ": Kolom tidak cukup (minimal 6), dilewati");
                        continue;
                    }

                    String questionText = record.get(0);
                    String optionA = record.get(1);
                    String optionB = record.get(2);
                    String optionC = record.get(3);
                    String optionD = record.get(4);
                    String correctAnswer = record.get(5);

                    if (questionText == null || questionText.trim().isEmpty()) {
                        result.addError("Baris " + record.getRecordNumber() + ": Teks pertanyaan kosong, dilewati");
                        continue;
                    }
                    if (optionA == null || optionA.trim().isEmpty() ||
                        optionB == null || optionB.trim().isEmpty() ||
                        optionC == null || optionC.trim().isEmpty() ||
                        optionD == null || optionD.trim().isEmpty()) {
                        result.addError("Baris " + record.getRecordNumber() + ": Opsi jawaban tidak lengkap, dilewati");
                        continue;
                    }
                    if (correctAnswer == null || correctAnswer.trim().isEmpty()) {
                        result.addError("Baris " + record.getRecordNumber() + ": Jawaban benar kosong, dilewati");
                        continue;
                    }

                    correctAnswer = correctAnswer.toUpperCase().trim();
                    if (!correctAnswer.matches("[ABCD]")) {
                        result.addError("Baris " + record.getRecordNumber() + ": Jawaban benar harus A/B/C/D, dilewati");
                        continue;
                    }

                    String explanation = null;
                    if (record.size() > 7) {
                        explanation = record.get(7);
                        if (explanation != null && explanation.trim().isEmpty()) {
                            explanation = null;
                        }
                    }

                    quizService.addQuestion(
                        quizId,
                        questionText.trim(),
                        null,
                        optionA.trim(),
                        optionB.trim(),
                        optionC.trim(),
                        optionD.trim(),
                        correctAnswer,
                        null,
                        explanation != null ? explanation.trim() : null
                    );
                    result.incrementQuestionCount();

                } catch (Exception e) {
                    result.addError("Baris " + record.getRecordNumber() + ": " + e.getMessage());
                }
            }
        }
    }

    /**
     * Clean a line from BOM and invisible characters
     */
    private String cleanLine(String line) {
        if (line == null) return "";
        line = line.trim();
        while (line.length() > 0 &&
               (line.charAt(0) == '\uFEFF' || line.charAt(0) == '\uFFFD' ||
                line.charAt(0) == '\u200B' || line.charAt(0) == '\u00A0')) {
            line = line.substring(1);
        }
        return line;
    }

    /**
     * Generate a blank CSV template with example data (questions only, no #QUIZ# row)
     */
    public String generateTemplate() {
        StringWriter writer = new StringWriter();

        try (CSVPrinter csvPrinter = new CSVPrinter(writer, CSVFormat.DEFAULT
             .withHeader(QUESTION_HEADERS))) {

            csvPrinter.printRecord(
                "Apa itu IP Address?",
                "Alamat fisik perangkat",
                "Alamat logis perangkat di jaringan",
                "Sebuah protokol",
                "Port pada komputer",
                "B",
                "Networking",
                "IP Address adalah alamat logis yang digunakan untuk mengidentifikasi perangkat di jaringan"
            );

            csvPrinter.printRecord(
                "HTTP menggunakan port berapa?",
                "21",
                "22",
                "80",
                "443",
                "C",
                "Networking",
                "HTTP secara default menggunakan port 80"
            );

            csvPrinter.printRecord(
                "Apa fungsi dari DNS?",
                "Mengenkripsi data",
                "Menerjemahkan nama domain ke IP Address",
                "Memblokir virus",
                "Mempercepat koneksi internet",
                "B",
                "Networking",
                "DNS (Domain Name System) berfungsi menerjemahkan nama domain menjadi IP Address"
            );

        } catch (IOException e) {
            return "Error generating template: " + e.getMessage();
        }

        return writer.toString();
    }

    /**
     * Parse boolean from string (true/false, yes/no, 1/0)
     */
    private boolean parseBoolean(String value, boolean defaultVal) {
        if (value == null || value.trim().isEmpty()) return defaultVal;
        String v = value.trim().toLowerCase();
        if ("true".equals(v) || "yes".equals(v) || "1".equals(v)) return true;
        if ("false".equals(v) || "no".equals(v) || "0".equals(v)) return false;
        return defaultVal;
    }

    /**
     * Import result for quiz import
     */
    public static class QuizImportResult {
        private int quizCount;
        private int questionCount;
        private String quizTitle;
        private List<String> errors;

        public QuizImportResult() {
            this.quizCount = 0;
            this.questionCount = 0;
            this.errors = new ArrayList<>();
        }

        public void incrementQuizCount() {
            this.quizCount++;
        }

        public void incrementQuestionCount() {
            this.questionCount++;
        }

        public void addError(String error) {
            this.errors.add(error);
        }

        public int getQuizCount() {
            return quizCount;
        }

        public int getQuestionCount() {
            return questionCount;
        }

        public String getQuizTitle() {
            return quizTitle;
        }

        public void setQuizTitle(String quizTitle) {
            this.quizTitle = quizTitle;
        }

        public List<String> getErrors() {
            return errors;
        }

        public boolean hasErrors() {
            return !errors.isEmpty();
        }
    }
}
