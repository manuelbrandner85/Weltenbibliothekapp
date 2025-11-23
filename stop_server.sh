#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# HTTP-Server stoppen
# ═══════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Stoppe HTTP-Server auf Port 8080...${NC}"

# Method 1: Kill by PID file
if [ -f /tmp/weltenbibliothek_http_server.pid ]; then
    PID=$(cat /tmp/weltenbibliothek_http_server.pid)
    if kill $PID 2>/dev/null; then
        echo -e "${GREEN}✓ HTTP-Server gestoppt (PID: $PID)${NC}"
        rm /tmp/weltenbibliothek_http_server.pid
    else
        echo -e "${YELLOW}⚠ Server mit PID $PID nicht gefunden${NC}"
    fi
fi

# Method 2: Kill all processes on port 8080
if lsof -ti:8080 > /dev/null 2>&1; then
    lsof -ti:8080 | xargs kill -9
    echo -e "${GREEN}✓ Alle Prozesse auf Port 8080 gestoppt${NC}"
else
    echo -e "${GREEN}✓ Kein Server läuft auf Port 8080${NC}"
fi

echo ""
echo -e "${GREEN}✓ Server erfolgreich gestoppt${NC}"
