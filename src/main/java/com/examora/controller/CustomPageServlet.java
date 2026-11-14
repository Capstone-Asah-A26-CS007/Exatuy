package com.examora.controller;

import com.examora.dao.CustomPageDAO;
import com.examora.model.CustomPage;
import com.examora.model.User;
import com.examora.service.UserService;
import com.google.gson.Gson;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

/**
 * CustomPage Servlet - Handles admin CRUD for custom menu links
 */
@WebServlet("/CustomPageServlet")
public class CustomPageServlet extends HttpServlet {

    private CustomPageDAO customPageDAO;
    private UserService userService;

    @Override
    public void init() throws ServletException {
        customPageDAO = new CustomPageDAO();
        userService = new UserService();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Check admin access
        User user = (User) request.getSession().getAttribute("user");
        if (user == null || !user.isAdmin()) {
            response.sendRedirect(request.getContextPath() + "/LoginServlet");
            return;
        }

        String action = request.getParameter("action");

        try {
            if ("list".equals(action) || action == null) {
                listPages(request, response);
            } else if ("getDetail".equals(action)) {
                getPageDetail(request, response);
            } else {
                listPages(request, response);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Error: " + e.getMessage());
            request.getRequestDispatcher("/admin/custompages.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Check admin access
        User user = (User) request.getSession().getAttribute("user");
        if (user == null || !user.isAdmin()) {
            response.sendRedirect(request.getContextPath() + "/LoginServlet");
            return;
        }

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");

        try {
            if ("create".equals(action)) {
                createPage(request, response);
            } else if ("update".equals(action)) {
                updatePage(request, response);
            } else if ("delete".equals(action)) {
                deletePage(request, response);
            } else if ("toggleStatus".equals(action)) {
                toggleStatus(request, response);
            } else {
                listPages(request, response);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Error: " + e.getMessage());
            listPages(request, response);
        }
    }

    private void listPages(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            List<CustomPage> pages = customPageDAO.findAll();
            request.setAttribute("customPages", pages);
        } catch (Exception e) {
            request.setAttribute("error", "Gagal memuat data halaman: " + e.getMessage());
        }
        // Load all tags for the target-tag dropdown (fail-safe to empty list)
        List<String> allTags;
        try {
            allTags = userService.getAllTags();
        } catch (Exception e) {
            allTags = new ArrayList<>();
        }
        request.setAttribute("allTags", allTags);
        request.getRequestDispatcher("/admin/custompages.jsp").forward(request, response);
    }

    private void createPage(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String menuName = request.getParameter("menuName");
        String menuLink = request.getParameter("menuLink");
        String icon = request.getParameter("icon");
        String sortOrderStr = request.getParameter("sortOrder");
        String targetTag = request.getParameter("targetTag");
        String adminComment = request.getParameter("adminComment");

        if (menuName == null || menuName.trim().isEmpty()) {
            request.setAttribute("error", "Nama menu tidak boleh kosong");
            listPages(request, response);
            return;
        }
        if (menuLink == null || menuLink.trim().isEmpty()) {
            request.setAttribute("error", "Link menu tidak boleh kosong");
            listPages(request, response);
            return;
        }

        try {
            CustomPage page = new CustomPage();
            page.setMenuName(menuName.trim());
            page.setMenuLink(menuLink.trim());
            page.setIcon(icon != null ? icon.trim() : "");
            page.setIsActive(true);
            page.setSortOrder(sortOrderStr != null && !sortOrderStr.isEmpty() ? Integer.parseInt(sortOrderStr) : 0);
            page.setTargetTag(targetTag);
            page.setAdminComment(adminComment);

            customPageDAO.create(page);
            request.setAttribute("success", "Menu \"" + menuName + "\" berhasil ditambahkan");
        } catch (Exception e) {
            request.setAttribute("error", "Gagal menambahkan menu: " + e.getMessage());
        }
        listPages(request, response);
    }

    private void updatePage(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        String menuName = request.getParameter("menuName");
        String menuLink = request.getParameter("menuLink");
        String icon = request.getParameter("icon");
        String sortOrderStr = request.getParameter("sortOrder");
        String targetTag = request.getParameter("targetTag");
        String adminComment = request.getParameter("adminComment");

        if (idStr == null || idStr.isEmpty()) {
            request.setAttribute("error", "ID tidak valid");
            listPages(request, response);
            return;
        }
        if (menuName == null || menuName.trim().isEmpty()) {
            request.setAttribute("error", "Nama menu tidak boleh kosong");
            listPages(request, response);
            return;
        }
        if (menuLink == null || menuLink.trim().isEmpty()) {
            request.setAttribute("error", "Link menu tidak boleh kosong");
            listPages(request, response);
            return;
        }

        try {
            Integer id = Integer.parseInt(idStr);
            CustomPage page = customPageDAO.findById(id);
            if (page == null) {
                request.setAttribute("error", "Menu tidak ditemukan");
                listPages(request, response);
                return;
            }

            page.setMenuName(menuName.trim());
            page.setMenuLink(menuLink.trim());
            page.setIcon(icon != null ? icon.trim() : "");
            page.setSortOrder(sortOrderStr != null && !sortOrderStr.isEmpty() ? Integer.parseInt(sortOrderStr) : 0);
            page.setTargetTag(targetTag);
            page.setAdminComment(adminComment);

            customPageDAO.update(page);
            request.setAttribute("success", "Menu berhasil diperbarui");
        } catch (Exception e) {
            request.setAttribute("error", "Gagal memperbarui menu: " + e.getMessage());
        }
        listPages(request, response);
    }

    private void deletePage(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");

        if (idStr == null || idStr.isEmpty()) {
            request.setAttribute("error", "ID tidak valid");
            listPages(request, response);
            return;
        }

        try {
            Integer id = Integer.parseInt(idStr);
            boolean deleted = customPageDAO.delete(id);
            if (deleted) {
                request.setAttribute("success", "Menu berhasil dihapus");
            } else {
                request.setAttribute("error", "Menu tidak ditemukan");
            }
        } catch (Exception e) {
            request.setAttribute("error", "Gagal menghapus menu: " + e.getMessage());
        }
        listPages(request, response);
    }

    private void toggleStatus(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");

        if (idStr == null || idStr.isEmpty()) {
            request.setAttribute("error", "ID tidak valid");
            listPages(request, response);
            return;
        }

        try {
            Integer id = Integer.parseInt(idStr);
            customPageDAO.toggleActive(id);
            request.setAttribute("success", "Status menu berhasil diubah");
        } catch (Exception e) {
            request.setAttribute("error", "Gagal mengubah status: " + e.getMessage());
        }
        listPages(request, response);
    }

    private void getPageDetail(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        try (PrintWriter out = response.getWriter()) {
            if (idStr == null || idStr.isEmpty()) {
                out.print("{\"error\":\"ID tidak valid\"}");
                return;
            }

            Integer id = Integer.parseInt(idStr);
            CustomPage page = customPageDAO.findById(id);
            if (page == null) {
                out.print("{\"error\":\"Menu tidak ditemukan\"}");
                return;
            }

            String json = new Gson().toJson(page);
            out.print(json);
        } catch (Exception e) {
            response.setStatus(500);
            try (PrintWriter out = response.getWriter()) {
                out.print("{\"error\":\"" + e.getMessage() + "\"}");
            }
        }
    }
}
