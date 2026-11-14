<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.examora.model.User" %>
<%@ page import="com.examora.model.UserPoints" %>
<%@ page import="com.examora.model.PointTransaction" %>
<%@ page import="java.util.List" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect("../LoginServlet");
        return;
    }

    List<UserPoints> leaderboard = (List<UserPoints>) request.getAttribute("leaderboard");
    if (leaderboard == null) leaderboard = List.of();

    List<PointTransaction> transactions = (List<PointTransaction>) request.getAttribute("transactions");
    if (transactions == null) transactions = List.of();

    String success = (String) request.getAttribute("success");
    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gamification - Admin Exatuy</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <link href="../assets/css/style.css" rel="stylesheet">
    <link rel="icon" type="image/svg+xml" href="../assets/img/favicon.svg?v=3">
<link href="../assets/css/handdrawn.css" rel="stylesheet">
</head>
<body>
    <!-- Sidebar -->
    <%@ include file="sidebar.jsp" %>

    <!-- Main Content -->
    <div class="main-content">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div>
                <h1 class="h3 mb-0">Gamification System</h1>
                <nav aria-label="breadcrumb">
                    <ol class="breadcrumb mb-0">
                        <li class="breadcrumb-item"><a href="../AdminServlet?action=dashboard">Dashboard</a></li>
                        <li class="breadcrumb-item active">Gamification</li>
                    </ol>
                </nav>
            </div>
            <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#awardPointsModal">
                <i class="bi bi-gift-fill me-2"></i>Award Points
            </button>
        </div>

        <% if (success != null) { %>
        <div class="alert alert-success alert-dismissible fade show">
            <i class="bi bi-check-circle me-2"></i><%= success %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <% if (error != null) { %>
        <div class="alert alert-danger alert-dismissible fade show">
            <i class="bi bi-exclamation-triangle me-2"></i><%= error %>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        <% } %>

        <div class="row mb-4">
            <div class="col-md-3">
                <div class="card border-primary">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="fs-1 text-primary me-3">
                                <i class="bi bi-people-fill"></i>
                            </div>
                            <div>
                                <h6 class="text-muted mb-0">Total Users</h6>
                                <h3 class="mb-0"><%= leaderboard.size() %></h3>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-success">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="fs-1 text-success me-3">
                                <i class="bi bi-trophy-fill"></i>
                            </div>
                            <div>
                                <h6 class="text-muted mb-0">Points Awarded</h6>
                                <h3 class="mb-0" id="totalPoints">0</h3>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-warning">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="fs-1 text-warning me-3">
                                <i class="bi bi-star-fill"></i>
                            </div>
                            <div>
                                <h6 class="text-muted mb-0">Avg Level</h6>
                                <h3 class="mb-0" id="avgLevel">0</h3>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card border-info">
                    <div class="card-body">
                        <div class="d-flex align-items-center">
                            <div class="fs-1 text-info me-3">
                                <i class="bi bi-graph-up-arrow"></i>
                            </div>
                            <div>
                                <h6 class="text-muted mb-0">Transactions</h6>
                                <h3 class="mb-0"><%= transactions.size() %></h3>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-lg-7 mb-4">
                <div class="card">
                    <div class="card-header">
                        <div class="d-flex justify-content-between align-items-center">
                            <h5 class="mb-0"><i class="bi bi-trophy-fill text-warning me-2"></i>Leaderboard</h5>
                            <div class="btn-group btn-group-sm">
                                <a href="../AdminServlet?action=gamification&period=all_time" class="btn btn-outline-primary active">All Time</a>
                                <a href="../AdminServlet?action=gamification&period=monthly" class="btn btn-outline-primary">Monthly</a>
                                <a href="../AdminServlet?action=gamification&period=weekly" class="btn btn-outline-primary">Weekly</a>
                            </div>
                        </div>
                    </div>
                    <div class="card-body">
                        <% if (leaderboard.isEmpty()) { %>
                        <div class="text-center py-5">
                            <i class="bi bi-trophy display-4 text-muted"></i>
                            <p class="text-muted mt-3">Belum ada data leaderboard</p>
                        </div>
                        <% } else { %>
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th width="60">Rank</th>
                                        <th>User</th>
                                        <th>Level</th>
                                        <th>Points</th>
                                        <th>XP</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% int rank = 1;
                                       for (UserPoints up : leaderboard) { %>
                                    <tr>
                                        <td>
                                            <% if (rank == 1) { %>
                                            <span class="badge bg-warning text-dark">🥆 <%= rank %></span>
                                            <% } else if (rank == 2) { %>
                                            <span class="badge bg-secondary">🥈 <%= rank %></span>
                                            <% } else if (rank == 3) { %>
                                            <span class="badge bg-danger">🥉 <%= rank %></span>
                                            <% } else { %>
                                            <span class="badge bg-light text-dark">#<%= rank %></span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <strong><%= up.getUserName() != null ? up.getUserName() : "User " + up.getUserId() %></strong>
                                        </td>
                                        <td>
                                            <span class="badge bg-primary">Level <%= up.getLevel() %></span>
                                            <small class="text-muted d-block"><%= up.getLevelTitle() %></small>
                                        </td>
                                        <td>
                                            <span class="fw-bold text-primary"><%= up.getTotalPoints() %></span>
                                        </td>
                                        <td>
                                            <div class="d-flex align-items-center">
                                                <div class="progress flex-grow-1" style="height: 6px;">
                                                    <div class="progress-bar" style="width: <%= up.progressToNext() %>%"></div>
                                                </div>
                                                <small class="ms-2 text-muted"><%= up.getExperiencePoints() %> XP</small>
                                            </div>
                                        </td>
                                    </tr>
                                    <% rank++; } %>
                                </tbody>
                            </table>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>

            <div class="col-lg-5 mb-4">
                <div class="card">
                    <div class="card-header">
                        <h5 class="mb-0"><i class="bi bi-clock-history text-primary me-2"></i>Recent Transactions</h5>
                    </div>
                    <div class="card-body">
                        <% if (transactions.isEmpty()) { %>
                        <div class="text-center py-5">
                            <i class="bi bi-clock-history display-4 text-muted"></i>
                            <p class="text-muted mt-3">Belum ada transaksi</p>
                        </div>
                        <% } else { %>
                        <div style="max-height: 400px; overflow-y: auto;">
                            <% DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm");
                               for (PointTransaction pt : transactions) {
                                   String textClass = pt.getPoints() > 0 ? "text-success" : "text-danger";
                                   String icon = pt.getPoints() > 0 ? "bi-plus-circle-fill" : "bi-dash-circle-fill";
                            %>
                            <div class="d-flex justify-content-between align-items-start mb-3 pb-3" style="border-bottom: 1px solid #dee2e6;">
                                <div>
                                    <div class="d-flex align-items-center mb-1">
                                        <i class="bi <%= icon %> <%= textClass %> me-2"></i>
                                        <strong><%= pt.getUserName() != null ? pt.getUserName() : "User " + pt.getUserId() %></strong>
                                    </div>
                                    <small class="text-muted"><%= pt.getDescription() %></small>
                                </div>
                                <div class="text-end">
                                    <div class="<%= textClass %> fw-bold"><%= pt.getPoints() > 0 ? "+" : "" %><%= pt.getPoints() %></div>
                                    <small class="text-muted"><%= pt.getCreatedAt().format(formatter) %></small>
                                </div>
                            </div>
                            <% } %>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <h5 class="mb-0"><i class="bi bi-info-circle-fill text-info me-2"></i>Level System Info</h5>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-6">
                        <h6>Level Requirements</h6>
                        <table class="table table-sm table-bordered">
                            <thead>
                                <tr>
                                    <th>Level</th>
                                    <th>Title</th>
                                    <th>XP Required</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr><td>1</td><td>Beginner</td><td>0</td></tr>
                                <tr><td>2</td><td>Novice</td><td>100</td></tr>
                                <tr><td>3</td><td>Intermediate</td><td>500</td></tr>
                                <tr><td>4</td><td>Advanced</td><td>1,500</td></tr>
                                <tr><td>5</td><td>Expert</td><td>3,500</td></tr>
                                <tr><td>6</td><td>Master</td><td>7,500</td></tr>
                                <tr><td>7</td><td>Grandmaster</td><td>15,000</td></tr>
                            </tbody>
                        </table>
                    </div>
                    <div class="col-md-6">
                        <h6>Point Values</h6>
                        <ul class="list-group">
                            <li class="list-group-item d-flex justify-content-between">
                                <span><i class="bi bi-journal-check text-primary me-2"></i>Quiz Completion</span>
                                <span class="badge bg-primary">+100 pts</span>
                            </li>
                            <li class="list-group-item d-flex justify-content-between">
                                <span><i class="bi bi-star-fill text-warning me-2"></i>Perfect Score</span>
                                <span class="badge bg-warning text-dark">+50 pts</span>
                            </li>
                            <li class="list-group-item d-flex justify-content-between">
                                <span><i class="bi bi-award-fill text-success me-2"></i>Achievement</span>
                                <span class="badge bg-success">+25 pts</span>
                            </li>
                            <li class="list-group-item d-flex justify-content-between">
                                <span><i class="bi bi-calendar-check text-info me-2"></i>Daily Login</span>
                                <span class="badge bg-info">+10 pts</span>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Award Points Modal -->
    <div class="modal fade" id="awardPointsModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Award Points to User</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <form action="../AdminServlet" method="post">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="awardPoints">
                        <div class="mb-3">
                            <label class="form-label">User *</label>
                            <select class="form-select" name="userId" required>
                                <option value="">Pilih User</option>
                                <% for (UserPoints up : leaderboard) { %>
                                <option value="<%= up.getUserId() %>"><%= up.getUserName() != null ? up.getUserName() : "User " + up.getUserId() %></option>
                                <% } %>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Points *</label>
                            <input type="number" class="form-control" name="points" required
                                   placeholder="Masukkan jumlah poin">
                            <div class="form-text">Gunakan nilai negatif untuk mengurangi poin</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Transaction Type *</label>
                            <select class="form-select" name="transactionType" required>
                                <option value="manual">Manual Award</option>
                                <option value="bonus">Bonus</option>
                                <option value="penalty">Penalty</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Description *</label>
                            <input type="text" class="form-control" name="description" required
                                   placeholder="Alasan pemberian poin">
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Batal</button>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-gift-fill me-2"></i>Award Points
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            let totalPoints = 0;
            let totalLevel = 0;
            const count = <%= leaderboard.size() %>;

            document.querySelectorAll('table tbody tr').forEach(row => {
                const pointsText = row.querySelector('.text-primary');
                if (pointsText) {
                    totalPoints += parseInt(pointsText.textContent.replace(/,/g, '')) || 0;
                }
                const levelText = row.querySelector('.badge');
                if (levelText) {
                    const level = parseInt(levelText.textContent.replace('Level ', '')) || 1;
                    totalLevel += level;
                }
            });

            document.getElementById('totalPoints').textContent = totalPoints.toLocaleString();
            document.getElementById('avgLevel').textContent = count > 0 ? (totalLevel / count).toFixed(1) : '0';
        });
    </script>
</body>
</html>
