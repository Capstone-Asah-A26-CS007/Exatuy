package com.examora.controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * FileServlet - Serves uploaded files from external directory
 * This allows files to persist across server redeployments
 */
@WebServlet("/uploads/*")
public class FileServlet extends HttpServlet {

    // Base directory for uploads (mounted volume in Docker)
    private static final String UPLOAD_BASE_DIR = "/app/uploads";

    // Allowed subdirectories for security
    private static final String[] ALLOWED_DIRS = {"questions", "photos", "signatures"};

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();

        if (pathInfo == null || pathInfo.equals("/") || pathInfo.isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid file path");
            return;
        }

        // Remove leading slash and get file path
        String relativePath = pathInfo.substring(1);

        // Security: prevent path traversal attacks
        if (relativePath.contains("..") || relativePath.contains("//") || relativePath.contains("\\")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return;
        }

        // Extract subdirectory (e.g., "questions" or "photos")
        String subDir = relativePath.contains("/") ? relativePath.substring(0, relativePath.indexOf("/")) : "";

        // Validate subdirectory is allowed
        boolean validDir = false;
        for (String allowed : ALLOWED_DIRS) {
            if (allowed.equals(subDir)) {
                validDir = true;
                break;
            }
        }

        if (!validDir) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return;
        }

        // Build full file path
        Path filePath = Paths.get(UPLOAD_BASE_DIR, relativePath);

        // Security: ensure the resolved path is still within our upload directory
        Path basePath = Paths.get(UPLOAD_BASE_DIR).normalize();
        Path resolvedPath = filePath.normalize();

        if (!resolvedPath.startsWith(basePath)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return;
        }

        File file = resolvedPath.toFile();

        // Check if file exists and is a file (not directory)
        if (!file.exists() || !file.isFile()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND, "File not found");
            return;
        }

        // Determine content type
        String contentType = getServletContext().getMimeType(file.getName());
        if (contentType == null) {
            contentType = "application/octet-stream";
        }

        // Set response headers
        response.setContentType(contentType);
        response.setContentLengthLong(file.length());
        response.setHeader("Cache-Control", "public, max-age=31536000"); // Cache for 1 year

        // Copy file to response output stream
        Files.copy(file.toPath(), response.getOutputStream());
    }
}
