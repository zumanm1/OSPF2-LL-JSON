#!/bin/bash
# NetViz Pro - Stop Script
# Stops all running servers

echo "Stopping NetViz Pro..."

STOPPED=0

for PORT in 9040 9041 9042; do
    PID=$(lsof -ti:$PORT 2>/dev/null)
    if [ -n "$PID" ]; then
        kill -9 $PID 2>/dev/null
        echo "✓ Stopped process on port $PORT (PID: $PID)"
        STOPPED=$((STOPPED + 1))
    fi
done

if [ $STOPPED -eq 0 ]; then
    echo "No running servers found."
else
    echo ""
    echo "Stopped $STOPPED server(s)."
fi
