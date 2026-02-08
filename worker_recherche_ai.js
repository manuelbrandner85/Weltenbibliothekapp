// ============================================================================
// RECHERCHE ENGINE V2.0 - WITH CLOUDFLARE AI
// ============================================================================
// AI-powered research and semantic search for Weltenbibliothek
// Features:
// - Cloudflare AI (Llama-2, Mistral, etc.)
// - Vectorize for semantic search
// - Embeddings generation
// - D1 Database integration
// - Knowledge base search
// ============================================================================

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
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Content-Type': 'application/json',
      // Security Headers
      'X-Frame-Options': 'DENY',
      'X-Content-Type-Options': 'nosniff',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
      'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://*.workers.dev https://*.pages.dev",
      'Permissions-Policy': 'geolocation=(), microphone=(), camera=(), payment=(), usb=()',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'X-XSS-Protection': '1; mode=block',
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
          version: '2.0 (AI Edition)',
          status: 'online',
          endpoints: {
            health: '/health',
            search: '/api/search (POST) - Semantic search with embeddings',
            research: '/api/research (POST) - AI-powered research',
            generate: '/api/generate (POST) - AI text generation',
            embeddings: '/api/embeddings (POST) - Generate embeddings'
          },
          ai_models: {
            text_generation: '@cf/meta/llama-2-7b-chat-int8',
            embeddings: '@cf/baai/bge-base-en-v1.5',
            translation: '@cf/meta/m2m100-1.2b'
          },
          features: {
            search: 'enabled',
            ai_research: env.AI ? 'available' : 'not_configured',
            vectorize: env.VECTORIZE ? 'available' : 'not_configured',
            database: env.DB ? 'connected' : 'not_connected'
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
          version: '2.0',
          timestamp: new Date().toISOString(),
          ai_available: env.AI ? true : false,
          vectorize_available: env.VECTORIZE ? true : false,
          database_available: env.DB ? true : false,
          capabilities: {
            text_generation: env.AI ? 'ready' : 'unavailable',
            embeddings: env.AI ? 'ready' : 'unavailable',
            semantic_search: (env.AI && env.VECTORIZE) ? 'ready' : 'partial'
          }
        }), { 
          status: 200,
          headers: corsHeaders 
        });
      }

      // ====================================================================
      // AI TEXT GENERATION
      // ====================================================================
      if (path === '/api/generate' && method === 'POST') {
        if (!env.AI) {
          return new Response(JSON.stringify({
            error: 'AI not configured',
            message: 'AI binding required for text generation'
          }), { status: 503, headers: corsHeaders });
        }

        const body = await request.json();
        const prompt = body.prompt || body.query || '';
        const model = body.model || '@cf/meta/llama-2-7b-chat-int8';
        const maxTokens = body.max_tokens || 512;

        if (!prompt) {
          return new Response(JSON.stringify({
            error: 'Prompt required',
            example: { prompt: 'Your question or topic' }
          }), { status: 400, headers: corsHeaders });
        }

        try {
          // Run AI model
          const aiResponse = await env.AI.run(model, {
            prompt: prompt,
            max_tokens: maxTokens,
            temperature: 0.7,
            top_p: 0.9
          });

          return new Response(JSON.stringify({
            success: true,
            model: model,
            prompt: prompt,
            response: aiResponse.response || aiResponse,
            timestamp: new Date().toISOString()
          }), { 
            status: 200,
            headers: corsHeaders 
          });

        } catch (error) {
          return new Response(JSON.stringify({
            error: 'AI generation failed',
            message: error.message,
            model: model
          }), { status: 500, headers: corsHeaders });
        }
      }

      // ====================================================================
      // GENERATE EMBEDDINGS
      // ====================================================================
      if (path === '/api/embeddings' && method === 'POST') {
        if (!env.AI) {
          return new Response(JSON.stringify({
            error: 'AI not configured',
            message: 'AI binding required for embeddings'
          }), { status: 503, headers: corsHeaders });
        }

        const body = await request.json();
        const text = body.text || '';

        if (!text) {
          return new Response(JSON.stringify({
            error: 'Text required',
            example: { text: 'Your text to embed' }
          }), { status: 400, headers: corsHeaders });
        }

        try {
          // Generate embeddings using BGE model
          const embeddings = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
            text: text
          });

          // Store in Vectorize if available
          if (env.VECTORIZE && body.id) {
            await env.VECTORIZE.insert([{
              id: body.id,
              values: embeddings.data[0],
              metadata: {
                text: text,
                timestamp: Date.now()
              }
            }]);
          }

          return new Response(JSON.stringify({
            success: true,
            text: text,
            embedding_size: embeddings.data[0].length,
            stored_in_vectorize: env.VECTORIZE && body.id ? true : false,
            timestamp: new Date().toISOString()
          }), { 
            status: 200,
            headers: corsHeaders 
          });

        } catch (error) {
          return new Response(JSON.stringify({
            error: 'Embedding generation failed',
            message: error.message
          }), { status: 500, headers: corsHeaders });
        }
      }

      // ====================================================================
      // SEMANTIC SEARCH
      // ====================================================================
      if (path === '/api/search' && method === 'POST') {
        const body = await request.json();
        const query = body.query || '';
        const limit = body.limit || 10;

        if (!query) {
          return new Response(JSON.stringify({
            error: 'Query parameter required',
            example: { query: 'your search term' }
          }), { status: 400, headers: corsHeaders });
        }

        // If AI and Vectorize available, use semantic search
        if (env.AI && env.VECTORIZE) {
          try {
            // Generate query embedding
            const queryEmbedding = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
              text: query
            });

            // Search in Vectorize
            const results = await env.VECTORIZE.query(
              queryEmbedding.data[0],
              {
                topK: limit,
                returnMetadata: true
              }
            );

            return new Response(JSON.stringify({
              success: true,
              query: query,
              search_type: 'semantic',
              results: results.matches.map(match => ({
                id: match.id,
                score: match.score,
                text: match.metadata?.text || '',
                metadata: match.metadata
              })),
              count: results.matches.length,
              timestamp: new Date().toISOString()
            }), { 
              status: 200,
              headers: corsHeaders 
            });

          } catch (error) {
            // Fallback to basic search
            console.error('Semantic search failed:', error);
          }
        }

        // Fallback: Basic keyword search in D1
        if (env.DB) {
          try {
            const searchResults = await env.DB.prepare(
              `SELECT * FROM knowledge_entries 
               WHERE title LIKE ? OR content LIKE ? 
               LIMIT ?`
            ).bind(`%${query}%`, `%${query}%`, limit).all();

            return new Response(JSON.stringify({
              success: true,
              query: query,
              search_type: 'keyword',
              results: searchResults.results || [],
              count: searchResults.results?.length || 0,
              timestamp: new Date().toISOString()
            }), { 
              status: 200,
              headers: corsHeaders 
            });

          } catch (error) {
            console.error('Database search failed:', error);
          }
        }

        // No search available
        return new Response(JSON.stringify({
          success: true,
          query: query,
          search_type: 'none',
          results: [],
          message: 'Search requires AI+Vectorize or Database configuration',
          timestamp: new Date().toISOString()
        }), { 
          status: 200,
          headers: corsHeaders 
        });
      }

      // ====================================================================
      // AI RESEARCH (Advanced)
      // ====================================================================
      if (path === '/api/research' && method === 'POST') {
        if (!env.AI) {
          return new Response(JSON.stringify({
            error: 'AI not configured',
            message: 'AI binding required for research functionality'
          }), { status: 503, headers: corsHeaders });
        }

        const body = await request.json();
        const topic = body.topic || '';
        const language = body.language || 'de';

        if (!topic) {
          return new Response(JSON.stringify({
            error: 'Topic parameter required',
            example: { topic: 'your research topic' }
          }), { status: 400, headers: corsHeaders });
        }

        try {
          // Create research prompt
          const researchPrompt = `Du bist ein Experte für Recherche und Wissenssammlung. 
Erstelle eine detaillierte Recherche zum Thema: "${topic}".

Strukturiere deine Antwort wie folgt:
1. Überblick und Definition
2. Wichtige Aspekte und Fakten
3. Historischer Kontext
4. Aktuelle Entwicklungen
5. Quellen und weiterführende Informationen

Antworte auf Deutsch und sei präzise und informativ.`;

          // Run AI research
          const aiResponse = await env.AI.run('@cf/meta/llama-2-7b-chat-int8', {
            prompt: researchPrompt,
            max_tokens: 1024,
            temperature: 0.7
          });

          // Extract response text
          const responseText = aiResponse.response || JSON.stringify(aiResponse);

          // If Vectorize available, store research for future retrieval
          if (env.VECTORIZE) {
            try {
              const embedding = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
                text: `${topic}: ${responseText.substring(0, 500)}`
              });

              await env.VECTORIZE.insert([{
                id: `research_${Date.now()}`,
                values: embedding.data[0],
                metadata: {
                  type: 'research',
                  topic: topic,
                  summary: responseText.substring(0, 200),
                  timestamp: Date.now()
                }
              }]);
            } catch (vectorError) {
              console.error('Failed to store in Vectorize:', vectorError);
            }
          }

          return new Response(JSON.stringify({
            success: true,
            topic: topic,
            research: responseText,
            model: '@cf/meta/llama-2-7b-chat-int8',
            language: language,
            stored_in_vectorize: env.VECTORIZE ? true : false,
            timestamp: new Date().toISOString()
          }), { 
            status: 200,
            headers: corsHeaders 
          });

        } catch (error) {
          return new Response(JSON.stringify({
            error: 'Research failed',
            message: error.message,
            topic: topic
          }), { status: 500, headers: corsHeaders });
        }
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
          research: '/api/research (POST)',
          generate: '/api/generate (POST)',
          embeddings: '/api/embeddings (POST)'
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
