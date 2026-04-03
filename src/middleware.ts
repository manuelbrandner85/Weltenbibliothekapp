import { NextRequest, NextResponse } from 'next/server'
import { updateSession } from '@/lib/supabase/middleware'

export async function middleware(request: NextRequest) {
  return await updateSession(request)
}

export const config = {
  matcher: [
    // Exclude static assets, manifests, service worker, icons, and the offline fallback page
    '/((?!_next/static|_next/image|favicon\\.ico|manifest\\.json|icons|screenshots|sw\\.js|offline|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico|html)$).*)',
  ],
}
