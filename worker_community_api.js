export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;
    
    // CORS + Security Headers
    const corsHeaders = {
      // CORS Headers
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Content-Type': 'application/json',
      // Security Headers
      'X-Frame-Options': 'DENY',
      'X-Content-Type-Options': 'nosniff',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
      'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://*.workers.dev",
      'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'X-XSS-Protection': '1; mode=block',
    };

    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    if (path === '/health' || path === '/api/health') {
      return new Response(JSON.stringify({
        status: 'healthy',
        service: 'community-api',
        version: '1.0',
        timestamp: new Date().toISOString()
      }), { status: 200, headers: corsHeaders });
    }

    if (path === '/' || path === '') {
      return new Response(JSON.stringify({
        service: 'Community API',
        version: '1.0',
        status: 'online',
        message: 'Community features placeholder',
        endpoints: { health: '/health' }
      }), { status: 200, headers: corsHeaders });
    }

    return new Response(JSON.stringify({
      error: 'Route not found',
      path: path
    }), { status: 404, headers: corsHeaders });
  }
};
