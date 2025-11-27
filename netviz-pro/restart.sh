#!/bin/bash
# NetViz Pro - Restart Script
# Stops and starts all servers

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Restarting NetViz Pro..."
echo ""

# Stop
"$SCRIPT_DIR/stop.sh"

sleep 2

# Start
"$SCRIPT_DIR/start.sh"
