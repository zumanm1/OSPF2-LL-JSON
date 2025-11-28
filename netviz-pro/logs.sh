#!/bin/bash
# ============================================================================
# NetViz Pro - Logs Script
# ============================================================================
# View application logs with various options
#
# Usage:
#   ./logs.sh              Show last 50 lines
#   ./logs.sh -f           Follow logs in real-time
#   ./logs.sh -n 100       Show last 100 lines
#   ./logs.sh --errors     Show only errors
#   ./logs.sh --clear      Clear the log file
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/tmp/netviz-pro.log"

# Defaults
LINES=50
FOLLOW=false
ERRORS_ONLY=false
CLEAR_LOG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--lines)
            LINES=$2
            shift 2
            ;;
        --errors)
            ERRORS_ONLY=true
            shift
            ;;
        --clear)
            CLEAR_LOG=true
            shift
            ;;
        -h|--help)
            echo ""
            echo "NetViz Pro - Logs Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --follow     Follow logs in real-time (Ctrl+C to stop)"
            echo "  -n, --lines N    Show last N lines (default: 50)"
            echo "  --errors         Show only errors and warnings"
            echo "  --clear          Clear the log file"
            echo "  -h, --help       Show this help"
            echo ""
            echo "Examples:"
            echo "  $0              # Show last 50 lines"
            echo "  $0 -f           # Follow logs live"
            echo "  $0 -n 200       # Show last 200 lines"
            echo "  $0 --errors     # Show only errors"
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

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     NetViz Pro - Logs                                        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo -e "  ${YELLOW}Log file not found: $LOG_FILE${NC}"
    echo ""
    echo "  The log file will be created when you start the application."
    echo "  Run: ./start.sh"
    echo ""
    exit 0
fi

# Clear log if requested
if [ "$CLEAR_LOG" = true ]; then
    > "$LOG_FILE"
    echo -e "  ${GREEN}✓${NC} Log file cleared"
    echo ""
    exit 0
fi

# Show log info
LOG_SIZE=$(ls -lh "$LOG_FILE" 2>/dev/null | awk '{print $5}')
LOG_LINES=$(wc -l < "$LOG_FILE" | tr -d ' ')
echo -e "  ${CYAN}Log file:${NC} $LOG_FILE"
echo -e "  ${CYAN}Size:${NC} $LOG_SIZE ($LOG_LINES lines)"
echo ""

# Show logs
if [ "$FOLLOW" = true ]; then
    echo -e "  ${CYAN}Following logs (Ctrl+C to stop)...${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
    echo ""

    if [ "$ERRORS_ONLY" = true ]; then
        tail -f "$LOG_FILE" | grep --line-buffered -iE "error|exception|failed|warn"
    else
        tail -f "$LOG_FILE"
    fi
elif [ "$ERRORS_ONLY" = true ]; then
    echo -e "  ${CYAN}Showing errors and warnings:${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
    echo ""

    ERROR_COUNT=$(grep -ciE "error|exception|failed" "$LOG_FILE" 2>/dev/null || echo "0")
    WARN_COUNT=$(grep -ci "warn" "$LOG_FILE" 2>/dev/null || echo "0")

    echo -e "  ${RED}Errors:${NC} $ERROR_COUNT  ${YELLOW}Warnings:${NC} $WARN_COUNT"
    echo ""

    grep -iE "error|exception|failed|warn" "$LOG_FILE" | tail -$LINES
else
    echo -e "  ${CYAN}Last $LINES lines:${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
    echo ""
    tail -$LINES "$LOG_FILE"
fi

echo ""
