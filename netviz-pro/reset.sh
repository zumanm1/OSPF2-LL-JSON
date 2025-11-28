#!/bin/bash
# ============================================================================
# NetViz Pro - Reset Script
# ============================================================================
# Resets databases and application state
#
# Usage:
#   ./reset.sh --db       Reset main database only
#   ./reset.sh --auth     Reset authentication (login counts, sessions)
#   ./reset.sh --all      Full factory reset (removes all data)
#   ./reset.sh            Interactive mode (prompts for options)
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_FILE="$SCRIPT_DIR/server/users.db"
NETVIZ_DB="$SCRIPT_DIR/server/netviz.db"
LOG_FILE="/tmp/netviz-pro.log"

# Parse arguments
RESET_DB=false
RESET_AUTH=false
RESET_ALL=false
NO_PROMPT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --db)
            RESET_DB=true
            NO_PROMPT=true
            shift
            ;;
        --auth)
            RESET_AUTH=true
            NO_PROMPT=true
            shift
            ;;
        --all)
            RESET_ALL=true
            NO_PROMPT=true
            shift
            ;;
        -y|--yes)
            NO_PROMPT=true
            shift
            ;;
        -h|--help)
            echo ""
            echo "NetViz Pro - Reset Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --db       Reset main database only"
            echo "  --auth     Reset authentication (recreates admin user)"
            echo "  --all      Full factory reset (removes all data)"
            echo "  -y, --yes  Skip confirmation prompts"
            echo "  -h, --help Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 --auth           # Reset login counts"
            echo "  $0 --db             # Reset database"
            echo "  $0 --all -y         # Full reset without prompts"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# If --all, enable everything
if [ "$RESET_ALL" = true ]; then
    RESET_DB=true
    RESET_AUTH=true
fi

# ============================================================================
# Header
# ============================================================================
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     NetViz Pro - Reset Utility                               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Interactive mode if no options provided
# ============================================================================
if [ "$RESET_DB" = false ] && [ "$RESET_AUTH" = false ]; then
    echo "  Select what to reset:"
    echo ""
    echo "  1) Database only (users.db)"
    echo "  2) Authentication only (recreate default admin)"
    echo "  3) Full reset (all data + auth)"
    echo "  4) Cancel"
    echo ""
    read -p "  Choice [1-4]: " choice

    case $choice in
        1) RESET_DB=true ;;
        2) RESET_AUTH=true ;;
        3) RESET_ALL=true; RESET_DB=true; RESET_AUTH=true ;;
        4|*) echo -e "\n${YELLOW}Cancelled.${NC}\n"; exit 0 ;;
    esac
    echo ""
fi

# ============================================================================
# Show what will be reset
# ============================================================================
echo -e "  ${CYAN}Actions to perform:${NC}"
echo ""

if [ "$RESET_DB" = true ]; then
    if [ -f "$DB_FILE" ]; then
        DB_SIZE=$(ls -lh "$DB_FILE" 2>/dev/null | awk '{print $5}')
        echo -e "  ${YELLOW}→${NC} Delete database: $DB_FILE ($DB_SIZE)"
    else
        echo -e "  ${GREEN}→${NC} Database not present (will create fresh)"
    fi
fi

if [ "$RESET_AUTH" = true ]; then
    echo -e "  ${YELLOW}→${NC} Reset authentication state"
    echo -e "  ${YELLOW}→${NC} Recreate default admin user"
fi

if [ "$RESET_ALL" = true ]; then
    echo -e "  ${YELLOW}→${NC} Clear log file"
    if [ -f "$NETVIZ_DB" ]; then
        echo -e "  ${YELLOW}→${NC} Delete netviz.db"
    fi
fi

echo ""

# ============================================================================
# Confirmation
# ============================================================================
if [ "$NO_PROMPT" = false ]; then
    echo -e "${YELLOW}WARNING: This action cannot be undone!${NC}"
    echo ""
    read -p "  Continue? (y/N): " confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo ""
        echo -e "${YELLOW}Cancelled.${NC}"
        echo ""
        exit 0
    fi
    echo ""
fi

# ============================================================================
# Stop services first
# ============================================================================
echo -e "${CYAN}[Step 1/3]${NC} Stopping services..."

STOPPED=0
for PORT in 9040 9041; do
    PID=""
    if command -v lsof &> /dev/null; then
        PID=$(lsof -ti:$PORT 2>/dev/null)
    elif command -v fuser &> /dev/null; then
        PID=$(fuser $PORT/tcp 2>/dev/null | awk '{print $1}')
    fi

    if [ -n "$PID" ]; then
        kill -9 $PID 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Stopped port $PORT (PID: $PID)"
        STOPPED=$((STOPPED + 1))
    fi
done

if [ $STOPPED -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} No running services found"
fi

sleep 1
echo ""

# ============================================================================
# Perform reset
# ============================================================================
echo -e "${CYAN}[Step 2/3]${NC} Resetting data..."

if [ "$RESET_DB" = true ]; then
    if [ -f "$DB_FILE" ]; then
        rm -f "$DB_FILE"
        echo -e "  ${GREEN}✓${NC} Deleted: users.db"
    fi

    if [ "$RESET_ALL" = true ] && [ -f "$NETVIZ_DB" ]; then
        rm -f "$NETVIZ_DB"
        echo -e "  ${GREEN}✓${NC} Deleted: netviz.db"
    fi
fi

if [ "$RESET_AUTH" = true ]; then
    # Auth is stored in the database, so if we're only resetting auth,
    # we still need to remove the database to reset the admin
    if [ -f "$DB_FILE" ]; then
        rm -f "$DB_FILE"
        echo -e "  ${GREEN}✓${NC} Authentication reset (database removed)"
    fi
    echo -e "  ${GREEN}✓${NC} Default admin will be created on restart"
fi

if [ "$RESET_ALL" = true ]; then
    # Clear log file
    if [ -f "$LOG_FILE" ]; then
        > "$LOG_FILE"
        echo -e "  ${GREEN}✓${NC} Cleared log file"
    fi
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
echo -e "${CYAN}[Step 3/3]${NC} Reset complete!"
echo ""

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Reset Complete!                                          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Database will be recreated on next start with:"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────┐"
echo "  │  Username: admin                                            │"
echo "  │  Password: admin123                                         │"
echo "  │  (Password change required after 10 logins)                 │"
echo "  └─────────────────────────────────────────────────────────────┘"
echo ""

# ============================================================================
# Ask to start
# ============================================================================
if [ "$NO_PROMPT" = false ]; then
    read -p "  Start services now? (Y/n): " start_now
    if [[ "$start_now" != "n" && "$start_now" != "N" ]]; then
        echo ""
        "$SCRIPT_DIR/start.sh"
    else
        echo ""
        echo "  To start later, run:"
        echo -e "  ${GREEN}./start.sh${NC}"
        echo ""
    fi
else
    echo "  To start services, run:"
    echo -e "  ${GREEN}./start.sh${NC}"
    echo ""
fi
