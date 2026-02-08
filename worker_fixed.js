// ============================================================================
// WELTENBIBLIOTHEK - MAIN API WORKER (FIXED & PRODUCTION READY)
// ============================================================================
// Version: 2.0 (Production)
// Features:
// - Health endpoint (/health, /api/health)
// - Default route (no 404)
// - Knowledge API (/api/knowledge/*)
// - Community API (/api/community/*)
// - D1 Database support
// - Proper error handling
// - CORS configured
// ============================================================================

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS Headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
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
          service: 'Weltenbibliothek API',
          version: '2.0',
          status: 'online',
          endpoints: {
            health: '/health or /api/health',
            knowledge: '/api/knowledge/*',
            community: '/api/community/*',
            articles: '/api/articles/*',
            documentation: 'https://weltenbibliothek-ey9.pages.dev'
          },
          database: env.DB ? 'connected' : 'not_configured',
          message: 'API is running. Use documented endpoints.'
        }), { 
          status: 200,
          headers: corsHeaders 
        });
      }

      // ====================================================================
      // HEALTH ENDPOINTS
      // ====================================================================
      if (path === '/health' || path === '/api/health') {
        // Test database connection
        let dbStatus = 'not_configured';
        let dbError = null;
        
        if (env.DB) {
          try {
            // Simple query to test connection
            await env.DB.prepare('SELECT 1').first();
            dbStatus = 'connected';
          } catch (e) {
            dbStatus = 'error';
            dbError = e.message;
          }
        }

        return new Response(JSON.stringify({
          status: 'healthy',
          version: '2.0',
          timestamp: new Date().toISOString(),
          services: {
            api: 'online',
            database: dbStatus,
            cors: 'enabled'
          },
          database_error: dbError,
          uptime: 'continuous'
        }), { 
          status: 200,
          headers: corsHeaders 
        });
      }

      // ====================================================================
      // KNOWLEDGE API
      // ====================================================================
      if (path.startsWith('/api/knowledge')) {
        // GET /api/knowledge - List all knowledge entries
        if (path === '/api/knowledge' && method === 'GET') {
          if (!env.DB) {
            return new Response(JSON.stringify({
              error: 'Database not configured',
              entries: []
            }), { status: 503, headers: corsHeaders });
          }

          try {
            const limit = parseInt(url.searchParams.get('limit') || '100');
            const offset = parseInt(url.searchParams.get('offset') || '0');
            const realm = url.searchParams.get('realm'); // materie or energie

            let query = 'SELECT * FROM knowledge_entries';
            const params = [];

            if (realm) {
              query += ' WHERE realm = ?';
              params.push(realm);
            }

            query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
            params.push(limit, offset);

            const result = await env.DB.prepare(query).bind(...params).all();

            return new Response(JSON.stringify({
              success: true,
              count: result.results.length,
              entries: result.results
            }), { 
              status: 200,
              headers: corsHeaders 
            });
          } catch (e) {
            return new Response(JSON.stringify({
              error: 'Database query failed',
              message: e.message,
              entries: []
            }), { status: 500, headers: corsHeaders });
          }
        }

        // GET /api/knowledge/:id - Get specific entry
        const knowledgeIdMatch = path.match(/^\/api\/knowledge\/([a-zA-Z0-9_-]+)$/);
        if (knowledgeIdMatch && method === 'GET') {
          const id = knowledgeIdMatch[1];

          if (!env.DB) {
            return new Response(JSON.stringify({
              error: 'Database not configured'
            }), { status: 503, headers: corsHeaders });
          }

          try {
            const entry = await env.DB.prepare(
              'SELECT * FROM knowledge_entries WHERE id = ?'
            ).bind(id).first();

            if (!entry) {
              return new Response(JSON.stringify({
                error: 'Entry not found',
                id: id
              }), { status: 404, headers: corsHeaders });
            }

            return new Response(JSON.stringify({
              success: true,
              entry: entry
            }), { 
              status: 200,
              headers: corsHeaders 
            });
          } catch (e) {
            return new Response(JSON.stringify({
              error: 'Database query failed',
              message: e.message
            }), { status: 500, headers: corsHeaders });
          }
        }
      }

      // ====================================================================
      // COMMUNITY API (Placeholder - implement as needed)
      // ====================================================================
      if (path.startsWith('/api/community')) {
        return new Response(JSON.stringify({
          message: 'Community API endpoint',
          status: 'not_implemented',
          note: 'This endpoint will be implemented based on requirements'
        }), { status: 501, headers: corsHeaders });
      }

      // ====================================================================
      // ARTICLES API (Placeholder)
      // ====================================================================
      if (path.startsWith('/api/articles')) {
        return new Response(JSON.stringify({
          message: 'Articles API endpoint',
          status: 'not_implemented',
          note: 'This endpoint will be implemented based on requirements'
        }), { status: 501, headers: corsHeaders });
      }

      // ====================================================================
      // 404 - ROUTE NOT FOUND (but with helpful message)
      // ====================================================================
      return new Response(JSON.stringify({
        error: 'Route not found',
        path: path,
        method: method,
        available_endpoints: {
          root: '/',
          health: '/health or /api/health',
          knowledge: '/api/knowledge',
          knowledge_by_id: '/api/knowledge/:id',
          community: '/api/community (not implemented)',
          articles: '/api/articles (not implemented)'
        },
        documentation: 'https://weltenbibliothek-ey9.pages.dev',
        suggestion: 'Check the available endpoints above'
      }), { 
        status: 404,
        headers: corsHeaders 
      });

    } catch (error) {
      // Global error handler
      return new Response(JSON.stringify({
        error: 'Internal server error',
        message: error.message,
        stack: error.stack,
        path: path,
        method: method
      }), { 
        status: 500,
        headers: corsHeaders 
      });
    }
  }
};
