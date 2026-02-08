#!/bin/bash

# Keep Flutter Web Server Alive
# Prüft alle 30 Sekunden ob Server läuft, startet bei Bedarf neu

while true; do
  if ! lsof -i :5060 > /dev/null 2>&1; then
    echo "[$(date)] ⚠️  Server auf Port 5060 ist gestoppt - starte neu..."
    cd /home/user/flutter_app
    nohup python3 -m http.server 5060 --directory build/web --bind 0.0.0.0 > /tmp/flutter_server.log 2>&1 &
    sleep 3
    if lsof -i :5060 > /dev/null 2>&1; then
      echo "[$(date)] ✅ Server erfolgreich gestartet!"
    else
      echo "[$(date)] ❌ Server-Start fehlgeschlagen!"
    fi
  else
    echo "[$(date)] ✅ Server läuft"
  fi
  
  sleep 30
done
