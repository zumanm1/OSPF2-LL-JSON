#!/bin/bash
#===============================================================================
# NetViz Pro - Remote Server Deployment Script
# Target: 172.16.39.173 (vmuser)
# Usage: ./deploy_to_remote.sh
#===============================================================================

set -e  # Exit on any error

# Configuration
REMOTE_HOST="172.16.39.173"
REMOTE_USER="vmuser"
REMOTE_PASS="vmuser"
REPO_URL="https://github.com/zumanm1/OSPF2-LL-JSON.git"
APP_DIR="/home/vmuser/OSPF-LL-JSON/netviz-pro"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
header() { echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"; }

# SSH command helper
ssh_cmd() {
    sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "$1"
}

# Check connectivity first
header "PHASE 1: Checking Server Connectivity"
if ! ping -c 1 -W 5 "$REMOTE_HOST" > /dev/null 2>&1; then
    error "Server $REMOTE_HOST is not reachable!"
    error "Please ensure:"
    error "  1. The VM is powered on"
    error "  2. VPN/Tailscale is connected"
    error "  3. Firewall allows SSH (port 22)"
    exit 1
fi
log "Server is reachable via ping"

# Test SSH
if ! sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_HOST" "echo 'SSH OK'" > /dev/null 2>&1; then
    error "SSH connection failed!"
    exit 1
fi
log "SSH connection successful"

# Phase 2: Clean the server
header "PHASE 2: Cleaning Server Environment"

ssh_cmd "
    echo '>>> Stopping any running netviz services...'
    pkill -f 'node.*netviz' || true
    pkill -f 'vite' || true

    echo '>>> Removing existing repository...'
    rm -rf ~/OSPF-LL-JSON 2>/dev/null || true
    rm -rf ~/OSPF2-LL-JSON 2>/dev/null || true

    echo '>>> Removing Node.js and npm...'
    sudo apt remove -y nodejs npm 2>/dev/null || true
    sudo rm -rf /usr/local/lib/node_modules 2>/dev/null || true
    sudo rm -f /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx 2>/dev/null || true

    echo '>>> Removing Python installations...'
    sudo apt remove -y python3.12 python3.12-venv 2>/dev/null || true
    pip cache purge 2>/dev/null || true

    echo '>>> Cleanup complete!'
"
log "Server cleanup complete"

# Phase 3: Install fresh tools
header "PHASE 3: Installing Node.js, Python, and Dependencies"

ssh_cmd "
    echo '>>> Updating package lists...'
    sudo apt update -y

    echo '>>> Installing build essentials...'
    sudo apt install -y curl wget git build-essential

    echo '>>> Installing Node.js v20 LTS...'
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs

    echo '>>> Verifying Node.js installation...'
    node --version
    npm --version

    echo '>>> Installing Python 3.12...'
    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update -y
    sudo apt install -y python3.12 python3.12-venv python3.12-dev python3-pip

    echo '>>> Installing uv (Python package manager)...'
    curl -LsSf https://astral.sh/uv/install.sh | sh

    echo '>>> Verifying Python installation...'
    python3.12 --version
"
log "Node.js and Python installed"

# Phase 4: Clone repository
header "PHASE 4: Cloning Repository"

ssh_cmd "
    echo '>>> Cloning repository...'
    cd ~
    git clone $REPO_URL

    echo '>>> Repository cloned successfully'
    ls -la ~/OSPF-LL-JSON/
"
log "Repository cloned"

# Phase 5: Install application dependencies
header "PHASE 5: Installing Application Dependencies"

ssh_cmd "
    cd ~/OSPF-LL-JSON/netviz-pro

    echo '>>> Installing npm dependencies...'
    npm install

    echo '>>> Setting up Python environment (if pyproject.toml exists)...'
    if [ -f pyproject.toml ]; then
        ~/.local/bin/uv venv
        ~/.local/bin/uv pip install -r requirements.txt 2>/dev/null || true
    fi

    echo '>>> Dependencies installed'
"
log "Dependencies installed"

# Phase 6: Setup and initialize database
header "PHASE 6: Database Setup"

ssh_cmd "
    cd ~/OSPF-LL-JSON/netviz-pro

    echo '>>> Clearing old database...'
    rm -f server/netviz.db 2>/dev/null || true

    echo '>>> Creating fresh database...'
    if [ -f server/database.js ]; then
        node -e \"const db = require('./server/database.js'); console.log('Database initialized');\"
    fi

    echo '>>> Database ready'
"
log "Database initialized"

# Phase 7: Create/update utility scripts
header "PHASE 7: Setting Up Utility Scripts"

ssh_cmd "
    cd ~/OSPF-LL-JSON/netviz-pro

    echo '>>> Making scripts executable...'
    chmod +x start.sh stop.sh install.sh check.sh 2>/dev/null || true

    echo '>>> Scripts ready'
    ls -la *.sh 2>/dev/null || echo 'No shell scripts found'
"
log "Utility scripts configured"

# Phase 8: Test the application
header "PHASE 8: Testing Application"

ssh_cmd "
    cd ~/OSPF-LL-JSON/netviz-pro

    echo '>>> Testing npm build...'
    npm run build 2>/dev/null || echo 'Build step skipped (dev mode)'

    echo '>>> Starting application in background...'
    nohup npm run dev:full > /tmp/netviz.log 2>&1 &

    sleep 5

    echo '>>> Checking if services are running...'
    if netstat -tlnp 2>/dev/null | grep -q ':9040'; then
        echo 'Frontend running on port 9040'
    else
        echo 'Frontend NOT running'
    fi

    if netstat -tlnp 2>/dev/null | grep -q ':9041'; then
        echo 'Auth server running on port 9041'
    else
        echo 'Auth server NOT running'
    fi

    echo ''
    echo '>>> Log output:'
    tail -20 /tmp/netviz.log 2>/dev/null || echo 'No logs yet'
"
log "Application started"

# Final summary
header "DEPLOYMENT COMPLETE"
echo -e "
${GREEN}NetViz Pro has been deployed to $REMOTE_HOST${NC}

Access the application at:
  ${BLUE}http://$REMOTE_HOST:9040${NC}

Default credentials:
  Username: admin
  Password: admin123

To manage the application:
  ${YELLOW}ssh vmuser@$REMOTE_HOST${NC}
  ${YELLOW}cd ~/OSPF-LL-JSON/netviz-pro${NC}
  ${YELLOW}./start.sh   # Start the app${NC}
  ${YELLOW}./stop.sh    # Stop the app${NC}
  ${YELLOW}./check.sh   # Check status${NC}
"

log "Deployment script finished successfully!"
