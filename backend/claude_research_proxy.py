#!/usr/bin/env python3
"""
Claude Research Proxy
Flutter → Backend → Claude API → WebSearch + Crawler → Echte Daten
"""

import os
import requests
import json
from typing import Dict, List

CLAUDE_API_KEY = os.getenv('ANTHROPIC_API_KEY', '')
CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages'

def research_with_claude(query: str, max_results: int = 10) -> Dict:
    """
    Nutze Claude API um echte Recherche durchzuführen
    Claude hat Zugriff auf WebSearch und Crawler Tools
    """
    
    if not CLAUDE_API_KEY:
        print("❌ ANTHROPIC_API_KEY nicht gesetzt!")
        return {'error': 'API Key fehlt'}
    
    print(f"🧠 Claude recherchiert: '{query}'")
    
    # Prompt für Claude
    prompt = f"""Führe eine umfassende Recherche zum Thema "{query}" durch.

Nutze WebSearch um aktuelle Quellen zu finden, dann crawle die Top-Artikel.

Liefere die Ergebnisse als JSON:
{{
  "query": "{query}",
  "sources": [
    {{
      "title": "Artikel-Titel",
      "url": "https://...",
      "source": "tagesschau.de",
      "snippet": "Kurze Zusammenfassung",
      "content": "Vollständiger Text",
      "published_at": "2026-01-03",
      "author": "Name"
    }}
  ]
}}

Crawle mindestens {max_results} verschiedene Quellen."""

    headers = {
        'x-api-key': CLAUDE_API_KEY,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
    }
    
    payload = {
        'model': 'claude-3-5-sonnet-20241022',
        'max_tokens': 8000,
        'tools': [
            {
                'name': 'web_search',
                'description': 'Search the web for information',
                'input_schema': {
                    'type': 'object',
                    'properties': {
                        'query': {'type': 'string', 'description': 'Search query'},
                    },
                    'required': ['query'],
                }
            },
            {
                'name': 'crawler',
                'description': 'Crawl a webpage',
                'input_schema': {
                    'type': 'object',
                    'properties': {
                        'url': {'type': 'string', 'description': 'URL to crawl'},
                    },
                    'required': ['url'],
                }
            }
        ],
        'messages': [
            {
                'role': 'user',
                'content': prompt
            }
        ]
    }
    
    try:
        response = requests.post(CLAUDE_API_URL, json=payload, headers=headers, timeout=60)
        response.raise_for_status()
        
        data = response.json()
        
        # Extrahiere Text-Content
        content = data.get('content', [])
        if content and len(content) > 0:
            text = content[0].get('text', '')
            
            # Parse JSON aus Response
            try:
                result = json.loads(text)
                print(f"✅ {len(result.get('sources', []))} Quellen erhalten")
                return result
            except json.JSONDecodeError:
                return {'error': 'JSON parsing failed', 'raw': text}
        
        return {'error': 'Keine Content-Response'}
        
    except Exception as e:
        print(f"❌ Claude API Fehler: {e}")
        return {'error': str(e)}


if __name__ == '__main__':
    # Test
    result = research_with_claude("Ukraine Krieg aktuelle Lage 2026", max_results=5)
    print(json.dumps(result, indent=2, ensure_ascii=False))
