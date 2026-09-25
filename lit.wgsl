// Cel / toon shading for vehicle meshes (TOON_SHADER.md recipe).
// Vertex: pos + normal (stride 24). Albedo from uniform color.
struct Uniforms {
    mvp: mat4x4<f32>,
    model: mat4x4<f32>,
    color: vec4<f32>,    // albedo rgb
    light: vec4<f32>,    // lightDir.xyz, intensity
    eye: vec4<f32>,      // eye.xyz, outlineSmooth
    style: vec4<f32>,    // outlineWidth, specThresh, specAmount, exposure
    shade: vec4<f32>,    // wrap, ambient, rimAmount, rimPower
    warm: vec4<f32>,     // warm key rgb, shadeBands
    cool: vec4<f32>,     // cool shadow rgb, metal
    rim: vec4<f32>,      // rimColor rgb, fresnel
};

@group(0) @binding(0) var<uniform> u: Uniforms;

struct VSIn {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
};

struct VSOut {
    @builtin(position) pos: vec4<f32>,
    @location(0) worldPos: vec3<f32>,
    @location(1) worldN: vec3<f32>,
};

fn aces_tonemap(x: vec3<f32>) -> vec3<f32> {
    let a = 2.51;
    let b = 0.03;
    let c = 2.43;
    let d = 0.59;
    let e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), vec3<f32>(0.0), vec3<f32>(1.0));
}

fn to_display(hdr: vec3<f32>) -> vec3<f32> {
    let exposure = max(u.style.w, 0.01);
    return pow(aces_tonemap(max(hdr, vec3<f32>(0.0)) * exposure), vec3<f32>(1.0 / 2.2));
}

fn mat3_inverse_transpose(m: mat3x3<f32>) -> mat3x3<f32> {
    let a = m[0];
    let b = m[1];
    let c = m[2];
    let det = dot(a, cross(b, c));
    let inv = 1.0 / max(abs(det), 1e-8) * sign(det);
    return mat3x3<f32>(cross(b, c) * inv, cross(c, a) * inv, cross(a, b) * inv);
}

fn model_normal(n: vec3<f32>) -> vec3<f32> {
    let m = mat3x3<f32>(u.model[0].xyz, u.model[1].xyz, u.model[2].xyz);
    return normalize(mat3_inverse_transpose(m) * n);
}

fn shade_band(ndotl: f32, bands: f32, wrap: f32) -> f32 {
    let n = max(floor(bands + 0.5), 2.0);
    let w = clamp(wrap, 0.0, 0.8);
    let t = clamp(ndotl * (0.5 + w) + (0.5 - w * 0.35), 0.0, 1.0);
    let stepped = floor(t * n + 0.0001) / max(n - 1.0, 1.0);
    return mix(0.26, 1.0, clamp(stepped, 0.0, 1.0));
}

fn saturate_rgb(col: vec3<f32>, amount: f32) -> vec3<f32> {
    let gray = vec3<f32>(dot(col, vec3<f32>(0.2126, 0.7152, 0.0722)));
    return mix(gray, col, amount);
}

@vertex
fn vs_main(input: VSIn) -> VSOut {
    var o: VSOut;
    let world = u.model * vec4<f32>(input.position, 1.0);
    o.worldPos = world.xyz;
    o.worldN = model_normal(input.normal);
    o.pos = u.mvp * vec4<f32>(input.position, 1.0);
    return o;
}

@vertex
fn vs_outline(input: VSIn) -> VSOut {
    var o: VSOut;
    let world = (u.model * vec4<f32>(input.position, 1.0)).xyz;
    let world_n = model_normal(input.normal);
    let center = u.model[3].xyz;
    let radial = normalize(world - center + vec3<f32>(0.0, 0.0001, 0.0));
    let soften = clamp(u.eye.w, 0.0, 1.0);
    let n = normalize(world_n * (1.0 - soften * 0.72) + radial * (0.18 + soften * 0.72));
    let width = u.style.x;
    // Inflate in local space along normal, then push in clip for screen-stable thickness
    let local_off = input.position + input.normal * (width * 0.012);
    var clip = u.mvp * vec4<f32>(local_off, 1.0);
    let cn = (u.mvp * vec4<f32>(input.normal, 0.0)).xy;
    let cn_len = max(length(cn), 1e-5);
    let clip_off = (cn / cn_len) * width * clip.w * 0.0018;
    clip = vec4<f32>(clip.xy + clip_off, clip.z + 0.0002, clip.w);
    o.worldPos = world + n * width * 0.01;
    o.worldN = n;
    o.pos = clip;
    return o;
}

@fragment
fn fs_outline(_in: VSOut) -> @location(0) vec4<f32> {
    // outlineColor #121014
    return vec4<f32>(0.071, 0.063, 0.078, 1.0);
}

@fragment
fn fs_main(input: VSOut) -> @location(0) vec4<f32> {
    let n = normalize(input.worldN);
    let v = normalize(u.eye.xyz - input.worldPos);
    let l = normalize(u.light.xyz);
    let albedo = pow(max(u.color.rgb, vec3<f32>(0.0)), vec3<f32>(2.2));
    let luma = dot(albedo, vec3<f32>(0.2126, 0.7152, 0.0722));
    let rubber = 1.0 - smoothstep(0.03, 0.14, luma);

    let wrap = u.shade.x;
    let ambient = max(u.shade.y, 0.0);
    let rim_amt = max(u.shade.z, 0.0);
    let rim_pow = max(u.shade.w, 0.2);
    let bands = max(u.warm.w, 2.0);
    let metal = clamp(u.cool.w, 0.0, 1.0);
    let fres = max(u.rim.w, 0.0);
    let sat = 1.12;
    let spec_soft = 0.42;

    let ndotl = dot(n, l);
    let band = shade_band(ndotl, bands, wrap);
    let warm = u.warm.rgb;
    let shadow_col = max(u.cool.rgb, vec3<f32>(0.02));
    let cool = mix(shadow_col, warm, 0.16);
    let light_col = mix(cool, warm, band);
    var lit = albedo * light_col * (0.34 + band * 0.98) * max(u.light.w, 0.0);
    lit += albedo * shadow_col * ambient;

    let h = normalize(l + v);
    let nh = max(dot(n, h), 0.0);
    let spec_col = mix(vec3<f32>(1.0, 0.96, 0.88), albedo, metal);
    let hard = select(0.0, 1.0, nh > u.style.y && ndotl > 0.22 && rubber < 0.55);
    let gloss = mix(18.0, 96.0, 1.0 - spec_soft);
    let soft = pow(nh, gloss) * select(0.0, 1.0, ndotl > 0.0);
    let spec = mix(hard, soft, spec_soft) * (1.0 - rubber * 0.85);
    lit += spec_col * spec * u.style.z;

    let nv = max(dot(n, v), 0.0);
    let rim = pow(1.0 - nv, rim_pow) * rim_amt;
    lit += u.rim.rgb * rim * mix(0.55, 1.15, luma);
    lit += albedo * pow(1.0 - nv, 2.4) * fres * 0.55;

    // Mild height AO (darken near ground)
    let ao_t = clamp(input.worldPos.y / 0.22, 0.0, 1.0);
    lit *= mix(1.0 - 0.32, 1.0, ao_t);

    // Soft distance fog
    let dist = length(u.eye.xyz - input.worldPos);
    let fog = clamp((dist - 7.0) / 12.0 * 0.18, 0.0, 1.0);
    lit = mix(lit, vec3<f32>(0.078, 0.086, 0.157), fog);

    lit = saturate_rgb(lit, sat);
    return vec4<f32>(to_display(lit), 1.0);
}
