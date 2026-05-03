import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

/// Generiert eine eindeutige Guest-ID. Optional kann der Client einen
/// stabilen clientGuestId mitgeben (z.B. UUID aus SharedPreferences) damit
/// Reconnects als gleicher User auftauchen.
///
/// WICHTIG: Wenn zwei Gäste denselben displayName hätten (z.B. zwei
/// "Mitglied"-User), würde gleiche Identity LiveKit dazu bringen den
/// einen rauszuschmeißen. Daher hängen wir einen zufälligen Suffix an
/// wenn kein clientGuestId mitgegeben wurde.
function buildGuestId(
  name: string,
  clientGuestId: string | null,
): string {
  const safeName = name.replace(/[^a-zA-Z0-9]/g, "_").slice(0, 16);
  if (clientGuestId && clientGuestId.length >= 8) {
    return `guest-${safeName}-${clientGuestId.slice(0, 16)}`;
  }
  // Fallback: Zufallssuffix damit kein Identity-Clash
  const rand = crypto.randomUUID().slice(0, 8);
  return `guest-${safeName}-${rand}`;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Auth-Modus erkennen:
    // 1. Bearer-Token mit gültiger Supabase-Session → identity = user.id
    // 2. apikey-Header (nur Anon-Key) → identity = guest-<datum>-<name>
    // 3. Weder noch → 401
    const authHeader = req.headers.get("Authorization") ?? "";
    const apikey = req.headers.get("apikey") ?? "";
    const expectedAnon = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    let userId: string | null = null;
    let userMeta: Record<string, unknown> = {};
    let userEmail: string | null = null;

    if (authHeader.startsWith("Bearer ")) {
      // Supabase-User-Token → echten User holen
      const supabase = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        expectedAnon,
        { global: { headers: { Authorization: authHeader } } },
      );
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        userId = user.id;
        userMeta = user.user_metadata ?? {};
        userEmail = user.email ?? null;
      }
      // Bei ungültigem Token KEIN Hard-Fail mehr — fall back zu apikey-Modus
    }

    // Fallback: apikey muss vorhanden + korrekt sein
    if (!userId) {
      if (!apikey || apikey !== expectedAnon) {
        return new Response(
          JSON.stringify({ error: "Authentifizierung erforderlich" }),
          {
            status: 401,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }
    }

    const body = await req.json().catch(() => ({}));
    const roomName = body.roomName;
    if (!roomName || typeof roomName !== "string") {
      return new Response(JSON.stringify({ error: "roomName fehlt" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 🔐 Room-Validierung: nur App-eigene Rooms erlaubt.
    // Akzeptiert: wb-materie-*, wb-energie-*, wb-shared-*
    // Zeichen: a-z A-Z 0-9 _ -, max 64 Zeichen, kein Whitespace.
    const roomPattern =
      /^wb-(materie|energie|shared)-[a-zA-Z0-9_-]{1,48}$/;
    if (!roomPattern.test(roomName)) {
      return new Response(
        JSON.stringify({
          error:
            "Ungültiger Raum-Name. Erlaubt sind nur App-Räume (wb-materie-*, wb-energie-*, wb-shared-*).",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const apiKey = Deno.env.get("LIVEKIT_API_KEY");
    const apiSecret = Deno.env.get("LIVEKIT_API_SECRET");
    // livekit-wb.srv1438024.hstgr.cloud wurde nie deployed — Mensaena nutzen.
    // Fallback korrigiert stale Supabase-Secrets die noch auf die alte URL zeigen.
    const rawUrl = Deno.env.get("LIVEKIT_URL") ?? "";
    const livekitUrl = (rawUrl && !rawUrl.includes("livekit-wb."))
      ? rawUrl
      : "wss://livekit.srv1438024.hstgr.cloud";

    if (!apiKey || !apiSecret) {
      return new Response(
        JSON.stringify({ error: "LiveKit ist serverseitig nicht konfiguriert" }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Display-Name + Identity-Resolution
    const displayName = body.displayName ??
      (userMeta.username as string | undefined) ??
      (userMeta.display_name as string | undefined) ??
      (userEmail ? userEmail.split("@")[0] : "Mitglied");

    // Wenn Client eine stabile guest-id mitgegeben hat (z.B. UUID aus
    // SharedPreferences), nutzen wir die — sonst wird im buildGuestId ein
    // Random-Suffix angehängt damit Identity-Clashes verhindert werden.
    const clientGuestId = typeof body.clientGuestId === "string"
      ? body.clientGuestId
      : null;
    const identity = userId ?? buildGuestId(displayName, clientGuestId);

    // JWT (HMAC-SHA256) — identisch zur bisherigen Cloudflare Worker Logik
    const b64url = (str: string) =>
      btoa(str).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

    const header = b64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
    const now = Math.floor(Date.now() / 1000);
    const payload = b64url(JSON.stringify({
      iss: apiKey,
      sub: identity,
      name: displayName,
      nbf: now,
      exp: now + 14400, // 4 Stunden
      video: {
        roomJoin: true,
        room: roomName,
        canPublish: true,
        canSubscribe: true,
        canPublishData: true,
        canPublishSources: [
          "camera",
          "microphone",
          "screen_share",
          "screen_share_audio",
        ],
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
    const signature = b64url(
      String.fromCharCode(...new Uint8Array(sigBytes)),
    );

    return new Response(
      JSON.stringify({
        token: `${header}.${payload}.${signature}`,
        url: livekitUrl,
        identity, // Hilfreich für Client-side Logging
      }),
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
