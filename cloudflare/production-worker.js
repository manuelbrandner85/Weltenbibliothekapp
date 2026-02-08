/**
 * PRODUCTION BACKEND WORKER - Weltenbibliothek Research API
 * 
 * Deployment URL: https://api-backend.weltenbibliothek.workers.dev
 * 
 * Features:
 * - ✅ CORS Support für Flutter Web
 * - ✅ Perplexity API Integration
 * - ✅ API Token Security (Environment Variable)
 * - ✅ Rate Limiting (100 req/min per IP)
 * - ✅ Request/Response Logging
 * - ✅ Error Handling mit Details
 * - ✅ Alternative Quellen Priorisierung
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // CORS Pre-flight
    if (request.method === 'OPTIONS') {
      return corsResponse();
    }

    // Health Check Endpoint
    if (url.pathname === '/health') {
      return jsonResponse({ 
        status: 'ok', 
        service: 'Weltenbibliothek Research API',
        version: '1.0.0',
        timestamp: new Date().toISOString()
      });
    }

    // Research Endpoint
    if (url.pathname === '/api/research' && request.method === 'POST') {
      return handleResearchRequest(request, env);
    }

    // 404 für alle anderen Routes
    return jsonResponse({ error: 'Not Found' }, 404);
  }
};

/**
 * Handle Research Request
 */
async function handleResearchRequest(request, env) {
  try {
    // Parse Request Body
    const body = await request.json();
    const query = body.query;

    if (!query || query.trim().length === 0) {
      return jsonResponse({ 
        error: 'Query is required',
        message: 'Bitte gib eine Suchanfrage ein.'
      }, 400);
    }

    console.log('🔍 Research Request:', {
      query: query,
      ip: request.headers.get('CF-Connecting-IP'),
      timestamp: new Date().toISOString()
    });

    // Rate Limiting Check
    const rateLimitResult = await checkRateLimit(request, env);
    if (!rateLimitResult.allowed) {
      return jsonResponse({
        error: 'Rate Limit Exceeded',
        message: 'Zu viele Anfragen. Bitte warte einen Moment.',
        retryAfter: 60
      }, 429);
    }

    // API Token Check
    if (!env.PERPLEXITY_API_KEY) {
      console.error('❌ PERPLEXITY_API_KEY not configured');
      return jsonResponse({
        error: 'Service Configuration Error',
        message: 'Backend-Service ist nicht korrekt konfiguriert.'
      }, 503);
    }

    // Call Perplexity API
    const perplexityResponse = await fetch('https://api.perplexity.ai/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.PERPLEXITY_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'llama-3.1-sonar-large-128k-online',
        messages: [
          {
            role: 'system',
            content: `Du bist ein investigativer Recherche-Assistent für die Weltenbibliothek.
Fokus auf:
1. Alternative Medien & unabhängige Quellen
2. Mainstream-Quellen zum Vergleich
3. Kritische Perspektiven
4. Verschwörungstheorien & alternative Erklärungen
5. Historischer Kontext

Priorisiere alternative und unabhängige Quellen!`
          },
          {
            role: 'user',
            content: `Recherchiere: ${query}`
          }
        ],
        temperature: 0.2,
        top_p: 0.9,
        return_citations: true,
        return_images: false,
        search_recency_filter: 'month',
      }),
    });

    if (!perplexityResponse.ok) {
      const errorText = await perplexityResponse.text();
      console.error('❌ Perplexity API Error:', {
        status: perplexityResponse.status,
        error: errorText
      });
      
      return jsonResponse({
        error: 'API Error',
        message: 'Externe API ist vorübergehend nicht erreichbar.',
        statusCode: perplexityResponse.status
      }, 503);
    }

    const data = await perplexityResponse.json();
    
    // Parse Response
    const summary = data.choices?.[0]?.message?.content || 'Keine Zusammenfassung verfügbar.';
    const citations = data.citations || [];
    
    const sources = citations.map(url => ({
      title: extractTitle(url),
      url: url,
      snippet: '',
      sourceType: detectSourceType(url)
    }));

    console.log('✅ Research Success:', {
      query: query,
      sourcesCount: sources.length,
      timestamp: new Date().toISOString()
    });

    // Return Response
    return jsonResponse({
      query: query,
      summary: summary,
      sources: sources,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Research Handler Error:', error);
    
    return jsonResponse({
      error: 'Internal Server Error',
      message: error.message || 'Ein unerwarteter Fehler ist aufgetreten.'
    }, 500);
  }
}

/**
 * Rate Limiting - 100 requests per minute per IP
 */
async function checkRateLimit(request, env) {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const key = `rate_limit:${ip}`;
  const now = Date.now();
  const minute = Math.floor(now / 60000);
  const rateLimitKey = `${key}:${minute}`;
  
  // Get current count from KV (wenn verfügbar)
  let count = 0;
  if (env.RATE_LIMIT_KV) {
    const stored = await env.RATE_LIMIT_KV.get(rateLimitKey);
    count = stored ? parseInt(stored) : 0;
  }
  
  if (count >= 100) {
    return { allowed: false, count: count };
  }
  
  // Increment counter
  if (env.RATE_LIMIT_KV) {
    await env.RATE_LIMIT_KV.put(rateLimitKey, (count + 1).toString(), {
      expirationTtl: 120 // 2 Minuten
    });
  }
  
  return { allowed: true, count: count + 1 };
}

/**
 * Detect Source Type
 */
function detectSourceType(url) {
  const alternativeSources = [
    'wikileaks.org', 'theintercept.com', 'propublica.org',
    'bellingcat.com', 'archive.org', 'substack.com',
    'telegram.org', 'odysee.com', 'bitchute.com', 'rumble.com'
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
 * Extract Title from URL
 */
function extractTitle(url) {
  try {
    const urlObj = new URL(url);
    const path = urlObj.pathname.split('/').filter(Boolean).pop() || urlObj.hostname;
    return path.replace(/-/g, ' ').replace(/_/g, ' ');
  } catch {
    return 'Unbekannte Quelle';
  }
}

/**
 * CORS Response Helper
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
      'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    }
  });
}
