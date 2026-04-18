import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface TavilyArticle {
  title: string;
  url: string;
  content: string;
  score: number;
  published_date?: string;
}

interface TavilyResponse {
  query: string;
  answer?: string;
  results: TavilyArticle[];
  images?: string[];
}

interface ResearchResult {
  query: string;
  answer: string | null;
  articles: Array<{
    title: string;
    url: string;
    content: string;
    score: number;
  }>;
  images: string[];
  searched_at: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const tavilyKey = Deno.env.get('TAVILY_API_KEY');
    if (!tavilyKey) {
      return new Response(
        JSON.stringify({ error: 'TAVILY_API_KEY not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const body = await req.json().catch(() => ({}));
    const query: string = body.query ?? '';
    const userId: string | undefined = body.userId;
    const world: string = body.world ?? 'materie';

    if (!query || query.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Query ist erforderlich' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Tavily API call
    const tavilyRes = await fetch('https://api.tavily.com/search', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        api_key: tavilyKey,
        query: query.trim(),
        search_depth: 'advanced',
        include_answer: true,
        include_images: true,
        max_results: 10,
      }),
    });

    if (!tavilyRes.ok) {
      const errText = await tavilyRes.text();
      console.error('Tavily API error:', tavilyRes.status, errText);
      return new Response(
        JSON.stringify({ error: `Tavily API Fehler: ${tavilyRes.status}` }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const tavilyData: TavilyResponse = await tavilyRes.json();

    const result: ResearchResult = {
      query: tavilyData.query,
      answer: tavilyData.answer ?? null,
      articles: (tavilyData.results ?? []).map((r) => ({
        title: r.title,
        url: r.url,
        content: r.content,
        score: r.score,
      })),
      images: tavilyData.images ?? [],
      searched_at: new Date().toISOString(),
    };

    // Persist to research_sessions if userId provided
    if (userId) {
      try {
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
        const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
        const supabase = createClient(supabaseUrl, serviceKey);

        const { error: insertErr } = await supabase
          .from('research_sessions')
          .insert({
            user_id: userId,
            query: result.query,
            answer: result.answer,
            results: {
              articles: result.articles,
              images: result.images,
              searched_at: result.searched_at,
              world,
            },
            source: 'tavily',
          });

        if (insertErr) {
          console.error('research_sessions insert error:', insertErr.message);
        } else {
          // Increment research_sessions_count on user_profiles
          await supabase.rpc('increment_research_count', { uid: userId });
        }
      } catch (dbErr) {
        // Non-fatal — still return results to client
        console.error('DB persist error:', dbErr);
      }
    }

    return new Response(
      JSON.stringify({ success: true, data: result }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('recherche function error:', err);
    return new Response(
      JSON.stringify({ error: 'Interner Serverfehler' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
