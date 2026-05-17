---
name: weltenbibliothek-gamification
description: Octalysis Gamification und Vorhang-Module
globs: ["lib/services/gamification_*", "lib/screens/vorhang/**", "lib/screens/shared/skill_tree*", "lib/screens/shared/artifact_*", "lib/screens/shared/destiny_*"]
---

# Gamification – Octalysis Framework

## XP-System
- Reguläre Module: 5 Fragen, 50 XP
- Boss-Module: 15 Fragen, 100 XP, ≥80% Bestehensquote
- XP-Award nur beim ERSTEN Bestehen (Upsert + exists-Check)
- GamificationService.addXp(world, amount) → Supabase RPC add_user_xp

## Vorhang-Module (30 Module in 6 Branches)
- Branch 1: Machtpsychologie (V-01 bis V-05)
- Branch 2: Manipulationserkennung (V-06 bis V-10)
- Branch 3: Verhandlung & Überzeugung (V-11 bis V-15)
- Branch 4: Körpersprache & Nonverbales (V-16 bis V-20)
- Branch 5: Strategisches Denken (V-21 bis V-25)
- Branch 6: Schattenarbeit (V-26 bis V-30)

## Supabase-Tabellen (alle mit RLS)
- user_xp, user_skills, user_artifacts, user_destiny_cards, user_achievements
- vorhang_modules, vorhang_user_progress
- RLS: auth.uid() = user_id auf ALLEN Tabellen

## UI-Screens
- VorhangModulesScreen: 6 ExpansionTiles mit Status-Icons
- VorhangLessonScreen: 5 Tabs (Theorie, Fallstudie, Übung, Test, Videos)
- SkillTreeScreen, ArtifactCollectionScreen, DestinyCardScreen
