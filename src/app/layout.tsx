import type { Metadata, Viewport } from 'next'
import '@/styles/globals.css'
import { Toaster } from 'react-hot-toast'
import { ServiceWorkerRegister } from '@/components/pwa/ServiceWorkerRegister'

export const metadata: Metadata = {
  title: 'Weltenbibliothek – Die alternative Wissensplattform',
  description: 'Weltenbibliothek bietet alternative Perspektiven zu globalen Ereignissen, spirituellen Themen und verborgenem Wissen. Erkunde die Welt der Materie und Energie.',
  keywords: 'Weltenbibliothek, alternative Medien, Recherche, Spiritualität, Materie, Energie, Verschwörungen, Faktencheck',
  manifest: '/manifest.json',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'Weltenbibliothek',
  },
  icons: {
    icon: [
      { url: '/icons/icon-192x192.png', sizes: '192x192', type: 'image/png' },
      { url: '/icons/icon-512x512.png', sizes: '512x512', type: 'image/png' },
    ],
    apple: [
      { url: '/icons/apple-touch-icon.png', sizes: '180x180' },
    ],
  },
  openGraph: {
    title: 'Weltenbibliothek',
    description: 'Die alternative Wissensplattform',
    type: 'website',
    locale: 'de_DE',
    siteName: 'Weltenbibliothek',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Weltenbibliothek',
    description: 'Die alternative Wissensplattform',
  },
}

export const viewport: Viewport = {
  themeColor: '#0A0A0A',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: 'cover',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="de" className="dark">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap"
          rel="stylesheet"
        />
        <link rel="apple-touch-icon" href="/icons/apple-touch-icon.png" />
        <meta name="mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
      </head>
      <body className="bg-background text-white antialiased">
        <ServiceWorkerRegister />
        {children}
        <Toaster
          position="top-center"
          toastOptions={{
            duration: 3000,
            style: {
              background: '#1A1A1A',
              color: '#FFFFFF',
              border: '1px solid rgba(255,255,255,0.1)',
              borderRadius: '12px',
              fontSize: '14px',
              fontFamily: 'Inter, sans-serif',
            },
            success: {
              iconTheme: { primary: '#4CAF50', secondary: '#1A1A1A' },
            },
            error: {
              iconTheme: { primary: '#FF5252', secondary: '#1A1A1A' },
            },
          }}
        />
      </body>
    </html>
  )
}
