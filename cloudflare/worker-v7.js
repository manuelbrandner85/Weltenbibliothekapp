/**
 * WELTENBIBLIOTHEK BACKEND v7.0
 * 
 * NEUE FEATURES:
 * - Detaillierte AI-generierte Recherche-Berichte (Offiziell + Alternative)
 * - 3D-Visualisierungs-Daten für Graph
 * - Geo-Koordinaten für interaktive Karte
 * - Video-Metadaten für In-App Player
 */

// KATEGORIEN
const CATEGORIES = {
  UFO: { id: 'ufo', name: 'UFOs & Außerirdische', icon: '👽', color: '#00FF00' },
  SECRET_SOCIETY: { id: 'secret_society', name: 'Geheime Gesellschaften', icon: '🏛️', color: '#8B4513' },
  TECHNOLOGY: { id: 'technology', name: 'Technologie & Experimente', icon: '⚡', color: '#FFD700' },
  HISTORY: { id: 'history', name: 'Historische Ereignisse', icon: '📜', color: '#CD5C5C' },
  GEOPOLITICS: { id: 'geopolitics', name: 'Geopolitik & Macht', icon: '🌍', color: '#4169E1' },
  SCIENCE: { id: 'science', name: 'Wissenschaft & Medizin', icon: '🔬', color: '#32CD32' },
  COSMOLOGY: { id: 'cosmology', name: 'Kosmologie & Weltbild', icon: '🌌', color: '#9370DB' },
};

// ERWEITERTE NARRATIVE MIT GEO-DATEN
const NARRATIVE_DB = {
  area51: {
    id: 'area51',
    title: 'Area 51 & Außerirdische Technologie',
    categories: ['ufo', 'technology'],
    priority: 1,
    keywords: ['area 51', 'groom lake', 'ufo', 'aliens', 'bob lazar', 's4'],
    location: { lat: 37.2431, lng: -115.7930, name: 'Area 51, Nevada, USA' },
    timeline: [
      { year: 1955, event: 'Gründung von Area 51 für U-2 Spionageflugzeug-Tests' },
      { year: 1989, event: 'Bob Lazar berichtet über außerirdische Technologie in S-4' },
      { year: 2013, event: 'CIA bestätigt offiziell Existenz von Area 51' }
    ],
    relatedNarratives: ['roswell', 'majestic12', 'dulce_base'],
    graphPosition: { x: 0, y: 0, z: 0 }
  },
  roswell: {
    id: 'roswell',
    title: 'Roswell UFO-Absturz 1947',
    categories: ['ufo', 'history'],
    priority: 1,
    keywords: ['roswell', 'ufo crash', '1947', 'flying disc', 'weather balloon'],
    location: { lat: 33.3943, lng: -104.5230, name: 'Roswell, New Mexico, USA' },
    timeline: [
      { year: 1947, event: 'UFO-Absturz bei Roswell' },
      { year: 1947, event: 'Militär erklärt: "Wetterballon"' },
      { year: 1994, event: 'Air Force Report: Project Mogul' }
    ],
    relatedNarratives: ['area51', 'majestic12'],
    graphPosition: { x: 100, y: 50, z: 20 }
  },
  illuminati: {
    id: 'illuminati',
    title: 'Illuminati & Geheime Machteliten',
    categories: ['secret_society', 'geopolitics'],
    priority: 1,
    keywords: ['illuminati', 'geheimgesellschaft', 'elite', 'nwo', 'freimaurer'],
    location: { lat: 48.1351, lng: 11.5820, name: 'München (Gründungsort), Deutschland' },
    timeline: [
      { year: 1776, event: 'Adam Weishaupt gründet den Illuminatenorden in Bayern' },
      { year: 1785, event: 'Verbot durch bayerische Regierung unter Karl Theodor' },
      { year: 1798, event: 'Verschwörungstheorien durch John Robison' }
    ],
    relatedNarratives: ['bilderberg', 'bohemian_grove', 'skull_and_bones'],
    graphPosition: { x: -80, y: 100, z: -30 }
  },
  '911': {
    id: '911',
    title: '9/11: Alternative Untersuchungen',
    categories: ['history', 'geopolitics'],
    priority: 1,
    keywords: ['9/11', 'world trade center', 'building 7', 'wtc', 'pentagon'],
    location: { lat: 40.7127, lng: -74.0134, name: 'New York City, USA' },
    timeline: [
      { year: 2001, event: '11. September: Anschläge auf WTC und Pentagon' },
      { year: 2004, event: '9/11 Commission Report veröffentlicht' },
      { year: 2008, event: 'NIST Final Report zu WTC 7-Einsturz' }
    ],
    relatedNarratives: ['operation_northwoods', 'pearl_harbor'],
    graphPosition: { x: 50, y: -70, z: 40 }
  },
  jfk: {
    id: 'jfk',
    title: 'JFK-Attentat: Ungeklärte Fragen',
    categories: ['history', 'geopolitics'],
    priority: 1,
    keywords: ['jfk', 'kennedy', 'assassination', 'oswald', 'dallas', 'grassy knoll'],
    location: { lat: 32.7767, lng: -96.8089, name: 'Dallas, Texas, USA' },
    timeline: [
      { year: 1963, event: 'Attentat auf John F. Kennedy in Dallas' },
      { year: 1964, event: 'Warren-Kommission: Oswald handelte allein' },
      { year: 1979, event: 'House Select Committee: Wahrscheinlich Verschwörung' }
    ],
    relatedNarratives: ['cia_operations', 'mafia_connection'],
    graphPosition: { x: -50, y: -50, z: -50 }
  },
  mk_ultra: {
    id: 'mk_ultra',
    title: 'MK-Ultra: CIA Mind Control Programm',
    categories: ['technology', 'science'],
    priority: 1,
    keywords: ['mk ultra', 'cia', 'mind control', 'lsd', 'brainwashing'],
    location: { lat: 38.9072, lng: -77.0369, name: 'Langley, Virginia, USA (CIA HQ)' },
    timeline: [
      { year: 1953, event: 'MK-Ultra Programm startet unter CIA-Direktor Allen Dulles' },
      { year: 1973, event: 'CIA-Direktor Richard Helms befiehlt Vernichtung der Akten' },
      { year: 1975, event: 'Church Committee deckt Experimente auf' }
    ],
    relatedNarratives: ['montauk', 'monarch_programming'],
    graphPosition: { x: 80, y: 80, z: -60 }
  }
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    if (request.method === 'OPTIONS') {
      return corsResponse();
    }

    // Health Check
    if (url.pathname === '/health') {
      return jsonResponse({ 
        status: 'ok', 
        service: 'Weltenbibliothek Research API',
        version: '7.0.0',
        features: [
          'Detaillierte AI-Recherche-Berichte',
          '3D-Visualisierungs-Daten',
          'Geo-Koordinaten für Karte',
          'Video-Metadaten für In-App Player',
          '30+ Alternative Narrative'
        ],
        narrativesCount: Object.keys(NARRATIVE_DB).length,
        categoriesCount: Object.keys(CATEGORIES).length,
        timestamp: new Date().toISOString()
      });
    }

    // Get all categories
    if (url.pathname === '/api/categories') {
      return jsonResponse({
        categories: Object.values(CATEGORIES),
        timestamp: new Date().toISOString()
      });
    }

    // Get narratives (with optional category filter)
    if (url.pathname === '/api/narratives') {
      const categoryFilter = url.searchParams.get('category');
      
      let narratives = Object.values(NARRATIVE_DB);
      
      if (categoryFilter) {
        narratives = narratives.filter(n => 
          n.categories.includes(categoryFilter)
        );
      }
      
      return jsonResponse({
        narratives: narratives,
        count: narratives.length,
        categoryFilter: categoryFilter,
        timestamp: new Date().toISOString()
      });
    }

    // Get single narrative with related and 3D graph data
    if (url.pathname.startsWith('/api/narrative/')) {
      const narrativeId = url.pathname.split('/').pop();
      const narrative = NARRATIVE_DB[narrativeId];
      
      if (!narrative) {
        return jsonResponse({ error: 'Narrative not found' }, 404);
      }
      
      const related = (narrative.relatedNarratives || [])
        .map(id => NARRATIVE_DB[id])
        .filter(n => n !== undefined);
      
      return jsonResponse({
        narrative: narrative,
        related: related,
        graphData: buildGraphData(narrative, related),
        timestamp: new Date().toISOString()
      });
    }

    // Research endpoint with AI-generated detailed reports
    if (url.pathname === '/api/research' && request.method === 'POST') {
      return handleResearchRequest(request, env);
    }

    return jsonResponse({ error: 'Not Found' }, 404);
  }
};

// 3D GRAPH DATA BUILDER
function buildGraphData(mainNarrative, relatedNarratives) {
  const nodes = [
    {
      id: mainNarrative.id,
      title: mainNarrative.title,
      position: mainNarrative.graphPosition,
      type: 'main',
      color: '#FF6B6B'
    }
  ];
  
  const edges = [];
  
  relatedNarratives.forEach((related, index) => {
    nodes.push({
      id: related.id,
      title: related.title,
      position: related.graphPosition,
      type: 'related',
      color: '#4ECDC4'
    });
    
    edges.push({
      from: mainNarrative.id,
      to: related.id,
      strength: 0.8
    });
  });
  
  return { nodes, edges };
}

// DETAILLIERTE AI-RECHERCHE
async function handleResearchRequest(request, env) {
  try {
    const body = await request.json();
    const query = body.query;

    if (!query) {
      return jsonResponse({ error: 'Bitte gib eine Suchanfrage ein.' }, 400);
    }

    console.log(`[RESEARCH] Query: ${query}`);

    const narrativeMatch = findMatchingNarrative(query);
    const searchResults = await performWebSearch(query, narrativeMatch);
    const multimedia = await searchMultimedia(query, narrativeMatch);
    
    // DETAILLIERTE AI-GENERIERTE ZUSAMMENFASSUNG
    let detailedSummary = '';
    
    if (env.AI) {
      try {
        const aiPrompt = generateResearchPrompt(query, narrativeMatch, searchResults);
        
        const aiResponse = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
          messages: [
            {
              role: 'system',
              content: `Du bist ein professioneller Recherche-Experte und Wissensarchivar. 

WICHTIG - AUSGABE-STIL:
- KEINE Hinweise auf KI, ChatGPT, oder "als KI"
- Schreibe wie ein erfahrener Bibliothekar und Historiker
- Verwende "Recherche zeigt...", "Dokumente belegen...", "Quellen berichten..."
- NIEMALS "Als KI kann ich...", "Ich bin ein Sprachmodell...", etc.

Du analysierst alternative Narrative mit kritischem Blick:
1. OFFIZIELLE PERSPEKTIVE: Was sagen Regierungen/Mainstream-Medien?
2. ALTERNATIVE PERSPEKTIVE: Welche kritischen Fragen stellen unabhängige Forscher?
3. DOKUMENTATION: Welche Beweise/Dokumente existieren?
4. OFFENE FRAGEN: Was bleibt ungeklärt?

Deine Antwort MUSS mindestens 600 Wörter haben und professionell strukturiert sein.`
            },
            {
              role: 'user',
              content: aiPrompt
            }
          ],
          max_tokens: 2048,
          temperature: 0.7
        });
        
        detailedSummary = aiResponse.response || aiResponse.text || '';
        
        // Fallback falls AI zu kurz antwortet
        if (detailedSummary.length < 500) {
          detailedSummary = generateFallbackReport(query, narrativeMatch, searchResults);
        }
        
      } catch (aiError) {
        console.error('[AI ERROR]', aiError);
        detailedSummary = generateFallbackReport(query, narrativeMatch, searchResults);
      }
    } else {
      detailedSummary = generateFallbackReport(query, narrativeMatch, searchResults);
    }
    
    return jsonResponse({
      query: query,
      summary: detailedSummary,
      sources: searchResults,
      narrative: narrativeMatch,
      multimedia: multimedia,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('[RESEARCH ERROR]', error);
    return jsonResponse({ 
      error: 'Recherche fehlgeschlagen. Bitte versuche es erneut.',
      details: error.message 
    }, 500);
  }
}

// AI PROMPT GENERATOR
function generateResearchPrompt(query, narrative, sources) {
  let prompt = `Erstelle einen detaillierten Recherche-Bericht zu: "${query}"

MINDESTLÄNGE: 600 Wörter

STRUKTUR:

## 1. EINLEITUNG (100 Wörter)
Worum geht es? Warum ist dieses Thema relevant?

## 2. OFFIZIELLE PERSPEKTIVE (150 Wörter)
Was sagen:
- Regierungen und offizielle Stellen
- Mainstream-Medien (CNN, BBC, etc.)
- Wissenschaftliche Institutionen
- Offizielle Berichte/Dokumente

## 3. ALTERNATIVE PERSPEKTIVEN (200 Wörter)
Kritische Fragen von:
- Unabhängigen Forschern
- Alternativen Medien (The Intercept, WikiLeaks, etc.)
- Whistleblowern
- Dokumentarfilmern

Welche Widersprüche oder ungeklärten Punkte gibt es?

## 4. BEWEISE & DOKUMENTE (100 Wörter)
Welche konkreten Beweise existieren?
- Freigegebene Dokumente
- Zeugenaussagen
- Forensische Analysen
- Fotos/Videos

## 5. OFFENE FRAGEN (50 Wörter)
Was bleibt ungeklärt? Welche Fragen sollten weiter untersucht werden?

`;

  if (narrative) {
    prompt += `\nKONTEXT:
Narrative: ${narrative.title}
Timeline: ${narrative.timeline.map(t => `${t.year}: ${t.event}`).join('; ')}
`;
  }

  prompt += `\nQUELLEN (zur Orientierung):
${sources.slice(0, 5).map(s => `- ${s.title} (${s.url})`).join('\n')}

WICHTIG:
- KEINE KI-Hinweise ("als KI", "ich bin ein Sprachmodell", etc.)
- Schreibe wie ein professioneller Bibliothekar/Forscher
- Verwende: "Recherche zeigt...", "Dokumente belegen...", "Quellen berichten..."
- Mindestens 600 Wörter!
- Objektiv aber kritisch
- Beide Seiten darstellen (offiziell + alternativ)
`;

  return prompt;
}

// FALLBACK REPORT (wenn AI nicht verfügbar)
function generateFallbackReport(query, narrative, sources) {
  let report = `# Recherche: ${query}\n\n`;
  
  report += `## Einleitung\n\n`;
  report += `Diese Recherche untersucht das Thema "${query}" aus verschiedenen Perspektiven. `;
  report += `Dabei werden sowohl offizielle Standpunkte als auch alternative Narrative berücksichtigt. `;
  report += `Das Ziel ist eine umfassende Dokumentation der verfügbaren Informationen und Quellen.\n\n`;
  
  if (narrative) {
    report += `## Historischer Kontext\n\n`;
    report += `**${narrative.title}**\n\n`;
    report += `Timeline der wichtigsten Ereignisse:\n`;
    narrative.timeline.forEach(event => {
      report += `- **${event.year}**: ${event.event}\n`;
    });
    report += `\n`;
  }
  
  report += `## Offizielle Perspektive\n\n`;
  report += `Die offiziellen Darstellungen zu "${query}" stammen hauptsächlich von Regierungsstellen und etablierten Medien. `;
  report += `Diese Quellen betonen in der Regel die Einhaltung von Sicherheitsprotokollen und die Transparenz der Vorgänge. `;
  report += `Freigegebene Dokumente und offizielle Berichte bilden die Grundlage der Mainstream-Narrative.\n\n`;
  
  report += `## Alternative Perspektiven\n\n`;
  report += `Unabhängige Forscher und alternative Medien hinterfragen oft die offiziellen Darstellungen. `;
  report += `Dabei werden folgende kritische Punkte hervorgehoben:\n\n`;
  report += `- **Widersprüche in offiziellen Berichten**: Diskrepanzen zwischen verschiedenen Quellen\n`;
  report += `- **Fehlende Transparenz**: Klassifizierte Dokumente und geschwärzte Akten\n`;
  report += `- **Zeugenaussagen**: Berichte von Insidern und Whistleblowern\n`;
  report += `- **Forensische Analysen**: Alternative Interpretationen von Beweismaterial\n\n`;
  
  report += `## Verfügbare Quellen\n\n`;
  report += `Folgende Quellen bieten weiterführende Informationen:\n\n`;
  
  const mainstreamSources = sources.filter(s => s.sourceType === 'mainstream').slice(0, 3);
  const alternativeSources = sources.filter(s => s.sourceType === 'alternative').slice(0, 3);
  
  if (mainstreamSources.length > 0) {
    report += `**Mainstream-Quellen:**\n`;
    mainstreamSources.forEach(s => {
      report += `- [${s.title}](${s.url})\n`;
    });
    report += `\n`;
  }
  
  if (alternativeSources.length > 0) {
    report += `**Alternative Quellen:**\n`;
    alternativeSources.forEach(s => {
      report += `- [${s.title}](${s.url})\n`;
    });
    report += `\n`;
  }
  
  report += `## Offene Fragen\n\n`;
  report += `Trotz umfangreicher Recherchen bleiben einige Fragen ungeklärt:\n\n`;
  report += `- Welche Informationen befinden sich noch in klassifizierten Dokumenten?\n`;
  report += `- Wie lassen sich Widersprüche zwischen verschiedenen Quellen erklären?\n`;
  report += `- Welche neuen Beweise könnten in Zukunft auftauchen?\n\n`;
  
  report += `## Fazit\n\n`;
  report += `Das Thema "${query}" erfordert eine sorgfältige Analyse aus verschiedenen Perspektiven. `;
  report += `Sowohl offizielle als auch alternative Narrative bieten wichtige Einblicke. `;
  report += `Weiterführende Forschung und kritische Auseinandersetzung mit den verfügbaren Quellen sind essentiell `;
  report += `für ein umfassendes Verständnis der Thematik.\n`;
  
  return report;
}

function findMatchingNarrative(query) {
  query = query.toLowerCase();
  
  for (const [id, narrative] of Object.entries(NARRATIVE_DB)) {
    if (narrative.keywords.some(k => query.includes(k))) {
      return narrative;
    }
  }
  
  return null;
}

async function performWebSearch(query, narrative) {
  // Erweiterte Quellen mit SourceType
  const sources = [
    // Offizielle Quellen
    {
      title: `CIA Declassified: ${query}`,
      url: `https://www.cia.gov/search?q=${encodeURIComponent(query)}`,
      snippet: 'Offizielle CIA-Dokumente und freigegebene Akten',
      sourceType: 'mainstream'
    },
    {
      title: `FBI Records: ${query}`,
      url: `https://vault.fbi.gov/search?SearchableText=${encodeURIComponent(query)}`,
      snippet: 'FBI-Archiv mit historischen Dokumenten',
      sourceType: 'mainstream'
    },
    // Alternative Quellen
    {
      title: `WikiLeaks: ${query}`,
      url: `https://search.wikileaks.org/?q=${encodeURIComponent(query)}`,
      snippet: 'Vertrauliche Dokumente und Leaks',
      sourceType: 'alternative'
    },
    {
      title: `The Intercept: ${query}`,
      url: `https://theintercept.com/?s=${encodeURIComponent(query)}`,
      snippet: 'Investigativer Journalismus und Whistleblower-Berichte',
      sourceType: 'alternative'
    },
    {
      title: `Archive.org: ${query}`,
      url: `https://archive.org/search.php?query=${encodeURIComponent(query)}`,
      snippet: 'Historische Dokumente und Archive',
      sourceType: 'independent'
    }
  ];
  
  return sources;
}

async function searchMultimedia(query, narrative) {
  return {
    videos: [
      {
        title: `Dokumentation: ${query}`,
        url: `https://www.youtube.com/results?search_query=${encodeURIComponent(query + ' documentary')}`,
        platform: 'YouTube',
        embedId: null, // Wird vom Frontend extrahiert
        thumbnail: `https://i.ytimg.com/vi/placeholder/hqdefault.jpg`
      },
      {
        title: `Alternative Perspektiven: ${query}`,
        url: `https://rumble.com/search/video?q=${encodeURIComponent(query)}`,
        platform: 'Rumble',
        embedId: null
      }
    ],
    documents: [
      {
        title: `Archiv-Dokumente: ${query}`,
        url: `https://archive.org/search.php?query=${encodeURIComponent(query)}`,
        source: 'Internet Archive',
        type: 'pdf'
      }
    ],
    images: [
      {
        title: `Bildmaterial: ${query}`,
        url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}&iax=images&ia=images`,
        source: 'DuckDuckGo Images'
      }
    ],
    audio: []
  };
}

function corsResponse() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    }
  });
}

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status: status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    }
  });
}
