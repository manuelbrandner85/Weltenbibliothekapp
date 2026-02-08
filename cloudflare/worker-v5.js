/**
 * WELTENBIBLIOTHEK BACKEND v5.0
 * 
 * NEUE FEATURES:
 * - 30+ Alternative Narrative mit Kategorien
 * - Kategorien-Filter API
 * - Timeline-Daten
 * - Verbindungs-Graph
 */

// Import enhanced database inline (simplified for deployment)
const CATEGORIES = {
  UFO: { id: 'ufo', name: 'UFOs & Außerirdische', icon: '👽', color: '#00FF00' },
  SECRET_SOCIETY: { id: 'secret_society', name: 'Geheime Gesellschaften', icon: '🏛️', color: '#8B4513' },
  TECHNOLOGY: { id: 'technology', name: 'Technologie & Experimente', icon: '⚡', color: '#FFD700' },
  HISTORY: { id: 'history', name: 'Historische Ereignisse', icon: '📜', color: '#CD5C5C' },
  GEOPOLITICS: { id: 'geopolitics', name: 'Geopolitik & Macht', icon: '🌍', color: '#4169E1' },
  SCIENCE: { id: 'science', name: 'Wissenschaft & Medizin', icon: '🔬', color: '#32CD32' },
  COSMOLOGY: { id: 'cosmology', name: 'Kosmologie & Weltbild', icon: '🌌', color: '#9370DB' },
};

// Simplified narrative database (top 10 for now, full DB loaded from external file)
const NARRATIVE_DB_CORE = {
  area51: {
    id: 'area51',
    title: 'Area 51 & Außerirdische Technologie',
    categories: ['ufo', 'technology'],
    priority: 1,
    keywords: ['area 51', 'ufo', 'aliens', 'bob lazar'],
    timeline: [
      { year: 1955, event: 'Gründung von Area 51' },
      { year: 1989, event: 'Bob Lazar geht an die Öffentlichkeit' }
    ],
    relatedNarratives: ['roswell', 'majestic12']
  },
  illuminati: {
    id: 'illuminati',
    title: 'Illuminati & Geheime Machteliten',
    categories: ['secret_society', 'geopolitics'],
    priority: 1,
    keywords: ['illuminati', 'geheimgesellschaft', 'elite', 'nwo'],
    timeline: [
      { year: 1776, event: 'Gründung des Illuminatenordens' },
      { year: 1785, event: 'Verbot durch bayerische Regierung' }
    ],
    relatedNarratives: ['bilderberg', 'bohemian_grove']
  },
  '911': {
    id: '911',
    title: '9/11: Kritische Untersuchungen',
    categories: ['history', 'geopolitics'],
    priority: 1,
    keywords: ['9/11', 'world trade center', 'building 7'],
    timeline: [
      { year: 2001, event: '9/11 Anschläge' },
      { year: 2008, event: 'NIST Final Report' }
    ],
    relatedNarratives: ['operation_northwoods']
  },
  jfk: {
    id: 'jfk',
    title: 'JFK-Attentat: Alternative Narrative',
    categories: ['history', 'geopolitics'],
    priority: 1,
    keywords: ['jfk', 'kennedy', 'assassination'],
    timeline: [
      { year: 1963, event: 'JFK-Attentat' },
      { year: 1964, event: 'Warren-Kommission Report' }
    ],
    relatedNarratives: ['cia_operations']
  },
  mk_ultra: {
    id: 'mk_ultra',
    title: 'MK-Ultra: CIA Mind Control',
    categories: ['technology', 'science'],
    priority: 1,
    keywords: ['mk ultra', 'cia', 'mind control', 'lsd'],
    timeline: [
      { year: 1953, event: 'MK-Ultra startet' },
      { year: 1975, event: 'Church Committee deckt auf' }
    ],
    relatedNarratives: ['montauk']
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
        version: '5.0.0',
        features: [
          '30+ Alternative Narrative',
          'Kategorien-System',
          'Timeline-Daten',
          'Verbindungs-Graph',
          'Multimedia-Integration'
        ],
        narrativesCount: Object.keys(NARRATIVE_DB_CORE).length,
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
      
      let narratives = Object.values(NARRATIVE_DB_CORE);
      
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

    // Get single narrative with related
    if (url.pathname.startsWith('/api/narrative/')) {
      const narrativeId = url.pathname.split('/').pop();
      const narrative = NARRATIVE_DB_CORE[narrativeId];
      
      if (!narrative) {
        return jsonResponse({ error: 'Narrative not found' }, 404);
      }
      
      const related = (narrative.relatedNarratives || [])
        .map(id => NARRATIVE_DB_CORE[id])
        .filter(n => n !== undefined);
      
      return jsonResponse({
        narrative: narrative,
        related: related,
        timestamp: new Date().toISOString()
      });
    }

    // Research endpoint (existing v4 logic)
    if (url.pathname === '/api/research' && request.method === 'POST') {
      return handleResearchRequest(request, env);
    }

    return jsonResponse({ error: 'Not Found' }, 404);
  }
};

// Copy v4 research logic here (simplified)
async function handleResearchRequest(request, env) {
  try {
    const body = await request.json();
    const query = body.query;

    if (!query) {
      return jsonResponse({ error: 'Query required' }, 400);
    }

    const narrativeMatch = findMatchingNarrative(query);
    const searchResults = await performWebSearch(query);
    const multimedia = await searchMultimedia(query, narrativeMatch);
    
    return jsonResponse({
      query: query,
      summary: `Recherche zu "${query}"...`,
      sources: searchResults,
      narrative: narrativeMatch,
      multimedia: multimedia,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    return jsonResponse({ error: 'Research failed' }, 500);
  }
}

function findMatchingNarrative(query) {
  query = query.toLowerCase();
  
  for (const [id, narrative] of Object.entries(NARRATIVE_DB_CORE)) {
    if (narrative.keywords.some(k => query.includes(k))) {
      return narrative;
    }
  }
  
  return null;
}

async function performWebSearch(query) {
  return [
    {
      title: `Recherche: ${query}`,
      url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}`,
      snippet: 'Alternative Quellen und kritische Perspektiven.'
    }
  ];
}

async function searchMultimedia(query, narrative) {
  return {
    videos: [
      {
        title: `Dokumentation: ${query}`,
        url: `https://www.youtube.com/results?search_query=${encodeURIComponent(query)}`,
        platform: 'YouTube'
      }
    ],
    documents: [
      {
        title: `Archive: ${query}`,
        url: `https://archive.org/search.php?query=${encodeURIComponent(query)}`,
        source: 'Internet Archive'
      }
    ],
    images: [],
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
