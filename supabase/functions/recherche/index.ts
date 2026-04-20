/**
 * 🔍 SUPABASE EDGE FUNCTION: recherche
 *
 * KI-gestützte Recherche – Port der Logik aus workers/api-worker.js
 * (/recherche Endpoint). Liefert parallel Ergebnisse von:
 *   1. Lokale Artikel-DB (Supabase REST)
 *   2. Wikipedia (DE + EN)
 *   3. DuckDuckGo Instant Answer API
 *
 * Fallback-URL zum Cloudflare-Worker entfällt damit — die App kann
 * direkt https://<project>.supabase.co/functions/v1/recherche
 * ansprechen.
 *
 * Deployment:
 *   supabase functions deploy recherche --no-verify-jwt
 *
 * Aufruf (GET oder POST):
 *   GET  /functions/v1/recherche?q=Stichwort&realm=materie
 *   POST /functions/v1/recherche  { "query": "...", "realm": "..." }
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// ── CORS ────────────────────────────────────────────────────────────────────
const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

// ── ENV ─────────────────────────────────────────────────────────────────────
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

// ── TYPES ───────────────────────────────────────────────────────────────────
interface SearchResult {
  title: string;
  snippet: string;
  source: string;
  url: string | null;
  type: string;
  category?: string;
  pageId?: number;
}

// ── FETCH HELPERS ───────────────────────────────────────────────────────────
async function fetchJson<T>(url: string, headers: Record<string, string> = {}): Promise<T | null> {
  try {
    const res = await fetch(url, { headers });
    if (!res.ok) return null;
    return (await res.json()) as T;
  } catch {
    return null;
  }
}

// ── SEARCH ADAPTERS ─────────────────────────────────────────────────────────
async function searchLocalDb(query: string): Promise<SearchResult[]> {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) return [];
  const pattern = encodeURIComponent(`%${query}%`);
  const url =
    `${SUPABASE_URL}/rest/v1/articles` +
    `?select=id,title,content,category,world,created_at` +
    `&or=(title.ilike.${pattern},content.ilike.${pattern})` +
    `&is_published=eq.true&limit=5`;

  const data = await fetchJson<Array<Record<string, unknown>>>(url, {
    apikey: SUPABASE_ANON_KEY,
    Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
  });

  if (!Array.isArray(data)) return [];
  return data.map((a) => ({
    title: String(a.title ?? ""),
    snippet: String(a.content ?? "").substring(0, 300),
    source: "Weltenbibliothek",
    url: null,
    category: typeof a.category === "string" ? a.category : undefined,
    type: "article",
  }));
}

interface WikiResponse {
  query?: { search?: Array<{ title: string; snippet: string; pageid: number }> };
}

async function searchWikipedia(
  query: string,
  lang: "de" | "en",
  limit: number,
): Promise<SearchResult[]> {
  const url =
    `https://${lang}.wikipedia.org/w/api.php` +
    `?action=query&list=search&srsearch=${encodeURIComponent(query)}` +
    `&srlimit=${limit}&format=json&utf8=1`;

  const data = await fetchJson<WikiResponse>(url, {
    "User-Agent": "WeltenbibliothekApp/1.0",
  });

  return (data?.query?.search ?? []).map((r) => ({
    title: r.title,
    snippet: (r.snippet || "").replace(/<[^>]+>/g, ""),
    source: lang === "de" ? "Wikipedia DE" : "Wikipedia EN",
    url: `https://${lang}.wikipedia.org/wiki/${encodeURIComponent(
      r.title.replace(/ /g, "_"),
    )}`,
    type: lang === "de" ? "wiki" : "wiki_en",
    pageId: r.pageid,
  }));
}

interface DdgResponse {
  Abstract?: string;
  AbstractSource?: string;
  AbstractURL?: string;
  Heading?: string;
  RelatedTopics?: Array<{ Text?: string; FirstURL?: string }>;
}

async function searchDuckDuckGo(query: string): Promise<SearchResult[]> {
  const url =
    `https://api.duckduckgo.com/?q=${encodeURIComponent(query)}` +
    `&format=json&no_redirect=1&no_html=1&skip_disambig=1`;

  const data = await fetchJson<DdgResponse>(url, {
    "User-Agent": "WeltenbibliothekApp/1.0",
  });
  if (!data) return [];

  const out: SearchResult[] = [];
  if (data.Abstract) {
    out.push({
      title: data.Heading || query,
      snippet: data.Abstract,
      source: data.AbstractSource || "DuckDuckGo",
      url: data.AbstractURL || null,
      type: "instant",
    });
  }
  for (const topic of (data.RelatedTopics ?? []).slice(0, 5)) {
    if (topic.Text) {
      out.push({
        title: topic.Text.split(" - ")[0] || topic.Text.substring(0, 80),
        snippet: topic.Text,
        source: "DuckDuckGo",
        url: topic.FirstURL ?? null,
        type: "related",
      });
    }
  }
  return out;
}

// ── MAIN HANDLER ────────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  const url = new URL(req.url);
  let query = "";
  let realm = "materie";

  try {
    if (req.method === "POST") {
      const body = await req.json().catch(() => ({}));
      query = body.query ?? body.q ?? "";
      realm = body.realm ?? "materie";
    } else if (req.method === "GET") {
      query = url.searchParams.get("q") ?? url.searchParams.get("query") ?? "";
      realm = url.searchParams.get("realm") ?? "materie";
    } else {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    if (!query || !query.trim()) {
      return jsonResponse({ results: [], query: "", error: "Kein Suchbegriff" });
    }

    const [dbResults, wikiDeResults, wikiEnResultsRaw, ddgResults] =
      await Promise.all([
        searchLocalDb(query),
        searchWikipedia(query, "de", 8),
        searchWikipedia(query, "en", 5),
        searchDuckDuckGo(query),
      ]);

    // Duplikate (DE vs EN) entfernen
    const deTitles = new Set(wikiDeResults.map((r) => r.title.toLowerCase()));
    const wikiEnResults = wikiEnResultsRaw.filter(
      (r) => !deTitles.has(r.title.toLowerCase()),
    );

    const allResults: SearchResult[] = [
      ...dbResults,
      ...ddgResults,
      ...wikiDeResults,
      ...wikiEnResults,
    ];

    return jsonResponse({
      query,
      realm,
      count: allResults.length,
      results: allResults,
      sources: {
        local: dbResults.length,
        wikipedia_de: wikiDeResults.length,
        wikipedia_en: wikiEnResults.length,
        duckduckgo: ddgResults.length,
      },
      aiSummary: null,
      timestamp: new Date().toISOString(),
    });
  } catch (e) {
    console.error("recherche error:", e);
    return jsonResponse(
      { error: String(e), query, realm, results: [] },
      500,
    );
  }
});
