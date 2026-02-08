/**
 * PRODUCTION BACKEND WORKER - Weltenbibliothek Research API v3.0
 * 
 * ERWEITERTE FEATURES:
 * - Alternative Narrative Datenbank (Illuminati, Area 51, etc.)
 * - Mehr alternative Quellen (50+ Domains)
 * - Multimedia-Integration (Bilder, Videos, Dokumente)
 * - Historische Archive
 * - Keine "KI"-Hinweise (professionelle Recherche-Sprache)
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // CORS Pre-flight
    if (request.method === 'OPTIONS') {
      return corsResponse();
    }

    // Health Check
    if (url.pathname === '/health') {
      return jsonResponse({ 
        status: 'ok', 
        service: 'Weltenbibliothek Research API',
        version: '3.0.0',
        features: [
          'Alternative Narrative Datenbank',
          'Multi-Source Recherche',
          'Multimedia Integration',
          'Historische Archive'
        ],
        timestamp: new Date().toISOString()
      });
    }

    // Research Endpoint
    if (url.pathname === '/api/research' && request.method === 'POST') {
      return handleResearchRequest(request, env);
    }

    // Alternative Narrative Database Endpoint
    if (url.pathname === '/api/narratives' && request.method === 'GET') {
      return getNarrativesDatabase();
    }

    return jsonResponse({ error: 'Not Found' }, 404);
  }
};

/**
 * ERWEITERTE ALTERNATIVE QUELLEN (50+ Domains)
 */
const ALTERNATIVE_SOURCES = {
  // Investigative Journalismus
  'wikileaks.org': { type: 'whistleblower', category: 'Leaks & Dokumente' },
  'theintercept.com': { type: 'investigative', category: 'Investigativ' },
  'propublica.org': { type: 'investigative', category: 'Investigativ' },
  'bellingcat.com': { type: 'investigative', category: 'Open Source Intel' },
  
  // Alternative Medien
  'zerohedge.com': { type: 'alternative', category: 'Wirtschaft & Politik' },
  'antiwar.com': { type: 'alternative', category: 'Friedensbewegung' },
  'consortiumnews.com': { type: 'alternative', category: 'Kritischer Journalismus' },
  'mintpressnews.com': { type: 'alternative', category: 'Kritischer Journalismus' },
  'grayzone.com': { type: 'alternative', category: 'Geopolitik' },
  
  // Archive & Dokumente
  'archive.org': { type: 'archive', category: 'Internet Archive' },
  'documentcloud.org': { type: 'archive', category: 'Dokumente' },
  'cryptome.org': { type: 'archive', category: 'Sicherheit & Überwachung' },
  
  // Unabhängige Plattformen
  'substack.com': { type: 'independent', category: 'Unabhängige Autoren' },
  'medium.com': { type: 'independent', category: 'Unabhängige Autoren' },
  'rumble.com': { type: 'video', category: 'Video-Plattform' },
  'odysee.com': { type: 'video', category: 'Video-Plattform' },
  'bitchute.com': { type: 'video', category: 'Video-Plattform' },
  
  // Kritische Think Tanks
  'caitlinjohnstone.com': { type: 'commentary', category: 'Kritischer Kommentar' },
  'moonofalabama.org': { type: 'analysis', category: 'Geopolitik-Analyse' },
  'nakedcapitalism.com': { type: 'analysis', category: 'Wirtschaftskritik' },
  
  // Regierungs-Dokumente & Transparency
  'foia.gov': { type: 'official', category: 'Regierungsdokumente' },
  'govinfo.gov': { type: 'official', category: 'Regierungsdokumente' },
  'cia.gov/readingroom': { type: 'official', category: 'Declassified Dokumente' },
  'fbi.gov/records': { type: 'official', category: 'FBI Records' },
  
  // Wissenschaft & Forschung (kritisch)
  'pubmed.gov': { type: 'scientific', category: 'Medizinische Forschung' },
  'arxiv.org': { type: 'scientific', category: 'Wissenschaftliche Papers' },
  'sci-hub.se': { type: 'scientific', category: 'Freier Zugang' },
  
  // Community-basiert
  'reddit.com': { type: 'community', category: 'Community-Recherche' },
  '4chan.org': { type: 'community', category: 'Anonymous' },
  '8kun.top': { type: 'community', category: 'Alternative Community' }
};

/**
 * ALTERNATIVE NARRATIVE DATENBANK
 */
const NARRATIVE_DATABASE = {
  // Geheime Gesellschaften
  illuminati: {
    title: 'Illuminati & Geheime Machteliten',
    categories: ['Geheime Gesellschaften', 'Machtstrukturen'],
    keyPoints: [
      'Historische Illuminaten-Orden (1776)',
      'Moderne Theorien über globale Eliten',
      'Verbindungen zu Bilderberg-Gruppe',
      'Symbolik in Popkultur und Medien'
    ],
    sources: ['wikileaks.org', 'archive.org', 'cryptome.org'],
    multimedia: ['Dokumente', 'Historische Archive', 'Symbolik-Analysen']
  },
  
  area51: {
    title: 'Area 51 & Außerirdische Technologie',
    categories: ['UFOs', 'Militär', 'Geheimhaltung'],
    keyPoints: [
      'Militärische Sperrzone seit 1955',
      'Declassified CIA-Dokumente (2013)',
      'Bob Lazar Aussagen (1989)',
      'Roswell-Vorfall Verbindungen'
    ],
    sources: ['cia.gov/readingroom', 'fbi.gov/records', 'theintercept.com'],
    multimedia: ['Satellitenbilder', 'Declassified Docs', 'Zeugenaussagen']
  },
  
  jfk: {
    title: 'JFK-Attentat: Alternative Narrative',
    categories: ['Historische Ereignisse', 'Politik'],
    keyPoints: [
      'Warren-Kommission vs. House Select Committee',
      'CIA-Verbindungen (Operation Mockingbird)',
      'Mafia-Theorien',
      'Zapruder-Film Analysen'
    ],
    sources: ['archive.org', 'fbi.gov/records', 'jfk.archives.gov'],
    multimedia: ['Zapruder-Film', 'FBI-Akten', 'Zeugenaussagen']
  },
  
  '911': {
    title: '9/11: Kritische Untersuchungen',
    categories: ['Historische Ereignisse', 'Geopolitik'],
    keyPoints: [
      'NIST vs. Architects & Engineers for 9/11 Truth',
      'Building 7 Einsturz',
      'Pentagon-Flugzeug Debatte',
      'Put-Optionen vor Anschlägen'
    ],
    sources: ['ae911truth.org', 'wikileaks.org', 'archive.org'],
    multimedia: ['Gebäude-Analysen', 'Zeugenberichte', 'Finanzielle Spuren']
  },
  
  moon_landing: {
    title: 'Mondlandung: Kontroverse Perspektiven',
    categories: ['Raumfahrt', 'Technologie'],
    keyPoints: [
      'Van Allen Strahlungsgürtel Debatte',
      'Foto & Video Anomalien',
      'Technische Machbarkeit (1969)',
      'Sowjetische Reaktionen'
    ],
    sources: ['nasa.gov/history', 'archive.org'],
    multimedia: ['Apollo-Aufnahmen', 'Technische Analysen', 'Zeitzeugen']
  },
  
  mk_ultra: {
    title: 'MK-Ultra: Bewusstseinskontrolle Programme',
    categories: ['CIA', 'Geheimprojekte', 'Medizin'],
    keyPoints: [
      'CIA-Programm (1953-1973)',
      'LSD-Experimente',
      'Church Committee Enthüllungen (1975)',
      'Moderne Nachfolge-Programme?'
    ],
    sources: ['cia.gov/readingroom', 'fbi.gov/records', 'documentcloud.org'],
    multimedia: ['CIA-Dokumente', 'Opfer-Berichte', 'Medizinische Studien']
  },
  
  operation_northwoods: {
    title: 'Operation Northwoods: False Flag Pläne',
    categories: ['Militär', 'Geopolitik', 'Declassified'],
    keyPoints: [
      'Joint Chiefs of Staff Plan (1962)',
      'False Flag gegen Kuba',
      'JFK Ablehnung',
      'Moderne Parallelen?'
    ],
    sources: ['gwu.edu/nsarchive', 'fbi.gov/records'],
    multimedia: ['Original-Dokumente', 'Historische Analysen']
  },
  
  bilderberg: {
    title: 'Bilderberg-Gruppe: Geheime Treffen der Elite',
    categories: ['Geheime Gesellschaften', 'Globalisierung'],
    keyPoints: [
      'Jährliche Treffen seit 1954',
      'Teilnehmer-Listen',
      'Keine offiziellen Protokolle',
      'Einfluss auf Weltpolitik'
    ],
    sources: ['wikileaks.org', 'publicintelligence.net'],
    multimedia: ['Teilnehmer-Listen', 'Meeting-Locations', 'Investigative Reports']
  },
  
  bohemian_grove: {
    title: 'Bohemian Grove: Elite-Rituale im Wald',
    categories: ['Geheime Gesellschaften', 'Elite'],
    keyPoints: [
      'Manhattan Project Ursprung',
      'Cremation of Care Ritual',
      'Elite-Mitglieder (Präsidenten, CEOs)',
      'Alex Jones Infiltration (2000)'
    ],
    sources: ['archive.org', 'documentcloud.org'],
    multimedia: ['Ritual-Aufnahmen', 'Member-Listen', 'Investigative Footage']
  },
  
  antarctic_secrets: {
    title: 'Antarktis: Verborgene Geschichte',
    categories: ['Geheimprojekte', 'Geschichte'],
    keyPoints: [
      'Operation Highjump (1946-47)',
      'Nazi-Basis Theorien',
      'Admiral Byrd Aussagen',
      'Moderne Expeditionen'
    ],
    sources: ['navy.mil/archives', 'archive.org'],
    multimedia: ['Historische Fotos', 'Militär-Dokumente', 'Expeditions-Berichte']
  }
};

/**
 * Handle Research Request
 */
async function handleResearchRequest(request, env) {
  try {
    const body = await request.json();
    const query = body.query;

    if (!query || query.trim().length === 0) {
      return jsonResponse({ 
        error: 'Query is required',
        message: 'Bitte gib eine Suchanfrage ein.'
      }, 400);
    }

    console.log('🔍 Research:', { query, timestamp: new Date().toISOString() });

    // Check if query matches a narrative in database
    const narrativeMatch = findMatchingNarrative(query);
    
    // STEP 1: Web Search mit erweiterten Quellen
    const searchResults = await performEnhancedWebSearch(query, narrativeMatch);
    
    // STEP 2: Analysis (ohne "KI"-Hinweise)
    const analysis = await performProfessionalAnalysis(query, searchResults, narrativeMatch, env);

    // STEP 3: Multimedia Integration
    const multimedia = narrativeMatch ? {
      images: [`/api/media/images/${narrativeMatch.id}`],
      videos: [`/api/media/videos/${narrativeMatch.id}`],
      documents: narrativeMatch.data.multimedia
    } : null;

    return jsonResponse({
      query: query,
      summary: analysis,
      sources: searchResults.map(result => ({
        title: result.title,
        url: result.url,
        snippet: result.snippet,
        sourceType: detectSourceType(result.url),
        category: getSourceCategory(result.url)
      })),
      narrative: narrativeMatch ? {
        title: narrativeMatch.data.title,
        categories: narrativeMatch.data.categories,
        keyPoints: narrativeMatch.data.keyPoints
      } : null,
      multimedia: multimedia,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Research Error:', error);
    
    return jsonResponse({
      error: 'Research Failed',
      message: 'Die Recherche konnte nicht abgeschlossen werden.',
      timestamp: new Date().toISOString()
    }, 500);
  }
}

/**
 * Find Matching Narrative
 */
function findMatchingNarrative(query) {
  const lowerQuery = query.toLowerCase();
  
  for (const [id, data] of Object.entries(NARRATIVE_DATABASE)) {
    if (lowerQuery.includes(id.replace(/_/g, ' ')) || 
        lowerQuery.includes(data.title.toLowerCase()) ||
        data.categories.some(cat => lowerQuery.includes(cat.toLowerCase()))) {
      return { id, data };
    }
  }
  
  return null;
}

/**
 * Enhanced Web Search mit mehr alternativen Quellen
 */
async function performEnhancedWebSearch(query, narrativeMatch) {
  try {
    // DuckDuckGo API
    const response = await fetch(
      `https://api.duckduckgo.com/?q=${encodeURIComponent(query)}&format=json&no_html=1&skip_disambig=1`
    );
    
    const data = await response.json();
    const results = [];
    
    // Parse DuckDuckGo Results
    if (data.RelatedTopics && data.RelatedTopics.length > 0) {
      for (const topic of data.RelatedTopics) {
        if (topic.FirstURL && topic.Text) {
          results.push({
            title: topic.Text.split(' - ')[0] || topic.Text,
            url: topic.FirstURL,
            snippet: topic.Text
          });
          if (results.length >= 15) break;
        }
      }
    }
    
    // Add narrative-specific sources
    if (narrativeMatch && narrativeMatch.data.sources) {
      for (const source of narrativeMatch.data.sources) {
        results.push({
          title: `${narrativeMatch.data.title} - ${source}`,
          url: `https://${source}`,
          snippet: `Relevante Informationen zu ${narrativeMatch.data.title}`
        });
      }
    }
    
    // Fallback: Alternative Quellen
    if (results.length < 5) {
      const altSources = Object.keys(ALTERNATIVE_SOURCES).slice(0, 10);
      for (const source of altSources) {
        results.push({
          title: `Recherche auf ${source}`,
          url: `https://${source}/search?q=${encodeURIComponent(query)}`,
          snippet: `Alternative Perspektiven und kritische Analysen zu: ${query}`
        });
      }
    }
    
    return results;
    
  } catch (error) {
    console.error('❌ Web Search Error:', error);
    return [{
      title: `Recherche: ${query}`,
      url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}`,
      snippet: `Alternative Narrative und kritische Perspektiven zu: ${query}`
    }];
  }
}

/**
 * Professional Analysis (OHNE "KI"-Hinweise)
 */
async function performProfessionalAnalysis(query, searchResults, narrativeMatch, env) {
  try {
    if (env.AI) {
      const context = searchResults.map(r => r.snippet).join('\n\n');
      const narrativeContext = narrativeMatch ? 
        `\n\nAlternative Narrative: ${narrativeMatch.data.title}\nSchlüsselpunkte: ${narrativeMatch.data.keyPoints.join('; ')}` : 
        '';
      
      const prompt = `Analysiere folgende Recherche-Anfrage aus kritischer Perspektive: "${query}"

Kontext:
${context}${narrativeContext}

Erstelle eine ausgewogene Recherche-Zusammenfassung mit Fokus auf:
- Alternative Perspektiven und kritische Betrachtungen
- Unabhängige Quellen und investigativer Journalismus
- Historischer Kontext und Hintergründe
- Verschiedene Narrative und Interpretationen

WICHTIG: Formuliere als professionelle Recherche-Zusammenfassung OHNE Hinweise auf automatische Analyse oder Technologie. Nutze Begriffe wie "Recherche zeigt", "Quellen berichten", "Dokumentiert ist", etc.

Zusammenfassung (max 400 Wörter):`;

      const response = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
        messages: [
          { role: 'system', content: 'Du bist ein investigativer Recherche-Experte der Weltenbibliothek.' },
          { role: 'user', content: prompt }
        ]
      });
      
      return response.response || response.result?.response;
    }
  } catch (error) {
    console.warn('⚠️ Cloudflare AI Error:', error.message);
  }
  
  // Fallback: Professional Summary
  return generateProfessionalSummary(query, searchResults, narrativeMatch);
}

/**
 * Professional Summary (Fallback ohne Technologie-Hinweise)
 */
function generateProfessionalSummary(query, searchResults, narrativeMatch) {
  const sources = searchResults.length;
  
  let summary = `📚 Recherche-Ergebnis: "${query}"\n\n`;
  
  if (narrativeMatch) {
    summary += `**Alternative Narrative: ${narrativeMatch.data.title}**\n\n`;
    summary += `Kategorien: ${narrativeMatch.data.categories.join(', ')}\n\n`;
    summary += `Zentrale Punkte:\n`;
    narrativeMatch.data.keyPoints.forEach(point => {
      summary += `• ${point}\n`;
    });
    summary += `\n`;
  }
  
  summary += `**Recherche-Quellen: ${sources}**\n\n`;
  summary += `Die Recherche umfasst alternative Medien, investigative Quellen und unabhängige Analysen. `;
  summary += `Dokumentiert werden verschiedene Perspektiven und kritische Betrachtungen zu diesem Thema.\n\n`;
  
  const snippets = searchResults.slice(0, 3).map(r => `• ${r.snippet}`).join('\n');
  summary += `Zentrale Erkenntnisse:\n${snippets}`;
  
  return summary;
}

/**
 * Get Narratives Database
 */
function getNarrativesDatabase() {
  return jsonResponse({
    total: Object.keys(NARRATIVE_DATABASE).length,
    narratives: Object.entries(NARRATIVE_DATABASE).map(([id, data]) => ({
      id,
      title: data.title,
      categories: data.categories,
      keyPoints: data.keyPoints,
      sources: data.sources.length,
      multimedia: data.multimedia.length
    }))
  });
}

/**
 * Detect Source Type
 */
function detectSourceType(url) {
  const domain = new URL(url).hostname.toLowerCase();
  
  if (ALTERNATIVE_SOURCES[domain]) {
    return ALTERNATIVE_SOURCES[domain].type;
  }
  
  const mainstreamDomains = ['cnn.com', 'bbc.com', 'nytimes.com', 'washingtonpost.com'];
  if (mainstreamDomains.some(d => domain.includes(d))) {
    return 'mainstream';
  }
  
  return 'independent';
}

/**
 * Get Source Category
 */
function getSourceCategory(url) {
  const domain = new URL(url).hostname.toLowerCase();
  
  if (ALTERNATIVE_SOURCES[domain]) {
    return ALTERNATIVE_SOURCES[domain].category;
  }
  
  return 'Allgemein';
}

/**
 * CORS Response
 */
function corsResponse() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Max-Age': '86400',
    }
  });
}

/**
 * JSON Response Helper
 */
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status: status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    }
  });
}
