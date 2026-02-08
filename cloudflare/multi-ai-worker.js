/**
 * PRODUCTION BACKEND WORKER - Weltenbibliothek Research API
 * 
 * Multi-AI Strategy:
 * 1. Cloudflare AI (Workers AI) - PRIMARY
 * 2. HuggingFace API - FALLBACK 1 (Free Tier)
 * 3. Together AI - FALLBACK 2 (Free Tier)
 * 4. Groq - FALLBACK 3 (Free Tier)
 * 
 * Features:
 * - ✅ Keine Perplexity Dependency
 * - ✅ Mehrere kostenlose KI-Dienste
 * - ✅ Automatischer Fallback
 * - ✅ DuckDuckGo für Web-Suche
 * - ✅ CORS Support
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
        service: 'Weltenbibliothek Research API (Multi-AI)',
        version: '2.0.0',
        aiProviders: ['Cloudflare AI', 'HuggingFace', 'Together AI', 'Groq'],
        timestamp: new Date().toISOString()
      });
    }

    // Research Endpoint
    if (url.pathname === '/api/research' && request.method === 'POST') {
      return handleResearchRequest(request, env);
    }

    return jsonResponse({ error: 'Not Found' }, 404);
  }
};

/**
 * Handle Research Request with Multi-AI Strategy
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

    console.log('🔍 Research Request:', { query, timestamp: new Date().toISOString() });

    // STEP 1: Web Search mit DuckDuckGo
    const searchResults = await performWebSearch(query);
    
    // STEP 2: AI Analysis (Multi-Provider mit Fallback)
    const summary = await performAIAnalysis(query, searchResults, env);

    // STEP 3: Response zusammenstellen
    return jsonResponse({
      query: query,
      summary: summary,
      sources: searchResults.map(result => ({
        title: result.title,
        url: result.url,
        snippet: result.snippet,
        sourceType: detectSourceType(result.url)
      })),
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Research Error:', error);
    
    return jsonResponse({
      error: 'Research Failed',
      message: error.message || 'Ein Fehler ist aufgetreten.',
      timestamp: new Date().toISOString()
    }, 500);
  }
}

/**
 * Web Search mit DuckDuckGo (kostenlos, kein API Key)
 */
async function performWebSearch(query) {
  try {
    // DuckDuckGo Instant Answer API
    const response = await fetch(
      `https://api.duckduckgo.com/?q=${encodeURIComponent(query)}&format=json&no_html=1&skip_disambig=1`
    );
    
    const data = await response.json();
    
    // Parse Results
    const results = [];
    
    // Related Topics
    if (data.RelatedTopics && data.RelatedTopics.length > 0) {
      for (const topic of data.RelatedTopics) {
        if (topic.FirstURL && topic.Text) {
          results.push({
            title: topic.Text.split(' - ')[0] || topic.Text,
            url: topic.FirstURL,
            snippet: topic.Text
          });
          
          if (results.length >= 10) break;
        }
      }
    }
    
    // Fallback: Simulierte Recherche-Ergebnisse
    if (results.length === 0) {
      results.push({
        title: `Recherche: ${query}`,
        url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}`,
        snippet: `Suchergebnisse für "${query}" - Alternative Quellen und kritische Perspektiven.`
      });
    }
    
    return results;
    
  } catch (error) {
    console.error('❌ Web Search Error:', error);
    
    // Fallback Ergebnisse
    return [{
      title: `Recherche: ${query}`,
      url: `https://duckduckgo.com/?q=${encodeURIComponent(query)}`,
      snippet: `Suche nach "${query}" - Verwende DuckDuckGo für weitere Ergebnisse.`
    }];
  }
}

/**
 * AI Analysis mit Multi-Provider Fallback
 */
async function performAIAnalysis(query, searchResults, env) {
  const providers = [
    { name: 'Cloudflare AI', handler: analyzeWithCloudflareAI },
    { name: 'HuggingFace', handler: analyzeWithHuggingFace },
    { name: 'Together AI', handler: analyzeWithTogetherAI },
    { name: 'Groq', handler: analyzeWithGroq }
  ];
  
  // Versuche jeden Provider in Reihenfolge
  for (const provider of providers) {
    try {
      console.log(`🤖 Versuche ${provider.name}...`);
      const result = await provider.handler(query, searchResults, env);
      
      if (result && result.length > 50) {
        console.log(`✅ ${provider.name} erfolgreich!`);
        return result;
      }
    } catch (error) {
      console.warn(`⚠️ ${provider.name} fehlgeschlagen:`, error.message);
      continue;
    }
  }
  
  // Fallback: Einfache Zusammenfassung
  return generateFallbackSummary(query, searchResults);
}

/**
 * 1. Cloudflare Workers AI (FREE!)
 */
async function analyzeWithCloudflareAI(query, searchResults, env) {
  if (!env.AI) {
    throw new Error('Cloudflare AI nicht verfügbar');
  }
  
  const context = searchResults.map(r => r.snippet).join('\n\n');
  
  const prompt = `Du bist ein investigativer Recherche-Assistent für die Weltenbibliothek.

Analysiere folgende Recherche-Anfrage: "${query}"

Kontext aus Web-Recherche:
${context}

Erstelle eine kritische, ausgewogene Analyse mit Fokus auf:
- Alternative Perspektiven
- Unabhängige Quellen
- Kritische Betrachtung
- Historischer Kontext

Antwort (max 500 Wörter):`;

  const response = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
    messages: [
      { role: 'system', content: 'Du bist ein kritischer Recherche-Assistent.' },
      { role: 'user', content: prompt }
    ]
  });
  
  return response.response || response.result?.response;
}

/**
 * 2. HuggingFace Inference API (FREE Tier)
 */
async function analyzeWithHuggingFace(query, searchResults, env) {
  const API_KEY = env.HUGGINGFACE_API_KEY || 'hf_anonymous';
  const context = searchResults.map(r => r.snippet).join('\n\n');
  
  const prompt = `Recherche: ${query}\n\nKontext:\n${context}\n\nAnalyse:`;
  
  const response = await fetch(
    'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.2',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        inputs: prompt,
        parameters: {
          max_new_tokens: 500,
          temperature: 0.7,
        }
      })
    }
  );
  
  if (!response.ok) {
    throw new Error(`HuggingFace API Error: ${response.status}`);
  }
  
  const data = await response.json();
  return data[0]?.generated_text?.replace(prompt, '').trim();
}

/**
 * 3. Together AI (FREE Tier)
 */
async function analyzeWithTogetherAI(query, searchResults, env) {
  const API_KEY = env.TOGETHER_API_KEY;
  
  if (!API_KEY) {
    throw new Error('Together AI Key nicht verfügbar');
  }
  
  const context = searchResults.map(r => r.snippet).join('\n\n');
  
  const response = await fetch('https://api.together.xyz/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'mistralai/Mixtral-8x7B-Instruct-v0.1',
      messages: [
        { role: 'system', content: 'Du bist ein kritischer Recherche-Assistent.' },
        { role: 'user', content: `Recherche: ${query}\n\nKontext:\n${context}\n\nAnalyse:` }
      ],
      max_tokens: 500,
      temperature: 0.7,
    })
  });
  
  const data = await response.json();
  return data.choices?.[0]?.message?.content;
}

/**
 * 4. Groq (FREE Tier - sehr schnell!)
 */
async function analyzeWithGroq(query, searchResults, env) {
  const API_KEY = env.GROQ_API_KEY;
  
  if (!API_KEY) {
    throw new Error('Groq Key nicht verfügbar');
  }
  
  const context = searchResults.map(r => r.snippet).join('\n\n');
  
  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'llama-3.1-70b-versatile',
      messages: [
        { role: 'system', content: 'Du bist ein kritischer Recherche-Assistent.' },
        { role: 'user', content: `Recherche: ${query}\n\nKontext:\n${context}\n\nAnalyse:` }
      ],
      max_tokens: 500,
      temperature: 0.7,
    })
  });
  
  const data = await response.json();
  return data.choices?.[0]?.message?.content;
}

/**
 * Fallback: Einfache Zusammenfassung ohne KI
 */
function generateFallbackSummary(query, searchResults) {
  const sources = searchResults.length;
  const snippets = searchResults.map(r => `• ${r.snippet}`).join('\n');
  
  return `🔍 Recherche zu: "${query}"

Gefundene Quellen: ${sources}

Zusammenfassung der Ergebnisse:
${snippets}

💡 Hinweis: Diese Zusammenfassung wurde ohne KI-Analyse erstellt. 
Für eine detaillierte Analyse mit alternativen Perspektiven und kritischer Betrachtung, 
kontaktiere bitte den Administrator.`;
}

/**
 * Source Type Detection
 */
function detectSourceType(url) {
  const alternativeSources = [
    'wikileaks', 'theintercept', 'propublica', 'bellingcat',
    'archive.org', 'substack', 'telegram', 'odysee', 'rumble'
  ];
  
  const mainstreamSources = [
    'cnn.com', 'bbc.com', 'nytimes.com', 'washingtonpost.com',
    'reuters.com', 'apnews.com', 'foxnews.com'
  ];
  
  const domain = new URL(url).hostname.toLowerCase();
  
  if (alternativeSources.some(s => domain.includes(s))) {
    return 'alternative';
  } else if (mainstreamSources.some(s => domain.includes(s))) {
    return 'mainstream';
  } else {
    return 'independent';
  }
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
