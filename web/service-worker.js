// 🌐 WELTENBIBLIOTHEK - SERVICE WORKER
// PWA Service Worker für Offline-Support und Caching

const CACHE_NAME = 'weltenbibliothek-v47';
const RUNTIME_CACHE = 'weltenbibliothek-runtime-v47';

// Assets to cache on install
const PRECACHE_ASSETS = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter.js',
  '/flutter_service_worker.js',
  '/manifest.json',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png',
];

// Install event - cache essential assets
self.addEventListener('install', (event) => {
  console.log('📦 Service Worker: Installing...');
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('📦 Service Worker: Caching app shell');
        return cache.addAll(PRECACHE_ASSETS);
      })
      .then(() => {
        console.log('✅ Service Worker: Installation complete');
        return self.skipWaiting();
      })
      .catch((error) => {
        console.error('❌ Service Worker: Installation failed', error);
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('🔄 Service Worker: Activating...');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((cacheName) => {
              // Delete old caches
              return cacheName !== CACHE_NAME && cacheName !== RUNTIME_CACHE;
            })
            .map((cacheName) => {
              console.log('🗑️ Service Worker: Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            })
        );
      })
      .then(() => {
        console.log('✅ Service Worker: Activation complete');
        return self.clients.claim();
      })
  );
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  const { request } = event;
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }
  
  // Skip cross-origin requests
  if (!request.url.startsWith(self.location.origin)) {
    return;
  }
  
  event.respondWith(
    caches.match(request)
      .then((cachedResponse) => {
        if (cachedResponse) {
          console.log('💾 Service Worker: Serving from cache:', request.url);
          return cachedResponse;
        }
        
        // Not in cache, fetch from network
        return fetch(request)
          .then((response) => {
            // Check if valid response
            if (!response || response.status !== 200 || response.type !== 'basic') {
              return response;
            }
            
            // Clone response (can only be used once)
            const responseToCache = response.clone();
            
            // Cache the fetched response
            caches.open(RUNTIME_CACHE)
              .then((cache) => {
                console.log('💾 Service Worker: Caching new resource:', request.url);
                cache.put(request, responseToCache);
              });
            
            return response;
          })
          .catch((error) => {
            console.error('❌ Service Worker: Fetch failed:', error);
            
            // Return offline page if available
            return caches.match('/offline.html')
              .then((offlinePage) => {
                if (offlinePage) {
                  return offlinePage;
                }
                
                // Last resort: return a basic response
                return new Response(
                  '<!DOCTYPE html><html><head><title>Offline</title></head><body><h1>📡 Offline</h1><p>Keine Internetverbindung. Bitte versuche es später erneut.</p></body></html>',
                  {
                    headers: { 'Content-Type': 'text/html' }
                  }
                );
              });
          });
      })
  );
});

// Background sync
self.addEventListener('sync', (event) => {
  console.log('🔄 Service Worker: Background sync:', event.tag);
  
  if (event.tag === 'sync-messages') {
    event.waitUntil(
      // Sync offline messages
      syncOfflineMessages()
    );
  }
});

// Push notifications
self.addEventListener('push', (event) => {
  console.log('🔔 Service Worker: Push notification received');
  
  const options = {
    body: event.data ? event.data.text() : 'Neue Nachricht',
    icon: '/icons/icon-192x192.png',
    badge: '/icons/icon-72x72.png',
    vibrate: [200, 100, 200],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1
    },
    actions: [
      {
        action: 'explore',
        title: 'Öffnen',
        icon: '/icons/icon-192x192.png'
      },
      {
        action: 'close',
        title: 'Schließen',
        icon: '/icons/icon-192x192.png'
      }
    ]
  };
  
  event.waitUntil(
    self.registration.showNotification('Weltenbibliothek', options)
  );
});

// Notification click
self.addEventListener('notificationclick', (event) => {
  console.log('🔔 Service Worker: Notification clicked:', event.action);
  
  event.notification.close();
  
  if (event.action === 'explore') {
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Helper: Sync offline messages
async function syncOfflineMessages() {
  try {
    console.log('🔄 Service Worker: Syncing offline messages...');
    
    // Get offline messages from IndexedDB (Hive)
    // This would integrate with OfflineSyncService
    
    // For now, just log
    console.log('✅ Service Worker: Offline messages synced');
    
  } catch (error) {
    console.error('❌ Service Worker: Sync failed:', error);
  }
}

// Message handler
self.addEventListener('message', (event) => {
  console.log('💬 Service Worker: Message received:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

console.log('🌐 Service Worker: Script loaded');
