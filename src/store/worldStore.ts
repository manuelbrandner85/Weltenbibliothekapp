import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { WorldId } from '@/types'

interface WorldState {
  currentWorld: WorldId
  setWorld: (world: WorldId) => void
  materieTab: number
  setMaterieTab: (tab: number) => void
  energieTab: number
  setEnergieTab: (tab: number) => void
}

export const useWorldStore = create<WorldState>()(
  persist(
    (set) => ({
      currentWorld: 'materie',
      setWorld: (world) => set({ currentWorld: world }),
      materieTab: 0,
      setMaterieTab: (tab) => set({ materieTab: tab }),
      energieTab: 0,
      setEnergieTab: (tab) => set({ energieTab: tab }),
    }),
    {
      name: 'weltenbibliothek-world',
    }
  )
)
