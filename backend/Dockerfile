# Weltenbibliothek Backend - Dockerfile
# Python 3.11 Slim Base Image

FROM python:3.11-slim

# Metadata
LABEL maintainer="weltenbibliothek@example.com"
LABEL description="Weltenbibliothek Deep Research API"
LABEL version="1.0.0"

# Setze Working Directory
WORKDIR /app

# System-Pakete installieren
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Python-Abhängigkeiten installieren
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Backend-Code kopieren
COPY *.py ./
COPY config.py ./

# Port freigeben
EXPOSE 8080

# Health-Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Environment Variables
ENV PYTHONUNBUFFERED=1
ENV LOG_LEVEL=INFO

# Starte Backend-Server
CMD ["python3", "deep_research_api.py"]
