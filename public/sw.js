// ============================================
// WELTENBIBLIOTHEK – Service Worker v1.1
// ============================================

const CACHE_NAME = 'weltenbibliothek-v1'
const OFFLINE_URL = '/offline.html'

// Assets to pre-cache on install
const PRECACHE_ASSETS = [
  '/',
  '/offline.html',
  '/manifest.json',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png',
]

// ---- Install ----
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_ASSETS).catch((err) => {
        console.warn('[SW] Precache warning:', err)
      })
    })
  )
  // Activate immediately without waiting for old SW to be released
  self.skipWaiting()
})

// ---- Activate ----
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => caches.delete(key))
      )
    ).then(() => self.clients.claim())
  )
})

// ---- Fetch ----
self.addEventListener('fetch', (event) => {
  const { request } = event
  const url = new URL(request.url)

  // Skip non-GET, browser-extension and non-http(s) requests
  if (request.method !== 'GET' || !url.protocol.startsWith('http')) {
    return
  }

  // Skip Supabase / API calls — always network-only (never cache auth or realtime)
  if (
    url.hostname.includes('supabase.co') ||
    url.pathname.startsWith('/api/')
  ) {
    event.respondWith(
      fetch(request).catch(() => {
        // For API failures, return a simple JSON error
        return new Response(
          JSON.stringify({ error: 'Offline – keine Netzwerkverbindung' }),
          { status: 503, headers: { 'Content-Type': 'application/json' } }
        )
      })
    )
    return
  }

  // Static assets (immutable): Cache-first strategy
  if (
    url.pathname.startsWith('/_next/static/') ||
    url.pathname.startsWith('/icons/') ||
    url.pathname.startsWith('/screenshots/') ||
    url.pathname.endsWith('.woff2') ||
    url.pathname.endsWith('.woff') ||
    url.pathname.endsWith('.ttf') ||
    url.pathname.endsWith('.png') ||
    url.pathname.endsWith('.jpg') ||
    url.pathname.endsWith('.jpeg') ||
    url.pathname.endsWith('.svg') ||
    url.pathname.endsWith('.ico') ||
    url.pathname === '/manifest.json'
  ) {
    event.respondWith(
      caches.match(request).then((cached) => {
        if (cached) return cached
        return fetch(request).then((response) => {
          if (response.ok) {
            const clone = response.clone()
            caches.open(CACHE_NAME).then((cache) => cache.put(request, clone))
          }
          return response
        }).catch(() => {
          // If static asset fails offline, return from cache
          return caches.match(request)
        })
      })
    )
    return
  }

  // HTML navigation: Network-first, fallback to cache, then offline page
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          if (response.ok) {
            const clone = response.clone()
            caches.open(CACHE_NAME).then((cache) => cache.put(request, clone))
          }
          return response
        })
        .catch(async () => {
          // Try cached version of this exact page
          const cached = await caches.match(request)
          if (cached) return cached

          // Try cached root
          const root = await caches.match('/')
          if (root) return root

          // Show offline fallback page
          const offline = await caches.match(OFFLINE_URL)
          if (offline) return offline

          // Last resort: minimal inline HTML
          return new Response(
            `<!DOCTYPE html><html lang="de"><head><meta charset="UTF-8"><title>Offline</title>
            <meta name="viewport" content="width=device-width,initial-scale=1">
            <style>body{background:#0A0A0A;color:#fff;font-family:system-ui;display:flex;align-items:center;justify-content:center;min-height:100vh;text-align:center;padding:24px}h1{font-size:1.5rem;margin-bottom:1rem}p{opacity:.6}</style></head>
            <body><div><h1>🌍 Weltenbibliothek</h1><p>Du bist offline. Bitte verbinde dich mit dem Internet.</p></div></body></html>`,
            { headers: { 'Content-Type': 'text/html' } }
          )
        })
    )
    return
  }

  // Default: Network with cache fallback
  event.respondWith(
    fetch(request)
      .then((response) => {
        // Cache successful responses for future offline use
        if (response.ok) {
          const clone = response.clone()
          caches.open(CACHE_NAME).then((cache) => cache.put(request, clone))
        }
        return response
      })
      .catch(() => caches.match(request))
  )
})

// ---- Push Notifications ----
self.addEventListener('push', (event) => {
  if (!event.data) return

  let data = { title: 'Weltenbibliothek', body: '', url: '/' }
  try {
    data = { ...data, ...event.data.json() }
  } catch {
    data.body = event.data.text()
  }

  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/icons/icon-192x192.png',
      badge: '/icons/icon-96x96.png',
      data: { url: data.url },
      vibrate: [100, 50, 100],
      requireInteraction: false,
    })
  )
})

// ---- Notification Click ----
self.addEventListener('notificationclick', (event) => {
  event.notification.close()
  const targetUrl = event.notification.data?.url || '/'

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Focus existing tab if available
      for (const client of clientList) {
        if (client.url === targetUrl && 'focus' in client) {
          return client.focus()
        }
      }
      // Open new tab
      if (clients.openWindow) {
        return clients.openWindow(targetUrl)
      }
    })
  )
})
