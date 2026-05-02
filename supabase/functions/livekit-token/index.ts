import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Nicht authentifiziert" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Supabase Client mit User-Token — User-ID + Metadata ermitteln
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Token ungültig" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json().catch(() => ({}));
    const roomName = body.roomName;
    if (!roomName || typeof roomName !== "string") {
      return new Response(JSON.stringify({ error: "roomName fehlt" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const apiKey = Deno.env.get("LIVEKIT_API_KEY");
    const apiSecret = Deno.env.get("LIVEKIT_API_SECRET");
    const livekitUrl = Deno.env.get("LIVEKIT_URL") ?? "";

    if (!apiKey || !apiSecret) {
      return new Response(
        JSON.stringify({ error: "LiveKit ist serverseitig nicht konfiguriert" }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const meta = user.user_metadata ?? {};
    const name = body.displayName ??
      meta.username ??
      meta.display_name ??
      (user.email ? user.email.split("@")[0] : "Mitglied");

    // JWT (HMAC-SHA256) — identisch zur bisherigen Cloudflare Worker Logik
    const b64url = (str: string) =>
      btoa(str).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

    const header = b64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
    const now = Math.floor(Date.now() / 1000);
    const payload = b64url(JSON.stringify({
      iss: apiKey,
      sub: user.id,
      name: name,
      nbf: now,
      exp: now + 14400, // 4 Stunden — wie Mensaena
      video: {
        roomJoin: true,
        room: roomName,
        canPublish: true,
        canSubscribe: true,
        canPublishData: true,
        canPublishSources: ["camera", "microphone", "screen_share", "screen_share_audio"],
      },
    }));

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(apiSecret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );
    const sigBytes = await crypto.subtle.sign(
      "HMAC",
      key,
      encoder.encode(`${header}.${payload}`),
    );
    const signature = b64url(String.fromCharCode(...new Uint8Array(sigBytes)));

    return new Response(
      JSON.stringify({ token: `${header}.${payload}.${signature}`, url: livekitUrl }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: `Fehler: ${(e as Error).message}` }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
