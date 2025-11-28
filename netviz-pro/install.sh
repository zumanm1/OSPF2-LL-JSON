#!/bin/bash
# ============================================================================
# NetViz Pro - Automated Installation Script
# ============================================================================
# Version: 3.0
# Repository: https://github.com/zumanm1/OSPF2-LL-JSON
#
# Usage:
#   ./install.sh              Standard installation (validates prerequisites)
#   ./install.sh --with-deps  Install Node.js, npm, Python if missing
#   ./install.sh --clean      Clean install (remove old, install fresh)
#   ./install.sh --force      Force reinstall even if exists
#
# 7-Phase Installation Process:
#   Phase 1: Remove old Node.js (--clean only)
#   Phase 2: Remove old npm (--clean only)
#   Phase 3: Clean Python environment (--clean only)
#   Phase 4: Install Python 3.12 (--with-deps or --clean)
#   Phase 5: Install Node.js 20.x (--with-deps or --clean)
#   Phase 6: Install Application Dependencies
#   Phase 7: Validation & Startup
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
REPO_URL="https://github.com/zumanm1/OSPF2-LL-JSON.git"
INSTALL_DIR="$HOME/OSPF2-LL-JSON"
APP_DIR="$INSTALL_DIR/netviz-pro"
LOG_FILE="/tmp/netviz-pro-install.log"
PORTS="9040 9041"

# Parse arguments
WITH_DEPS=false
CLEAN_INSTALL=false
FORCE_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --with-deps)
            WITH_DEPS=true
            shift
            ;;
        --clean)
            CLEAN_INSTALL=true
            WITH_DEPS=true  # Clean implies with-deps
            shift
            ;;
        --force)
            FORCE_INSTALL=true
            shift
            ;;
        -h|--help)
            echo ""
            echo "NetViz Pro - Installation Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --with-deps  Install Node.js, npm, Python if missing"
            echo "  --clean      Clean install (7-phase: remove old, install fresh)"
            echo "  --force      Force reinstall even if already installed"
            echo "  -h, --help   Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                    # Standard install (prereqs must exist)"
            echo "  $0 --with-deps        # Install missing dependencies"
            echo "  $0 --clean            # Full clean install from scratch"
            echo "  $0 --clean --force    # Force clean reinstall"
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

# ============================================================================
# Helper Functions
# ============================================================================
print_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_phase() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "  ${CYAN}ℹ${NC} $1"
}

print_warn() {
    echo -e "  ${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_skip() {
    echo -e "  ${YELLOW}○${NC} $1"
}

check_command() {
    command -v "$1" &> /dev/null
}

# Check port and return PID if in use
check_port() {
    local PORT=$1
    if check_command lsof; then
        lsof -ti:$PORT 2>/dev/null
    elif check_command fuser; then
        fuser $PORT/tcp 2>/dev/null | awk '{print $1}'
    elif check_command ss; then
        ss -tlnp "sport = :$PORT" 2>/dev/null | grep -oP 'pid=\K\d+'
    else
        echo ""
    fi
}

# Stop service on port
stop_port() {
    local PORT=$1
    local PID=$(check_port $PORT)
    if [ -n "$PID" ]; then
        kill -9 $PID 2>/dev/null || true
        return 0
    fi
    return 1
}

# Start logging
echo "NetViz Pro Installation Log - $(date)" > "$LOG_FILE"
echo "Arguments: $@" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# ============================================================================
# Header
# ============================================================================
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     ${BOLD}NetViz Pro - Installer${NC}${BLUE}                                   ║${NC}"
echo -e "${BLUE}║     Version 3.0                                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect OS
OS_NAME=$(uname -s)
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_PRETTY="$PRETTY_NAME"
else
    OS_PRETTY="$OS_NAME"
fi
ARCH=$(uname -m)

echo -e "  Detected OS: ${CYAN}$OS_PRETTY${NC}"
echo -e "  Architecture: ${CYAN}$ARCH${NC}"
echo -e "  Working Directory: ${CYAN}$(pwd)${NC}"

if [ "$CLEAN_INSTALL" = true ]; then
    echo -e "  Install Mode: ${YELLOW}CLEAN (7-Phase)${NC}"
elif [ "$WITH_DEPS" = true ]; then
    echo -e "  Install Mode: ${YELLOW}WITH-DEPS${NC}"
else
    echo -e "  Install Mode: ${GREEN}STANDARD${NC}"
fi

echo ""
echo "  Log file: $LOG_FILE"

# ============================================================================
# CLEAN INSTALL - PHASE 1-3: Remove Old Installations
# ============================================================================
if [ "$CLEAN_INSTALL" = true ]; then
    print_header "CLEAN INSTALLATION MODE - 7-Phase Automated Process"
    echo "  This will remove old installations and install fresh"
    echo ""

    # Phase 1: Remove old Node.js
    print_phase "PHASE 1: Remove Old Node.js"
    if check_command node; then
        print_info "Removing existing Node.js installation..."
        if check_command apt-get; then
            sudo apt-get remove -y nodejs npm 2>/dev/null >> "$LOG_FILE" 2>&1 || true
            sudo apt-get autoremove -y 2>/dev/null >> "$LOG_FILE" 2>&1 || true
        fi
        sudo rm -rf /usr/local/lib/node* /usr/local/include/node* 2>/dev/null || true
        sudo rm -f /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx 2>/dev/null || true
        sudo rm -f /usr/bin/node /usr/bin/npm /usr/bin/npx 2>/dev/null || true
        rm -rf ~/.npm ~/.node* 2>/dev/null || true
        hash -r 2>/dev/null || true
        print_step "Node.js removed"
    else
        print_skip "Node.js not installed (skipping)"
    fi

    # Phase 2: Remove old npm
    print_phase "PHASE 2: Remove Old npm"
    if [ -d ~/.npm ]; then
        rm -rf ~/.npm 2>/dev/null || true
        print_step "npm cache removed"
    else
        print_skip "npm cache clean (already done)"
    fi

    # Phase 3: Clean Python environment
    print_phase "PHASE 3: Clean Python Environment"
    if [ -d "$APP_DIR/venv" ] || [ -d "$APP_DIR/backend/venv" ]; then
        print_info "Cleaning Python virtual environment and cache..."
        rm -rf "$APP_DIR/venv" "$APP_DIR/backend/venv" 2>/dev/null || true
        rm -rf ~/.cache/pip 2>/dev/null || true
        print_step "Python environment cleaned"
    else
        print_skip "No Python venv to clean"
    fi

    # Remove old repository
    if [ -d "$INSTALL_DIR" ]; then
        print_info "Removing old repository..."
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
        print_step "Old repository removed"
    fi
fi

# ============================================================================
# PHASE 4: Install/Verify Python
# ============================================================================
if [ "$WITH_DEPS" = true ]; then
    print_phase "PHASE 4: Install Python 3.12"

    if check_command python3; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f1)
        PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f2)

        if [ "$PYTHON_MAJOR" -ge 3 ] && [ "$PYTHON_MINOR" -ge 10 ]; then
            print_step "Python $PYTHON_VERSION already installed (OK)"
        else
            print_info "Python version too old, installing 3.12..."
            if check_command apt-get; then
                sudo apt-get update >> "$LOG_FILE" 2>&1
                sudo apt-get install -y python3 python3-pip python3-venv >> "$LOG_FILE" 2>&1
            fi
        fi
    else
        print_info "Installing Python 3..."
        if check_command apt-get; then
            sudo apt-get update >> "$LOG_FILE" 2>&1
            sudo apt-get install -y python3 python3-pip python3-venv >> "$LOG_FILE" 2>&1
            print_step "Python 3 installed"
        else
            print_error "Cannot install Python - please install manually"
        fi
    fi

    # Verify
    if check_command python3; then
        print_step "Python $(python3 --version 2>&1 | awk '{print $2}') verified"
    fi
fi

# ============================================================================
# PHASE 5: Install/Verify Node.js
# ============================================================================
if [ "$WITH_DEPS" = true ]; then
    print_phase "PHASE 5: Install Node.js 20.x"

    if check_command node; then
        NODE_VERSION=$(node --version | tr -d 'v')
        NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d'.' -f1)

        if [ "$NODE_MAJOR" -ge 18 ]; then
            print_step "Node.js v$NODE_VERSION already installed (OK)"
        else
            print_info "Node.js version too old, installing v20..."
            INSTALL_NODE=true
        fi
    else
        print_info "Node.js not found, installing v20..."
        INSTALL_NODE=true
    fi

    if [ "$INSTALL_NODE" = true ]; then
        if check_command apt-get; then
            print_info "Installing Node.js 20.x from NodeSource..."
            curl -fsSL https://deb.nodesource.com/setup_20.x 2>/dev/null | sudo -E bash - >> "$LOG_FILE" 2>&1
            sudo apt-get install -y nodejs >> "$LOG_FILE" 2>&1
            hash -r 2>/dev/null || true
            print_step "Node.js installed"
        else
            print_error "Cannot install Node.js - please install manually"
            exit 1
        fi
    fi

    # Verify Node.js and npm
    if check_command node && check_command npm; then
        print_step "Node.js $(node --version) installed"
        print_step "npm v$(npm --version) installed"
    else
        print_error "Node.js/npm installation failed"
        exit 1
    fi
fi

# ============================================================================
# PHASE 6: Validate Prerequisites (Standard Install)
# ============================================================================
if [ "$WITH_DEPS" = false ]; then
    print_phase "PHASE 1: Validating Prerequisites"

    PREREQ_ERRORS=0

    # Check Git
    echo -n "  Checking git... "
    if check_command git; then
        echo -e "${GREEN}OK${NC} ($(git --version | awk '{print $3}'))"
    else
        echo -e "${RED}NOT FOUND${NC}"
        PREREQ_ERRORS=$((PREREQ_ERRORS + 1))
    fi

    # Check Node.js
    echo -n "  Checking node... "
    if check_command node; then
        NODE_VERSION=$(node --version)
        NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d'.' -f1 | tr -d 'v')
        if [ "$NODE_MAJOR" -ge 18 ]; then
            echo -e "${GREEN}OK${NC} ($NODE_VERSION)"
        else
            echo -e "${RED}TOO OLD${NC} ($NODE_VERSION, need v18+)"
            PREREQ_ERRORS=$((PREREQ_ERRORS + 1))
        fi
    else
        echo -e "${RED}NOT FOUND${NC}"
        PREREQ_ERRORS=$((PREREQ_ERRORS + 1))
    fi

    # Check npm
    echo -n "  Checking npm... "
    if check_command npm; then
        echo -e "${GREEN}OK${NC} (v$(npm --version))"
    else
        echo -e "${RED}NOT FOUND${NC}"
        PREREQ_ERRORS=$((PREREQ_ERRORS + 1))
    fi

    # Check curl
    echo -n "  Checking curl... "
    if check_command curl; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}NOT FOUND${NC} (optional)"
    fi

    echo ""

    if [ $PREREQ_ERRORS -gt 0 ]; then
        print_error "Prerequisites not met! Install with: $0 --with-deps"
        echo ""
        echo "  Or manually install:"
        echo "    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
        echo "    sudo apt-get install -y nodejs"
        echo ""
        exit 1
    fi

    print_step "All prerequisites OK"
fi

# ============================================================================
# PHASE 6/2: Stop Running Services
# ============================================================================
print_phase "PHASE 6: Stop Running Services"

STOPPED=0
for PORT in $PORTS; do
    PID=$(check_port $PORT)
    if [ -n "$PID" ]; then
        stop_port $PORT
        print_step "Stopped port $PORT (PID: $PID)"
        STOPPED=$((STOPPED + 1))
    else
        print_skip "Port $PORT already free"
    fi
done

# Kill any npm/node netviz processes
pkill -f "netviz-pro" 2>/dev/null || true
pkill -f "OSPF2-LL-JSON.*npm" 2>/dev/null || true

sleep 2

# ============================================================================
# PHASE 6/3: Clone Repository
# ============================================================================
print_phase "PHASE 6: Clone Repository"

cd "$HOME"

# Check if already exists
if [ -d "$INSTALL_DIR" ]; then
    if [ "$FORCE_INSTALL" = true ]; then
        print_info "Removing existing installation (--force)..."
        rm -rf "$INSTALL_DIR"
    else
        print_warn "Installation already exists at $INSTALL_DIR"
        print_info "Use --force to reinstall or --clean for fresh install"

        # Check if we should just update
        cd "$INSTALL_DIR"
        if [ -d ".git" ]; then
            print_info "Pulling latest changes..."
            git pull >> "$LOG_FILE" 2>&1 || true
        fi

        # Skip to dependency installation
        if [ -d "$APP_DIR" ]; then
            cd "$APP_DIR"
        fi
    fi
fi

# Clone if doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    print_info "Cloning from: $REPO_URL"
    if git clone "$REPO_URL" >> "$LOG_FILE" 2>&1; then
        print_step "Repository cloned successfully"
    else
        print_error "Failed to clone repository"
        echo "  Check log: $LOG_FILE"
        exit 1
    fi
fi

# ============================================================================
# PHASE 6/4: Install npm Dependencies
# ============================================================================
print_phase "PHASE 6: Install npm Dependencies"

cd "$APP_DIR"

# Remove old node_modules if force
if [ "$FORCE_INSTALL" = true ] && [ -d "node_modules" ]; then
    print_info "Removing old node_modules (--force)..."
    rm -rf node_modules package-lock.json
fi

print_info "Running npm install..."
NPM_PATH=$(which npm 2>/dev/null || echo "/usr/bin/npm")

if "$NPM_PATH" install >> "$LOG_FILE" 2>&1; then
    MODULE_COUNT=$(ls -1 node_modules 2>/dev/null | wc -l | tr -d ' ')
    print_step "npm packages installed ($MODULE_COUNT packages)"
else
    print_warn "First npm install failed, retrying with clean cache..."
    npm cache clean --force >> "$LOG_FILE" 2>&1 || true
    rm -rf node_modules package-lock.json

    if "$NPM_PATH" install >> "$LOG_FILE" 2>&1; then
        print_step "npm packages installed (after retry)"
    else
        print_error "npm install failed"
        echo "  Check log: $LOG_FILE"
        exit 1
    fi
fi

# ============================================================================
# PHASE 6/5: Database Setup
# ============================================================================
print_phase "PHASE 6: Database Setup"

# Clear old database for fresh start
if [ "$CLEAN_INSTALL" = true ] || [ "$FORCE_INSTALL" = true ]; then
    if [ -f "$APP_DIR/server/users.db" ]; then
        rm -f "$APP_DIR/server/users.db"
        print_step "Database cleared (will recreate with default admin)"
    fi
    if [ -f "$APP_DIR/server/netviz.db" ]; then
        rm -f "$APP_DIR/server/netviz.db"
        print_step "Netviz database cleared"
    fi
else
    if [ -f "$APP_DIR/server/users.db" ]; then
        print_skip "Database exists (keeping existing data)"
    else
        print_step "Fresh database will be created on first run"
    fi
fi

# ============================================================================
# PHASE 6/6: Set Permissions
# ============================================================================
print_phase "PHASE 6: Set Permissions"

# Make all scripts executable
for SCRIPT in start.sh stop.sh restart.sh install.sh check.sh prep.sh run.sh reset.sh status.sh logs.sh clean-db.sh netviz.py; do
    if [ -f "$APP_DIR/$SCRIPT" ]; then
        chmod +x "$APP_DIR/$SCRIPT"
        echo -e "  ${GREEN}✓${NC} $SCRIPT"
    fi
done

# ============================================================================
# PHASE 7: Start Application & Validate
# ============================================================================
print_phase "PHASE 7: Start Application & Validate"

cd "$APP_DIR"

# Clear log and start
> /tmp/netviz-pro.log

print_info "Starting application..."

# Use full path for npm
NPM_PATH=$(which npm 2>/dev/null || echo "/usr/bin/npm")
nohup "$NPM_PATH" run dev:full >> /tmp/netviz-pro.log 2>&1 &
APP_PID=$!

print_info "Application starting (PID: $APP_PID)"

# Wait for startup with progress
WAIT_TIME=0
MAX_WAIT=45
printf "  Waiting: ["

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    APP=$(check_port 9040)
    AUTH=$(check_port 9041)

    if [ -n "$APP" ] && [ -n "$AUTH" ]; then
        break
    fi

    printf "."
    sleep 1
    WAIT_TIME=$((WAIT_TIME + 1))
done
printf "] ${WAIT_TIME}s\n"
echo ""

# Validate services
SERVICES_UP=0
VALIDATION_PASSED=true

if [ -n "$(check_port 9040)" ]; then
    print_step "Frontend (9040) RUNNING"
    SERVICES_UP=$((SERVICES_UP + 1))
else
    print_error "Frontend (9040) NOT RUNNING"
    VALIDATION_PASSED=false
fi

if [ -n "$(check_port 9041)" ]; then
    print_step "Backend (9041) RUNNING"
    SERVICES_UP=$((SERVICES_UP + 1))
else
    print_error "Backend (9041) NOT RUNNING"
    VALIDATION_PASSED=false
fi

echo ""

# API Health Check
if check_command curl && [ $SERVICES_UP -eq 2 ]; then
    print_info "Running API health checks..."

    # Auth API
    HEALTH=$(curl -s -m 5 http://127.0.0.1:9041/api/health 2>/dev/null || echo "FAILED")
    if echo "$HEALTH" | grep -q '"status":"ok"'; then
        print_step "Auth API: OK"
    else
        print_warn "Auth API: Not responding (may need more time)"
    fi

    # Frontend
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 5 http://localhost:9040 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        print_step "Frontend: OK (HTTP 200)"
    else
        print_warn "Frontend: HTTP $HTTP_CODE (may need more time)"
    fi
fi

# ============================================================================
# Installation Complete
# ============================================================================
echo ""
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     Installation Complete!                                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║     Installation Complete (with warnings)                    ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo "  Installation Summary:"
echo "  ├── Directory: $INSTALL_DIR"
echo "  ├── Node.js: $(node --version 2>/dev/null || echo 'N/A')"
echo "  ├── npm: v$(npm --version 2>/dev/null || echo 'N/A')"
echo "  └── Services: $SERVICES_UP/2 running"
echo ""
echo "  ┌─────────────────────────────────────────────────────────────┐"
echo "  │  Access URL:    http://localhost:9040                       │"
echo "  │  Username:      admin                                       │"
echo "  │  Password:      admin123                                    │"
echo "  │                                                             │"
echo "  │  IMPORTANT: Change password after first login!              │"
echo "  └─────────────────────────────────────────────────────────────┘"
echo ""
echo "  Management Commands:"
echo "  ├── Start:    ./start.sh"
echo "  ├── Stop:     ./stop.sh"
echo "  ├── Restart:  ./restart.sh"
echo "  ├── Status:   ./status.sh"
echo "  ├── Logs:     ./logs.sh -f"
echo "  └── Reset:    ./reset.sh --auth"
echo ""
echo "  Logs: /tmp/netviz-pro.log"
echo "  Install Log: $LOG_FILE"
echo ""
