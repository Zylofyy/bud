// Liquid glass: two rounded rectangles joined with a smooth minimum, lit with
// a thin rim and refracting the background and two content layers near the
// edge. Ported from the Morph Lab's WebGL shader.
//
// Coordinates are logical pixels with the origin at the top left. Lengths that
// the original measured in canvas pixels (antialiasing, outlines) are scaled
// by uDpr so edges stay one device pixel wide.

#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uRes;
uniform float uDpr;
uniform vec4 uA;        // shape A: centre, half size
uniform vec2 uAr;       //          radius, sdf offset (> 9000 = off)
uniform vec4 uB;        // shape B: centre, half size
uniform vec2 uBr;       //          radius, sdf offset (> 9000 = off)
uniform float uBt;      // shape B egg taper
uniform float uK;       // smooth-min blend radius
uniform float uAlpha;
uniform vec4 uGlass;    // mul, add rgb
uniform vec4 uGlass2;   // unused, lens, lens width, rim
uniform vec4 uOpq;      // opaque amount, rgb
uniform vec4 uMisc;     // dim, shadow, debug, px unit
uniform vec4 uC0r;      // content 0: layer rect
uniform vec4 uC0x;      //            now xy, scale xy
uniform vec4 uC0m;      //            natural xy, alpha, blur radius
uniform float uC0free;  // content 0 drawn outside the glass
uniform vec4 uC1r;
uniform vec4 uC1x;
uniform vec4 uC1m;
uniform vec4 uHi;       // pressed highlight: centre, half size
uniform vec2 uHi2;      //                    radius, alpha
uniform float uSoft;    // blur (sigma) of the softened content copies

uniform sampler2D uBg;
uniform sampler2D uBgBlur;
uniform sampler2D uT0;
uniform sampler2D uT0a;
uniform sampler2D uT1;
uniform sampler2D uT1a;

out vec4 fragColor;

float sdRR(vec2 p, vec2 c, vec2 h, float r) {
  h = max(h, vec2(0.0));
  r = min(r, min(h.x, h.y));
  vec2 q = abs(p - c) - h + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float smin(float a, float b, float k) {
  if (k <= 0.0) return min(a, b);
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

float sdA(vec2 p) {
  return uAr.y > 9000.0 ? 1e5 : sdRR(p, uA.xy, uA.zw, uAr.x) + uAr.y;
}

float sdB(vec2 p) {
  if (uBr.y > 9000.0) return 1e5;
  vec2 d = p - uB.xy;
  float sy = clamp(d.y / max(uB.w, 1.0), -1.0, 1.0);
  d.x *= 1.0 - uBt * sy;  // egg taper: narrower top, wider bottom
  return sdRR(uB.xy + d, uB.xy, uB.zw, uBr.x) + uBr.y;
}

float scene(vec2 p) {
  return smin(sdA(p), sdB(p), uK);
}

bool outside01(vec2 uv) {
  return uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0;
}

// Content blur of radius r: 12 taps on a golden-angle disc, like the
// original. Its taps read mip levels; here they read the sharp layer for
// small radii and a pre-softened copy (uSoft) for large ones.
vec4 blur0(vec2 uv, float r) {
  if (r * uDpr < 0.6) return texture(uT0, uv);
  vec2 ruv = r / uC0r.zw;
  float soft = smoothstep(uSoft, 2.0 * uSoft, r);
  vec4 a = vec4(0.0);
  vec4 b = vec4(0.0);
  for (int i = 0; i < 12; i++) {
    float fi = float(i);
    float an = fi * 2.39996323 + 0.7;
    vec2 o = vec2(cos(an), sin(an)) * sqrt((fi + 0.5) / 12.0) * ruv;
    if (soft < 1.0) a += texture(uT0, uv + o);
    if (soft > 0.0) b += texture(uT0a, uv + o);
  }
  return mix(a, b, soft) / 12.0;
}

vec4 blur1(vec2 uv, float r) {
  if (r * uDpr < 0.6) return texture(uT1, uv);
  vec2 ruv = r / uC1r.zw;
  float soft = smoothstep(uSoft, 2.0 * uSoft, r);
  vec4 a = vec4(0.0);
  vec4 b = vec4(0.0);
  for (int i = 0; i < 12; i++) {
    float fi = float(i);
    float an = fi * 2.39996323 + 0.7;
    vec2 o = vec2(cos(an), sin(an)) * sqrt((fi + 0.5) / 12.0) * ruv;
    if (soft < 1.0) a += texture(uT1, uv + o);
    if (soft > 0.0) b += texture(uT1a, uv + o);
  }
  return mix(a, b, soft) / 12.0;
}

vec4 content0(vec2 p) {
  if (uC0m.z <= 0.002) return vec4(0.0);
  vec2 nat = (p - uC0x.xy) / uC0x.zw + uC0m.xy;
  vec2 uv = (nat - uC0r.xy) / uC0r.zw;
  if (outside01(uv)) return vec4(0.0);
  return blur0(uv, uC0m.w) * uC0m.z;
}

vec4 content1(vec2 p) {
  if (uC1m.z <= 0.002) return vec4(0.0);
  vec2 nat = (p - uC1x.xy) / uC1x.zw + uC1m.xy;
  vec2 uv = (nat - uC1r.xy) / uC1r.zw;
  if (outside01(uv)) return vec4(0.0);
  return blur1(uv, uC1m.w) * uC1m.z;
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 uv = p / uRes;
  float u = uMisc.w;
  float dimK = 1.0 - uMisc.x;
  vec3 bg = texture(uBg, uv).rgb * dimK;
  float d = scene(p);
  float sh = 0.0;
  if (uMisc.y > 0.0 && uAlpha > 0.0) {
    float ds = scene(p - vec2(0.0, 5.0 * u));
    sh = uMisc.y * (1.0 - smoothstep(-6.0 * u, 26.0 * u, ds)) * uAlpha;
  }
  vec3 outside = bg * (1.0 - sh);
  vec3 fin = outside;
  if (d * uDpr < 1.5) {
    vec2 e = vec2(1.0, 0.0);
    vec2 g = vec2(scene(p + e.xy) - scene(p - e.xy),
                  scene(p + e.yx) - scene(p - e.yx));
    vec2 n = length(g) > 1e-5 ? normalize(g) : vec2(0.0, -1.0);
    float inside = max(-d, 0.0);
    float lf = clamp(1.0 - inside / max(uGlass2.z, 1.0), 0.0, 1.0);
    float lens = uGlass2.y * lf * lf;
    vec2 q = p - n * lens;
    vec3 gb = uOpq.x > 0.999 ? vec3(0.0)
                             : texture(uBgBlur, clamp(q / uRes, 0.0, 1.0)).rgb * dimK;
    vec3 col = gb * uGlass.x + uGlass.yzw;
    col = mix(col, uOpq.yzw, uOpq.x);
    if (uHi2.y > 0.0) {
      float dh = sdRR(p, uHi.xy, uHi.zw, uHi2.x);
      col = mix(col, vec3(1.0), uHi2.y * clamp(0.5 - dh * uDpr, 0.0, 1.0));
    }
    if (uC0free < 0.5) {
      vec4 c0 = content0(q);
      col = col * (1.0 - c0.a) + c0.rgb;
    }
    vec4 c1 = content1(q);
    col = col * (1.0 - c1.a) + c1.rgb;
    float rimw = 1.0 - smoothstep(0.0, max(1.6 * u, 1.2 / uDpr), inside);
    float dl = dot(n, normalize(vec2(-0.55, -0.83)));
    float spec = 0.5 + 0.3 * max(-n.y, 0.0) + 0.7 * pow(abs(dl), 6.0);
    col += uGlass2.w * rimw * spec;
    col += uGlass2.w * 0.22 * (1.0 - smoothstep(0.0, 14.0 * u, inside)) *
           pow(abs(dl), 3.0);
    float a = clamp(0.5 - d * uDpr, 0.0, 1.0) * uAlpha;
    fin = mix(outside, col, a);
  }
  if (uC0free > 0.5) {
    vec4 c0 = content0(p);
    fin = fin * (1.0 - c0.a) + c0.rgb;
  }
  if (uMisc.z > 0.5) {
    float da = (sdA(p) - uAr.y) * uDpr;
    float db = (sdB(p) - uBr.y) * uDpr;
    if (uAr.y < 9000.0 && abs(da) < 1.2) fin = mix(fin, vec3(0.2, 0.85, 1.0), 0.9);
    if (uBr.y < 9000.0 && abs(db) < 1.2) fin = mix(fin, vec3(1.0, 0.7, 0.1), 0.9);
    if (abs(d * uDpr) < 0.8 && uAlpha > 0.0) fin = mix(fin, vec3(1.0, 0.25, 0.3), 0.5);
  }
  fragColor = vec4(fin, 1.0);
}
