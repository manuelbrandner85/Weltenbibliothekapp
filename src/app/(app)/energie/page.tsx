'use client'

import { WorldHeader } from '@/components/layout/WorldHeader'
import { BottomTabBar } from '@/components/layout/BottomTabBar'
import { EnergieHomeTab } from '@/components/energie/EnergieHomeTab'

export default function EnergiePage() {
  return (
    <div className="min-h-screen bg-energie-world">
      <WorldHeader world="energie" />
      <main className="pb-20">
        <EnergieHomeTab />
      </main>
      <BottomTabBar world="energie" />
    </div>
  )
}
