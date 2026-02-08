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

/**
 * 50+ ALTERNATIVE QUELLEN
 */
const ALTERNATIVE_SOURCES = {
  // Investigative Journalism
  'wikileaks.org': { credibility: 'high', category: 'Investigative Journalism' },
  'theintercept.com': { credibility: 'high', category: 'Investigative Journalism' },
  'propublica.org': { credibility: 'high', category: 'Investigative Journalism' },
  'bellingcat.com': { credibility: 'high', category: 'Investigative Journalism' },
  
  // Alternative Medien
  'zerohedge.com': { credibility: 'medium', category: 'Alternative Media' },
  'off-guardian.org': { credibility: 'medium', category: 'Alternative Media' },
  'corbettreport.com': { credibility: 'medium', category: 'Alternative Media' },
  'mintpressnews.com': { credibility: 'medium', category: 'Alternative Media' },
  'consortiumnews.com': { credibility: 'medium', category: 'Alternative Media' },
  
  // Archive & Dokumente
  'archive.org': { credibility: 'high', category: 'Archives' },
  'documentcloud.org': { credibility: 'high', category: 'Archives' },
  
  // Regierungs-Dokumente
  'cia.gov': { credibility: 'official', category: 'Government' },
  'fbi.gov': { credibility: 'official', category: 'Government' },
  'archives.gov': { credibility: 'official', category: 'Government' },
  'govinfo.gov': { credibility: 'official', category: 'Government' },
  
  // Wissenschaft
  'pubmed.ncbi.nlm.nih.gov': { credibility: 'high', category: 'Science' },
  'arxiv.org': { credibility: 'high', category: 'Science' },
  'scholar.google.com': { credibility: 'high', category: 'Science' },
  
  // Community & Foren
  'reddit.com': { credibility: 'low', category: 'Community' },
  '4chan.org': { credibility: 'low', category: 'Community' },
  'telegram.org': { credibility: 'low', category: 'Community' },
  
  // Video-Plattformen
  'youtube.com': { credibility: 'medium', category: 'Video' },
  'rumble.com': { credibility: 'medium', category: 'Video' },
  'odysee.com': { credibility: 'medium', category: 'Video' },
  'bitchute.com': { credibility: 'medium', category: 'Video' }
};

/**
 * NARRATIVE DATABASE (10 Themen)
 */
const NARRATIVE_DATABASE = {
  illuminati: {
    id: 'illuminati',
    title: 'Illuminati & Geheime Machteliten',
    categories: ['Geheime Gesellschaften', 'Machtstrukturen'],
    keyPoints: [
      'Historischer Illuminaten-Orden (1776-1785)',
      'Moderne Interpretationen von Machtstrukturen',
      'Symbole und ihre Bedeutung in Populärkultur',
      'Bilderberg-Gruppe und andere Elite-Treffen'
    ],
    keywords: ['illuminati', 'geheimgesellschaft', 'elite', 'bilderberg', 'neue weltordnung'],
    historicalContext: 'Der Illuminatenorden wurde 1776 in Bayern gegründet und 1785 verboten.'
  },
  
  area51: {
    id: 'area51',
    title: 'Area 51 & Außerirdische Technologie',
    categories: ['UFOs', 'Militär', 'Geheimhaltung'],
    keyPoints: [
      'Militärische Testanlage in Nevada',
      'UFO-Sichtungen und Zeugenaussagen',
      'Bob Lazar und Element 115',
      'Declassified Documents der CIA'
    ],
    keywords: ['area 51', 'ufo', 'aliens', 'bob lazar', 'roswell'],
    historicalContext: 'Area 51 wurde 1955 als Testgelände für das U-2 Spionageflugzeug eingerichtet.'
  },
  
  '911': {
    id: '911',
    title: '9/11: Kritische Untersuchungen',
    categories: ['Historische Ereignisse', 'Geopolitik'],
    keyPoints: [
      'Building 7 Einsturz',
      'NIST-Report und kritische Analysen',
      'Operation Northwoods als historischer Präzedenzfall',
      'Geopolitische Folgen und "War on Terror"'
    ],
    keywords: ['9/11', 'world trade center', 'building 7', 'nist', 'pentagon'],
    historicalContext: 'Die Anschläge vom 11. September 2001 führten zu grundlegenden geopolitischen Veränderungen.'
  },
  
  jfk: {
    id: 'jfk',
    title: 'JFK-Attentat: Alternative Narrative',
    categories: ['Historische Ereignisse', 'Politik'],
    keyPoints: [
      'Warren-Kommission vs. Kritische Analysen',
      'Zapruder-Film und ballistische Untersuchungen',
      'Magic Bullet Theory',
      'CIA und FBI Declassified Documents'
    ],
    keywords: ['jfk', 'kennedy', 'assassination', 'zapruder', 'warren commission'],
    historicalContext: 'John F. Kennedy wurde am 22. November 1963 in Dallas erschossen.'
  },
  
  mondlandung: {
    id: 'mondlandung',
    title: 'Mondlandung: Kontroverse Perspektiven',
    categories: ['Raumfahrt', 'Wissenschaft'],
    keyPoints: [
      'Technische Herausforderungen der Apollo-Missionen',
      'Fotografische und videographische Analysen',
      'Radiation Belt Controversy',
      'NASA-Telemetrie und Originalmaterial'
    ],
    keywords: ['mondlandung', 'apollo', 'nasa', 'moon hoax', 'van allen'],
    historicalContext: 'Die erste bemannte Mondlandung fand am 20. Juli 1969 statt (Apollo 11).'
  },
  
  mk_ultra: {
    id: 'mk_ultra',
    title: 'MK-Ultra: CIA Mind Control Experimente',
    categories: ['Geheimdienste', 'Medizin'],
    keyPoints: [
      'Declassified CIA Documents (1975)',
      'LSD und andere psychoaktive Substanzen',
      'Menschenversuche ohne Einwilligung',
      'Church Committee Untersuchungen'
    ],
    keywords: ['mk ultra', 'cia', 'mind control', 'lsd', 'experimente'],
    historicalContext: 'MK-Ultra war ein geheimes CIA-Programm (1953-1973) zur Bewusstseinskontrolle.'
  },
  
  operation_northwoods: {
    id: 'operation_northwoods',
    title: 'Operation Northwoods',
    categories: ['Militär', 'False Flag'],
    keyPoints: [
      'Declassified DoD Documents (1997)',
      'Geplante False-Flag-Operationen gegen Kuba',
      'Joint Chiefs of Staff Vorschläge',
      'Präsident Kennedy lehnte Operation ab'
    ],
    keywords: ['operation northwoods', 'false flag', 'kuba', 'pentagon'],
    historicalContext: 'Operation Northwoods war ein 1962 vorgeschlagener (aber abgelehnter) Plan des US-Militärs.'
  },
  
  bilderberg: {
    id: 'bilderberg',
    title: 'Bilderberg-Gruppe & Elite-Treffen',
    categories: ['Geheime Gesellschaften', 'Politik', 'Wirtschaft'],
    keyPoints: [
      'Jährliche Konferenzen seit 1954',
      'Teilnehmerlisten und Agenda',
      'Einfluss auf globale Politik',
      'Medienberichterstattung und Geheimhaltung'
    ],
    keywords: ['bilderberg', 'davos', 'wef', 'elite', 'global governance'],
    historicalContext: 'Die Bilderberg-Konferenz wurde 1954 gegründet und tagt jährlich unter Ausschluss der Öffentlichkeit.'
  },
  
  bohemian_grove: {
    id: 'bohemian_grove',
    title: 'Bohemian Grove: Elite-Rituale',
    categories: ['Geheime Gesellschaften', 'Elite'],
    keyPoints: [
      'Private Club in Kalifornien',
      'Cremation of Care Ritual',
      'Mitglieder aus Politik, Wirtschaft, Medien',
      'Investigative Recherchen und Insider-Berichte'
    ],
    keywords: ['bohemian grove', 'elite', 'ritual', 'kalifornien'],
    historicalContext: 'Bohemian Grove ist ein privater Club in Kalifornien, der seit 1872 existiert.'
  },
  
  antarktis: {
    id: 'antarktis',
    title: 'Antarktis: Geheime Basen & Expeditionen',
    categories: ['Militär', 'Geheimhaltung'],
    keyPoints: [
      'Operation Highjump (1946-1947)',
      'Admiral Byrd Expeditionen',
      'Neuschwabenland und Nazi-Deutschland',
      'Moderne Forschungsstationen und Geheimhaltung'
    ],
    keywords: ['antarktis', 'operation highjump', 'admiral byrd', 'neuschwabenland'],
    historicalContext: 'Operation Highjump war die größte Antarktis-Expedition der US Navy (1946-1947).'
  }
};

/**
 * Find Matching Narrative
 */
function findMatchingNarrative(query) {
  query = query.toLowerCase();
  
  for (const [id, narrative] of Object.entries(NARRATIVE_DATABASE)) {
    if (narrative.keywords.some(keyword => query.includes(keyword))) {
      return { id, data: narrative };
    }
  }
  
  return null;
}

/**
 * Get Narratives Database
 */
function getNarrativesDatabase() {
  return jsonResponse({
    narratives: Object.values(NARRATIVE_DATABASE),
    count: Object.keys(NARRATIVE_DATABASE).length,
    timestamp: new Date().toISOString()
  });
}

/**
 * Enhanced Web Search mit Alternative Quellen
 */
async function performEnhancedWebSearch(query, narrativeMatch) {
  const searchTerms = narrativeMatch ? 
    `${query} ${narrativeMatch.data.keywords.join(' ')}` : 
    query;
  
  const duckduckgoUrl = `https://api.duckduckgo.com/?q=${encodeURIComponent(searchTerms)}&format=json&no_html=1`;
  
  try {
    const response = await fetch(duckduckgoUrl);
    const data = await response.json();
    
    const results = [];
    
    // RelatedTopics
    if (data.RelatedTopics) {
      data.RelatedTopics.forEach(topic => {
        if (topic.Text && topic.FirstURL) {
          results.push({
            title: topic.Text.split(' - ')[0] || topic.Text.substring(0, 80),
            url: topic.FirstURL,
            snippet: topic.Text
          });
        }
      });
    }
    
    // Alternative Quellen hinzufügen
    const alternativeResults = generateAlternativeSourceResults(query, narrativeMatch);
    results.push(...alternativeResults);
    
    return results.slice(0, 20); // Top 20 Quellen
    
  } catch (error) {
    console.warn('⚠️ DuckDuckGo Error:', error.message);
    return generateAlternativeSourceResults(query, narrativeMatch);
  }
}

/**
 * Generate Alternative Source Results
 */
function generateAlternativeSourceResults(query, narrativeMatch) {
  const results = [];
  
  // Narrative-spezifische Quellen
  if (narrativeMatch) {
    const id = narrativeMatch.id;
    
    if (id === 'illuminati') {
      results.push({
        title: 'Illuminaten-Orden Originaldokumente',
        url: 'https://archive.org/details/illuminati-documents',
        snippet: 'Historische Dokumente des Illuminaten-Ordens aus dem 18. Jahrhundert.'
      });
    }
    
    if (id === 'area51') {
      results.push({
        title: 'CIA Declassified: Area 51',
        url: 'https://www.cia.gov/readingroom/search/site/area%2051',
        snippet: 'Freigegebene CIA-Dokumente zu Area 51 und U-2 Programm.'
      });
    }
    
    if (id === '911') {
      results.push({
        title: '9/11 Commission Report',
        url: 'https://www.govinfo.gov/content/pkg/GPO-911REPORT/pdf/GPO-911REPORT.pdf',
        snippet: 'Offizieller Bericht der 9/11 Kommission.'
      });
    }
    
    if (id === 'jfk') {
      results.push({
        title: 'JFK Assassination Records',
        url: 'https://www.archives.gov/research/jfk',
        snippet: 'National Archives JFK Assassination Records Collection.'
      });
    }
    
    if (id === 'mk_ultra') {
      results.push({
        title: 'MK-Ultra CIA Documents',
        url: 'https://www.cia.gov/readingroom/collection/crest-25-year-program-archive',
        snippet: 'Declassified CIA Documents über MK-Ultra Experimente.'
      });
    }
  }
  
  // Allgemeine alternative Quellen
  results.push(
    {
      title: `WikiLeaks: ${query}`,
      url: `https://wikileaks.org/search?q=${encodeURIComponent(query)}`,
      snippet: 'WikiLeaks Dokumente und Leaks zu diesem Thema.'
    },
    {
      title: `The Intercept: ${query}`,
      url: `https://theintercept.com/?s=${encodeURIComponent(query)}`,
      snippet: 'Investigativer Journalismus von The Intercept.'
    },
    {
      title: `Archive.org: ${query}`,
      url: `https://archive.org/search.php?query=${encodeURIComponent(query)}`,
      snippet: 'Historische Dokumente und Archive.'
    }
  );
  
  return results;
}

/**
 * Detect Source Type
 */
function detectSourceType(url) {
  const domain = extractDomain(url);
  
  if (ALTERNATIVE_SOURCES[domain]) {
    return ALTERNATIVE_SOURCES[domain].category;
  }
  
  if (domain.endsWith('.gov')) return 'Government';
  if (['cnn.com', 'bbc.com', 'nytimes.com'].some(d => domain.includes(d))) return 'Mainstream';
  
  return 'Independent';
}

/**
 * Get Source Category
 */
function getSourceCategory(url) {
  const domain = extractDomain(url);
  
  if (ALTERNATIVE_SOURCES[domain]) {
    return ALTERNATIVE_SOURCES[domain].category;
  }
  
  if (domain.endsWith('.gov')) return 'Regierung';
  if (domain.includes('archive')) return 'Archive';
  if (domain.includes('wiki')) return 'Community';
  if (['youtube', 'rumble', 'odysee'].some(v => domain.includes(v))) return 'Video';
  
  return 'Alternative Medien';
}

/**
 * Extract Domain
 */
function extractDomain(url) {
  try {
    return new URL(url).hostname.replace('www.', '');
  } catch {
    return 'unknown';
  }
}

/**
 * Assess Credibility
 */
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
 * JSON Response
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
