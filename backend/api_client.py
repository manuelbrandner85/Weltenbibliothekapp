"""
Genspark API Client
Wrapper für WebSearch, Crawler und Summarize APIs
"""

import aiohttp
import asyncio
from typing import List, Dict, Optional
from config import (
    API_TOKEN,
    WEBSEARCH_ENDPOINT,
    CRAWLER_ENDPOINT,
    SUMMARIZE_ENDPOINT,
    WEBSEARCH_TIMEOUT,
    CRAWLER_TIMEOUT,
    SUMMARIZE_TIMEOUT,
)


class GensparkAPIClient:
    """
    Client für Genspark AI APIs
    
    Unterstützt:
    - WebSearch: Finde URLs zu Suchbegriff
    - Crawler: Lade Website-Inhalte
    - Summarize: Fasse Text zusammen
    """
    
    def __init__(self, api_token: str = API_TOKEN):
        self.api_token = api_token
        self.session = None
    
    async def __aenter__(self):
        """Async Context Manager - Erstelle Session"""
        self.session = aiohttp.ClientSession(
            headers={
                'Authorization': f'Bearer {self.api_token}',
                'Content-Type': 'application/json',
            }
        )
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async Context Manager - Schließe Session"""
        if self.session:
            await self.session.close()
    
    async def websearch(
        self,
        query: str,
        allowed_domains: Optional[List[str]] = None,
        max_results: int = 20,
    ) -> List[Dict[str, str]]:
        """
        WebSearch: Finde URLs zu Suchbegriff
        
        Args:
            query: Suchbegriff (z.B. "Ukraine Krieg")
            allowed_domains: Liste erlaubter Domains (optional)
            max_results: Maximale Anzahl Ergebnisse
        
        Returns:
            Liste von Dictionaries mit 'title' und 'url'
        """
        print(f"🔍 [WebSearch] Query: '{query}', Max: {max_results}")
        
        if not self.session:
            raise RuntimeError("Session nicht initialisiert - nutze async with")
        
        # Request-Body
        payload = {
            'query': query,
            'max_results': max_results,
        }
        
        if allowed_domains:
            payload['allowed_domains'] = allowed_domains
        
        try:
            async with self.session.post(
                WEBSEARCH_ENDPOINT,
                json=payload,
                timeout=aiohttp.ClientTimeout(total=WEBSEARCH_TIMEOUT),
            ) as response:
                
                if response.status == 200:
                    data = await response.json()
                    
                    # Extrahiere Ergebnisse
                    results = []
                    for item in data.get('results', []):
                        results.append({
                            'title': item.get('title', 'Unbekannt'),
                            'url': item.get('url', ''),
                            'snippet': item.get('snippet', ''),
                        })
                    
                    print(f"   ✅ {len(results)} Ergebnisse gefunden")
                    return results
                
                else:
                    error_text = await response.text()
                    print(f"   ❌ WebSearch Fehler: {response.status} - {error_text}")
                    raise Exception(f"WebSearch API Error: {response.status}")
        
        except asyncio.TimeoutError:
            print(f"   ⚠️ WebSearch Timeout nach {WEBSEARCH_TIMEOUT}s")
            raise Exception("WebSearch Timeout")
        
        except Exception as e:
            print(f"   ❌ WebSearch Exception: {e}")
            raise
    
    async def crawl(self, url: str) -> Dict[str, str]:
        """
        Crawler: Lade Website-Inhalte
        
        Args:
            url: URL der zu crawlenden Website
        
        Returns:
            Dictionary mit 'text', 'title', 'author', etc.
        """
        print(f"🌐 [Crawler] URL: {url}")
        
        if not self.session:
            raise RuntimeError("Session nicht initialisiert - nutze async with")
        
        # Request-Body
        payload = {
            'url': url,
            'include_html': False,  # Nur Text, kein HTML
        }
        
        try:
            async with self.session.post(
                CRAWLER_ENDPOINT,
                json=payload,
                timeout=aiohttp.ClientTimeout(total=CRAWLER_TIMEOUT),
            ) as response:
                
                if response.status == 200:
                    data = await response.json()
                    
                    text = data.get('text', '')
                    print(f"   ✅ {len(text)} Zeichen extrahiert")
                    
                    return {
                        'text': text,
                        'title': data.get('title', ''),
                        'author': data.get('author'),
                        'published_at': data.get('published_at'),
                    }
                
                else:
                    error_text = await response.text()
                    print(f"   ❌ Crawler Fehler: {response.status} - {error_text}")
                    raise Exception(f"Crawler API Error: {response.status}")
        
        except asyncio.TimeoutError:
            print(f"   ⚠️ Crawler Timeout nach {CRAWLER_TIMEOUT}s")
            raise Exception("Crawler Timeout")
        
        except Exception as e:
            print(f"   ❌ Crawler Exception: {e}")
            raise
    
    async def summarize(
        self,
        text: str,
        language: str = 'de',
        max_length: int = 200,
    ) -> str:
        """
        Summarize: Fasse Text zusammen
        
        Args:
            text: Zu fassender Text
            language: Zielsprache (de, en, etc.)
            max_length: Maximale Länge der Zusammenfassung (Wörter)
        
        Returns:
            Zusammengefasster Text
        """
        print(f"📝 [Summarize] Text: {len(text)} Zeichen → {language}")
        
        if not self.session:
            raise RuntimeError("Session nicht initialisiert - nutze async with")
        
        # Request-Body
        payload = {
            'text': text[:10000],  # Limit auf 10k Zeichen
            'language': language,
            'max_length': max_length,
        }
        
        try:
            async with self.session.post(
                SUMMARIZE_ENDPOINT,
                json=payload,
                timeout=aiohttp.ClientTimeout(total=SUMMARIZE_TIMEOUT),
            ) as response:
                
                if response.status == 200:
                    data = await response.json()
                    
                    summary = data.get('summary', '')
                    print(f"   ✅ {len(summary)} Zeichen Zusammenfassung")
                    
                    return summary
                
                else:
                    error_text = await response.text()
                    print(f"   ❌ Summarize Fehler: {response.status} - {error_text}")
                    # Fallback: Erste 200 Wörter
                    words = text.split()[:max_length]
                    return ' '.join(words) + '...'
        
        except asyncio.TimeoutError:
            print(f"   ⚠️ Summarize Timeout nach {SUMMARIZE_TIMEOUT}s")
            # Fallback
            words = text.split()[:max_length]
            return ' '.join(words) + '...'
        
        except Exception as e:
            print(f"   ❌ Summarize Exception: {e}")
            # Fallback
            words = text.split()[:max_length]
            return ' '.join(words) + '...'


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

async def test_api_connection():
    """Test API-Verbindung"""
    print("🧪 Teste Genspark API-Verbindung...")
    
    try:
        async with GensparkAPIClient() as client:
            # Test WebSearch
            results = await client.websearch("test query", max_results=3)
            print(f"✅ WebSearch: {len(results)} Ergebnisse")
            
            if results:
                # Test Crawler
                url = results[0]['url']
                content = await client.crawl(url)
                print(f"✅ Crawler: {len(content['text'])} Zeichen")
                
                # Test Summarize
                summary = await client.summarize(content['text'][:1000])
                print(f"✅ Summarize: {len(summary)} Zeichen")
        
        print("✅ API-Verbindung erfolgreich!")
        return True
    
    except Exception as e:
        print(f"❌ API-Verbindung fehlgeschlagen: {e}")
        return False


if __name__ == '__main__':
    # Test-Modus
    asyncio.run(test_api_connection())
