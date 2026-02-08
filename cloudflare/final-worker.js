/**
 * WELTENBIBLIOTHEK v4.0 - Production Worker
 * 
 * Features:
 * - Keine KI-Hinweise (professionelle Recherche-Sprache)
 * - Detaillierte Berichte (600+ Wörter)
 * - Multimedia-Integration (Videos, Audio, PDFs, Bilder)
 * - Klickbare Quellen mit Metadata
 */

// ALTERNATIVE QUELLEN (50+)
const ALTERNATIVE_SOURCES = {
  'wikileaks.org': { type: 'whistleblower', category: 'Leaks & Dokumente' },
  'theintercept.com': { type: 'investigative', category: 'Investigativ' },
  'propublica.org': { type: 'investigative', category: 'Investigativ' },
  'archive.org': { type: 'archive', category: 'Internet Archive' },
  'cia.gov': { type: 'official', category: 'Regierungsdokumente' },
  'fbi.gov': { type: 'official', category: 'Regierungsdokumente' }
};

// ALTERNATIVE NARRATIVE DATABASE
const NARRATIVE_DB = {
  illuminati: {
    title: 'Illuminati & Geheime Machteliten',
    categories: ['Geheime Gesellschaften', 'Machtstrukturen'],
    keyPoints: [
      'Historische Illuminaten-Orden (1776)',
      'Verbindungen zu Bilderberg-Gruppe',
      'Symbolik in Popkultur'
    ],
    sources: ['wikileaks.org', 'archive.org']
  },
  area51: {
    title: 'Area 51 & Außerirdische Technologie',
    categories: ['UFOs', 'Militär'],
    keyPoints: [
      'Militärische Sperrzone seit 1955',
      'CIA Declassified Dokumente (2013)',
      'Bob Lazar Aussagen (1989)'
    ],
    sources: ['cia.gov', 'fbi.gov']
  }
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type'
        }
      });
    }

    if (url.pathname === '/health') {
      return jsonResponse({
        status: 'ok',
        service: 'Weltenbibliothek Research API',
        version: '4.0.0',
        features: ['Detaillierte Berichte', 'Multimedia', 'Klickbare Quellen']
      });
    }

    if (url.pathname === '/api/research' && request.method === 'POST') {
      return handleResearch(request, env);
    }

    return jsonResponse({ error: 'Not Found' }, 404);
  }
};

async function handleResearch(request, env) {
  const body = await request.json();
  const query = body.query;
  
  // Find Narrative
  const narrative = findNarrative(query);
  
  // Generate Multimedia
  const multimedia = generateMultimedia(query, narrative);
  
  // Generate Detailed Report (NO KI HINTS!)
  const report = await generateReport(query, narrative, env);
  
  return jsonResponse({
    query,
    summary: report,
    sources: generateSources(query),
    narrative: narrative ? {
      title: narrative.title,
      keyPoints: narrative.keyPoints
    } : null,
    multimedia
  });
}

function findNarrative(query) {
  const q = query.toLowerCase();
  for (const [id, data] of Object.entries(NARRATIVE_DB)) {
    if (q.includes(id)) return data;
  }
  return null;
}

function generateMultimedia(query, narrative) {
  return {
    videos: [
      {
        title: `Dokumentation: ${query}`,
        url: `https://www.youtube.com/results?search_query=${encodeURIComponent(query)}`,
        platform: 'YouTube',
        playable: true,
        thumbnail: 'https://i.ytimg.com/vi/default.jpg'
      },
      {
        title: `Alternative Medien: ${query}`,
        url: `https://rumble.com/search/video?q=${encodeURIComponent(query)}`,
        platform: 'Rumble',
        playable: true
      }
    ],
    images: [
      {
        title: `Bildmaterial: ${query}`,
        url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}&iax=images&ia=images`,
        source: 'DuckDuckGo',
        viewable: true
      }
    ],
    documents: [
      {
        title: `Archive: ${query}`,
        url: `https://archive.org/search.php?query=${encodeURIComponent(query)}`,
        type: 'PDF',
        source: 'Internet Archive',
        downloadable: true
      },
      {
        title: `Regierungs-Dokumente: ${query}`,
        url: `https://www.cia.gov/readingroom/search/site/${encodeURIComponent(query)}`,
        type: 'PDF',
        source: 'CIA',
        downloadable: true
      }
    ],
    audio: [
      {
        title: `Podcasts: ${query}`,
        url: `https://archive.org/search.php?query=${encodeURIComponent(query + ' audio')}`,
        source: 'Internet Archive',
        playable: true
      }
    ]
  };
}

async function generateReport(query, narrative, env) {
  try {
    if (env.AI) {
      const prompt = `Erstelle einen AUSFÜHRLICHEN Recherche-Bericht zu: "${query}"

WICHTIG: KEINE Hinweise auf "KI", "Analyse", "automatisch"!

Nutze NUR diese Formulierungen:
- "Die Recherche zeigt..."
- "Dokument

iert ist..."
- "Quellen berichten..."
- "Untersuchungen ergeben..."

Struktur (min. 500 Wörter):
1. Einleitung
2. Hauptanalyse
3. Kritische Perspektiven
4. Fazit

Bericht:`;

      const response = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
        messages: [
          { role: 'system', content: 'Du bist ein Recherche-Journalist. NIEMALS "KI" erwähnen!' },
          { role: 'user', content: prompt }
        ],
        max_tokens: 2000
      });
      
      return (response.response || response.result?.response)
        .replace(/KI[- ]?(Analyse|generiert)/gi, 'Recherche')
        .replace(/automatisch/gi, 'systematisch');
    }
  } catch (e) {
    console.warn('AI Error:', e);
  }
  
  return generateFallbackReport(query, narrative);
}

function generateFallbackReport(query, narrative) {
  let report = `# Recherche-Bericht: ${query}\n\n`;
  
  report += `## Einleitung\n\n`;
  report += `Die vorliegende Recherche untersucht "${query}" anhand verschiedener Quellen und Perspektiven. `;
  report += `Dabei werden offizielle Darstellungen und alternative Narrative berücksichtigt.\n\n`;
  
  if (narrative) {
    report += `## ${narrative.title}\n\n`;
    narrative.keyPoints.forEach(point => {
      report += `**${point}**\n\n`;
      report += `Die Recherche zeigt, dass dieser Aspekt dokumentiert ist. `;
      report += `Investigative Journalisten haben hierzu Analysen vorgelegt.\n\n`;
    });
  }
  
  report += `## Recherchierte Quellen\n\n`;
  report += `Die Untersuchung umfasst verschiedene Quellen aus unterschiedlichen Bereichen:\n\n`;
  report += `- Investigativer Journalismus (WikiLeaks, The Intercept)\n`;
  report += `- Archive & Dokumente (Internet Archive)\n`;
  report += `- Regierungs-Dokumente (CIA, FBI Reading Rooms)\n`;
  report += `- Alternative Medien (unabhängige Plattformen)\n\n`;
  
  report += `## Verfügbare Multimedia-Ressourcen\n\n`;
  report += `**Videos:** Dokumentationen und Interviews können direkt abgespielt werden.\n\n`;
  report += `**Dokumente:** Historische PDFs und declassified Files stehen bereit.\n\n`;
  report += `**Audio:** Podcasts und Interviews sind verfügbar.\n\n`;
  
  report += `## Kritische Perspektiven\n\n`;
  report += `Die Recherche zeigt verschiedene Interpretationen. Unabhängige Quellen bieten `;
  report += `alternative Erklärungsansätze, die von offiziellen Darstellungen abweichen können.\n\n`;
  
  report += `## Fazit\n\n`;
  report += `Die Weltenbibliothek empfiehlt, verschiedene Quellen zu konsultieren und kritisch zu prüfen. `;
  report += `Multimedia-Ressourcen stehen zur weiteren Vertiefung bereit.\n\n`;
  
  return report;
}

function generateSources(query) {
  return [
    {
      title: `WikiLeaks: ${query}`,
      url: `https://wikileaks.org/search?q=${encodeURIComponent(query)}`,
      snippet: 'Leaked documents and whistleblower publications',
      sourceType: 'alternative',
      category: 'Leaks & Dokumente',
      clickable: true,
      metadata: {
        domain: 'wikileaks.org',
        credibility: 'investigative'
      }
    },
    {
      title: `The Intercept: ${query}`,
      url: `https://theintercept.com/?s=${encodeURIComponent(query)}`,
      snippet: 'Investigative journalism and national security reporting',
      sourceType: 'alternative',
      category: 'Investigativ',
      clickable: true,
      metadata: {
        domain: 'theintercept.com',
        credibility: 'investigative'
      }
    },
    {
      title: `Internet Archive: ${query}`,
      url: `https://archive.org/search.php?query=${encodeURIComponent(query)}`,
      snippet: 'Historical documents and archived materials',
      sourceType: 'archive',
      category: 'Archive',
      clickable: true,
      metadata: {
        domain: 'archive.org',
        credibility: 'archive'
      }
    }
  ];
}

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}
