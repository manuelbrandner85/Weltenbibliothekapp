/**
 * WELTENBIBLIOTHEK BACKEND v7.2
 * 
 * NEU:
 * - Themen-spezifische PDFs (echte Dokumente)
 * - Themen-spezifische Bilder (relevante Fotos)
 * - In-App Viewer Support
 * - Verbesserte Multimedia-Integration
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

// NARRATIVE DATABASE
const NARRATIVE_DB = {
  area51: {
    id: 'area51',
    title: 'Area 51 & Außerirdische Technologie',
    categories: ['ufo', 'technology'],
    priority: 1,
    keywords: ['area 51', 'groom lake', 'ufo', 'aliens', 'bob lazar', 's4', 's-4'],
    location: { lat: 37.2431, lng: -115.7930, name: 'Area 51, Nevada, USA' },
    timeline: [
      { year: 1955, event: 'Gründung von Area 51 für U-2 Spionageflugzeug-Tests' },
      { year: 1989, event: 'Bob Lazar berichtet über außerirdische Technologie in S-4' },
      { year: 2013, event: 'CIA bestätigt offiziell Existenz von Area 51' }
    ],
    relatedNarratives: ['roswell', 'majestic12'],
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
    relatedNarratives: ['area51'],
    graphPosition: { x: 100, y: 50, z: 20 }
  },
  majestic12: {
    id: 'majestic12',
    title: 'Majestic 12: Geheime UFO-Gruppe',
    categories: ['ufo', 'secret_society'],
    priority: 1,
    keywords: ['majestic 12', 'mj-12', 'majestic twelve', 'ufo cover up'],
    location: { lat: 38.8977, lng: -77.0365, name: 'Washington D.C., USA' },
    timeline: [
      { year: 1947, event: 'Angebliche Gründung von Majestic 12 durch Truman' },
      { year: 1984, event: 'MJ-12 Dokumente auftauchen' }
    ],
    relatedNarratives: ['area51', 'roswell'],
    graphPosition: { x: 50, y: 100, z: -30 }
  },
  mk_ultra: {
    id: 'mk_ultra',
    title: 'MK-Ultra: CIA Mind Control',
    categories: ['technology', 'science'],
    priority: 1,
    keywords: ['mk ultra', 'mk-ultra', 'mkultra', 'cia', 'mind control', 'lsd', 'brainwashing'],
    location: { lat: 38.9072, lng: -77.0369, name: 'Langley, Virginia, USA (CIA HQ)' },
    timeline: [
      { year: 1953, event: 'MK-Ultra Programm startet unter CIA-Direktor Allen Dulles' },
      { year: 1973, event: 'CIA-Direktor Richard Helms befiehlt Vernichtung der Akten' },
      { year: 1975, event: 'Church Committee deckt Experimente auf' }
    ],
    relatedNarratives: [],
    graphPosition: { x: 80, y: 80, z: -60 }
  },
  illuminati: {
    id: 'illuminati',
    title: 'Illuminati & Geheime Machteliten',
    categories: ['secret_society', 'geopolitics'],
    priority: 1,
    keywords: ['illuminati', 'geheimgesellschaft', 'elite', 'nwo', 'freimaurer', 'new world order'],
    location: { lat: 48.1351, lng: 11.5820, name: 'München (Gründungsort), Deutschland' },
    timeline: [
      { year: 1776, event: 'Adam Weishaupt gründet den Illuminatenorden in Bayern' },
      { year: 1785, event: 'Verbot durch bayerische Regierung unter Karl Theodor' }
    ],
    relatedNarratives: [],
    graphPosition: { x: -80, y: 100, z: -30 }
  },
  '911': {
    id: '911',
    title: '9/11: Alternative Untersuchungen',
    categories: ['history', 'geopolitics'],
    priority: 1,
    keywords: ['9/11', '911', 'nine eleven', 'world trade center', 'building 7', 'wtc', 'pentagon'],
    location: { lat: 40.7127, lng: -74.0134, name: 'New York City, USA' },
    timeline: [
      { year: 2001, event: '11. September: Anschläge auf WTC und Pentagon' },
      { year: 2008, event: 'NIST Final Report zu WTC 7-Einsturz' }
    ],
    relatedNarratives: [],
    graphPosition: { x: 50, y: -70, z: 40 }
  }
};

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
        version: '7.1.0',
        features: [
          'Detaillierte AI-Recherche (800+ Wörter)',
          '10+ Quellen pro Recherche',
          'Multimedia-Integration',
          '3D-Graph-Daten',
          'Geo-Koordinaten'
        ],
        narrativesCount: Object.keys(NARRATIVE_DB).length,
        timestamp: new Date().toISOString()
      });
    }

    if (url.pathname === '/api/categories') {
      return jsonResponse({
        categories: Object.values(CATEGORIES),
        timestamp: new Date().toISOString()
      });
    }

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
        timestamp: new Date().toISOString()
      });
    }

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

    if (url.pathname === '/api/research' && request.method === 'POST') {
      return handleResearchRequest(request, env);
    }

    return jsonResponse({ error: 'Not Found' }, 404);
  }
};

function buildGraphData(mainNarrative, relatedNarratives) {
  const nodes = [{
    id: mainNarrative.id,
    title: mainNarrative.title,
    position: mainNarrative.graphPosition,
    type: 'main',
    color: '#FF6B6B'
  }];
  
  const edges = [];
  
  relatedNarratives.forEach((related) => {
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

// HAUPTFUNKTION: RECHERCHE
async function handleResearchRequest(request, env) {
  try {
    const body = await request.json();
    const query = body.query;

    if (!query) {
      return jsonResponse({ error: 'Bitte gib eine Suchanfrage ein.' }, 400);
    }

    const narrativeMatch = findMatchingNarrative(query);
    const sources = generateComprehensiveSources(query);
    const multimedia = generateMultimedia(query, narrativeMatch);
    
    // DETAILLIERTE AI-ZUSAMMENFASSUNG
    let detailedSummary = '';
    
    if (env.AI) {
      try {
        const aiPrompt = `Erstelle einen SEHR DETAILLIERTEN Recherche-Bericht zu: "${query}"

KRITISCHE ANFORDERUNG: Der Bericht MUSS mindestens 800 Wörter haben!

PFLICHT-STRUKTUR:

## Einleitung (150 Wörter)
Was ist "${query}"? Warum ist dieses Thema wichtig? Welche Kontroversen gibt es?

## Historischer Kontext (200 Wörter)
Wann begann das Thema? Welche Schlüsselereignisse gab es? Zeitstrahl mit Jahreszahlen.

## Offizielle Darstellung (200 Wörter)
Was sagen:
- Regierungen und Behörden
- Mainstream-Medien (CNN, BBC, New York Times)
- Offizielle wissenschaftliche Institute
- Etablierte Experten

Welche offiziellen Dokumente existieren? Welche Erklärungen werden gegeben?

## Alternative Perspektiven (200 Wörter)
Was sagen:
- Unabhängige Forscher und Journalisten
- Alternative Medien (The Intercept, WikiLeaks)
- Whistleblower und Insider
- Kritische Wissenschaftler

Welche Widersprüche in offiziellen Darstellungen werden genannt?
Welche alternativen Theorien existieren?

## Dokumentation & Beweise (100 Wörter)
Welche konkreten Beweise gibt es?
- Freigegebene Regierungsdokumente
- Zeugenaussagen
- Wissenschaftliche Analysen
- Foto/Video-Material

## Schlussfolgerung (50 Wörter)
Welche Fragen bleiben offen? Was sollte weiter untersucht werden?

WICHTIGE REGELN:
1. MINDESTENS 800 WÖRTER - sonst ungültig!
2. KEINE KI-Hinweise ("als KI", "ich bin ein Sprachmodell")
3. Schreibe wie ein Bibliothekar/Historiker
4. Verwende "Recherche zeigt...", "Dokumente belegen..."
5. Beide Seiten fair darstellen (offiziell + alternativ)
6. Konkrete Jahreszahlen und Namen nennen
7. Professioneller, sachlicher Ton

Beginne jetzt mit dem Bericht:`;

        const aiResponse = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
          messages: [
            {
              role: 'system',
              content: 'Du bist ein professioneller Recherche-Experte und Wissensarchivar. Du schreibst LANGE, detaillierte Berichte (mindestens 800 Wörter). KEINE KI-Hinweise!'
            },
            {
              role: 'user',
              content: aiPrompt
            }
          ],
          max_tokens: 3000,
          temperature: 0.7
        });
        
        detailedSummary = aiResponse.response || aiResponse.text || '';
        
        // Fallback wenn AI zu kurz
        if (detailedSummary.split(' ').length < 400) {
          detailedSummary = generateLongFallbackReport(query, narrativeMatch, sources);
        }
        
      } catch (aiError) {
        console.error('[AI ERROR]', aiError);
        detailedSummary = generateLongFallbackReport(query, narrativeMatch, sources);
      }
    } else {
      detailedSummary = generateLongFallbackReport(query, narrativeMatch, sources);
    }
    
    return jsonResponse({
      query: query,
      summary: detailedSummary,
      sources: sources,
      narrative: narrativeMatch,
      multimedia: multimedia,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('[RESEARCH ERROR]', error);
    return jsonResponse({ 
      error: 'Recherche fehlgeschlagen.',
      details: error.message 
    }, 500);
  }
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

function generateComprehensiveSources(query) {
  return [
    {
      title: `CIA Archiv: ${query}`,
      url: `https://www.cia.gov/search?q=${encodeURIComponent(query)}`,
      snippet: 'Freigegebene CIA-Dokumente und offizielle Berichte zur Thematik',
      sourceType: 'mainstream',
      timestamp: new Date().toISOString()
    },
    {
      title: `FBI Records Vault: ${query}`,
      url: `https://vault.fbi.gov/search?SearchableText=${encodeURIComponent(query)}`,
      snippet: 'FBI-Archiv mit historischen Ermittlungsakten und Dokumenten',
      sourceType: 'mainstream',
      timestamp: new Date().toISOString()
    },
    {
      title: `National Security Archive: ${query}`,
      url: `https://nsarchive.gwu.edu/?s=${encodeURIComponent(query)}`,
      snippet: 'Declassified Dokumente von US-Regierungsbehörden',
      sourceType: 'mainstream',
      timestamp: new Date().toISOString()
    },
    {
      title: `WikiLeaks: ${query}`,
      url: `https://search.wikileaks.org/?q=${encodeURIComponent(query)}`,
      snippet: 'Vertrauliche Dokumente und Whistleblower-Leaks',
      sourceType: 'alternative',
      timestamp: new Date().toISOString()
    },
    {
      title: `The Intercept: ${query}`,
      url: `https://theintercept.com/?s=${encodeURIComponent(query)}`,
      snippet: 'Investigativer Journalismus und kritische Berichterstattung',
      sourceType: 'alternative',
      timestamp: new Date().toISOString()
    },
    {
      title: `ProPublica: ${query}`,
      url: `https://www.propublica.org/search?q=${encodeURIComponent(query)}`,
      snippet: 'Gemeinnütziger investigativer Journalismus',
      sourceType: 'alternative',
      timestamp: new Date().toISOString()
    },
    {
      title: `Bellingcat: ${query}`,
      url: `https://www.bellingcat.com/?s=${encodeURIComponent(query)}`,
      snippet: 'Open-Source Investigationen und Recherchen',
      sourceType: 'alternative',
      timestamp: new Date().toISOString()
    },
    {
      title: `Internet Archive: ${query}`,
      url: `https://archive.org/search.php?query=${encodeURIComponent(query)}`,
      snippet: 'Historische Dokumente, Bücher und Archive',
      sourceType: 'independent',
      timestamp: new Date().toISOString()
    },
    {
      title: `DuckDuckGo Web Search: ${query}`,
      url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}`,
      snippet: 'Umfassende Web-Recherche ohne Tracking',
      sourceType: 'independent',
      timestamp: new Date().toISOString()
    },
    {
      title: `Google Scholar: ${query}`,
      url: `https://scholar.google.com/scholar?q=${encodeURIComponent(query)}`,
      snippet: 'Wissenschaftliche Publikationen und akademische Quellen',
      sourceType: 'mainstream',
      timestamp: new Date().toISOString()
    }
  ];
}

function generateMultimedia(query, narrative) {
  // Themen-spezifische Dokumente & Bilder
  const themeSpecificContent = getThemeSpecificContent(query, narrative);
  
  return {
    videos: [
      {
        title: `Dokumentation: ${query}`,
        url: `https://www.youtube.com/results?search_query=${encodeURIComponent(query + ' documentary')}`,
        platform: 'YouTube',
        thumbnail: `https://i.ytimg.com/vi/placeholder/hqdefault.jpg`
      },
      {
        title: `Alternative Berichterstattung: ${query}`,
        url: `https://rumble.com/search/video?q=${encodeURIComponent(query)}`,
        platform: 'Rumble'
      },
      {
        title: `Unabhängige Recherche: ${query}`,
        url: `https://odysee.com/$/search?q=${encodeURIComponent(query)}`,
        platform: 'Odysee'
      }
    ],
    documents: themeSpecificContent.documents,
    images: themeSpecificContent.images,
    audio: []
  };
}

// THEMEN-SPEZIFISCHE INHALTE
function getThemeSpecificContent(query, narrative) {
  const queryLower = query.toLowerCase();
  
  // MK-ULTRA spezifisch
  if (queryLower.includes('mk ultra') || queryLower.includes('mkultra')) {
    return {
      documents: [
        {
          title: 'CIA MK-ULTRA Documents (1977 Senate Hearing)',
          url: 'https://www.intelligence.senate.gov/sites/default/files/hearings/95mkultra.pdf',
          source: 'U.S. Senate Intelligence Committee',
          description: 'Offizielle Anhörung zum MK-ULTRA Programm',
          type: 'pdf',
          year: 1977
        },
        {
          title: 'Project MK-ULTRA: The CIA\'s Program of Research',
          url: 'https://www.cia.gov/readingroom/docs/CIA-RDP87B00858R000500810003-5.pdf',
          source: 'CIA Freedom of Information Act',
          description: 'Freigegebene CIA-Dokumente über Mind Control',
          type: 'pdf',
          year: 1953
        },
        {
          title: 'Church Committee Report on MK-ULTRA',
          url: 'https://www.intelligence.senate.gov/sites/default/files/94intelligent_activities_II.pdf',
          source: 'Senate Select Committee',
          description: 'Untersuchungsbericht zu illegalen CIA-Aktivitäten',
          type: 'pdf',
          year: 1975
        }
      ],
      images: [
        {
          title: 'MK-ULTRA Dokument-Sammlung',
          url: 'https://commons.wikimedia.org/wiki/File:Declassified_MK_Ultra_document_1.jpg',
          source: 'Wikimedia Commons',
          description: 'Freigegebene Original-Dokumente'
        },
        {
          title: 'CIA Mind Control Experiments',
          url: 'https://www.cia.gov/readingroom/collection/mind-control-collection',
          source: 'CIA Reading Room',
          description: 'Historische Fotos und Dokumente'
        }
      ]
    };
  }
  
  // AREA 51 spezifisch
  if (queryLower.includes('area 51') || queryLower.includes('groom lake')) {
    return {
      documents: [
        {
          title: 'CIA Declassified: Area 51 History',
          url: 'https://www.cia.gov/readingroom/docs/DOC_0000190094.pdf',
          source: 'CIA FOIA',
          description: 'Offizielle Geschichte von Area 51',
          type: 'pdf',
          year: 2013
        },
        {
          title: 'U-2 Spy Plane Program Documents',
          url: 'https://www.cia.gov/readingroom/collection/u-2-spy-plane-aircraft',
          source: 'CIA Historical Collection',
          description: 'Freigegebene U-2 Programm-Dokumente',
          type: 'pdf',
          year: 1955
        }
      ],
      images: [
        {
          title: 'Area 51 Luftaufnahmen',
          url: 'https://commons.wikimedia.org/wiki/Category:Area_51',
          source: 'Wikimedia Commons',
          description: 'Satellitenbilder und historische Fotos'
        },
        {
          title: 'Groom Lake Facility',
          url: 'https://www.cia.gov/readingroom/document/cia-rdp90b01390r000300120001-3',
          source: 'CIA Reading Room',
          description: 'Declassified Facility Photos'
        }
      ]
    };
  }
  
  // ROSWELL spezifisch
  if (queryLower.includes('roswell')) {
    return {
      documents: [
        {
          title: 'The Roswell Report: Case Closed (1997)',
          url: 'https://www.dod.mil/pubs/foi/Reading_Room/UFOsandUAPs/825.pdf',
          source: 'U.S. Air Force',
          description: 'Offizieller Air Force Report zu Roswell',
          type: 'pdf',
          year: 1997
        },
        {
          title: 'FBI Roswell Investigation Files',
          url: 'https://vault.fbi.gov/Roswell%20UFO',
          source: 'FBI Records Vault',
          description: 'FBI-Untersuchungsakten zum Roswell-Vorfall',
          type: 'pdf',
          year: 1947
        }
      ],
      images: [
        {
          title: 'Roswell Daily Record (1947)',
          url: 'https://commons.wikimedia.org/wiki/File:RoswellDailyRecordJuly8,1947.jpg',
          source: 'Wikimedia Commons',
          description: 'Original-Zeitungstitelseite'
        },
        {
          title: 'Roswell Debris Photos',
          url: 'https://www.nsa.gov/portals/75/images/news-features/declassified-documents/cryptologs/roswell.png',
          source: 'NSA Archives',
          description: 'Historische Trümmerfotos'
        }
      ]
    };
  }
  
  // 9/11 spezifisch
  if (queryLower.includes('9/11') || queryLower.includes('911') || queryLower.includes('wtc')) {
    return {
      documents: [
        {
          title: '9/11 Commission Report (Complete)',
          url: 'https://www.9-11commission.gov/report/911Report.pdf',
          source: '9/11 Commission',
          description: 'Offizieller Untersuchungsbericht',
          type: 'pdf',
          year: 2004
        },
        {
          title: 'NIST WTC 7 Investigation Report',
          url: 'https://www.nist.gov/publications/final-report-collapse-world-trade-center-building-7',
          source: 'National Institute of Standards',
          description: 'Technischer Bericht zum WTC 7-Einsturz',
          type: 'pdf',
          year: 2008
        }
      ],
      images: [
        {
          title: '9/11 Documentary Photos',
          url: 'https://commons.wikimedia.org/wiki/Category:September_11_attacks',
          source: 'Wikimedia Commons',
          description: 'Dokumentarfotos vom 11. September'
        },
        {
          title: 'WTC 7 Collapse Sequence',
          url: 'https://www.nist.gov/image/wtc7collapsejpg',
          source: 'NIST Archive',
          description: 'Einsturz-Sequenz Fotos'
        }
      ]
    };
  }
  
  // ILLUMINATI spezifisch
  if (queryLower.includes('illuminati') || queryLower.includes('illuminaten')) {
    return {
      documents: [
        {
          title: 'Illuminaten-Orden Originalschriften (1776)',
          url: 'https://archive.org/details/illuminati-documents',
          source: 'Internet Archive',
          description: 'Historische Originaldokumente',
          type: 'pdf',
          year: 1776
        },
        {
          title: 'Adam Weishaupt: Illuminatenorden',
          url: 'https://www.gutenberg.org/ebooks/author/42738',
          source: 'Project Gutenberg',
          description: 'Schriften des Gründers',
          type: 'pdf',
          year: 1785
        }
      ],
      images: [
        {
          title: 'Illuminati Symbole & Siegel',
          url: 'https://commons.wikimedia.org/wiki/Category:Illuminati',
          source: 'Wikimedia Commons',
          description: 'Historische Symbole und Dokumente'
        },
        {
          title: 'Bayerische Illuminaten',
          url: 'https://www.loc.gov/pictures/?q=illuminati',
          source: 'Library of Congress',
          description: 'Historische Abbildungen'
        }
      ]
    };
  }
  
  // FALLBACK: Allgemeine Ressourcen
  return {
    documents: [
      {
        title: `Archiv-Dokumente: ${query}`,
        url: `https://archive.org/search.php?query=${encodeURIComponent(query)}&mediatype=texts`,
        source: 'Internet Archive',
        description: 'Historische Dokumente und Texte',
        type: 'collection'
      },
      {
        title: `Declassified Files: ${query}`,
        url: `https://www.cia.gov/search?q=${encodeURIComponent(query)}`,
        source: 'CIA FOIA',
        description: 'Freigegebene Regierungsdokumente',
        type: 'collection'
      },
      {
        title: `FBI Records: ${query}`,
        url: `https://vault.fbi.gov/search?SearchableText=${encodeURIComponent(query)}`,
        source: 'FBI Records Vault',
        description: 'FBI-Archiv Dokumente',
        type: 'collection'
      }
    ],
    images: [
      {
        title: `Bildmaterial: ${query}`,
        url: `https://commons.wikimedia.org/w/index.php?search=${encodeURIComponent(query)}&title=Special:MediaSearch&type=image`,
        source: 'Wikimedia Commons',
        description: 'Freie Bilder und historische Fotos'
      },
      {
        title: `Historische Fotos: ${query}`,
        url: `https://www.loc.gov/pictures/?q=${encodeURIComponent(query)}`,
        source: 'Library of Congress',
        description: 'US Library of Congress Fotoarchiv'
      },
      {
        title: `NASA Images: ${query}`,
        url: `https://images.nasa.gov/search-results?q=${encodeURIComponent(query)}`,
        source: 'NASA Image Library',
        description: 'NASA Bildarchiv'
      }
    ]
  };
}

function generateLongFallbackReport(query, narrative, sources) {
  let report = `# Umfassende Recherche: ${query}\n\n`;
  
  report += `## Einleitung\n\n`;
  report += `Diese detaillierte Recherche untersucht das komplexe Thema "${query}" aus verschiedenen Perspektiven. `;
  report += `Dabei werden sowohl offizielle Darstellungen als auch alternative Narrative kritisch analysiert. `;
  report += `Das Ziel ist eine umfassende, ausgewogene Dokumentation aller verfügbaren Informationen, `;
  report += `Quellen und unterschiedlichen Interpretationen. Die Recherche basiert auf offiziellen Regierungsdokumenten, `;
  report += `investigativem Journalismus, wissenschaftlichen Publikationen und unabhängigen Quellen. `;
  report += `Besonders relevant sind dabei die historischen Entwicklungen, dokumentierte Fakten und `;
  report += `die verschiedenen Interpretationsansätze, die in der öffentlichen und akademischen Diskussion vertreten werden.\n\n`;
  
  if (narrative) {
    report += `## Historischer Kontext\n\n`;
    report += `**${narrative.title}** ist ein bedeutendes Thema in der Erforschung alternativer Narrative. `;
    report += `Die historische Entwicklung zeigt eine Reihe wichtiger Ereignisse:\n\n`;
    narrative.timeline.forEach(event => {
      report += `**${event.year}**: ${event.event}\n\n`;
      report += `Dieses Ereignis markiert einen wichtigen Wendepunkt in der öffentlichen Wahrnehmung und `;
      report += `hat zu zahlreichen Fragen und Untersuchungen geführt. Die Bedeutung dieses Datums liegt `;
      report += `darin, dass es sowohl offizielle als auch alternative Interpretationen hervorbrachte.\n\n`;
    });
    
    if (narrative.location) {
      report += `**Geografischer Kontext**: Die Ereignisse sind geografisch mit ${narrative.location.name} verbunden. `;
      report += `Diese Lokalisierung ist wichtig für das Verständnis der regionalen und globalen Zusammenhänge. `;
      report += `Der Ort selbst hat historische und strategische Bedeutung in diesem Kontext.\n\n`;
    }
  }
  
  report += `## Offizielle Perspektive\n\n`;
  report += `Die offiziellen Darstellungen zu "${query}" stammen von verschiedenen staatlichen Institutionen, `;
  report += `etablierten Medien und anerkannten Experten. Diese Perspektiven betonen in der Regel:\n\n`;
  report += `**Regierungsposition**: Offizielle Stellen haben verschiedene Erklärungen und Berichte veröffentlicht. `;
  report += `Diese basieren auf offiziellen Untersuchungen, Kommissionen und Studien. Die Kernaussagen `;
  report += `konzentrieren sich auf etablierte Fakten und konventionelle Erklärungsmodelle. Regierungsbehörden `;
  report += `haben teilweise Dokumente freigegeben, die Einblicke in offizielle Vorgänge geben.\n\n`;
  report += `**Mainstream-Medien**: Etablierte Nachrichtenagenturen wie CNN, BBC, New York Times und andere `;
  report += `haben umfangreich über das Thema berichtet. Ihre Darstellungen folgen in der Regel den `;
  report += `offiziellen Narrativen und betonen Quellen, die als vertrauenswürdig gelten. Die Berichterstattung `;
  report += `konzentriert sich auf verifizierte Fakten und etablierte Erklärungsansätze.\n\n`;
  report += `**Wissenschaftliche Institutionen**: Akademische Einrichtungen und Forschungsinstitute haben `;
  report += `Studien durchgeführt und Analysen veröffentlicht. Diese basieren auf wissenschaftlichen Methoden `;
  report += `und peer-reviewten Prozessen. Die Schlussfolgerungen orientieren sich an empirischen Daten `;
  report += `und etablierten wissenschaftlichen Paradigmen.\n\n`;
  
  report += `## Alternative Perspektiven\n\n`;
  report += `Unabhängige Forscher, investigative Journalisten und alternative Medien bieten oft abweichende `;
  report += `Interpretationen und kritische Analysen:\n\n`;
  report += `**Kritische Hinterfragung**: Alternative Quellen weisen auf Widersprüche in offiziellen `;
  report += `Darstellungen hin. Sie analysieren Lücken in der Beweisführung, ungeklärte Fragen und `;
  report += `Inkonsistenzen in offiziellen Berichten. Besonders kritisch werden oft die Informationspolitik `;
  report += `und der Umgang mit klassifizierten Dokumenten betrachtet.\n\n`;
  report += `**Unabhängige Untersuchungen**: Journalisten von The Intercept, ProPublica, Bellingcat und `;
  report += `anderen investigativen Medien haben eigene Recherchen durchgeführt. Diese basieren auf `;
  report += `FOIA-Anfragen, Whistleblower-Aussagen und unabhängigen forensischen Analysen. Die Ergebnisse `;
  report += `weichen teilweise erheblich von offiziellen Narrativen ab.\n\n`;
  report += `**Whistleblower-Aussagen**: Insider und ehemalige Mitarbeiter relevanter Organisationen haben `;
  report += `in verschiedenen Fällen öffentlich über ihre Erfahrungen gesprochen. Diese Zeugenaussagen `;
  report += `bieten oft Einblicke in interne Vorgänge und werfen neue Fragen auf. Die Glaubwürdigkeit `;
  report += `dieser Quellen wird kontrovers diskutiert.\n\n`;
  report += `**Alternative Theorien**: Verschiedene Erklärungsmodelle wurden entwickelt, die von den `;
  report += `offiziellen Narrativen abweichen. Diese Theorien basieren auf unterschiedlichen Interpretationen `;
  report += `der verfügbaren Beweise und ziehen alternative Schlussfolgerungen. Die Diskussion um diese `;
  report += `Ansätze ist Teil einer breiteren Debatte über Transparenz und Informationsfreiheit.\n\n`;
  
  report += `## Dokumentation & Quellen\n\n`;
  report += `Für weiterführende Recherchen stehen folgende Quellen zur Verfügung:\n\n`;
  
  const mainstreamSources = sources.filter(s => s.sourceType === 'mainstream').slice(0, 3);
  const alternativeSources = sources.filter(s => s.sourceType === 'alternative').slice(0, 3);
  const independentSources = sources.filter(s => s.sourceType === 'independent').slice(0, 2);
  
  if (mainstreamSources.length > 0) {
    report += `**Offizielle Quellen:**\n`;
    mainstreamSources.forEach(s => {
      report += `- [${s.title}](${s.url}): ${s.snippet}\n`;
    });
    report += `\n`;
  }
  
  if (alternativeSources.length > 0) {
    report += `**Alternative & Investigative Quellen:**\n`;
    alternativeSources.forEach(s => {
      report += `- [${s.title}](${s.url}): ${s.snippet}\n`;
    });
    report += `\n`;
  }
  
  if (independentSources.length > 0) {
    report += `**Unabhängige Archive:**\n`;
    independentSources.forEach(s => {
      report += `- [${s.title}](${s.url}): ${s.snippet}\n`;
    });
    report += `\n`;
  }
  
  report += `## Offene Fragen\n\n`;
  report += `Trotz umfangreicher Recherchen bleiben wichtige Fragen offen:\n\n`;
  report += `- Welche klassifizierten Dokumente existieren noch und wann werden sie freigegeben?\n`;
  report += `- Wie lassen sich Widersprüche zwischen verschiedenen Quellen erklären?\n`;
  report += `- Welche Rolle spielten verschiedene Akteure und Organisationen?\n`;
  report += `- Welche neuen Beweise könnten in Zukunft auftauchen?\n`;
  report += `- Wie beeinflusst die fortschreitende Freigabe von Dokumenten unser Verständnis?\n\n`;
  
  report += `## Schlussfolgerung\n\n`;
  report += `Das Thema "${query}" erfordert eine differenzierte Betrachtung aus verschiedenen Perspektiven. `;
  report += `Sowohl offizielle als auch alternative Narrative bieten wichtige Einblicke und Informationen. `;
  report += `Eine umfassende Auseinandersetzung mit allen verfügbaren Quellen, kritisches Denken und `;
  report += `die Bereitschaft, verschiedene Interpretationen zu berücksichtigen, sind essentiell für ein `;
  report += `vollständiges Verständnis. Weiterführende Forschung und die fortlaufende Analyse neu `;
  report += `freigegebener Dokumente werden unser Wissen in diesem Bereich weiter vertiefen.\n`;
  
  return report;
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
