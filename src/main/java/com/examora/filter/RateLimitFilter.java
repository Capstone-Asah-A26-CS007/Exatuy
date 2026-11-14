package com.examora.filter;

import com.examora.util.RateLimiter;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Global Rate Limit Filter - Protects all endpoints from abuse
 */
@WebFilter("/*")
public class RateLimitFilter implements Filter {

    // Rate limits per endpoint type
    private static final int GENERAL_REQUESTS_PER_MINUTE = 100;    // General browsing
    private static final int AUTH_REQUESTS_PER_MINUTE = 10;        // Login/Register
    private static final int API_REQUESTS_PER_MINUTE = 60;         // API calls
    private static final int SUBMIT_REQUESTS_PER_MINUTE = 20;      // Form submissions
    private static final int CHAT_REQUESTS_PER_MINUTE = 20;        // Chat messages
    private static final int QUIZ_ANSWER_PER_MINUTE = 120;         // Quiz answer saving (higher limit)

    // Store for request counts: key = IP + endpoint, value = RequestCounter
    private static final Map<String, RequestCounter> requestStore = new ConcurrentHashMap<>();

    // Cleanup interval
    private static final long WINDOW_SIZE_MS = 60 * 1000; // 1 minute window
    private static final int CLEANUP_INTERVAL = 500;
    private static AtomicInteger cleanupCounter = new AtomicInteger(0);

    /**
     * Inner class to track request counts
     */
    private static class RequestCounter {
        AtomicInteger count = new AtomicInteger(0);
        long windowStart = System.currentTimeMillis();

        synchronized boolean incrementAndCheck(int limit) {
            long now = System.currentTimeMillis();

            // Reset window if expired
            if (now - windowStart > WINDOW_SIZE_MS) {
                count.set(0);
                windowStart = now;
            }

            return count.incrementAndGet() > limit;
        }

        synchronized boolean isExpired() {
            return System.currentTimeMillis() - windowStart > WINDOW_SIZE_MS * 2;
        }
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String clientIp = getClientIp(httpRequest);
        String uri = httpRequest.getRequestURI();
        String method = httpRequest.getMethod();
        String action = httpRequest.getParameter("action");

        // Skip static resources
        if (isStaticResource(uri)) {
            chain.doFilter(request, response);
            return;
        }

        // Skip rate limit for saveAnswer - quiz answers need to be saved quickly
        // But still apply a higher limit to prevent abuse
        if ("saveAnswer".equals(action) && isQuizEndpoint(uri)) {
            String key = clientIp + ":quizAnswer";
            RequestCounter counter = requestStore.computeIfAbsent(key, k -> new RequestCounter());

            if (counter.incrementAndCheck(QUIZ_ANSWER_PER_MINUTE)) {
                httpResponse.setStatus(429);
                httpResponse.setContentType("application/json");
                httpResponse.setCharacterEncoding("UTF-8");
                httpResponse.getWriter().write("{\"success\":false,\"error\":\"Terlalu banyak permintaan. Silakan tunggu sebentar.\",\"code\":429}");
                return;
            }

            chain.doFilter(request, response);
            return;
        }

        // Determine rate limit based on endpoint
        int limit = getRateLimitForEndpoint(uri, method, action);
        String key = clientIp + ":" + getEndpointType(uri, method, action);

        // Periodic cleanup
        if (cleanupCounter.incrementAndGet() % CLEANUP_INTERVAL == 0) {
            cleanup();
        }

        // Check rate limit
        RequestCounter counter = requestStore.computeIfAbsent(key, k -> new RequestCounter());

        if (counter.incrementAndCheck(limit)) {
            // Rate limit exceeded
            httpResponse.setStatus(429);
            httpResponse.setContentType("application/json");
            httpResponse.setCharacterEncoding("UTF-8");
            httpResponse.getWriter().write("{\"success\":false,\"error\":\"Terlalu banyak permintaan. Silakan coba lagi nanti.\",\"code\":429}");
            return;
        }

        chain.doFilter(request, response);
    }

    /**
     * Check if endpoint is quiz-related
     */
    private boolean isQuizEndpoint(String uri) {
        return uri.contains("QuizServlet") || uri.contains("ExamServlet") || uri.contains("ArenaServlet");
    }

    /**
     * Get rate limit based on endpoint
     */
    private int getRateLimitForEndpoint(String uri, String method, String action) {
        // Authentication endpoints - stricter limit
        if (uri.contains("LoginServlet") || uri.contains("RegisterServlet")) {
            return AUTH_REQUESTS_PER_MINUTE;
        }

        // Chat endpoints
        if (uri.contains("ChatServlet")) {
            return CHAT_REQUESTS_PER_MINUTE;
        }

        // Quiz submit (not saveAnswer) - stricter limit
        if ("POST".equalsIgnoreCase(method) && isQuizEndpoint(uri)) {
            if ("submit".equals(action)) {
                return SUBMIT_REQUESTS_PER_MINUTE;
            }
            // For other quiz POST operations (like saveAnswer which is handled above)
            return QUIZ_ANSWER_PER_MINUTE;
        }

        // Form submissions - stricter limit
        if ("POST".equalsIgnoreCase(method)) {
            return SUBMIT_REQUESTS_PER_MINUTE;
        }

        // API endpoints
        if (uri.contains("/api/") || (uri.contains("Servlet") && action != null)) {
            return API_REQUESTS_PER_MINUTE;
        }

        // General browsing
        return GENERAL_REQUESTS_PER_MINUTE;
    }

    /**
     * Get endpoint type for grouping
     */
    private String getEndpointType(String uri, String method, String action) {
        if (uri.contains("LoginServlet") || uri.contains("RegisterServlet")) {
            return "auth";
        }
        if (uri.contains("ChatServlet")) {
            return "chat";
        }
        if (isQuizEndpoint(uri)) {
            if ("saveAnswer".equals(action)) {
                return "quizAnswer";
            }
            if ("submit".equals(action)) {
                return "quizSubmit";
            }
            return "quiz";
        }
        if ("POST".equalsIgnoreCase(method)) {
            return "post";
        }
        if ("GET".equalsIgnoreCase(method)) {
            return "get";
        }
        return "other";
    }

    /**
     * Check if request is for static resource
     */
    private boolean isStaticResource(String uri) {
        return uri.contains("/assets/") ||
               uri.contains("/css/") ||
               uri.contains("/js/") ||
               uri.contains("/images/") ||
               uri.endsWith(".css") ||
               uri.endsWith(".js") ||
               uri.endsWith(".png") ||
               uri.endsWith(".jpg") ||
               uri.endsWith(".jpeg") ||
               uri.endsWith(".gif") ||
               uri.endsWith(".svg") ||
               uri.endsWith(".ico") ||
               uri.endsWith(".woff") ||
               uri.endsWith(".woff2") ||
               uri.endsWith(".ttf");
    }

    /**
     * Get client IP address
     */
    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("WL-Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }
        return ip;
    }

    /**
     * Cleanup expired records
     */
    private void cleanup() {
        requestStore.entrySet().removeIf(entry -> entry.getValue().isExpired());
    }

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // Initialization
    }

    @Override
    public void destroy() {
        requestStore.clear();
    }
}
