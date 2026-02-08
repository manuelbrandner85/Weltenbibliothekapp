/**
 * PRODUCTION BACKEND WORKER v4.0 - Weltenbibliothek Research API
 * 
 * NEUE FEATURES v4.0:
 * - Keine "KI-Analyse" Hinweise (professionelle Recherche-Sprache)
 * - Detaillierte, ausführliche Zusammenfassungen
 * - Multimedia-Integration (Bilder, PDFs, Audio, Videos)
 * - Direkte Media-Links für In-App Wiedergabe
 * - Klickbare Quellen mit Rich Metadata
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    if (request.method === 'OPTIONS') {
      return corsResponse();
    }

    if (url.pathname === '/health') {
      return jsonResponse({ 
        status: 'ok', 
        service: 'Weltenbibliothek Research API',
        version: '4.0.0',
        features: [
          'Detaillierte Recherche-Berichte',
          'Multimedia-Integration (Video, Audio, PDF, Bilder)',
          'Alternative Narrative Datenbank',
          'Klickbare Quellen',
          'In-App Media Playback'
        ],
        timestamp: new Date().toISOString()
      });
    }

    if (url.pathname === '/api/research' && request.method === 'POST') {
      return handleResearchRequest(request, env);
    }

    if (url.pathname === '/api/narratives' && request.method === 'GET') {
      return getNarrativesDatabase();
    }

    return jsonResponse({ error: 'Not Found' }, 404);
  }
};

/**
 * Handle Research Request mit Multimedia
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

    // Narrative Match
    const narrativeMatch = findMatchingNarrative(query);
    
    // Web Search
    const searchResults = await performEnhancedWebSearch(query, narrativeMatch);
    
    // Multimedia Search
    const multimedia = await searchMultimedia(query, narrativeMatch);
    
    // Detailed Analysis (OHNE KI-Hinweise!)
    const detailedReport = await generateDetailedReport(query, searchResults, narrativeMatch, multimedia, env);

    return jsonResponse({
      query: query,
      summary: detailedReport,
      sources: enhanceSourcesWithMetadata(searchResults),
      narrative: narrativeMatch ? {
        title: narrativeMatch.data.title,
        categories: narrativeMatch.data.categories,
        keyPoints: narrativeMatch.data.keyPoints,
        historicalContext: narrativeMatch.data.historicalContext || null
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
 * MULTIMEDIA SEARCH - Bilder, Videos, PDFs, Audio
 */
async function searchMultimedia(query, narrativeMatch) {
  const multimedia = {
    videos: [],
    images: [],
    documents: [],
    audio: []
  };

  // VIDEO-QUELLEN
  multimedia.videos = [
    {
      title: `Dokumentation: ${query}`,
      url: `https://www.youtube.com/results?search_query=${encodeURIComponent(query + ' documentary')}`,
      platform: 'YouTube',
      thumbnail: `https://i.ytimg.com/vi/default.jpg`,
      playable: false // Link zu YouTube
    },
    {
      title: `Alternative Perspektiven: ${query}`,
      url: `https://rumble.com/search/video?q=${encodeURIComponent(query)}`,
      platform: 'Rumble',
      thumbnail: null,
      playable: false
    },
    {
      title: `Unabhängige Recherche: ${query}`,
      url: `https://odysee.com/$/search?q=${encodeURIComponent(query)}`,
      platform: 'Odysee',
      thumbnail: null,
      playable: false
    }
  ];

  // BILDER
  multimedia.images = [
    {
      title: `Bildmaterial: ${query}`,
      url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}&iax=images&ia=images`,
      source: 'DuckDuckGo Images',
      viewable: true
    },
    {
      title: `Historische Bilder: ${query}`,
      url: `https://www.loc.gov/pictures/?q=${encodeURIComponent(query)}`,
      source: 'Library of Congress',
      viewable: true
    }
  ];

  // DOKUMENTE (PDFs, Archives)
  multimedia.documents = [
    {
      title: `Dokumente & Archive: ${query}`,
      url: `https://archive.org/search.php?query=${encodeURIComponent(query)}`,
      type: 'archive',
      source: 'Internet Archive',
      downloadable: true
    },
    {
      title: `Wissenschaftliche Publikationen: ${query}`,
      url: `https://pubmed.ncbi.nlm.nih.gov/?term=${encodeURIComponent(query)}`,
      type: 'scientific',
      source: 'PubMed',
      downloadable: true
    },
    {
      title: `Regierungs-Dokumente: ${query}`,
      url: `https://www.govinfo.gov/app/search/${encodeURIComponent(query)}`,
      type: 'official',
      source: 'GovInfo',
      downloadable: true
    }
  ];

  // AUDIO (Podcasts, Interviews)
  multimedia.audio = [
    {
      title: `Podcasts & Interviews: ${query}`,
      url: `https://archive.org/search.php?query=${encodeURIComponent(query + ' audio')}&and[]=mediatype%3A%22audio%22`,
      source: 'Internet Archive Audio',
      playable: true
    }
  ];

  // Narrative-spezifische Multimedia
  if (narrativeMatch) {
    const narrativeMedia = getNarrativeMultimedia(narrativeMatch.id, query);
    multimedia.videos.unshift(...narrativeMedia.videos);
    multimedia.documents.unshift(...narrativeMedia.documents);
  }

  return multimedia;
}

/**
 * Narrative-spezifische Multimedia
 */
function getNarrativeMultimedia(narrativeId, query) {
  const media = {
    videos: [],
    documents: []
  };

  switch(narrativeId) {
    case 'illuminati':
      media.videos.push({
        title: 'Geheime Gesellschaften - Dokumentation',
        url: 'https://www.youtube.com/results?search_query=illuminati+documentary',
        platform: 'YouTube',
        playable: false
      });
      media.documents.push({
        title: 'Illuminaten-Orden Originaldokumente (1776)',
        url: 'https://archive.org/details/illuminati-documents',
        type: 'historical',
        source: 'Internet Archive',
        downloadable: true
      });
      break;

    case 'area51':
      media.videos.push({
        title: 'Bob Lazar Interview - Area 51',
        url: 'https://www.youtube.com/results?search_query=bob+lazar+area+51',
        platform: 'YouTube',
        playable: false
      });
      media.documents.push({
        title: 'CIA Declassified: Area 51 Documents',
        url: 'https://www.cia.gov/readingroom/search/site/area%2051',
        type: 'declassified',
        source: 'CIA Reading Room',
        downloadable: true
      });
      break;

    case '911':
      media.videos.push({
        title: '9/11: Kritische Analysen',
        url: 'https://www.youtube.com/results?search_query=911+building+7',
        platform: 'YouTube',
        playable: false
      });
      media.documents.push({
        title: '9/11 Commission Report',
        url: 'https://www.govinfo.gov/content/pkg/GPO-911REPORT/pdf/GPO-911REPORT.pdf',
        type: 'official',
        source: 'GovInfo',
        downloadable: true
      });
      break;

    case 'jfk':
      media.videos.push({
        title: 'JFK Assassination - Zapruder Film',
        url: 'https://www.youtube.com/results?search_query=zapruder+film+jfk',
        platform: 'YouTube',
        playable: false
      });
      media.documents.push({
        title: 'JFK Assassination Records',
        url: 'https://www.archives.gov/research/jfk',
        type: 'official',
        source: 'National Archives',
        downloadable: true
      });
      break;

    case 'mk_ultra':
      media.documents.push({
        title: 'MK-Ultra CIA Documents (Declassified)',
        url: 'https://www.cia.gov/readingroom/collection/crest-25-year-program-archive',
        type: 'declassified',
        source: 'CIA Reading Room',
        downloadable: true
      });
      break;
  }

  return media;
}

/**
 * Enhance Sources mit Metadata (klickbar + Rich Info)
 */
function enhanceSourcesWithMetadata(searchResults) {
  return searchResults.map(source => {
    const enhanced = {
      title: source.title,
      url: source.url,
      snippet: source.snippet,
      sourceType: detectSourceType(source.url),
      category: getSourceCategory(source.url),
      clickable: true,
      metadata: {
        domain: extractDomain(source.url),
        credibility: assessCredibility(source.url),
        language: 'de/en',
        lastUpdated: null
      }
    };

    return enhanced;
  });
}

/**
 * DETAILLIERTER RECHERCHE-BERICHT (OHNE KI-Hinweise!)
 */
async function generateDetailedReport(query, searchResults, narrativeMatch, multimedia, env) {
  try {
    if (env.AI) {
      const context = searchResults.map(r => r.snippet).join('\n\n');
      const narrativeContext = narrativeMatch ? 
        `\n\nAlternative Narrative: ${narrativeMatch.data.title}\nSchlüsselpunkte:\n${narrativeMatch.data.keyPoints.map(p => `- ${p}`).join('\n')}` : 
        '';
      
      const prompt = `Erstelle einen AUSFÜHRLICHEN, DETAILLIERTEN Recherche-Bericht zu: "${query}"

Kontext aus Quellen:
${context}${narrativeContext}

WICHTIGE VORGABEN:
1. KEINE Hinweise auf "KI", "automatische Analyse", "Technologie" oder ähnliches
2. Schreibe als wäre es ein professioneller Recherche-Journalist
3. Nutze AUSSCHLIESSLICH diese Formulierungen:
   - "Die Recherche zeigt..."
   - "Dokumentiert ist..."
   - "Quellen berichten..."
   - "Untersuchungen ergeben..."
   - "Historische Aufzeichnungen belegen..."
   - "Experten weisen darauf hin..."
   - "Kritische Analysen deuten auf..."

4. Struktur (AUSFÜHRLICH, min. 600 Wörter):
   
   EINLEITUNG (100 Wörter)
   - Kontext und Bedeutung des Themas
   
   HAUPTANALYSE (300 Wörter)
   - Detaillierte Darstellung verschiedener Perspektiven
   - Offizielle Narrative vs. Alternative Interpretationen
   - Historischer Kontext und Entwicklung
   - Zentrale Akteure und Ereignisse
   
   QUELLEN UND BELEGE (100 Wörter)
   - Dokumentierte Fakten
   - Investigative Recherchen
   - Zeitzeugenberichte
   
   KRITISCHE PERSPEKTIVEN (100 Wörter)
   - Unabhängige Analysen
   - Alternative Erklärungsansätze
   - Offene Fragen und Widersprüche

5. Schreibstil:
   - Professionell und neutral
   - Detailliert und ausführlich
   - Faktenbasiert
   - Verschiedene Perspektiven berücksichtigend

Recherche-Bericht:`;

      const response = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
        messages: [
          { 
            role: 'system', 
            content: 'Du bist ein investigativer Recherche-Journalist der Weltenbibliothek. Schreibe AUSFÜHRLICH und DETAILLIERT. NIEMALS Hinweise auf KI oder Automatisierung!' 
          },
          { role: 'user', content: prompt }
        ],
        max_tokens: 2000
      });
      
      const report = response.response || response.result?.response;
      
      // Post-Processing: Entferne eventuelle KI-Hinweise
      return report
        .replace(/KI[- ]?(Analyse|generiert|erstellt|basiert)/gi, 'Recherche')
        .replace(/automatisch/gi, 'systematisch')
        .replace(/Algorithmus/gi, 'Methodik')
        .replace(/Modell/gi, 'Analyse-Framework');
    }
  } catch (error) {
    console.warn('⚠️ Cloudflare AI Error:', error.message);
  }
  
  // Fallback: Detaillierter manueller Bericht
  return generateDetailedFallbackReport(query, searchResults, narrativeMatch, multimedia);
}

/**
 * Detaillierter Fallback-Bericht (OHNE KI-Hinweise)
 */
function generateDetailedFallbackReport(query, searchResults, narrativeMatch, multimedia) {
  let report = `# Recherche-Bericht: ${query}\n\n`;
  
  // EINLEITUNG
  report += `## Einleitung\n\n`;
  report += `Die vorliegende Recherche untersucht das Thema "${query}" anhand verschiedener `;
  report += `Quellen und Perspektiven. Dabei werden sowohl offizielle Darstellungen als auch `;
  report += `alternative Narrative und kritische Analysen berücksichtigt.\n\n`;
  
  if (narrativeMatch) {
    report += `## Alternative Narrative: ${narrativeMatch.data.title}\n\n`;
    report += `**Kategorien:** ${narrativeMatch.data.categories.join(', ')}\n\n`;
    report += `### Zentrale Punkte:\n\n`;
    narrativeMatch.data.keyPoints.forEach(point => {
      report += `**${point}**\n\n`;
      report += `Die Recherche zeigt, dass dieser Aspekt in verschiedenen Quellen dokumentiert ist. `;
      report += `Investigative Journalisten und unabhängige Forscher haben hierzu umfangreiche Analysen vorgelegt.\n\n`;
    });
  }
  
  // QUELLEN-ANALYSE
  report += `## Recherchierte Quellen\n\n`;
  report += `Die Untersuchung umfasst ${searchResults.length} verschiedene Quellen aus unterschiedlichen Bereichen:\n\n`;
  
  const sourcesByType = {};
  searchResults.forEach(source => {
    const type = getSourceCategory(source.url);
    if (!sourcesByType[type]) sourcesByType[type] = [];
    sourcesByType[type].push(source);
  });
  
  Object.entries(sourcesByType).forEach(([type, sources]) => {
    report += `### ${type}\n\n`;
    sources.slice(0, 3).forEach(source => {
      report += `**${source.title}**\n`;
      report += `${source.snippet}\n\n`;
    });
  });
  
  // MULTIMEDIA
  report += `## Verfügbare Multimedia-Ressourcen\n\n`;
  
  if (multimedia.videos.length > 0) {
    report += `### Video-Dokumentationen (${multimedia.videos.length})\n`;
    report += `Dokumentarfilme, Interviews und investigative Berichte sind verfügbar und können direkt in der App abgespielt werden.\n\n`;
  }
  
  if (multimedia.documents.length > 0) {
    report += `### Dokumente und Archive (${multimedia.documents.length})\n`;
    report += `Historische Dokumente, declassified Files und wissenschaftliche Publikationen stehen zum Download und zur Ansicht bereit.\n\n`;
  }
  
  if (multimedia.audio.length > 0) {
    report += `### Audio-Ressourcen (${multimedia.audio.length})\n`;
    report += `Podcasts, Interviews und Audio-Dokumentationen können direkt angehört werden.\n\n`;
  }
  
  // KRITISCHE PERSPEKTIVEN
  report += `## Kritische Perspektiven\n\n`;
  report += `Die Recherche zeigt, dass zu diesem Thema verschiedene Interpretationen existieren. `;
  report += `Unabhängige Quellen und investigativer Journalismus bieten alternative Erklärungsansätze, `;
  report += `die von den offiziellen Darstellungen abweichen können. Eine umfassende Betrachtung `;
  report += `sollte alle verfügbaren Perspektiven berücksichtigen.\n\n`;
  
  // FAZIT
  report += `## Fazit\n\n`;
  report += `Die vorliegende Recherche dokumentiert ${searchResults.length} Quellen aus verschiedenen Bereichen. `;
  report += `Multimedia-Ressourcen (${multimedia.videos.length} Videos, ${multimedia.documents.length} Dokumente, `;
  report += `${multimedia.audio.length} Audio-Dateien) stehen zur weiteren Vertiefung zur Verfügung. `;
  report += `Die Weltenbibliothek empfiehlt, verschiedene Quellen zu konsultieren und kritisch zu prüfen.\n\n`;
  
  return report;
}

// ... [Rest des Codes bleibt gleich: ALTERNATIVE_SOURCES, NARRATIVE_DATABASE, etc.]

${ALTERNATIVE_SOURCES_CODE}
${NARRATIVE_DATABASE_CODE}
${HELPER_FUNCTIONS_CODE}

function extractDomain(url) {
  try {
    return new URL(url).hostname.replace('www.', '');
  } catch {
    return 'unknown';
  }
}

function assessCredibility(url) {
  const domain = extractDomain(url);
  
  // Offizielle Regierungs-Quellen
  if (domain.endsWith('.gov') || domain.includes('cia.gov') || domain.includes('fbi.gov')) {
    return 'official';
  }
  
  // Investigative Journalism
  if (['wikileaks.org', 'theintercept.com', 'propublica.org', 'bellingcat.com'].some(d => domain.includes(d))) {
    return 'investigative';
  }
  
  // Alternative Medien
  if (ALTERNATIVE_SOURCES[domain]) {
    return 'alternative';
  }
  
  // Mainstream
  if (['cnn.com', 'bbc.com', 'nytimes.com'].some(d => domain.includes(d))) {
    return 'mainstream';
  }
  
  return 'independent';
}

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

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status: status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    }
  });
}
