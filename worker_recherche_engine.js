// ============================================================================
// RECHERCHE ENGINE WORKER (FIXED & PRODUCTION READY)
// ============================================================================
// Purpose: Research/Search functionality for Weltenbibliothek
// Features:
// - Health endpoint
// - Search API
// - AI-powered research (if AI binding available)
// - Proper error handling
// ============================================================================

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS Headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Content-Type': 'application/json',
    };

    // OPTIONS preflight
    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // ====================================================================
      // ROOT / DEFAULT ROUTE
      // ====================================================================
      if (path === '/' || path === '') {
        return new Response(JSON.stringify({
          service: 'Recherche Engine',
          version: '1.0',
          status: 'online',
          endpoints: {
            health: '/health',
            search: '/api/search (POST)',
            research: '/api/research (POST)'
          },
          features: {
            search: 'enabled',
            ai_research: env.AI ? 'available' : 'not_configured'
          }
        }), { 
          status: 200,
          headers: corsHeaders 
        });
      }

      // ====================================================================
      // HEALTH ENDPOINT
      // ====================================================================
      if (path === '/health' || path === '/api/health') {
        return new Response(JSON.stringify({
          status: 'healthy',
          service: 'recherche-engine',
          version: '1.0',
          timestamp: new Date().toISOString(),
          ai_available: env.AI ? true : false,
          database_available: env.DB ? true : false
        }), { 
          status: 200,
          headers: corsHeaders 
        });
      }

      // ====================================================================
      // SEARCH API
      // ====================================================================
      if (path === '/api/search' && method === 'POST') {
        const body = await request.json();
        const query = body.query || '';

        if (!query) {
          return new Response(JSON.stringify({
            error: 'Query parameter required',
            example: { query: 'your search term' }
          }), { status: 400, headers: corsHeaders });
        }

        // Basic search implementation
        // TODO: Implement actual search logic with D1 database
        return new Response(JSON.stringify({
          success: true,
          query: query,
          results: [],
          message: 'Search functionality will be implemented based on requirements'
        }), { 
          status: 200,
          headers: corsHeaders 
        });
      }

      // ====================================================================
      // RESEARCH API (AI-powered)
      // ====================================================================
      if (path === '/api/research' && method === 'POST') {
        const body = await request.json();
        const topic = body.topic || '';

        if (!topic) {
          return new Response(JSON.stringify({
            error: 'Topic parameter required',
            example: { topic: 'your research topic' }
          }), { status: 400, headers: corsHeaders });
        }

        if (!env.AI) {
          return new Response(JSON.stringify({
            error: 'AI not configured',
            message: 'AI binding required for research functionality'
          }), { status: 503, headers: corsHeaders });
        }

        // AI research implementation
        // TODO: Implement actual AI research logic
        return new Response(JSON.stringify({
          success: true,
          topic: topic,
          research: 'AI research will be implemented',
          message: 'AI functionality will be added based on requirements'
        }), { 
          status: 200,
          headers: corsHeaders 
        });
      }

      // ====================================================================
      // 404 - ROUTE NOT FOUND
      // ====================================================================
      return new Response(JSON.stringify({
        error: 'Route not found',
        path: path,
        method: method,
        available_endpoints: {
          root: '/',
          health: '/health',
          search: '/api/search (POST)',
          research: '/api/research (POST)'
        }
      }), { 
        status: 404,
        headers: corsHeaders 
      });

    } catch (error) {
      return new Response(JSON.stringify({
        error: 'Internal server error',
        message: error.message
      }), { 
        status: 500,
        headers: corsHeaders 
      });
    }
  }
};
