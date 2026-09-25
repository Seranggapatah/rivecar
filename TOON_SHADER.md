# Toon shader recipe (Cli / `plane.wgsl`)

Hand this file to another AI agent to recreate the same stylized look.

## Look target

Cel-shaded mesh: **quantized light bands**, warm key + cool shadow tint, **inverted-hull outline**, hard/soft specular, rim light, mild height AO + distance fog. Display path: **ACES tonemap → gamma 2.2**.

Source of truth in this repo:

- Shader: `plane.wgsl` (`shade_band`, `fs_mesh`, `vs_outline` / `fs_outline`)
- Inspector defaults: `scene.rml` (groups Light, Outline, Shading, Atmosphere, Camera)

## Draw order

1. Sky (optional)
2. Ground + contact shadow (optional)
3. **Outline pass** — cull front, inflate verts along normal, solid outline color
4. **Mesh pass** — toon shade
5. Debug axis / UI (optional)

## Core lighting

```
ndotl = dot(N, L)
t = saturate(ndotl * (0.5 + wrap) + (0.5 - wrap * 0.35))
band = floor(t * bands) / (bands - 1)   // remap roughly 0.26 .. 1.0
lightCol = lerp(coolShadowTint, warmKeyColor, band)
lit = albedo * lightCol * (0.34 + band * 0.98) * intensity
lit += albedo * shadowColor * ambient
```

Then add:

- **Specular** — Blinn-Phong; hard step above `specThresh`, softened by `specSoft`; tint toward albedo by `metal`; scale by `specAmount`
- **Rim** — `pow(1 - N·V, rimPower) * rimAmount * rimColor`
- **Fresnel** — small edge boost (`fresnel`)
- **Height AO** — darken near model base (`aoAmount`, `aoHeight`)
- **Fog** — distance fog after shading (`fogAmount`, `fogStart`, `fogColor`)

Albedo comes from vertex color: linearize sRGB → shade in linear → ACES → gamma out.

## Outline

- Separate inverted-hull pass (not post-process edge detect)
- Extrude along normal; width = `outlineWidth`
- `outlineSmooth` softens extrusion at grazing angles
- `outlineScreen`: prefer screen-space inflate so thickness stays stable with distance
- Color = `outlineColor`

## Default inspector values

### Light

| param | value | notes |
|---|---|---|
| lightYaw | 16.5 | degrees |
| lightPitch | 25 | degrees |
| lightColor | `#FFD194` | warm key |
| lightIntensity | 1 | |
| shadowColor | `#8A96C8` | cool fill / low band |
| rimColor | `#F4C896` | |
| rimAmount | 0.48 | |
| rimPower | 2.8 | |

### Outline

| param | value |
|---|---|
| showOutline | true |
| outlineWidth | 3.8 |
| outlineColor | `#121014` |
| outlineSmooth | 0.82 |
| outlineScreen | true |

### Shading (toon core)

| param | value | role |
|---|---|---|
| shadeBands | **3** | cel steps (min 2) |
| wrapLight | 0.28 | wrap Lambert before quantize |
| ambient | 0.24 | shadow-tint ambient |
| specAmount | 0.35 | |
| specThresh | 0.88 | hard highlight threshold |
| specSoft | 0.42 | 0 = hard anime, 1 = soft |
| exposure | 0.68 | ACES exposure |
| saturate | 1.12 | post saturation |
| metal | 0.62 | specular tint toward albedo |
| fresnel | 0.32 | edge boost |

### Atmosphere

| param | value |
|---|---|
| aoAmount | 0.32 |
| aoHeight | 0.22 |
| fogAmount | 0.18 |
| fogStart | 7 |
| fogColor | `#141628` |
| contactShadow | 0.42 |
| contactRadius | 1.6 |
| skyGlow | 1.35 |

### Camera (similar framing)

| param | value |
|---|---|
| camYaw | 55 |
| camPitch | 18 |
| camDistance | 6.6 |
| camFov | 26 |

## Signature combo

`shadeBands = 3`, warm `#FFD194` + cool `#8A96C8`, outline `#121014` @ width ~3.8.

Bands must be **stepped**, not smooth Lambert — that is the toon look.
