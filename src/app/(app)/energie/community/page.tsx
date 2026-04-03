'use client'

import { Suspense } from 'react'
import { WorldHeader } from '@/components/layout/WorldHeader'
import { BottomTabBar } from '@/components/layout/BottomTabBar'
import { ChatView } from '@/components/chat/ChatView'

export default function EnergieCommunityPage() {
  return (
    <div className="min-h-screen bg-energie-world flex flex-col">
      <WorldHeader world="energie" title="COMMUNITY" showBack />
      <main className="flex-1 pb-20">
        <Suspense fallback={
          <div className="flex items-center justify-center py-20">
            <div className="w-8 h-8 border-2 border-[#9C27B0] border-t-transparent rounded-full animate-spin" />
          </div>
        }>
          <ChatView world="energie" />
        </Suspense>
      </main>
      <BottomTabBar world="energie" />
    </div>
  )
}
