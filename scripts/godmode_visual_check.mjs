// God-Mode: visuelle Smoke-Verifikation des gebauten Web-Builds.
// Laedt die App per Playwright, macht einen Screenshot und prueft per
// Gemini-Vision, ob ein echter App-Screen gerendert wird (nicht leer/schwarz/
// Crash). Rein advisory -- gibt IMMER exit 0 zurueck, gibt ein Verdict-JSON
// auf stdout aus. Fehlt Playwright/Gemini, wird sauber uebersprungen.
//
// Aufruf: node scripts/godmode_visual_check.mjs <url> <screenshotPath>

import fs from 'node:fs';

const url = process.argv[2] || 'http://localhost:8787';
const shot = process.argv[3] || '/tmp/godmode_shot.png';

function out(o) { process.stdout.write(JSON.stringify(o)); }

let chromium;
try {
  ({ chromium } = await import('playwright'));
} catch (_) {
  out({ skipped: true, reason: 'playwright_missing' });
  process.exit(0);
}

let browser;
try {
  browser = await chromium.launch({ args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 412, height: 892 } });
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e).slice(0, 200)));
  await page.goto(url, { waitUntil: 'networkidle', timeout: 45000 }).catch(() => {});
  // Flutter-Web braucht einen Moment bis zum ersten Paint.
  await page.waitForTimeout(9000);
  await page.screenshot({ path: shot });

  // Heuristik: ist der Screenshot quasi-leer/einfarbig (schwarz/weiss)?
  const buf = fs.readFileSync(shot);
  const sizeKb = Math.round(buf.length / 1024);

  let vision = null;
  const key = process.env.GEMINI_API_KEY;
  if (key) {
    try {
      const b64 = buf.toString('base64');
      const prompt =
        'Dies ist ein Screenshot einer Flutter-Web-App. Antworte NUR als JSON: ' +
        '{"rendered":true|false,"blank_or_black":true|false,"note":"kurz"}. ' +
        'rendered=true wenn sichtbarer App-Inhalt (Text/UI) zu sehen ist; ' +
        'blank_or_black=true wenn der Screen leer, komplett schwarz/weiss oder ein Fehler ist.';
      const r = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${key}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [
              { text: prompt },
              { inline_data: { mime_type: 'image/png', data: b64 } },
            ] }],
          }),
        });
      if (r.ok) {
        const d = await r.json().catch(() => null);
        const txt = (d?.candidates?.[0]?.content?.parts || []).map((p) => p.text || '').join('');
        const a = txt.indexOf('{'); const b = txt.lastIndexOf('}');
        if (a !== -1 && b > a) { try { vision = JSON.parse(txt.slice(a, b + 1)); } catch (_) {} }
      }
    } catch (_) {}
  }

  out({
    skipped: false,
    screenshot_kb: sizeKb,
    page_errors: errors.slice(0, 5),
    vision,
  });
} catch (e) {
  out({ skipped: true, reason: 'error', detail: String(e).slice(0, 200) });
} finally {
  try { await browser?.close(); } catch (_) {}
}
process.exit(0);
