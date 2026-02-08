"""
Konfiguration für Weltenbibliothek Backend
"""

import os

# ============================================================================
# API CONFIGURATION
# ============================================================================

# API Token (aus Environment oder direkt)
API_TOKEN = os.getenv('GENSPARK_API_TOKEN', '_C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv')

# API Endpoints
WEBSEARCH_ENDPOINT = 'https://api.genspark.ai/v1/websearch'
CRAWLER_ENDPOINT = 'https://api.genspark.ai/v1/crawler'
SUMMARIZE_ENDPOINT = 'https://api.genspark.ai/v1/summarize'

# ============================================================================
# ENGINE CONFIGURATION
# ============================================================================

# Parallele Verarbeitung
MAX_PARALLEL_REQUESTS = 5

# Rate-Limiting
RATE_LIMIT_DELAY = 1.0  # Sekunden zwischen Requests

# Timeouts
WEBSEARCH_TIMEOUT = 30  # Sekunden
CRAWLER_TIMEOUT = 30     # Sekunden
SUMMARIZE_TIMEOUT = 20   # Sekunden

# ============================================================================
# QUELLENTYP-MAPPINGS
# ============================================================================

QUELLENTYP_DOMAINS = {
    'news': [
        'reuters.com', 'spiegel.de', 'zeit.de', 'sueddeutsche.de',
        'bbc.com', 'aljazeera.com', 'propublica.org', 'theintercept.com',
        'correctiv.org', 'bellingcat.com', 'tagesschau.de', 'faz.net',
    ],
    'science': [
        'scholar.google.com', 'ncbi.nlm.nih.gov', 'arxiv.org',
        'doaj.org', 'core.ac.uk', 'openaire.eu', 'researchgate.net',
    ],
    'government': [
        'bundesregierung.de', 'bundestag.de', 'europarl.europa.eu',
        'whitehouse.gov', 'congress.gov', 'gov.uk', 'data.gov',
    ],
    'legal': [
        'bundesverfassungsgericht.de', 'bundesgerichtshof.de',
        'eur-lex.europa.eu', 'hudoc.echr.coe.int', 'supreme.justia.com',
    ],
    'archive': [
        'archive.org', 'dnb.de', 'loc.gov', 'europeana.eu',
    ],
    'multimedia': [
        'youtube.com', 'vimeo.com', 'arte.tv', 'phoenix.de',
        'c-span.org', 'mediathek.ard.de', 'zdf.de',
    ],
}

# ============================================================================
# LOGGING
# ============================================================================

LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
LOG_FORMAT = '%(asctime)s [%(levelname)s] %(message)s'
LOG_FILE = 'backend.log'
