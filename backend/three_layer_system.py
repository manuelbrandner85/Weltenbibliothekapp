#!/usr/bin/env python3
"""
WELTENBIBLIOTHEK - 3-EBENEN-SYSTEM

EBENE 1: ECHTZEIT-DATEN (Crawler/Search)
  → Sammelt ECHTE aktuelle Daten von Webseiten
  → Keine APIs, direkt HTML crawlen
  → Nutzt: requests + BeautifulSoup

EBENE 2: KI-ANALYSE
  → Analysiert gesammelte Daten
  → Findet Muster, Akteure, Zusammenhänge
  → Generiert alternative Sichtweisen
  → Nutzt: Cloudflare AI Workers / lokale NLP

EBENE 3: VISUALISIERUNG (Flutter)
  → Zeigt strukturierte Ergebnisse
  → Charts, Karten, Timeline
"""

import asyncio
import requests
from bs4 import BeautifulSoup
from typing import List, Dict
import re
from datetime import datetime
import json

# ============================================================================
# EBENE 1: ECHTZEIT-DATEN-LAYER
# ============================================================================

class RealTimeDataCollector:
    """
    Sammelt ECHTE Daten von öffentlichen Webseiten
    OHNE API-Abhängigkeiten
    """
    
    def __init__(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'de-DE,de;q=0.9',
        }
        
        # Vordefinierte Nachrichten-Seiten (ohne APIs)
        self.news_sites = {
            'tagesschau': 'https://www.tagesschau.de',
            'spiegel': 'https://www.spiegel.de',
            'zeit': 'https://www.zeit.de',
            'sueddeutsche': 'https://www.sueddeutsche.de',
            'faz': 'https://www.faz.net',
            'welt': 'https://www.welt.de',
        }
    
    def collect_data(self, query: str) -> List[Dict]:
        """
        EBENE 1: Sammle ECHTE Daten
        
        Strategie:
        1. Gehe zu Nachrichten-Hauptseiten
        2. Suche nach Artikeln zum Thema (in HTML)
        3. Crawle gefundene Artikel
        4. Extrahiere Text-Inhalt
        """
        print(f"\n{'='*60}")
        print(f"EBENE 1: ECHTZEIT-DATEN-SAMMLUNG")
        print(f"Thema: {query}")
        print(f"{'='*60}\n")
        
        collected_data = []
        
        for site_name, base_url in self.news_sites.items():
            print(f"📰 Crawle {site_name}...")
            
            try:
                # Strategie: Crawle Hauptseite, suche nach relevanten Links
                articles = self._find_articles_on_site(base_url, query, site_name)
                collected_data.extend(articles)
                
                if len(articles) > 0:
                    print(f"   ✅ {len(articles)} Artikel gefunden")
                
            except Exception as e:
                print(f"   ⚠️ Fehler: {e}")
        
        print(f"\n✅ EBENE 1 ABGESCHLOSSEN: {len(collected_data)} Quellen gesammelt\n")
        return collected_data
    
    def _find_articles_on_site(self, base_url: str, query: str, site_name: str) -> List[Dict]:
        """Finde Artikel auf einer Seite (ohne API)"""
        
        try:
            # Hole Hauptseite
            response = requests.get(base_url, headers=self.headers, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Finde alle Links
            links = soup.find_all('a', href=True)
            
            articles = []
            query_lower = query.lower()
            
            for link in links[:50]:  # Limitiere auf 50 Links
                href = link['href']
                text = link.get_text(strip=True)
                
                # Prüfe ob Link zum Thema passt
                if not text or len(text) < 10:
                    continue
                
                # Einfache Keyword-Suche
                if any(keyword in text.lower() for keyword in query_lower.split()):
                    # Baue vollständige URL
                    if href.startswith('/'):
                        full_url = base_url + href
                    elif href.startswith('http'):
                        full_url = href
                    else:
                        continue
                    
                    # Crawle Artikel
                    article = self._crawl_article(full_url, text, site_name)
                    if article:
                        articles.append(article)
                        
                        # Max 3 Artikel pro Seite
                        if len(articles) >= 3:
                            break
            
            return articles
            
        except Exception as e:
            print(f"   Fehler bei {site_name}: {e}")
            return []
    
    def _crawl_article(self, url: str, title: str, source: str) -> Dict:
        """Crawle einzelnen Artikel"""
        
        try:
            response = requests.get(url, headers=self.headers, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Entferne Script/Style
            for tag in soup(['script', 'style', 'nav', 'footer', 'header']):
                tag.decompose()
            
            # Extrahiere Text aus <p> Tags
            paragraphs = soup.find_all('p')
            text_parts = [p.get_text(strip=True) for p in paragraphs if len(p.get_text(strip=True)) > 50]
            
            full_text = '\n\n'.join(text_parts)
            
            if len(full_text) < 200:
                return None
            
            return {
                'id': f"{source}_{hash(url)}",
                'title': title,
                'url': url,
                'source': source,
                'type': 'news',
                'content': full_text,
                'summary': full_text[:500] + '...',
                'published_at': datetime.now().isoformat(),
                'length': len(full_text),
            }
            
        except Exception as e:
            return None


# ============================================================================
# EBENE 2: KI-ANALYSE-LAYER
# ============================================================================

class AIAnalysisLayer:
    """
    EBENE 2: Analysiert gesammelte Daten mit KI
    """
    
    def analyze_data(self, data: List[Dict], query: str) -> Dict:
        """
        EBENE 2: KI-Analyse der Daten
        
        Analysiert:
        - Hauptakteure
        - Machtstrukturen
        - Geldflüsse
        - Narrative
        - Zeitliche Entwicklung
        - Alternative Sichtweisen
        """
        print(f"\n{'='*60}")
        print(f"EBENE 2: KI-ANALYSE")
        print(f"Analysiere {len(data)} Quellen...")
        print(f"{'='*60}\n")
        
        # Extrahiere alle Texte
        all_text = '\n\n'.join([d['content'] for d in data])
        
        # Simple NLP-Analyse (später mit Cloudflare AI ersetzen)
        analysis = {
            'query': query,
            'timestamp': datetime.now().isoformat(),
            
            # Akteure-Erkennung
            'actors': self._extract_actors(all_text),
            
            # Narrative
            'narratives': self._extract_narratives(data),
            
            # Timeline
            'timeline': self._create_timeline(data),
            
            # Alternative Sichtweisen
            'alternative_views': self._generate_alternatives(all_text, query),
            
            # Meta-Kontext
            'meta_context': self._analyze_meta(data),
        }
        
        print(f"✅ EBENE 2 ABGESCHLOSSEN")
        print(f"   Akteure: {len(analysis['actors'])}")
        print(f"   Narrative: {len(analysis['narratives'])}")
        print(f"   Timeline: {len(analysis['timeline'])}")
        print(f"   Alternative Sichtweisen: {len(analysis['alternative_views'])}\n")
        
        return analysis
    
    def _extract_actors(self, text: str) -> List[Dict]:
        """Extrahiere Akteure (simple Regex)"""
        
        # Suche nach Eigennamen
        actors = []
        
        # Regierungen/Organisationen
        orgs = re.findall(r'\b(Ukraine|Russland|USA|EU|NATO|Bundeswehr|Kreml)\b', text)
        for org in set(orgs):
            actors.append({
                'id': f'actor_{org.lower()}',
                'name': org,
                'typ': 'regierung',
                'mentions': orgs.count(org),
            })
        
        # Personen (mit Titel)
        persons = re.findall(r'\b(Präsident|Kanzler|Minister)\s+(\w+(?:\s+\w+)?)', text)
        for title, name in set(persons):
            actors.append({
                'id': f'actor_{name.lower().replace(" ", "_")}',
                'name': f'{title} {name}',
                'typ': 'person',
                'mentions': 1,
            })
        
        return actors[:10]  # Top 10
    
    def _extract_narratives(self, data: List[Dict]) -> List[Dict]:
        """Extrahiere Narrative"""
        narratives = []
        
        for item in data:
            narratives.append({
                'id': f'narrative_{item["id"]}',
                'titel': item['title'],
                'beschreibung': item['summary'],
                'quelle': item['source'],
            })
        
        return narratives
    
    def _create_timeline(self, data: List[Dict]) -> List[Dict]:
        """Erstelle Timeline"""
        timeline = []
        
        for item in data:
            timeline.append({
                'id': f'event_{item["id"]}',
                'datum': item['published_at'],
                'ereignis': item['title'],
                'beschreibung': item['summary'],
                'quelle': item['url'],
            })
        
        return sorted(timeline, key=lambda x: x['datum'])
    
    def _generate_alternatives(self, text: str, query: str) -> List[Dict]:
        """Generiere alternative Sichtweisen"""
        
        # Basis-Alternative
        return [{
            'id': 'alt_view_1',
            'titel': f'Alternative Perspektive zu: {query}',
            'these': 'Verschiedene Interpretationen der Ereignisse sind möglich',
            'beschreibung': 'Basierend auf den gesammelten Quellen gibt es unterschiedliche Perspektiven',
        }]
    
    def _analyze_meta(self, data: List[Dict]) -> str:
        """Meta-Kontext Analyse"""
        
        sources = ', '.join(set([d['source'] for d in data]))
        
        return f"""Meta-Analyse der Recherche:
        
Quellen: {len(data)} Artikel
Medien: {sources}
Zeitraum: {datetime.now().strftime('%d.%m.%Y')}

Die Recherche basiert auf aktuellen Nachrichten-Artikeln von etablierten Medien.
Alle Daten wurden in Echtzeit gesammelt und analysiert."""


# ============================================================================
# HAUPT-WORKFLOW
# ============================================================================

async def three_layer_research(query: str) -> Dict:
    """
    Kompletter 3-Ebenen-Workflow
    """
    
    # EBENE 1: Sammle ECHTE Daten
    collector = RealTimeDataCollector()
    raw_data = collector.collect_data(query)
    
    if not raw_data:
        return {
            'error': 'Keine Daten gefunden',
            'query': query,
        }
    
    # EBENE 2: KI-Analyse
    analyzer = AIAnalysisLayer()
    analysis = analyzer.analyze_data(raw_data, query)
    
    # Kombiniere
    result = {
        'query': query,
        'timestamp': datetime.now().isoformat(),
        'raw_data': raw_data,  # EBENE 1
        'analysis': analysis,   # EBENE 2
        'status': 'completed',
    }
    
    return result


# ============================================================================
# TEST
# ============================================================================

if __name__ == '__main__':
    # Test
    result = asyncio.run(three_layer_research("Ukraine Krieg"))
    
    # Ausgabe
    print(f"\n{'='*60}")
    print(f"FINALE ERGEBNISSE")
    print(f"{'='*60}")
    print(f"Query: {result['query']}")
    print(f"Quellen: {len(result['raw_data'])}")
    print(f"Akteure: {len(result['analysis']['actors'])}")
    print(f"Status: {result['status']}")
    
    # Speichere als JSON
    with open('/tmp/research_result.json', 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Ergebnis gespeichert: /tmp/research_result.json")
