#!/bin/bash
# Update quiz deadline to future date
echo "Usage: ./update_deadline.sh <quiz_id> <date> <hour> <minute>"
echo "Example: ./update_deadline.sh 6 2026-03-10 23 59"

QUIZ_ID=$1
DATE=$2
HOUR=$3
MINUTE=$4

if [ -z "$QUIZ_ID" ] || [ -z "$DATE" ] || [ -z "$HOUR" ]; then
    echo "Error: Missing parameters"
    echo "Usage: ./update_deadline.sh <quiz_id> <date> <hour> <minute>"
    exit 1
fi

DEETIME="${DATE} ${HOUR}:${MINUTE}:00"

# Ambil kredensial dari .env (jangan hardcode password di script)
if [ -f .env ]; then
    set -a
    . ./.env
    set +a
fi

if [ -z "$MYSQL_PASSWORD" ]; then
    echo "Error: MYSQL_PASSWORD tidak ditemukan. Pastikan file .env ada."
    exit 1
fi

echo "Updating quiz $QUIZ_ID deadline to: $DEETIME"

docker exec examora-mysql mysql -u"${MYSQL_USER:-examora_app}" -p"$MYSQL_PASSWORD" "${MYSQL_DATABASE:-examora_db}" \
  -e "UPDATE quiz SET deadline='$DEETIME' WHERE id=$QUIZ_ID;" 2>&1 | grep -v "Warning"

echo ""
echo "Verify update:"
docker exec examora-mysql mysql -u"${MYSQL_USER:-examora_app}" -p"$MYSQL_PASSWORD" "${MYSQL_DATABASE:-examora_db}" \
  --table -e "SELECT id, title, deadline, CASE WHEN deadline > NOW() THEN 'ACTIVE' ELSE 'EXPIRED' END as status FROM quiz WHERE id=$QUIZ_ID;" 2>&1 | grep -v "Warning"

echo ""
echo "Done! Quiz deadline has been updated."
echo "Please refresh your browser to see the changes."
