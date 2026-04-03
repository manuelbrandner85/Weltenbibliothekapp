#!/usr/bin/env node
// ============================================================
// Weltenbibliothek – Supabase Migration Runner
// Usage: node scripts/migrate.mjs
// ============================================================

import { readFileSync, readdirSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const ROOT = join(__dirname, '..')

// Load env
import { createRequire } from 'module'
const require = createRequire(import.meta.url)

let supabaseUrl, serviceRoleKey

// Try to read .env.local
try {
  const envFile = readFileSync(join(ROOT, '.env.local'), 'utf-8')
  for (const line of envFile.split('\n')) {
    const trimmed = line.trim()
    if (trimmed.startsWith('#') || !trimmed.includes('=')) continue
    const [key, ...rest] = trimmed.split('=')
    const value = rest.join('=').trim()
    if (key === 'NEXT_PUBLIC_SUPABASE_URL') supabaseUrl = value
    if (key === 'SUPABASE_SERVICE_ROLE_KEY') serviceRoleKey = value
  }
} catch {
  // Fall back to process.env
  supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY
}

if (!supabaseUrl || !serviceRoleKey) {
  console.error('❌ Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY')
  console.error('   Set them in .env.local or as environment variables')
  process.exit(1)
}

const migrationsDir = join(ROOT, 'supabase', 'migrations')
const migrationFiles = readdirSync(migrationsDir)
  .filter(f => f.endsWith('.sql'))
  .sort()

console.log(`🌍 Weltenbibliothek – Running ${migrationFiles.length} migration(s)...`)
console.log(`   Supabase: ${supabaseUrl}\n`)

let success = 0
let skipped = 0
let failed = 0

for (const file of migrationFiles) {
  const sql = readFileSync(join(migrationsDir, file), 'utf-8')
  const endpoint = `${supabaseUrl}/rest/v1/rpc/exec_sql`

  process.stdout.write(`  → ${file} ... `)

  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/`, {
      method: 'GET',
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
      },
    })

    // Use Supabase Management API to run SQL
    const sqlRes = await fetch(`${supabaseUrl.replace('.supabase.co', '')}/pg/query`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({ query: sql }),
    })

    if (sqlRes.ok) {
      console.log('✅')
      success++
    } else {
      // Try direct REST approach
      const directRes = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_migration`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          Prefer: 'return=minimal',
        },
        body: JSON.stringify({ sql_content: sql }),
      })

      if (directRes.ok) {
        console.log('✅')
        success++
      } else {
        console.log('⚠️  (Apply manually via Supabase Dashboard > SQL Editor)')
        skipped++
      }
    }
  } catch (err) {
    console.log('⚠️  (Apply manually)')
    skipped++
  }
}

console.log(`\n📊 Results: ${success} applied, ${skipped} manual, ${failed} failed`)
console.log('\n💡 To apply manually:')
console.log('   1. Go to https://supabase.com/dashboard/project/adtviduaftdquvfjpojb/sql')
console.log('   2. Open each SQL file in supabase/migrations/')
console.log('   3. Run them in order (001, 002, 003)')
console.log('\n✅ Done!')
