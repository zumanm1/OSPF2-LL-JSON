#!/bin/bash
# NetViz Pro - Start Script
# Starts all servers in background

APP_DIR="$HOME/OSPF2-LL-JSON/netviz-pro"
LOG_FILE="/tmp/netviz-pro.log"

echo "Starting NetViz Pro..."

cd "$APP_DIR" 2>/dev/null || cd "$(dirname "$0")"

# Start in background
nohup npm run dev:full > "$LOG_FILE" 2>&1 &

echo "Waiting for servers..."
sleep 4

# Check if running
if lsof -ti:9040 > /dev/null 2>&1; then
    echo "✓ Gateway (9040) running"
else
    echo "✗ Gateway (9040) not running"
fi

if lsof -ti:9041 > /dev/null 2>&1; then
    echo "✓ Auth API (9041) running"
else
    echo "✗ Auth API (9041) not running"
fi

if lsof -ti:9042 > /dev/null 2>&1; then
    echo "✓ Vite (9042) running"
else
    echo "✗ Vite (9042) not running"
fi

echo ""
echo "Access: http://localhost:9040"
echo "Logs:   tail -f $LOG_FILE"
