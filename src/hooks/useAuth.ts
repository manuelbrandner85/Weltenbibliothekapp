'use client'

import { useEffect, useState, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { User, Session } from '@supabase/supabase-js'
import type { Profile } from '@/types'

interface AuthState {
  user: User | null
  session: Session | null
  profile: Profile | null
  loading: boolean
  isAdmin: boolean
  isModerator: boolean
}

export function useAuth() {
  const [state, setState] = useState<AuthState>({
    user: null,
    session: null,
    profile: null,
    loading: true,
    isAdmin: false,
    isModerator: false,
  })

  const loadProfile = useCallback(async (userId: string) => {
    const supabase = createClient()
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()
    return data as Profile | null
  }, [])

  useEffect(() => {
    const supabase = createClient()

    // Initial session check
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      if (session?.user) {
        const profile = await loadProfile(session.user.id)
        setState({
          user: session.user,
          session,
          profile,
          loading: false,
          isAdmin: profile?.role === 'admin',
          isModerator: profile?.role === 'moderator' || profile?.role === 'admin',
        })
      } else {
        setState(s => ({ ...s, loading: false }))
      }
    })

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (session?.user) {
          const profile = await loadProfile(session.user.id)
          setState({
            user: session.user,
            session,
            profile,
            loading: false,
            isAdmin: profile?.role === 'admin',
            isModerator: profile?.role === 'moderator' || profile?.role === 'admin',
          })
        } else {
          setState({ user: null, session: null, profile: null, loading: false, isAdmin: false, isModerator: false })
        }
      }
    )

    return () => subscription.unsubscribe()
  }, [loadProfile])

  const signOut = useCallback(async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
  }, [])

  const refreshProfile = useCallback(async () => {
    if (!state.user) return
    const profile = await loadProfile(state.user.id)
    setState(s => ({ ...s, profile, isAdmin: profile?.role === 'admin', isModerator: profile?.role === 'moderator' || profile?.role === 'admin' }))
  }, [state.user, loadProfile])

  return { ...state, signOut, refreshProfile }
}
