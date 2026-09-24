struct Frame {
    view_proj: mat4x4<f32>,
    model: mat4x4<f32>,
    sun: vec4<f32>,
    eye: vec4<f32>,
    params: vec4<f32>,
    style: vec4<f32>,
    outline: vec4<f32>,
    light_col: vec4<f32>,
    pick: vec4<f32>,
    shade: vec4<f32>,
    shade_col: vec4<f32>,
    rim_col: vec4<f32>,
    fx: vec4<f32>,
    fx2: vec4<f32>,
    atmos: vec4<f32>,
}

@group(0) @binding(0) var<uniform> frame: Frame;

const PI: f32 = 3.14159265;

struct VertexIn {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec4<f32>,
}

struct VertexOut {
    @builtin(position) position: vec4<f32>,
    @location(0) world_pos: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec4<f32>,
}

struct SkyOut {
    @builtin(position) position: vec4<f32>,
    @location(0) clip: vec2<f32>,
}

fn aces_tonemap(x: vec3<f32>) -> vec3<f32> {
    let a = 2.51;
    let b = 0.03;
    let c = 2.43;
    let d = 0.59;
    let e = 0.14;
    return clamp(
        (x * (a * x + b)) / (x * (c * x + d) + e),
        vec3<f32>(0.0),
        vec3<f32>(1.0),
    );
}

fn to_display(hdr: vec3<f32>) -> vec3<f32> {
    let exposure = max(frame.style.w, 0.01);
    return pow(
        aces_tonemap(max(hdr, vec3<f32>(0.0)) * exposure),
        vec3<f32>(1.0 / 2.2),
    );
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
    let m = mat3x3<f32>(
        frame.model[0].xyz,
        frame.model[1].xyz,
        frame.model[2].xyz,
    );
    return normalize(mat3_inverse_transpose(m) * n);
}

fn shade_band(ndotl: f32, bands: f32, wrap: f32) -> f32 {
    let n = max(floor(bands + 0.5), 2.0);
    let w = clamp(wrap, 0.0, 0.8);
    let t = clamp(ndotl * (0.5 + w) + (0.5 - w * 0.35), 0.0, 1.0);
    let stepped = floor(t * n + 0.0001) / max(n - 1.0, 1.0);
    return mix(0.26, 1.0, clamp(stepped, 0.0, 1.0));
}

fn apply_fog(col: vec3<f32>, world_pos: vec3<f32>) -> vec3<f32> {
    let dist = length(frame.eye.xyz - world_pos);
    let start = max(frame.fx.w, 0.1);
    let amt = max(frame.fx.z, 0.0);
    let fog = clamp((dist - start) / max(8.0, start * 1.6) * amt, 0.0, 1.0);
    return mix(col, max(frame.atmos.rgb, vec3<f32>(0.0)), fog);
}

fn saturate_rgb(col: vec3<f32>, amount: f32) -> vec3<f32> {
    let gray = vec3<f32>(dot(col, vec3<f32>(0.2126, 0.7152, 0.0722)));
    return mix(gray, col, amount);
}

@vertex
fn vs_sky(@builtin(vertex_index) idx: u32) -> SkyOut {
    var pos = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(3.0, -1.0),
        vec2<f32>(-1.0, 3.0),
    );
    var out: SkyOut;
    out.position = vec4<f32>(pos[idx], 1.0, 1.0);
    out.clip = pos[idx];
    return out;
}

@fragment
fn fs_sky(in: SkyOut) -> @location(0) vec4<f32> {
    let v = clamp(in.clip.y * 0.5 + 0.5, 0.0, 1.0);
    let fogc = max(frame.atmos.rgb, vec3<f32>(0.01, 0.015, 0.03));
    let floor_col = fogc * 0.45;
    let haze = mix(vec3<f32>(1.08, 0.7, 0.36), fogc * 2.2, 0.28);
    let zenith = mix(vec3<f32>(0.055, 0.12, 0.36), fogc, 0.22);
    var col = mix(floor_col, haze, smoothstep(0.08, 0.38, v));
    col = mix(col, zenith, smoothstep(0.38, 1.0, v));
    let r = length(in.clip * vec2<f32>(1.0, 1.12));
    col *= 1.0 - smoothstep(0.5, 1.45, r) * 0.5;
    let glow = exp(-10.0 * abs(v - 0.32));
    col += vec3<f32>(1.55, 0.82, 0.34) * glow * max(frame.atmos.w, 0.0);
    return vec4<f32>(to_display(col), 1.0);
}

@vertex
fn vs_mesh(input: VertexIn) -> VertexOut {
    var out: VertexOut;
    let world = frame.model * vec4<f32>(input.position, 1.0);
    out.world_pos = world.xyz;
    out.normal = model_normal(input.normal);
    out.color = input.color;
    out.position = frame.view_proj * world;
    return out;
}

@vertex
fn vs_outline(input: VertexIn) -> VertexOut {
    var out: VertexOut;
    let world = (frame.model * vec4<f32>(input.position, 1.0)).xyz;
    let world_n = model_normal(input.normal);
    let center = vec3<f32>(frame.params.y, frame.eye.w, frame.params.z);
    let radial = normalize(world - center + vec3<f32>(0.0, 0.0001, 0.0));
    let soften = clamp(frame.outline.w, 0.0, 1.0);
    let n = normalize(
        world_n * (1.0 - soften * 0.72) + radial * (0.18 + soften * 0.72),
    );
    let width = frame.style.x;
    let screen = clamp(frame.light_col.w, 0.0, 1.0);
    let world_off = world + n * width * mix(1.0, 0.22, screen);
    var clip = frame.view_proj * vec4<f32>(world_off, 1.0);
    let cn = (frame.view_proj * vec4<f32>(n, 0.0)).xy;
    let cn_len = max(length(cn), 1e-5);
    let clip_off = (cn / cn_len) * width * clip.w * mix(0.15, 1.0, screen);
    clip = vec4<f32>(clip.xy + clip_off, clip.z, clip.w);
    out.world_pos = world_off;
    out.normal = n;
    out.color = input.color;
    out.position = clip;
    return out;
}

@fragment
fn fs_outline(_in: VertexOut) -> @location(0) vec4<f32> {
    return vec4<f32>(frame.outline.rgb, 1.0);
}

@fragment
fn fs_mesh(in: VertexOut) -> @location(0) vec4<f32> {
    let n = normalize(in.normal);
    let v = normalize(frame.eye.xyz - in.world_pos);
    let l = normalize(frame.sun.xyz);
    let albedo = pow(max(in.color.rgb, vec3<f32>(0.0)), vec3<f32>(2.2));
    let luma = dot(albedo, vec3<f32>(0.2126, 0.7152, 0.0722));
    let rubber = 1.0 - smoothstep(0.03, 0.14, luma);

    let wrap = frame.shade.x;
    let ambient = max(frame.shade.y, 0.0);
    let rim_amt = max(frame.shade.z, 0.0);
    let rim_pow = max(frame.shade.w, 0.2);
    let shadow_col = max(frame.shade_col.rgb, vec3<f32>(0.02));
    let sat = frame.shade_col.w;
    let metal = clamp(frame.rim_col.w, 0.0, 1.0);
    let spec_soft = clamp(frame.fx2.z, 0.0, 1.0);
    let fres = max(frame.fx2.w, 0.0);

    let ndotl = dot(n, l);
    let band = shade_band(ndotl, frame.params.w, wrap);
    let warm = frame.light_col.rgb;
    let cool = mix(shadow_col, warm, 0.16);
    let light_col = mix(cool, warm, band);
    var lit = albedo * light_col * (0.34 + band * 0.98) * max(frame.sun.w, 0.0);
    lit += albedo * shadow_col * ambient;

    let h = normalize(l + v);
    let nh = max(dot(n, h), 0.0);
    let spec_col = mix(vec3<f32>(1.0, 0.96, 0.88), albedo, metal);
    let hard = select(
        0.0,
        1.0,
        nh > frame.style.y && ndotl > 0.22 && rubber < 0.55,
    );
    let gloss = mix(18.0, 96.0, 1.0 - spec_soft);
    let soft = pow(nh, gloss) * select(0.0, 1.0, ndotl > 0.0);
    let spec = mix(hard, soft, spec_soft) * (1.0 - rubber * 0.85);
    lit += spec_col * spec * frame.style.z;

    let nv = max(dot(n, v), 0.0);
    let rim = pow(1.0 - nv, rim_pow) * rim_amt;
    lit += frame.rim_col.rgb * rim * mix(0.55, 1.15, luma);
    lit += albedo * pow(1.0 - nv, 2.4) * fres * 0.55;

    let ao_h = max(frame.fx.y, 0.001);
    let ao_t = clamp((in.world_pos.y - frame.params.x) / ao_h, 0.0, 1.0);
    lit *= mix(1.0 - clamp(frame.fx.x, 0.0, 0.9), 1.0, ao_t);

    let part = frame.pick.x;
    if abs(part - frame.pick.y) < 0.5 && frame.pick.y > 0.5 {
        lit *= 1.16;
        lit += vec3<f32>(0.18, 0.55, 1.15) * 0.28;
    }
    if abs(part - frame.pick.z) < 0.5 && frame.pick.z > 0.5 {
        lit *= 1.08;
        lit += vec3<f32>(1.15, 0.82, 0.18) * 0.32;
    }

    lit = saturate_rgb(lit, sat);
    lit = apply_fog(lit, in.world_pos);
    return vec4<f32>(to_display(lit), 1.0);
}

@vertex
fn vs_ground(input: VertexIn) -> VertexOut {
    var out: VertexOut;
    let world = frame.model * vec4<f32>(input.position, 1.0);
    out.world_pos = world.xyz;
    out.normal = vec3<f32>(0.0, 1.0, 0.0);
    out.color = input.color;
    out.position = frame.view_proj * world;
    return out;
}

fn grid_aa(coord: f32, cell: f32, thickness: f32) -> f32 {
    let g = abs(fract(coord / cell + 0.5) - 0.5);
    let w = fwidth(coord / cell) * thickness;
    return 1.0 - smoothstep(0.0, max(w, 0.001), g);
}

@fragment
fn fs_ground(in: VertexOut) -> @location(0) vec4<f32> {
    let origin = frame.params.yz;
    let p = in.world_pos.xz - origin;
    let dist = length(p);
    let v = normalize(frame.eye.xyz - in.world_pos);
    let r = reflect(-v, vec3<f32>(0.0, 1.0, 0.0));
    let env = mix(
        vec3<f32>(0.05, 0.04, 0.03),
        vec3<f32>(0.35, 0.28, 0.18),
        r.y * 0.5 + 0.5,
    );
    let fres = pow(1.0 - max(v.y, 0.0), 3.4);
    let shadow_r = max(frame.fx2.x, 0.05);
    let shadow_a = clamp(frame.fx2.y, 0.0, 1.0);
    let shadow = (1.0 - smoothstep(shadow_r * 0.35, shadow_r, dist)) * shadow_a;
    var col = vec3<f32>(0.045, 0.05, 0.062) + env * fres * 0.06;
    col *= 1.0 - shadow;

    let cell = frame.pick.w;
    if cell > 0.001 {
        let gx = in.world_pos.x;
        let gz = in.world_pos.z;
        let minor = max(grid_aa(gx, cell, 1.15), grid_aa(gz, cell, 1.15));
        let major = max(
            grid_aa(gx, cell * 5.0, 1.45),
            grid_aa(gz, cell * 5.0, 1.45),
        );
        let axis_z = 1.0 - smoothstep(0.0, 0.016 + fwidth(gx) * 1.8, abs(gx));
        let axis_x = 1.0 - smoothstep(0.0, 0.016 + fwidth(gz) * 1.8, abs(gz));
        col = mix(col, vec3<f32>(0.28, 0.4, 0.52), minor * 0.55);
        col = mix(col, vec3<f32>(0.5, 0.66, 0.82), major * 0.72);
        col = mix(col, vec3<f32>(0.92, 0.28, 0.24), axis_x);
        col = mix(col, vec3<f32>(0.24, 0.5, 0.96), axis_z);
    }

    let fade = 1.0 - smoothstep(5.5, 14.0, dist);
    col = apply_fog(col, in.world_pos);
    return vec4<f32>(to_display(col), fade * 0.92);
}

@vertex
fn vs_axis(input: VertexIn) -> VertexOut {
    var out: VertexOut;
    let world = frame.model * vec4<f32>(input.position, 1.0);
    out.world_pos = world.xyz;
    out.normal = input.normal;
    out.color = input.color;
    out.position = frame.view_proj * world;
    return out;
}

@fragment
fn fs_axis(in: VertexOut) -> @location(0) vec4<f32> {
    return vec4<f32>(in.color.rgb, 1.0);
}
