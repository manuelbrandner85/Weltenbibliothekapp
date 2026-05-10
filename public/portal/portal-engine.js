// Weltenbibliothek · Cinematic Portal Engine
// Three.js scene: volumetric nebula + iridescent core + GPU starfield + bloom
import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { FilmPass } from 'three/addons/postprocessing/FilmPass.js';

const canvas = document.getElementById('gl');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false, powerPreference: 'high-performance' });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.05;
renderer.setSize(innerWidth, innerHeight);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x000004);
const camera = new THREE.PerspectiveCamera(45, innerWidth / innerHeight, 0.1, 200);
camera.position.set(0, 0, 7);

// ───── shared GLSL noise ─────
const NOISE_GLSL = `
vec3 mod289(vec3 x){return x-floor(x*(1./289.))*289.;}
vec4 mod289(vec4 x){return x-floor(x*(1./289.))*289.;}
vec4 permute(vec4 x){return mod289(((x*34.)+1.)*x);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159-0.85373472095314*r;}
float snoise(vec3 v){
  const vec2 C=vec2(1./6.,1./3.); const vec4 D=vec4(0.,.5,1.,2.);
  vec3 i=floor(v+dot(v,C.yyy)); vec3 x0=v-i+dot(i,C.xxx);
  vec3 g=step(x0.yzx,x0.xyz); vec3 l=1.-g;
  vec3 i1=min(g.xyz,l.zxy); vec3 i2=max(g.xyz,l.zxy);
  vec3 x1=x0-i1+C.xxx; vec3 x2=x0-i2+C.yyy*2.; vec3 x3=x0-D.yyy;
  i=mod289(i);
  vec4 p=permute(permute(permute(i.z+vec4(0.,i1.z,i2.z,1.))+i.y+vec4(0.,i1.y,i2.y,1.))+i.x+vec4(0.,i1.x,i2.x,1.));
  float n_=0.142857142857; vec3 ns=n_*D.wyz-D.xzx;
  vec4 j=p-49.*floor(p*ns.z*ns.z);
  vec4 x_=floor(j*ns.z); vec4 y_=floor(j-7.*x_);
  vec4 x=x_*ns.x+ns.yyyy; vec4 y=y_*ns.x+ns.yyyy; vec4 h=1.-abs(x)-abs(y);
  vec4 b0=vec4(x.xy,y.xy); vec4 b1=vec4(x.zw,y.zw);
  vec4 s0=floor(b0)*2.+1.; vec4 s1=floor(b1)*2.+1.; vec4 sh=-step(h,vec4(0.));
  vec4 a0=b0.xzyw+s0.xzyw*sh.xxyy; vec4 a1=b1.xzyw+s1.xzyw*sh.zzww;
  vec3 p0=vec3(a0.xy,h.x); vec3 p1=vec3(a0.zw,h.y); vec3 p2=vec3(a1.xy,h.z); vec3 p3=vec3(a1.zw,h.w);
  vec4 norm=taylorInvSqrt(vec4(dot(p0,p0),dot(p1,p1),dot(p2,p2),dot(p3,p3)));
  p0*=norm.x; p1*=norm.y; p2*=norm.z; p3*=norm.w;
  vec4 m=max(.6-vec4(dot(x0,x0),dot(x1,x1),dot(x2,x2),dot(x3,x3)),0.); m=m*m;
  return 42.*dot(m*m,vec4(dot(p0,x0),dot(p1,x1),dot(p2,x2),dot(p3,x3)));
}
float fbm(vec3 p){float v=0.,a=.5; for(int i=0;i<5;i++){v+=a*snoise(p);p*=2.07;a*=.5;} return v;}
`;

// ───── nebula sky (a giant inverted sphere with fragment-shaded volumetric look) ─────
const nebulaUniforms = {
  uTime:    { value: 0 },
  uColorA:  { value: new THREE.Color(0x1a3a8a) },  // deep blue
  uColorB:  { value: new THREE.Color(0x6b1fa8) },  // royal purple
  uColorC:  { value: new THREE.Color(0xff5ec4) },  // accent magenta
  uDensity: { value: 0.62 },
  uMode:    { value: 0 },  // 0 cosmic / 1 geometry / 2 aurora
};
const nebulaMat = new THREE.ShaderMaterial({
  side: THREE.BackSide,
  uniforms: nebulaUniforms,
  vertexShader: `varying vec3 vWorldPos; void main(){ vec4 wp=modelMatrix*vec4(position,1.); vWorldPos=wp.xyz; gl_Position=projectionMatrix*viewMatrix*wp; }`,
  fragmentShader: `
    varying vec3 vWorldPos;
    uniform float uTime, uDensity; uniform int uMode;
    uniform vec3 uColorA, uColorB, uColorC;
    ${NOISE_GLSL}
    void main(){
      vec3 d=normalize(vWorldPos);
      float t=uTime*0.025;
      vec3 q=d*1.6 + vec3(t,-t*0.6,t*0.4);
      float n=fbm(q);
      float n2=fbm(q*2.4 + vec3(0.,0.,t*1.2));
      float n3=fbm(q*0.6 - vec3(t*0.3,0.,0.));
      float clouds=smoothstep(0.05,0.85, n*0.55 + n2*0.35 + n3*0.25);
      vec3 col=mix(uColorA*0.18, uColorB*0.55, clouds);
      col += uColorC * pow(clouds,3.) * 0.6;
      // tiny stars by noise
      float starN=snoise(d*220.);
      float stars=smoothstep(0.985,1.,starN);
      col += vec3(stars)*1.4;
      // aurora prismatic shimmer
      if(uMode==2){
        float sh=fbm(q*3. + vec3(t*1.4));
        vec3 prism=vec3(sin(sh*6.+0.),sin(sh*6.+2.094),sin(sh*6.+4.188))*0.5+0.5;
        col=mix(col,prism*0.8 + col*0.4, smoothstep(0.4,0.95,clouds));
      }
      // geometry mode: dim nebula, sharper stars
      if(uMode==1){
        col*=0.6; col += vec3(stars)*0.8;
      }
      // radial darkening at edges to feel like deep field
      float edge=smoothstep(0.0,0.7, length(d.xy));
      col*=mix(1.2, 0.5, edge);
      col*=uDensity*1.1+0.2;
      gl_FragColor=vec4(col,1.);
    }
  `,
});
const nebula = new THREE.Mesh(new THREE.SphereGeometry(80, 64, 48), nebulaMat);
scene.add(nebula);

// ───── core portal sphere (iridescent, displaced) ─────
const coreUniforms = {
  uTime:    { value: 0 },
  uColorA:  { value: new THREE.Color(0x4a90ff) },
  uColorB:  { value: new THREE.Color(0xc966ff) },
  uColorC:  { value: new THREE.Color(0xfff0c8) },
  uDistort: { value: 0.28 },
  uMode:    { value: 0 },
  uPulse:   { value: 0 },
};
const coreMat = new THREE.ShaderMaterial({
  uniforms: coreUniforms,
  vertexShader: `
    varying vec3 vN; varying vec3 vWorldPos; varying vec3 vView;
    uniform float uTime, uDistort;
    ${NOISE_GLSL}
    void main(){
      vec3 p=position;
      float n=snoise(p*1.6 + uTime*0.45);
      float n2=snoise(p*3.5 - uTime*0.6);
      p += normal * (n*0.45 + n2*0.18) * uDistort;
      vec4 wp=modelMatrix*vec4(p,1.);
      vWorldPos=wp.xyz;
      vN=normalize(normalMatrix*normal);
      vView=normalize(cameraPosition - wp.xyz);
      gl_Position=projectionMatrix*viewMatrix*wp;
    }
  `,
  fragmentShader: `
    varying vec3 vN; varying vec3 vWorldPos; varying vec3 vView;
    uniform float uTime, uPulse; uniform int uMode;
    uniform vec3 uColorA, uColorB, uColorC;
    ${NOISE_GLSL}
    void main(){
      float fres=pow(1.-max(dot(vN,vView),0.0),2.0);
      float n=fbm(vWorldPos*1.4 + uTime*0.3);
      vec3 base=mix(uColorA, uColorB, smoothstep(-0.4,0.6,n));
      // hot core
      base += uColorC * pow(fres,3.0) * 1.4;
      // iridescent shimmer
      float ir=sin(n*6. + uTime*0.8)*0.5+0.5;
      vec3 shift=vec3(sin(ir*6.28+0.0),sin(ir*6.28+2.094),sin(ir*6.28+4.188))*0.5+0.5;
      base=mix(base, shift*1.1, fres*0.55);
      base += pow(fres,1.4)*0.6;
      // mode tweaks
      if(uMode==1){ base = mix(base, vec3(0.95,0.92,1.0), fres*0.7); }
      if(uMode==2){ base += vec3(0.4,0.7,0.3) * sin(n*7.+uTime)*0.25; }
      base *= 1. + uPulse*0.6;
      gl_FragColor=vec4(base, 0.92);
    }
  `,
  transparent: true,
});
const core = new THREE.Mesh(new THREE.IcosahedronGeometry(1.05, 6), coreMat);
core.position.set(0, 0.1, 0);
scene.add(core);

// ───── twin planet system: MATERIE (blue) + ENERGIE (purple) ─────
// (replaces single core; clearly shows the two-worlds duality, hyperreal)
const planetsGroup = new THREE.Group();
planetsGroup.position.set(0, 0.1, 0);
scene.add(planetsGroup);

function makePlanet({ radius, base, deep, atmo, hot, axisTilt, mode }) {
  const u = {
    uTime:    { value: 0 },
    uBase:    { value: new THREE.Color(base) },
    uDeep:    { value: new THREE.Color(deep) },
    uHot:     { value: new THREE.Color(hot) },
    uAtmo:    { value: new THREE.Color(atmo) },
    uMode:    { value: mode },
    uLightDir:{ value: new THREE.Vector3(0.6, 0.4, 0.7).normalize() },
    uPulse:   { value: 0 },
  };
  const surfMat = new THREE.ShaderMaterial({
    uniforms: u,
    vertexShader: `
      varying vec3 vN; varying vec3 vWorldPos; varying vec3 vView; varying vec3 vLocal;
      void main(){
        vLocal = position;
        vec4 wp = modelMatrix * vec4(position,1.);
        vWorldPos = wp.xyz;
        vN = normalize(mat3(modelMatrix) * normal);
        vView = normalize(cameraPosition - wp.xyz);
        gl_Position = projectionMatrix * viewMatrix * wp;
      }
    `,
    fragmentShader: `
      varying vec3 vN; varying vec3 vWorldPos; varying vec3 vView; varying vec3 vLocal;
      uniform float uTime, uPulse; uniform int uMode;
      uniform vec3 uBase, uDeep, uHot, uAtmo, uLightDir;
      ${NOISE_GLSL}
      void main(){
        // surface continents / storm bands via fbm
        vec3 q = vLocal * 1.3 + vec3(uTime*0.04, 0., 0.);
        float c = fbm(q*1.4);
        float c2 = fbm(q*3.5 + vec3(0., uTime*0.06, 0.));
        float continents = smoothstep(-0.05, 0.45, c + c2*0.35);
        // storm/cloud band
        float bands = sin(vLocal.y*8.0 + c2*4.0)*0.5+0.5;
        bands = smoothstep(0.4, 0.9, bands) * 0.6;
        vec3 surface = mix(uDeep*0.9, uBase, continents);
        surface = mix(surface, uHot*0.9, bands * (uMode==1 ? 0.7 : 0.4));
        // day-night lambert
        float lambert = max(dot(normalize(vN), normalize(uLightDir)), 0.0);
        float terminator = smoothstep(0.0, 0.18, lambert);
        vec3 night = uDeep * 0.06;
        // city lights on dark side following continents
        float cities = smoothstep(0.6, 0.9, continents) * (1.0 - lambert) * 0.9;
        vec3 col = mix(night + uHot*cities*0.6, surface * (0.18 + 0.95*lambert), terminator);
        // limb fresnel atmosphere glow
        float fres = pow(1.0 - max(dot(vN, vView), 0.0), 2.6);
        col += uAtmo * fres * 1.4;
        col += uAtmo * pow(fres, 5.0) * 2.2;
        // hot core pulse
        col += uBase * uPulse * 0.8;
        gl_FragColor = vec4(col, 1.);
      }
    `,
  });
  const mesh = new THREE.Mesh(new THREE.IcosahedronGeometry(radius, 5), surfMat);
  mesh.rotation.z = axisTilt;

  // atmosphere shell
  const atmoMat = new THREE.ShaderMaterial({
    uniforms: u,
    vertexShader: `varying vec3 vN; varying vec3 vView;
      void main(){ vec4 wp=modelMatrix*vec4(position,1.); vN=normalize(mat3(modelMatrix)*normal); vView=normalize(cameraPosition-wp.xyz); gl_Position=projectionMatrix*viewMatrix*wp; }`,
    fragmentShader: `varying vec3 vN; varying vec3 vView; uniform vec3 uAtmo; uniform float uPulse;
      void main(){ float f=pow(1.-max(dot(vN,vView),0.),3.0); gl_FragColor=vec4(uAtmo*(f*1.6 + uPulse*0.3), f*0.85); }`,
    transparent: true, blending: THREE.AdditiveBlending, side: THREE.BackSide, depthWrite: false,
  });
  const atmosphere = new THREE.Mesh(new THREE.SphereGeometry(radius * 1.18, 48, 36), atmoMat);

  // cloud layer (semi-transparent)
  const cloudMat = new THREE.ShaderMaterial({
    uniforms: u,
    vertexShader: `varying vec3 vL; varying vec3 vN; varying vec3 vView;
      void main(){ vL=position; vec4 wp=modelMatrix*vec4(position,1.); vN=normalize(mat3(modelMatrix)*normal); vView=normalize(cameraPosition-wp.xyz); gl_Position=projectionMatrix*viewMatrix*wp; }`,
    fragmentShader: `varying vec3 vL; varying vec3 vN; varying vec3 vView; uniform float uTime; uniform vec3 uLightDir;
      ${NOISE_GLSL}
      void main(){ float n=fbm(vL*2.6 + vec3(uTime*0.05,0.,uTime*0.02));
        float a=smoothstep(0.05,0.55,n)*0.55;
        float lambert=max(dot(normalize(vN),normalize(uLightDir)),0.05);
        gl_FragColor=vec4(vec3(0.95,0.97,1.)*lambert, a); }`,
    transparent: true, depthWrite: false,
  });
  const clouds = new THREE.Mesh(new THREE.SphereGeometry(radius * 1.025, 64, 48), cloudMat);

  const group = new THREE.Group();
  group.add(mesh); group.add(clouds); group.add(atmosphere);
  group.userData = { uniforms: u, surface: mesh, clouds, atmosphere };
  return group;
}

const PLANET_R = 0.55;
const ORBIT_R = 1.35;
const materiePlanet = makePlanet({
  radius: PLANET_R, base: 0x4a90ff, deep: 0x0a1a3a, hot: 0xfff0c8, atmo: 0x6aa0ff, axisTilt: 0.32, mode: 0,
});
const energiePlanet = makePlanet({
  radius: PLANET_R, base: 0xc966ff, deep: 0x2a0a4a, hot: 0xffa0e8, atmo: 0xb98aff, axisTilt: -0.4, mode: 0,
});
planetsGroup.add(materiePlanet);
planetsGroup.add(energiePlanet);

// connecting ribbon of energy between planets
const ribbonMat = new THREE.ShaderMaterial({
  uniforms: { uTime: { value: 0 }, uA: { value: new THREE.Color(0x6aa0ff) }, uB: { value: new THREE.Color(0xc966ff) } },
  vertexShader: `varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.); }`,
  fragmentShader: `varying vec2 vUv; uniform float uTime; uniform vec3 uA, uB;
    ${NOISE_GLSL}
    void main(){
      float y=abs(vUv.y-0.5)*2.;
      float n=snoise(vec3(vUv.x*8., uTime*0.6, 0.))*0.18;
      float band=smoothstep(0.5+n,0.0,y);
      vec3 col=mix(uA, uB, vUv.x);
      gl_FragColor=vec4(col*band*1.4, band*0.85);
    }`,
  transparent: true, blending: THREE.AdditiveBlending, depthWrite: false,
});
const ribbon = new THREE.Mesh(new THREE.PlaneGeometry(2 * ORBIT_R + 0.2, 0.18, 64, 1), ribbonMat);
planetsGroup.add(ribbon);

// REPLACE old single core / innerCore — twin planets above are the new portal
core_legacy_remove: {
  scene.remove(core);
}

// halo glow billboard
const haloMat = new THREE.ShaderMaterial({
  uniforms: { uTime: { value: 0 }, uColorA: coreUniforms.uColorA, uColorB: coreUniforms.uColorB, uPulse: coreUniforms.uPulse },
  vertexShader: `varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.); }`,
  fragmentShader: `
    varying vec2 vUv; uniform float uTime, uPulse; uniform vec3 uColorA, uColorB;
    void main(){
      vec2 c=vUv-0.5; float r=length(c);
      float g=exp(-r*8.5)*0.9 + exp(-r*3.0)*0.35;
      vec3 col=mix(uColorB, uColorA, sin(uTime*0.4 + r*4.)*0.5+0.5);
      gl_FragColor=vec4(col*g*(1.0+uPulse*0.8), g);
    }
  `,
  transparent: true, blending: THREE.AdditiveBlending, depthWrite: false,
});
const halo = new THREE.Mesh(new THREE.PlaneGeometry(8, 8), haloMat);
halo.position.set(0, 0.1, -0.4);
scene.add(halo);

// ───── sacred geometry rings (visible only in geometry mode) ─────
const ringsGroup = new THREE.Group(); ringsGroup.visible = false; scene.add(ringsGroup);
function makeRing(r, w, color, dashed) {
  const segs = 256;
  const pts = [];
  for (let i = 0; i <= segs; i++) { const a = (i / segs) * Math.PI * 2; pts.push(new THREE.Vector3(Math.cos(a) * r, Math.sin(a) * r, 0)); }
  const geom = new THREE.BufferGeometry().setFromPoints(pts);
  const mat = dashed
    ? new THREE.LineDashedMaterial({ color, dashSize: 0.08, gapSize: 0.06, transparent: true, opacity: 0.7, linewidth: w })
    : new THREE.LineBasicMaterial({ color, transparent: true, opacity: 0.85, linewidth: w });
  const l = new THREE.Line(geom, mat);
  if (dashed) l.computeLineDistances();
  return l;
}
ringsGroup.add(makeRing(1.7, 1, 0xa6c1ff, false));
ringsGroup.add(makeRing(2.0, 1, 0xc99cff, true));
ringsGroup.add(makeRing(2.35, 1, 0xfff0c8, false));
const r4 = makeRing(2.7, 1, 0xa6c1ff, true); ringsGroup.add(r4);
// hexagram
const hexGeom = new THREE.BufferGeometry();
const hp = []; for (let i = 0; i < 7; i++) { const a = (i / 6) * Math.PI * 2 + Math.PI / 2; hp.push(Math.cos(a) * 1.45, Math.sin(a) * 1.45, 0); } hp.push(hp[0], hp[1], hp[2]);
hexGeom.setAttribute('position', new THREE.Float32BufferAttribute(hp, 3));
const hex = new THREE.Line(hexGeom, new THREE.LineBasicMaterial({ color: 0xfff0c8, transparent: true, opacity: 0.65 }));
ringsGroup.add(hex);

// ───── star field (instanced points) ─────
function makeStars(count, range, sizeMin, sizeMax) {
  const g = new THREE.BufferGeometry();
  const pos = new Float32Array(count * 3);
  const col = new Float32Array(count * 3);
  const sz = new Float32Array(count);
  const seed = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    pos[i * 3] = (Math.random() - 0.5) * range;
    pos[i * 3 + 1] = (Math.random() - 0.5) * range * 0.7;
    pos[i * 3 + 2] = -Math.random() * range * 0.6 - 1;
    const tone = Math.random();
    if (tone < 0.5) { col[i*3]=0.95; col[i*3+1]=0.97; col[i*3+2]=1.0; }
    else if (tone < 0.8) { col[i*3]=0.7; col[i*3+1]=0.78; col[i*3+2]=1.0; }
    else { col[i*3]=1.0; col[i*3+1]=0.78; col[i*3+2]=0.6; }
    sz[i] = sizeMin + Math.random() * (sizeMax - sizeMin);
    seed[i] = Math.random() * 100;
  }
  g.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  g.setAttribute('color', new THREE.BufferAttribute(col, 3));
  g.setAttribute('aSize', new THREE.BufferAttribute(sz, 1));
  g.setAttribute('aSeed', new THREE.BufferAttribute(seed, 1));
  return g;
}
const starsUniforms = { uTime: { value: 0 }, uPixel: { value: renderer.getPixelRatio() } };
const starsMat = new THREE.ShaderMaterial({
  uniforms: starsUniforms,
  vertexShader: `
    attribute float aSize; attribute float aSeed; varying vec3 vCol; varying float vTwinkle;
    uniform float uTime, uPixel;
    void main(){
      vCol=color;
      vec4 mv=modelViewMatrix*vec4(position,1.);
      float tw=sin(uTime*1.6 + aSeed*6.28)*0.5+0.5;
      vTwinkle=tw;
      gl_PointSize=aSize*uPixel*(0.55+tw*0.85)*(180./-mv.z);
      gl_Position=projectionMatrix*mv;
    }
  `,
  fragmentShader: `
    varying vec3 vCol; varying float vTwinkle;
    void main(){
      vec2 c=gl_PointCoord-0.5; float d=length(c);
      float a=smoothstep(0.5,0.0,d);
      // diffraction spike
      float spk=max(0., 1.0-abs(c.x)*40.) * smoothstep(0.5,0.,abs(c.y));
      spk += max(0., 1.0-abs(c.y)*40.) * smoothstep(0.5,0.,abs(c.x));
      float v=a + spk*0.6*vTwinkle;
      gl_FragColor=vec4(vCol*v, v);
    }
  `,
  vertexColors: true, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
});
const stars = new THREE.Points(makeStars(1800, 80, 1.4, 4.0), starsMat);
scene.add(stars);

// foreground drift particles (small dust)
const dustUniforms = { uTime: { value: 0 }, uColor: { value: new THREE.Color(0xc5b8ff) }, uPixel: { value: renderer.getPixelRatio() } };
const dustMat = new THREE.ShaderMaterial({
  uniforms: dustUniforms,
  vertexShader: `
    attribute float aSize; attribute float aSeed; varying float vA;
    uniform float uTime, uPixel;
    void main(){
      vec3 p=position;
      p.y += mod(uTime*0.25 + aSeed*10., 18.) - 9.;
      p.x += sin(uTime*0.4 + aSeed*4.)*0.4;
      vec4 mv=modelViewMatrix*vec4(p,1.);
      vA=smoothstep(0.,1., 1.-abs(mv.y)/9.);
      gl_PointSize=aSize*uPixel*(160./-mv.z);
      gl_Position=projectionMatrix*mv;
    }
  `,
  fragmentShader: `
    uniform vec3 uColor; varying float vA;
    void main(){
      vec2 c=gl_PointCoord-0.5; float d=length(c);
      float a=smoothstep(0.5,0.0,d)*vA*0.55;
      gl_FragColor=vec4(uColor*a, a);
    }
  `,
  transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
});
const dust = new THREE.Points(makeStars(600, 18, 0.6, 2.2), dustMat);
scene.add(dust);

// god-ray plane behind core (cheap volumetric look)
const rayUniforms = { uTime: { value: 0 }, uColor: { value: new THREE.Color(0x9c8fff) }, uIntensity: { value: 0.55 } };
const rayMat = new THREE.ShaderMaterial({
  uniforms: rayUniforms,
  vertexShader: `varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.); }`,
  fragmentShader: `
    varying vec2 vUv; uniform float uTime, uIntensity; uniform vec3 uColor;
    void main(){
      vec2 c=vUv-0.5;
      float a=atan(c.y,c.x);
      float r=length(c);
      float rays=pow(0.5+0.5*sin(a*36. + uTime*0.4)*sin(a*7.-uTime*0.2),3.);
      rays *= smoothstep(0.6,0.0,r);
      gl_FragColor=vec4(uColor * rays * uIntensity, rays*uIntensity*0.8);
    }
  `,
  transparent: true, blending: THREE.AdditiveBlending, depthWrite: false,
});
const rays = new THREE.Mesh(new THREE.PlaneGeometry(10, 10), rayMat);
rays.position.set(0, 0.1, -1.2);
scene.add(rays);

// ───── post-processing ─────
const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const bloom = new UnrealBloomPass(new THREE.Vector2(innerWidth, innerHeight), 0.95, 0.85, 0.18);
composer.addPass(bloom);
const film = new FilmPass(0.18, false);
composer.addPass(film);

// chromatic aberration
const chromPass = new ShaderPass({
  uniforms: { tDiffuse: { value: null }, uAmount: { value: 0.0014 } },
  vertexShader: `varying vec2 vUv; void main(){ vUv=uv; gl_Position=vec4(position,1.); }`,
  fragmentShader: `
    uniform sampler2D tDiffuse; uniform float uAmount; varying vec2 vUv;
    void main(){
      vec2 d=(vUv-0.5);
      float r=texture2D(tDiffuse, vUv - d*uAmount).r;
      float g=texture2D(tDiffuse, vUv).g;
      float b=texture2D(tDiffuse, vUv + d*uAmount).b;
      gl_FragColor=vec4(r,g,b,1.);
    }
  `,
});
composer.addPass(chromPass);

// ───── interaction state ─────
const state = { mx: 0, my: 0, tmx: 0, tmy: 0, parallax: true, mode: 0, density: 0.62, particles: 0.55, bloom: 0.68, pulse: 0, pulseTarget: 0 };
window.addEventListener('mousemove', e => {
  state.tmx = (e.clientX / innerWidth - 0.5) * 2;
  state.tmy = (e.clientY / innerHeight - 0.5) * 2;
});
window.addEventListener('touchmove', e => {
  if (!e.touches[0]) return;
  state.tmx = (e.touches[0].clientX / innerWidth - 0.5) * 2;
  state.tmy = (e.touches[0].clientY / innerHeight - 0.5) * 2;
}, { passive: true });

window.addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
  composer.setSize(innerWidth, innerHeight);
  bloom.setSize(innerWidth, innerHeight);
});

window.PortalEngine = {
  setVariant(v) {
    const m = v === 'cosmic' ? 0 : v === 'geometry' ? 1 : 2;
    state.mode = m;
    nebulaUniforms.uMode.value = m;
    coreUniforms.uMode.value = m;
    ringsGroup.visible = (m === 1);
    if (m === 0) {
      nebulaUniforms.uColorA.value.setHex(0x1a3a8a);
      nebulaUniforms.uColorB.value.setHex(0x6b1fa8);
      nebulaUniforms.uColorC.value.setHex(0xff5ec4);
      coreUniforms.uColorA.value.setHex(0x4a90ff);
      coreUniforms.uColorB.value.setHex(0xc966ff);
      rayUniforms.uColor.value.setHex(0x9c8fff);
    } else if (m === 1) {
      nebulaUniforms.uColorA.value.setHex(0x0a1a3a);
      nebulaUniforms.uColorB.value.setHex(0x2a1a4a);
      nebulaUniforms.uColorC.value.setHex(0xfff0c8);
      coreUniforms.uColorA.value.setHex(0xfff0c8);
      coreUniforms.uColorB.value.setHex(0xa78bfa);
      rayUniforms.uColor.value.setHex(0xfff0c8);
    } else {
      nebulaUniforms.uColorA.value.setHex(0x0a3a3a);
      nebulaUniforms.uColorB.value.setHex(0x6b1fa8);
      nebulaUniforms.uColorC.value.setHex(0x40ffd0);
      coreUniforms.uColorA.value.setHex(0x40ffd0);
      coreUniforms.uColorB.value.setHex(0xff5ec4);
      rayUniforms.uColor.value.setHex(0x40ffd0);
    }
  },
  setFog(v)       { state.density = v; nebulaUniforms.uDensity.value = v; },
  setParticles(v) { state.particles = v; stars.visible = v > 0.05; dust.visible = v > 0.05; starsMat.opacity = v; },
  setBloom(v)     { state.bloom = v; bloom.strength = 0.4 + v * 1.4; },
  setParallax(on) { state.parallax = on; if (!on) { state.tmx = 0; state.tmy = 0; } },
  pulse() { state.pulseTarget = 1; setTimeout(() => state.pulseTarget = 0, 180); },
  warp(world, onArrive) {
    if (state.warping) return;
    state.warping = true;
    state.world = world;
    const c1 = world === 'materie' ? new THREE.Color(0x4a90ff) : new THREE.Color(0xc966ff);
    const c2 = world === 'materie' ? new THREE.Color(0x0a2452) : new THREE.Color(0x3b0d6e);
    state.warpFrom = camera.position.z;
    state.warpStart = clock.getElapsedTime();
    state.warpC1 = c1; state.warpC2 = c2;
    state.warpPhase = null;
    state.onArrive = onArrive;
  },
  resetCamera() {
    state.warping = false;
    state.warpPhase = null;
    camera.position.set(0, 0, 7);
    camera.fov = 45;
    camera.up.set(0, 1, 0);
    camera.updateProjectionMatrix();
    bloom.strength = 0.4 + state.bloom * 1.4;
    bloom.radius = 0.85;
    chromPass.uniforms.uAmount.value = 0.0014;
    starsMat.uniforms.uPixel.value = renderer.getPixelRatio();
    coreUniforms.uPulse.value = 0;
    if (film.uniforms?.nIntensity) film.uniforms.nIntensity.value = 0.18;
    materiePlanet.scale.setScalar(1); energiePlanet.scale.setScalar(1);
  },
};

// ───── animation loop ─────
const clock = new THREE.Clock();
function tick() {
  const dt = clock.getDelta();
  const t = clock.getElapsedTime();

  nebulaUniforms.uTime.value = t;
  coreUniforms.uTime.value = t;
  haloMat.uniforms.uTime.value = t;
  starsUniforms.uTime.value = t;
  dustUniforms.uTime.value = t;
  rayUniforms.uTime.value = t;

  // pulse decay
  state.pulse += (state.pulseTarget - state.pulse) * Math.min(1, dt * 8);
  coreUniforms.uPulse.value = state.pulse;

  // parallax
  if (state.parallax) {
    state.mx += (state.tmx - state.mx) * Math.min(1, dt * 3);
    state.my += (state.tmy - state.my) * Math.min(1, dt * 3);
  }
  camera.position.x = state.mx * 0.45;
  camera.position.y = -state.my * 0.3 + Math.sin(t * 0.18) * 0.05;
  camera.lookAt(0, 0.1, 0);

  // core gentle wobble (legacy single-core kept invisible; twin planets handled below)
  // twin planet orbit + spin
  const orbitT = t * 0.18;
  materiePlanet.position.set(Math.cos(orbitT) * ORBIT_R, Math.sin(orbitT) * 0.12, Math.sin(orbitT) * 0.4);
  energiePlanet.position.set(-Math.cos(orbitT) * ORBIT_R, -Math.sin(orbitT) * 0.12, -Math.sin(orbitT) * 0.4);
  materiePlanet.userData.surface.rotation.y = t * 0.12;
  materiePlanet.userData.clouds.rotation.y = t * 0.16;
  energiePlanet.userData.surface.rotation.y = -t * 0.10;
  energiePlanet.userData.clouds.rotation.y = -t * 0.14;
  materiePlanet.userData.uniforms.uTime.value = t;
  energiePlanet.userData.uniforms.uTime.value = t;
  // ribbon between planets
  const dx = energiePlanet.position.x - materiePlanet.position.x;
  const dz = energiePlanet.position.z - materiePlanet.position.z;
  const dy = energiePlanet.position.y - materiePlanet.position.y;
  ribbon.position.set((materiePlanet.position.x + energiePlanet.position.x) / 2, (materiePlanet.position.y + energiePlanet.position.y) / 2, (materiePlanet.position.z + energiePlanet.position.z) / 2);
  ribbon.scale.x = Math.hypot(dx, dy, dz) / (2 * ORBIT_R + 0.2);
  ribbon.rotation.y = -Math.atan2(dz, dx);
  ribbon.lookAt(camera.position.x, ribbon.position.y, camera.position.z);
  ribbon.rotation.z = Math.sin(t * 0.5) * 0.04;
  ribbonMat.uniforms.uTime.value = t;
  // pulse couples to planet uniforms
  materiePlanet.userData.uniforms.uPulse.value = state.pulse * 0.6;
  energiePlanet.userData.uniforms.uPulse.value = state.pulse * 0.6;

  // rings rotate
  ringsGroup.rotation.z = t * 0.12;
  ringsGroup.children[1].rotation.z = -t * 0.18;
  ringsGroup.children[3].rotation.z = -t * 0.06;
  ringsGroup.children.at(-1).rotation.z = t * 0.22;

  // halo billboard always faces camera
  halo.lookAt(camera.position);
  rays.lookAt(camera.position);
  rays.rotation.z = t * 0.04;

  // ───── warp progression (hyperreal cinematic) ─────
  if (state.warping) {
    const e = (clock.getElapsedTime() - state.warpStart);
    const total = 2.2;
    const p = Math.min(1, e / total);
    const world = state.world;
    const target = world === 'materie' ? materiePlanet : energiePlanet;
    const other  = world === 'materie' ? energiePlanet : materiePlanet;

    // 4-phase curve: anticipation → accel → entry → emerge
    const anti   = Math.min(1, p / 0.12);
    const accel  = Math.max(0, Math.min(1, (p - 0.12) / 0.40));
    const entry  = Math.max(0, Math.min(1, (p - 0.52) / 0.28));
    const inside = Math.max(0, Math.min(1, (p - 0.80) / 0.20));
    const accelE = accel * accel * (3 - 2 * accel);
    const entryE = entry * entry * (3 - 2 * entry);

    // anticipation: tiny pull-back + planet flare
    const back = Math.sin(anti * Math.PI) * 0.5;
    target.userData.uniforms.uPulse.value = anti * 0.8 + accelE * 1.4 + entryE * 2.2 + inside * 1.0;
    other.userData.uniforms.uPulse.value  = -accelE * 0.7;

    // camera path: dolly directly toward target's screen-space position, slow into atmosphere, plunge through
    const tx = target.position.x, ty = target.position.y;
    camera.position.x = tx * (accelE * 0.92 + entryE * 0.45);
    camera.position.y = ty * (accelE * 0.92 + entryE * 0.45) + (1 - accelE) * camera.position.y * 0.6;
    camera.position.z = 7 + back - accelE * 7.8 - entryE * 3.6 - inside * 1.8;
    // micro-shake on entry for atmospheric buffet
    if (entry > 0 && entry < 1) {
      const sh = (1 - Math.abs(entry - 0.5) * 2) * 0.05;
      camera.position.x += (Math.random() - 0.5) * sh;
      camera.position.y += (Math.random() - 0.5) * sh;
    }
    camera.up.set(Math.sin(p * 0.8) * 0.04, 1, 0);

    // FOV widens during accel (speed feel) then narrows inside (immersion)
    camera.fov = 45 + accelE * 9 - inside * 8;
    camera.updateProjectionMatrix();

    // FX ramps
    bloom.strength = 0.4 + state.bloom * 1.4 + accelE * 1.4 + entryE * 3.0 + inside * 0.6;
    chromPass.uniforms.uAmount.value = 0.0014 + accelE * 0.012 + entryE * 0.045;
    starsMat.uniforms.uPixel.value = renderer.getPixelRatio() * (1 + accelE * 5 + entryE * 9);

    // nebula + atmosphere fully saturate to world color in entry/inside
    const lerp = 0.04 + entryE * 0.16 + inside * 0.32;
    nebulaUniforms.uColorA.value.lerp(state.warpC1, lerp);
    nebulaUniforms.uColorB.value.lerp(state.warpC2, lerp);
    nebulaUniforms.uDensity.value = state.density * (1 + entryE * 2.2 + inside * 1.5);
    rayUniforms.uIntensity.value = 0.55 + entryE * 2.6 + inside * 0.6;
    haloMat.uniforms.uPulse.value = entryE * 1.6;

    // fade the OTHER world out completely
    other.position.x *= (1 - accelE * 0.45);
    other.scale.setScalar(Math.max(0.02, 1 - accelE * 0.85));

    // phase events to DOM overlays
    if (state.warpPhase !== 'accel' && accel > 0.05) {
      state.warpPhase = 'accel';
      document.dispatchEvent(new CustomEvent('warp:accel'));
    }
    if (state.warpPhase !== 'entry' && entry > 0.05) {
      state.warpPhase = 'entry';
      document.dispatchEvent(new CustomEvent('warp:entry'));
    }
    if (state.warpPhase !== 'inside' && inside > 0.1) {
      state.warpPhase = 'inside';
      document.dispatchEvent(new CustomEvent('warp:inside'));
    }

    if (p >= 1 && state.onArrive) {
      const cb = state.onArrive; state.onArrive = null; cb();
    }
  }

  composer.render();
  requestAnimationFrame(tick);
}
tick();

// hide loader once first frame is up
requestAnimationFrame(() => requestAnimationFrame(() => {
  const l = document.getElementById('loader');
  if (l) l.classList.add('hide');
}));
