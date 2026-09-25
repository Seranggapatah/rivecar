// Simple oval shape shadow on the ground (unit disc / ellipse via scale).
struct Uniforms {
    mvp: mat4x4<f32>,
    color: vec4<f32>, // rgb + peak alpha
};

@group(0) @binding(0) var<uniform> u: Uniforms;

struct VSIn {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
};

struct VSOut {
    @builtin(position) pos: vec4<f32>,
    @location(0) local: vec3<f32>,
};

@vertex
fn vs_main(input: VSIn) -> VSOut {
    var o: VSOut;
    o.local = input.position;
    o.pos = u.mvp * vec4<f32>(input.position, 1.0);
    return o;
}

@fragment
fn fs_main(input: VSOut) -> @location(0) vec4<f32> {
    let d = length(input.local.xz);
    // Clean shape with a short soft rim (not a mesh silhouette)
    let a = smoothstep(1.0, 0.72, d) * u.color.a;
    if a < 0.01 {
        discard;
    }
    return vec4<f32>(u.color.rgb, a);
}
