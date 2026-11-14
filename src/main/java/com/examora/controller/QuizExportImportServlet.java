package com.examora.controller;

import com.examora.model.Question;
import com.examora.model.Quiz;
import com.examora.model.User;
import com.examora.service.QuizExportImportService;
import com.examora.service.QuizExportImportService.QuizImportResult;
import com.examora.service.QuizService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;

/**
 * Servlet for importing and exporting complete quizzes (metadata + questions)
 */
@WebServlet("/QuizExportImportServlet")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,      // 1 MB
    maxFileSize = 1024 * 1024 * 10,       // 10 MB
    maxRequestSize = 1024 * 1024 * 20     // 20 MB
)
public class QuizExportImportServlet extends HttpServlet {
    private QuizExportImportService exportImportService;
    private QuizService quizService;

    @Override
    public void init() throws ServletException {
        exportImportService = new QuizExportImportService();
        quizService = new QuizService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = (User) request.getSession().getAttribute("user");
        if (user == null || !user.isAdmin()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return;
        }

        String action = request.getParameter("action");

        try {
            switch (action != null ? action : "") {
                case "export":
                    exportQuiz(request, response);
                    break;
                case "importForm":
                    showImportForm(request, response);
                    break;
                case "template":
                    downloadTemplate(request, response);
                    break;
                default:
                    response.sendRedirect(request.getContextPath() + "/QuizServlet?action=list");
            }
        } catch (Exception e) {
            request.setAttribute("error", "Error: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/QuizServlet?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = (User) request.getSession().getAttribute("user");
        if (user == null || !user.isAdmin()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return;
        }

        String action = request.getParameter("action");

        try {
            switch (action != null ? action : "") {
                case "importQuiz":
                    importQuiz(request, response);
                    break;
                default:
                    response.sendRedirect(request.getContextPath() + "/QuizServlet?action=list");
            }
        } catch (Exception e) {
            request.setAttribute("error", "Error: " + e.getMessage());
            showImportForm(request, response);
        }
    }

    /**
     * Export quiz with questions to CSV
     */
    private void exportQuiz(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");

        try {
            if (idStr == null || idStr.isEmpty()) {
                response.sendRedirect(request.getContextPath() + "/QuizServlet?action=list");
                return;
            }

            Integer quizId = Integer.parseInt(idStr);
            Quiz quiz = quizService.getQuizById(quizId);
            List<Question> questions = quizService.getQuestions(quizId);

            String csvContent = exportImportService.exportQuizToCSV(quiz, questions);

            // Sanitize filename
            String safeTitle = quiz.getTitle()
                .replaceAll("[^a-zA-Z0-9\\s\\-_.]", "")
                .replaceAll("\\s+", "_")
                .toLowerCase();

            response.setContentType("text/csv");
            response.setHeader("Content-Disposition",
                "attachment; filename=\"quiz_" + safeTitle + ".csv\"");
            response.setCharacterEncoding("UTF-8");

            // BOM for Excel compatibility
            response.getOutputStream().write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
            response.getOutputStream().write(csvContent.getBytes("UTF-8"));
            response.getOutputStream().flush();

        } catch (Exception e) {
            request.setAttribute("error", "Error exporting quiz: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/QuizServlet?action=list");
        }
    }

    /**
     * Show import form
     */
    private void showImportForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/admin/quiz-import.jsp").forward(request, response);
    }

    /**
     * Import quiz from CSV
     */
    private void importQuiz(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            Part filePart = request.getPart("csvFile");
            if (filePart == null || filePart.getSize() == 0) {
                request.setAttribute("error", "Pilih file CSV untuk diimport");
                showImportForm(request, response);
                return;
            }

            String fileName = getSubmittedFileName(filePart);
            if (!fileName.toLowerCase().endsWith(".csv")) {
                request.setAttribute("error", "File harus berformat CSV");
                showImportForm(request, response);
                return;
            }

            User currentUser = (User) request.getSession().getAttribute("user");
            Integer createdBy = currentUser != null ? currentUser.getId() : null;

            String importMode = request.getParameter("importMode");
            QuizImportResult result;

            try (InputStream inputStream = filePart.getInputStream()) {
                if ("questionsOnly".equals(importMode)) {
                    // Mode: CSV contains only questions (no #QUIZ# row), quiz metadata from form
                    String title = request.getParameter("quizTitle");
                    String description = request.getParameter("quizDescription");
                    int duration = 30;
                    try {
                        duration = Integer.parseInt(request.getParameter("quizDuration"));
                    } catch (NumberFormatException e) { /* use default */ }
                    String targetTag = request.getParameter("quizTargetTag");

                    result = exportImportService.importQuestionsOnly(
                        inputStream, createdBy, title, description, duration, targetTag);
                } else {
                    // Mode: CSV has #QUIZ# row (default)
                    result = exportImportService.importQuizFromCSV(inputStream, createdBy);
                }

                if (result.getQuizCount() > 0) {
                    StringBuilder msg = new StringBuilder();
                    msg.append("Quiz \"").append(result.getQuizTitle()).append("\" berhasil diimport dengan ");
                    msg.append(result.getQuestionCount()).append(" soal.");
                    request.setAttribute("success", msg.toString());

                    // Show question-level errors as warnings
                    if (result.hasErrors()) {
                        request.setAttribute("warnings", result.getErrors());
                    }
                } else if (result.hasErrors()) {
                    // Quiz creation failed — show first error as red alert
                    request.setAttribute("error", result.getErrors().get(0));
                    if (result.getErrors().size() > 1) {
                        request.setAttribute("warnings", result.getErrors().subList(1, result.getErrors().size()));
                    }
                } else {
                    request.setAttribute("error", "Tidak ada quiz yang berhasil diimport");
                }
            }

            request.getRequestDispatcher("/admin/quiz-import.jsp").forward(request, response);

        } catch (Exception e) {
            request.setAttribute("error", "Error importing quiz: " + e.getMessage());
            showImportForm(request, response);
        }
    }

    /**
     * Download blank CSV template
     */
    private void downloadTemplate(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String csvContent = exportImportService.generateTemplate();

        response.setContentType("text/csv");
        response.setHeader("Content-Disposition", "attachment; filename=\"template_quiz.csv\"");
        response.setCharacterEncoding("UTF-8");

        // BOM for Excel compatibility
        response.getOutputStream().write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
        response.getOutputStream().write(csvContent.getBytes("UTF-8"));
        response.getOutputStream().flush();
    }

    /**
     * Get submitted filename from Part
     */
    private String getSubmittedFileName(Part part) {
        String contentDisp = part.getHeader("content-disposition");
        if (contentDisp == null) return "";

        String[] items = contentDisp.split(";");
        for (String s : items) {
            s = s.trim();
            if (s.toLowerCase().startsWith("filename")) {
                int idx = s.indexOf("=");
                if (idx >= 0) {
                    String name = s.substring(idx + 1).trim();
                    if (name.startsWith("\"") && name.endsWith("\"")) {
                        name = name.substring(1, name.length() - 1);
                    }
                    return name;
                }
            }
        }
        return "";
    }
}
