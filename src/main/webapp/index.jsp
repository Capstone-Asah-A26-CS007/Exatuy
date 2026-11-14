<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.dao.SettingsDAO" %>
<%
    User user = (User) session.getAttribute("user");
    String redirectUrl = "";
    if (user != null) {
        redirectUrl = user.isAdmin() ? "admin/dashboard.jsp" : "user/dashboard.jsp";
        response.sendRedirect(redirectUrl);
        return;
    }

    // Check if registration is enabled
    SettingsDAO settingsDAO = new SettingsDAO();
    boolean registrationEnabled = settingsDAO.isRegistrationEnabled();
    pageContext.setAttribute("registrationEnabled", registrationEnabled);
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Exatuy - Platform Ujian Online Modern</title>
    <meta name="description" content="Platform ujian online dengan fitur lengkap untuk kebutuhan asesmen modern dan evaluasi pembelajaran">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
    <link href="assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" href="assets/img/favicon.svg">

    <style>
        /* ===== ROOT VARIABLES ===== */
        :root {
            --primary: #6366f1;
            --primary-dark: #4f46e5;
            --primary-light: #818cf8;
            --secondary: #06b6d4;
            --accent: #f43f5e;
            --success: #10b981;
            --warning: #f59e0b;
            --dark: #0f172a;
            --gray: #64748b;
            --light: #f8fafc;
            --white: #ffffff;
            --gradient-primary: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
            --gradient-secondary: linear-gradient(135deg, #06b6d4 0%, #3b82f6 100%);
            --gradient-accent: linear-gradient(135deg, #f43f5e 0%, #f97316 100%);
            --shadow-sm: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.24);
            --shadow-md: 0 4px 6px rgba(0,0,0,0.16), 0 2px 4px rgba(0,0,0,0.23);
            --shadow-lg: 0 10px 40px rgba(0,0,0,0.15);
            --shadow-xl: 0 20px 60px rgba(0,0,0,0.25);
        }

        /* ===== RESET & BASE ===== */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            overflow-x: hidden;
            color: var(--dark);
            background: var(--white);
            line-height: 1.6;
        }

        /* ===== NAVBAR ===== */
        .navbar {
            background: transparent;
            padding: 1.25rem 0;
            transition: all 0.4s ease;
            position: fixed;
            width: 100%;
            top: 0;
            z-index: 1000;
        }

        .navbar.scrolled {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            box-shadow: var(--shadow-sm);
            padding: 0.875rem 0;
        }

        .navbar-brand {
            font-weight: 800;
            font-size: 1.5rem;
            display: flex;
            align-items: center;
            gap: 0.75rem;
            background: linear-gradient(135deg, #4A90D9, #7BC67E);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .navbar-brand .brand-icon {
            width: 42px;
            height: 42px;
            background: var(--gradient-primary);
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.25rem;
            box-shadow: 0 4px 15px rgba(99, 102, 241, 0.4);
        }

        .nav-link {
            color: rgba(15, 23, 42, 0.85) !important;
            font-weight: 600;
            padding: 0.625rem 1.25rem !important;
            position: relative;
            transition: all 0.3s ease;
        }

        .nav-link::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 50%;
            width: 0;
            height: 2px;
            background: var(--primary);
            transition: all 0.3s ease;
            transform: translateX(-50%);
        }

        .nav-link:hover::after {
            width: 70%;
        }

        .nav-link:hover {
            color: var(--primary) !important;
        }

        .btn-login {
            background: var(--gradient-primary);
            border: none;
            color: white;
            font-weight: 600;
            padding: 0.625rem 1.75rem;
            border-radius: 50px;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3);
        }

        .btn-login:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(99, 102, 241, 0.4);
            color: white;
        }

        .btn-register {
            background: white;
            border: 2px solid var(--primary);
            color: var(--primary);
            font-weight: 600;
            padding: 0.625rem 1.75rem;
            border-radius: 50px;
            transition: all 0.3s ease;
        }

        .btn-register:hover {
            background: var(--primary);
            border-color: var(--primary);
            color: white;
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(99, 102, 241, 0.3);
        }

        /* ===== HERO SECTION ===== */
        .hero {
            position: relative;
            min-height: 100vh;
            display: flex;
            align-items: center;
            background: linear-gradient(135deg, #f8fafc 0%, #e0e7ff 100%);
            overflow: hidden;
        }

        .hero-bg-shapes {
            position: absolute;
            inset: 0;
            overflow: hidden;
        }

        .hero-shape {
            position: absolute;
            border-radius: 50%;
            opacity: 0.6;
        }

        .hero-shape-1 {
            width: 600px;
            height: 600px;
            background: var(--gradient-primary);
            opacity: 0.1;
            top: -200px;
            right: -200px;
            filter: blur(80px);
        }

        .hero-shape-2 {
            width: 500px;
            height: 500px;
            background: var(--gradient-secondary);
            opacity: 0.1;
            bottom: -150px;
            left: -150px;
            filter: blur(80px);
        }

        .hero-shape-3 {
            width: 400px;
            height: 400px;
            background: var(--gradient-accent);
            opacity: 0.08;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            filter: blur(60px);
        }

        .hero-content {
            position: relative;
            z-index: 2;
            padding-top: 80px;
        }

        .hero-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1rem;
            background: white;
            border: 1px solid #e2e8f0;
            border-radius: 50px;
            font-size: 0.875rem;
            font-weight: 600;
            color: var(--primary);
            margin-bottom: 1.5rem;
            box-shadow: var(--shadow-sm);
        }

        .hero-badge .badge-icon {
            width: 20px;
            height: 20px;
            background: var(--gradient-primary);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 0.75rem;
        }

        .hero-title {
            font-size: clamp(2.5rem, 5vw, 4rem);
            font-weight: 800;
            line-height: 1.2;
            margin-bottom: 1.5rem;
            background: linear-gradient(135deg, var(--dark) 0%, var(--primary) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .hero-subtitle {
            font-size: clamp(1rem, 2vw, 1.25rem);
            color: var(--gray);
            margin-bottom: 2rem;
            max-width: 600px;
            line-height: 1.7;
        }

        .hero-buttons {
            display: flex;
            flex-wrap: wrap;
            gap: 1rem;
        }

        .hero-image {
            position: relative;
            z-index: 2;
        }

        .hero-card {
            background: white;
            border-radius: 24px;
            padding: 1.5rem;
            box-shadow: var(--shadow-xl);
            position: relative;
            overflow: hidden;
        }

        .hero-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background: var(--gradient-primary);
        }

        .hero-card-icon {
            width: 50px;
            height: 50px;
            background: var(--gradient-primary);
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.5rem;
            margin-bottom: 1rem;
        }

        .hero-card-title {
            font-weight: 700;
            font-size: 1.125rem;
            margin-bottom: 0.25rem;
        }

        .hero-card-text {
            font-size: 0.875rem;
            color: var(--gray);
        }

        .floating-card {
            background: white;
            border-radius: 16px;
            padding: 1rem;
            box-shadow: var(--shadow-lg);
            display: flex;
            align-items: center;
            gap: 0.75rem;
            position: absolute;
            animation: float 6s ease-in-out infinite;
        }

        .floating-card.gold {
            top: -20px;
            right: -20px;
        }

        .floating-card.success {
            bottom: -20px;
            left: -20px;
            animation-delay: 2s;
        }

        .floating-card-icon {
            width: 40px;
            height: 40px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1rem;
        }

        .floating-card.gold .floating-card-icon {
            background: linear-gradient(135deg, #fbbf24 0%, #f97316 100%);
        }

        .floating-card.success .floating-card-icon {
            background: linear-gradient(135deg, #10b981 0%, #06b6d4 100%);
        }

        .floating-card-content {
            flex: 1;
        }

        .floating-card-title {
            font-weight: 700;
            font-size: 0.875rem;
            color: var(--dark);
        }

        .floating-card-text {
            font-size: 0.75rem;
            color: var(--gray);
        }

        @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-10px); }
        }

        /* ===== FEATURES SECTION ===== */
        .features {
            padding: 6rem 0;
            background: white;
        }

        .section-header {
            text-align: center;
            margin-bottom: 4rem;
        }

        .section-label {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1rem;
            background: #f1f5f9;
            border-radius: 50px;
            font-size: 0.875rem;
            font-weight: 600;
            color: var(--primary);
            margin-bottom: 1rem;
        }

        .section-title {
            font-size: clamp(2rem, 4vw, 2.5rem);
            font-weight: 800;
            margin-bottom: 1rem;
            color: var(--dark);
        }

        .section-subtitle {
            font-size: 1.125rem;
            color: var(--gray);
            max-width: 600px;
            margin: 0 auto;
        }

        .feature-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
            gap: 2rem;
        }

        .feature-card {
            background: white;
            border-radius: 20px;
            padding: 2rem;
            border: 1px solid #f1f5f9;
            transition: all 0.4s ease;
            position: relative;
            overflow: hidden;
        }

        .feature-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: var(--gradient-primary);
            transform: scaleX(0);
            transition: transform 0.4s ease;
        }

        .feature-card:hover::before {
            transform: scaleX(1);
        }

        .feature-card:hover {
            transform: translateY(-8px);
            box-shadow: var(--shadow-xl);
            border-color: transparent;
        }

        .feature-icon {
            width: 65px;
            height: 65px;
            background: var(--gradient-primary);
            border-radius: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.75rem;
            margin-bottom: 1.5rem;
            box-shadow: 0 8px 20px rgba(99, 102, 241, 0.3);
        }

        .feature-card h5 {
            font-weight: 700;
            font-size: 1.25rem;
            margin-bottom: 0.75rem;
            color: var(--dark);
        }

        .feature-card p {
            color: var(--gray);
            margin-bottom: 1rem;
            line-height: 1.6;
        }

        .feature-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }

        .feature-list li {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            padding: 0.5rem 0;
            color: var(--gray);
            font-size: 0.9375rem;
        }

        .feature-list li i {
            color: var(--success);
            flex-shrink: 0;
        }

        /* ===== STATS SECTION ===== */
        .stats {
            padding: 6rem 0;
            background: linear-gradient(135deg, var(--dark) 0%, #1e293b 100%);
            position: relative;
            overflow: hidden;
        }

        .stats::before {
            content: '';
            position: absolute;
            inset: 0;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="1" fill="rgba(255,255,255,0.03)"/></svg>');
            background-size: 50px 50px;
        }

        .stat-item {
            text-align: center;
            padding: 2rem;
        }

        .stat-icon {
            width: 70px;
            height: 70px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--primary-light);
            font-size: 2rem;
            margin: 0 auto 1.5rem;
            backdrop-filter: blur(10px);
        }

        .stat-number {
            font-size: 3rem;
            font-weight: 800;
            color: white;
            margin-bottom: 0.5rem;
            line-height: 1;
        }

        .stat-label {
            font-size: 1rem;
            color: rgba(255, 255, 255, 0.8);
            font-weight: 500;
        }

        /* ===== CTA SECTION ===== */
        .cta {
            padding: 6rem 0;
            background: linear-gradient(135deg, #f8fafc 0%, #e0e7ff 100%);
            text-align: center;
        }

        .cta-card {
            background: white;
            border-radius: 24px;
            padding: 3rem;
            box-shadow: var(--shadow-xl);
            border: 1px solid #f1f5f9;
            max-width: 800px;
            margin: 0 auto;
        }

        .cta-title {
            font-size: 2rem;
            font-weight: 800;
            margin-bottom: 1rem;
            color: var(--dark);
        }

        .cta-text {
            font-size: 1.125rem;
            color: var(--gray);
            margin-bottom: 2rem;
        }

        .cta-buttons {
            display: flex;
            flex-wrap: wrap;
            gap: 1rem;
            justify-content: center;
        }

        .btn-primary-lg {
            background: var(--gradient-primary);
            border: none;
            color: white;
            font-weight: 600;
            padding: 1rem 2.5rem;
            border-radius: 50px;
            font-size: 1.125rem;
            transition: all 0.3s ease;
            box-shadow: 0 8px 25px rgba(99, 102, 241, 0.3);
        }

        .btn-primary-lg:hover {
            transform: translateY(-3px);
            box-shadow: 0 12px 35px rgba(99, 102, 241, 0.4);
            color: white;
        }

        .btn-outline-lg {
            background: transparent;
            border: 2px solid var(--primary);
            color: var(--primary);
            font-weight: 600;
            padding: 1rem 2.5rem;
            border-radius: 50px;
            font-size: 1.125rem;
            transition: all 0.3s ease;
        }

        .btn-outline-lg:hover {
            background: var(--primary);
            border-color: var(--primary);
            color: white;
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(99, 102, 241, 0.2);
        }

        /* ===== FOOTER ===== */
        .footer {
            background: var(--dark);
            padding: 4rem 0 2rem;
        }

        .footer-title {
            font-weight: 700;
            font-size: 1.125rem;
            color: white;
            margin-bottom: 1.5rem;
        }

        .footer-links {
            list-style: none;
            padding: 0;
        }

        .footer-links li {
            margin-bottom: 0.75rem;
        }

        .footer-links a {
            color: rgba(255, 255, 255, 0.7);
            text-decoration: none;
            transition: color 0.3s ease;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .footer-links a:hover {
            color: var(--primary-light);
        }

        .social-links {
            display: flex;
            gap: 0.75rem;
        }

        .social-link {
            width: 40px;
            height: 40px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            transition: all 0.3s ease;
        }

        .social-link:hover {
            background: var(--primary);
            transform: translateY(-3px);
        }

        .footer-bottom {
            border-top: 1px solid rgba(255, 255, 255, 0.1);
            padding-top: 2rem;
            margin-top: 2rem;
            text-align: center;
        }

        .footer-bottom p {
            color: rgba(255, 255, 255, 0.6);
            margin: 0;
        }

        /* ===== ANIMATIONS ===== */
        .reveal {
            opacity: 1;
            transform: none;
            transition: all 0.8s ease;
        }

        @media (prefers-reduced-motion: no-preference) {
            .reveal.hd-pending {
                opacity: 0;
                transform: translateY(30px);
            }
        }

        .reveal.active {
            opacity: 1;
            transform: translateY(0);
        }

        /* ===== RESPONSIVE ===== */
        @media (max-width: 768px) {
            .hero-content {
                text-align: center;
                padding-top: 120px;
            }

            .hero-buttons {
                justify-content: center;
            }

            .hero-image {
                margin-top: 3rem;
            }

            .section-title {
                font-size: 1.75rem;
            }

            .stat-number {
                font-size: 2rem;
            }
        }

        @media (max-width: 576px) {
            .navbar-brand span {
                font-size: 1.25rem;
            }

            .hero-title {
                font-size: 2rem;
            }

            .btn-login,
            .btn-register {
                padding: 0.5rem 1.25rem;
                font-size: 0.875rem;
            }
        }
    </style>
<link href="assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <!-- Navbar -->
    <nav class="navbar" id="navbar">
        <div class="container">
            <div class="d-flex justify-content-between align-items-center">
                <a class="navbar-brand" href="index.jsp">
                    <i class="bi bi-mortarboard-fill" style="font-size: 1.75rem; color: #4A90D9;"></i>
                    <span>Exatuy</span>
                </a>

                <div class="d-flex align-items-center gap-3">
                    <a href="LoginServlet" class="btn-login">Masuk</a>
                    <c:if test="${registrationEnabled}">
                        <a href="RegisterServlet" class="btn-register">Daftar</a>
                    </c:if>
                </div>
            </div>
        </div>
    </nav>

    <!-- Hero Section -->
    <section class="hero">
        <div class="hero-bg-shapes">
            <div class="hero-shape hero-shape-1"></div>
            <div class="hero-shape hero-shape-2"></div>
            <div class="hero-shape hero-shape-3"></div>
        </div>

        <div class="container">
            <div class="row align-items-center">
                <div class="col-lg-6 hero-content">
                    <div class="hero-badge reveal">
                        <span class="badge-icon">
                            <i class="bi bi-stars"></i>
                        </span>
                        Platform Belajar & Ujian Online
                    </div>

                    <h1 class="hero-title reveal">
                        Platform Belajar &amp; Ujian<br>untuk Semua Kalangan
                    </h1>

                    <p class="hero-subtitle reveal">
                        Solusi all-in-one untuk bimbingan belajar, sekolah, dan pelatihan.
                        Kelola siswa, tagihan SPP, presensi, materi, dan ujian dalam satu platform.
                    </p>

                    <div class="hero-buttons reveal">
                        <a href="LoginServlet" class="btn-primary-lg">
                            <i class="bi bi-rocket-takeoff me-2"></i>
                            Mulai Sekarang
                        </a>
                        <a href="#features" class="btn-outline-lg">
                            <i class="bi bi-info-circle me-2"></i>
                            Pelajari Lebih
                        </a>
                    </div>
                </div>

                <div class="col-lg-6 hero-image">
                    <div class="position-relative">
                        <!-- Hero Main Card -->
                        <div class="hero-card p-4 mb-4">
                            <div class="d-flex align-items-center gap-3">
                                <div class="hero-card-icon" style="background: linear-gradient(135deg, #4A90D9, #7BC67E);">
                                    <i class="bi bi-cash-stack"></i>
                                </div>
                                <div>
                                    <div class="hero-card-title">Tagihan Otomatis</div>
                                    <div class="hero-card-text">Invoice digital & pengingat pembayaran</div>
                                </div>
                            </div>
                        </div>

                        <!-- Stats Floating Cards -->
                        <div class="floating-card gold">
                            <div class="floating-card-icon">
                                <i class="bi bi-clipboard-check"></i>
                            </div>
                            <div class="floating-card-content">
                                <div class="floating-card-title">Presensi Digital</div>
                                <div class="floating-card-text">Auto-potong kuota</div>
                            </div>
                        </div>

                        <div class="floating-card success">
                            <div class="floating-card-icon">
                                <i class="bi bi-people"></i>
                            </div>
                            <div class="floating-card-content">
                                <div class="floating-card-title">Portal Orang Tua</div>
                                <div class="floating-card-text">Pantau anak real-time</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Features Section -->
    <section class="features" id="features">
        <div class="container">
            <div class="section-header reveal">
                <div class="section-label">
                    <i class="bi bi-sparkles"></i>
                    Fitur Unggulan
                </div>
                <h2 class="section-title">Semua yang Anda Butuhkan</h2>
                <p class="section-subtitle">Platform lengkap dengan berbagai fitur modern untuk memenuhi kebutuhan asesmen dan evaluasi pembelajaran.</p>
            </div>

            <div class="feature-grid">
                <!-- Tagihan & Kuota -->
                <div class="feature-card reveal">
                    <div class="feature-icon" style="background: linear-gradient(135deg, #4A90D9, #357ABD);">
                        <i class="bi bi-cash-stack"></i>
                    </div>
                    <h5>Tagihan & Kuota</h5>
                    <p>Sistem invoice otomatis dengan pengingat pembayaran dan tracker sisa sesi.</p>
                    <ul class="feature-list">
                        <li><i class="bi bi-check-circle-fill"></i>Paket sesi belajar</li>
                        <li><i class="bi bi-check-circle-fill"></i>Invoice digital</li>
                        <li><i class="bi bi-check-circle-fill"></i>Pengingat tagihan</li>
                        <li><i class="bi bi-check-circle-fill"></i>Tracking kuota</li>
                    </ul>
                </div>

                <!-- Presensi Digital -->
                <div class="feature-card reveal">
                    <div class="feature-icon" style="background: linear-gradient(135deg, #7BC67E, #5FB062);">
                        <i class="bi bi-clipboard-check"></i>
                    </div>
                    <h5>Presensi Digital</h5>
                    <p>Absensi mudah dengan kode unik dan auto-potong kuota saat siswa hadir.</p>
                    <ul class="feature-list">
                        <li><i class="bi bi-check-circle-fill"></i>Kode absensi unik</li>
                        <li><i class="bi bi-check-circle-fill"></i>Hadir/Izin/Sakit/Alpa</li>
                        <li><i class="bi bi-check-circle-fill"></i>Auto-potong kuota</li>
                        <li><i class="bi bi-check-circle-fill"></i>Export PDF/CSV</li>
                    </ul>
                </div>

                <!-- Bank Soal & CBT -->
                <div class="feature-card reveal">
                    <div class="feature-icon" style="background: linear-gradient(135deg, #F5A623, #E09000);">
                        <i class="bi bi-journal-text"></i>
                    </div>
                    <h5>Bank Soal & CBT</h5>
                    <p>Pre-test, post-test, koreksi otomatis, dan rapor nilai per siswa.</p>
                    <ul class="feature-list">
                        <li><i class="bi bi-check-circle-fill"></i>Soal pilihan ganda & esai</li>
                        <li><i class="bi bi-check-circle-fill"></i>Auto-grading</li>
                        <li><i class="bi bi-check-circle-fill"></i>Rapor nilai</li>
                        <li><i class="bi bi-check-circle-fill"></i>Analisis per soal</li>
                    </ul>
                </div>

                <!-- Portal Orang Tua -->
                <div class="feature-card reveal">
                    <div class="feature-icon" style="background: linear-gradient(135deg, #9B7ED8, #7B5CBF);">
                        <i class="bi bi-people"></i>
                    </div>
                    <h5>Portal Orang Tua</h5>
                    <p>Orang tua bisa pantau jadwal, presensi, dan nilai anak secara real-time.</p>
                    <ul class="feature-list">
                        <li><i class="bi bi-check-circle-fill"></i>Jadwal kelas anak</li>
                        <li><i class="bi bi-check-circle-fill"></i>Sisa kuota transparan</li>
                        <li><i class="bi bi-check-circle-fill"></i>Riwayat presensi</li>
                        <li><i class="bi bi-check-circle-fill"></i>Nilai ujian anak</li>
                    </ul>
                </div>

                <!-- Statistik & Laporan -->
                <div class="feature-card reveal">
                    <div class="feature-icon">
                        <i class="bi bi-graph-up"></i>
                    </div>
                    <h5>Statistik & Laporan</h5>
                    <p>Analisis performa siswa dengan chart dan export ke PDF/TXT.</p>
                    <ul class="feature-list">
                        <li><i class="bi bi-check-circle-fill"></i>Distribusi nilai</li>
                        <li><i class="bi bi-check-circle-fill"></i>Pass rate analysis</li>
                        <li><i class="bi bi-check-circle-fill"></i>Export laporan</li>
                        <li><i class="bi bi-check-circle-fill"></i>Filter berdasarkan tag</li>
                    </ul>
                </div>

                <!-- Keamanan -->
                <div class="feature-card reveal">
                    <div class="feature-icon">
                        <i class="bi bi-shield-check"></i>
                    </div>
                    <h5>Sistem Keamanan</h5>
                    <p>Keamanan tingkat enterprise untuk menjaga integritas data dan ujian.</p>
                    <ul class="feature-list">
                        <li><i class="bi bi-check-circle-fill"></i>Rate limiting</li>
                        <li><i class="bi bi-check-circle-fill"></i>CSRF protection</li>
                        <li><i class="bi bi-check-circle-fill"></i>BCrypt hashing</li>
                        <li><i class="bi bi-check-circle-fill"></i>Session security</li>
                    </ul>
                </div>
            </div>
        </div>
    </section>

    <!-- Stats Section -->
    <section class="stats">
        <div class="container">
            <div class="row g-4">
                <div class="col-md-3 col-6 reveal">
                    <div class="stat-item">
                        <div class="stat-icon">
                            <i class="bi bi-people"></i>
                        </div>
                        <div class="stat-number">500+</div>
                        <div class="stat-label">Siswa Aktif</div>
                    </div>
                </div>
                <div class="col-md-3 col-6 reveal">
                    <div class="stat-item">
                        <div class="stat-icon">
                            <i class="bi bi-journal-text"></i>
                        </div>
                        <div class="stat-number">1200+</div>
                        <div class="stat-label">Quiz Dibuat</div>
                    </div>
                </div>
                <div class="col-md-3 col-6 reveal">
                    <div class="stat-item">
                        <div class="stat-icon">
                            <i class="bi bi-building"></i>
                        </div>
                        <div class="stat-number">50+</div>
                        <div class="stat-label">Bimbel Bergabung</div>
                    </div>
                </div>
                <div class="col-md-3 col-6 reveal">
                    <div class="stat-item">
                        <div class="stat-icon">
                            <i class="bi bi-graph-up-arrow"></i>
                        </div>
                        <div class="stat-number">98%</div>
                        <div class="stat-label">Kepuasan</div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- CTA Section -->
    <section class="cta">
        <div class="container">
            <div class="cta-card reveal">
                <h2 class="cta-title">Siap Memudahkan Pengelolaan Les Anda?</h2>
                <p class="cta-text">Bergabung dengan ratusan lembaga pendidikan yang sudah menggunakan Exatuy.</p>
                <div class="cta-buttons">
                    <a href="LoginServlet" class="btn-primary-lg">
                        <i class="bi bi-box-arrow-in-right me-2"></i>
                        Mulai Sekarang
                    </a>
                    <a href="#features" class="btn-outline-lg">
                        <i class="bi bi-info-circle me-2"></i>
                        Pelajari Fitur
                    </a>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="footer">
        <div class="container">
            <div class="row">
                <div class="col-lg-4 mb-4">
                    <h6 class="footer-title">
                        <i class="bi bi-mortarboard-fill me-2" style="color: #4A90D9;"></i>
                        Exatuy
                    </h6>
                    <p style="color: rgba(255,255,255,0.7); margin-bottom: 1.5rem;">
                        Platform ujian online modern untuk kebutuhan asesmen dan evaluasi pembelajaran yang lengkap dan mudah digunakan.
                    </p>
                    <div class="social-links">
                        <a href="https://github.com/Re-xist/" class="social-link" title="GitHub" target="_blank">
                            <i class="bi bi-github"></i>
                        </a>
                    </div>
                </div>
                <div class="col-lg-2 col-md-4 mb-4">
                    <h6 class="footer-title">Navigasi</h6>
                    <ul class="footer-links">
                        <li><a href="#features"><i class="bi bi-chevron-right"></i> Fitur</a></li>
                        <li><a href="LoginServlet"><i class="bi bi-chevron-right"></i> Masuk</a></li>
                        <li><a href="RegisterServlet"><i class="bi bi-chevron-right"></i> Daftar</a></li>
                    </ul>
                </div>
                <div class="col-lg-3 col-md-4 mb-4">
                    <h6 class="footer-title">Fitur</h6>
                    <ul class="footer-links">
                        <li><a href="#features"><i class="bi bi-journal-text"></i> Quiz Online</a></li>
                        <li><a href="#features"><i class="bi bi-graph-up"></i> Statistik</a></li>
                        <li><a href="#features"><i class="bi bi-shield-check"></i> Keamanan</a></li>
                    </ul>
                </div>
            </div>
            <div class="footer-bottom">
                <p>&copy; 2024 <strong>Exatuy</strong>. All rights reserved.</p>
                <p>Dibuat dengan <i class="bi bi-heart-fill text-danger"></i> untuk pendidikan Indonesia</p>
            </div>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Navbar scroll effect
        const navbar = document.getElementById('navbar');
        window.addEventListener('scroll', () => {
            if (window.scrollY > 50) {
                navbar.classList.add('scrolled');
            } else {
                navbar.classList.remove('scrolled');
            }
        });

        // Scroll reveal animation
        const revealElements = document.querySelectorAll('.reveal');
        const revealOnScroll = () => {
            const windowHeight = window.innerHeight;
            revealElements.forEach(element => {
                const elementTop = element.getBoundingClientRect().top;
                if (elementTop < windowHeight - 100) {
                    element.classList.add('active');
                }
            });
        };
        window.addEventListener('scroll', revealOnScroll);
        window.addEventListener('load', revealOnScroll);

        // Smooth scroll for anchor links
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function(e) {
                const href = this.getAttribute('href');
                if (href !== '#') {
                    e.preventDefault();
                    const target = document.querySelector(href);
                    if (target) {
                        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
                    }
                }
            });
        });

        // Animate stats on scroll
        const animateStats = () => {
            const statNumbers = document.querySelectorAll('.stat-number');
            statNumbers.forEach(stat => {
                const text = stat.textContent;
                if (text.includes('+')) return;

                const target = parseInt(text);
                let current = 0;
                const increment = target / 50;
                const timer = setInterval(() => {
                    current += increment;
                    if (current >= target) {
                        stat.textContent = target + (text.includes('%') ? '%' : '+');
                        clearInterval(timer);
                    } else {
                        stat.textContent = Math.floor(current);
                    }
                }, 30);
            });
        };

        let statsAnimated = false;
        const statsSection = document.querySelector('.stats');
        const statsObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting && !statsAnimated) {
                    animateStats();
                    statsAnimated = true;
                }
            });
        }, { threshold: 0.5 });

        if (statsSection) {
            statsObserver.observe(statsSection);
        }
    </script>
</body>
</html>
