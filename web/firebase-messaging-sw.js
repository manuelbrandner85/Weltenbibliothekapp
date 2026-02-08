// 🔔 Weltenbibliothek Service Worker für Web Push Notifications
// Version: 1.0.0

const CACHE_NAME = 'weltenbibliothek-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter.js',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

// Installation - Cache static assets
self.addEventListener('install', (event) => {
  console.log('📦 [SW] Installing Service Worker...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('✅ [SW] Caching app shell');
        return cache.addAll(urlsToCache);
      })
  );
  self.skipWaiting();
});

// Activation - Clean up old caches
self.addEventListener('activate', (event) => {
  console.log('🔄 [SW] Activating Service Worker...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('🗑️ [SW] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  return self.clients.claim();
});

// Fetch - Network first, fallback to cache
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Clone response and cache it
        const responseToCache = response.clone();
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseToCache);
        });
        return response;
      })
      .catch(() => {
        // Network failed, try cache
        return caches.match(event.request);
      })
  );
});

// 🔔 PUSH NOTIFICATION HANDLER
self.addEventListener('push', (event) => {
  console.log('🔔 [SW] Push notification received');
  
  let notificationData = {
    title: 'Weltenbibliothek',
    body: 'Neue Nachricht',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'weltenbibliothek-notification',
    requireInteraction: false,
    data: {
      url: '/',
    }
  };

  if (event.data) {
    try {
      const data = event.data.json();
      notificationData = {
        title: data.title || notificationData.title,
        body: data.body || notificationData.body,
        icon: data.icon || notificationData.icon,
        badge: data.badge || notificationData.badge,
        tag: data.tag || notificationData.tag,
        requireInteraction: data.requireInteraction || false,
        data: {
          url: data.url || '/',
          roomId: data.roomId,
          messageId: data.messageId,
          world: data.world, // materie, energie, spirit
        }
      };
    } catch (e) {
      console.error('❌ [SW] Error parsing push data:', e);
    }
  }

  event.waitUntil(
    self.registration.showNotification(notificationData.title, notificationData)
  );
});

// 🖱️ NOTIFICATION CLICK HANDLER
self.addEventListener('notificationclick', (event) => {
  console.log('🖱️ [SW] Notification clicked');
  
  event.notification.close();

  const urlToOpen = event.notification.data?.url || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // Check if app is already open
        for (let client of clientList) {
          if (client.url === urlToOpen && 'focus' in client) {
            return client.focus();
          }
        }
        // Open new window
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen);
        }
      })
  );
});

// 🔕 NOTIFICATION CLOSE HANDLER
self.addEventListener('notificationclose', (event) => {
  console.log('🔕 [SW] Notification closed', event.notification.tag);
});

// 📨 MESSAGE HANDLER (from Flutter app)
self.addEventListener('message', (event) => {
  console.log('📨 [SW] Message received:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

console.log('✅ [SW] Weltenbibliothek Service Worker loaded successfully');
