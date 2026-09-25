// Sharp planar projected shadow (sunlight silhouette clone on ground).
struct Uniforms {
    viewProj: mat4x4<f32>,
    model: mat4x4<f32>,
    lightPlane: vec4<f32>, // lightDir.xyz (toward light), planeY
    color: vec4<f32>,      // rgb + alpha
};

@group(0) @binding(0) var<uniform> u: Uniforms;

struct VSIn {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
};

struct VSOut {
    @builtin(position) pos: vec4<f32>,
};

@vertex
fn vs_main(input: VSIn) -> VSOut {
    var o: VSOut;
    let world = (u.model * vec4<f32>(input.position, 1.0)).xyz;
    let L = u.lightPlane.xyz;
    let planeY = u.lightPlane.w;
    let ly = max(L.y, 0.18);
    let t = (world.y - planeY) / ly;
    var shadow = world - L * t;
    shadow.y = planeY;
    o.pos = u.viewProj * vec4<f32>(shadow, 1.0);
    o.pos.z -= 0.0002 * o.pos.w;
    return o;
}

@fragment
fn fs_main(_in: VSOut) -> @location(0) vec4<f32> {
    // Hard silhouette — darkness controlled only by uniform alpha
    return u.color;
}
