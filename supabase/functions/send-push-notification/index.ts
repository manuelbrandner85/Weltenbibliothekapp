/**
 * 🔔 SUPABASE EDGE FUNCTION: send-push-notification
 *
 * Verarbeitet die notification_queue und sendet Web Push Notifications
 * über die Web Push Protocol (RFC 8030) an gespeicherte Endpoints.
 *
 * Deployment:
 *   supabase functions deploy send-push-notification
 *
 * Secrets (via `supabase secrets set`):
 *   VAPID_PRIVATE_KEY  – VAPID private key (Base64url)
 *   VAPID_PUBLIC_KEY   – VAPID public key (Base64url)
 *   VAPID_SUBJECT      – mailto: oder https: URL
 *
 * Kann als Cron-Job alle 30 Sekunden ausgeführt werden:
 *   supabase functions deploy send-push-notification --schedule "*/30 * * * * *"
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── VAPID ───────────────────────────────────────────────────────────────────

const VAPID_PUBLIC_KEY  = Deno.env.get("VAPID_PUBLIC_KEY")  ?? "";
const VAPID_PRIVATE_KEY = Deno.env.get("VAPID_PRIVATE_KEY") ?? "";
const VAPID_SUBJECT     = Deno.env.get("VAPID_SUBJECT")     ?? "mailto:admin@weltenbibliothek.app";

// ── SUPABASE CLIENT ─────────────────────────────────────────────────────────

function getSupabaseAdmin() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } }
  );
}

// ── WEB PUSH HELPERS ────────────────────────────────────────────────────────

/** Base64url → Uint8Array */
function base64urlToUint8Array(base64url: string): Uint8Array {
  const base64 = base64url.replace(/-/g, "+").replace(/_/g, "/");
  const padded = base64.padEnd(base64.length + (4 - (base64.length % 4)) % 4, "=");
  const binary = atob(padded);
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

/** Uint8Array → Base64url */
function uint8ArrayToBase64url(array: Uint8Array): string {
  return btoa(String.fromCharCode(...array))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}

/** VAPID JWT erstellen */
async function createVapidJwt(audience: string): Promise<string> {
  const header = { typ: "JWT", alg: "ES256" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    aud: audience,
    exp: now + 12 * 3600,
    sub: VAPID_SUBJECT,
  };

  const encode = (obj: object) =>
    uint8ArrayToBase64url(new TextEncoder().encode(JSON.stringify(obj)));

  const signingInput = `${encode(header)}.${encode(payload)}`;

  const privateKeyBytes = base64urlToUint8Array(VAPID_PRIVATE_KEY);
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    privateKeyBytes,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  const signatureBase64 = uint8ArrayToBase64url(new Uint8Array(signature));
  return `${signingInput}.${signatureBase64}`;
}

/** Web Push Notification senden */
async function sendWebPush(
  subscription: { endpoint: string; p256dh: string; auth_key: string },
  payload: string
): Promise<{ success: boolean; status?: number; error?: string }> {
  try {
    const url = new URL(subscription.endpoint);
    const audience = `${url.protocol}//${url.host}`;
    const jwt = await createVapidJwt(audience);

    // Encrypt payload with ECDH + AES-GCM (simplified: send as plaintext for demo)
    // Production: use Web Push encryption per RFC 8291
    const encoder = new TextEncoder();
    const body = encoder.encode(payload);

    const response = await fetch(subscription.endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/octet-stream",
        "Content-Encoding": "aes128gcm",
        "Authorization": `vapid t=${jwt},k=${VAPID_PUBLIC_KEY}`,
        "TTL": "3600",
      },
      body,
    });

    if (response.status === 201 || response.status === 200) {
      return { success: true, status: response.status };
    }

    // 410 Gone: Subscription abgelaufen → deaktivieren
    const error = await response.text().catch(() => "");
    return { success: false, status: response.status, error };
  } catch (e) {
    return { success: false, error: String(e) };
  }
}

/** FCM-Token Push senden (für Android/iOS) */
async function sendFcmPush(
  fcmToken: string,
  notification: { title: string; body: string; data?: Record<string, string> }
): Promise<{ success: boolean; error?: string }> {
  const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");
  if (!fcmServerKey) return { success: false, error: "FCM_SERVER_KEY not set" };

  try {
    const response = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `key=${fcmServerKey}`,
      },
      body: JSON.stringify({
        to: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: notification.data ?? {},
        priority: "high",
      }),
    });

    const result = await response.json();
    if (result.success === 1) return { success: true };
    return { success: false, error: JSON.stringify(result) };
  } catch (e) {
    return { success: false, error: String(e) };
  }
}

// ── MAIN HANDLER ────────────────────────────────────────────────────────────

serve(async (req) => {
  const supabase = getSupabaseAdmin();

  try {
    // Pending Notifications laden (max. 50 pro Run)
    const { data: queue, error: queueError } = await supabase
      .from("notification_queue")
      .select("*")
      .eq("status", "pending")
      .lt("attempts", 3)
      .order("created_at", { ascending: true })
      .limit(50);

    if (queueError) {
      console.error("Queue fetch error:", queueError);
      return new Response(JSON.stringify({ error: queueError.message }), { status: 500 });
    }

    if (!queue || queue.length === 0) {
      return new Response(JSON.stringify({ processed: 0, message: "Keine ausstehenden Notifications" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    let sent = 0;
    let failed = 0;

    for (const notification of queue) {
      // Subscriptions des Users laden
      const { data: subscriptions } = await supabase
        .from("push_subscriptions")
        .select("*")
        .eq("user_id", notification.user_id)
        .eq("is_active", true);

      if (!subscriptions || subscriptions.length === 0) {
        // Kein aktiver Endpoint → als verarbeitet markieren
        await supabase
          .from("notification_queue")
          .update({ status: "sent", processed_at: new Date().toISOString() })
          .eq("id", notification.id);
        continue;
      }

      const payload = JSON.stringify({
        title: notification.title,
        body: notification.body,
        data: notification.data ?? {},
        timestamp: Date.now(),
      });

      let notificationSent = false;

      for (const sub of subscriptions) {
        let result: { success: boolean; status?: number; error?: string };

        if (sub.platform === "fcm" && sub.fcm_token) {
          // Android/iOS via FCM
          result = await sendFcmPush(sub.fcm_token, {
            title: notification.title,
            body: notification.body,
            data: { ...notification.data, notificationId: notification.id },
          });
        } else {
          // Web Push
          result = await sendWebPush(
            { endpoint: sub.endpoint, p256dh: sub.p256dh, auth_key: sub.auth_key },
            payload
          );

          // 410 Gone: Subscription deaktivieren
          if (result.status === 410) {
            await supabase
              .from("push_subscriptions")
              .update({ is_active: false })
              .eq("id", sub.id);
          }
        }

        if (result.success) {
          notificationSent = true;
          console.log(`✅ Push sent to ${sub.platform} for user ${notification.user_id}`);
        } else {
          console.warn(`⚠️ Push failed: ${result.error}`);
        }
      }

      // Status in der Queue aktualisieren
      await supabase
        .from("notification_queue")
        .update({
          status: notificationSent ? "sent" : "failed",
          attempts: notification.attempts + 1,
          processed_at: new Date().toISOString(),
        })
        .eq("id", notification.id);

      if (notificationSent) sent++; else failed++;
    }

    return new Response(
      JSON.stringify({ processed: queue.length, sent, failed }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("Edge Function error:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
