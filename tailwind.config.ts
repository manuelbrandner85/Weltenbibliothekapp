import type { Config } from 'tailwindcss'

// Weltenbibliothek Design System
// Dark Theme: Background #0A0A0A, Surface #1A1A1A, #2A2A2A
// Materie-Welt: Blau #2196F3 / #1976D2 / #0D47A1
// Energie-Welt: Lila #9C27B0 / #7B1FA2 / #4A148C

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // === WELTENBIBLIOTHEK DESIGN SYSTEM ===
        
        // Background & Surfaces (Dark Theme)
        background: '#0A0A0A',
        surface: {
          DEFAULT: '#1A1A1A',
          light:   '#2A2A2A',
          lighter: '#3A3A3A',
        },

        // Text
        text: {
          primary:   '#FFFFFF',
          secondary: '#B0B0B0',
          hint:      '#707070',
        },

        // Materie-Welt: Blau
        materie: {
          DEFAULT: '#2196F3',
          dark:    '#1976D2',
          darker:  '#0D47A1',
          light:   '#64B5F6',
          glow:    'rgba(33,150,243,0.4)',
        },

        // Energie-Welt: Lila
        energie: {
          DEFAULT: '#9C27B0',
          dark:    '#7B1FA2',
          darker:  '#4A148C',
          light:   '#CE93D8',
          glow:    'rgba(156,39,176,0.4)',
        },

        // Kategorie-Farben Materie
        geopolitik: '#4CAF50',
        medien:     '#FF5252',
        forschung:  '#9C27B0',
        transparenz:'#FFEB3B',
        ueberwachung:'#FF9800',

        // Kategorie-Farben Energie
        kraftorte:  '#9C27B0',
        leylines:   '#2196F3',
        heilige:    '#4CAF50',
        spirituell: '#FFEB3B',
        vortex:     '#FFD700',

        // Signal Farben
        success: '#4CAF50',
        error:   '#FF5252',
        warning: '#FFC107',
        info:    '#2196F3',
      },

      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },

      borderRadius: {
        sm:   '8px',
        md:   '16px',
        lg:   '24px',
        xl:   '32px',
        full: '9999px',
      },

      boxShadow: {
        'materie':     '0 0 20px rgba(33,150,243,0.4)',
        'materie-sm':  '0 0 10px rgba(33,150,243,0.3)',
        'energie':     '0 0 20px rgba(156,39,176,0.4)',
        'energie-sm':  '0 0 10px rgba(156,39,176,0.3)',
        'card':        '0 4px 24px rgba(0,0,0,0.4)',
        'card-hover':  '0 8px 32px rgba(0,0,0,0.6)',
        'inner-glow':  'inset 0 1px 0 rgba(255,255,255,0.1)',
      },

      backgroundImage: {
        // Materie Gradient (Blau)
        'materie-gradient':  'linear-gradient(135deg, #0D47A1 0%, #1976D2 50%, #2196F3 100%)',
        'materie-gradient-v':'linear-gradient(to bottom, #0D47A1, #1A1A1A, #000000)',
        // Energie Gradient (Lila)
        'energie-gradient':  'linear-gradient(135deg, #4A148C 0%, #7B1FA2 50%, #9C27B0 100%)',
        'energie-gradient-v':'linear-gradient(to bottom, #4A148C, #1A1A1A, #000000)',
        // Dark Surface
        'dark-gradient':     'linear-gradient(to bottom, rgba(0,0,0,0.85), rgba(0,0,0,0.5))',
        // Portal
        'portal-gradient':   'radial-gradient(ellipse at center, #1a237e 0%, #0a0a0a 70%)',
      },

      animation: {
        'fade-in':        'fadeIn 0.3s ease-in-out',
        'fade-in-slow':   'fadeIn 0.6s ease-in-out',
        'slide-up':       'slideUp 0.35s ease-out',
        'slide-down':     'slideDown 0.35s ease-out',
        'scale-in':       'scaleIn 0.2s cubic-bezier(0.34,1.56,0.64,1)',
        'pulse-soft':     'pulseSoft 2.5s ease-in-out infinite',
        'spin-slow':      'spin 8s linear infinite',
        'float':          'float 6s ease-in-out infinite',
        'float-slow':     'float 10s ease-in-out infinite',
        'portal-rotate':  'portalRotate 10s linear infinite',
        'nebula-pulse':   'nebulaPulse 4s ease-in-out infinite',
        'particle-float': 'particleFloat 20s linear infinite',
        'glow-pulse':     'glowPulse 2s ease-in-out infinite',
        'shimmer':        'shimmer 1.8s linear infinite',
        'bounce-in':      'bounceIn 0.5s cubic-bezier(0.34,1.56,0.64,1)',
      },

      keyframes: {
        fadeIn: {
          '0%':   { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%':   { transform: 'translateY(16px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        slideDown: {
          '0%':   { transform: 'translateY(-16px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        scaleIn: {
          '0%':   { transform: 'scale(0.75)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '1', transform: 'scale(1)' },
          '50%':      { opacity: '0.7', transform: 'scale(0.97)' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px) rotate(0deg)' },
          '33%':      { transform: 'translateY(-14px) rotate(2deg)' },
          '66%':      { transform: 'translateY(-6px) rotate(-1.5deg)' },
        },
        portalRotate: {
          '0%':   { transform: 'rotate(0deg)' },
          '100%': { transform: 'rotate(360deg)' },
        },
        nebulaPulse: {
          '0%, 100%': { opacity: '0.6', transform: 'scale(1)' },
          '50%':      { opacity: '1', transform: 'scale(1.05)' },
        },
        particleFloat: {
          '0%':   { transform: 'translateY(100vh) rotate(0deg)', opacity: '0' },
          '10%':  { opacity: '1' },
          '90%':  { opacity: '1' },
          '100%': { transform: 'translateY(-100px) rotate(360deg)', opacity: '0' },
        },
        glowPulse: {
          '0%, 100%': { boxShadow: '0 0 6px rgba(33,150,243,0.3)' },
          '50%':      { boxShadow: '0 0 24px rgba(33,150,243,0.7)' },
        },
        shimmer: {
          '0%':   { backgroundPosition: '-400px 0' },
          '100%': { backgroundPosition: '400px 0' },
        },
        bounceIn: {
          '0%':   { transform: 'scale(0.3)', opacity: '0' },
          '50%':  { transform: 'scale(1.05)', opacity: '1' },
          '70%':  { transform: 'scale(0.95)' },
          '100%': { transform: 'scale(1)' },
        },
      },

      transitionTimingFunction: {
        spring: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
        bounce: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
      },
    },
  },
  plugins: [],
}

export default config
