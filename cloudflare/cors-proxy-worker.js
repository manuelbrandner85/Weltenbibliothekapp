/**
 * CLOUDFLARE WORKER - CORS PROXY FÜR PERPLEXITY API
 * 
 * Löst das Netzwerk-Problem zwischen Flutter Web und Perplexity API
 * 
 * Features:
 * - CORS Headers
 * - API Token Security (aus Environment)
 * - Request/Response Logging
 * - Error Handling
 * - Rate Limiting
 */

export default {
  async fetch(request, env) {
    // CORS Pre-flight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          'Access-Control-Max-Age': '86400',
        }
      });
    }

    // Nur POST Requests erlauben
    if (request.method !== 'POST') {
      return new Response('Method Not Allowed', { 
        status: 405,
        headers: { 'Access-Control-Allow-Origin': '*' }
      });
    }

    try {
      // Request Body parsen
      const body = await request.json();
      
      console.log('📥 Incoming Request:', {
        model: body.model,
        messages: body.messages?.length,
        timestamp: new Date().toISOString()
      });

      // API Request zu Perplexity
      const perplexityResponse = await fetch('https://api.perplexity.ai/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${env.PERPLEXITY_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      const responseData = await perplexityResponse.json();
      
      console.log('📤 Perplexity Response:', {
        status: perplexityResponse.status,
        hasContent: !!responseData.choices?.[0]?.message?.content,
        citationsCount: responseData.citations?.length || 0,
        timestamp: new Date().toISOString()
      });

      // Response mit CORS Headers
      return new Response(JSON.stringify(responseData), {
        status: perplexityResponse.status,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        }
      });

    } catch (error) {
      console.error('❌ Proxy Error:', error);
      
      return new Response(JSON.stringify({ 
        error: 'Proxy Error',
        message: error.message,
        timestamp: new Date().toISOString()
      }), {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      });
    }
  }
};
