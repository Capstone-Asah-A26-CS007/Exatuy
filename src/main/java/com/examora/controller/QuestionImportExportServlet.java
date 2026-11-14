package com.examora.controller;

import com.examora.model.Question;
import com.examora.model.Quiz;
import com.examora.model.User;
import com.examora.service.QuestionImportExportService;
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
import java.io.OutputStream;
import java.util.List;

/**
 * Servlet for importing and exporting questions
 */
@WebServlet("/QuestionImportExportServlet")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,      // 1 MB
    maxFileSize = 1024 * 1024 * 10,       // 10 MB
    maxRequestSize = 1024 * 1024 * 20     // 20 MB
)
public class QuestionImportExportServlet extends HttpServlet {
    private QuestionImportExportService importExportService;
    private QuizService quizService;

    @Override
    public void init() throws ServletException {
        importExportService = new QuestionImportExportService();
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
                case "template":
                    downloadTemplate(request, response);
                    break;
                case "exportCSV":
                    exportCSV(request, response);
                    break;
                case "exportPDF":
                    exportPDF(request, response);
                    break;
                case "import":
                    showImportForm(request, response);
                    break;
                case "analytics":
                    showAnalytics(request, response);
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
                case "import":
                    importCSV(request, response);
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
     * Show import form
     */
    private void showImportForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String quizIdStr = request.getParameter("quizId");

        if (quizIdStr != null && !quizIdStr.isEmpty()) {
            try {
                Integer quizId = Integer.parseInt(quizIdStr);
                Quiz quiz = quizService.getQuizById(quizId);
                request.setAttribute("quiz", quiz);
            } catch (Exception e) {
                // Ignore
            }
        }

        request.getRequestDispatcher("/admin/question-import.jsp").forward(request, response);
    }

    /**
     * Import questions from CSV
     */
    private void importCSV(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String quizIdStr = request.getParameter("quizId");
        Integer quizId = null;

        if (quizIdStr != null && !quizIdStr.isEmpty()) {
            try {
                quizId = Integer.parseInt(quizIdStr);
            } catch (NumberFormatException e) {
                request.setAttribute("error", "ID Quiz tidak valid");
                showImportForm(request, response);
                return;
            }
        }

        try {
            Part filePart = request.getPart("csvFile");
            if (filePart == null || filePart.getSize() == 0) {
                request.setAttribute("error", "Pilih file CSV untuk diimport");
                showImportForm(request, response);
                return;
            }

            // Validate file type
            String fileName = getSubmittedFileName(filePart);
            if (!fileName.toLowerCase().endsWith(".csv")) {
                request.setAttribute("error", "File harus berformat CSV");
                showImportForm(request, response);
                return;
            }

            try (InputStream inputStream = filePart.getInputStream()) {
                QuestionImportExportService.ImportResult result = importExportService.importFromCSV(inputStream, quizId);

                if (result.hasErrors()) {
                    request.setAttribute("warnings", result.getErrors());
                }

                if (result.getSuccessCount() > 0) {
                    request.setAttribute("success", result.getSuccessCount() + " soal berhasil diimport");
                } else if (!result.hasErrors()) {
                    request.setAttribute("error", "Tidak ada soal yang berhasil diimport");
                }
            }

            // Keep quiz attribute for form
            if (quizId != null) {
                try {
                    Quiz quiz = quizService.getQuizById(quizId);
                    request.setAttribute("quiz", quiz);
                } catch (Exception e) {
                    // Ignore
                }
            }

            request.getRequestDispatcher("/admin/question-import.jsp").forward(request, response);

        } catch (Exception e) {
            request.setAttribute("error", "Error importing CSV: " + e.getMessage());
            showImportForm(request, response);
        }
    }

    /**
     * Download CSV template
     */
    private void downloadTemplate(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String csvContent = importExportService.generateCSVTemplate();

        response.setContentType("text/csv");
        response.setHeader("Content-Disposition", "attachment; filename=\"template_soal.csv\"");
        response.setCharacterEncoding("UTF-8");

        // Add BOM for Excel compatibility
        response.getOutputStream().write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
        response.getOutputStream().write(csvContent.getBytes("UTF-8"));
        response.getOutputStream().flush();
    }

    /**
     * Export questions to CSV
     */
    private void exportCSV(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String quizIdStr = request.getParameter("quizId");
        List<Question> questions;

        try {
            if (quizIdStr != null && !quizIdStr.isEmpty()) {
                Integer quizId = Integer.parseInt(quizIdStr);
                questions = quizService.getQuestions(quizId);
            } else {
                request.setAttribute("error", "Quiz ID diperlukan untuk export");
                response.sendRedirect(request.getContextPath() + "/QuizServlet?action=list");
                return;
            }

            String csvContent = importExportService.exportToCSV(questions);

            response.setContentType("text/csv");
            response.setHeader("Content-Disposition", "attachment; filename=\"soal_export.csv\"");
            response.setCharacterEncoding("UTF-8");

            // Add BOM for Excel compatibility
            response.getOutputStream().write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
            response.getOutputStream().write(csvContent.getBytes("UTF-8"));
            response.getOutputStream().flush();

        } catch (Exception e) {
            request.setAttribute("error", "Error exporting CSV: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/QuizServlet?action=list");
        }
    }

    /**
     * Export questions to PDF
     */
    private void exportPDF(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String quizIdStr = request.getParameter("quizId");
        List<Question> questions;
        String title = "Daftar Soal";

        try {
            if (quizIdStr != null && !quizIdStr.isEmpty()) {
                Integer quizId = Integer.parseInt(quizIdStr);
                Quiz quiz = quizService.getQuizById(quizId);
                questions = quizService.getQuestions(quizId);
                title = "Soal: " + quiz.getTitle();
            } else {
                request.setAttribute("error", "Quiz ID diperlukan untuk export");
                response.sendRedirect(request.getContextPath() + "/QuizServlet?action=list");
                return;
            }

            byte[] pdfContent = importExportService.exportToPDF(questions, title);

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=\"soal_export.pdf\"");
            response.setContentLength(pdfContent.length);

            OutputStream out = response.getOutputStream();
            out.write(pdfContent);
            out.flush();

        } catch (Exception e) {
            request.setAttribute("error", "Error exporting PDF: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/QuizServlet?action=list");
        }
    }

    /**
     * Show question analytics
     */
    private void showAnalytics(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String quizIdStr = request.getParameter("quizId");

        try {
            if (quizIdStr != null && !quizIdStr.isEmpty()) {
                Integer quizId = Integer.parseInt(quizIdStr);
                Quiz quiz = quizService.getQuizById(quizId);
                request.setAttribute("quiz", quiz);
            }

            request.getRequestDispatcher("/admin/question-analytics.jsp").forward(request, response);

        } catch (Exception e) {
            request.setAttribute("error", "Error: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + "/QuizServlet?action=list");
        }
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
