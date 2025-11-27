#!/bin/bash
# NetViz Pro - Clean Database Script
# Removes database and restarts with fresh default admin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_FILE="$SCRIPT_DIR/server/users.db"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     NetViz Pro - Database Reset                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Confirm
read -p "This will DELETE all users and reset to default admin. Continue? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# Stop servers first
echo "Stopping servers..."
"$SCRIPT_DIR/stop.sh" 2>/dev/null

sleep 1

# Remove database
if [ -f "$DB_FILE" ]; then
    rm -f "$DB_FILE"
    echo "✓ Database removed: $DB_FILE"
else
    echo "✓ No existing database found"
fi

echo ""
echo "Database will be recreated on next start with:"
echo "  Username: admin"
echo "  Password: admin123"
echo "  (Password change required after 10 logins)"
echo ""

read -p "Start servers now? (Y/n): " start_now
if [[ "$start_now" != "n" && "$start_now" != "N" ]]; then
    echo ""
    "$SCRIPT_DIR/start.sh"
fi
