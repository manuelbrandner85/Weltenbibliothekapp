'use client'

// Weltenbibliothek – Offline fallback page (served by service worker)
// This page is shown when the user is offline and the requested page is not cached.

export default function OfflinePage() {
  return (
    <div className="min-h-screen bg-background flex items-center justify-center px-6">
      <div className="text-center max-w-sm">
        {/* Animated rings */}
        <div className="relative w-24 h-24 mx-auto mb-8">
          <div className="absolute inset-0 rounded-full border-2 border-materie/30 animate-rotate-slow" />
          <div className="absolute inset-2 rounded-full border border-energie/20 animate-counter-rotate" />
          <div className="absolute inset-4 rounded-full bg-gradient-to-br from-materie/10 to-energie/10 flex items-center justify-center">
            <span className="text-3xl">🌍</span>
          </div>
        </div>

        <h1 className="text-xl font-bold tracking-widest uppercase mb-3 text-white">
          Weltenbibliothek
        </h1>
        <p className="text-text-secondary text-sm leading-relaxed mb-8">
          Du bist gerade offline.<br />
          Verbinde dich mit dem Internet,<br />
          um die Weltenbibliothek zu nutzen.
        </p>

        <button
          onClick={() => window.location.reload()}
          className="inline-flex items-center gap-2 px-7 py-3 rounded-xl
            bg-gradient-to-r from-materie to-energie text-white
            font-semibold text-sm transition-opacity hover:opacity-85 active:opacity-70"
        >
          ↻ Erneut versuchen
        </button>

        <p className="mt-6 text-xs text-text-secondary/50">
          Diese Seite wurde aus dem Service-Worker-Cache geladen.
        </p>
      </div>
    </div>
  )
}
