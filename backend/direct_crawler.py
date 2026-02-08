#!/usr/bin/env python3
"""
Direct Web Crawler - OHNE APIs
Crawlt öffentliche Webseiten direkt mit requests + BeautifulSoup
"""

import requests
from bs4 import BeautifulSoup
import re
from typing import Dict, List, Optional
from urllib.parse import urljoin, urlparse

class DirectWebCrawler:
    """Direkter Web-Crawler ohne API-Abhängigkeiten"""
    
    def __init__(self, timeout: int = 10):
        self.timeout = timeout
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'de-DE,de;q=0.9,en;q=0.8',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
        }
    
    def search_google(self, query: str, num_results: int = 10) -> List[Dict[str, str]]:
        """
        Suche auf Google (direkt ohne API)
        Scrapt Google-Suchergebnisse
        """
        print(f"🔍 Suche auf Google: '{query}'")
        
        # Google-Suche URL
        search_url = f"https://www.google.com/search?q={requests.utils.quote(query)}&num={num_results}&hl=de"
        
        try:
            response = requests.get(search_url, headers=self.headers, timeout=self.timeout)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            results = []
            
            # Extrahiere Suchergebnisse
            for g in soup.find_all('div', class_='g'):
                # Link
                link_tag = g.find('a')
                if not link_tag or not link_tag.get('href'):
                    continue
                
                url = link_tag['href']
                
                # Titel
                title_tag = g.find('h3')
                title = title_tag.text if title_tag else 'Kein Titel'
                
                # Snippet
                snippet_tag = g.find('div', class_=['VwiC3b', 'yXK7lf'])
                snippet = snippet_tag.text if snippet_tag else ''
                
                results.append({
                    'title': title,
                    'url': url,
                    'snippet': snippet,
                })
            
            print(f"   ✅ {len(results)} Ergebnisse gefunden")
            return results
            
        except Exception as e:
            print(f"   ❌ Fehler bei Google-Suche: {e}")
            return []
    
    def crawl_page(self, url: str) -> Optional[Dict[str, str]]:
        """
        Crawle eine einzelne Webseite
        Extrahiert Text-Inhalt ohne HTML
        """
        print(f"🌐 Crawle: {url}")
        
        try:
            response = requests.get(url, headers=self.headers, timeout=self.timeout)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Entferne Script/Style-Tags
            for script in soup(["script", "style", "nav", "footer", "header"]):
                script.decompose()
            
            # Titel
            title = soup.find('title')
            title_text = title.text.strip() if title else 'Kein Titel'
            
            # Hauptinhalt (versuche verschiedene Selektoren)
            content_tags = soup.find_all(['article', 'main', 'div'], class_=re.compile('content|article|post|entry'))
            
            if not content_tags:
                # Fallback: Alle <p> Tags
                content_tags = soup.find_all('p')
            
            # Extrahiere Text
            text_parts = []
            for tag in content_tags:
                text = tag.get_text(separator=' ', strip=True)
                if text and len(text) > 50:  # Nur längere Texte
                    text_parts.append(text)
            
            full_text = '\n\n'.join(text_parts)
            
            # Zusammenfassung (erste 500 Zeichen)
            summary = full_text[:500] + '...' if len(full_text) > 500 else full_text
            
            print(f"   ✅ {len(full_text)} Zeichen extrahiert")
            
            return {
                'url': url,
                'title': title_text,
                'text': full_text,
                'summary': summary,
                'length': len(full_text),
            }
            
        except Exception as e:
            print(f"   ❌ Fehler beim Crawlen: {e}")
            return None
    
    def crawl_news_sites(self, query: str, sites: List[str], max_per_site: int = 3) -> List[Dict[str, str]]:
        """
        Crawle News-Seiten für einen Suchbegriff
        """
        print(f"\n📰 Crawle News-Seiten für: '{query}'")
        results = []
        
        for site in sites:
            # Suche auf spezifischer Seite
            site_query = f"site:{site} {query}"
            search_results = self.search_google(site_query, num_results=max_per_site)
            
            for result in search_results[:max_per_site]:
                url = result['url']
                
                # Crawle Seite
                crawled = self.crawl_page(url)
                if crawled:
                    crawled['source_site'] = site
                    crawled['search_title'] = result['title']
                    crawled['snippet'] = result['snippet']
                    results.append(crawled)
        
        print(f"\n✅ Gesamt: {len(results)} Artikel gecrawlt")
        return results


# Test-Funktion
if __name__ == '__main__':
    crawler = DirectWebCrawler()
    
    # Test 1: Google-Suche
    results = crawler.search_google("Ukraine Krieg 2026", num_results=5)
    print(f"\n{len(results)} Suchergebnisse:")
    for i, r in enumerate(results, 1):
        print(f"{i}. {r['title']}")
        print(f"   {r['url']}")
    
    # Test 2: Crawle News-Seiten
    news_sites = [
        'tagesschau.de',
        'spiegel.de',
        'zeit.de',
        'sueddeutsche.de',
    ]
    
    articles = crawler.crawl_news_sites("Ukraine Krieg", news_sites, max_per_site=2)
    print(f"\n{len(articles)} Artikel gecrawlt")
