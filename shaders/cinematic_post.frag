#version 460 core
#include <flutter/runtime_effect.glsl>

// Kaninchenbau Cinema-Postprocessing — Single-Pass:
//   Chromatic Aberration + Approx-Bloom + Vignette + Film-Grain.
// Uniforms werden in cinematic_post_process.dart in dieser Reihenfolge gesetzt.

precision mediump float;

uniform vec2 uSize;        // 0,1  Aufloesung in Pixeln
uniform float uTime;       // 2    Sekunden (fuer animiertes Korn)
uniform float uIntensity;  // 3    Master 0..1 (Qualitaetsstufe)
uniform float uGrain;      // 4    Film-Grain Staerke 0..1
uniform float uAberration; // 5    Chromatic Aberration 0..1
uniform float uBloom;      // 6    Bloom 0..1
uniform float uVignette;   // 7    Vignette 0..1
uniform float uSharpen;    // 8    Unsharp-Mask / Detail 0..1 (Fotorealismus)
uniform sampler2D uTexture;// Sampler 0  (der gerenderte Inhalt)

out vec4 fragColor;

// Cheap hash-noise fuer Film-Grain.
float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

void main() {
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / uSize;
  vec2 centered = uv - 0.5;
  float dist = length(centered);

  // ── Chromatic Aberration: Versatz waechst zum Rand hin ──
  float ca = uAberration * uIntensity * 0.004 * (0.2 + dist * 1.8);
  vec2 dir = normalize(centered + vec2(1e-5));
  vec3 col;
  col.r = texture(uTexture, uv + dir * ca).r;
  col.g = texture(uTexture, uv).g;
  col.b = texture(uTexture, uv - dir * ca).b;

  // ── 4-Tap Nachbarschaft (geteilt fuer Bloom + Unsharp-Mask) ──
  vec2 px = 1.0 / uSize;
  vec3 neigh = vec3(0.0);
  neigh += texture(uTexture, uv + vec2(px.x, px.y) * 1.5).rgb;
  neigh += texture(uTexture, uv + vec2(-px.x, px.y) * 1.5).rgb;
  neigh += texture(uTexture, uv + vec2(px.x, -px.y) * 1.5).rgb;
  neigh += texture(uTexture, uv + vec2(-px.x, -px.y) * 1.5).rgb;
  neigh *= 0.25;

  // ── Unsharp-Mask: Detail/Schaerfe fuer fotorealistischen Look ──
  // col + (col - blur) * amount  -> hebt Kanten/Mikrokontrast an.
  col += (col - neigh) * (uSharpen * uIntensity * 1.1);

  // ── Approx-Bloom: heller Bright-Pass, additiv ──
  if (uBloom > 0.0) {
    vec3 b = neigh;
    float s = 1.5 + uBloom * 2.5;
    b += texture(uTexture, uv + vec2(px.x, px.y) * s).rgb;
    b += texture(uTexture, uv + vec2(-px.x, -px.y) * s).rgb;
    b *= (1.0 / 3.0);
    float lum = dot(b, vec3(0.299, 0.587, 0.114));
    float bright = smoothstep(0.6, 1.0, lum);
    col += b * bright * uBloom * uIntensity * 0.6;
  }

  // ── Vignette ──
  float vig = smoothstep(0.85, 0.35, dist);
  col *= mix(1.0, vig, uVignette * uIntensity * 0.9);

  // ── Film-Grain ──
  float g = hash(uv * uSize * 0.5 + vec2(uTime * 60.0)) - 0.5;
  col += g * uGrain * uIntensity * 0.09;

  fragColor = vec4(col, 1.0);
}
