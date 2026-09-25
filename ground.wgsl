// Artist cutting-mat floor: forest green + mint grid (infinite XZ).
struct Uniforms {
    mvp: mat4x4<f32>,
    model: mat4x4<f32>,
    params: vec4<f32>, // x=cell, y=majorEvery, z=fadeStart, w=fadeEnd
    axis: vec4<f32>,
};

@group(0) @binding(0) var<uniform> u: Uniforms;

struct VSIn {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
};

struct VSOut {
    @builtin(position) pos: vec4<f32>,
    @location(0) world: vec3<f32>,
};

@vertex
fn vs_main(input: VSIn) -> VSOut {
    var o: VSOut;
    let world4 = u.model * vec4<f32>(input.position, 1.0);
    o.world = world4.xyz;
    o.pos = u.mvp * vec4<f32>(input.position, 1.0);
    return o;
}

fn line_aa(coord: f32, cell: f32, thickness: f32) -> f32 {
    let g = abs(fract(coord / cell + 0.5) - 0.5);
    let w = fwidth(coord / cell) * thickness;
    return 1.0 - smoothstep(0.0, max(w, 1e-5), g);
}

@fragment
fn fs_main(input: VSOut) -> @location(0) vec4<f32> {
    let cell = max(u.params.x, 0.001);
    let major = max(u.params.y, 1.0) * cell;
    let px = input.world.x;
    let pz = input.world.z;

    // Cutting-mat greens (self-healing craft mat)
    let matDark = vec3<f32>(0.20, 0.45, 0.30);
    let matBase = vec3<f32>(0.24, 0.52, 0.34);
    let lineSoft = vec3<f32>(0.48, 0.70, 0.52);
    let lineHard = vec3<f32>(0.58, 0.78, 0.58);

    // Subtle checker so big blocks read like a real mat
    let cx = floor(px / major);
    let cz = floor(pz / major);
    let checker = select(0.0, 1.0, ((i32(cx) + i32(cz)) & 1) != 0);
    var base = mix(matBase, matDark, checker * 0.28);

    let minor = max(line_aa(px, cell, 0.95), line_aa(pz, cell, 0.95));
    let maj = max(line_aa(px, major, 1.35), line_aa(pz, major, 1.35));
    base = mix(base, lineSoft, minor * 0.55);
    base = mix(base, lineHard, maj * 0.8);

    // Origin axes: slightly brighter mint (mat style, not Unreal RGB)
    let axisX = 1.0 - smoothstep(0.0, 0.045 + fwidth(pz) * 1.5, abs(pz));
    let axisZ = 1.0 - smoothstep(0.0, 0.045 + fwidth(px) * 1.5, abs(px));
    let axisCol = vec3<f32>(0.68, 0.86, 0.66);
    base = mix(base, axisCol, max(axisX, axisZ) * 0.7);

    let center = u.model[3].xz;
    let dist = length(input.world.xz - center);
    let fade = 1.0 - smoothstep(u.params.z, u.params.w, dist);
    if fade <= 0.001 {
        discard;
    }
    return vec4<f32>(base, fade);
}
