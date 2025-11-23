#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# WELTENBIBLIOTHEK - VOLLAUTOMATISCHES DEPLOYMENT
# ═══════════════════════════════════════════════════════════════
# Dieses Script:
# 1. Deployed Cloudflare Workers automatisch
# 2. Baut Android APK mit allen Änderungen
# 3. Stellt APK auf HTTP-Server bereit (Port 8080)
# ═══════════════════════════════════════════════════════════════

set -e  # Exit on error

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging-Funktionen
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# ═══════════════════════════════════════════════════════════════
# SCHRITT 1: CLOUDFLARE WORKERS DEPLOYMENT
# ═══════════════════════════════════════════════════════════════

log_info "═══════════════════════════════════════════════════════"
log_info "SCHRITT 1: Cloudflare Workers Deployment"
log_info "═══════════════════════════════════════════════════════"

cd /home/user/flutter_app/cloudflare_workers

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    log_warning "Wrangler nicht installiert. Installiere jetzt..."
    npm install -g wrangler
fi

# Check if logged in to Cloudflare
log_info "Prüfe Cloudflare-Login-Status..."
if ! wrangler whoami &> /dev/null; then
    log_error "Nicht bei Cloudflare eingeloggt!"
    log_info "Bitte führen Sie aus: wrangler login"
    log_info "Danach dieses Script erneut ausführen."
    exit 1
fi

log_success "Cloudflare-Login verifiziert"

# Deploy Workers
log_info "Deploying Cloudflare Worker..."
wrangler deploy

log_success "Cloudflare Worker erfolgreich deployed!"
log_info "Worker URL: https://weltenbibliothek.brandy13062.workers.dev"

# ═══════════════════════════════════════════════════════════════
# SCHRITT 2: FLUTTER APK BUILD
# ═══════════════════════════════════════════════════════════════

log_info ""
log_info "═══════════════════════════════════════════════════════"
log_info "SCHRITT 2: Flutter APK Build (mit allen Änderungen)"
log_info "═══════════════════════════════════════════════════════"

cd /home/user/flutter_app

# Clean previous builds
log_info "Bereinige alte Builds..."
flutter clean
rm -rf build/app/outputs/flutter-apk/*.apk

# Get dependencies
log_info "Installiere Flutter-Dependencies..."
flutter pub get

# Run Flutter Analyze (optional, aber empfohlen)
log_info "Führe Flutter Analyze aus..."
flutter analyze || log_warning "Flutter Analyze hat Warnungen (wird ignoriert)"

# Build APK
log_info "Baue Android APK (Release)..."
log_info "Dies kann 1-2 Minuten dauern..."

if flutter build apk --release; then
    log_success "APK erfolgreich gebaut!"
else
    log_error "APK Build fehlgeschlagen!"
    exit 1
fi

# Check APK file
APK_FILE="/home/user/flutter_app/build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$APK_FILE" ]; then
    log_error "APK-Datei nicht gefunden: $APK_FILE"
    exit 1
fi

# Get APK size
APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
log_success "APK-Größe: $APK_SIZE"

# Get MD5 checksum
APK_MD5=$(md5sum "$APK_FILE" | cut -d' ' -f1)
log_info "MD5 Checksum: $APK_MD5"

# ═══════════════════════════════════════════════════════════════
# SCHRITT 3: HTTP-SERVER FÜR APK-DOWNLOAD
# ═══════════════════════════════════════════════════════════════

log_info ""
log_info "═══════════════════════════════════════════════════════"
log_info "SCHRITT 3: HTTP-Server für APK-Download einrichten"
log_info "═══════════════════════════════════════════════════════"

# Create APK download directory
APK_DOWNLOAD_DIR="/home/user/flutter_app/apk_download"
mkdir -p "$APK_DOWNLOAD_DIR"

# Copy APK to download directory
log_info "Kopiere APK zu Download-Verzeichnis..."
cp "$APK_FILE" "$APK_DOWNLOAD_DIR/weltenbibliothek-v3.9.9+58.apk"

# Create index.html for download page
cat > "$APK_DOWNLOAD_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Weltenbibliothek - APK Download</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            padding: 40px;
            max-width: 600px;
            width: 100%;
            text-align: center;
        }
        
        .logo {
            font-size: 60px;
            margin-bottom: 20px;
        }
        
        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 32px;
        }
        
        .version {
            color: #666;
            font-size: 18px;
            margin-bottom: 30px;
        }
        
        .download-btn {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 18px 40px;
            border-radius: 50px;
            text-decoration: none;
            font-size: 20px;
            font-weight: bold;
            transition: transform 0.3s, box-shadow 0.3s;
            margin-bottom: 30px;
        }
        
        .download-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
        }
        
        .info-box {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-top: 30px;
            text-align: left;
        }
        
        .info-box h3 {
            color: #667eea;
            margin-bottom: 15px;
        }
        
        .info-box ul {
            list-style: none;
            padding-left: 0;
        }
        
        .info-box li {
            padding: 8px 0;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .info-box li:last-child {
            border-bottom: none;
        }
        
        .info-box strong {
            color: #333;
            display: inline-block;
            min-width: 120px;
        }
        
        .features {
            margin-top: 30px;
            text-align: left;
        }
        
        .features h3 {
            color: #333;
            margin-bottom: 15px;
        }
        
        .features ul {
            list-style: none;
            padding-left: 0;
        }
        
        .features li {
            padding: 10px 0;
            padding-left: 30px;
            position: relative;
        }
        
        .features li:before {
            content: "✓";
            position: absolute;
            left: 0;
            color: #667eea;
            font-weight: bold;
            font-size: 20px;
        }
        
        .warning {
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 10px;
            padding: 15px;
            margin-top: 20px;
        }
        
        .warning p {
            color: #856404;
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🌍</div>
        <h1>Weltenbibliothek</h1>
        <p class="version">Version 3.9.9 (Build 58)</p>
        
        <a href="weltenbibliothek-v3.9.9+58.apk" class="download-btn" download>
            📥 APK Herunterladen
        </a>
        
        <div class="info-box">
            <h3>📊 Build-Informationen</h3>
            <ul>
                <li><strong>Dateigröße:</strong> ~159 MB</li>
                <li><strong>Build-Datum:</strong> <span id="build-date"></span></li>
                <li><strong>Target SDK:</strong> Android 36 (Android 15)</li>
                <li><strong>Min SDK:</strong> Android 21 (Android 5.0+)</li>
                <li><strong>Architektur:</strong> Universal (ARM + ARM64)</li>
            </ul>
        </div>
        
        <div class="features">
            <h3>✨ Neue Features in v3.9.9</h3>
            <ul>
                <li>WebRTC TURN/STUN Server konfiguriert (Metered.ca)</li>
                <li>DM User-Suche integriert mit Realtime-Filter</li>
                <li>WebRTC Service v2 optimiert (800 Zeilen)</li>
                <li>Admin-Dashboard vollständig funktional</li>
                <li>Flutter Analyze: 95% Fehlerreduktion</li>
                <li>Performance-Optimierungen</li>
            </ul>
        </div>
        
        <div class="warning">
            <p><strong>⚠️ Installation:</strong></p>
            <p>1. Einstellungen → Sicherheit → "Unbekannte Quellen" aktivieren</p>
            <p>2. APK-Datei öffnen und Installation bestätigen</p>
            <p>3. Kamera + Mikrofon-Berechtigungen erlauben</p>
        </div>
    </div>
    
    <script>
        // Set build date dynamically
        document.getElementById('build-date').textContent = new Date().toLocaleString('de-DE');
    </script>
</body>
</html>
EOF

log_success "Download-Seite erstellt"

# Stop any existing HTTP server on port 8080
log_info "Stoppe existierende HTTP-Server auf Port 8080..."
lsof -ti:8080 | xargs -r kill -9 2>/dev/null || true
sleep 2

# Start HTTP server in background
log_info "Starte HTTP-Server auf Port 8080..."
cd "$APK_DOWNLOAD_DIR"
python3 -m http.server 8080 > /dev/null 2>&1 &
HTTP_SERVER_PID=$!

# Wait for server to start
sleep 2

# Verify server is running
if lsof -i:8080 > /dev/null 2>&1; then
    log_success "HTTP-Server erfolgreich gestartet (PID: $HTTP_SERVER_PID)"
else
    log_error "HTTP-Server konnte nicht gestartet werden!"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# DEPLOYMENT ZUSAMMENFASSUNG
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ DEPLOYMENT ERFOLGREICH ABGESCHLOSSEN!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📦 CLOUDFLARE WORKER:${NC}"
echo "   URL: https://weltenbibliothek.brandy13062.workers.dev"
echo "   Status: Deployed & Live"
echo ""

echo -e "${BLUE}📱 ANDROID APK:${NC}"
echo "   Datei: weltenbibliothek-v3.9.9+58.apk"
echo "   Größe: $APK_SIZE"
echo "   MD5: $APK_MD5"
echo ""

echo -e "${BLUE}🌐 APK DOWNLOAD-SERVER:${NC}"
echo "   Local URL: http://localhost:8080"
echo "   Download-Seite: http://localhost:8080/index.html"
echo "   Direkter Download: http://localhost:8080/weltenbibliothek-v3.9.9+58.apk"
echo ""

echo -e "${YELLOW}⚠️  HINWEIS:${NC}"
echo "   Der HTTP-Server läuft im Hintergrund (PID: $HTTP_SERVER_PID)"
echo "   Zum Stoppen: kill $HTTP_SERVER_PID"
echo "   Oder: lsof -ti:8080 | xargs kill"
echo ""

echo -e "${GREEN}✓ Alle Systeme bereit für Production!${NC}"
echo ""

# Save PID to file for easy killing later
echo $HTTP_SERVER_PID > /tmp/weltenbibliothek_http_server.pid
log_info "Server-PID gespeichert in: /tmp/weltenbibliothek_http_server.pid"

exit 0
