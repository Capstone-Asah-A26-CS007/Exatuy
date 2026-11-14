package com.examora.controller;

import com.examora.dao.SettingsDAO;
import com.examora.model.User;
import com.examora.service.UserService;
import com.examora.util.ValidationUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Register Servlet - Handles user registration with input validation
 */
@WebServlet("/RegisterServlet")
public class RegisterServlet extends HttpServlet {
    private UserService userService;
    private SettingsDAO settingsDAO;

    @Override
    public void init() throws ServletException {
        userService = new UserService();
        settingsDAO = new SettingsDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session != null && session.getAttribute("user") != null) {
            User user = (User) session.getAttribute("user");
            if (user.isAdmin()) {
                response.sendRedirect(request.getContextPath() + "/admin/dashboard.jsp");
            } else {
                response.sendRedirect(request.getContextPath() + "/user/dashboard.jsp");
            }
            return;
        }

        // Check if registration is enabled
        if (!settingsDAO.isRegistrationEnabled()) {
            response.sendRedirect(request.getContextPath() + "/LoginServlet?error=registration_disabled");
            return;
        }

        request.getRequestDispatcher("/common/register.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Check if registration is enabled
        if (!settingsDAO.isRegistrationEnabled()) {
            response.sendRedirect(request.getContextPath() + "/LoginServlet?error=registration_disabled");
            return;
        }

        String name = ValidationUtil.trim(request.getParameter("name"));
        String email = ValidationUtil.trim(request.getParameter("email"));
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");

        // Validate name
        if (!ValidationUtil.isValidName(name)) {
            request.setAttribute("error", "Nama tidak valid (hanya huruf, spasi, titik, dan tanda hubung, maks 100 karakter)");
            forwardWithError(request, response, name, email);
            return;
        }

        // Validate email
        if (!ValidationUtil.isValidEmail(email)) {
            request.setAttribute("error", "Format email tidak valid: \"" + (email == null ? "" : email.trim())
                    + "\". Gunakan format nama@domain.com (contoh: budi@gmail.com)");
            forwardWithError(request, response, name, email);
            return;
        }

        // Validate password
        ValidationUtil.PasswordStrength passwordStrength = ValidationUtil.checkPasswordStrength(password);
        if (!passwordStrength.isValid()) {
            request.setAttribute("error", passwordStrength.getFeedback());
            forwardWithError(request, response, name, email);
            return;
        }

        // Check password confirmation
        if (!password.equals(confirmPassword)) {
            request.setAttribute("error", "Konfirmasi password tidak cocok");
            forwardWithError(request, response, name, email);
            return;
        }

        // Check for potential attacks
        ValidationUtil.ValidationResult nameValidation = ValidationUtil.validateSafeInput(name, "Nama", 100);
        if (!nameValidation.isValid()) {
            request.setAttribute("error", nameValidation.getErrorMessage());
            forwardWithError(request, response, name, email);
            return;
        }

        try {
            User user = userService.register(name, email, password, "peserta");

            HttpSession session = request.getSession(true);
            session.setAttribute("user", user);
            session.setAttribute("userId", user.getId());
            session.setAttribute("userName", user.getName());
            session.setAttribute("userRole", user.getRole());
            session.setAttribute("csrfToken", com.examora.util.PasswordUtil.generateToken());

            response.sendRedirect(request.getContextPath() + "/user/dashboard.jsp");

        } catch (UserService.ServiceException e) {
            request.setAttribute("error", e.getMessage());
            forwardWithError(request, response, name, email);
        }
    }

    private void forwardWithError(HttpServletRequest request, HttpServletResponse response, String name, String email)
            throws ServletException, IOException {
        request.setAttribute("name", name);
        request.setAttribute("email", email);
        request.getRequestDispatcher("/common/register.jsp").forward(request, response);
    }
}
