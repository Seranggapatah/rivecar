type MeshDraw = {
    vertexBuffer: GPUBuffer,
    indexBuffer: GPUBuffer,
    indexCount: number,
}

type MeshPart = {
    name: string,
    localSpace: boolean,
    draw: MeshDraw,
    ubo: GPUBuffer?,
    bindGroup: GPUBindGroup?,
    bmin: Vector,
    bmax: Vector,
    translation: Vector,
    scale: Vector,
    world: Mat4,
    partId: number,
    pivot: Vector,
    bone: number,
    doOutline: boolean,
}

type BoneKey = {
    t: number,
    rx: number,
    ry: number,
    rz: number,
}

type SkelBone = {
    name: string,
    parent: number,
    isJoint: boolean,
    tx: number,
    ty: number,
    tz: number,
    qx: number,
    qy: number,
    qz: number,
    qw: number,
    sx: number,
    sy: number,
    sz: number,
    liveRX: number,
    liveRY: number,
    liveRZ: number,
    liveSX: number,
    liveSY: number,
    liveSZ: number,
    posed: boolean,
    keys: { BoneKey },
    world: Mat4,
}

type PlaneLoader = {
    context: Context?,
    size: Vector,
    scale: number,
    elapsed: number,
    ready: boolean,
    sampler: ImageSampler,
    gpu: GPUCanvas?,
    depth: GPUTexture?,
    depthView: GPUTextureView?,
    msaaColor: GPUTexture?,
    samples: number,
    skyPipeline: GPUPipeline?,
    meshPipeline: GPUPipeline?,
    outlinePipeline: GPUPipeline?,
    groundPipeline: GPUPipeline?,
    axisPipeline: GPUPipeline?,
    uboAxis: GPUBuffer?,
    uboGround: GPUBuffer?,
    uboBytes: buffer,
    bindGroup: GPUBindGroup?,
    bindGroupAxis: GPUBindGroup?,
    bindGroupGround: GPUBindGroup?,
    parts: { MeshPart },
    bones: { SkelBone },
    selectedBone: number,
    hoverBone: number,
    ground: MeshDraw?,
    axisMesh: MeshDraw?,
    center: Vector,
    extent: Vector,
    tmpViewProj: Mat4,
    tmpModel: Mat4,
    tmpMul: Mat4,
    gpuFailed: boolean,
    hoverId: number,
    selectedId: number,
    hasPointer: boolean,
    pointerX: number,
    pointerY: number,
    lightYaw: Input<number>,
    lightPitch: Input<number>,
    lightColor: Input<Color>,
    lightIntensity: Input<number>,
    outlineWidth: Input<number>,
    outlineColor: Input<Color>,
    showOutline: Input<boolean>,
    outlineSmooth: Input<number>,
    outlineScreen: Input<boolean>,
    shadeBands: Input<number>,
    specAmount: Input<number>,
    exposure: Input<number>,
    posX: Input<number>,
    posY: Input<number>,
    posZ: Input<number>,
    rotX: Input<number>,
    rotY: Input<number>,
    rotZ: Input<number>,
    modelScale: Input<number>,
    camYaw: Input<number>,
    camPitch: Input<number>,
    camDistance: Input<number>,
    camFov: Input<number>,
    orbit: Input<boolean>,
    orbitSpeed: Input<number>,
    camBob: Input<boolean>,
    showAxis: Input<boolean>,
    axisLocal: Input<boolean>,
    axisPosX: Input<number>,
    axisPosY: Input<number>,
    axisPosZ: Input<number>,
    axisPosLocal: Input<boolean>,
    axisSize: Input<number>,
    showSky: Input<boolean>,
    showGround: Input<boolean>,
    showGrid: Input<boolean>,
    gridSize: Input<number>,
    showCamGizmo: Input<boolean>,
    showSockets: Input<boolean>,
    showGuides: Input<boolean>,
    showUI: Input<boolean>,
    transparentBg: Input<boolean>,
    msaa: Input<boolean>,
    specThresh: Input<number>,
    specSoft: Input<number>,
    wrapLight: Input<number>,
    ambient: Input<number>,
    saturate: Input<number>,
    metal: Input<number>,
    fresnel: Input<number>,
    shadowColor: Input<Color>,
    rimColor: Input<Color>,
    rimAmount: Input<number>,
    rimPower: Input<number>,
    aoAmount: Input<number>,
    aoHeight: Input<number>,
    fogAmount: Input<number>,
    fogStart: Input<number>,
    contactShadow: Input<number>,
    contactRadius: Input<number>,
    skyGlow: Input<number>,
    fogColor: Input<Color>,
    skelLidHingeX: Input<number>,
    skelLidHingeY: Input<number>,
    skelLidHingeZ: Input<number>,
    skelCapHingeX: Input<number>,
    skelCapHingeY: Input<number>,
    skelCapHingeZ: Input<number>,
    skelLidArmX: Input<number>,
    skelLidArmY: Input<number>,
    skelLidArmZ: Input<number>,
    skelCapArmX: Input<number>,
    skelCapArmY: Input<number>,
    skelCapArmZ: Input<number>,
    skelChestX: Input<number>,
    skelChestY: Input<number>,
    skelChestZ: Input<number>,
    skelChestScaleX: Input<number>,
    skelChestScaleY: Input<number>,
    skelChestScaleZ: Input<number>,
    skelRootX: Input<number>,
    skelRootY: Input<number>,
    skelRootZ: Input<number>,
    pickEnable: Input<boolean>,
    animTime: number,
    animDuration: number,
    animPlaying: boolean,
    animScrubbing: boolean,
    hoverAnim: number,
    toolMode: Input<number>,
    liveTool: number,
    overridePos: boolean,
    overrideRot: boolean,
    overrideScale: boolean,
    overrideLight: boolean,
    overrideCam: boolean,
    overrideOrbit: boolean,
    overrideGrid: boolean,
    liveGrid: boolean,
    overrideGuides: boolean,
    liveGuides: boolean,
    overrideOutline: boolean,
    liveShowOutline: boolean,
    liveOutlineWidth: number,
    liveOutlineSmooth: number,
    liveOutlineScreen: boolean,
    liveOutlineColor: Color,
    liveOutlinePreset: number,
    hoverOutline: number,
    livePosX: number,
    livePosY: number,
    livePosZ: number,
    liveRotX: number,
    liveRotY: number,
    liveRotZ: number,
    liveScale: number,
    liveScaleX: number,
    liveScaleY: number,
    liveScaleZ: number,
    liveLightYaw: number,
    liveLightPitch: number,
    liveCamYaw: number,
    liveCamPitch: number,
    liveCamDistance: number,
    liveOrbit: boolean,
    liveCamBob: boolean,
    dragging: boolean,
    dragTool: number,
    dragHandle: number,
    lastDragX: number,
    lastDragY: number,
    hoverHandle: number,
    hoverTool: number,
    fillPaint: Paint,
    strokePaint: Paint,
    uiPaths: { Path },
    uiCursor: number,
    eyePos: Vector,
    lookAt: Vector,
    overrideTarget: boolean,
    liveTargetX: number,
    liveTargetY: number,
    liveTargetZ: number,
    hoverCube: number,
    hoverZoom: number,
}

local HEADER = 44
local PART_REC = 96
local BONE_REC = 80
local BONE_NONE = -1
local VERTEX_STRIDE = 40
local UBO_SIZE = 384
local SHADOW_COLOR = Color.rgb(138, 150, 200)
local RIM_COLOR = Color.rgb(244, 200, 150)
local FOG_COLOR = Color.rgb(20, 22, 40)
local PART_NONE = 0
local TOOL_SELECT = 1
local TOOL_MOVE = 2
local TOOL_ROTATE = 3
local TOOL_SCALE = 4
local TOOL_LIGHT = 5
local TOOL_CAMERA = 6
local HANDLE_NONE = 0
local HANDLE_X = 1
local HANDLE_Y = 2
local HANDLE_Z = 3
local HANDLE_UNI = 4
local HANDLE_DOLLY = 5
local HANDLE_ORBIT = 6
local LIGHT_COLOR = Color.rgb(255, 209, 148)
local OUTLINE_COLOR = Color.rgb(18, 15, 20)
local OUTLINE_PRESETS = {
    Color.rgb(18, 15, 20),
    Color.rgb(8, 8, 12),
    Color.rgb(255, 255, 255),
    Color.rgb(72, 24, 96),
    Color.rgb(255, 196, 80),
}
local OUT_TOGGLE = 1
local OUT_WDEC = 2
local OUT_WINC = 3
local OUT_SDEC = 4
local OUT_SINC = 5
local OUT_SCREEN = 6
local OUT_COLOR = 7
local OUT_COUNT = 7
local OUT_BTN = 36
local GLFW_O = 79
local GLFW_LEFT_BRACKET = 91
local GLFW_RIGHT_BRACKET = 93
local GLFW_SEMICOLON = 59
local GLFW_APOSTROPHE = 39
local GLFW_I = 73
local GLFW_K = 75
local ANIM_PLAY = 1
local ANIM_KEY = 2
local ANIM_PREV = 3
local ANIM_NEXT = 4
local ANIM_TRACK = 5
local AXIS_RED = Color.rgb(235, 64, 52)
local AXIS_GREEN = Color.rgb(56, 209, 72)
local AXIS_BLUE = Color.rgb(56, 118, 242)
local TOOL_X = 14
local TOOL_Y = 14
local TOOL_PAD = 8
local BTN = 40
local BTN_GAP = 6
local TOOL_COUNT = 6
local GIZMO_HIT = 16
local GLFW_Q = 81
local GLFW_W = 87
local GLFW_E = 69
local GLFW_R = 82
local GLFW_F = 70
local GLFW_G = 71
local GLFW_H = 72
local GLFW_L = 76
local GLFW_C = 67
local GLFW_ONE = 49
local GLFW_MINUS = 45
local GLFW_EQUAL = 61
local GLFW_ESCAPE = 256
local GLFW_KP_SUBTRACT = 333
local GLFW_KP_ADD = 334
local TOOL_NAMES = { "select", "move", "rotate", "scale", "light", "camera" }

local function align4(n: number): number
    local rem = n % 4
    if rem == 0 then
        return n
    end
    return n + (4 - rem)
end

local function asNumber(value: any, fallback: number): number
    if type(value) == "number" and value == value then
        return value
    end
    return fallback
end

local function numOr(value: any, fallback: number): number
    if type(value) == "number" and value == value and value > 0 then
        return value
    end
    return fallback
end

local function asBool(value: any, fallback: boolean): boolean
    if type(value) == "boolean" then
        return value
    end
    return fallback
end

local function colorRgb(value: any, fallback: Color): (number, number, number)
    local col = value
    if type(col) ~= "number" then
        col = fallback
    end
    local f = Color.toFloat(col)
    return f[1], f[2], f[3]
end

local function currentTool(self: PlaneLoader): number
    local t = math.floor(asNumber(self.liveTool, 0) + 0.5)
    if t < 1 or t > TOOL_COUNT then
        t = math.floor(asNumber(self.toolMode, TOOL_MOVE) + 0.5)
    end
    if t < 1 or t > TOOL_COUNT then
        return TOOL_MOVE
    end
    return t
end

local function setTool(self: PlaneLoader, tool: number)
    if tool < 1 or tool > TOOL_COUNT then
        return
    end
    self.liveTool = tool
    self.hoverTool = tool
    self.dragging = false
    print("tool " .. TOOL_NAMES[tool])
end

local function readTransparent(self: PlaneLoader): boolean
    return asBool(self.transparentBg, false)
end

local function readGuides(self: PlaneLoader): boolean
    if asBool(self.showUI, true) == false then
        return false
    end
    if self.overrideGuides then
        return self.liveGuides
    end
    return asBool(self.showGuides, true)
end

local function readGrid(self: PlaneLoader): boolean
    if readGuides(self) == false then
        return false
    end
    if self.overrideGrid then
        return self.liveGrid
    end
    return asBool(self.showGrid, true)
end

local function packedColor(value: any, fallback: Color): Color
    if type(value) == "number" then
        return value
    end
    return fallback
end

local function readShowOutline(self: PlaneLoader): boolean
    if self.overrideOutline then
        return self.liveShowOutline
    end
    return asBool(self.showOutline, true)
end

local function readOutlineWidth(self: PlaneLoader): number
    if self.overrideOutline then
        return self.liveOutlineWidth
    end
    return asNumber(self.outlineWidth, 3.8)
end

local function readOutlineSmooth(self: PlaneLoader): number
    if self.overrideOutline then
        return self.liveOutlineSmooth
    end
    return math.clamp(asNumber(self.outlineSmooth, 0.82), 0, 1)
end

local function readOutlineScreen(self: PlaneLoader): boolean
    if self.overrideOutline then
        return self.liveOutlineScreen
    end
    return asBool(self.outlineScreen, true)
end

local function readOutlineColor(self: PlaneLoader): Color
    if self.overrideOutline then
        return self.liveOutlineColor
    end
    return packedColor(self.outlineColor, OUTLINE_COLOR)
end

local function ensureLiveOutline(self: PlaneLoader)
    if self.overrideOutline then
        return
    end
    self.liveShowOutline = asBool(self.showOutline, true)
    self.liveOutlineWidth = asNumber(self.outlineWidth, 3.8)
    self.liveOutlineSmooth = math.clamp(asNumber(self.outlineSmooth, 0.82), 0, 1)
    self.liveOutlineScreen = asBool(self.outlineScreen, true)
    self.liveOutlineColor = packedColor(self.outlineColor, OUTLINE_COLOR)
    self.overrideOutline = true
end

local function readPos(self: PlaneLoader): (number, number, number)
    if self.overridePos then
        return self.livePosX, self.livePosY, self.livePosZ
    end
    return asNumber(self.posX, 0), asNumber(self.posY, 0), asNumber(self.posZ, 0)
end

local function readRot(self: PlaneLoader): (number, number, number)
    if self.overrideRot then
        return self.liveRotX, self.liveRotY, self.liveRotZ
    end
    return asNumber(self.rotX, 0), asNumber(self.rotY, 0), asNumber(self.rotZ, 0)
end

local function readScale(self: PlaneLoader): (number, number, number, number)
    local sc = asNumber(self.modelScale, 1)
    if self.overrideScale then
        sc = self.liveScale
        return sc, self.liveScaleX, self.liveScaleY, self.liveScaleZ
    end
    return sc, 1, 1, 1
end

local function bodyModel(self: PlaneLoader): Mat4
    local px, py, pz = readPos(self)
    local rx, ry, rz = readRot(self)
    local sc, sx, sy, sz = readScale(self)
    if sc == 0 then
        sc = 0.0001
    end
    return Mat4.fromTranslation(self.center.x + px, self.center.y + py, self.center.z + pz)
        * Mat4.fromRotationY(math.rad(ry))
        * Mat4.fromRotationX(math.rad(rx))
        * Mat4.fromRotationZ(math.rad(rz))
        * Mat4.fromScale(sc * sx, sc * sy, sc * sz)
        * Mat4.fromTranslation(-self.center.x, -self.center.y, -self.center.z)
end

local function readLight(self: PlaneLoader): (number, number)
    if self.overrideLight then
        return self.liveLightYaw, self.liveLightPitch
    end
    return asNumber(self.lightYaw, 16.5), asNumber(self.lightPitch, 25)
end

local function readCam(self: PlaneLoader): (number, number, number)
    if self.overrideCam then
        return self.liveCamYaw, self.liveCamPitch, self.liveCamDistance
    end
    return asNumber(self.camYaw, 55), asNumber(self.camPitch, 18), asNumber(self.camDistance, 6.6)
end

local function readTarget(self: PlaneLoader): (number, number, number)
    if self.overrideTarget then
        return self.liveTargetX, self.liveTargetY, self.liveTargetZ
    end
    return self.center.x, self.center.y + 0.08, self.center.z
end

local function readOrbit(self: PlaneLoader): boolean
    if self.overrideOrbit then
        return self.liveOrbit
    end
    return asBool(self.orbit, false)
end

local function readCamBob(self: PlaneLoader): boolean
    if self.overrideOrbit then
        return self.liveCamBob
    end
    return asBool(self.camBob, false)
end

local function freezeCameraAnim(self: PlaneLoader)
    if self.overrideOrbit == false then
        self.liveOrbit = false
        self.liveCamBob = false
        self.overrideOrbit = true
    end
end

local function rotMatrix(self: PlaneLoader): Mat4
    local rx, ry, rz = readRot(self)
    return Mat4.fromRotationY(math.rad(ry))
        * Mat4.fromRotationX(math.rad(rx))
        * Mat4.fromRotationZ(math.rad(rz))
end

local function axisDir(self: PlaneLoader, axis: number, localSpace: boolean): (number, number, number)
    if localSpace then
        local m = rotMatrix(self)
        if axis == HANDLE_X then
            local p = m:transformPoint(1, 0, 0)
            return p.x, p.y, p.z
        elseif axis == HANDLE_Y then
            local p = m:transformPoint(0, 1, 0)
            return p.x, p.y, p.z
        end
        local p = m:transformPoint(0, 0, 1)
        return p.x, p.y, p.z
    end
    if axis == HANDLE_X then
        return 1, 0, 0
    elseif axis == HANDLE_Y then
        return 0, 1, 0
    end
    return 0, 0, 1
end

local function objectOrigin(self: PlaneLoader): (number, number, number)
    if currentTool(self) == TOOL_ROTATE and self.selectedBone ~= BONE_NONE then
        local bone = self.bones[self.selectedBone + 1]
        if bone ~= nil then
            local p = bone.world:transformPoint(0, 0, 0)
            return p.x, p.y, p.z
        end
    end
    local px, py, pz = readPos(self)
    return self.center.x + px, self.center.y + py, self.center.z + pz
end

local function lightOrigin(self: PlaneLoader): (number, number, number)
    return self.center.x, self.center.y + 0.2, self.center.z
end

local function gizmoLen(self: PlaneLoader): number
    local span = math.max(self.extent.x, self.extent.y, self.extent.z)
    if currentTool(self) == TOOL_ROTATE and self.selectedBone ~= BONE_NONE then
        return span * 0.38
    end
    return span * 0.62
end

local function sunDir(self: PlaneLoader): Vector
    local yaw, pitch = readLight(self)
    local ly = math.rad(yaw)
    local lp = math.rad(pitch)
    return Vector.xyz(math.cos(lp) * math.cos(ly), math.sin(lp), math.cos(lp) * math.sin(ly))
end

local function project(self: PlaneLoader, x: number, y: number, z: number): (number, number, boolean)
    local cx, cy, _, cw = self.tmpViewProj:transformVec4(x, y, z, 1)
    if cw <= 0.001 then
        return 0, 0, false
    end
    local w = numOr(self.size.x, 800)
    local h = numOr(self.size.y, 800)
    return (cx / cw * 0.5 + 0.5) * w, (0.5 - cy / cw * 0.5) * h, true
end

local function dist2(ax: number, ay: number, bx: number, by: number): number
    local dx = ax - bx
    local dy = ay - by
    return dx * dx + dy * dy
end

local function distToSegment(px: number, py: number, x1: number, y1: number, x2: number, y2: number): number
    local dx = x2 - x1
    local dy = y2 - y1
    local len2 = dx * dx + dy * dy
    if len2 < 1e-6 then
        return math.sqrt(dist2(px, py, x1, y1))
    end
    local t = math.clamp(((px - x1) * dx + (py - y1) * dy) / len2, 0, 1)
    return math.sqrt(dist2(px, py, x1 + dx * t, y1 + dy * t))
end

local function toolbarRect(): (number, number, number, number)
    local w = TOOL_PAD * 2 + BTN
    local h = TOOL_PAD * 2 + TOOL_COUNT * BTN + (TOOL_COUNT - 1) * BTN_GAP
    return TOOL_X, TOOL_Y, w, h
end

local function hitToolbar(px: number, py: number): number
    local x0, y0 = TOOL_X, TOOL_Y
    local bx = x0 + TOOL_PAD
    local by = y0 + TOOL_PAD
    if px < bx or px > bx + BTN then
        return 0
    end
    for i = 1, TOOL_COUNT do
        local y = by + (i - 1) * (BTN + BTN_GAP)
        if py >= y and py <= y + BTN then
            return i
        end
    end
    return 0
end

local function usesLocalAxes(tool: number): boolean
    return tool == TOOL_ROTATE or tool == TOOL_SCALE
end

local function meshIsSelected(self: PlaneLoader): boolean
    return self.selectedId ~= PART_NONE or self.selectedBone ~= BONE_NONE
end

local function quatMat(x: number, y: number, z: number, w: number): Mat4
    local xx, yy, zz = x * x, y * y, z * z
    local xy, xz, yz = x * y, x * z, y * z
    local wx, wy, wz = w * x, w * y, w * z
    return Mat4.values(
        1 - 2 * (yy + zz),
        2 * (xy + wz),
        2 * (xz - wy),
        0,
        2 * (xy - wz),
        1 - 2 * (xx + zz),
        2 * (yz + wx),
        0,
        2 * (xz + wy),
        2 * (yz - wx),
        1 - 2 * (xx + yy),
        0,
        0,
        0,
        0,
        1
    )
end

local function boneLocal(bone: SkelBone): Mat4
    return Mat4.fromTranslation(bone.tx, bone.ty, bone.tz)
        * quatMat(bone.qx, bone.qy, bone.qz, bone.qw)
        * Mat4.fromRotationY(math.rad(bone.liveRY))
        * Mat4.fromRotationX(math.rad(bone.liveRX))
        * Mat4.fromRotationZ(math.rad(bone.liveRZ))
        * Mat4.fromScale(bone.sx * bone.liveSX, bone.sy * bone.liveSY, bone.sz * bone.liveSZ)
end

local function inputRot(self: PlaneLoader, name: string): (number, number, number)
    if name == "LidHinge" then
        return asNumber(self.skelLidHingeX, 0), asNumber(self.skelLidHingeY, 0), asNumber(self.skelLidHingeZ, 0)
    elseif name == "CapHinge" then
        return asNumber(self.skelCapHingeX, 0), asNumber(self.skelCapHingeY, 0), asNumber(self.skelCapHingeZ, 0)
    elseif name == "LidArm" then
        return asNumber(self.skelLidArmX, 0), asNumber(self.skelLidArmY, 0), asNumber(self.skelLidArmZ, 0)
    elseif name == "CapArm" then
        return asNumber(self.skelCapArmX, 0), asNumber(self.skelCapArmY, 0), asNumber(self.skelCapArmZ, 0)
    elseif name == "Chest" then
        return asNumber(self.skelChestX, 0), asNumber(self.skelChestY, 0), asNumber(self.skelChestZ, 0)
    elseif name == "Root" then
        return asNumber(self.skelRootX, 0), asNumber(self.skelRootY, 0), asNumber(self.skelRootZ, 0)
    end
    return 0, 0, 0
end

local function inputScale(self: PlaneLoader, name: string): (number, number, number)
    if name == "Chest" then
        return asNumber(self.skelChestScaleX, 1), asNumber(self.skelChestScaleY, 1), asNumber(self.skelChestScaleZ, 1)
    end
    return 1, 1, 1
end

local function evalBoneKeys(keys: { BoneKey }, t: number): (number, number, number)
    if #keys == 0 then
        return 0, 0, 0
    end
    if t <= keys[1].t then
        return keys[1].rx, keys[1].ry, keys[1].rz
    end
    local last = keys[#keys]
    if t >= last.t then
        return last.rx, last.ry, last.rz
    end
    for i = 1, #keys - 1 do
        local a = keys[i]
        local b = keys[i + 1]
        if t <= b.t then
            local span = math.max(0.0001, b.t - a.t)
            local u = (t - a.t) / span
            return a.rx + (b.rx - a.rx) * u, a.ry + (b.ry - a.ry) * u, a.rz + (b.rz - a.rz) * u
        end
    end
    return last.rx, last.ry, last.rz
end

local function applyBonePose(self: PlaneLoader)
    local t = self.animTime
    local playing = self.animPlaying or self.animScrubbing
    for i, bone in self.bones do
        if bone.isJoint then
            local draggingThis = self.dragging and self.selectedBone == i - 1
            if draggingThis or (bone.posed and playing == false) then
                -- keep gizmo pose until playhead moves or playback starts
            elseif #bone.keys > 0 then
                bone.liveRX, bone.liveRY, bone.liveRZ = evalBoneKeys(bone.keys, t)
                bone.posed = false
            else
                bone.liveRX, bone.liveRY, bone.liveRZ = inputRot(self, bone.name)
            end
        end
        bone.liveSX, bone.liveSY, bone.liveSZ = inputScale(self, bone.name)
    end
end

local function insertBoneKey(self: PlaneLoader)
    local t = self.animTime
    local count = 0
    for i, bone in self.bones do
        local take = bone.isJoint and (self.selectedBone == BONE_NONE or self.selectedBone == i - 1)
        if take then
            local replaced = false
            for _, key in bone.keys do
                if math.abs(key.t - t) < 0.04 then
                    key.t = t
                    key.rx = bone.liveRX
                    key.ry = bone.liveRY
                    key.rz = bone.liveRZ
                    replaced = true
                    break
                end
            end
            if replaced == false then
                table.insert(bone.keys, {
                    t = t,
                    rx = bone.liveRX,
                    ry = bone.liveRY,
                    rz = bone.liveRZ,
                })
                table.sort(bone.keys, function(a: BoneKey, b: BoneKey)
                    return a.t < b.t
                end)
            end
            bone.posed = true
            count += 1
            if t > self.animDuration - 0.05 then
                self.animDuration = math.min(12, t + 0.5)
            end
            print(string.format("key %s @ %.2fs  %.1f %.1f %.1f", bone.name, t, bone.liveRX, bone.liveRY, bone.liveRZ))
        end
    end
    if count == 0 then
        print("select a joint, pose it, then key")
    end
end

local function stepAnimKey(self: PlaneLoader, dir: number)
    local times = {}
    for _, bone in self.bones do
        for _, key in bone.keys do
            table.insert(times, key.t)
        end
    end
    if #times == 0 then
        return
    end
    table.sort(times)
    for _, bone in self.bones do
        if #bone.keys > 0 then
            bone.posed = false
        end
    end
    local t = self.animTime
    if dir > 0 then
        for _, kt in times do
            if kt > t + 0.02 then
                self.animTime = kt
                self.animPlaying = false
                return
            end
        end
        self.animTime = times[#times]
    else
        for i = #times, 1, -1 do
            if times[i] < t - 0.02 then
                self.animTime = times[i]
                self.animPlaying = false
                return
            end
        end
        self.animTime = times[1]
    end
    self.animPlaying = false
end

local function toggleAnimPlay(self: PlaneLoader)
    self.animPlaying = not self.animPlaying
    if self.animPlaying and self.animTime >= self.animDuration - 0.001 then
        self.animTime = 0
    end
    for _, bone in self.bones do
        if #bone.keys > 0 then
            bone.posed = false
        end
    end
    print(if self.animPlaying then "anim play" else "anim pause")
end

local function updateBones(self: PlaneLoader, model: Mat4)
    local bones = self.bones
    if #bones == 0 then
        return
    end
    applyBonePose(self)
    local done: { boolean } = {}
    local function eval(index: number): Mat4
        if done[index + 1] then
            return bones[index + 1].world
        end
        local bone = bones[index + 1]
        local localM = boneLocal(bone)
        if bone.parent < 0 then
            bone.world = model * localM
        else
            bone.world = eval(bone.parent) * localM
        end
        done[index + 1] = true
        return bone.world
    end
    for i = 0, #bones - 1 do
        eval(i)
    end
end

local function boneOrigin(self: PlaneLoader, index: number): (number, number, number)
    local bone = self.bones[index + 1]
    if bone == nil then
        return 0, 0, 0
    end
    local p = bone.world:transformPoint(0, 0, 0)
    return p.x, p.y, p.z
end

local function controllingJoint(self: PlaneLoader, boneIndex: number): number
    local i = boneIndex
    while i >= 0 do
        local bone = self.bones[i + 1]
        if bone == nil then
            return BONE_NONE
        end
        if bone.isJoint then
            return i
        end
        i = bone.parent
    end
    return BONE_NONE
end

local function selectHoveredPart(self: PlaneLoader): boolean
    if self.hoverId == PART_NONE then
        return false
    end
    self.selectedId = self.hoverId
    self.selectedBone = BONE_NONE
    local partName = ""
    local partBone = BONE_NONE
    for _, part in self.parts do
        if part.partId == self.selectedId then
            partName = part.name
            partBone = part.bone
            break
        end
    end
    if currentTool(self) == TOOL_ROTATE then
        local joint = controllingJoint(self, partBone)
        if joint ~= BONE_NONE then
            self.selectedBone = joint
            self.selectedId = PART_NONE
            print("bone " .. self.bones[joint + 1].name .. " via " .. partName)
            return true
        end
    end
    print("tracking " .. partName)
    return true
end

local function gizmoTool(tool: number): boolean
    return tool == TOOL_MOVE or tool == TOOL_ROTATE or tool == TOOL_SCALE
end

local function hitGizmo(self: PlaneLoader, px: number, py: number, tool: number): number
    local ox, oy, oz
    if tool == TOOL_LIGHT then
        ox, oy, oz = lightOrigin(self)
    else
        ox, oy, oz = objectOrigin(self)
    end
    local sx, sy, vis = project(self, ox, oy, oz)
    if vis == false then
        return HANDLE_NONE
    end
    local best = HANDLE_NONE
    local bestD = GIZMO_HIT
    if tool == TOOL_LIGHT then
        local sun = sunDir(self)
        local len = gizmoLen(self) * 1.15
        local tx, ty, tvis = project(self, ox + sun.x * len, oy + sun.y * len, oz + sun.z * len)
        if tvis then
            local d = distToSegment(px, py, sx, sy, tx, ty)
            if d < bestD then
                return HANDLE_UNI
            end
            if math.sqrt(dist2(px, py, tx, ty)) < 14 then
                return HANDLE_UNI
            end
        end
        return HANDLE_NONE
    end
    if math.sqrt(dist2(px, py, sx, sy)) < 11 then
        return HANDLE_UNI
    end
    local len = gizmoLen(self)
    local localSpace = usesLocalAxes(tool)
    if tool == TOOL_ROTATE then
            for axis = HANDLE_X, HANDLE_Z do
            local ux, uy, uz = 0, 1, 0
            local vx, vy, vz = 0, 0, 1
            if axis == HANDLE_X then
                ux, uy, uz = 0, 1, 0
                vx, vy, vz = 0, 0, 1
            elseif axis == HANDLE_Y then
                ux, uy, uz = 1, 0, 0
                vx, vy, vz = 0, 0, 1
            else
                ux, uy, uz = 1, 0, 0
                vx, vy, vz = 0, 1, 0
            end
            local prevx = 0
            local prevy = 0
            local prevVis = false
            for i = 0, 48 do
                local a = (i / 48) * math.pi * 2
                local c = math.cos(a)
                local s = math.sin(a)
                local wx = ox + (ux * c + vx * s) * len
                local wy = oy + (uy * c + vy * s) * len
                local wz = oz + (uz * c + vz * s) * len
                local qx, qy, qvis = project(self, wx, wy, wz)
                if qvis and prevVis then
                    local d = distToSegment(px, py, prevx, prevy, qx, qy)
                    if d < bestD then
                        bestD = d
                        best = axis
                    end
                end
                prevx = qx
                prevy = qy
                prevVis = qvis
            end
        end
        return best
    end
    for axis = HANDLE_X, HANDLE_Z do
        local ax, ay, az = axisDir(self, axis, localSpace)
        local tx, ty, tvis = project(self, ox + ax * len, oy + ay * len, oz + az * len)
        if tvis then
            local d = distToSegment(px, py, sx, sy, tx, ty)
            if d < bestD then
                bestD = d
                best = axis
            end
            if math.sqrt(dist2(px, py, tx, ty)) < 14 then
                bestD = 0
                best = axis
            end
        end
    end
    return best
end

local function screenDeltaToWorld(
    self: PlaneLoader,
    ox: number,
    oy: number,
    oz: number,
    dx: number,
    dy: number
): (number, number, number)
    if dx == 0 and dy == 0 then
        return 0, 0, 0
    end
    local sx, sy, vis = project(self, ox, oy, oz)
    if vis == false then
        return 0, 0, 0
    end
    local inv = self.tmpViewProj:invert()
    if inv == nil then
        return 0, 0, 0
    end
    local w = numOr(self.size.x, 800)
    local h = numOr(self.size.y, 800)
    local ndc = self.tmpViewProj:transformPoint(ox, oy, oz)
    local function unproject(px: number, py: number): Vector
        local ndcX = (px / w) * 2 - 1
        local ndcY = 1 - (py / h) * 2
        return inv:transformPoint(ndcX, ndcY, ndc.z)
    end
    local a = unproject(sx, sy)
    local b = unproject(sx + dx, sy + dy)
    return b.x - a.x, b.y - a.y, b.z - a.z
end

local function beginDrag(self: PlaneLoader, tool: number, handle: number, px: number, py: number)
    self.dragging = true
    self.dragTool = tool
    self.dragHandle = handle
    self.lastDragX = px
    self.lastDragY = py
    if tool == TOOL_MOVE then
        local x, y, z = readPos(self)
        self.livePosX = x
        self.livePosY = y
        self.livePosZ = z
        self.overridePos = true
        freezeCameraAnim(self)
    elseif tool == TOOL_ROTATE then
        if self.selectedBone == BONE_NONE then
            local x, y, z = readRot(self)
            self.liveRotX = x
            self.liveRotY = y
            self.liveRotZ = z
            self.overrideRot = true
        end
        freezeCameraAnim(self)
    elseif tool == TOOL_SCALE then
        local sc, sx, sy, sz = readScale(self)
        self.liveScale = sc
        self.liveScaleX = sx
        self.liveScaleY = sy
        self.liveScaleZ = sz
        self.overrideScale = true
        freezeCameraAnim(self)
    elseif tool == TOOL_LIGHT then
        local yaw, pitch = readLight(self)
        self.liveLightYaw = yaw
        self.liveLightPitch = pitch
        self.overrideLight = true
    elseif tool == TOOL_CAMERA then
        local yaw, pitch, dist = readCam(self)
        self.liveCamYaw = yaw
        self.liveCamPitch = pitch
        self.liveCamDistance = dist
        self.overrideCam = true
        local tx, ty, tz = readTarget(self)
        self.liveTargetX = tx
        self.liveTargetY = ty
        self.liveTargetZ = tz
        freezeCameraAnim(self)
    end
end

local function applyDrag(self: PlaneLoader, px: number, py: number)
    local dx = px - self.lastDragX
    local dy = py - self.lastDragY
    local tool = self.dragTool
    local handle = self.dragHandle
    local ox, oy, oz = objectOrigin(self)
    if tool == TOOL_CAMERA then
        local tox, toy, toz = readTarget(self)
        if handle == HANDLE_UNI then
            local wx, wy, wz = screenDeltaToWorld(self, tox, toy, toz, dx, dy)
            self.liveTargetX += wx
            self.liveTargetY += wy
            self.liveTargetZ += wz
            self.overrideTarget = true
        elseif handle == HANDLE_DOLLY or handle == HANDLE_Z then
            self.liveCamDistance = math.clamp(self.liveCamDistance - dy * 0.012, 1.2, 12)
        else
            self.liveCamYaw += dx * 0.35
            self.liveCamPitch = math.clamp(self.liveCamPitch + dy * 0.35, -80, 80)
        end
    elseif tool == TOOL_LIGHT then
        self.liveLightYaw += dx * 0.45
        self.liveLightPitch = math.clamp(self.liveLightPitch - dy * 0.45, -85, 85)
    elseif tool == TOOL_MOVE then
        local wx, wy, wz = screenDeltaToWorld(self, ox, oy, oz, dx, dy)
        if handle == HANDLE_UNI then
            self.livePosX += wx
            self.livePosY += wy
            self.livePosZ += wz
        else
            local ax, ay, az = axisDir(self, handle, false)
            local along = wx * ax + wy * ay + wz * az
            self.livePosX += ax * along
            self.livePosY += ay * along
            self.livePosZ += az * along
        end
    elseif tool == TOOL_ROTATE then
        local sx, sy, vis = project(self, ox, oy, oz)
        if vis then
            local a0 = math.atan2(self.lastDragY - sy, self.lastDragX - sx)
            local a1 = math.atan2(py - sy, px - sx)
            local ddeg = math.deg(a1 - a0)
            if ddeg > 180 then
                ddeg -= 360
            elseif ddeg < -180 then
                ddeg += 360
            end
            local ax, ay, az = axisDir(self, handle, true)
            local toEye = Vector.xyz(self.eyePos.x - ox, self.eyePos.y - oy, self.eyePos.z - oz)
            if ax * toEye.x + ay * toEye.y + az * toEye.z < 0 then
                ddeg = -ddeg
            end
            if self.selectedBone ~= BONE_NONE then
                local bone = self.bones[self.selectedBone + 1]
                if bone ~= nil then
                    bone.posed = true
                    if handle == HANDLE_X then
                        bone.liveRX += ddeg
                    elseif handle == HANDLE_Y then
                        bone.liveRY += ddeg
                    elseif handle == HANDLE_Z then
                        bone.liveRZ += ddeg
                    else
                        bone.liveRY += dx * 0.4
                        bone.liveRX += dy * 0.4
                    end
                end
            elseif handle == HANDLE_X then
                self.liveRotX += ddeg
            elseif handle == HANDLE_Y then
                self.liveRotY += ddeg
            elseif handle == HANDLE_Z then
                self.liveRotZ += ddeg
            else
                self.liveRotY += dx * 0.4
                self.liveRotX += dy * 0.4
            end
        end
    elseif tool == TOOL_SCALE then
        local sx, sy, vis = project(self, ox, oy, oz)
        if vis then
            local d0 = math.max(10, math.sqrt(dist2(self.lastDragX, self.lastDragY, sx, sy)))
            local d1 = math.max(10, math.sqrt(dist2(px, py, sx, sy)))
            local f = math.clamp(d1 / d0, 0.94, 1.06)
            if handle == HANDLE_UNI or handle == HANDLE_NONE then
                self.liveScale = math.clamp(self.liveScale * f, 0.05, 8)
            elseif handle == HANDLE_X then
                self.liveScaleX = math.clamp(self.liveScaleX * f, 0.05, 8)
            elseif handle == HANDLE_Y then
                self.liveScaleY = math.clamp(self.liveScaleY * f, 0.05, 8)
            else
                self.liveScaleZ = math.clamp(self.liveScaleZ * f, 0.05, 8)
            end
        end
    end
    self.lastDragX = px
    self.lastDragY = py
end

local function nextPath(self: PlaneLoader): Path
    self.uiCursor += 1
    local p = self.uiPaths[self.uiCursor]
    if p == nil then
        p = Path.new()
        self.uiPaths[self.uiCursor] = p
    end
    p:reset()
    return p
end

local function addRect(path: Path, x: number, y: number, w: number, h: number)
    path:moveTo(Vector.xy(x, y))
    path:lineTo(Vector.xy(x + w, y))
    path:lineTo(Vector.xy(x + w, y + h))
    path:lineTo(Vector.xy(x, y + h))
    path:close()
end

local function addLine(path: Path, x1: number, y1: number, x2: number, y2: number)
    path:moveTo(Vector.xy(x1, y1))
    path:lineTo(Vector.xy(x2, y2))
end

local function addCircle(path: Path, cx: number, cy: number, r: number)
    local k = 0.5522847 * r
    path:moveTo(Vector.xy(cx + r, cy))
    path:cubicTo(Vector.xy(cx + r, cy + k), Vector.xy(cx + k, cy + r), Vector.xy(cx, cy + r))
    path:cubicTo(Vector.xy(cx - k, cy + r), Vector.xy(cx - r, cy + k), Vector.xy(cx - r, cy))
    path:cubicTo(Vector.xy(cx - r, cy - k), Vector.xy(cx - k, cy - r), Vector.xy(cx, cy - r))
    path:cubicTo(Vector.xy(cx + k, cy - r), Vector.xy(cx + r, cy - k), Vector.xy(cx + r, cy))
    path:close()
end

local function addTriangle(path: Path, x1: number, y1: number, x2: number, y2: number, x3: number, y3: number)
    path:moveTo(Vector.xy(x1, y1))
    path:lineTo(Vector.xy(x2, y2))
    path:lineTo(Vector.xy(x3, y3))
    path:close()
end

local function drawIcon(self: PlaneLoader, renderer: Renderer, tool: number, bx: number, by: number)
    local cx = bx + BTN * 0.5
    local cy = by + BTN * 0.5
    local path = nextPath(self)
    local paint = self.strokePaint
    paint.style = "stroke"
    paint.thickness = 1.8
    paint.cap = "round"
    paint.join = "round"
    paint.color = Color.rgb(236, 244, 255)
    if tool == TOOL_SELECT then
        path:moveTo(Vector.xy(cx - 8, cy - 11))
        path:lineTo(Vector.xy(cx - 8, cy + 9))
        path:lineTo(Vector.xy(cx - 3, cy + 3))
        path:lineTo(Vector.xy(cx + 3, cy + 11))
        path:lineTo(Vector.xy(cx + 6, cy + 9))
        path:lineTo(Vector.xy(cx + 0.5, cy + 1))
        path:lineTo(Vector.xy(cx + 9, cy + 1))
        path:close()
        paint.style = "fill"
        renderer:drawPath(path, paint)
    elseif tool == TOOL_MOVE then
        addLine(path, cx, cy - 12, cx, cy + 12)
        addLine(path, cx - 12, cy, cx + 12, cy)
        renderer:drawPath(path, paint)
        local heads = nextPath(self)
        paint.style = "fill"
        addTriangle(heads, cx, cy - 14, cx - 4, cy - 8, cx + 4, cy - 8)
        addTriangle(heads, cx, cy + 14, cx - 4, cy + 8, cx + 4, cy + 8)
        addTriangle(heads, cx - 14, cy, cx - 8, cy - 4, cx - 8, cy + 4)
        addTriangle(heads, cx + 14, cy, cx + 8, cy - 4, cx + 8, cy + 4)
        renderer:drawPath(heads, paint)
    elseif tool == TOOL_ROTATE then
        path:moveTo(Vector.xy(cx + 10, cy))
        path:cubicTo(Vector.xy(cx + 10, cy + 8), Vector.xy(cx + 5, cy + 12), Vector.xy(cx, cy + 12))
        path:cubicTo(Vector.xy(cx - 8, cy + 12), Vector.xy(cx - 12, cy + 5), Vector.xy(cx - 12, cy))
        path:cubicTo(Vector.xy(cx - 12, cy - 6), Vector.xy(cx - 6, cy - 12), Vector.xy(cx + 1, cy - 12))
        renderer:drawPath(path, paint)
        local head = nextPath(self)
        paint.style = "fill"
        addTriangle(head, cx + 10, cy - 1, cx + 4, cy - 8, cx + 14, cy - 8)
        renderer:drawPath(head, paint)
    elseif tool == TOOL_SCALE then
        addLine(path, cx - 9, cy - 9, cx - 4, cy - 4)
        addLine(path, cx + 9, cy + 9, cx + 4, cy + 4)
        renderer:drawPath(path, paint)
        local boxes = nextPath(self)
        paint.style = "fill"
        addRect(boxes, cx - 13, cy - 13, 7, 7)
        addRect(boxes, cx + 6, cy + 6, 7, 7)
        renderer:drawPath(boxes, paint)
    elseif tool == TOOL_LIGHT then
        addCircle(path, cx, cy, 5)
        for i = 0, 7 do
            local a = i * math.pi / 4
            local c = math.cos(a)
            local s = math.sin(a)
            addLine(path, cx + c * 8, cy + s * 8, cx + c * 13, cy + s * 13)
        end
        renderer:drawPath(path, paint)
    else
        addRect(path, cx - 9, cy - 5, 14, 11)
        addCircle(path, cx + 7, cy, 5)
        addRect(path, cx - 3, cy - 9, 6, 4)
        renderer:drawPath(path, paint)
    end
end

local function axisColor(axis: number, hover: boolean): Color
    if axis == HANDLE_X then
        return if hover then Color.rgb(255, 140, 120) else AXIS_RED
    elseif axis == HANDLE_Y then
        return if hover then Color.rgb(140, 255, 150) else AXIS_GREEN
    elseif axis == HANDLE_Z then
        return if hover then Color.rgb(130, 180, 255) else AXIS_BLUE
    end
    return Color.rgb(240, 240, 240)
end

local function drawArrowHead(
    self: PlaneLoader,
    renderer: Renderer,
    x1: number,
    y1: number,
    x2: number,
    y2: number,
    color: Color
)
    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 4 then
        return
    end
    local nx = dx / len
    local ny = dy / len
    local px = -ny
    local py = nx
    local path = nextPath(self)
    addTriangle(
        path,
        x2,
        y2,
        x2 - nx * 12 + px * 5,
        y2 - ny * 12 + py * 5,
        x2 - nx * 12 - px * 5,
        y2 - ny * 12 - py * 5
    )
    local paint = self.fillPaint
    paint.style = "fill"
    paint.color = color
    renderer:drawPath(path, paint)
end

local function drawProjectedCircle(
    self: PlaneLoader,
    renderer: Renderer,
    ox: number,
    oy: number,
    oz: number,
    ux: number,
    uy: number,
    uz: number,
    vx: number,
    vy: number,
    vz: number,
    radius: number,
    color: Color,
    thick: number
)
    local path = nextPath(self)
    local started = false
    for i = 0, 48 do
        local a = (i / 48) * math.pi * 2
        local c = math.cos(a)
        local s = math.sin(a)
        local wx = ox + (ux * c + vx * s) * radius
        local wy = oy + (uy * c + vy * s) * radius
        local wz = oz + (uz * c + vz * s) * radius
        local qx, qy, vis = project(self, wx, wy, wz)
        if vis then
            if started then
                path:lineTo(Vector.xy(qx, qy))
            else
                path:moveTo(Vector.xy(qx, qy))
                started = true
            end
        else
            started = false
        end
    end
    local paint = self.strokePaint
    paint.style = "stroke"
    paint.thickness = thick
    paint.cap = "round"
    paint.join = "round"
    paint.color = color
    renderer:drawPath(path, paint)
end

local function drawToolbar(self: PlaneLoader, renderer: Renderer)
    local x0, y0, pw, ph = toolbarRect()
    local panel = nextPath(self)
    addRect(panel, x0, y0, pw, ph)
    local fill = self.fillPaint
    fill.style = "fill"
    fill.color = Color.rgba(8, 14, 24, 220)
    renderer:drawPath(panel, fill)
    local stroke = self.strokePaint
    stroke.style = "stroke"
    stroke.thickness = 1.2
    stroke.color = Color.rgba(90, 150, 190, 90)
    renderer:drawPath(panel, stroke)
    local tool = currentTool(self)
    for i = 1, TOOL_COUNT do
        local bx = x0 + TOOL_PAD
        local by = y0 + TOOL_PAD + (i - 1) * (BTN + BTN_GAP)
        local btn = nextPath(self)
        addRect(btn, bx, by, BTN, BTN)
        if tool == i then
            fill.color = Color.rgba(48, 92, 128, 240)
        elseif self.hoverTool == i then
            fill.color = Color.rgba(32, 52, 78, 230)
        else
            fill.color = Color.rgba(18, 30, 46, 230)
        end
        fill.style = "fill"
        renderer:drawPath(btn, fill)
        stroke.style = "stroke"
        stroke.thickness = if tool == i then 2 else 1
        stroke.color = if tool == i then Color.rgb(255, 196, 110) else Color.rgba(80, 110, 140, 80)
        renderer:drawPath(btn, stroke)
        drawIcon(self, renderer, i, bx, by)
    end
end

local function drawGizmos(self: PlaneLoader, renderer: Renderer)
    local tool = currentTool(self)
    if tool == TOOL_SELECT or tool == TOOL_CAMERA then
        return
    end
    if tool ~= TOOL_LIGHT and meshIsSelected(self) == false and self.dragging == false then
        return
    end
    local ox, oy, oz
    if tool == TOOL_LIGHT then
        ox, oy, oz = lightOrigin(self)
    else
        ox, oy, oz = objectOrigin(self)
    end
    local sx, sy, vis = project(self, ox, oy, oz)
    if vis == false then
        return
    end
    local len = gizmoLen(self)
    local hover = self.hoverHandle
    if self.dragging then
        hover = self.dragHandle
    end
    if tool == TOOL_LIGHT then
        local sun = sunDir(self)
        local tx, ty, tvis = project(self, ox + sun.x * len * 1.15, oy + sun.y * len * 1.15, oz + sun.z * len * 1.15)
        if tvis then
            local path = nextPath(self)
            addLine(path, sx, sy, tx, ty)
            local paint = self.strokePaint
            paint.style = "stroke"
            paint.thickness = if hover == HANDLE_UNI then 4 else 2.6
            paint.color = Color.rgb(255, 214, 96)
            renderer:drawPath(path, paint)
            drawArrowHead(self, renderer, sx, sy, tx, ty, Color.rgb(255, 214, 96))
            local disc = nextPath(self)
            addCircle(disc, tx, ty, 7)
            local fill = self.fillPaint
            fill.style = "fill"
            fill.color = Color.rgb(255, 230, 140)
            renderer:drawPath(disc, fill)
        end
        return
    end
    if tool == TOOL_ROTATE then
        drawProjectedCircle(self, renderer, ox, oy, oz, 0, 1, 0, 0, 0, 1, len, axisColor(HANDLE_X, hover == HANDLE_X), if hover == HANDLE_X then 3.4 else 2)
        drawProjectedCircle(self, renderer, ox, oy, oz, 1, 0, 0, 0, 0, 1, len, axisColor(HANDLE_Y, hover == HANDLE_Y), if hover == HANDLE_Y then 3.4 else 2)
        drawProjectedCircle(self, renderer, ox, oy, oz, 1, 0, 0, 0, 1, 0, len, axisColor(HANDLE_Z, hover == HANDLE_Z), if hover == HANDLE_Z then 3.4 else 2)
        local core = nextPath(self)
        addCircle(core, sx, sy, 5)
        local fill = self.fillPaint
        fill.style = "fill"
        fill.color = Color.rgb(250, 250, 250)
        renderer:drawPath(core, fill)
        return
    end
    local localSpace = usesLocalAxes(tool)
    for axis = HANDLE_X, HANDLE_Z do
        local ax, ay, az = axisDir(self, axis, localSpace)
        local tx, ty, tvis = project(self, ox + ax * len, oy + ay * len, oz + az * len)
        if tvis then
            local col = axisColor(axis, hover == axis)
            local path = nextPath(self)
            addLine(path, sx, sy, tx, ty)
            local paint = self.strokePaint
            paint.style = "stroke"
            paint.thickness = if hover == axis then 4 else 2.5
            paint.color = col
            renderer:drawPath(path, paint)
            if tool == TOOL_SCALE then
                local box = nextPath(self)
                addRect(box, tx - 6, ty - 6, 12, 12)
                local fill = self.fillPaint
                fill.style = "fill"
                fill.color = col
                renderer:drawPath(box, fill)
            else
                drawArrowHead(self, renderer, sx, sy, tx, ty, col)
            end
        end
    end
    local core = nextPath(self)
    if tool == TOOL_SCALE then
        addRect(core, sx - 6, sy - 6, 12, 12)
    else
        addCircle(core, sx, sy, 5)
    end
    local fill = self.fillPaint
    fill.style = "fill"
    fill.color = if hover == HANDLE_UNI then Color.rgb(255, 220, 140) else Color.rgb(245, 245, 245)
    renderer:drawPath(core, fill)
end

local function cameraGizmoLen(self: PlaneLoader): number
    return math.max(self.extent.x, self.extent.y, self.extent.z) * 0.72
end

local function hitCameraGizmo(self: PlaneLoader, px: number, py: number): number
    if asBool(self.showCamGizmo, true) == false then
        return HANDLE_NONE
    end
    local ox, oy, oz = readTarget(self)
    local sx, sy, vis = project(self, ox, oy, oz)
    if vis == false then
        return HANDLE_NONE
    end
    if math.sqrt(dist2(px, py, sx, sy)) < 12 then
        return HANDLE_UNI
    end
    local len = cameraGizmoLen(self)
    local eye = self.eyePos
    local dx = eye.x - ox
    local dy = eye.y - oy
    local dz = eye.z - oz
    local elen = math.max(0.001, math.sqrt(dx * dx + dy * dy + dz * dz))
    local dl = len * 0.85
    local tx, ty, tvis = project(self, ox + dx / elen * dl, oy + dy / elen * dl, oz + dz / elen * dl)
    if tvis and math.sqrt(dist2(px, py, tx, ty)) < 14 then
        return HANDLE_DOLLY
    end
    local best = HANDLE_NONE
    local bestD = GIZMO_HIT
    local function hitRing(ux: number, uy: number, uz: number, vx: number, vy: number, vz: number, handle: number)
        local prevx = 0
        local prevy = 0
        local prevVis = false
        for i = 0, 48 do
            local a = (i / 48) * math.pi * 2
            local c = math.cos(a)
            local s = math.sin(a)
            local wx = ox + (ux * c + vx * s) * len
            local wy = oy + (uy * c + vy * s) * len
            local wz = oz + (uz * c + vz * s) * len
            local qx, qy, qvis = project(self, wx, wy, wz)
            if qvis and prevVis then
                local d = distToSegment(px, py, prevx, prevy, qx, qy)
                if d < bestD then
                    bestD = d
                    best = handle
                end
            end
            prevx = qx
            prevy = qy
            prevVis = qvis
        end
    end
    hitRing(1, 0, 0, 0, 0, 1, HANDLE_X)
    local rx = -dz / elen
    local rz = dx / elen
    local rlen = math.max(0.001, math.sqrt(rx * rx + rz * rz))
    hitRing(rx / rlen, 0, rz / rlen, 0, 1, 0, HANDLE_Y)
    return best
end

local function drawCameraGizmos(self: PlaneLoader, renderer: Renderer)
    if asBool(self.showCamGizmo, true) == false then
        return
    end
    local ox, oy, oz = readTarget(self)
    local sx, sy, vis = project(self, ox, oy, oz)
    if vis == false then
        return
    end
    local len = cameraGizmoLen(self)
    local hover = self.hoverHandle
    if self.dragging and self.dragTool == TOOL_CAMERA then
        hover = self.dragHandle
    end
    drawProjectedCircle(self, renderer, ox, oy, oz, 1, 0, 0, 0, 0, 1, len, if hover == HANDLE_X then Color.rgb(120, 230, 255) else Color.rgb(56, 196, 230), if hover == HANDLE_X then 3.2 else 2)
    local eye = self.eyePos
    local dx = eye.x - ox
    local dy = eye.y - oy
    local dz = eye.z - oz
    local elen = math.max(0.001, math.sqrt(dx * dx + dy * dy + dz * dz))
    local rx = -dz / elen
    local rz = dx / elen
    local rlen = math.max(0.001, math.sqrt(rx * rx + rz * rz))
    drawProjectedCircle(self, renderer, ox, oy, oz, rx / rlen, 0, rz / rlen, 0, 1, 0, len, if hover == HANDLE_Y then Color.rgb(255, 210, 120) else Color.rgb(230, 170, 64), if hover == HANDLE_Y then 3.2 else 2)
    local dl = len * 0.85
    local camx = ox + dx / elen * dl
    local camy = oy + dy / elen * dl
    local camz = oz + dz / elen * dl
    local tx, ty, tvis = project(self, camx, camy, camz)
    if tvis then
        local path = nextPath(self)
        addLine(path, sx, sy, tx, ty)
        local paint = self.strokePaint
        paint.style = "stroke"
        paint.thickness = if hover == HANDLE_DOLLY then 3.4 else 2
        paint.color = if hover == HANDLE_DOLLY then Color.rgb(180, 255, 210) else Color.rgb(90, 220, 170)
        renderer:drawPath(path, paint)
        local body = nextPath(self)
        addRect(body, tx - 8, ty - 6, 16, 12)
        addTriangle(body, tx + 8, ty - 4, tx + 16, ty, tx + 8, ty + 4)
        local fill = self.fillPaint
        fill.style = "fill"
        fill.color = if hover == HANDLE_DOLLY then Color.rgb(160, 255, 210) else Color.rgb(72, 210, 170)
        renderer:drawPath(body, fill)
    end
    local core = nextPath(self)
    addCircle(core, sx, sy, 6)
    local fill = self.fillPaint
    fill.style = "fill"
    fill.color = if hover == HANDLE_UNI then Color.rgb(255, 230, 140) else Color.rgb(240, 248, 255)
    renderer:drawPath(core, fill)
    local ring = nextPath(self)
    addCircle(ring, sx, sy, 6)
    local stroke = self.strokePaint
    stroke.style = "stroke"
    stroke.thickness = 1.6
    stroke.color = Color.rgb(80, 170, 220)
    renderer:drawPath(ring, stroke)
end

local function viewCubePos(self: PlaneLoader): (number, number)
    local w = numOr(self.size.x, 800)
    return w - 58, 58
end

local function zoomButtonPos(self: PlaneLoader, which: number): (number, number)
    local cx, cy = viewCubePos(self)
    if which == 1 then
        return cx, cy + 48
    end
    return cx, cy + 92
end

local function hitZoom(self: PlaneLoader, px: number, py: number): number
    for i = 1, 2 do
        local cx, cy = zoomButtonPos(self, i)
        if dist2(px, py, cx, cy) <= 18 * 18 then
            return i
        end
    end
    return 0
end

local function outlinePanelOrigin(self: PlaneLoader): (number, number)
    local h = numOr(self.size.y, 800)
    return 14, h - 70
end

local function outlineButtonRect(self: PlaneLoader, which: number): (number, number, number, number)
    local x0, y0 = outlinePanelOrigin(self)
    local bx = x0 + TOOL_PAD + (which - 1) * (OUT_BTN + BTN_GAP)
    local by = y0 + TOOL_PAD
    return bx, by, OUT_BTN, OUT_BTN
end

local function hitOutline(self: PlaneLoader, px: number, py: number): number
    for i = 1, OUT_COUNT do
        local x, y, w, h = outlineButtonRect(self, i)
        if px >= x and px <= x + w and py >= y and py <= y + h then
            return i
        end
    end
    return 0
end

local function applyOutline(self: PlaneLoader, which: number)
    ensureLiveOutline(self)
    if which == OUT_TOGGLE then
        self.liveShowOutline = not self.liveShowOutline
        print(if self.liveShowOutline then "outline on" else "outline off")
    elseif which == OUT_WDEC then
        self.liveOutlineWidth = math.clamp(self.liveOutlineWidth - 0.45, 0, 12)
        print(string.format("outline width %.2f", self.liveOutlineWidth))
    elseif which == OUT_WINC then
        self.liveOutlineWidth = math.clamp(self.liveOutlineWidth + 0.45, 0, 12)
        print(string.format("outline width %.2f", self.liveOutlineWidth))
    elseif which == OUT_SDEC then
        self.liveOutlineSmooth = math.clamp(self.liveOutlineSmooth - 0.15, 0, 1)
        print(string.format("outline smooth %.2f", self.liveOutlineSmooth))
    elseif which == OUT_SINC then
        self.liveOutlineSmooth = math.clamp(self.liveOutlineSmooth + 0.15, 0, 1)
        print(string.format("outline smooth %.2f", self.liveOutlineSmooth))
    elseif which == OUT_SCREEN then
        self.liveOutlineScreen = not self.liveOutlineScreen
        print(if self.liveOutlineScreen then "outline even (screen)" else "outline mesh")
    elseif which == OUT_COLOR then
        self.liveOutlinePreset = self.liveOutlinePreset % #OUTLINE_PRESETS + 1
        self.liveOutlineColor = OUTLINE_PRESETS[self.liveOutlinePreset]
        print("outline color " .. self.liveOutlinePreset)
    end
end

local function drawOutlineIcon(self: PlaneLoader, renderer: Renderer, which: number, x: number, y: number)
    local stroke = self.strokePaint
    local fill = self.fillPaint
    local cx = x + OUT_BTN * 0.5
    local cy = y + OUT_BTN * 0.5
    stroke.style = "stroke"
    stroke.cap = "round"
    stroke.join = "round"
    stroke.color = Color.rgb(236, 244, 255)
    if which == OUT_TOGGLE then
        local ring = nextPath(self)
        addCircle(ring, cx, cy, 8)
        stroke.thickness = if readShowOutline(self) then 2.4 else 1.4
        renderer:drawPath(ring, stroke)
        if readShowOutline(self) then
            local core = nextPath(self)
            addCircle(core, cx, cy, 3.2)
            fill.style = "fill"
            fill.color = Color.rgb(255, 196, 110)
            renderer:drawPath(core, fill)
        end
    elseif which == OUT_WDEC then
        local path = nextPath(self)
        addLine(path, cx - 8, cy, cx + 8, cy)
        stroke.thickness = 2
        renderer:drawPath(path, stroke)
    elseif which == OUT_WINC then
        local path = nextPath(self)
        addLine(path, cx - 8, cy, cx + 8, cy)
        addLine(path, cx, cy - 8, cx, cy + 8)
        stroke.thickness = 2.4
        renderer:drawPath(path, stroke)
    elseif which == OUT_SDEC then
        local path = nextPath(self)
        path:moveTo(Vector.xy(cx - 10, cy + 4))
        path:lineTo(Vector.xy(cx - 4, cy - 6))
        path:lineTo(Vector.xy(cx + 2, cy + 5))
        path:lineTo(Vector.xy(cx + 10, cy - 4))
        stroke.thickness = 2
        renderer:drawPath(path, stroke)
    elseif which == OUT_SINC then
        local path = nextPath(self)
        path:moveTo(Vector.xy(cx - 10, cy + 3))
        path:cubicTo(Vector.xy(cx - 4, cy - 8), Vector.xy(cx + 4, cy + 8), Vector.xy(cx + 10, cy - 3))
        stroke.thickness = 2.2
        renderer:drawPath(path, stroke)
    elseif which == OUT_SCREEN then
        local box = nextPath(self)
        addRect(box, cx - 8, cy - 8, 16, 16)
        stroke.thickness = if readOutlineScreen(self) then 2.6 else 1.3
        stroke.color = if readOutlineScreen(self) then Color.rgb(255, 196, 110) else Color.rgb(236, 244, 255)
        renderer:drawPath(box, stroke)
    else
        local swatch = nextPath(self)
        addCircle(swatch, cx, cy, 8)
        fill.style = "fill"
        fill.color = readOutlineColor(self)
        renderer:drawPath(swatch, fill)
        local ring = nextPath(self)
        addCircle(ring, cx, cy, 8)
        stroke.thickness = 1.4
        renderer:drawPath(ring, stroke)
    end
end

local function drawOutlineButtons(self: PlaneLoader, renderer: Renderer)
    local x0, y0 = outlinePanelOrigin(self)
    local pw = TOOL_PAD * 2 + OUT_COUNT * OUT_BTN + (OUT_COUNT - 1) * BTN_GAP
    local ph = TOOL_PAD * 2 + OUT_BTN
    local panel = nextPath(self)
    addRect(panel, x0, y0, pw, ph)
    local fill = self.fillPaint
    fill.style = "fill"
    fill.color = Color.rgba(8, 14, 24, 220)
    renderer:drawPath(panel, fill)
    local stroke = self.strokePaint
    stroke.style = "stroke"
    stroke.thickness = 1.2
    stroke.color = Color.rgba(90, 150, 190, 90)
    renderer:drawPath(panel, stroke)
    for i = 1, OUT_COUNT do
        local bx, by, bw, bh = outlineButtonRect(self, i)
        local btn = nextPath(self)
        addRect(btn, bx, by, bw, bh)
        if self.hoverOutline == i then
            fill.color = Color.rgba(48, 92, 128, 240)
        else
            fill.color = Color.rgba(18, 30, 46, 230)
        end
        fill.style = "fill"
        renderer:drawPath(btn, fill)
        stroke.style = "stroke"
        stroke.thickness = 1
        stroke.color = Color.rgba(80, 110, 140, 80)
        renderer:drawPath(btn, stroke)
        drawOutlineIcon(self, renderer, i, bx, by)
    end
end

local function timelineRect(self: PlaneLoader): (number, number, number, number)
    local w = numOr(self.size.x, 800)
    local h = numOr(self.size.y, 800)
    return 14, h - 128, w - 28, 50
end

local function timelineTrackRect(self: PlaneLoader): (number, number, number, number)
    local x, y, w = timelineRect(self)
    return x + 168, y + 16, w - 180, 18
end

local function hitAnim(self: PlaneLoader, px: number, py: number): number
    local x, y, w, h = timelineRect(self)
    if px < x or px > x + w or py < y or py > y + h then
        return 0
    end
    local tx, ty, tw, th = timelineTrackRect(self)
    if px >= tx and px <= tx + tw and py >= ty - 6 and py <= ty + th + 6 then
        return ANIM_TRACK
    end
    local bx = x + 8
    local by = y + 8
    for i = 1, 4 do
        if px >= bx and px <= bx + 34 and py >= by and py <= by + 34 then
            return i
        end
        bx += 38
    end
    return 0
end

local function scrubAnim(self: PlaneLoader, px: number)
    local tx, _, tw = timelineTrackRect(self)
    local u = math.clamp((px - tx) / math.max(1, tw), 0, 1)
    self.animTime = u * self.animDuration
    self.animPlaying = false
    for _, bone in self.bones do
        if #bone.keys > 0 then
            bone.posed = false
        end
    end
end

local function applyAnimHit(self: PlaneLoader, which: number, px: number)
    if which == ANIM_PLAY then
        toggleAnimPlay(self)
    elseif which == ANIM_KEY then
        insertBoneKey(self)
    elseif which == ANIM_PREV then
        stepAnimKey(self, -1)
    elseif which == ANIM_NEXT then
        stepAnimKey(self, 1)
    elseif which == ANIM_TRACK then
        self.animScrubbing = true
        scrubAnim(self, px)
    end
end

local function drawTimeline(self: PlaneLoader, renderer: Renderer)
    local x, y, w, h = timelineRect(self)
    local panel = nextPath(self)
    addRect(panel, x, y, w, h)
    local fill = self.fillPaint
    fill.style = "fill"
    fill.color = Color.rgba(8, 14, 24, 220)
    renderer:drawPath(panel, fill)
    local stroke = self.strokePaint
    stroke.style = "stroke"
    stroke.thickness = 1.2
    stroke.color = Color.rgba(90, 150, 190, 90)
    renderer:drawPath(panel, stroke)
    for i = 1, 4 do
        local bx = x + 8 + (i - 1) * 38
        local by = y + 8
        local btn = nextPath(self)
        addRect(btn, bx, by, 34, 34)
        if self.hoverAnim == i or (i == ANIM_PLAY and self.animPlaying) then
            fill.color = Color.rgba(48, 92, 128, 240)
        else
            fill.color = Color.rgba(18, 30, 46, 230)
        end
        fill.style = "fill"
        renderer:drawPath(btn, fill)
        stroke.thickness = 1
        stroke.color = Color.rgba(80, 110, 140, 80)
        renderer:drawPath(btn, stroke)
        local icon = nextPath(self)
        local cx = bx + 17
        local cy = by + 17
        if i == ANIM_PLAY then
            if self.animPlaying then
                addRect(icon, cx - 6, cy - 7, 4, 14)
                addRect(icon, cx + 2, cy - 7, 4, 14)
            else
                icon:moveTo(Vector.xy(cx - 5, cy - 8))
                icon:lineTo(Vector.xy(cx + 8, cy))
                icon:lineTo(Vector.xy(cx - 5, cy + 8))
                icon:close()
            end
            fill.color = Color.rgb(236, 244, 255)
            renderer:drawPath(icon, fill)
        elseif i == ANIM_KEY then
            addCircle(icon, cx, cy, 6)
            fill.color = Color.rgb(255, 196, 110)
            renderer:drawPath(icon, fill)
        else
            if i == ANIM_PREV then
                icon:moveTo(Vector.xy(cx + 6, cy - 7))
                icon:lineTo(Vector.xy(cx - 7, cy))
                icon:lineTo(Vector.xy(cx + 6, cy + 7))
            else
                icon:moveTo(Vector.xy(cx - 6, cy - 7))
                icon:lineTo(Vector.xy(cx + 7, cy))
                icon:lineTo(Vector.xy(cx - 6, cy + 7))
            end
            icon:close()
            fill.color = Color.rgb(236, 244, 255)
            renderer:drawPath(icon, fill)
        end
    end
    local tx, ty, tw, th = timelineTrackRect(self)
    local track = nextPath(self)
    addRect(track, tx, ty, tw, th)
    fill.color = Color.rgba(12, 22, 34, 240)
    renderer:drawPath(track, fill)
    local u = 0
    if self.animDuration > 0.001 then
        u = math.clamp(self.animTime / self.animDuration, 0, 1)
    end
    local play = nextPath(self)
    addRect(play, tx, ty, tw * u, th)
    fill.color = Color.rgba(64, 120, 168, 160)
    renderer:drawPath(play, fill)
    for _, bone in self.bones do
        for _, key in bone.keys do
            local kx = tx + (key.t / math.max(0.001, self.animDuration)) * tw
            local mark = nextPath(self)
            addRect(mark, kx - 2, ty - 3, 4, th + 6)
            fill.color = if bone.isJoint and self.selectedBone ~= BONE_NONE and self.bones[self.selectedBone + 1] == bone
                then Color.rgb(255, 210, 90)
                else Color.rgb(255, 168, 56)
            renderer:drawPath(mark, fill)
        end
    end
    local head = nextPath(self)
    addRect(head, tx + tw * u - 2, ty - 5, 4, th + 10)
    fill.color = Color.rgb(255, 255, 255)
    renderer:drawPath(head, fill)
end

local function applyZoom(self: PlaneLoader, dir: number)
    freezeCameraAnim(self)
    local yaw, pitch, dist = readCam(self)
    self.liveCamYaw = yaw
    self.liveCamPitch = pitch
    local factor = if dir == 1 then 0.78 else 1.28
    self.liveCamDistance = math.clamp(dist * factor, 1.15, 14)
    self.overrideCam = true
    print(if dir == 1 then "zoom in" else "zoom out")
end

local function drawZoomButtons(self: PlaneLoader, renderer: Renderer)
    for i = 1, 2 do
        local cx, cy = zoomButtonPos(self, i)
        local bg = nextPath(self)
        addCircle(bg, cx, cy, 18)
        local fill = self.fillPaint
        fill.style = "fill"
        if self.hoverZoom == i then
            fill.color = Color.rgba(48, 92, 128, 240)
        else
            fill.color = Color.rgba(8, 14, 24, 210)
        end
        renderer:drawPath(bg, fill)
        local ring = nextPath(self)
        addCircle(ring, cx, cy, 18)
        local stroke = self.strokePaint
        stroke.style = "stroke"
        stroke.thickness = 1.3
        stroke.color = Color.rgba(90, 150, 190, 100)
        renderer:drawPath(ring, stroke)
        local icon = nextPath(self)
        addLine(icon, cx - 7, cy, cx + 7, cy)
        if i == 1 then
            addLine(icon, cx, cy - 7, cx, cy + 7)
        end
        stroke.thickness = 2.2
        stroke.cap = "round"
        stroke.color = Color.rgb(236, 244, 255)
        renderer:drawPath(icon, stroke)
    end
end

local function hitViewCube(self: PlaneLoader, px: number, py: number): number
    local cx, cy = viewCubePos(self)
    if math.abs(px - cx) > 28 or math.abs(py - cy) > 28 then
        return 0
    end
    local lx = px - cx
    local ly = py - cy
    if math.abs(lx) < 8 and math.abs(ly) < 8 then
        return 4
    end
    if ly < -6 then
        return 3
    end
    if lx > 4 then
        return 2
    end
    return 1
end

local function snapView(self: PlaneLoader, face: number)
    freezeCameraAnim(self)
    self.overrideCam = true
    if face == 1 then
        self.liveCamYaw = 180
        self.liveCamPitch = 12
        print("view front")
    elseif face == 2 then
        self.liveCamYaw = -90
        self.liveCamPitch = 12
        print("view right")
    elseif face == 3 then
        self.liveCamYaw = 0
        self.liveCamPitch = 88
        print("view top")
    else
        self.liveCamYaw = 55
        self.liveCamPitch = 18
        self.liveCamDistance = math.max(3.2, math.max(self.extent.x, self.extent.y, self.extent.z) * 4.1)
        self.overrideTarget = false
        print("view home")
    end
    local _, _, dist = readCam(self)
    if face ~= 4 then
        self.liveCamDistance = dist
    end
end

local function drawViewCube(self: PlaneLoader, renderer: Renderer)
    local cx, cy = viewCubePos(self)
    local hover = self.hoverCube
    local pad = nextPath(self)
    addCircle(pad, cx, cy, 30)
    local fill = self.fillPaint
    fill.style = "fill"
    fill.color = Color.rgba(8, 14, 24, 200)
    renderer:drawPath(pad, fill)
    local yaw, pitch, _ = readCam(self)
    local y = math.rad(-yaw)
    local p = math.rad(-pitch * 0.45)
    local function xf(x: number, yv: number, z: number): (number, number)
        local x1 = x * math.cos(y) + z * math.sin(y)
        local z1 = -x * math.sin(y) + z * math.cos(y)
        local y1 = yv * math.cos(p) - z1 * math.sin(p)
        return cx + x1 * 20, cy - y1 * 20
    end
    local function face(
        x1: number, y1: number, z1: number,
        x2: number, y2: number, z2: number,
        x3: number, y3: number, z3: number,
        x4: number, y4: number, z4: number,
        col: Color
    )
        local ax, ay = xf(x1, y1, z1)
        local bx, by = xf(x2, y2, z2)
        local cx2, cy2 = xf(x3, y3, z3)
        local dx, dy = xf(x4, y4, z4)
        local path = nextPath(self)
        path:moveTo(Vector.xy(ax, ay))
        path:lineTo(Vector.xy(bx, by))
        path:lineTo(Vector.xy(cx2, cy2))
        path:lineTo(Vector.xy(dx, dy))
        path:close()
        fill.style = "fill"
        fill.color = col
        renderer:drawPath(path, fill)
        local stroke = self.strokePaint
        stroke.style = "stroke"
        stroke.thickness = 1.1
        stroke.color = Color.rgba(255, 255, 255, 50)
        renderer:drawPath(path, stroke)
    end
    local topCol = if hover == 3 then Color.rgb(140, 255, 160) else Color.rgb(56, 180, 82)
    local rightCol = if hover == 2 then Color.rgb(255, 150, 130) else Color.rgb(220, 70, 58)
    local frontCol = if hover == 1 then Color.rgb(130, 180, 255) else Color.rgb(56, 118, 220)
    face(-1, 1, -1, 1, 1, -1, 1, 1, 1, -1, 1, 1, topCol)
    face(1, -1, -1, 1, 1, -1, 1, 1, 1, 1, -1, 1, rightCol)
    face(-1, -1, -1, 1, -1, -1, 1, 1, -1, -1, 1, -1, frontCol)
    local function axis(x: number, yv: number, z: number, col: Color)
        local ox, oy = xf(0, 0, 0)
        local tx, ty = xf(x, yv, z)
        local path = nextPath(self)
        addLine(path, ox, oy, tx, ty)
        local stroke = self.strokePaint
        stroke.style = "stroke"
        stroke.thickness = 2.4
        stroke.cap = "round"
        stroke.color = col
        renderer:drawPath(path, stroke)
    end
    axis(1.7, 0, 0, AXIS_RED)
    axis(0, 1.7, 0, AXIS_GREEN)
    axis(0, 0, 1.7, AXIS_BLUE)
    local home = nextPath(self)
    addCircle(home, cx, cy, 5)
    fill.style = "fill"
    fill.color = if hover == 4 then Color.rgb(255, 220, 140) else Color.rgb(240, 245, 250)
    renderer:drawPath(home, fill)
end

local function drawSocketAxis(
    self: PlaneLoader,
    renderer: Renderer,
    sx: number,
    sy: number,
    x: number,
    y: number,
    z: number,
    color: Color
)
    local tx, ty, vis = project(self, x, y, z)
    if vis == false then
        return
    end
    local path = nextPath(self)
    addLine(path, sx, sy, tx, ty)
    local paint = self.strokePaint
    paint.style = "stroke"
    paint.thickness = 2.2
    paint.cap = "round"
    paint.color = color
    renderer:drawPath(path, paint)
end

local function drawSockets(self: PlaneLoader, renderer: Renderer)
    if asBool(self.showSockets, true) == false then
        return
    end
    local fill = self.fillPaint
    local stroke = self.strokePaint
    local axisLen = math.max(self.extent.x, self.extent.y, self.extent.z) * 0.18
    for _, part in self.parts do
        local wp = part.world:transformPoint(part.pivot.x, part.pivot.y, part.pivot.z)
        local sx, sy, vis = project(self, wp.x, wp.y, wp.z)
        if vis then
            local selected = part.partId == self.selectedId
            local hover = part.partId == self.hoverId
            local r = if selected then 7 else (if hover then 5.5 else 4)
            local diamond = nextPath(self)
            diamond:moveTo(Vector.xy(sx, sy - r))
            diamond:lineTo(Vector.xy(sx + r, sy))
            diamond:lineTo(Vector.xy(sx, sy + r))
            diamond:lineTo(Vector.xy(sx - r, sy))
            diamond:close()
            fill.style = "fill"
            if selected then
                fill.color = Color.rgb(255, 210, 90)
            elseif hover then
                fill.color = Color.rgb(120, 220, 255)
            else
                fill.color = Color.rgba(70, 190, 220, 210)
            end
            renderer:drawPath(diamond, fill)
            stroke.style = "stroke"
            stroke.thickness = 1.2
            stroke.color = Color.rgba(8, 16, 28, 210)
            renderer:drawPath(diamond, stroke)
            if selected then
                local ring = nextPath(self)
                addCircle(ring, sx, sy, 11)
                stroke.style = "stroke"
                stroke.thickness = 1.6
                stroke.color = Color.rgb(255, 210, 90)
                renderer:drawPath(ring, stroke)
                local x1 = part.world:transformPoint(part.pivot.x + axisLen, part.pivot.y, part.pivot.z)
                local y1 = part.world:transformPoint(part.pivot.x, part.pivot.y + axisLen, part.pivot.z)
                local z1 = part.world:transformPoint(part.pivot.x, part.pivot.y, part.pivot.z + axisLen)
                drawSocketAxis(self, renderer, sx, sy, x1.x, x1.y, x1.z, AXIS_RED)
                drawSocketAxis(self, renderer, sx, sy, y1.x, y1.y, y1.z, AXIS_GREEN)
                drawSocketAxis(self, renderer, sx, sy, z1.x, z1.y, z1.z, AXIS_BLUE)
            end
        end
    end
end

local function hitBone(self: PlaneLoader, px: number, py: number): number
    local best = BONE_NONE
    local bestD = 22
    for i, bone in self.bones do
        if bone.isJoint then
            local ox, oy, oz = boneOrigin(self, i - 1)
            local sx, sy, vis = project(self, ox, oy, oz)
            if vis then
                local d = math.sqrt(dist2(px, py, sx, sy))
                if d < bestD then
                    bestD = d
                    best = i - 1
                end
            end
        end
    end
    return best
end

local function drawBones(self: PlaneLoader, renderer: Renderer)
    if #self.bones == 0 then
        return
    end
    local fill = self.fillPaint
    local stroke = self.strokePaint
    for i, bone in self.bones do
        if bone.parent >= 0 then
            local ax, ay, az = boneOrigin(self, bone.parent)
            local bx, by, bz = boneOrigin(self, i - 1)
            local sx, sy, svis = project(self, ax, ay, az)
            local tx, ty, tvis = project(self, bx, by, bz)
            if svis and tvis then
                local path = nextPath(self)
                addLine(path, sx, sy, tx, ty)
                stroke.style = "stroke"
                stroke.thickness = 2.2
                stroke.cap = "round"
                stroke.color = Color.rgba(255, 186, 72, 200)
                renderer:drawPath(path, stroke)
            end
        end
    end
    for i, bone in self.bones do
        if bone.isJoint then
            local ox, oy, oz = boneOrigin(self, i - 1)
            local sx, sy, vis = project(self, ox, oy, oz)
            if vis then
                local selected = self.selectedBone == i - 1
                local hover = self.hoverBone == i - 1
                local r = if selected then 10 else (if hover then 8 else 7)
                local joint = nextPath(self)
                addCircle(joint, sx, sy, r)
                fill.style = "fill"
                if selected then
                    fill.color = Color.rgb(255, 210, 90)
                elseif hover then
                    fill.color = Color.rgb(255, 236, 160)
                else
                    fill.color = Color.rgb(255, 168, 56)
                end
                renderer:drawPath(joint, fill)
                stroke.style = "stroke"
                stroke.thickness = if selected then 2 else 1.2
                stroke.color = Color.rgba(20, 12, 8, 220)
                renderer:drawPath(joint, stroke)
            end
        end
    end
end

local function drawOverlay(self: PlaneLoader, renderer: Renderer)
    self.uiCursor = 0
    if readGuides(self) == false then
        return
    end
    drawToolbar(self, renderer)
    drawSockets(self, renderer)
    drawBones(self, renderer)
    if currentTool(self) == TOOL_CAMERA then
        drawCameraGizmos(self, renderer)
    else
        drawGizmos(self, renderer)
    end
    drawViewCube(self, renderer)
    drawZoomButtons(self, renderer)
    drawTimeline(self, renderer)
    drawOutlineButtons(self, renderer)
end

local function makeVertexLayout(): { VertexBufferLayout }
    return {
        {
            stride = VERTEX_STRIDE,
            attributes = {
                { format = "float32x3", slot = 0, offset = 0 },
                { format = "float32x3", slot = 1, offset = 12 },
                { format = "float32x4", slot = 2, offset = 24 },
            },
        },
    }
end

local function makeDepthState(): DepthStencilState
    return {
        format = "depth32float",
        compare = "less",
        write = true,
    }
end

local function uploadBuffer(usage: BufferUsage, data: buffer, srcOffset: number, byteLength: number): GPUBuffer
    local gpu = GPUBuffer.new({
        size = byteLength,
        usage = usage,
        label = usage,
    })
    gpu:write(data, 0, srcOffset, byteLength)
    return gpu
end

local function readName(data: buffer, off: number): string
    local chars = {}
    for i = 0, 31 do
        local b = buffer.readu8(data, off + i)
        if b == 0 then
            break
        end
        table.insert(chars, string.char(b))
    end
    return table.concat(chars)
end

local function loadPackedMesh(self: PlaneLoader, data: buffer)
    local magic = buffer.readu32(data, 0)
    if magic ~= 0x4E4C5052 then
        print("plane.mesh: bad magic")
        return
    end
    local version = buffer.readu32(data, 4)
    if version ~= 3 then
        print("plane.mesh: expected v3")
        return
    end
    local partCount = buffer.readu32(data, 8)
    self.center = Vector.xyz(
        buffer.readf32(data, 12),
        buffer.readf32(data, 16),
        buffer.readf32(data, 20)
    )
    self.extent = Vector.xyz(
        buffer.readf32(data, 24),
        buffer.readf32(data, 28),
        buffer.readf32(data, 32)
    )
    local boneCount = buffer.readu32(data, 36)
    self.bones = {}
    for i = 0, boneCount - 1 do
        local rec = HEADER + i * BONE_REC
        table.insert(self.bones, {
            name = readName(data, rec + 48),
            parent = (function(): number
                local p = buffer.readu32(data, rec)
                if p > 10000 then
                    return BONE_NONE
                end
                return p
            end)(),
            isJoint = bit32.band(buffer.readu32(data, rec + 4), 1) ~= 0,
            tx = buffer.readf32(data, rec + 8),
            ty = buffer.readf32(data, rec + 12),
            tz = buffer.readf32(data, rec + 16),
            qx = buffer.readf32(data, rec + 20),
            qy = buffer.readf32(data, rec + 24),
            qz = buffer.readf32(data, rec + 28),
            qw = buffer.readf32(data, rec + 32),
            sx = buffer.readf32(data, rec + 36),
            sy = buffer.readf32(data, rec + 40),
            sz = buffer.readf32(data, rec + 44),
            liveRX = 0,
            liveRY = 0,
            liveRZ = 0,
            liveSX = 1,
            liveSY = 1,
            liveSZ = 1,
            posed = false,
            keys = {} :: { BoneKey },
            world = Mat4.identity(),
        })
    end
    local partBase = HEADER + boneCount * BONE_REC
    local cursor = partBase + partCount * PART_REC
    self.parts = {}
    for i = 0, partCount - 1 do
        local rec = partBase + i * PART_REC
        local flags = buffer.readu32(data, rec)
        local vcount = buffer.readu32(data, rec + 4)
        local icount = buffer.readu32(data, rec + 8)
        local bmin = Vector.xyz(
            buffer.readf32(data, rec + 12),
            buffer.readf32(data, rec + 16),
            buffer.readf32(data, rec + 20)
        )
        local bmax = Vector.xyz(
            buffer.readf32(data, rec + 24),
            buffer.readf32(data, rec + 28),
            buffer.readf32(data, rec + 32)
        )
        local bone = buffer.readu32(data, rec + 36)
        local translation = Vector.xyz(0, 0, 0)
        local scale = Vector.xyz(1, 1, 1)
        local name = readName(data, rec + 60)
        local vertBytes = vcount * VERTEX_STRIDE
        local idxBytes = icount * 2
        local idxPadded = align4(idxBytes)
        local vertOff = cursor
        local idxOff = cursor + vertBytes
        cursor = idxOff + idxPadded
        table.insert(self.parts, {
            name = name,
            localSpace = bit32.band(flags, 1) ~= 0,
            draw = {
                vertexBuffer = uploadBuffer("vertex", data, vertOff, vertBytes),
                indexBuffer = uploadBuffer("index", data, idxOff, idxBytes),
                indexCount = icount,
            },
            ubo = nil,
            bindGroup = nil,
            bmin = bmin,
            bmax = bmax,
            translation = translation,
            scale = scale,
            world = Mat4.identity(),
            partId = i + 1,
            bone = bone,
            doOutline = bit32.band(flags, 2) ~= 0,
            pivot = Vector.xyz(
                (bmin.x + bmax.x) * 0.5,
                (bmin.y + bmax.y) * 0.5,
                (bmin.z + bmax.z) * 0.5
            ),
        })
    end
    local jointCount = 0
    for _, bone in self.bones do
        if bone.isJoint then
            jointCount += 1
        end
    end
    print("skeleton: " .. #self.bones .. " nodes, " .. jointCount .. " joints (click a joint, then rotate)")
    for _, part in self.parts do
        print("  " .. part.partId .. " " .. part.name)
    end
    for i, bone in self.bones do
        if bone.isJoint then
            print("  joint " .. (i - 1) .. " " .. bone.name)
        end
    end
end

local function pushVert(
    verts: { number },
    x: number,
    y: number,
    z: number,
    nx: number,
    ny: number,
    nz: number,
    r: number,
    g: number,
    b: number
)
    table.insert(verts, x)
    table.insert(verts, y)
    table.insert(verts, z)
    table.insert(verts, nx)
    table.insert(verts, ny)
    table.insert(verts, nz)
    table.insert(verts, r)
    table.insert(verts, g)
    table.insert(verts, b)
    table.insert(verts, 1)
end

local function pushBox(
    verts: { number },
    x0: number,
    y0: number,
    z0: number,
    x1: number,
    y1: number,
    z1: number,
    r: number,
    g: number,
    b: number
)
    local faces = {
        { x0, y0, z1, x1, y0, z1, x1, y1, z1, x0, y1, z1, 0, 0, 1 },
        { x1, y0, z0, x0, y0, z0, x0, y1, z0, x1, y1, z0, 0, 0, -1 },
        { x0, y1, z0, x0, y1, z1, x1, y1, z1, x1, y1, z0, 0, 1, 0 },
        { x0, y0, z1, x0, y0, z0, x1, y0, z0, x1, y0, z1, 0, -1, 0 },
        { x1, y0, z1, x1, y0, z0, x1, y1, z0, x1, y1, z1, 1, 0, 0 },
        { x0, y0, z0, x0, y0, z1, x0, y1, z1, x0, y1, z0, -1, 0, 0 },
    }
    for _, f in faces do
        local nx, ny, nz = f[13], f[14], f[15]
        pushVert(verts, f[1], f[2], f[3], nx, ny, nz, r, g, b)
        pushVert(verts, f[4], f[5], f[6], nx, ny, nz, r, g, b)
        pushVert(verts, f[7], f[8], f[9], nx, ny, nz, r, g, b)
        pushVert(verts, f[1], f[2], f[3], nx, ny, nz, r, g, b)
        pushVert(verts, f[7], f[8], f[9], nx, ny, nz, r, g, b)
        pushVert(verts, f[10], f[11], f[12], nx, ny, nz, r, g, b)
    end
end

local function meshFromVerts(verts: { number }, label: string): MeshDraw
    local bytes = buffer.create(#verts * 4)
    for i, value in verts do
        buffer.writef32(bytes, (i - 1) * 4, value)
    end
    return {
        vertexBuffer = GPUBuffer.new({
            size = #verts * 4,
            usage = "vertex",
            data = bytes,
            immutable = true,
            label = label,
        }),
        indexBuffer = GPUBuffer.new({
            size = 4,
            usage = "index",
            data = buffer.create(4),
            immutable = true,
        }),
        indexCount = #verts / 10,
    }
end

local function makeGround(self: PlaneLoader)
    local y = self.center.y - self.extent.y - 0.02
    local s = math.max(self.extent.x, self.extent.z) * 8
    local cx = self.center.x
    local cz = self.center.z
    local verts = {
        cx - s, y, cz - s, 0, 1, 0, 0.05, 0.08, 0.1, 1,
        cx + s, y, cz - s, 0, 1, 0, 0.05, 0.08, 0.1, 1,
        cx + s, y, cz + s, 0, 1, 0, 0.05, 0.08, 0.1, 1,
        cx - s, y, cz - s, 0, 1, 0, 0.05, 0.08, 0.1, 1,
        cx + s, y, cz + s, 0, 1, 0, 0.05, 0.08, 0.1, 1,
        cx - s, y, cz + s, 0, 1, 0, 0.05, 0.08, 0.1, 1,
    }
    self.ground = meshFromVerts(verts, "ground")
end

local function makeAxis(self: PlaneLoader)
    local t = 0.018
    local verts = {}
    pushBox(verts, 0, -t, -t, 1, t, t, 0.92, 0.18, 0.16)
    pushBox(verts, -t, 0, -t, t, 1, t, 0.22, 0.82, 0.28)
    pushBox(verts, -t, -t, 0, t, t, 1, 0.2, 0.42, 0.95)
    pushBox(verts, -t * 1.8, -t * 1.8, -t * 1.8, t * 1.8, t * 1.8, t * 1.8, 1, 1, 1)
    self.axisMesh = meshFromVerts(verts, "axis")
end

local function pixelSize(self: PlaneLoader): (number, number)
    local scale = self.scale
    if type(scale) ~= "number" or scale ~= scale or scale <= 0 then
        scale = 1
        self.scale = 1
    end
    local size = self.size
    local sx = 800
    local sy = 800
    if size ~= nil then
        sx = numOr(size.x, numOr(size[1], 800))
        sy = numOr(size.y, numOr(size[2], 800))
    end
    return math.max(1, math.floor(sx * scale)), math.max(1, math.floor(sy * scale))
end

local function chooseSamples(self: PlaneLoader, context: Context): number
    if asBool(self.msaa, true) == false then
        return 1
    end
    local maxSamples = 4
    local ok, feats = pcall(function()
        return (context :: any):features()
    end)
    if ok and feats ~= nil then
        local n = (feats :: any).maxSamples
        if type(n) == "number" then
            maxSamples = n
        end
    end
    if maxSamples >= 4 then
        return 4
    elseif maxSamples >= 2 then
        return 2
    end
    print("msaa off: maxSamples=" .. tostring(maxSamples))
    return 1
end

local function rebuildTargets(self: PlaneLoader)
    local gpu = self.gpu
    if gpu == nil then
        return
    end
    local w = math.max(1, gpu.width)
    local h = math.max(1, gpu.height)
    local samples = self.samples
    if samples ~= 4 and samples ~= 2 then
        samples = 1
    end
    self.samples = samples
    self.msaaColor = nil
    if samples > 1 then
        self.msaaColor = GPUTexture.new({
            width = w,
            height = h,
            format = gpu.format,
            renderTarget = true,
            sampleCount = samples,
            label = "msaa",
        })
    end
    local depth = GPUTexture.new({
        width = w,
        height = h,
        format = "depth32float",
        renderTarget = true,
        sampleCount = samples,
        label = "depth",
    })
    self.depth = depth
    self.depthView = depth:view()
end

local function ensureGpu(self: PlaneLoader, context: Context)
    if self.gpu ~= nil or self.gpuFailed then
        return
    end
    local w, h = pixelSize(self)
    local canvasOk, canvas = pcall(function()
        return context:gpuCanvas({ width = w, height = h })
    end)
    if not canvasOk or canvas == nil then
        self.gpuFailed = true
        return
    end
    local gpu = canvas :: GPUCanvas
    self.gpu = gpu
    self.samples = chooseSamples(self, context)
    local targetsOk = pcall(function()
        rebuildTargets(self)
    end)
    if (not targetsOk or self.depthView == nil) and self.samples > 1 then
        print("msaa targets failed, falling back to 1x")
        self.samples = 1
        self.msaaColor = nil
        targetsOk = pcall(function()
            rebuildTargets(self)
        end)
    end
    if not targetsOk or self.depthView == nil then
        self.gpuFailed = true
        self.gpu = nil
        return
    end
    if self.samples > 1 then
        print("msaa " .. tostring(self.samples) .. "x")
    end

    local shader = context:shader("plane")
    if shader == nil then
        print("missing plane shader")
        self.gpuFailed = true
        self.gpu = nil
        return
    end
    local built = pcall(function()
        local colorFmt = gpu.format
        local vertexLayout = makeVertexLayout()
        local samples = self.samples
        self.skyPipeline = GPUPipeline.new({
            vertex = { module = shader, entryPoint = "vs_sky" },
            fragment = { module = shader, entryPoint = "fs_sky" },
            vertexLayout = {},
            colorTargets = { { format = colorFmt } },
            depthStencil = {
                format = "depth32float",
                compare = "always",
                write = false,
            },
            cullMode = "none",
            topology = "triangle-list",
            sampleCount = samples,
        })
        self.meshPipeline = GPUPipeline.new({
            vertex = { module = shader, entryPoint = "vs_mesh" },
            fragment = { module = shader, entryPoint = "fs_mesh" },
            vertexLayout = vertexLayout,
            colorTargets = { { format = colorFmt } },
            depthStencil = makeDepthState(),
            cullMode = "none",
            topology = "triangle-list",
            sampleCount = samples,
        })
        self.outlinePipeline = GPUPipeline.new({
            vertex = { module = shader, entryPoint = "vs_outline" },
            fragment = { module = shader, entryPoint = "fs_outline" },
            vertexLayout = vertexLayout,
            colorTargets = { { format = colorFmt } },
            depthStencil = makeDepthState(),
            cullMode = "front",
            topology = "triangle-list",
            sampleCount = samples,
        })
        self.groundPipeline = GPUPipeline.new({
            vertex = { module = shader, entryPoint = "vs_ground" },
            fragment = { module = shader, entryPoint = "fs_ground" },
            vertexLayout = vertexLayout,
            colorTargets = {
                {
                    format = colorFmt,
                    blend = {
                        srcColor = "src-alpha",
                        dstColor = "one-minus-src-alpha",
                        srcAlpha = "one",
                        dstAlpha = "one-minus-src-alpha",
                    },
                },
            },
            depthStencil = {
                format = "depth32float",
                compare = "less",
                write = false,
            },
            cullMode = "none",
            topology = "triangle-list",
            sampleCount = samples,
        })
        self.axisPipeline = GPUPipeline.new({
            vertex = { module = shader, entryPoint = "vs_axis" },
            fragment = { module = shader, entryPoint = "fs_axis" },
            vertexLayout = vertexLayout,
            colorTargets = { { format = colorFmt } },
            depthStencil = makeDepthState(),
            cullMode = "none",
            topology = "triangle-list",
            sampleCount = samples,
        })
        local uboAxis = GPUBuffer.new({
            size = UBO_SIZE,
            usage = "uniform",
            label = "axis",
        })
        self.uboAxis = uboAxis
        local meshPipeline = self.meshPipeline
        if meshPipeline == nil then
            error("mesh pipeline missing")
        end
        local layout = meshPipeline:getBindGroupLayout(0)
        self.bindGroupAxis = GPUBindGroup.new({
            layout = layout,
            ubos = {
                { slot = 0, buffer = uboAxis },
            },
        })
        local uboGround = GPUBuffer.new({
            size = UBO_SIZE,
            usage = "uniform",
            label = "ground",
        })
        self.uboGround = uboGround
        self.bindGroupGround = GPUBindGroup.new({
            layout = layout,
            ubos = {
                { slot = 0, buffer = uboGround },
            },
        })
        for _, part in self.parts do
            local ubo = GPUBuffer.new({
                size = UBO_SIZE,
                usage = "uniform",
                label = part.name,
            })
            part.ubo = ubo
            part.bindGroup = GPUBindGroup.new({
                layout = layout,
                ubos = {
                    { slot = 0, buffer = ubo },
                },
            })
        end
        if #self.parts > 0 then
            self.bindGroup = self.parts[1].bindGroup
        end
    end)
    if not built or self.meshPipeline == nil or self.bindGroup == nil then
        self.gpuFailed = true
        self.gpu = nil
    end
end

function init(self: PlaneLoader, context: Context): boolean
    self.context = context
    local blob = context:blob("plane")
    if blob == nil then
        print("missing plane blob")
        return true
    end
    local packed = pcall(function()
        loadPackedMesh(self, blob.data)
        makeGround(self)
        makeAxis(self)
    end)
    self.ready = packed and #self.parts > 0
    print("skeleton: click an orange joint, then drag the rotate rings")
    print("I key  K play  timeline bottom")
    return true
end

function resize(self: PlaneLoader, size: Vector, scale: number)
    if size ~= nil then
        self.size = size
    end
    if type(scale) == "number" and scale == scale and scale > 0 then
        self.scale = scale
    elseif type(self.scale) ~= "number" or self.scale <= 0 then
        self.scale = 1
    end
    local context = self.context
    if context == nil or self.ready == false or self.gpuFailed then
        return
    end
    local w, h = pixelSize(self)
    if self.gpu == nil then
        ensureGpu(self, context)
        return
    end
    if self.gpu.width ~= w or self.gpu.height ~= h then
        self.gpu:resize(w, h)
        rebuildTargets(self)
    end
end

function advance(self: PlaneLoader, seconds: number): boolean
    self.elapsed += seconds
    if seconds > 0.05 then
        seconds = 0.05
    end
    if self.animPlaying then
        self.animTime += seconds
        if self.animTime >= self.animDuration then
            self.animTime = self.animTime - self.animDuration
            if self.animTime < 0 then
                self.animTime = 0
            end
        end
    end
    return true
end

local function writeFrame(
    self: PlaneLoader,
    ubo: GPUBuffer,
    viewProj: Mat4,
    model: Mat4,
    sun: Vector,
    sunW: number,
    eye: Vector,
    groundY: number,
    bands: number,
    outlineWidth: number,
    specThresh: number,
    specAmt: number,
    exposure: number,
    orr: number,
    og: number,
    ob: number,
    lr: number,
    lg: number,
    lb: number,
    partId: number,
    hoverId: number,
    selectedId: number
)
    viewProj:writeToBuffer(self.uboBytes, 0)
    model:writeToBuffer(self.uboBytes, 64)
    buffer.writef32(self.uboBytes, 128, sun.x)
    buffer.writef32(self.uboBytes, 132, sun.y)
    buffer.writef32(self.uboBytes, 136, sun.z)
    buffer.writef32(self.uboBytes, 140, sunW)
    buffer.writef32(self.uboBytes, 144, eye.x)
    buffer.writef32(self.uboBytes, 148, eye.y)
    buffer.writef32(self.uboBytes, 152, eye.z)
    local _, py, _ = readPos(self)
    buffer.writef32(self.uboBytes, 156, self.center.y + py)
    buffer.writef32(self.uboBytes, 160, groundY)
    local gpx, _, gpz = readPos(self)
    buffer.writef32(self.uboBytes, 164, self.center.x + gpx)
    buffer.writef32(self.uboBytes, 168, self.center.z + gpz)
    buffer.writef32(self.uboBytes, 172, bands)
    buffer.writef32(self.uboBytes, 176, outlineWidth)
    buffer.writef32(self.uboBytes, 180, math.clamp(asNumber(self.specThresh, specThresh), 0.05, 0.995))
    buffer.writef32(self.uboBytes, 184, specAmt)
    buffer.writef32(self.uboBytes, 188, exposure)
    buffer.writef32(self.uboBytes, 192, orr)
    buffer.writef32(self.uboBytes, 196, og)
    buffer.writef32(self.uboBytes, 200, ob)
    buffer.writef32(self.uboBytes, 204, readOutlineSmooth(self))
    buffer.writef32(self.uboBytes, 208, lr)
    buffer.writef32(self.uboBytes, 212, lg)
    buffer.writef32(self.uboBytes, 216, lb)
    buffer.writef32(self.uboBytes, 220, if readOutlineScreen(self) then 1 else 0)
    buffer.writef32(self.uboBytes, 224, partId)
    buffer.writef32(self.uboBytes, 228, hoverId)
    buffer.writef32(self.uboBytes, 232, selectedId)
    local grid = 0
    if readGrid(self) then
        grid = math.max(0.04, asNumber(self.gridSize, 0.25))
    end
    buffer.writef32(self.uboBytes, 236, grid)
    buffer.writef32(self.uboBytes, 240, math.clamp(asNumber(self.wrapLight, 0.28), 0, 0.8))
    buffer.writef32(self.uboBytes, 244, math.max(0, asNumber(self.ambient, 0.24)))
    buffer.writef32(self.uboBytes, 248, math.max(0, asNumber(self.rimAmount, 0.48)))
    buffer.writef32(self.uboBytes, 252, math.max(0.2, asNumber(self.rimPower, 2.8)))
    local sr, sg, sb = colorRgb(self.shadowColor, SHADOW_COLOR)
    buffer.writef32(self.uboBytes, 256, sr)
    buffer.writef32(self.uboBytes, 260, sg)
    buffer.writef32(self.uboBytes, 264, sb)
    buffer.writef32(self.uboBytes, 268, math.clamp(asNumber(self.saturate, 1.12), 0, 2.2))
    local rr, rg, rb = colorRgb(self.rimColor, RIM_COLOR)
    buffer.writef32(self.uboBytes, 272, rr)
    buffer.writef32(self.uboBytes, 276, rg)
    buffer.writef32(self.uboBytes, 280, rb)
    buffer.writef32(self.uboBytes, 284, math.clamp(asNumber(self.metal, 0.62), 0, 1))
    buffer.writef32(self.uboBytes, 288, math.clamp(asNumber(self.aoAmount, 0.32), 0, 0.9))
    buffer.writef32(self.uboBytes, 292, math.max(0.001, asNumber(self.aoHeight, 0.22)))
    buffer.writef32(self.uboBytes, 296, math.max(0, asNumber(self.fogAmount, 0.18)))
    buffer.writef32(self.uboBytes, 300, math.max(0.1, asNumber(self.fogStart, 7)))
    buffer.writef32(self.uboBytes, 304, math.max(0.05, asNumber(self.contactRadius, 1.6)))
    buffer.writef32(self.uboBytes, 308, math.clamp(asNumber(self.contactShadow, 0.42), 0, 1))
    buffer.writef32(self.uboBytes, 312, math.clamp(asNumber(self.specSoft, 0.42), 0, 1))
    buffer.writef32(self.uboBytes, 316, math.max(0, asNumber(self.fresnel, 0.32)))
    local fr, fg, fb = colorRgb(self.fogColor, FOG_COLOR)
    buffer.writef32(self.uboBytes, 320, fr)
    buffer.writef32(self.uboBytes, 324, fg)
    buffer.writef32(self.uboBytes, 328, fb)
    buffer.writef32(self.uboBytes, 332, math.max(0, asNumber(self.skyGlow, 1.35)))
    ubo:write(self.uboBytes)
end

local function drawMesh(pass: GPURenderPass, mesh: MeshDraw, indexed: boolean)
    pass:setVertexBuffer(0, mesh.vertexBuffer)
    if indexed then
        pass:setIndexBuffer(mesh.indexBuffer, "uint16")
        pass:drawIndexed(mesh.indexCount)
    else
        pass:draw(mesh.indexCount)
    end
end

local function rayAabb(
    ox: number,
    oy: number,
    oz: number,
    dx: number,
    dy: number,
    dz: number,
    minx: number,
    miny: number,
    minz: number,
    maxx: number,
    maxy: number,
    maxz: number
): number
    local tmin = -1e9
    local tmax = 1e9
    local axesO = { ox, oy, oz }
    local axesD = { dx, dy, dz }
    local axesMin = { minx, miny, minz }
    local axesMax = { maxx, maxy, maxz }
    for i = 1, 3 do
        local o = axesO[i]
        local d = axesD[i]
        local mn = axesMin[i]
        local mx = axesMax[i]
        if math.abs(d) < 1e-8 then
            if o < mn or o > mx then
                return -1
            end
        else
            local t1 = (mn - o) / d
            local t2 = (mx - o) / d
            if t1 > t2 then
                local tmp = t1
                t1 = t2
                t2 = tmp
            end
            tmin = math.max(tmin, t1)
            tmax = math.min(tmax, t2)
            if tmin > tmax then
                return -1
            end
        end
    end
    if tmax < 0 then
        return -1
    end
    if tmin > 0 then
        return tmin
    end
    return tmax
end

local function hitDistance(model: Mat4, origin: Vector, dir: Vector, bmin: Vector, bmax: Vector, pad: number): number
    local inv = model:invertAffine()
    if inv == nil then
        return -1
    end
    local localO = inv:transformPoint(origin.x, origin.y, origin.z)
    local lx, ly, lz, _ = inv:transformVec4(dir.x, dir.y, dir.z, 0)
    local t = rayAabb(
        localO.x,
        localO.y,
        localO.z,
        lx,
        ly,
        lz,
        bmin.x - pad,
        bmin.y - pad,
        bmin.z - pad,
        bmax.x + pad,
        bmax.y + pad,
        bmax.z + pad
    )
    if t < 0 then
        return -1
    end
    local hx = localO.x + lx * t
    local hy = localO.y + ly * t
    local hz = localO.z + lz * t
    local world = model:transformPoint(hx, hy, hz)
    return Vector.distance(origin, world)
end

local function pickAt(self: PlaneLoader, px: number, py: number): number
    if asBool(self.pickEnable, true) == false then
        return PART_NONE
    end
    local w = numOr(self.size.x, 800)
    local h = numOr(self.size.y, 800)
    if w <= 0 or h <= 0 then
        return PART_NONE
    end
    local ndcX = (px / w) * 2 - 1
    local ndcY = 1 - (py / h) * 2
    local inv = self.tmpViewProj:invert()
    if inv == nil then
        return PART_NONE
    end
    local near = inv:transformPoint(ndcX, ndcY, 0)
    local far = inv:transformPoint(ndcX, ndcY, 1)
    local dir = Vector.normalized(Vector.xyz(far.x - near.x, far.y - near.y, far.z - near.z))
    local pad = math.max(self.extent.x, self.extent.y, self.extent.z) * 0.012
    local bestId = PART_NONE
    local bestVol = 1e9
    local bestT = 1e9
    for _, part in self.parts do
        local dx = math.max(0.001, part.bmax.x - part.bmin.x)
        local dy = math.max(0.001, part.bmax.y - part.bmin.y)
        local dz = math.max(0.001, part.bmax.z - part.bmin.z)
        local vol = dx * dy * dz
        local partPad = math.max(pad * 0.15, math.min(dx, dy, dz) * 0.03)
        local t = hitDistance(part.world, near, dir, part.bmin, part.bmax, partPad)
        if t >= 0 then
            local tighter = vol < bestVol * 0.82
            local similar = vol < bestVol * 1.18 and t < bestT
            if bestId == PART_NONE or tighter or similar then
                bestVol = vol
                bestT = t
                bestId = part.partId
            end
        end
    end
    return bestId
end

local function updateHover(self: PlaneLoader)
    if self.hasPointer then
        self.hoverId = pickAt(self, self.pointerX, self.pointerY)
    else
        self.hoverId = PART_NONE
    end
end

function pointerMove(self: PlaneLoader, event: PointerEvent)
    self.hasPointer = true
    local px = asNumber(event.position.x, 0)
    local py = asNumber(event.position.y, 0)
    self.pointerX = px
    self.pointerY = py
    if self.animScrubbing then
        scrubAnim(self, px)
        event:hit()
        return
    end
    if self.dragging then
        applyDrag(self, px, py)
        event:hit()
        return
    end
    local guides = readGuides(self)
    if guides then
        self.hoverTool = hitToolbar(px, py)
        self.hoverCube = hitViewCube(self, px, py)
        self.hoverZoom = hitZoom(self, px, py)
        self.hoverOutline = hitOutline(self, px, py)
        self.hoverAnim = hitAnim(self, px, py)
        self.hoverBone = hitBone(self, px, py)
    else
        self.hoverTool = 0
        self.hoverCube = 0
        self.hoverZoom = 0
        self.hoverOutline = 0
        self.hoverAnim = 0
        self.hoverBone = BONE_NONE
    end
    local tool = currentTool(self)
    if guides == false then
        self.hoverHandle = HANDLE_NONE
    elseif tool == TOOL_CAMERA then
        self.hoverHandle = hitCameraGizmo(self, px, py)
    elseif tool == TOOL_LIGHT then
        self.hoverHandle = hitGizmo(self, px, py, tool)
    elseif meshIsSelected(self) and gizmoTool(tool) then
        self.hoverHandle = hitGizmo(self, px, py, tool)
    else
        self.hoverHandle = HANDLE_NONE
    end
    updateHover(self)
    if self.hoverTool ~= 0 or self.hoverHandle ~= HANDLE_NONE or self.hoverId ~= PART_NONE or self.hoverCube ~= 0 or self.hoverZoom ~= 0 or self.hoverOutline ~= 0 or self.hoverAnim ~= 0 or self.hoverBone ~= BONE_NONE then
        event:hit()
    end
end

function pointerDown(self: PlaneLoader, event: PointerEvent)
    self.hasPointer = true
    local px = asNumber(event.position.x, 0)
    local py = asNumber(event.position.y, 0)
    self.pointerX = px
    self.pointerY = py
    if readGuides(self) then
        local tb = hitToolbar(px, py)
        if tb ~= 0 then
            setTool(self, tb)
            event:hit()
            return
        end
        local zoom = hitZoom(self, px, py)
        if zoom ~= 0 then
            applyZoom(self, zoom)
            event:hit()
            return
        end
        local animBtn = hitAnim(self, px, py)
        if animBtn ~= 0 then
            applyAnimHit(self, animBtn, px)
            event:hit()
            return
        end
        local outlineBtn = hitOutline(self, px, py)
        if outlineBtn ~= 0 then
            applyOutline(self, outlineBtn)
            event:hit()
            return
        end
        local cube = hitViewCube(self, px, py)
        if cube ~= 0 then
            snapView(self, cube)
            event:hit()
            return
        end
        local bone = hitBone(self, px, py)
        if bone ~= BONE_NONE then
            self.selectedBone = bone
            self.selectedId = PART_NONE
            setTool(self, TOOL_ROTATE)
            print("bone " .. self.bones[bone + 1].name)
            event:hit()
            return
        end
    end
    local tool = currentTool(self)
    local guides = readGuides(self)
    if tool == TOOL_CAMERA then
        local handle = HANDLE_ORBIT
        if guides then
            handle = hitCameraGizmo(self, px, py)
            if handle == HANDLE_NONE then
                handle = HANDLE_ORBIT
            end
        end
        beginDrag(self, tool, handle, px, py)
        event:hit()
        return
    end
    if guides and tool == TOOL_LIGHT then
        local handle = hitGizmo(self, px, py, tool)
        if handle == HANDLE_NONE then
            handle = HANDLE_UNI
        end
        beginDrag(self, tool, handle, px, py)
        event:hit()
        return
    end
    if guides and meshIsSelected(self) and gizmoTool(tool) then
        local handle = hitGizmo(self, px, py, tool)
        if handle ~= HANDLE_NONE then
            beginDrag(self, tool, handle, px, py)
            event:hit()
            return
        end
    end
    updateHover(self)
    if selectHoveredPart(self) then
        if gizmoTool(tool) then
            beginDrag(self, tool, HANDLE_UNI, px, py)
        end
        event:hit()
        return
    end
    self.selectedId = PART_NONE
    self.selectedBone = BONE_NONE
    self.hoverHandle = HANDLE_NONE
end

function pointerUp(self: PlaneLoader, event: PointerEvent)
    if self.dragging or self.animScrubbing or self.hoverTool ~= 0 or self.hoverHandle ~= HANDLE_NONE or self.hoverId ~= PART_NONE or self.hoverAnim ~= 0 then
        event:hit()
    end
    self.animScrubbing = false
    if self.dragging then
        if self.dragTool == TOOL_MOVE then
            print(string.format("moved %.2f %.2f %.2f", self.livePosX, self.livePosY, self.livePosZ))
        elseif self.dragTool == TOOL_ROTATE then
            if self.selectedBone ~= BONE_NONE then
                local bone = self.bones[self.selectedBone + 1]
                print(string.format("bone %s %.1f %.1f %.1f", bone.name, bone.liveRX, bone.liveRY, bone.liveRZ))
            else
                print(string.format("rotated %.1f %.1f %.1f", self.liveRotX, self.liveRotY, self.liveRotZ))
            end
        elseif self.dragTool == TOOL_SCALE then
            print(string.format("scaled %.2f", self.liveScale * self.liveScaleX))
        end
    end
    self.dragging = false
    self.dragHandle = HANDLE_NONE
end

function pointerExit(self: PlaneLoader, event: PointerEvent)
    self.hasPointer = false
    self.hoverId = PART_NONE
    self.hoverTool = 0
    self.hoverHandle = HANDLE_NONE
    self.hoverCube = 0
    self.hoverZoom = 0
    self.hoverOutline = 0
    self.hoverAnim = 0
    self.hoverBone = BONE_NONE
    self.animScrubbing = false
    self.dragging = false
end

function keyboardEvent(self: PlaneLoader, event: KeyboardEvent): boolean
    local key = event.key
    if event.phase == "up" then
        return false
    end
    local once = event.phase == "down"
    if key == GLFW_Q or key == GLFW_ONE then
        if once then
            setTool(self, TOOL_SELECT)
        end
        return true
    elseif key == GLFW_W or key == GLFW_ONE + 1 then
        if once then
            setTool(self, TOOL_MOVE)
        end
        return true
    elseif key == GLFW_E or key == GLFW_ONE + 2 then
        if once then
            setTool(self, TOOL_ROTATE)
        end
        return true
    elseif key == GLFW_R or key == GLFW_ONE + 3 then
        if once then
            setTool(self, TOOL_SCALE)
        end
        return true
    elseif key == GLFW_L or key == GLFW_ONE + 4 then
        if once then
            setTool(self, TOOL_LIGHT)
        end
        return true
    elseif key == GLFW_C or key == GLFW_ONE + 5 then
        if once then
            setTool(self, TOOL_CAMERA)
        end
        return true
    elseif key == GLFW_F then
        if once then
            snapView(self, 4)
        end
        return true
    elseif key == GLFW_G then
        if once then
            if self.overrideGrid == false then
                self.liveGrid = asBool(self.showGrid, true)
                self.overrideGrid = true
            end
            self.liveGrid = not self.liveGrid
            print(if self.liveGrid then "grid on" else "grid off")
        end
        return true
    elseif key == GLFW_H then
        if once then
            if self.overrideGuides == false then
                self.liveGuides = asBool(self.showGuides, true) and asBool(self.showUI, true)
                self.overrideGuides = true
            end
            self.liveGuides = not self.liveGuides
            print(if self.liveGuides then "ui on" else "ui off")
        end
        return true
    elseif key == GLFW_ESCAPE then
        if once then
            self.selectedId = PART_NONE
            self.selectedBone = BONE_NONE
            self.hoverHandle = HANDLE_NONE
            self.dragging = false
            print("deselect")
        end
        return true
    elseif key == GLFW_O then
        if once then
            applyOutline(self, OUT_TOGGLE)
        end
        return true
    elseif key == GLFW_LEFT_BRACKET then
        if once then
            applyOutline(self, OUT_WDEC)
        end
        return true
    elseif key == GLFW_RIGHT_BRACKET then
        if once then
            applyOutline(self, OUT_WINC)
        end
        return true
    elseif key == GLFW_SEMICOLON then
        if once then
            applyOutline(self, OUT_SDEC)
        end
        return true
    elseif key == GLFW_APOSTROPHE then
        if once then
            applyOutline(self, OUT_SINC)
        end
        return true
    elseif key == GLFW_EQUAL or key == GLFW_KP_ADD then
        applyZoom(self, 1)
        return true
    elseif key == GLFW_MINUS or key == GLFW_KP_SUBTRACT then
        applyZoom(self, 2)
        return true
    elseif key == GLFW_I then
        if once then
            insertBoneKey(self)
        end
        return true
    elseif key == GLFW_K then
        if once then
            toggleAnimPlay(self)
        end
        return true
    end
    return false
end

local function objectModel(self: PlaneLoader): Mat4
    return bodyModel(self)
end

function draw(self: PlaneLoader, renderer: Renderer)
    local context = self.context
    if context == nil or self.ready == false then
        return
    end
    if self.gpuFailed then
        self.uiCursor = 0
        if readGuides(self) then
            drawToolbar(self, renderer)
        end
        return
    end
    ensureGpu(self, context)
    local gpu = self.gpu
    local depthView = self.depthView
    local skyPipeline = self.skyPipeline
    local meshPipeline = self.meshPipeline
    local outlinePipeline = self.outlinePipeline
    local groundPipeline = self.groundPipeline
    local axisPipeline = self.axisPipeline
    local bindGroup = self.bindGroup
    local bindGroupAxis = self.bindGroupAxis
    local bindGroupGround = self.bindGroupGround
    local uboAxis = self.uboAxis
    local uboGround = self.uboGround
    local ground = self.ground
    local axisMesh = self.axisMesh
    if gpu == nil or depthView == nil or skyPipeline == nil or meshPipeline == nil or outlinePipeline == nil or groundPipeline == nil or axisPipeline == nil or bindGroup == nil or bindGroupAxis == nil or bindGroupGround == nil or uboAxis == nil or uboGround == nil or #self.parts == 0 or ground == nil or axisMesh == nil then
        self.uiCursor = 0
        if readGuides(self) then
            drawToolbar(self, renderer)
        end
        return
    end

    local aspect = gpu.width / math.max(gpu.height, 1)
    local camYaw, camPitch, camDist = readCam(self)
    local radius = math.max(self.extent.x, self.extent.y, self.extent.z) * camDist
    local yaw = math.rad(camYaw)
    if readOrbit(self) then
        yaw += self.elapsed * asNumber(self.orbitSpeed, 0.32)
    end
    local pitch = math.rad(camPitch)
    local bob = readCamBob(self)
    if bob then
        pitch += math.sin(self.elapsed * 0.65) * 0.04
    end
    local px, py, pz = readPos(self)
    local tx, ty, tz = readTarget(self)
    local target = Vector.xyz(
        tx,
        ty + (if bob then math.sin(self.elapsed * 1.4) * 0.05 else 0),
        tz
    )
    self.lookAt = target
    local eye = Vector.xyz(
        target.x + math.cos(yaw) * math.cos(pitch) * radius,
        target.y + math.sin(pitch) * radius + 0.35,
        target.z + math.sin(yaw) * math.cos(pitch) * radius
    )
    self.eyePos = eye
    local view = Mat4.lookAt(eye, target, Vector.xyz(0, 1, 0))
    local proj = Mat4.perspective(math.rad(asNumber(self.camFov, 26)), aspect, 0.1, radius * 12)
    Mat4.multiply(self.tmpViewProj, proj, view)

    local sun = sunDir(self)
    local groundY = self.center.y - self.extent.y
    local bands = math.clamp(math.floor(asNumber(self.shadeBands, 3) + 0.5), 2, 8)
    local outlineWidth = math.max(0, readOutlineWidth(self) * 0.01)
    local specAmt = asNumber(self.specAmount, 0.35)
    local exposure = asNumber(self.exposure, 0.68)
    local orr, og, ob = colorRgb(readOutlineColor(self), OUTLINE_COLOR)
    local lr, lg, lb = colorRgb(self.lightColor, LIGHT_COLOR)
    local model = objectModel(self)
    self.tmpModel = model
    updateBones(self, model)
    for _, part in self.parts do
        local bone = self.bones[part.bone + 1]
        if bone ~= nil then
            part.world = bone.world
        else
            part.world = model
        end
    end
    updateHover(self)

    local axisScale = math.max(self.extent.x, self.extent.y, self.extent.z) * asNumber(self.axisSize, 1)
    if axisScale == 0 then
        axisScale = 1
    end
    local apx = asNumber(self.axisPosX, 0)
    local apy = asNumber(self.axisPosY, 0)
    local apz = asNumber(self.axisPosZ, 0)
    local axisModel: Mat4
    if asBool(self.axisLocal, true) then
        axisModel = model * Mat4.fromTranslation(apx, apy, apz) * Mat4.fromScale(axisScale)
    elseif asBool(self.axisPosLocal, true) then
        axisModel = Mat4.fromTranslation(
            self.center.x + px + apx,
            self.center.y + py + apy,
            self.center.z + pz + apz
        ) * Mat4.fromScale(axisScale)
    else
        axisModel = Mat4.fromTranslation(apx, apy, apz) * Mat4.fromScale(axisScale)
    end

    local hoverId = self.hoverId
    local selectedId = self.selectedId
    if readGuides(self) == false then
        hoverId = PART_NONE
        selectedId = PART_NONE
    end

    for _, part in self.parts do
        local ubo = part.ubo
        if ubo ~= nil then
            writeFrame(self, ubo, self.tmpViewProj, part.world, sun, asNumber(self.lightIntensity, 1), eye, groundY, bands, outlineWidth, 0.965, specAmt, exposure, orr, og, ob, lr, lg, lb, part.partId, hoverId, selectedId)
        end
    end
    writeFrame(self, uboAxis, self.tmpViewProj, axisModel, sun, 1, eye, groundY, bands, outlineWidth, 0.965, specAmt, exposure, orr, og, ob, lr, lg, lb, PART_NONE, 0, 0)
    writeFrame(self, uboGround, self.tmpViewProj, Mat4.identity(), sun, 1, eye, groundY, bands, outlineWidth, 0.965, specAmt, exposure, orr, og, ob, lr, lg, lb, PART_NONE, 0, 0)

    local transparent = readTransparent(self)
    local clearColor = if transparent then { 0, 0, 0, 0 } else { 0.02, 0.04, 0.06, 1 }
    local msaaColor = self.msaaColor
    local colorArr: any
    if msaaColor ~= nil and self.samples > 1 then
        colorArr = {
            {
                view = msaaColor:view(),
                resolveTarget = gpu:colorView(),
                loadOp = "clear",
                storeOp = "discard",
                clearColor = clearColor,
            },
        }
    else
        colorArr = {
            {
                loadOp = "clear",
                storeOp = "store",
                clearColor = clearColor,
            },
        }
    end
    local pass = gpu:beginRenderPass({
        color = colorArr,
        depthStencil = {
            view = depthView,
            depthLoadOp = "clear",
            depthStoreOp = "discard",
            depthClearValue = 1,
        },
    })
    if transparent == false and asBool(self.showSky, true) then
        pass:setPipeline(skyPipeline)
        pass:setBindGroup(0, bindGroup)
        pass:draw(3)
    end

    if asBool(self.showGround, true) then
        pass:setPipeline(groundPipeline)
        pass:setBindGroup(0, bindGroupGround)
        pass:setVertexBuffer(0, ground.vertexBuffer)
        pass:draw(6)
    end

    if readShowOutline(self) and outlineWidth > 0 then
        pass:setPipeline(outlinePipeline)
        for _, part in self.parts do
            local bg = part.bindGroup
            if bg ~= nil and part.doOutline then
                pass:setBindGroup(0, bg)
                drawMesh(pass, part.draw, true)
            end
        end
    end

    pass:setPipeline(meshPipeline)
    for _, part in self.parts do
        local bg = part.bindGroup
        if bg ~= nil then
            pass:setBindGroup(0, bg)
            drawMesh(pass, part.draw, true)
        end
    end

    if readGuides(self) and asBool(self.showAxis, true) and currentTool(self) == TOOL_SELECT then
        pass:setPipeline(axisPipeline)
        pass:setBindGroup(0, bindGroupAxis)
        pass:setVertexBuffer(0, axisMesh.vertexBuffer)
        pass:draw(axisMesh.indexCount)
    end
    pass:finish()

    renderer:save()
    if self.scale ~= 1 then
        renderer:transform(Mat2D.withScale(1 / self.scale, 1 / self.scale))
    end
    renderer:drawImage(gpu.image, self.sampler, "srcOver", 1)
    renderer:restore()
    drawOverlay(self, renderer)
end

return function(context: Context): Layout<PlaneLoader>
    return {
        context = context,
        size = Vector.xy(800, 800),
        scale = 1,
        elapsed = 0,
        ready = false,
        sampler = ImageSampler("clamp", "clamp", "bilinear"),
        gpu = nil,
        depth = nil,
        depthView = nil,
        msaaColor = nil,
        samples = 1,
        skyPipeline = nil,
        meshPipeline = nil,
        outlinePipeline = nil,
        groundPipeline = nil,
        axisPipeline = nil,
        uboAxis = nil,
        uboGround = nil,
        uboBytes = buffer.create(UBO_SIZE),
        bindGroup = nil,
        bindGroupAxis = nil,
        bindGroupGround = nil,
        parts = {},
        bones = {},
        selectedBone = BONE_NONE,
        hoverBone = BONE_NONE,
        ground = nil,
        axisMesh = nil,
        center = Vector.xyz(0, 0, 0),
        extent = Vector.xyz(1, 1, 1),
        tmpViewProj = Mat4.identity(),
        tmpModel = Mat4.identity(),
        tmpMul = Mat4.identity(),
        gpuFailed = false,
        hoverId = 0,
        selectedId = 0,
        hasPointer = false,
        pointerX = 0,
        pointerY = 0,
        lightYaw = 16.5,
        lightPitch = 25,
        lightColor = LIGHT_COLOR,
        lightIntensity = 1,
        outlineWidth = 3.8,
        outlineColor = OUTLINE_COLOR,
        showOutline = true,
        outlineSmooth = 0.82,
        outlineScreen = true,
        shadeBands = 3,
        specAmount = 0.35,
        exposure = 0.68,
        posX = 0,
        posY = 0,
        posZ = 0,
        rotX = 0,
        rotY = 0,
        rotZ = 0,
        modelScale = 1,
        camYaw = 55,
        camPitch = 18,
        camDistance = 6.6,
        camFov = 26,
        orbit = false,
        orbitSpeed = 0.32,
        camBob = false,
        specThresh = 0.88,
        specSoft = 0.42,
        wrapLight = 0.28,
        ambient = 0.24,
        saturate = 1.12,
        metal = 0.62,
        fresnel = 0.32,
        shadowColor = SHADOW_COLOR,
        rimColor = RIM_COLOR,
        rimAmount = 0.48,
        rimPower = 2.8,
        aoAmount = 0.32,
        aoHeight = 0.22,
        fogAmount = 0.18,
        fogStart = 7,
        contactShadow = 0.42,
        contactRadius = 1.6,
        skyGlow = 1.35,
        fogColor = FOG_COLOR,
        showAxis = true,
        axisLocal = true,
        axisPosX = 0,
        axisPosY = 0,
        axisPosZ = 0,
        axisPosLocal = true,
        axisSize = 0.45,
        showSky = true,
        showGround = true,
        showGrid = true,
        gridSize = 0.25,
        showCamGizmo = true,
        showSockets = true,
        showGuides = true,
        showUI = true,
        transparentBg = false,
        msaa = true,
        skelLidHingeX = 0,
        skelLidHingeY = 0,
        skelLidHingeZ = 0,
        skelCapHingeX = 0,
        skelCapHingeY = 0,
        skelCapHingeZ = 0,
        skelLidArmX = 0,
        skelLidArmY = 0,
        skelLidArmZ = 0,
        skelCapArmX = 0,
        skelCapArmY = 0,
        skelCapArmZ = 0,
        skelChestX = 0,
        skelChestY = 0,
        skelChestZ = 0,
        skelChestScaleX = 1,
        skelChestScaleY = 1,
        skelChestScaleZ = 1,
        skelRootX = 0,
        skelRootY = 0,
        skelRootZ = 0,
        pickEnable = true,
        animTime = 0,
        animDuration = 3,
        animPlaying = false,
        animScrubbing = false,
        hoverAnim = 0,
        toolMode = 2,
        liveTool = TOOL_MOVE,
        overridePos = false,
        overrideRot = false,
        overrideScale = false,
        overrideLight = false,
        overrideCam = false,
        overrideOrbit = false,
        overrideGrid = false,
        liveGrid = true,
        overrideGuides = false,
        liveGuides = true,
        overrideOutline = false,
        liveShowOutline = true,
        liveOutlineWidth = 3.8,
        liveOutlineSmooth = 0.82,
        liveOutlineScreen = true,
        liveOutlineColor = OUTLINE_COLOR,
        liveOutlinePreset = 1,
        livePosX = 0,
        livePosY = 0,
        livePosZ = 0,
        liveRotX = 0,
        liveRotY = 0,
        liveRotZ = 0,
        liveScale = 1,
        liveScaleX = 1,
        liveScaleY = 1,
        liveScaleZ = 1,
        liveLightYaw = 16.5,
        liveLightPitch = 25,
        liveCamYaw = 55,
        liveCamPitch = 18,
        liveCamDistance = 6.6,
        liveOrbit = false,
        liveCamBob = false,
        dragging = false,
        dragTool = TOOL_MOVE,
        dragHandle = HANDLE_NONE,
        lastDragX = 0,
        lastDragY = 0,
        hoverHandle = HANDLE_NONE,
        hoverTool = 0,
        fillPaint = Paint.with({ style = "fill", color = Color.rgba(8, 14, 24, 220) }),
        strokePaint = Paint.with({
            style = "stroke",
            thickness = 2,
            cap = "round",
            join = "round",
            color = Color.rgb(255, 255, 255),
        }),
        uiPaths = {},
        uiCursor = 0,
        eyePos = Vector.xyz(0, 0, 0),
        lookAt = Vector.xyz(0, 0, 0),
        overrideTarget = false,
        liveTargetX = 0,
        liveTargetY = 0,
        liveTargetZ = 0,
        hoverCube = 0,
        hoverZoom = 0,
        hoverOutline = 0,
        init = init,
        resize = resize,
        advance = advance,
        draw = draw,
        pointerMove = pointerMove,
        pointerDown = pointerDown,
        pointerUp = pointerUp,
        pointerExit = pointerExit,
        keyboardEvent = keyboardEvent,
    }
end
