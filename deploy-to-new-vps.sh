#!/bin/bash
# ============================================
# Examora - Deploy ke VPS Baru
# ============================================
# Jalankan script ini dari komputer LOKAL Anda
# di dalam folder project Examora
#
# Usage: ./deploy-to-new-vps.sh user@IP_VPS_BARU
# ============================================

set -e

# ===== KONFIGURASI =====
VPS_TARGET="${1:?Usage: $0 user@IP_VPS_BARU}"
REMOTE_DIR="/opt/examora"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================="
echo "  Examora - Deploy ke VPS Baru"
echo "========================================="
echo "Target: $VPS_TARGET"
echo "Remote dir: $REMOTE_DIR"
echo ""

# ===== STEP 1: Build WAR di lokal =====
echo "[1/7] Building WAR file di lokal..."
cd "$LOCAL_DIR"
mvn clean package -DskipTests -q
echo "  -> Build selesai: target/examora.war"
echo ""

# ===== STEP 2: Install Docker di VPS baru =====
echo "[2/7] Menginstall Docker di VPS baru..."
ssh "$VPS_TARGET" bash -s <<'REMOTE_SCRIPT'
if ! command -v docker &> /dev/null; then
    echo "  -> Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo "  -> Docker terinstall"
else
    echo "  -> Docker sudah ada"
fi

if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    echo "  -> Docker Compose sudah tersedia (plugin)"
fi

# Buat directory
mkdir -p /opt/examora/sql /opt/examora/uploads /opt/examora/tomcat-conf
echo "  -> Directory /opt/examora dibuat"
REMOTE_SCRIPT
echo ""

# ===== STEP 3: Upload file-file ke VPS =====
echo "[3/7] Uploading files ke VPS..."

# WAR file
scp "$LOCAL_DIR/target/examora.war" "$VPS_TARGET:$REMOTE_DIR/examora.war"
echo "  -> examora.war"

# Dockerfile
scp "$LOCAL_DIR/Dockerfile" "$VPS_TARGET:$REMOTE_DIR/Dockerfile"
echo "  -> Dockerfile"

# docker-compose.yml
scp "$LOCAL_DIR/docker-compose.yml" "$VPS_TARGET:$REMOTE_DIR/docker-compose.yml"
echo "  -> docker-compose.yml"

# .env
scp "$LOCAL_DIR/.env" "$VPS_TARGET:$REMOTE_DIR/.env"
echo "  -> .env"

# SQL schema
scp "$LOCAL_DIR/sql/schema.sql" "$VPS_TARGET:$REMOTE_DIR/sql/schema.sql"
echo "  -> sql/schema.sql"

# Tomcat config
scp "$LOCAL_DIR/tomcat-conf/server.xml" "$VPS_TARGET:$REMOTE_DIR/tomcat-conf/server.xml"
echo "  -> tomcat-conf/server.xml"

echo "  -> Semua file terupload"
echo ""

# ===== STEP 4: Setup permission =====
echo "[4/7] Setting permissions..."
ssh "$VPS_TARGET" bash -s <<REMOTE_SCRIPT
chmod 600 $REMOTE_DIR/.env
chmod 644 $REMOTE_DIR/docker-compose.yml
chmod 644 $REMOTE_DIR/Dockerfile
echo "  -> Permissions set"
REMOTE_SCRIPT
echo ""

# ===== STEP 5: Stop containers lama (jika ada) =====
echo "[5/7] Checking existing containers..."
ssh "$VPS_TARGET" bash -s <<REMOTE_SCRIPT
cd $REMOTE_DIR
if docker compose ps -q 2>/dev/null | grep -q .; then
    echo "  -> Stopping existing containers..."
    docker compose down
else
    echo "  -> Tidak ada container yang running"
fi
REMOTE_SCRIPT
echo ""

# ===== STEP 6: Build dan start containers =====
echo "[6/7] Building dan starting containers..."
ssh "$VPS_TARGET" bash -s <<REMOTE_SCRIPT
cd $REMOTE_DIR
docker compose up -d --build
echo "  -> Containers started"
REMOTE_SCRIPT
echo ""

# ===== STEP 7: Verifikasi =====
echo "[7/7] Verifying deployment..."
ssh "$VPS_TARGET" bash -s <<REMOTE_SCRIPT
echo ""
echo "Container Status:"
docker compose -f $REMOTE_DIR/docker-compose.yml ps
echo ""
echo "Health Check:"
sleep 5
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8888 | grep -q "200\|302"; then
    echo "  -> Website: OK (http://localhost:8888)"
else
    echo "  -> Website: Waiting... (mungkin perlu beberapa detik untuk start)"
fi
REMOTE_SCRIPT

echo ""
echo "========================================="
echo "  DEPLOY SELESAI!"
echo "========================================="
echo ""
echo "  Website: http://IP_VPS_BARU:8888"
echo ""
echo "  File yang ada di VPS:"
echo "    - examora.war (binary saja)"
echo "    - Dockerfile"
echo "    - docker-compose.yml"
echo "    - .env"
echo "    - sql/schema.sql"
echo "    - tomcat-conf/server.xml"
echo ""
echo "  TIDAK ADA source code di VPS."
echo ""
echo "  Untuk update berikutnya, jalankan:"
echo "    ./deploy-to-new-vps.sh user@IP_VPS_BARU"
echo "========================================="
