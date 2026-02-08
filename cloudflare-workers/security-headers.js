/**
 * Cloudflare Worker: Security Headers for Weltenbibliothek
 * 
 * This worker adds comprehensive security headers to all responses
 * to improve security posture and protect against common web vulnerabilities.
 * 
 * Deploy: wrangler deploy
 * Route: weltenbibliothek-ey9.pages.dev/*
 */

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  // Fetch the original response
  const response = await fetch(request)
  
  // Create new headers with security enhancements
  const newHeaders = new Headers(response.headers)
  
  // ==========================================================================
  // SECURITY HEADERS
  // ==========================================================================
  
  // 1. Content Security Policy (CSP)
  // Prevents XSS attacks by controlling which resources can be loaded
  const csp = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.gstatic.com https://www.google.com",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "img-src 'self' data: https: blob:",
    "font-src 'self' data: https://fonts.gstatic.com",
    "connect-src 'self' https://weltenbibliothek-api.brandy13062.workers.dev https://*.firebaseapp.com https://*.firebaseio.com https://*.googleapis.com https://*.cloudflare.com",
    "media-src 'self' https: blob:",
    "object-src 'none'",
    "frame-ancestors 'self'",
    "base-uri 'self'",
    "form-action 'self'",
    "upgrade-insecure-requests"
  ].join('; ')
  
  newHeaders.set('Content-Security-Policy', csp)
  
  // 2. X-Frame-Options
  // Prevents clickjacking attacks
  newHeaders.set('X-Frame-Options', 'SAMEORIGIN')
  
  // 3. Strict-Transport-Security (HSTS)
  // Forces HTTPS connections for 1 year
  newHeaders.set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload')
  
  // 4. X-Content-Type-Options
  // Prevents MIME-sniffing attacks
  newHeaders.set('X-Content-Type-Options', 'nosniff')
  
  // 5. Referrer-Policy
  // Controls how much referrer information is shared
  newHeaders.set('Referrer-Policy', 'strict-origin-when-cross-origin')
  
  // 6. Permissions-Policy (formerly Feature-Policy)
  // Restricts access to browser features
  const permissions = [
    'geolocation=()',
    'microphone=()',
    'camera=()',
    'payment=()',
    'usb=()',
    'magnetometer=()',
    'gyroscope=()',
    'accelerometer=()'
  ].join(', ')
  
  newHeaders.set('Permissions-Policy', permissions)
  
  // 7. X-XSS-Protection
  // Enables browser XSS protection (legacy, but still useful)
  newHeaders.set('X-XSS-Protection', '1; mode=block')
  
  // 8. Cross-Origin-Embedder-Policy (COEP)
  // Required for SharedArrayBuffer and high-resolution timers
  // Note: This might need adjustment based on your app's requirements
  // newHeaders.set('Cross-Origin-Embedder-Policy', 'require-corp')
  
  // 9. Cross-Origin-Opener-Policy (COOP)
  // Prevents other origins from gaining arbitrary window references
  newHeaders.set('Cross-Origin-Opener-Policy', 'same-origin-allow-popups')
  
  // 10. Cross-Origin-Resource-Policy (CORP)
  // Controls which origins can load this resource
  newHeaders.set('Cross-Origin-Resource-Policy', 'same-origin')
  
  // ==========================================================================
  // PERFORMANCE & CACHING HEADERS
  // ==========================================================================
  
  // Keep existing cache headers for static assets
  const url = new URL(request.url)
  const path = url.pathname
  
  // Static assets: cache for 1 year
  if (path.match(/\.(js|css|woff2?|ttf|otf|eot|png|jpg|jpeg|gif|svg|ico|webp|avif)$/)) {
    newHeaders.set('Cache-Control', 'public, max-age=31536000, immutable')
  }
  // HTML: no cache (always fresh)
  else if (path.match(/\.html$/) || path === '/') {
    newHeaders.set('Cache-Control', 'public, max-age=0, must-revalidate')
  }
  
  // ==========================================================================
  // DEBUGGING HEADERS (Remove in production if needed)
  // ==========================================================================
  
  // Add custom header to identify security worker is active
  newHeaders.set('X-Security-Worker', 'active')
  newHeaders.set('X-Security-Worker-Version', '1.0.0')
  
  // Return the response with new headers
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: newHeaders
  })
}

// ==========================================================================
// HELPER FUNCTIONS
// ==========================================================================

/**
 * Health check endpoint
 * Returns worker status and configuration
 */
function healthCheck() {
  return new Response(JSON.stringify({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    worker: 'security-headers',
    headers_added: [
      'Content-Security-Policy',
      'X-Frame-Options',
      'Strict-Transport-Security',
      'X-Content-Type-Options',
      'Referrer-Policy',
      'Permissions-Policy',
      'X-XSS-Protection',
      'Cross-Origin-Opener-Policy',
      'Cross-Origin-Resource-Policy'
    ]
  }, null, 2), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'X-Security-Worker': 'active'
    }
  })
}
