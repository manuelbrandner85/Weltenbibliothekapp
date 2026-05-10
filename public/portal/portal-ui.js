// Weltenbibliothek · Portal UI bindings (DOM + tweaks + easter egg)
(function () {
  // ───── wordmark letter-by-letter reveal ─────
  function spell(el, txt, baseDelay) {
    el.innerHTML = '';
    [...txt].forEach((c, i) => {
      const s = document.createElement('span');
      s.className = 'char';
      s.textContent = c === ' ' ? '\u00A0' : c;
      s.style.animationDelay = (baseDelay + i * 0.06) + 's';
      el.appendChild(s);
    });
  }
  spell(document.getElementById('rowWelten'), 'WELTEN', 0.6);
  spell(document.getElementById('rowBibliothek'), 'BIBLIOTHEK', 1.05);

  // ───── world hover light follow ─────
  document.querySelectorAll('.world').forEach(el => {
    el.addEventListener('mousemove', e => {
      const r = el.getBoundingClientRect();
      el.style.setProperty('--mx', ((e.clientX - r.left) / r.width * 100) + '%');
      el.style.setProperty('--my', ((e.clientY - r.top) / r.height * 100) + '%');
    });
    el.addEventListener('click', () => {
      const w = el.classList.contains('materie') ? 'materie' : 'energie';
      const c1 = w === 'materie' ? '#3b82f6' : '#a855f7';
      const c2 = w === 'materie' ? '#1d4ed8' : '#7e22ce';
      const eyebrow = w === 'materie' ? 'EINTRITT · WELT I' : 'EINTRITT · WELT II';
      const name = w === 'materie' ? 'MATERIE' : 'ENERGIE';
      const sub = w === 'materie' ? 'Wissen · Logik · Fakten' : 'Spiritualität · Mystik · Bewusstsein';

      const warp = document.getElementById('warp');
      warp.style.setProperty('--warp-c1', c1);
      warp.style.setProperty('--warp-c2', c2);
      document.getElementById('warpEyebrow').textContent = eyebrow;
      document.getElementById('warpName').textContent = name;
      document.getElementById('warpSub').textContent = sub;

      document.body.classList.add('warping');
      // ORIGINAL transition video (from the Flutter repo). Falls back to fluid morph
      // if the asset can't be fetched (CORS/network).
      const vid = document.getElementById('warpVideo');
      const baseUrl = 'https://raw.githubusercontent.com/manuelbrandner85/Weltenbibliothekapp/main/assets/videos/';
      const src = w === 'materie'
        ? baseUrl + 'transition_energie_to_materie.mp4'
        : baseUrl + 'transition_materie_to_energie.mp4';
      vid.crossOrigin = 'anonymous';
      vid.src = src;
      let videoStarted = false;
      vid.addEventListener('playing', () => { videoStarted = true; warp.classList.add('video-on'); }, { once: true });
      vid.addEventListener('error',   () => startFluidWarp(w, c1, c2), { once: true });
      vid.play().catch(() => startFluidWarp(w, c1, c2));
      requestAnimationFrame(() => {
        warp.classList.add('on');
        // safety fallback if video stalls
        setTimeout(() => { if (!videoStarted) startFluidWarp(w, c1, c2); }, 700);
      });
      // sync DOM overlay phases with engine events
      const onAccel  = () => warp.classList.add('streaking');
      const onEntry  = () => { warp.classList.add('entering'); warp.classList.add('flash'); };
      const onInside = () => warp.classList.add('inside');
      document.addEventListener('warp:accel', onAccel,  { once: true });
      document.addEventListener('warp:entry', onEntry,  { once: true });
      document.addEventListener('warp:inside', onInside, { once: true });
      window.PortalEngine?.warp(w, () => {
        setTimeout(() => warp.classList.add('arrived'), 250);
      });
    });
  });

  // ───── tap dots + easter egg ─────
  let taps = 0; let golden = false;
  const dotsEl = document.getElementById('tapDots');
  for (let i = 0; i < 10; i++) { const d = document.createElement('div'); d.className = 'd'; dotsEl.appendChild(d); }
  const halo = document.getElementById('halo');
  const eggEl = document.getElementById('egg');
  halo.addEventListener('click', () => {
    taps++;
    window.PortalEngine?.pulse();
    [...dotsEl.children].forEach((d, i) => d.classList.toggle('on', i < taps));
    if (taps >= 10) {
      taps = 0;
      golden = !golden;
      [...dotsEl.children].forEach(d => d.classList.remove('on'));
      eggEl.classList.add('show');
      setTimeout(() => eggEl.classList.remove('show'), 2400);
      // toggle to a "golden" override on top of current variant
      if (golden) {
        const tx = document.querySelector('.tweaks');
        tx?.classList.add('golden');
      }
    }
  });

  // ───── tweaks panel: hidden by default, toggles via gear icon ─────
  const panel = document.getElementById('tweaks');
  const gear = document.getElementById('gearBtn');
  const closeBtn = document.getElementById('tweaksClose');
  function setPanel(open) {
    panel.classList.toggle('hidden', !open);
    gear?.classList.toggle('active', open);
  }
  gear?.addEventListener('click', e => { e.stopPropagation(); setPanel(panel.classList.contains('hidden')); });
  closeBtn?.addEventListener('click', () => setPanel(false));
  document.addEventListener('click', e => {
    if (!panel.classList.contains('hidden') && !panel.contains(e.target) && e.target !== gear && !gear.contains(e.target)) setPanel(false);
  });

  // initial defaults: Glow 40 %, Fog 50 %, Particles 50 %
  setTimeout(() => {
    window.PortalEngine?.setBloom(0.40);
    window.PortalEngine?.setFog(0.50);
    window.PortalEngine?.setParticles(0.50);
  }, 100);

  // ───── tweaks panel wiring ─────
  const opts = document.querySelectorAll('.tweaks .opt');
  opts.forEach(b => b.addEventListener('click', () => {
    opts.forEach(o => o.classList.remove('active'));
    b.classList.add('active');
    window.PortalEngine?.setVariant(b.dataset.variant);
  }));

  const fog = document.getElementById('fog');
  fog.addEventListener('input', () => window.PortalEngine?.setFog(+fog.value / 100));

  const dens = document.getElementById('density');
  dens.addEventListener('input', () => window.PortalEngine?.setParticles(+dens.value / 100));

  const bl = document.getElementById('bloom');
  bl.addEventListener('input', () => window.PortalEngine?.setBloom(+bl.value / 100));

  const par = document.getElementById('parallax');
  par.addEventListener('click', () => {
    par.classList.toggle('on');
    window.PortalEngine?.setParallax(par.classList.contains('on'));
  });

  // ───── fluid color-morph canvas (procedural metaball that mimics a video transition) ─────
  const fluidCanvas = document.getElementById('warpFluid');
  let fluidCtx, fluidRaf, fluidStart, fluidActive = false;
  function resizeFluid() {
    if (!fluidCanvas) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    fluidCanvas.width = innerWidth * dpr;
    fluidCanvas.height = innerHeight * dpr;
    fluidCtx = fluidCanvas.getContext('2d');
    fluidCtx.scale(dpr, dpr);
  }
  resizeFluid();
  window.addEventListener('resize', resizeFluid);
  function startFluidWarp(world, c1, c2) {
    if (!fluidCtx) return;
    fluidStart = performance.now();
    fluidActive = true;
    cancelAnimationFrame(fluidRaf);
    const blobs = [];
    for (let i = 0; i < 14; i++) {
      blobs.push({
        a: Math.random() * Math.PI * 2,
        r: 80 + Math.random() * 240,
        s: 0.4 + Math.random() * 1.2,
        c: Math.random() < 0.5 ? c1 : c2,
        ph: Math.random() * 6.28,
      });
    }
    const draw = () => {
      const t = (performance.now() - fluidStart) / 1000;
      const w = innerWidth, h = innerHeight, cx = w / 2, cy = h * 0.52;
      fluidCtx.clearRect(0, 0, w, h);
      fluidCtx.globalCompositeOperation = 'screen';
      blobs.forEach(b => {
        const dist = b.r * (1 + t * b.s * 0.9);
        const x = cx + Math.cos(b.a + t * 0.6 + b.ph) * dist;
        const y = cy + Math.sin(b.a + t * 0.45 + b.ph) * dist * 0.7;
        const rad = 220 + Math.sin(t * 2 + b.ph) * 60 + t * 80;
        const g = fluidCtx.createRadialGradient(x, y, 0, x, y, rad);
        g.addColorStop(0, b.c + 'ff');
        g.addColorStop(0.4, b.c + '88');
        g.addColorStop(1, b.c + '00');
        fluidCtx.fillStyle = g;
        fluidCtx.beginPath();
        fluidCtx.arc(x, y, rad, 0, Math.PI * 2);
        fluidCtx.fill();
      });
      // central column accelerating outward
      const colRad = 100 + t * 600;
      const cg = fluidCtx.createRadialGradient(cx, cy, 0, cx, cy, colRad);
      cg.addColorStop(0, '#ffffffcc');
      cg.addColorStop(0.3, c1 + 'aa');
      cg.addColorStop(1, c2 + '00');
      fluidCtx.fillStyle = cg;
      fluidCtx.beginPath(); fluidCtx.arc(cx, cy, colRad, 0, Math.PI * 2); fluidCtx.fill();
      if (fluidActive && t < 4) fluidRaf = requestAnimationFrame(draw);
    };
    draw();
  }
  function stopFluidWarp() { fluidActive = false; cancelAnimationFrame(fluidRaf); if (fluidCtx) fluidCtx.clearRect(0, 0, innerWidth, innerHeight); }

  // ───── back from warp ─────
  document.getElementById('warpBack')?.addEventListener('click', () => {
    const warp = document.getElementById('warp');
    warp.classList.remove('on', 'video-on', 'streaking', 'bursting', 'entering', 'flash', 'inside', 'arrived');
    const v = document.getElementById('warpVideo'); if (v) { try { v.pause(); v.removeAttribute('src'); v.load(); } catch (_) {} }
    stopFluidWarp();
    document.body.classList.remove('warping');
    window.PortalEngine?.resetCamera();
    // restore variant colors
    const active = document.querySelector('.tweaks .opt.active');
    if (active) window.PortalEngine?.setVariant(active.dataset.variant);
  });

  // ───── tilt the wordmark with parallax ─────
  let tx = 0, ty = 0, cx = 0, cy = 0;
  const wm = document.querySelector('.wordmark');
  window.addEventListener('mousemove', e => {
    tx = (e.clientX / innerWidth - 0.5) * 2;
    ty = (e.clientY / innerHeight - 0.5) * 2;
  });
  function tilt() {
    cx += (tx - cx) * 0.08;
    cy += (ty - cy) * 0.08;
    if (wm) wm.style.transform = `perspective(800px) rotateY(${cx * 4}deg) rotateX(${-cy * 3}deg)`;
    requestAnimationFrame(tilt);
  }
  tilt();
})();
