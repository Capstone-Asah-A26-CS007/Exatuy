<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page isErrorPage="true" %>
<%!
    public String esc(String input) {
        if (input == null) return "";
        return input.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    // Log error untuk admin tapi jangan tampilkan ke user
    if (exception != null) {
        System.err.println("ERROR: " + exception.getMessage());
        exception.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error - Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .error-container {
            background: white;
            border-radius: 1rem;
            padding: 2rem;
            box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
            max-width: 500px;
            text-align: center;
        }
        .error-icon {
            font-size: 4rem;
            color: #667eea;
            margin-bottom: 1rem;
        }
    </style>
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <div class="error-container">
        <div class="error-icon">
            <i class="bi bi-exclamation-triangle-fill"></i>
        </div>
        <h2 class="mb-3">Terjadi Kesalahan</h2>
        <p class="text-muted mb-4">
            Maaf, terjadi kesalahan saat memproses permintaan Anda.
            Silakan coba lagi atau hubungi administrator jika masalah berlanjut.
        </p>
        <div class="d-flex gap-2 justify-content-center">
            <a href="<%= request.getContextPath() %>/AdminServlet?action=dashboard" class="btn btn-primary">
                <i class="bi bi-house me-2"></i>Dashboard
            </a>
            <a href="javascript:history.back()" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-left me-2"></i>Kembali
            </a>
        </div>
    </div>
</body>
</html>
