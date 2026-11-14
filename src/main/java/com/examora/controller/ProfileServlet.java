package com.examora.controller;

import com.examora.dao.SettingsDAO;
import com.examora.model.User;
import com.examora.service.AuditService;
import com.examora.service.UserService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Profile Servlet - Handles user profile and password management
 */
@WebServlet("/ProfileServlet")
public class ProfileServlet extends HttpServlet {
    private UserService userService;
    private AuditService auditService;
    private SettingsDAO settingsDAO;

    @Override
    public void init() throws ServletException {
        userService = new UserService();
        auditService = new AuditService();
        settingsDAO = new SettingsDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/LoginServlet");
            return;
        }

        User currentUser = (User) session.getAttribute("user");

        // Refresh user data from database
        try {
            User freshUser = userService.getUserById(currentUser.getId());
            request.setAttribute("userProfile", freshUser);
        } catch (UserService.ServiceException e) {
            request.setAttribute("error", "Gagal memuat data profil: " + e.getMessage());
            request.setAttribute("userProfile", currentUser);
        }

        // Check if chat is enabled for navbar
        request.setAttribute("chatEnabled", settingsDAO.isChatEnabled());

        request.getRequestDispatcher("/user/profile.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/LoginServlet");
            return;
        }

        User currentUser = (User) session.getAttribute("user");
        String action = request.getParameter("action");

        if ("changePassword".equals(action)) {
            handleChangePassword(request, response, currentUser);
        } else {
            doGet(request, response);
        }
    }

    private void handleChangePassword(HttpServletRequest request, HttpServletResponse response, User currentUser)
            throws ServletException, IOException {
        String oldPassword = request.getParameter("oldPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        // Validate inputs
        if (oldPassword == null || oldPassword.trim().isEmpty()) {
            request.setAttribute("error", "Password lama harus diisi");
            doGet(request, response);
            return;
        }

        if (newPassword == null || newPassword.trim().isEmpty()) {
            request.setAttribute("error", "Password baru harus diisi");
            doGet(request, response);
            return;
        }

        if (confirmPassword == null || confirmPassword.trim().isEmpty()) {
            request.setAttribute("error", "Konfirmasi password harus diisi");
            doGet(request, response);
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("error", "Password baru dan konfirmasi tidak cocok");
            doGet(request, response);
            return;
        }

        if (newPassword.length() < 6) {
            request.setAttribute("error", "Password baru minimal 6 karakter");
            doGet(request, response);
            return;
        }

        try {
            userService.changePassword(currentUser.getId(), oldPassword, newPassword);

            // Audit log
            try {
                auditService.log("PASSWORD_CHANGE", "user", currentUser.getId(),
                    currentUser.getEmail(), null, currentUser, request);
            } catch (Exception auditEx) {
                System.err.println("Warning: Failed to log audit: " + auditEx.getMessage());
            }

            request.setAttribute("success", "Password berhasil diubah");

        } catch (UserService.ServiceException e) {
            request.setAttribute("error", e.getMessage());
        }

        doGet(request, response);
    }
}
