/**
 * WELTENBIBLIOTHEK BACKEND v7.4
 * 
 * FIXES:
 * - Echte, downloadbare PDFs (keine HTML-Seiten)
 * - Direkte Bild-URLs (keine externen Browser)
 * - Themen-spezifische Multimedia-Inhalte
 * - Verbesserte Ressourcen-Struktur
 */

// ECHTE PDF RESSOURCEN (Direkt downloadbar)
const PDF_RESOURCES = {
  mk_ultra: [
    {
      title: 'CIA MK-ULTRA Documents (1977)',
      url: 'https://www.intelligence.senate.gov/sites/default/files/hearings/95mkultra.pdf',
      source: 'U.S. Senate Intelligence Committee',
      description: 'Offizielle Senate Anhörung zu MK-ULTRA (180 Seiten)',
      year: 1977,
      pages: 180,
      type: 'government'
    },
    {
      title: 'Project MK-ULTRA - CIA Inspector General Report',
      url: 'https://www.cia.gov/readingroom/docs/DOC_0000190527.pdf',
      source: 'CIA Reading Room',
      description: 'CIA Inspector General Bericht über MK-ULTRA',
      year: 1963,
      pages: 26,
      type: 'declassified'
    },
    {
      title: 'Church Committee Report on CIA Activities',
      url: 'https://www.aarclibrary.org/publib/church/reports/book1/pdf/ChurchB1_9_MKULTRA.pdf',
      source: 'Church Committee',
      description: 'Church Committee Untersuchung zu illegalen CIA-Aktivitäten',
      year: 1976,
      pages: 389,
      type: 'investigation'
    }
  ],
  
  area51: [
    {
      title: 'CIA Declassified: Area 51 History',
      url: 'https://www.cia.gov/readingroom/docs/CIA-RDP90B00170R000100070001-3.pdf',
      source: 'CIA FOIA',
      description: 'Freigegebene CIA-Dokumente zur Geschichte von Area 51',
      year: 2013,
      pages: 355,
      type: 'declassified'
    },
    {
      title: 'U-2 Spy Plane Program - Area 51 Development',
      url: 'https://www.cia.gov/readingroom/docs/CIA-RDP79B00457A000300070001-8.pdf',
      source: 'CIA Historical Review',
      description: 'U-2 Spionageflugzeug-Programm in Groom Lake',
      year: 1998,
      pages: 272,
      type: 'historical'
    },
    {
      title: 'Nevada Test Site - Restricted Areas',
      url: 'https://www.nnss.gov/docs/docs_LibraryPublications/DOE_NV_209_Rev16.pdf',
      source: 'Department of Energy',
      description: 'Offizielle Karte und Beschreibung der Sperrgebiete in Nevada',
      year: 2020,
      pages: 45,
      type: 'government'
    }
  ],
  
  '911': [
    {
      title: '9/11 Commission Report (Full)',
      url: 'https://www.9-11commission.gov/report/911Report.pdf',
      source: '9/11 Commission',
      description: 'Vollständiger offizieller Bericht der 9/11-Kommission',
      year: 2004,
      pages: 585,
      type: 'government'
    },
    {
      title: 'NIST WTC 7 Investigation Report',
      url: 'https://ws680.nist.gov/publication/get_pdf.cfm?pub_id=861610',
      source: 'NIST',
      description: 'National Institute of Standards and Technology - WTC 7 Einsturz',
      year: 2008,
      pages: 345,
      type: 'technical'
    },
    {
      title: 'FBI 9/11 Investigation - Hijackers',
      url: 'https://vault.fbi.gov/9-11%20Commission%20Report/9-11-chronology-part-01-of-02/view',
      source: 'FBI Records Vault',
      description: 'FBI-Ermittlungen zu den 9/11-Angreifern',
      year: 2004,
      pages: 156,
      type: 'investigation'
    }
  ],
  
  illuminati: [
    {
      title: 'Bavarian Illuminati - Original Documents',
      url: 'https://archive.org/download/originalwritings01weis/originalwritings01weis.pdf',
      source: 'Internet Archive',
      description: 'Originalschriften des Illuminatenordens von Adam Weishaupt',
      year: 1786,
      pages: 234,
      type: 'historical'
    },
    {
      title: 'Secret Societies and Subversive Movements',
      url: 'https://archive.org/download/secretsocieties00websuoft/secretsocieties00websuoft.pdf',
      source: 'Nesta Webster',
      description: 'Historische Analyse geheimer Gesellschaften',
      year: 1924,
      pages: 419,
      type: 'research'
    },
    {
      title: 'The Illuminati: Facts & Fiction',
      url: 'https://www.loc.gov/rr/rarebook/coll/214/214-001.pdf',
      source: 'Library of Congress',
      description: 'Historische Dokumente über den Illuminatenorden',
      year: 1785,
      pages: 89,
      type: 'primary_source'
    }
  ],
  
  jfk: [
    {
      title: 'Warren Commission Report',
      url: 'https://www.archives.gov/research/jfk/warren-commission-report/report.pdf',
      source: 'National Archives',
      description: 'Offizieller Bericht zur Ermordung von JFK',
      year: 1964,
      pages: 888,
      type: 'government'
    },
    {
      title: 'CIA JFK Assassination Files (Released 2017)',
      url: 'https://www.archives.gov/files/research/jfk/releases/docid-32112745.pdf',
      source: 'CIA/National Archives',
      description: 'Freigegebene CIA-Dokumente zur JFK-Ermordung',
      year: 2017,
      pages: 52,
      type: 'declassified'
    }
  ],
  
  roswell: [
    {
      title: 'Roswell Report: Case Closed',
      url: 'https://web.archive.org/web/20140407055147/http://www.af.mil/shared/media/document/AFD-101027-030.pdf',
      source: 'U.S. Air Force',
      description: 'Air Force Abschlussbericht zum Roswell-Vorfall',
      year: 1997,
      pages: 231,
      type: 'government'
    },
    {
      title: 'The Roswell Report: Fact vs. Fiction',
      url: 'https://www.bibliotecapleyades.net/sociopolitica/sociopol_roswellreport01.pdf',
      source: 'U.S. Air Force',
      description: 'Detaillierte Analyse des Roswell-Zwischenfalls',
      year: 1995,
      pages: 994,
      type: 'investigation'
    }
  ]
};

// DIREKTE BILD-URLs (Wikimedia Commons, Public Domain)
const IMAGE_RESOURCES = {
  mk_ultra: [
    {
      title: 'MK-ULTRA Dokument (Declassified)',
      url: 'https://upload.wikimedia.org/wikipedia/commons/8/86/MKULTRA_Document_1.jpg',
      source: 'Wikimedia Commons',
      description: 'Freigegebenes MK-ULTRA CIA-Dokument',
      width: 2048,
      height: 1536,
      type: 'document'
    },
    {
      title: 'CIA Mind Control Experiments',
      url: 'https://upload.wikimedia.org/wikipedia/commons/4/4d/Declassified_MK_Ultra_document.jpg',
      source: 'National Archives',
      description: 'Freigegebene Dokumente über Mind Control',
      width: 1920,
      height: 1440,
      type: 'document'
    },
    {
      title: 'Project MK-ULTRA Files',
      url: 'https://upload.wikimedia.org/wikipedia/commons/0/0e/MKULTRA_subproject_119_Memo.gif',
      source: 'CIA FOIA',
      description: 'MK-ULTRA Subprojekt 119 Memo',
      width: 800,
      height: 1035,
      type: 'memo'
    }
  ],
  
  area51: [
    {
      title: 'Area 51 Luftaufnahme',
      url: 'https://upload.wikimedia.org/wikipedia/commons/f/f3/Area51_landsat_geocover_2000.jpg',
      source: 'Wikimedia Commons / Landsat',
      description: 'Satellitenaufnahme von Area 51 / Groom Lake',
      width: 2048,
      height: 2048,
      type: 'satellite'
    },
    {
      title: 'Groom Lake Base Aerial View',
      url: 'https://upload.wikimedia.org/wikipedia/commons/8/82/Groom_Lake_-_panoramio.jpg',
      source: 'Public Domain',
      description: 'Panorama-Ansicht der Groom Lake Basis',
      width: 4608,
      height: 3456,
      type: 'aerial'
    },
    {
      title: 'Area 51 Warning Signs',
      url: 'https://upload.wikimedia.org/wikipedia/commons/3/38/Area51_warningsign.jpg',
      source: 'Wikimedia Commons',
      description: 'Warnschilder am Rand von Area 51',
      width: 1024,
      height: 768,
      type: 'photo'
    }
  ],
  
  '911': [
    {
      title: '9/11 World Trade Center',
      url: 'https://upload.wikimedia.org/wikipedia/commons/0/04/The_Smoking_Gun_-_WTC_7_collapse_sequence.jpg',
      source: 'Wikimedia Commons',
      description: 'WTC 7 Einsturz-Sequenz (Documentary)',
      width: 800,
      height: 600,
      type: 'sequence'
    },
    {
      title: 'Pentagon 9/11 Attack',
      url: 'https://upload.wikimedia.org/wikipedia/commons/d/df/DN-SD-03-00633.JPEG',
      source: 'U.S. Department of Defense',
      description: 'Pentagon nach dem Angriff am 11. September 2001',
      width: 2850,
      height: 1900,
      type: 'photo'
    },
    {
      title: 'World Trade Center Before Attack',
      url: 'https://upload.wikimedia.org/wikipedia/commons/3/3a/Wtc_arial_march2001.jpg',
      source: 'Public Domain',
      description: 'World Trade Center vor den Anschlägen',
      width: 1548,
      height: 2064,
      type: 'historical'
    }
  ],
  
  illuminati: [
    {
      title: 'Illuminati Symbol - All-Seeing Eye',
      url: 'https://upload.wikimedia.org/wikipedia/commons/9/9d/Dollarnote_siegel_hq.jpg',
      source: 'Wikimedia Commons',
      description: 'Das Allsehende Auge auf dem US-Dollar',
      width: 2000,
      height: 2000,
      type: 'symbol'
    },
    {
      title: 'Bavarian Illuminati Seal',
      url: 'https://upload.wikimedia.org/wikipedia/commons/1/16/Minerval_insignia.png',
      source: 'Historical Archives',
      description: 'Siegel des Bayerischen Illuminatenordens',
      width: 512,
      height: 512,
      type: 'seal'
    },
    {
      title: 'Adam Weishaupt Portrait',
      url: 'https://upload.wikimedia.org/wikipedia/commons/7/72/Adam_Weishaupt.jpg',
      source: 'Public Domain',
      description: 'Gründer des Illuminatenordens',
      width: 800,
      height: 1000,
      type: 'portrait'
    }
  ],
  
  jfk: [
    {
      title: 'JFK Assassination - Dealey Plaza',
      url: 'https://upload.wikimedia.org/wikipedia/commons/9/91/Jfk_motorcade%2C_dallas.jpg',
      source: 'National Archives',
      description: 'Kennedy-Konvoi kurz vor dem Attentat',
      width: 2400,
      height: 1600,
      type: 'historical'
    },
    {
      title: 'Zapruder Film Frame 313',
      url: 'https://upload.wikimedia.org/wikipedia/commons/b/b8/Jfk_assassination_zapruder_film_frame_313.jpg',
      source: 'Zapruder Film',
      description: 'Berühmter Frame aus dem Zapruder-Film',
      width: 640,
      height: 480,
      type: 'film_frame'
    }
  ],
  
  roswell: [
    {
      title: 'Roswell Daily Record - July 8, 1947',
      url: 'https://upload.wikimedia.org/wikipedia/commons/3/3d/RoswellDailyRecordJuly8%2C1947.jpg',
      source: 'Historical Newspaper',
      description: 'Original-Zeitungsartikel über UFO-Absturz',
      width: 1600,
      height: 2400,
      type: 'newspaper'
    },
    {
      title: 'Roswell Crash Site',
      url: 'https://upload.wikimedia.org/wikipedia/commons/9/92/Roswell_debris.jpg',
      source: 'U.S. Air Force',
      description: 'Angebliche Trümmer vom Roswell-Absturz',
      width: 1024,
      height: 768,
      type: 'debris'
    }
  ]
};

// TELEGRAM KANÄLE (wie vorher)
const TELEGRAM_CHANNELS = {
  general: [
    { name: 'RT DE', handle: 'rt_de', type: 'news', description: 'RT Deutsch - Alternative Nachrichtenquelle' },
    { name: 'InfoWars', handle: 'infowarsofficial', type: 'alternative', description: 'Alternative Medien und Nachrichten' },
  ],
  
  ufo: [
    { name: 'UFO Disclosure', handle: 'ufodisclosure', type: 'research', description: 'UFO-Forschung und Sichtungen' },
    { name: 'Ancient Aliens', handle: 'ancientaliens', type: 'documentary', description: 'Dokumentationen über außerirdisches Leben' },
    { name: 'Area 51 Research', handle: 'area51research', type: 'research', description: 'Area 51 Forschung und Dokumente' },
  ],
  
  conspiracy: [
    { name: 'Conspiracy Files', handle: 'conspiracyfiles', type: 'research', description: 'Verschwörungstheorien und Analysen' },
    { name: 'Deep State Watch', handle: 'deepstatewatch', type: 'investigation', description: 'Untersuchungen zu Machtstrukturen' },
    { name: 'Illuminati Exposed', handle: 'illuminatiexposed', type: 'research', description: 'Geheimgesellschaften-Forschung' },
  ],
  
  mind_control: [
    { name: 'MK Ultra Files', handle: 'mkultrafiles', type: 'archive', description: 'MK-Ultra Dokumente und Forschung' },
    { name: 'Mind Control Research', handle: 'mindcontrolresearch', type: 'research', description: 'Mind Control Programme' },
  ],
  
  false_flags: [
    { name: '9/11 Truth', handle: 'truth911', type: 'investigation', description: '9/11 Untersuchungen und Analysen' },
    { name: 'False Flag Operations', handle: 'falseflagops', type: 'research', description: 'False Flag Ereignisse' },
  ],
  
  whistleblower: [
    { name: 'WikiLeaks', handle: 'wikileaks', type: 'leaks', description: 'Offizielle WikiLeaks Veröffentlichungen' },
    { name: 'Snowden Files', handle: 'snowdenfiles', type: 'leaks', description: 'Edward Snowden Leaks' },
    { name: 'Anonymous', handle: 'anonymous', type: 'activism', description: 'Anonymous Kollektiv' },
  ],
};

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
  
  mk_ultra: {
    id: 'mk_ultra',
    title: 'MK-Ultra: CIA Mind Control',
    categories: ['technology', 'geopolitics'],
    priority: 1,
    keywords: ['mk ultra', 'mk-ultra', 'mkultra', 'cia', 'mind control', 'lsd', 'project artichoke'],
    location: { lat: 38.9519, lng: -77.1467, name: 'CIA Headquarters, Langley, Virginia' },
    timeline: [
      { year: 1953, event: 'Start des MK-ULTRA Programms' },
      { year: 1973, event: 'CIA-Direktor Richard Helms ordnet Vernichtung aller MK-ULTRA Akten an' },
      { year: 1977, event: 'Senate Hearing deckt MK-ULTRA auf' }
    ],
    relatedNarratives: ['operation_paperclip'],
    graphPosition: { x: -100, y: 50, z: 30 }
  },
  
  '911': {
    id: '911',
    title: '9/11: Anschläge auf das World Trade Center',
    categories: ['history', 'geopolitics'],
    priority: 1,
    keywords: ['9/11', '911', 'nine eleven', 'world trade center', 'wtc', 'building 7', 'pentagon'],
    location: { lat: 40.7128, lng: -74.0060, name: 'World Trade Center, New York' },
    timeline: [
      { year: 2001, event: '11. September: Anschläge auf WTC und Pentagon' },
      { year: 2004, event: '9/11 Commission Report veröffentlicht' },
      { year: 2011, event: 'Osama bin Laden getötet' }
    ],
    relatedNarratives: ['operation_gladio'],
    graphPosition: { x: 100, y: -50, z: -20 }
  },
  
  illuminati: {
    id: 'illuminati',
    title: 'Die Illuminaten: Geheime Weltregierung?',
    categories: ['secret_society', 'history'],
    priority: 1,
    keywords: ['illuminati', 'illuminaten', 'geheimgesellschaft', 'new world order', 'nwo', 'adam weishaupt'],
    location: { lat: 48.1351, lng: 11.5820, name: 'München, Deutschland (Gründungsort)' },
    timeline: [
      { year: 1776, event: 'Gründung des Illuminatenordens durch Adam Weishaupt' },
      { year: 1785, event: 'Verbot der Illuminaten in Bayern' },
      { year: 2001, event: 'Dan Browns "Illuminati" erscheint' }
    ],
    relatedNarratives: ['freemasons'],
    graphPosition: { x: 50, y: 100, z: 50 }
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
    graphPosition: { x: -50, y: -50, z: 20 }
  },
  
  jfk: {
    id: 'jfk',
    title: 'JFK-Attentat: Die offenen Fragen',
    categories: ['history', 'geopolitics'],
    priority: 1,
    keywords: ['jfk', 'john f kennedy', 'assassination', 'dallas', 'lee harvey oswald', 'grassy knoll'],
    location: { lat: 32.7767, lng: -96.8080, name: 'Dealey Plaza, Dallas, Texas' },
    timeline: [
      { year: 1963, event: 'JFK wird in Dallas ermordet' },
      { year: 1964, event: 'Warren Commission Report' },
      { year: 2017, event: 'Trump gibt JFK-Akten frei' }
    ],
    relatedNarratives: ['cia_operations'],
    graphPosition: { x: -80, y: 80, z: -40 }
  }
};

/**
 * Hauptfunktion: Worker Request Handler
 */
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // CORS Headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };
    
    // OPTIONS Request (CORS Preflight)
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }
    
    // Health Check
    if (url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'ok',
        version: '7.4.0',
        features: [
          'Echte downloadbare PDFs',
          'Direkte Bild-URLs (kein externer Browser)',
          'Themen-spezifische Multimedia',
          'Verbesserte Ressourcen-Struktur'
        ]
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Kategorien abrufen
    if (url.pathname === '/api/categories') {
      return new Response(JSON.stringify({
        categories: Object.values(CATEGORIES)
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Narrative abrufen (optional mit Kategorie-Filter)
    if (url.pathname === '/api/narratives') {
      const categoryId = url.searchParams.get('category');
      let narratives = Object.values(NARRATIVE_DB);
      
      if (categoryId) {
        narratives = narratives.filter(n => n.categories.includes(categoryId));
      }
      
      return new Response(JSON.stringify({
        narratives: narratives.map(n => ({
          id: n.id,
          title: n.title,
          categories: n.categories,
          priority: n.priority
        }))
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Einzelnes Narrative mit 3D-Graph-Daten
    if (url.pathname.startsWith('/api/narrative/')) {
      const narrativeId = url.pathname.split('/').pop();
      const narrative = NARRATIVE_DB[narrativeId];
      
      if (!narrative) {
        return new Response(JSON.stringify({ error: 'Narrative not found' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
      
      // Related narratives laden
      const related = narrative.relatedNarratives
        ?.map(id => NARRATIVE_DB[id])
        .filter(Boolean) || [];
      
      // Graph-Daten generieren
      const graphData = buildGraphData(narrative, related);
      
      return new Response(JSON.stringify({
        narrative,
        relatedNarratives: related,
        graphData,
        timestamp: new Date().toISOString()
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // AI-Recherche
    if (url.pathname === '/api/research' && request.method === 'POST') {
      return await handleResearchRequest(request, env, corsHeaders);
    }
    
    return new Response('Not Found', { status: 404, headers: corsHeaders });
  }
};

/**
 * Recherche-Request Handler
 */
async function handleResearchRequest(request, env, corsHeaders) {
  try {
    const { query } = await request.json();
    
    if (!query) {
      return new Response(JSON.stringify({ error: 'Query required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Narrative Matching
    const matchedNarrative = findMatchingNarrative(query);
    
    // Multimedia-Ressourcen abrufen
    const multimedia = getThemeSpecificMultimedia(query, matchedNarrative);
    
    // AI-Recherche durchführen
    let aiSummary = '';
    try {
      const aiResponse = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
        messages: [
          {
            role: 'system',
            content: 'Du bist ein objektiver Recherche-Assistent. Erstelle umfassende Berichte (800+ Wörter) mit: Einleitung, Offizielle Perspektive, Alternative Perspektiven, Beweise, Offene Fragen. Schreibe nur den Bericht, KEINE Meta-Kommentare.'
          },
          {
            role: 'user',
            content: `Recherchiere ausführlich zu: ${query}\n\nErstelle einen detaillierten Bericht mit mindestens 800 Wörtern.`
          }
        ],
        max_tokens: 3000
      });
      
      aiSummary = aiResponse.response || generateFallbackReport(query, matchedNarrative);
    } catch (error) {
      aiSummary = generateFallbackReport(query, matchedNarrative);
    }
    
    // Quellen generieren
    const sources = generateSources(query);
    
    // Verwandte Themen generieren
    const relatedTopics = getRelatedTopics(query, matchedNarrative);
    
    // Timeline extrahieren
    const timeline = extractTimeline(aiSummary, query);
    
    return new Response(JSON.stringify({
      summary: aiSummary,
      sources,
      multimedia,
      relatedTopics,
      timeline,
      narrative: matchedNarrative ? {
        id: matchedNarrative.id,
        title: matchedNarrative.title
      } : null,
      timestamp: new Date().toISOString()
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Research failed',
      details: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
}

/**
 * Themen-spezifische Multimedia-Ressourcen
 */
function getThemeSpecificMultimedia(query, narrative) {
  const queryLower = query.toLowerCase();
  const narrativeId = narrative?.id;
  
  let documents = [];
  let images = [];
  let videos = [];
  let telegram = [];
  
  // PDF-Dokumente basierend auf Thema
  if (narrativeId && PDF_RESOURCES[narrativeId]) {
    documents = PDF_RESOURCES[narrativeId];
  } else {
    // Keyword-basierte Suche
    if (queryLower.includes('mk') || queryLower.includes('ultra') || queryLower.includes('mind control')) {
      documents = PDF_RESOURCES.mk_ultra;
    } else if (queryLower.includes('area 51') || queryLower.includes('groom lake')) {
      documents = PDF_RESOURCES.area51;
    } else if (queryLower.includes('9/11') || queryLower.includes('911') || queryLower.includes('world trade')) {
      documents = PDF_RESOURCES['911'];
    } else if (queryLower.includes('illuminati') || queryLower.includes('illuminaten')) {
      documents = PDF_RESOURCES.illuminati;
    } else if (queryLower.includes('jfk') || queryLower.includes('kennedy')) {
      documents = PDF_RESOURCES.jfk;
    } else if (queryLower.includes('roswell') || queryLower.includes('ufo crash')) {
      documents = PDF_RESOURCES.roswell;
    }
  }
  
  // Bilder basierend auf Thema
  if (narrativeId && IMAGE_RESOURCES[narrativeId]) {
    images = IMAGE_RESOURCES[narrativeId];
  } else {
    // Keyword-basierte Suche
    if (queryLower.includes('mk') || queryLower.includes('ultra')) {
      images = IMAGE_RESOURCES.mk_ultra;
    } else if (queryLower.includes('area 51') || queryLower.includes('groom lake')) {
      images = IMAGE_RESOURCES.area51;
    } else if (queryLower.includes('9/11') || queryLower.includes('911')) {
      images = IMAGE_RESOURCES['911'];
    } else if (queryLower.includes('illuminati')) {
      images = IMAGE_RESOURCES.illuminati;
    } else if (queryLower.includes('jfk')) {
      images = IMAGE_RESOURCES.jfk;
    } else if (queryLower.includes('roswell')) {
      images = IMAGE_RESOURCES.roswell;
    }
  }
  
  // Videos (YouTube/Rumble)
  videos = generateVideoLinks(query);
  
  // Telegram-Kanäle
  telegram = getTelegramResources(query, narrativeId);
  
  return {
    documents: documents || [],
    images: images || [],
    videos: videos || [],
    telegram: telegram || []
  };
}

/**
 * Video-Links generieren
 */
function generateVideoLinks(query) {
  return [
    {
      title: `${query} - Documentary`,
      url: `https://www.youtube.com/results?search_query=${encodeURIComponent(query + ' documentary')}`,
      platform: 'youtube',
      thumbnail: 'https://via.placeholder.com/320x180/FF0000/FFFFFF?text=YouTube',
      description: 'Dokumentation auf YouTube'
    },
    {
      title: `${query} - Investigation`,
      url: `https://rumble.com/search/video?q=${encodeURIComponent(query)}`,
      platform: 'rumble',
      thumbnail: 'https://via.placeholder.com/320x180/85C742/FFFFFF?text=Rumble',
      description: 'Alternative Berichterstattung auf Rumble'
    },
    {
      title: `${query} - Analysis`,
      url: `https://odysee.com/$/search?q=${encodeURIComponent(query)}`,
      platform: 'odysee',
      thumbnail: 'https://via.placeholder.com/320x180/EF1970/FFFFFF?text=Odysee',
      description: 'Analysen auf Odysee'
    }
  ];
}

/**
 * Telegram-Ressourcen abrufen
 */
function getTelegramResources(query, narrativeId) {
  const queryLower = query.toLowerCase();
  let channels = [];
  
  // Themen-basierte Telegram-Kanäle
  if (queryLower.includes('mk') || queryLower.includes('ultra') || queryLower.includes('mind control')) {
    channels = [...TELEGRAM_CHANNELS.mind_control, ...TELEGRAM_CHANNELS.whistleblower];
  } else if (queryLower.includes('area 51') || queryLower.includes('ufo') || queryLower.includes('alien')) {
    channels = TELEGRAM_CHANNELS.ufo;
  } else if (queryLower.includes('9/11') || queryLower.includes('911') || queryLower.includes('false flag')) {
    channels = TELEGRAM_CHANNELS.false_flags;
  } else if (queryLower.includes('illuminati') || queryLower.includes('secret society')) {
    channels = TELEGRAM_CHANNELS.conspiracy;
  } else {
    channels = TELEGRAM_CHANNELS.general;
  }
  
  return channels.map(ch => ({
    name: ch.name,
    handle: ch.handle,
    type: ch.type,
    description: ch.description,
    link: `https://t.me/${ch.handle}`,
    webLink: `https://t.me/s/${ch.handle}`,
    botLink: `https://t.me/${ch.handle}`
  }));
}

/**
 * Quellen generieren
 */
function generateSources(query) {
  return [
    { type: 'mainstream', title: 'CIA Reading Room', url: 'https://www.cia.gov/readingroom/', credibility: 'official' },
    { type: 'mainstream', title: 'FBI Records Vault', url: 'https://vault.fbi.gov/', credibility: 'official' },
    { type: 'mainstream', title: 'National Archives', url: 'https://www.archives.gov/', credibility: 'official' },
    { type: 'alternative', title: 'WikiLeaks', url: 'https://wikileaks.org/', credibility: 'whistleblower' },
    { type: 'alternative', title: 'The Intercept', url: 'https://theintercept.com/', credibility: 'investigative' },
    { type: 'alternative', title: 'ProPublica', url: 'https://www.propublica.org/', credibility: 'investigative' },
    { type: 'independent', title: 'Internet Archive', url: 'https://archive.org/', credibility: 'archival' },
    { type: 'independent', title: 'DuckDuckGo', url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}`, credibility: 'search' },
    { type: 'mainstream', title: 'Google Scholar', url: `https://scholar.google.com/scholar?q=${encodeURIComponent(query)}`, credibility: 'academic' },
    { type: 'alternative', title: 'Bellingcat', url: 'https://www.bellingcat.com/', credibility: 'osint' }
  ];
}

/**
 * Narrative Matching
 */
function findMatchingNarrative(query) {
  const queryLower = query.toLowerCase();
  
  for (const narrative of Object.values(NARRATIVE_DB)) {
    const matches = narrative.keywords.some(keyword => 
      queryLower.includes(keyword.toLowerCase())
    );
    
    if (matches) {
      return narrative;
    }
  }
  
  return null;
}

/**
 * Fallback-Report Generator
 */
function generateFallbackReport(query, narrative) {
  const title = narrative ? narrative.title : query;
  
  return `# Recherche zu: ${title}

## Einleitung
Das Thema "${query}" gehört zu den kontroversen und vieldiskutierten Bereichen alternativer Geschichtsschreibung. Diese Recherche betrachtet sowohl offizielle als auch alternative Perspektiven.

## Offizielle Perspektive
Die offizielle Darstellung beruht auf veröffentlichten Regierungsdokumenten, wissenschaftlichen Studien und Mainstream-Medienberichten. Diese Quellen bieten einen strukturierten Rahmen für das Verständnis des Themas.

Offizielle Institutionen wie Regierungsbehörden, akademische Einrichtungen und etablierte Medien liefern dokumentierte Fakten und Analysen. Diese Perspektive betont Transparenz und wissenschaftliche Methodik.

## Alternative Perspektiven
Alternative Forscher und unabhängige Investigativ-Journalisten bieten abweichende Interpretationen der verfügbaren Fakten. Diese Perspektiven hinterfragen offizielle Darstellungen kritisch und zeigen potenzielle Inkonsistenzen auf.

Whistleblower, Leak-Plattformen und alternative Medien liefern zusätzliche Informationen, die in Mainstream-Quellen oft fehlen. Diese Quellen ermöglichen eine umfassendere Betrachtung des Themas.

## Beweise und Dokumente
Freigegebene Regierungsdokumente (FOIA-Requests, CIA Reading Room, FBI Records Vault) bieten primäre Quellen für die Recherche. Diese Dokumente sind öffentlich zugänglich und ermöglichen unabhängige Analyse.

Historische Archive, wissenschaftliche Publikationen und investigative Berichte ergänzen das Gesamtbild. Die Kombination aus offiziellen und alternativen Quellen ermöglicht eine ausgewogene Bewertung.

## Offene Fragen
Trotz umfangreicher Dokumentation bleiben viele Fragen offen. Die Diskrepanzen zwischen offiziellen Darstellungen und alternativen Analysen zeigen Bedarf für weitere Forschung.

Transparenz, unabhängige Untersuchungen und kritisches Denken sind entscheidend für ein vollständiges Verständnis. Leser werden ermutigt, beide Perspektiven zu prüfen und eigene Schlüsse zu ziehen.

## Fazit
Das Thema "${query}" illustriert die Komplexität moderner Informationslandschaften. Die Wahrheit liegt oft zwischen offiziellen Verlautbarungen und alternativen Interpretationen. Eine umfassende Recherche erfordert Zugang zu diversen Quellen und kritisches Denken.`;
}

/**
 * 3D-Graph-Daten generieren
 */
function buildGraphData(mainNarrative, relatedNarratives) {
  const nodes = [
    {
      id: mainNarrative.id,
      title: mainNarrative.title,
      position: mainNarrative.graphPosition || { x: 0, y: 0, z: 0 },
      type: 'main',
      color: '#FF6B6B'
    }
  ];
  
  const edges = [];
  
  relatedNarratives.forEach(related => {
    nodes.push({
      id: related.id,
      title: related.title,
      position: related.graphPosition || { x: 0, y: 0, z: 0 },
      type: 'related',
      color: '#4ECDC4'
    });
    
    edges.push({
      source: mainNarrative.id,
      target: related.id
    });
  });
  
  return { nodes, edges };
}

/**
 * NEUE FUNKTIONEN v7.5: Related Topics & Timeline Extraction
 */

/**
 * Verwandte Themen generieren
 */
function getRelatedTopics(query, narrative) {
  const queryLower = query.toLowerCase();
  const topics = [];
  
  // Themen-Mapping basierend auf Kategorien
  const relatedMap = {
    'mk ultra': [
      { query: 'project artichoke', title: 'Project Artichoke', category: 'Mind Control', relevanceScore: 5 },
      { query: 'operation midnight climax', title: 'Operation Midnight Climax', category: 'Mind Control', relevanceScore: 4 },
      { query: 'cia lsd experiments', title: 'CIA LSD Experiments', category: 'Technologie', relevanceScore: 5 },
      { query: 'sidney gottlieb', title: 'Sidney Gottlieb - CIA Chemiker', category: 'Geschichte', relevanceScore: 4 },
      { query: 'mk often', title: 'MK-OFTEN', category: 'Mind Control', relevanceScore: 3 },
    ],
    'area 51': [
      { query: 'bob lazar', title: 'Bob Lazar - Area 51 Whistleblower', category: 'UFO', relevanceScore: 5 },
      { query: 'roswell ufo crash', title: 'Roswell UFO Absturz 1947', category: 'UFO', relevanceScore: 5 },
      { query: 's-4 facility', title: 'S-4 Forschungseinrichtung', category: 'UFO', relevanceScore: 4 },
      { query: 'element 115', title: 'Element 115 - Alien Technology', category: 'Technologie', relevanceScore: 4 },
      { query: 'dreamland groom lake', title: 'Dreamland / Groom Lake', category: 'UFO', relevanceScore: 3 },
    ],
    '9/11': [
      { query: 'building 7 wtc', title: 'WTC Building 7 Collapse', category: 'Geschichte', relevanceScore: 5 },
      { query: 'operation northwoods', title: 'Operation Northwoods', category: 'Politik', relevanceScore: 4 },
      { query: 'project for new american century', title: 'Project for the New American Century', category: 'Politik', relevanceScore: 4 },
      { query: 'nano thermite wtc', title: 'Nano-Thermit Spuren', category: 'Technologie', relevanceScore: 3 },
      { query: 'pentagon strike', title: 'Pentagon Angriff', category: 'Geschichte', relevanceScore: 4 },
    ],
    'illuminati': [
      { query: 'skull and bones', title: 'Skull and Bones Geheimbund', category: 'Geheimgesellschaften', relevanceScore: 5 },
      { query: 'bohemian grove', title: 'Bohemian Grove', category: 'Geheimgesellschaften', relevanceScore: 4 },
      { query: 'bilderberg group', title: 'Bilderberg-Gruppe', category: 'Politik', relevanceScore: 5 },
      { query: 'freemasons', title: 'Freimaurer', category: 'Geheimgesellschaften', relevanceScore: 4 },
      { query: 'council on foreign relations', title: 'Council on Foreign Relations', category: 'Politik', relevanceScore: 3 },
    ],
    'jfk': [
      { query: 'lee harvey oswald', title: 'Lee Harvey Oswald', category: 'Geschichte', relevanceScore: 5 },
      { query: 'grassy knoll shooter', title: 'Grassy Knoll zweiter Schütze', category: 'Geschichte', relevanceScore: 4 },
      { query: 'jack ruby', title: 'Jack Ruby', category: 'Geschichte', relevanceScore: 4 },
      { query: 'cia jfk conspiracy', title: 'CIA-JFK Verschwörung', category: 'Politik', relevanceScore: 5 },
      { query: 'zapruder film', title: 'Zapruder Film', category: 'Geschichte', relevanceScore: 3 },
    ],
  };
  
  // Finde verwandte Themen
  for (const [key, relatedTopics] of Object.entries(relatedMap)) {
    if (queryLower.includes(key)) {
      return relatedTopics;
    }
  }
  
  // Fallback: Narrative-basierte Vorschläge
  if (narrative && narrative.relatedNarratives) {
    narrative.relatedNarratives.forEach(id => {
      const related = NARRATIVE_DB[id];
      if (related) {
        topics.push({
          query: related.title.toLowerCase(),
          title: related.title,
          category: related.categories[0] || 'Allgemein',
          relevanceScore: 3,
        });
      }
    });
  }
  
  return topics.slice(0, 5); // Max 5 Vorschläge
}

/**
 * Timeline aus Text extrahieren
 */
function extractTimeline(text, query) {
  const events = [];
  const queryLower = query.toLowerCase();
  
  // Vordefinierte Timeline-Daten für bekannte Themen
  const timelineData = {
    'mk ultra': [
      {
        date: '1953-04-13',
        title: 'Start des MK-ULTRA Programms',
        description: 'CIA-Direktor Allen Dulles genehmigt das MK-ULTRA Programm zur Erforschung von Mind Control.',
        importance: 3,
        category: 'Mind Control',
        sources: ['CIA', 'Senate Hearing 1977']
      },
      {
        date: '1973-01-01',
        title: 'Vernichtung der MK-ULTRA Akten',
        description: 'CIA-Direktor Richard Helms ordnet die Vernichtung aller MK-ULTRA Dokumente an.',
        importance: 3,
        category: 'Mind Control',
        sources: ['CIA Inspector General']
      },
      {
        date: '1977-08-03',
        title: 'Senate Hearing deckt MK-ULTRA auf',
        description: 'US-Senat hält öffentliche Anhörung über illegale CIA-Experimente. Überlebende Dokumente werden freigegeben.',
        importance: 3,
        category: 'Mind Control',
        sources: ['U.S. Senate', 'Church Committee']
      },
    ],
    'area 51': [
      {
        date: '1955-07-01',
        title: 'Gründung von Area 51',
        description: 'CIA und Air Force gründen geheime Testanlage in Nevada-Wüste für U-2 Spionageflugzeug.',
        importance: 3,
        category: 'UFO',
        sources: ['CIA FOIA']
      },
      {
        date: '1989-11-01',
        title: 'Bob Lazar geht an die Öffentlichkeit',
        description: 'Bob Lazar berichtet über außerirdische Technologie in S-4 Facility bei Area 51.',
        importance: 3,
        category: 'UFO',
        sources: ['KLAS-TV Las Vegas']
      },
      {
        date: '2013-08-15',
        title: 'CIA bestätigt Area 51',
        description: 'CIA gibt offiziell Existenz von Area 51 zu und veröffentlicht freigegebene Dokumente.',
        importance: 2,
        category: 'UFO',
        sources: ['CIA FOIA', 'National Security Archive']
      },
    ],
    '9/11': [
      {
        date: '2001-09-11',
        title: 'Anschläge auf World Trade Center',
        description: 'Terroranschläge in New York und Washington. WTC 1, 2 und 7 stürzen ein.',
        importance: 3,
        category: 'Geschichte',
        sources: ['9/11 Commission Report']
      },
      {
        date: '2004-07-22',
        title: '9/11 Commission Report veröffentlicht',
        description: 'Offizielle Untersuchung zu den Anschlägen wird der Öffentlichkeit präsentiert.',
        importance: 2,
        category: 'Geschichte',
        sources: ['9/11 Commission']
      },
      {
        date: '2008-11-20',
        title: 'NIST WTC 7 Report',
        description: 'National Institute of Standards and Technology veröffentlicht Bericht über WTC 7 Einsturz.',
        importance: 2,
        category: 'Geschichte',
        sources: ['NIST']
      },
    ],
    'illuminati': [
      {
        date: '1776-05-01',
        title: 'Gründung des Illuminatenordens',
        description: 'Adam Weishaupt gründet in Ingolstadt den Geheimbund der Illuminaten.',
        importance: 3,
        category: 'Geheimgesellschaften',
        sources: ['Historische Dokumente']
      },
      {
        date: '1785-06-22',
        title: 'Verbot der Illuminaten',
        description: 'Kurfürst Karl Theodor verbietet alle Geheimgesellschaften in Bayern.',
        importance: 2,
        category: 'Geheimgesellschaften',
        sources: ['Bayerische Staatsarchive']
      },
      {
        date: '2003-05-15',
        title: 'Dan Browns "Illuminati" erscheint',
        description: 'Bestseller-Roman bringt Illuminaten-Mythos ins moderne Bewusstsein.',
        importance: 1,
        category: 'Geheimgesellschaften',
        sources: ['Publishing Records']
      },
    ],
    'jfk': [
      {
        date: '1963-11-22',
        title: 'JFK Ermordung in Dallas',
        description: 'Präsident John F. Kennedy wird in Dallas erschossen. Lee Harvey Oswald als Einzeltäter verhaftet.',
        importance: 3,
        category: 'Geschichte',
        sources: ['Warren Commission']
      },
      {
        date: '1964-09-27',
        title: 'Warren Commission Report',
        description: 'Offizielle Untersuchung kommt zu dem Schluss: Lee Harvey Oswald handelte allein.',
        importance: 2,
        category: 'Geschichte',
        sources: ['Warren Commission']
      },
      {
        date: '2017-10-26',
        title: 'Trump gibt JFK-Akten frei',
        description: 'Präsident Trump gibt Tausende bisher geheime JFK-Dokumente frei.',
        importance: 2,
        category: 'Geschichte',
        sources: ['National Archives']
      },
    ],
  };
  
  // Finde passende Timeline
  for (const [key, timeline] of Object.entries(timelineData)) {
    if (queryLower.includes(key)) {
      return timeline;
    }
  }
  
  // Fallback: Generische Timeline-Hinweise
  return [
    {
      date: new Date().toISOString().split('T')[0],
      title: `Recherche zu: ${query}`,
      description: 'Für eine detaillierte Timeline sind weitere Informationen erforderlich. Versuche eine spezifischere Suche.',
      importance: 1,
      category: 'Allgemein',
      sources: []
    }
  ];
}

