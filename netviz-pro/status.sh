#!/bin/bash
# ============================================================================
# NetViz Pro - Status Script
# ============================================================================
# Shows the current status of all services
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="/tmp/netviz-pro.log"
DB_FILE="$SCRIPT_DIR/server/users.db"

# Helper function to check port
check_port() {
    local PORT=$1
    if command -v lsof &> /dev/null; then
        lsof -ti:$PORT 2>/dev/null
    elif command -v fuser &> /dev/null; then
        fuser $PORT/tcp 2>/dev/null | awk '{print $1}'
    elif command -v ss &> /dev/null; then
        ss -tlnp "sport = :$PORT" 2>/dev/null | grep -oP 'pid=\K\d+'
    else
        echo ""
    fi
}

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     NetViz Pro - Status                                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Service Status
# ============================================================================
echo -e "  ${CYAN}Services:${NC}"
echo ""

SERVICES_UP=0

# Check App Server (port 9040)
APP_PID=$(check_port 9040)
if [ -n "$APP_PID" ]; then
    echo -e "  ${GREEN}✓${NC} Frontend (9040):  RUNNING  [PID: $APP_PID]"
    SERVICES_UP=$((SERVICES_UP + 1))
else
    echo -e "  ${RED}✗${NC} Frontend (9040):  NOT RUNNING"
fi

# Check Auth Server (port 9041)
AUTH_PID=$(check_port 9041)
if [ -n "$AUTH_PID" ]; then
    echo -e "  ${GREEN}✓${NC} Backend  (9041):  RUNNING  [PID: $AUTH_PID]"
    SERVICES_UP=$((SERVICES_UP + 1))
else
    echo -e "  ${RED}✗${NC} Backend  (9041):  NOT RUNNING"
fi

echo ""

# ============================================================================
# Database Status
# ============================================================================
echo -e "  ${CYAN}Database:${NC}"
echo ""

if [ -f "$DB_FILE" ]; then
    DB_SIZE=$(ls -lh "$DB_FILE" 2>/dev/null | awk '{print $5}')
    DB_MOD=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$DB_FILE" 2>/dev/null || stat -c "%y" "$DB_FILE" 2>/dev/null | cut -d'.' -f1)
    echo -e "  ${GREEN}✓${NC} users.db: $DB_SIZE (modified: $DB_MOD)"
else
    echo -e "  ${YELLOW}○${NC} users.db: Not created yet"
fi

echo ""

# ============================================================================
# Log Status
# ============================================================================
echo -e "  ${CYAN}Logs:${NC}"
echo ""

if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(ls -lh "$LOG_FILE" 2>/dev/null | awk '{print $5}')
    echo -e "  ${GREEN}✓${NC} Log file: $LOG_FILE ($LOG_SIZE)"

    # Show last error if any
    LAST_ERROR=$(grep -i "error\|exception\|failed" "$LOG_FILE" 2>/dev/null | tail -1)
    if [ -n "$LAST_ERROR" ]; then
        echo -e "  ${YELLOW}!${NC} Last error: $(echo "$LAST_ERROR" | head -c 60)..."
    fi
else
    echo -e "  ${YELLOW}○${NC} Log file: Not created yet"
fi

echo ""

# ============================================================================
# API Health (if curl available and services running)
# ============================================================================
if [ $SERVICES_UP -eq 2 ] && command -v curl &> /dev/null; then
    echo -e "  ${CYAN}API Health:${NC}"
    echo ""

    # Auth API
    HEALTH=$(curl -s -m 3 http://127.0.0.1:9041/api/health 2>/dev/null || echo "FAILED")
    if echo "$HEALTH" | grep -q '"status":"ok"'; then
        echo -e "  ${GREEN}✓${NC} Auth API: OK"
    else
        echo -e "  ${RED}✗${NC} Auth API: Failed"
    fi

    # Frontend
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 3 http://localhost:9040 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "  ${GREEN}✓${NC} Frontend: OK (HTTP 200)"
    else
        echo -e "  ${RED}✗${NC} Frontend: Failed (HTTP $HTTP_CODE)"
    fi

    echo ""
fi

# ============================================================================
# Summary
# ============================================================================
echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
echo ""

if [ $SERVICES_UP -eq 2 ]; then
    echo -e "  ${GREEN}All services running!${NC}"
    echo ""
    echo "  Access: http://localhost:9040"
    echo "  Logs:   tail -f $LOG_FILE"
else
    echo -e "  ${YELLOW}Status: $SERVICES_UP/2 services running${NC}"
    echo ""
    echo "  Start:  ./start.sh"
    echo "  Logs:   tail -f $LOG_FILE"
fi

echo ""
