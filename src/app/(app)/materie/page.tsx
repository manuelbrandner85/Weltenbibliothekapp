'use client'

import { WorldHeader } from '@/components/layout/WorldHeader'
import { BottomTabBar } from '@/components/layout/BottomTabBar'
import { MaterieHomeTab } from '@/components/materie/MaterieHomeTab'

export default function MateriePage() {
  return (
    <div className="min-h-screen bg-materie-world">
      <WorldHeader world="materie" />
      <main className="pb-20">
        <MaterieHomeTab />
      </main>
      <BottomTabBar world="materie" />
    </div>
  )
}
