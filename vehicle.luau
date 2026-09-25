-- 3D Bruno-style vehicle in Rive: chassis boxes + ban.glb wheels (GPU) + body spring.
-- Controls: A/D steer, W/S gas, Shift NOS, Space drift.
-- B = contact guides, T = physics tune, O = look/shade/outline panel (drag sliders).
-- Camera: fixed angle, position follows the car (no yaw orbit).

local wheel_glb = require("wheel_glb")

local MAX_DRAWS = 128
local MAX_SHADOWS = 64
local MAX_PLANAR = 96
local MAX_JUICE = 96
local UNIFORM_STRIDE = 256

-- Antialiasing (MSAA). Change this yourself:
--   1 = OFF (safest, no crash)
--   2 = light AA (usually OK)
--   4 = heavy AA (crashed this viewer before with mobil.glb)
local MSAA_SAMPLES = 1

type Vec3 = { x: number, y: number, z: number }

type GpuMesh = {
	vertex: GPUBuffer,
	index: GPUBuffer,
	indexCount: number,
}

type GpuPart = {
	mesh: GpuMesh,
	r: number,
	g: number,
	b: number,
}

type JuiceParticle = {
	wx: number,
	wy: number,
	wz: number,
	vx: number,
	vy: number,
	vz: number,
	life: number,
	maxLife: number,
	size: number,
	r: number,
	g: number,
	b: number,
}

type Wheel = {
	ox: number,
	oz: number,
	radius: number,
	suspension: number,
	suspensionVel: number,
	inContact: boolean,
	spin: number,
	isFront: boolean,
	-- World planting (updated each frame)
	wx: number,
	wz: number,
	groundY: number,
	hubY: number,
}

-- Pushable world crates (AABB + yaw, simple impulse physics).
type PhysBox = {
	x: number,
	y: number,
	z: number,
	hx: number,
	hy: number,
	hz: number,
	vx: number,
	vy: number,
	vz: number,
	yaw: number,
	yawVel: number,
	r: number,
	g: number,
	b: number,
	mass: number,
}

-- Immovable ramp cubes (visual + solid walls; ride on top via groundHeight).
type StaticBox = {
	x: number,
	y: number,
	z: number,
	hx: number,
	hy: number,
	hz: number,
	r: number,
	g: number,
	b: number,
}

-- Live-tunable physics knobs (drag sliders; T toggles panel)
type TuneSlider = {
	key: string,
	label: string,
	lo: number,
	hi: number,
	value: number,
	r: number,
	g: number,
	b: number,
}

type Vehicle3D = {
	context: Context,
	canvas: GPUCanvas,
	sampler: ImageSampler,
	size: Vector,
	scale: number,
	path: Path,

	groundPaint: Paint,
	chassisPaint: Paint,
	bodyPaint: Paint,
	cabinPaint: Paint,
	wheelPaint: Paint,
	hubPaint: Paint,
	edgePaint: Paint,
	debugPaint: Paint,

	pipeline: GPUPipeline?,
	outlinePipeline: GPUPipeline?,
	shadowPipeline: GPUPipeline?,
	shadowUbo: GPUBuffer?,
	shadowCpu: buffer,
	shadowBindGroups: { GPUBindGroup },
	shadowMeshes: { GpuMesh },
	shadowCursor: number,
	planarPipeline: GPUPipeline?,
	planarUbo: GPUBuffer?,
	planarCpu: buffer,
	planarBindGroups: { GPUBindGroup },
	planarMeshes: { GpuMesh },
	planarCursor: number,
	drawEyeX: number,
	drawEyeY: number,
	drawEyeZ: number,
	groundPipeline: GPUPipeline?,
	groundUbo: GPUBuffer?,
	groundBind: GPUBindGroup?,
	groundCpu: buffer,
	depth: GPUTexture?,
	depthView: GPUTextureView?,
	msaaColor: GPUTexture?,
	samples: number,
	pipelineSamples: number,
	targetSamples: number,
	ubo: GPUBuffer?,
	uboCpu: buffer,
	bindGroups: { GPUBindGroup },
	drawMeshes: { GpuMesh },
	drawCursor: number,
	boxMesh: GpuMesh?,
	shadowDiscMesh: GpuMesh?,
	wheelParts: { GpuPart },
	wheelMeshRadius: number,
	wheelMeshOrient: Mat4,
	bodyParts: { GpuPart },
	bodyMeshSizeX: number,
	bodyMeshSizeY: number,
	bodyMeshSizeZ: number,
	bodyMeshOrient: Mat4,
	bodyMeshScale: number,
	bodyMeshLift: number,
	crates: { PhysBox },
	rampBlocks: { StaticBox },

	gas: number,
	steer: number,
	steerAngle: number,
	boost: number,
	drift: number,
	keysW: boolean,
	keysS: boolean,
	keysA: boolean,
	keysD: boolean,
	showDebug: boolean,
	paused: boolean,
	showTune: boolean,
	showLook: boolean,
	tune: { TuneSlider },
	look: { TuneSlider },
	tuneDrag: number,
	lookDrag: number,
	uiPaint: Paint,
	uiFill: Paint,

	x: number,
	y: number,
	z: number,
	yaw: number,
	vx: number,
	vy: number,
	vz: number,
	localSpeed: number,

	wheels: { Wheel },

	bodyPitch: number,
	bodyPitchVel: number,
	bodyRoll: number,
	bodyRollVel: number,
	bodySquash: number,

	-- Game juice
	camShake: number,
	fovKick: number,
	squashPunch: number,
	whiteFlash: number,
	prevBoost: number,
	airTime: number,
	juiceEmit: number,
	juiceParticles: { JuiceParticle },

	-- Fixed camera (same angle always; position follows the car)
	camOffset: Vec3,
	camLookOffset: Vec3,
	camIso: boolean,
	camOrthoSize: number,
	-- Intro home-cam (close showcase) → gameplay blend
	raceStarted: boolean,
	camBlend: number,
	camIntroAngle: number,
	wasOnRamp: boolean,
	-- True after ramp lip launch until all wheels can plant again
	launched: boolean,
}

local KEY = {
	A = 65,
	B = 66,
	D = 68,
	O = 79,
	P = 80,
	R = 82,
	W = 87,
	S = 83,
	LEFT = 263,
	RIGHT = 262,
	UP = 265,
	DOWN = 264,
	SPACE = 32,
	T = 84,
	C = 67,
	ENTER = 257,
	SHIFT_L = 340,
	SHIFT_R = 344,
}

-- Authoritative sizes used by both solid draw + debug overlays (world units).
local CHASSIS_HX, CHASSIS_HY, CHASSIS_HZ = 1.35, 0.28, 0.9
local CHASSIS_OY = -0.15
local BODY_HX, BODY_HY, BODY_HZ = 1.2, 0.35, 0.82
local BODY_OX, BODY_OY = 0.05, 0.35
local CABIN_HX, CABIN_HY, CABIN_HZ = 0.55, 0.28, 0.7
local CABIN_OX, CABIN_OY = -0.15, 0.85
local WHEEL_OX, WHEEL_OZ = 1.15, 0.85
local WHEEL_RADIUS = 0.42
local WHEEL_HALF_WIDTH = 0.14
local AXIS_LEN = 2.4

local ENGINE = 48
local ENGINE_LAUNCH = 1.85 -- punch from standstill
local BOOST_MULT = 1.85
local TOP_SPEED = 18
local TOP_SPEED_BOOST = 28
local DRAG = 0.85
local LATERAL_GRIP = 36
local LATERAL_GRIP_DRIFT = 2.4
local DRIFT_STEER_MULT = 2.4
local DRIFT_DRAG = 1.25
local STEER_SPEED = 4.0
local STEER_MAX = 0.88
local STEER_LERP = 16
local FRONT_GRIP = 1.35 -- nose stickiness / turn bite
local GRAVITY = 24
-- Real spring-damper suspension (chassis floats — not glued to ground)
-- Rest compress ≈ mass*g / (4*stiff) should sit near 0.12
local SUSP_REST = 0.52
local SUSP_MIN = 0.22
local SUSP_MAX = 1.15
local SUSP_STIFF = 260
local SUSP_DAMP = 22
local CAR_MASS = 14
local PITCH_INERTIA = 11
local ROLL_INERTIA = 7
local ANG_DAMP = 5.0
-- Extra lean from throttle / steer (on top of suspension)
local LEAN_PITCH_EXTRA = 0.14
local LEAN_ROLL_EXTRA = 0.2
-- Max contact-height span before we treat it as a cliff / jump
-- Max height a wheel may climb in one go (blocks wall / tip snapping)
local MAX_STEP_UP = 1.25 -- continuous slope OK; only blocks near-walls
local TUNE_X = 10
local TUNE_Y = 10
local TUNE_W = 292
local TUNE_ROW = 20
local TUNE_PAD = 6
local TUNE_TRACK_H = 6
local TUNE_THUMB = 10
local TUNE_LABEL_W = 78
local TUNE_HEAD = 24
local TUNE_TAB_W = 56
local TUNE_TAB_H = 22
local ISO_TAB_X = TUNE_X + TUNE_TAB_W + 8
local ISO_TAB_W = 48
local PAUSE_TAB_X = ISO_TAB_X + ISO_TAB_W + 8
local PAUSE_TAB_W = 60
local LOOK_TAB_X = PAUSE_TAB_X + PAUSE_TAB_W + 8
local LOOK_TAB_W = 56
local LOOK_W = 292

local BOX_FRICTION = 3.2
local BOX_ANG_DAMP = 4.5

-- Jump ramp: smooth plank. Drive up from -X (bottom); thin tip wall blocks +X ramming.
local RAMP_X0 = 14
local RAMP_X1 = 28
local RAMP_Z0 = -4.2
local RAMP_Z1 = 4.2
local RAMP_HEIGHT = 5.2
local RAMP_LEN = RAMP_X1 - RAMP_X0
local RAMP_THICK = 0.22
-- Lift so tire sits ON the surface (not through it)
local CONTACT_EPS = 0.03

-- Physics surface: linear plank (not stairs).
local function groundHeight(x: number, z: number): number
	if x >= RAMP_X0 and x <= RAMP_X1 and z >= RAMP_Z0 and z <= RAMP_Z1 then
		local t = (x - RAMP_X0) / RAMP_LEN
		return t * RAMP_HEIGHT
	end
	return 0
end

local function groundSlope(x: number, z: number): number
	if x >= RAMP_X0 and x <= RAMP_X1 and z >= RAMP_Z0 and z <= RAMP_Z1 then
		return RAMP_HEIGHT / RAMP_LEN
	end
	return 0
end

-- Surface normal (pointing "up" from the collider).
local function groundNormal(x: number, z: number): (number, number, number)
	local s = groundSlope(x, z)
	if s == 0 then
		return 0, 1, 0
	end
	local angle = math.atan(s)
	return -math.sin(angle), math.cos(angle), 0
end

-- Tip wall + solid fill under the HIGH part of the plank only.
-- Leave the low entrance open so you can drive onto the slope (no vertical curb).
local function buildRampBlocks(): { StaticBox }
	local halfW = (RAMP_Z1 - RAMP_Z0) * 0.5
	local out: { StaticBox } = {}
	local SEGS = 16
	local segL = RAMP_LEN / SEGS
	-- Only block the kolong once the underside is tall enough to drive under
	local MIN_FILL_H = 1.15
	for i = 0, SEGS - 1 do
		local x0 = RAMP_X0 + i * segL
		local mid = x0 + segL * 0.5
		local h = groundHeight(mid, 0)
		if h >= MIN_FILL_H then
			local fillH = h - 0.08
			table.insert(out, {
				x = mid,
				y = fillH * 0.5,
				z = 0,
				hx = segL * 0.5 * 0.98,
				hy = fillH * 0.5,
				hz = halfW * 0.98,
				r = 0.38,
				g = 0.34,
				b = 0.28,
			})
		end
	end
	-- High-end face wall (only blocks UNDER-deck ramming from +X; hang-over tip is allowed)
	table.insert(out, {
		x = RAMP_X1 + 0.22,
		y = RAMP_HEIGHT * 0.42,
		z = 0,
		hx = 0.22,
		hy = RAMP_HEIGHT * 0.42,
		hz = halfW + 0.15,
		r = 1.0,
		g = 0.78,
		b = 0.18,
	})
	return out
end

local function makeCrate(
	x: number,
	z: number,
	hx: number,
	hy: number,
	hz: number,
	r: number,
	g: number,
	b: number,
	mass: number
): PhysBox
	return {
		x = x,
		y = hy,
		z = z,
		hx = hx,
		hy = hy,
		hz = hz,
		vx = 0,
		vy = 0,
		vz = 0,
		yaw = 0,
		yawVel = 0,
		r = r,
		g = g,
		b = b,
		mass = mass,
	}
end

local function spawnCrates(): { PhysBox }
	return {
		makeCrate(6.5, 5.5, 0.55, 0.55, 0.55, 0.85, 0.45, 0.22, 2.2),
		makeCrate(8.2, 6.8, 0.55, 0.55, 0.55, 0.75, 0.35, 0.18, 2.2),
		makeCrate(7.0, 4.2, 0.55, 0.55, 0.55, 0.92, 0.55, 0.25, 2.2),
		makeCrate(10.5, 5.0, 0.7, 0.7, 0.7, 0.25, 0.55, 0.9, 3.5),
		makeCrate(5.0, 8.5, 0.65, 0.9, 0.65, 0.35, 0.75, 0.4, 3.0),
		makeCrate(-4.5, 7.0, 0.8, 0.6, 0.8, 0.9, 0.35, 0.55, 3.2),
		makeCrate(-6.0, 9.0, 0.55, 0.55, 0.55, 0.95, 0.8, 0.3, 2.0),
		makeCrate(12.0, 9.5, 1.0, 0.5, 0.5, 0.4, 0.7, 0.75, 2.8),
	}
end

local function clamp(v: number, lo: number, hi: number): number
	if v < lo then
		return lo
	end
	if v > hi then
		return hi
	end
	return v
end

local function addShake(self: Vehicle3D, amount: number)
	self.camShake = math.min(1.4, self.camShake + amount)
end

local function spawnJuice(
	self: Vehicle3D,
	wx: number,
	wy: number,
	wz: number,
	count: number,
	speed: number,
	size: number,
	life: number,
	r: number,
	g: number,
	b: number
)
	for _ = 1, count do
		if #self.juiceParticles >= MAX_JUICE then
			table.remove(self.juiceParticles, 1)
		end
		local ang = math.random() * math.pi * 2
		local elev = (math.random() - 0.25) * 0.9
		local spd = speed * (0.45 + math.random() * 0.9)
		table.insert(self.juiceParticles, {
			wx = wx + (math.random() - 0.5) * 0.2,
			wy = wy + (math.random() - 0.5) * 0.1,
			wz = wz + (math.random() - 0.5) * 0.2,
			vx = math.cos(ang) * spd,
			vy = math.abs(elev) * spd * 0.85 + spd * 0.15,
			vz = math.sin(ang) * spd,
			life = life * (0.7 + math.random() * 0.5),
			maxLife = life,
			size = size * (0.7 + math.random() * 0.6),
			r = r,
			g = g,
			b = b,
		})
	end
end

local function stepJuice(self: Vehicle3D, dt: number)
	self.camShake = math.max(0, self.camShake - dt * 3.2)
	self.fovKick = math.max(0, self.fovKick - dt * 2.4)
	self.squashPunch = math.max(0, self.squashPunch - dt * 4.5)
	self.whiteFlash = math.max(0, self.whiteFlash - dt * 5.5)
	self.juiceEmit += dt

	local i = 1
	while i <= #self.juiceParticles do
		local p = self.juiceParticles[i]
		p.life -= dt
		if p.life <= 0 then
			table.remove(self.juiceParticles, i)
		else
			p.wx += p.vx * dt
			p.wy += p.vy * dt
			p.wz += p.vz * dt
			p.vy -= 14 * dt
			p.vx *= (1 - 2.2 * dt)
			p.vz *= (1 - 2.2 * dt)
			i += 1
		end
	end
end

local function makeLook(): { TuneSlider }
	return {
		-- OUTLINE
		{ key = "outlineW", label = "OUT.W", lo = 0, hi = 12, value = 3.8, r = 220, g = 220, b = 230 },
		{ key = "outlineSm", label = "OUT.SM", lo = 0, hi = 1, value = 0.82, r = 180, g = 190, b = 210 },
		-- TOON SHADE
		{ key = "bands", label = "BANDS", lo = 2, hi = 6, value = 3, r = 255, g = 200, b = 100 },
		{ key = "wrap", label = "WRAP", lo = 0, hi = 0.8, value = 0.28, r = 255, g = 180, b = 80 },
		{ key = "ambient", label = "AMB", lo = 0, hi = 0.8, value = 0.24, r = 140, g = 160, b = 220 },
		{ key = "specAmt", label = "SPEC", lo = 0, hi = 1.2, value = 0.35, r = 255, g = 240, b = 180 },
		{ key = "specThr", label = "S.THR", lo = 0.4, hi = 1, value = 0.88, r = 255, g = 220, b = 140 },
		{ key = "exposure", label = "EXPOS", lo = 0.2, hi = 1.6, value = 0.68, r = 200, g = 200, b = 120 },
		{ key = "rimAmt", label = "RIM", lo = 0, hi = 1.4, value = 0.48, r = 255, g = 180, b = 120 },
		{ key = "rimPow", label = "R.POW", lo = 0.5, hi = 6, value = 2.8, r = 255, g = 160, b = 100 },
		{ key = "metal", label = "METAL", lo = 0, hi = 1, value = 0.62, r = 160, g = 180, b = 200 },
		{ key = "fresnel", label = "FRES", lo = 0, hi = 1, value = 0.32, r = 180, g = 200, b = 255 },
		-- LIGHT
		{ key = "lightYaw", label = "L.YAW", lo = -180, hi = 180, value = 70, r = 255, g = 210, b = 90 },
		{ key = "lightPitch", label = "L.PIT", lo = 5, hi = 80, value = 22, r = 255, g = 190, b = 70 },
		{ key = "lightInt", label = "L.INT", lo = 0.2, hi = 2.2, value = 1, r = 255, g = 230, b = 140 },
	}
end

local function lookVal(self: Vehicle3D, key: string, fallback: number): number
	for _, s in self.look do
		if s.key == key then
			return s.value
		end
	end
	return fallback
end

local function makeTune(): { TuneSlider }
	return {
		-- GRIP
		{ key = "latGrip", label = "GRIP", lo = 8, hi = 70, value = LATERAL_GRIP, r = 90, g = 200, b = 255 },
		{ key = "frontGrip", label = "F.GRIP", lo = 0.7, hi = 2.6, value = FRONT_GRIP, r = 255, g = 140, b = 70 },
		{ key = "driftGrip", label = "D.GRIP", lo = 0.4, hi = 12, value = LATERAL_GRIP_DRIFT, r = 255, g = 90, b = 180 },
		-- STEER
		{ key = "steerSpd", label = "STEER", lo = 1.0, hi = 8.0, value = STEER_SPEED, r = 120, g = 255, b = 140 },
		{ key = "steerMax", label = "S.MAX", lo = 0.35, hi = 1.25, value = STEER_MAX, r = 180, g = 255, b = 100 },
		{ key = "steerLerp", label = "S.SNAP", lo = 4, hi = 28, value = STEER_LERP, r = 200, g = 220, b = 90 },
		{ key = "driftSteer", label = "D.TURN", lo = 1.0, hi = 4.5, value = DRIFT_STEER_MULT, r = 255, g = 120, b = 200 },
		-- GAS / ENGINE
		{ key = "engine", label = "GAS", lo = 15, hi = 90, value = ENGINE, r = 255, g = 200, b = 80 },
		{ key = "launch", label = "LAUNCH", lo = 0.4, hi = 3.5, value = ENGINE_LAUNCH, r = 255, g = 170, b = 60 },
		{ key = "boost", label = "NOS", lo = 1.0, hi = 3.5, value = BOOST_MULT, r = 255, g = 90, b = 60 },
		{ key = "topSpd", label = "TOP", lo = 8, hi = 36, value = TOP_SPEED, r = 100, g = 220, b = 220 },
		{ key = "boostTop", label = "NOS TOP", lo = 12, hi = 45, value = TOP_SPEED_BOOST, r = 80, g = 200, b = 255 },
		{ key = "drag", label = "DRAG", lo = 0.2, hi = 2.5, value = DRAG, r = 160, g = 160, b = 200 },
		{ key = "driftDrag", label = "D.DRAG", lo = 0.4, hi = 3.0, value = DRIFT_DRAG, r = 180, g = 140, b = 220 },
		-- SUSPENSION / RIDE / WHEEL LAYOUT
		{ key = "wheel", label = "RODA", lo = 0.22, hi = 1.1, value = WHEEL_RADIUS, r = 240, g = 240, b = 120 },
		{ key = "base", label = "JARAK", lo = 1.2, hi = 4.8, value = WHEEL_OX * 2, r = 255, g = 180, b = 100 },
		{ key = "track", label = "LEBAR", lo = 0.9, hi = 3.4, value = WHEEL_OZ * 2, r = 255, g = 160, b = 140 },
		{ key = "ride", label = "HEIGHT", lo = 0.28, hi = 1.45, value = SUSP_REST, r = 255, g = 210, b = 90 },
		{ key = "suspStiff", label = "SPRING", lo = 80, hi = 520, value = SUSP_STIFF, r = 140, g = 180, b = 255 },
		{ key = "suspDamp", label = "DAMP", lo = 4, hi = 55, value = SUSP_DAMP, r = 100, g = 150, b = 255 },
		{ key = "maxStep", label = "CLIMB", lo = 0.2, hi = 2.0, value = MAX_STEP_UP, r = 220, g = 180, b = 120 },
		{ key = "zoom", label = "ZOOM", lo = 6, hi = 36, value = 14, r = 180, g = 220, b = 255 },
	}
end

local function syncWheelLayout(self: Vehicle3D)
	-- 1 FL, 2 FR, 3 RL, 4 RR
	local side = { 1, -1, 1, -1 }
	for i = 1, #self.wheels do
		local w = self.wheels[i]
		w.ox = if w.isFront then WHEEL_OX else -WHEEL_OX
		w.oz = side[i] * WHEEL_OZ
		w.radius = WHEEL_RADIUS
	end
end

local function applyTune(self: Vehicle3D)
	for _, s in self.tune do
		local v = s.value
		if s.key == "latGrip" then
			LATERAL_GRIP = v
		elseif s.key == "frontGrip" then
			FRONT_GRIP = v
		elseif s.key == "steerSpd" then
			STEER_SPEED = v
		elseif s.key == "steerMax" then
			STEER_MAX = v
		elseif s.key == "steerLerp" then
			STEER_LERP = v
		elseif s.key == "driftGrip" then
			LATERAL_GRIP_DRIFT = v
		elseif s.key == "driftSteer" then
			DRIFT_STEER_MULT = v
		elseif s.key == "engine" then
			ENGINE = v
		elseif s.key == "launch" then
			ENGINE_LAUNCH = v
		elseif s.key == "boost" then
			BOOST_MULT = v
		elseif s.key == "topSpd" then
			TOP_SPEED = v
		elseif s.key == "boostTop" then
			TOP_SPEED_BOOST = v
		elseif s.key == "drag" then
			DRAG = v
		elseif s.key == "driftDrag" then
			DRIFT_DRAG = v
		elseif s.key == "wheel" then
			WHEEL_RADIUS = v
			syncWheelLayout(self)
		elseif s.key == "base" then
			-- Full front–rear axle distance
			WHEEL_OX = v * 0.5
			syncWheelLayout(self)
		elseif s.key == "track" then
			-- Full left–right track width
			WHEEL_OZ = v * 0.5
			syncWheelLayout(self)
		elseif s.key == "ride" then
			-- Ride height: chassis sits higher, wheels stay on the ground
			SUSP_REST = v
			SUSP_MIN = math.max(0.12, math.min(SUSP_MIN, v - 0.2))
			if SUSP_MAX < v + 0.35 then
				SUSP_MAX = v + 0.35
			end
		elseif s.key == "suspStiff" then
			SUSP_STIFF = v
		elseif s.key == "suspDamp" then
			SUSP_DAMP = v
		elseif s.key == "maxStep" then
			MAX_STEP_UP = v
		elseif s.key == "zoom" then
			self.camOrthoSize = v
			-- Also pull/push perspective camera distance
			local scale = v / 14
			self.camOffset = { x = 10 * scale, y = 8 * scale, z = 12 * scale }
		end
	end
end

local function printTuneLegend(self: Vehicle3D)
	print("--- CAR TUNE (T = hide/show) drag sliders ---")
	for i, s in self.tune do
		print(string.format("  %2d  %-8s %-10s = %.3f", i, s.label, s.key, s.value))
	end
end

local function tunePanelHeight(self: Vehicle3D): number
	return TUNE_HEAD + TUNE_PAD + #self.tune * TUNE_ROW + TUNE_PAD
end

local function tuneHitIndex(self: Vehicle3D, px: number, py: number): number
	if not self.showTune then
		return 0
	end
	local h = tunePanelHeight(self)
	if px < TUNE_X or px > TUNE_X + TUNE_W or py < TUNE_Y or py > TUNE_Y + h then
		return 0
	end
	local rowsTop = TUNE_Y + TUNE_HEAD
	local rel = py - rowsTop
	if rel < 0 then
		return 0
	end
	local idx = math.floor(rel / TUNE_ROW) + 1
	if idx < 1 or idx > #self.tune then
		return 0
	end
	return idx
end

local function tuneTabHit(self: Vehicle3D, px: number, py: number): boolean
	return px >= TUNE_X and px <= TUNE_X + TUNE_TAB_W and py >= TUNE_Y and py <= TUNE_Y + TUNE_TAB_H
end

local function isoTabHit(_self: Vehicle3D, px: number, py: number): boolean
	return px >= ISO_TAB_X and px <= ISO_TAB_X + ISO_TAB_W and py >= TUNE_Y and py <= TUNE_Y + TUNE_TAB_H
end

local function pauseTabHit(_self: Vehicle3D, px: number, py: number): boolean
	return px >= PAUSE_TAB_X and px <= PAUSE_TAB_X + PAUSE_TAB_W and py >= TUNE_Y and py <= TUNE_Y + TUNE_TAB_H
end

local function lookTabHit(_self: Vehicle3D, px: number, py: number): boolean
	return px >= LOOK_TAB_X and px <= LOOK_TAB_X + LOOK_TAB_W and py >= TUNE_Y and py <= TUNE_Y + TUNE_TAB_H
end

local function lookPanelX(self: Vehicle3D): number
	return math.max(TUNE_X, self.size.x - LOOK_W - 10)
end

local function lookPanelHeight(self: Vehicle3D): number
	return TUNE_HEAD + TUNE_PAD + #self.look * TUNE_ROW + TUNE_PAD
end

local function lookHitIndex(self: Vehicle3D, px: number, py: number): number
	if not self.showLook then
		return 0
	end
	local lx = lookPanelX(self)
	local h = lookPanelHeight(self)
	if px < lx or px > lx + LOOK_W or py < TUNE_Y or py > TUNE_Y + h then
		return 0
	end
	local rowsTop = TUNE_Y + TUNE_HEAD
	local rel = py - rowsTop
	if rel < 0 then
		return 0
	end
	local idx = math.floor(rel / TUNE_ROW) + 1
	if idx < 1 or idx > #self.look then
		return 0
	end
	return idx
end

local function setLookFromX(self: Vehicle3D, idx: number, px: number)
	local s = self.look[idx]
	if not s then
		return
	end
	local lx = lookPanelX(self)
	local trackX0 = lx + TUNE_PAD + TUNE_LABEL_W
	local trackX1 = lx + LOOK_W - TUNE_PAD - 52
	local t = clamp((px - trackX0) / math.max(trackX1 - trackX0, 1), 0, 1)
	s.value = s.lo + (s.hi - s.lo) * t
	if s.key == "bands" then
		s.value = math.floor(s.value + 0.5)
	end
	print(string.format("look %s (%s) = %.3f", s.label, s.key, s.value))
end

local function toggleLook(self: Vehicle3D)
	self.showLook = not self.showLook
	self.lookDrag = 0
	if self.showLook then
		self.showTune = false
		self.tuneDrag = 0
		print("LOOK panel ON — outline / shade / light (O to close)")
	else
		print("look panel OFF")
	end
end

local function togglePause(self: Vehicle3D)
	self.paused = not self.paused
	print(if self.paused then "PAUSE — sim frozen (P / PAUSE)" else "RESUME")
end

local function toggleCamIso(self: Vehicle3D)
	self.camIso = not self.camIso
	print(if self.camIso then "camera ISO ortho ON" else "camera perspective ON")
end

local function raceButtonRect(self: Vehicle3D): (number, number, number, number)
	local bw, bh = 120, 36
	local bx = (self.size.x - bw) * 0.5
	local by = self.size.y - 56
	return bx, by, bw, bh
end

local function startRace(self: Vehicle3D)
	if self.raceStarted then
		return
	end
	self.raceStarted = true
	print("START — camera to gameplay")
end

local function restartRace(self: Vehicle3D)
	self.raceStarted = false
	self.camBlend = 0
	self.camIntroAngle = 0
	self.paused = false
	self.x = 0
	self.y = WHEEL_RADIUS + CONTACT_EPS + SUSP_REST
	self.z = 0
	self.yaw = 0
	self.vx = 0
	self.vy = 0
	self.vz = 0
	self.localSpeed = 0
	self.steerAngle = 0
	self.gas = 0
	self.steer = 0
	self.boost = 0
	self.drift = 0
	self.bodyPitch = 0
	self.bodyPitchVel = 0
	self.bodyRoll = 0
	self.bodyRollVel = 0
	self.bodySquash = 1
	self.camShake = 0
	self.fovKick = 0
	self.squashPunch = 0
	self.whiteFlash = 0
	self.prevBoost = 0
	self.airTime = 0
	self.juiceEmit = 0
	self.juiceParticles = {}
	self.wasOnRamp = false
	self.launched = false
	self.camOffset = { x = 10, y = 8, z = 12 }
	self.camLookOffset = { x = 0, y = 0.5, z = 0 }
	for _, w in self.wheels do
		w.suspension = SUSP_REST
		w.suspensionVel = 0
		w.inContact = true
		w.spin = 0
		w.wx = 0
		w.wz = 0
		w.groundY = 0
		w.hubY = WHEEL_RADIUS
	end
	self.crates = spawnCrates()
	print("RESTART — home cam (ENTER / START or W to race)")
end

local function startTabHit(self: Vehicle3D, px: number, py: number): boolean
	if self.raceStarted then
		return false
	end
	local bx, by, bw, bh = raceButtonRect(self)
	return px >= bx and px <= bx + bw and py >= by and py <= by + bh
end

local function restartTabHit(self: Vehicle3D, px: number, py: number): boolean
	if not self.raceStarted then
		return false
	end
	local bx, by, bw, bh = raceButtonRect(self)
	return px >= bx and px <= bx + bw and py >= by and py <= by + bh
end

local function setTuneFromX(self: Vehicle3D, idx: number, px: number)
	local s = self.tune[idx]
	if not s then
		return
	end
	local trackX0 = TUNE_X + TUNE_PAD + TUNE_LABEL_W
	local trackX1 = TUNE_X + TUNE_W - TUNE_PAD - 52
	local t = clamp((px - trackX0) / math.max(trackX1 - trackX0, 1), 0, 1)
	s.value = s.lo + (s.hi - s.lo) * t
	applyTune(self)
	print(string.format("tune %s (%s) = %.3f", s.label, s.key, s.value))
end

local function drawRect(
	path: Path,
	renderer: Renderer,
	paint: Paint,
	x: number,
	y: number,
	w: number,
	h: number
)
	path:reset()
	path:moveTo(Vector.xy(x, y))
	path:lineTo(Vector.xy(x + w, y))
	path:lineTo(Vector.xy(x + w, y + h))
	path:lineTo(Vector.xy(x, y + h))
	path:close()
	renderer:drawPath(path, paint)
end

-- Tiny 3x5 pixel font (A-Z, 0-9, . -) so labels are readable without a Text API
local GLYPH: { [string]: { string } } = {
	["A"] = { ".#.", "#.#", "###", "#.#", "#.#" },
	["B"] = { "##.", "#.#", "##.", "#.#", "##." },
	["C"] = { ".##", "#..", "#..", "#..", ".##" },
	["D"] = { "##.", "#.#", "#.#", "#.#", "##." },
	["E"] = { "###", "#..", "##.", "#..", "###" },
	["F"] = { "###", "#..", "##.", "#..", "#.." },
	["G"] = { ".##", "#..", "#.#", "#.#", ".##" },
	["H"] = { "#.#", "#.#", "###", "#.#", "#.#" },
	["I"] = { "###", ".#.", ".#.", ".#.", "###" },
	["J"] = { ".##", "..#", "..#", "#.#", ".#." },
	["K"] = { "#.#", "#.#", "##.", "#.#", "#.#" },
	["L"] = { "#..", "#..", "#..", "#..", "###" },
	["M"] = { "#.#", "###", "#.#", "#.#", "#.#" },
	["N"] = { "#.#", "##.", "#.#", "#.#", "#.#" },
	["O"] = { ".#.", "#.#", "#.#", "#.#", ".#." },
	["P"] = { "##.", "#.#", "##.", "#..", "#.." },
	["R"] = { "##.", "#.#", "##.", "#.#", "#.#" },
	["S"] = { ".##", "#..", ".#.", "..#", "##." },
	["T"] = { "###", ".#.", ".#.", ".#.", ".#." },
	["U"] = { "#.#", "#.#", "#.#", "#.#", ".#." },
	["W"] = { "#.#", "#.#", "#.#", "###", "#.#" },
	["X"] = { "#.#", "#.#", ".#.", "#.#", "#.#" },
	["Y"] = { "#.#", "#.#", ".#.", ".#.", ".#." },
	["0"] = { ".#.", "#.#", "#.#", "#.#", ".#." },
	["1"] = { ".#.", "##.", ".#.", ".#.", "###" },
	["2"] = { "##.", "..#", ".#.", "#..", "###" },
	["3"] = { "##.", "..#", "##.", "..#", "##." },
	["4"] = { "#.#", "#.#", "###", "..#", "..#" },
	["5"] = { "###", "#..", "##.", "..#", "##." },
	["6"] = { ".##", "#..", "##.", "#.#", ".#." },
	["7"] = { "###", "..#", ".#.", ".#.", ".#." },
	["8"] = { ".#.", "#.#", ".#.", "#.#", ".#." },
	["9"] = { ".#.", "#.#", ".##", "..#", "##." },
	["."] = { "...", "...", "...", "...", ".#." },
	["-"] = { "...", "...", "###", "...", "..." },
	[" "] = { "...", "...", "...", "...", "..." },
}

local function drawGlyph(
	path: Path,
	renderer: Renderer,
	paint: Paint,
	ch: string,
	ox: number,
	oy: number,
	px: number
)
	local g = GLYPH[ch]
	if not g then
		g = GLYPH["-"]
	end
	if not g then
		return
	end
	for row = 1, 5 do
		local line = g[row]
		for col = 1, 3 do
			if string.sub(line, col, col) == "#" then
				drawRect(path, renderer, paint, ox + (col - 1) * px, oy + (row - 1) * px, px, px)
			end
		end
	end
end

local function drawLabel(
	path: Path,
	renderer: Renderer,
	paint: Paint,
	str: string,
	x: number,
	y: number,
	px: number
)
	local cx = x
	local gap = px
	for i = 1, #str do
		local ch = string.sub(str, i, i)
		drawGlyph(path, renderer, paint, ch, cx, y, px)
		cx += 3 * px + gap
	end
end

local SEG: { [string]: { number }? } = {
	["0"] = { 1, 1, 1, 1, 1, 1, 0 },
	["1"] = { 0, 1, 1, 0, 0, 0, 0 },
	["2"] = { 1, 1, 0, 1, 1, 0, 1 },
	["3"] = { 1, 1, 1, 1, 0, 0, 1 },
	["4"] = { 0, 1, 1, 0, 0, 1, 1 },
	["5"] = { 1, 0, 1, 1, 0, 1, 1 },
	["6"] = { 1, 0, 1, 1, 1, 1, 1 },
	["7"] = { 1, 1, 1, 0, 0, 0, 0 },
	["8"] = { 1, 1, 1, 1, 1, 1, 1 },
	["9"] = { 1, 1, 1, 1, 0, 1, 1 },
	["-"] = { 0, 0, 0, 0, 0, 0, 1 },
}

local function drawSegDigit(
	path: Path,
	renderer: Renderer,
	paint: Paint,
	ch: string,
	ox: number,
	oy: number,
	sw: number,
	sh: number
)
	if ch == "." then
		drawRect(path, renderer, paint, ox + sw * 0.7, oy + sh * 0.85, sw * 0.22, sh * 0.18)
		return
	end
	local bits = SEG[ch]
	if not bits then
		return
	end
	local t = math.max(1.0, sh * 0.12)
	if bits[1] == 1 then
		drawRect(path, renderer, paint, ox + t, oy, sw - 2 * t, t)
	end
	if bits[2] == 1 then
		drawRect(path, renderer, paint, ox + sw - t, oy + t, t, sh * 0.5 - t)
	end
	if bits[3] == 1 then
		drawRect(path, renderer, paint, ox + sw - t, oy + sh * 0.5, t, sh * 0.5 - t)
	end
	if bits[4] == 1 then
		drawRect(path, renderer, paint, ox + t, oy + sh - t, sw - 2 * t, t)
	end
	if bits[5] == 1 then
		drawRect(path, renderer, paint, ox, oy + sh * 0.5, t, sh * 0.5 - t)
	end
	if bits[6] == 1 then
		drawRect(path, renderer, paint, ox, oy + t, t, sh * 0.5 - t)
	end
	if bits[7] == 1 then
		drawRect(path, renderer, paint, ox + t, oy + sh * 0.5 - t * 0.5, sw - 2 * t, t)
	end
end

local function drawNumber(
	path: Path,
	renderer: Renderer,
	paint: Paint,
	value: number,
	x: number,
	y: number,
	digitW: number,
	digitH: number
)
	local s = string.format("%.1f", value)
	local cx = x
	for i = 1, #s do
		local ch = string.sub(s, i, i)
		if ch == "." then
			drawSegDigit(path, renderer, paint, ch, cx, y, digitW * 0.5, digitH)
			cx += digitW * 0.4
		else
			drawSegDigit(path, renderer, paint, ch, cx, y, digitW, digitH)
			cx += digitW + 1.5
		end
	end
end

local function drawTunePanel(self: Vehicle3D, renderer: Renderer)
	local path = self.path
	local bg = self.uiPaint
	local fill = self.uiFill

	-- Always-visible TUNE + ISO + PAUSE + LOOK tabs
	bg.color = if self.showTune then Color.rgba(40, 90, 180, 230) else Color.rgba(20, 28, 40, 220)
	bg.style = "fill"
	drawRect(path, renderer, bg, TUNE_X, TUNE_Y, TUNE_TAB_W, TUNE_TAB_H)
	fill.color = Color.rgb(230, 240, 255)
	fill.style = "fill"
	drawLabel(path, renderer, fill, "TUNE", TUNE_X + 8, TUNE_Y + 5, 2)

	bg.color = if self.camIso then Color.rgba(40, 140, 90, 230) else Color.rgba(20, 28, 40, 220)
	bg.style = "fill"
	drawRect(path, renderer, bg, ISO_TAB_X, TUNE_Y, ISO_TAB_W, TUNE_TAB_H)
	fill.color = if self.camIso then Color.rgb(200, 255, 220) else Color.rgb(180, 190, 200)
	drawLabel(path, renderer, fill, "ISO", ISO_TAB_X + 10, TUNE_Y + 5, 2)

	bg.color = if self.paused then Color.rgba(180, 120, 30, 235) else Color.rgba(20, 28, 40, 220)
	bg.style = "fill"
	drawRect(path, renderer, bg, PAUSE_TAB_X, TUNE_Y, PAUSE_TAB_W, TUNE_TAB_H)
	fill.color = if self.paused then Color.rgb(255, 240, 180) else Color.rgb(180, 190, 200)
	drawLabel(path, renderer, fill, "PAUSE", PAUSE_TAB_X + 6, TUNE_Y + 5, 2)

	bg.color = if self.showLook then Color.rgba(160, 70, 200, 235) else Color.rgba(20, 28, 40, 220)
	bg.style = "fill"
	drawRect(path, renderer, bg, LOOK_TAB_X, TUNE_Y, LOOK_TAB_W, TUNE_TAB_H)
	fill.color = if self.showLook then Color.rgb(250, 230, 255) else Color.rgb(180, 190, 200)
	drawLabel(path, renderer, fill, "LOOK", LOOK_TAB_X + 8, TUNE_Y + 5, 2)

	if self.paused then
		local w = self.size.x
		fill.color = Color.rgba(255, 200, 80, 230)
		drawLabel(path, renderer, fill, "PAUSED", (w - 72) * 0.5, 36, 3)
	end

	if not self.showTune then
		return
	end

	local panelH = tunePanelHeight(self)
	bg.color = Color.rgba(10, 14, 22, 225)
	bg.style = "fill"
	drawRect(path, renderer, bg, TUNE_X, TUNE_Y, TUNE_W, panelH)

	bg.color = Color.rgba(70, 130, 255, 230)
	bg.style = "stroke"
	bg.thickness = 1.4
	drawRect(path, renderer, bg, TUNE_X, TUNE_Y, TUNE_W, panelH)

	-- Header bar
	bg.color = Color.rgba(30, 50, 90, 240)
	bg.style = "fill"
	drawRect(path, renderer, bg, TUNE_X, TUNE_Y, TUNE_W, TUNE_HEAD)
	fill.color = Color.rgb(200, 220, 255)
	drawLabel(path, renderer, fill, "CAR SETUP", TUNE_X + 10, TUNE_Y + 8, 2)
	fill.color = Color.rgb(140, 160, 190)
	drawLabel(path, renderer, fill, "T CLOSE", TUNE_X + TUNE_W - 70, TUNE_Y + 10, 1)

	local trackX0 = TUNE_X + TUNE_PAD + TUNE_LABEL_W
	local trackW = TUNE_W - TUNE_PAD * 2 - TUNE_LABEL_W - 52
	local rowsTop = TUNE_Y + TUNE_HEAD

	for i, s in self.tune do
		local rowY = rowsTop + (i - 1) * TUNE_ROW
		local trackY = rowY + (TUNE_ROW - TUNE_TRACK_H) * 0.5
		local active = self.tuneDrag == i

		if active then
			bg.color = Color.rgba(40, 60, 100, 160)
			bg.style = "fill"
			drawRect(path, renderer, bg, TUNE_X + 2, rowY, TUNE_W - 4, TUNE_ROW)
		end

		-- Label
		fill.color = Color.rgb(s.r, s.g, s.b)
		fill.style = "fill"
		drawLabel(path, renderer, fill, s.label, TUNE_X + TUNE_PAD, rowY + 5, 2)

		-- Track
		fill.color = Color.rgb(36, 44, 58)
		drawRect(path, renderer, fill, trackX0, trackY, trackW, TUNE_TRACK_H)

		local t = clamp((s.value - s.lo) / math.max(s.hi - s.lo, 1e-6), 0, 1)
		local fillW = trackW * t
		fill.color = Color.rgb(s.r, s.g, s.b)
		drawRect(path, renderer, fill, trackX0, trackY, fillW, TUNE_TRACK_H)

		local thumbX = trackX0 + fillW - TUNE_THUMB * 0.5
		fill.color = if active then Color.rgb(255, 255, 255) else Color.rgb(230, 235, 245)
		drawRect(
			path,
			renderer,
			fill,
			thumbX,
			trackY + TUNE_TRACK_H * 0.5 - TUNE_THUMB * 0.5,
			TUNE_THUMB,
			TUNE_THUMB
		)

		-- Value
		fill.color = Color.rgb(s.r, s.g, s.b)
		drawNumber(path, renderer, fill, s.value, TUNE_X + TUNE_W - 50, rowY + 4, 6, 11)
	end
end

local function drawLookPanel(self: Vehicle3D, renderer: Renderer)
	if not self.showLook then
		return
	end
	local path = self.path
	local bg = self.uiPaint
	local fill = self.uiFill
	local lx = lookPanelX(self)
	local panelH = lookPanelHeight(self)

	bg.color = Color.rgba(14, 10, 22, 230)
	bg.style = "fill"
	drawRect(path, renderer, bg, lx, TUNE_Y, LOOK_W, panelH)

	bg.color = Color.rgba(180, 90, 220, 230)
	bg.style = "stroke"
	bg.thickness = 1.4
	drawRect(path, renderer, bg, lx, TUNE_Y, LOOK_W, panelH)

	bg.color = Color.rgba(60, 30, 90, 240)
	bg.style = "fill"
	drawRect(path, renderer, bg, lx, TUNE_Y, LOOK_W, TUNE_HEAD)
	fill.color = Color.rgb(235, 210, 255)
	fill.style = "fill"
	drawLabel(path, renderer, fill, "LOOK / SHADE", lx + 10, TUNE_Y + 8, 2)
	fill.color = Color.rgb(170, 140, 200)
	drawLabel(path, renderer, fill, "O CLOSE", lx + LOOK_W - 70, TUNE_Y + 10, 1)

	local trackX0 = lx + TUNE_PAD + TUNE_LABEL_W
	local trackW = LOOK_W - TUNE_PAD * 2 - TUNE_LABEL_W - 52
	local rowsTop = TUNE_Y + TUNE_HEAD

	for i, s in self.look do
		local rowY = rowsTop + (i - 1) * TUNE_ROW
		local trackY = rowY + (TUNE_ROW - TUNE_TRACK_H) * 0.5
		local active = self.lookDrag == i

		if active then
			bg.color = Color.rgba(70, 40, 110, 160)
			bg.style = "fill"
			drawRect(path, renderer, bg, lx + 2, rowY, LOOK_W - 4, TUNE_ROW)
		end

		fill.color = Color.rgb(s.r, s.g, s.b)
		fill.style = "fill"
		drawLabel(path, renderer, fill, s.label, lx + TUNE_PAD, rowY + 5, 2)

		fill.color = Color.rgb(40, 32, 52)
		drawRect(path, renderer, fill, trackX0, trackY, trackW, TUNE_TRACK_H)

		local t = clamp((s.value - s.lo) / math.max(s.hi - s.lo, 1e-6), 0, 1)
		local fillW = trackW * t
		fill.color = Color.rgb(s.r, s.g, s.b)
		drawRect(path, renderer, fill, trackX0, trackY, fillW, TUNE_TRACK_H)

		local thumbX = trackX0 + fillW - TUNE_THUMB * 0.5
		fill.color = if active then Color.rgb(255, 255, 255) else Color.rgb(230, 235, 245)
		drawRect(
			path,
			renderer,
			fill,
			thumbX,
			trackY + TUNE_TRACK_H * 0.5 - TUNE_THUMB * 0.5,
			TUNE_THUMB,
			TUNE_THUMB
		)

		fill.color = Color.rgb(s.r, s.g, s.b)
		drawNumber(path, renderer, fill, s.value, lx + LOOK_W - 50, rowY + 4, 6, 11)
	end
end

local function v3(x: number, y: number, z: number): Vec3
	return { x = x, y = y, z = z }
end

local function project(mvp: Mat4, p: Vec3, screenW: number, screenH: number): (Vector, number)
	local x, y, z, w = mvp:transformVec4(p.x, p.y, p.z, 1)
	if w == 0 then
		w = 1e-6
	end
	local ndcX = x / w
	local ndcY = y / w
	local sx = (ndcX * 0.5 + 0.5) * screenW
	local sy = (1 - (ndcY * 0.5 + 0.5)) * screenH
	return Vector.xy(sx, sy), z / w
end

local function drawStartPrompt(self: Vehicle3D, renderer: Renderer)
	local path = self.path
	local bg = self.uiPaint
	local fill = self.uiFill
	local bx, by, bw, bh = raceButtonRect(self)

	if self.raceStarted then
		bg.color = Color.rgba(40, 70, 120, 210)
		bg.style = "fill"
		drawRect(path, renderer, bg, bx, by, bw, bh)
		bg.color = Color.rgba(160, 190, 240, 220)
		bg.style = "stroke"
		bg.thickness = 2
		drawRect(path, renderer, bg, bx, by, bw, bh)
		fill.color = Color.rgb(230, 240, 255)
		fill.style = "fill"
		drawLabel(path, renderer, fill, "RESTART", bx + 18, by + 10, 2)
		fill.color = Color.rgb(170, 185, 205)
		drawLabel(path, renderer, fill, "R", bx + 54, by - 18, 2)
		return
	end

	local pulse = 0.75 + 0.25 * math.sin(self.camIntroAngle * 4)
	bg.color = Color.rgba(220, 50, 60, math.floor(180 + 50 * pulse))
	bg.style = "fill"
	drawRect(path, renderer, bg, bx, by, bw, bh)
	bg.color = Color.rgba(255, 220, 220, 230)
	bg.style = "stroke"
	bg.thickness = 2
	drawRect(path, renderer, bg, bx, by, bw, bh)
	fill.color = Color.rgb(255, 255, 255)
	fill.style = "fill"
	drawLabel(path, renderer, fill, "START", bx + 28, by + 10, 2)
	fill.color = Color.rgb(200, 210, 220)
	drawLabel(path, renderer, fill, "ENTER", bx + 30, by - 18, 2)
end

-- Unit disc in XZ (y=0), non-overlapping fan — one soft planar shadow layer
local function makeShadowDiscMesh(segments: number): GpuMesh
	local segs = math.max(8, math.floor(segments))
	local vertCount = segs + 1
	local vertices = buffer.create(vertCount * 24)
	-- center
	buffer.writef32(vertices, 0, 0)
	buffer.writef32(vertices, 4, 0)
	buffer.writef32(vertices, 8, 0)
	buffer.writef32(vertices, 12, 0)
	buffer.writef32(vertices, 16, 1)
	buffer.writef32(vertices, 20, 0)
	for i = 0, segs - 1 do
		local a = (i / segs) * math.pi * 2
		local dst = (i + 1) * 24
		buffer.writef32(vertices, dst, math.cos(a))
		buffer.writef32(vertices, dst + 4, 0)
		buffer.writef32(vertices, dst + 8, math.sin(a))
		buffer.writef32(vertices, dst + 12, 0)
		buffer.writef32(vertices, dst + 16, 1)
		buffer.writef32(vertices, dst + 20, 0)
	end
	local indices = buffer.create(segs * 3 * 2)
	for i = 0, segs - 1 do
		local ii = i * 6
		local i1 = i + 1
		local i2 = if i + 1 < segs then i + 2 else 1
		buffer.writeu16(indices, ii, 0)
		buffer.writeu16(indices, ii + 2, i1)
		buffer.writeu16(indices, ii + 4, i2)
	end
	return {
		vertex = GPUBuffer.new({
			size = buffer.len(vertices),
			usage = "vertex",
			data = vertices,
			immutable = true,
		}),
		index = GPUBuffer.new({
			size = buffer.len(indices),
			usage = "index",
			data = indices,
			immutable = true,
		}),
		indexCount = segs * 3,
	}
end

local function makeBoxMesh(): GpuMesh
	local px = { 1, 1, 1, 1, -1, -1, -1, -1, -1, -1, 1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1, -1, -1, 1 }
	local py = { -1, 1, 1, -1, -1, 1, 1, -1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1, 1, 1, -1, -1, 1, 1 }
	local pz = { -1, -1, 1, 1, 1, 1, -1, -1, -1, 1, 1, -1, 1, 1, -1, -1, 1, 1, 1, 1, -1, -1, -1, -1 }
	local nx = { 1, 1, 1, 1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	local ny = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0 }
	local nz = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, -1, -1, -1, -1 }
	local vertices = buffer.create(24 * 24)
	for i = 0, 23 do
		local dst = i * 24
		buffer.writef32(vertices, dst, px[i + 1])
		buffer.writef32(vertices, dst + 4, py[i + 1])
		buffer.writef32(vertices, dst + 8, pz[i + 1])
		buffer.writef32(vertices, dst + 12, nx[i + 1])
		buffer.writef32(vertices, dst + 16, ny[i + 1])
		buffer.writef32(vertices, dst + 20, nz[i + 1])
	end
	local indices = buffer.create(36 * 2)
	local ii = 0
	for face = 0, 5 do
		local base = face * 4
		buffer.writeu16(indices, ii, base)
		buffer.writeu16(indices, ii + 2, base + 1)
		buffer.writeu16(indices, ii + 4, base + 2)
		buffer.writeu16(indices, ii + 6, base)
		buffer.writeu16(indices, ii + 8, base + 2)
		buffer.writeu16(indices, ii + 10, base + 3)
		ii += 12
	end
	return {
		vertex = GPUBuffer.new({
			size = buffer.len(vertices),
			usage = "vertex",
			data = vertices,
			immutable = true,
		}),
		index = GPUBuffer.new({
			size = buffer.len(indices),
			usage = "index",
			data = indices,
			immutable = true,
		}),
		indexCount = 36,
	}
end

local function keyLightDir(self: Vehicle3D): (number, number, number)
	local ly = math.rad(lookVal(self, "lightYaw", 70))
	local lp = math.rad(lookVal(self, "lightPitch", 22))
	return math.cos(lp) * math.sin(ly), math.sin(lp), math.cos(lp) * math.cos(ly)
end

local function writeUniform(
	self: Vehicle3D,
	cpu: buffer,
	offset: number,
	mvp: Mat4,
	model: Mat4,
	r: number,
	g: number,
	b: number,
	eyeX: number,
	eyeY: number,
	eyeZ: number
)
	mvp:writeToBuffer(cpu, offset)
	model:writeToBuffer(cpu, offset + 64)
	buffer.writef32(cpu, offset + 128, r)
	buffer.writef32(cpu, offset + 132, g)
	buffer.writef32(cpu, offset + 136, b)
	buffer.writef32(cpu, offset + 140, 1)
	local lx, ly, lz = keyLightDir(self)
	buffer.writef32(cpu, offset + 144, lx)
	buffer.writef32(cpu, offset + 148, ly)
	buffer.writef32(cpu, offset + 152, lz)
	buffer.writef32(cpu, offset + 156, lookVal(self, "lightInt", 1))
	buffer.writef32(cpu, offset + 160, eyeX)
	buffer.writef32(cpu, offset + 164, eyeY)
	buffer.writef32(cpu, offset + 168, eyeZ)
	buffer.writef32(cpu, offset + 172, lookVal(self, "outlineSm", 0.82))
	buffer.writef32(cpu, offset + 176, lookVal(self, "outlineW", 3.8))
	buffer.writef32(cpu, offset + 180, lookVal(self, "specThr", 0.88))
	buffer.writef32(cpu, offset + 184, lookVal(self, "specAmt", 0.35))
	buffer.writef32(cpu, offset + 188, lookVal(self, "exposure", 0.68))
	buffer.writef32(cpu, offset + 192, lookVal(self, "wrap", 0.28))
	buffer.writef32(cpu, offset + 196, lookVal(self, "ambient", 0.24))
	buffer.writef32(cpu, offset + 200, lookVal(self, "rimAmt", 0.48))
	buffer.writef32(cpu, offset + 204, lookVal(self, "rimPow", 2.8))
	buffer.writef32(cpu, offset + 208, 1.0)
	buffer.writef32(cpu, offset + 212, 0.820)
	buffer.writef32(cpu, offset + 216, 0.580)
	buffer.writef32(cpu, offset + 220, lookVal(self, "bands", 3))
	buffer.writef32(cpu, offset + 224, 0.541)
	buffer.writef32(cpu, offset + 228, 0.588)
	buffer.writef32(cpu, offset + 232, 0.784)
	buffer.writef32(cpu, offset + 236, lookVal(self, "metal", 0.62))
	buffer.writef32(cpu, offset + 240, 0.957)
	buffer.writef32(cpu, offset + 244, 0.784)
	buffer.writef32(cpu, offset + 248, 0.588)
	buffer.writef32(cpu, offset + 252, lookVal(self, "fresnel", 0.32))
end

local function queueDraw(self: Vehicle3D, mesh: GpuMesh, model: Mat4, vp: Mat4, r: number, g: number, b: number)
	if self.drawCursor >= MAX_DRAWS then
		return
	end
	writeUniform(
		self,
		self.uboCpu,
		self.drawCursor * UNIFORM_STRIDE,
		vp * model,
		model,
		r,
		g,
		b,
		self.drawEyeX,
		self.drawEyeY,
		self.drawEyeZ
	)
	self.drawMeshes[self.drawCursor + 1] = mesh
	self.drawCursor += 1
end

local function writeShadowUniform(cpu: buffer, offset: number, mvp: Mat4, alpha: number)
	mvp:writeToBuffer(cpu, offset)
	buffer.writef32(cpu, offset + 64, 0.08)
	buffer.writef32(cpu, offset + 68, 0.09)
	buffer.writef32(cpu, offset + 72, 0.11)
	buffer.writef32(cpu, offset + 76, alpha)
end

local function _writePlanarUniform(
	self: Vehicle3D,
	cpu: buffer,
	offset: number,
	viewProj: Mat4,
	model: Mat4,
	planeY: number,
	alpha: number
)
	viewProj:writeToBuffer(cpu, offset)
	model:writeToBuffer(cpu, offset + 64)
	local lx, ly, lz = keyLightDir(self)
	buffer.writef32(cpu, offset + 128, lx)
	buffer.writef32(cpu, offset + 132, ly)
	buffer.writef32(cpu, offset + 136, lz)
	buffer.writef32(cpu, offset + 140, planeY)
	buffer.writef32(cpu, offset + 144, 0.07)
	buffer.writef32(cpu, offset + 148, 0.08)
	buffer.writef32(cpu, offset + 152, 0.1)
	buffer.writef32(cpu, offset + 156, alpha)
end

local function _queuePlanarShadow(_self: Vehicle3D, _mesh: GpuMesh, _model: Mat4, _vp: Mat4, _planeY: number, _alpha: number)
	-- unused: shadows are simple ground ellipses now
end

local function queueShadow(self: Vehicle3D, model: Mat4, vp: Mat4, alpha: number, mesh: GpuMesh?)
	if self.shadowCursor >= MAX_SHADOWS then
		return
	end
	writeShadowUniform(self.shadowCpu, self.shadowCursor * UNIFORM_STRIDE, vp * model, alpha)
	local m = mesh
	if m == nil then
		m = self.boxMesh
	end
	if m == nil then
		return
	end
	self.shadowMeshes[self.shadowCursor + 1] = m
	self.shadowCursor += 1
end

-- Soft blob under an object, cast slightly opposite the key light
local function queueContactShadow(
	self: Vehicle3D,
	vp: Mat4,
	x: number,
	y: number,
	z: number,
	halfX: number,
	halfZ: number,
	yaw: number,
	alpha: number
)
	local gh = groundHeight(x, z)
	local lift = y - gh
	local ldx, _, ldz = keyLightDir(self)
	local stretch = 1 + clamp(lift * 0.1, 0, 0.9)
	local ox = -ldx * lift * 0.45
	local oz = -ldz * lift * 0.45
	local disc = self.shadowDiscMesh
	local model = Mat4.fromTranslation(x + ox, gh + 0.028, z + oz)
		* Mat4.fromRotationY(yaw)
		* Mat4.fromScale(halfX * stretch, 1, halfZ * stretch)
	queueShadow(self, model, vp, alpha, disc)
end

local function chooseBestSamples(context: Context): number
	local want = MSAA_SAMPLES
	if want ~= 2 and want ~= 4 and want ~= 8 then
		return 1
	end
	local maxSamples = 1
	local ok, feats = pcall(function()
		return (context :: any):features()
	end)
	if ok and feats ~= nil then
		local n = (feats :: any).maxSamples
		if type(n) == "number" then
			maxSamples = n
		end
	end
	if want <= maxSamples then
		return want
	end
	if maxSamples >= 4 then
		return 4
	elseif maxSamples >= 2 then
		return 2
	end
	return 1
end

local function ensurePipeline(self: Vehicle3D): boolean
	local samples = self.samples
	if samples ~= 8 and samples ~= 4 and samples ~= 2 then
		samples = 1
		self.samples = 1
	end
	-- Rebuild pipelines if MSAA sample count changed
	if self.pipelineSamples ~= samples then
		self.pipeline = nil
		self.outlinePipeline = nil
		self.shadowPipeline = nil
		self.planarPipeline = nil
		self.groundPipeline = nil
		self.groundBind = nil
		self.bindGroups = {}
		self.shadowBindGroups = {}
		self.planarBindGroups = {}
		self.pipelineSamples = samples
	end

	if self.pipeline and self.outlinePipeline and self.shadowPipeline and self.planarPipeline and self.groundPipeline then
		return true
	end
	local shader = self.context:shader("lit")
	if shader == nil then
		print("missing lit.wgsl shader")
		return false
	end
	local ubo = self.ubo
	if ubo == nil then
		return false
	end
	local colorFmt = self.canvas.format
	if self.pipeline == nil then
		local pipeline = GPUPipeline.new({
			vertex = { module = shader, entryPoint = "vs_main" },
			fragment = { module = shader, entryPoint = "fs_main" },
			vertexLayout = {
				{
					stride = 24,
					attributes = {
						{ format = "float32x3", slot = 0, offset = 0 },
						{ format = "float32x3", slot = 1, offset = 12 },
					},
				},
			},
			colorTargets = { { format = colorFmt } },
			depthStencil = {
				format = "depth32float",
				compare = "less",
				write = true,
			},
			cullMode = "back",
			topology = "triangle-list",
			sampleCount = samples,
		})
		self.pipeline = pipeline
		local layout = pipeline:getBindGroupLayout(0)
		local groups: { GPUBindGroup } = {}
		for i = 0, MAX_DRAWS - 1 do
			table.insert(groups, GPUBindGroup.new({
				layout = layout,
				ubos = {
					{
						slot = 0,
						buffer = ubo,
						offset = i * UNIFORM_STRIDE,
						size = UNIFORM_STRIDE,
					},
				},
			}))
		end
		self.bindGroups = groups
	end

	if self.outlinePipeline == nil then
		self.outlinePipeline = GPUPipeline.new({
			vertex = { module = shader, entryPoint = "vs_outline" },
			fragment = { module = shader, entryPoint = "fs_outline" },
			vertexLayout = {
				{
					stride = 24,
					attributes = {
						{ format = "float32x3", slot = 0, offset = 0 },
						{ format = "float32x3", slot = 1, offset = 12 },
					},
				},
			},
			colorTargets = { { format = colorFmt } },
			depthStencil = {
				format = "depth32float",
				compare = "less-equal",
				write = true,
			},
			cullMode = "front",
			topology = "triangle-list",
			sampleCount = samples,
		})
	end

	if self.shadowPipeline == nil then
		local shadowShader = self.context:shader("shadow")
		if shadowShader == nil then
			print("missing shadow.wgsl shader")
			return false
		end
		local shadowUbo = self.shadowUbo
		if shadowUbo == nil then
			return false
		end
		local shadowPipeline = GPUPipeline.new({
			vertex = { module = shadowShader, entryPoint = "vs_main" },
			fragment = { module = shadowShader, entryPoint = "fs_main" },
			vertexLayout = {
				{
					stride = 24,
					attributes = {
						{ format = "float32x3", slot = 0, offset = 0 },
						{ format = "float32x3", slot = 1, offset = 12 },
					},
				},
			},
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
				compare = "less-equal",
				write = false,
			},
			cullMode = "none",
			topology = "triangle-list",
			sampleCount = samples,
		})
		self.shadowPipeline = shadowPipeline
		local layout = shadowPipeline:getBindGroupLayout(0)
		local groups: { GPUBindGroup } = {}
		for i = 0, MAX_SHADOWS - 1 do
			table.insert(groups, GPUBindGroup.new({
				layout = layout,
				ubos = {
					{
						slot = 0,
						buffer = shadowUbo,
						offset = i * UNIFORM_STRIDE,
						size = UNIFORM_STRIDE,
					},
				},
			}))
		end
		self.shadowBindGroups = groups
	end

	if self.planarPipeline == nil then
		local planarShader = self.context:shader("planar_shadow")
		if planarShader == nil then
			print("missing planar_shadow.wgsl shader")
			return false
		end
		local planarUbo = self.planarUbo
		if planarUbo == nil then
			return false
		end
		local planarPipeline = GPUPipeline.new({
			vertex = { module = planarShader, entryPoint = "vs_main" },
			fragment = { module = planarShader, entryPoint = "fs_main" },
			vertexLayout = {
				{
					stride = 24,
					attributes = {
						{ format = "float32x3", slot = 0, offset = 0 },
						{ format = "float32x3", slot = 1, offset = 12 },
					},
				},
			},
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
				compare = "less-equal",
				write = false,
			},
			cullMode = "none",
			topology = "triangle-list",
			sampleCount = samples,
		})
		self.planarPipeline = planarPipeline
		local layout = planarPipeline:getBindGroupLayout(0)
		local groups: { GPUBindGroup } = {}
		for i = 0, MAX_PLANAR - 1 do
			table.insert(groups, GPUBindGroup.new({
				layout = layout,
				ubos = {
					{
						slot = 0,
						buffer = planarUbo,
						offset = i * UNIFORM_STRIDE,
						size = UNIFORM_STRIDE,
					},
				},
			}))
		end
		self.planarBindGroups = groups
	end

	if self.groundPipeline == nil then
		local groundShader = self.context:shader("ground")
		if groundShader == nil then
			print("missing ground.wgsl shader")
			return false
		end
		local groundUbo = self.groundUbo
		if groundUbo == nil then
			groundUbo = GPUBuffer.new({
				size = 256,
				usage = "uniform",
			})
			self.groundUbo = groundUbo
		end
		local groundBuf = groundUbo :: GPUBuffer
		local groundPipeline = GPUPipeline.new({
			vertex = groundShader,
			fragment = groundShader,
			vertexLayout = {
				{
					stride = 24,
					attributes = {
						{ format = "float32x3", slot = 0, offset = 0 },
						{ format = "float32x3", slot = 1, offset = 12 },
					},
				},
			},
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
				write = true,
			},
			cullMode = "none",
			topology = "triangle-list",
			sampleCount = samples,
		})
		self.groundPipeline = groundPipeline
		self.groundBind = GPUBindGroup.new({
			layout = groundPipeline:getBindGroupLayout(0),
			ubos = { { slot = 0, buffer = groundBuf, offset = 0, size = 256 } },
		})
	end
	return true
end

local function writeGroundUniform(cpu: buffer, mvp: Mat4, model: Mat4, cell: number, majorEvery: number, fadeStart: number, fadeEnd: number)
	mvp:writeToBuffer(cpu, 0)
	model:writeToBuffer(cpu, 64)
	buffer.writef32(cpu, 128, cell)
	buffer.writef32(cpu, 132, majorEvery)
	buffer.writef32(cpu, 136, fadeStart)
	buffer.writef32(cpu, 140, fadeEnd)
	buffer.writef32(cpu, 144, 0)
	buffer.writef32(cpu, 148, 0)
	buffer.writef32(cpu, 152, 0)
	buffer.writef32(cpu, 156, 0)
end

local function ensureRenderTargets(self: Vehicle3D)
	local canvas = self.canvas
	if canvas.width <= 0 then
		return
	end
	local samples = self.samples
	if samples ~= 8 and samples ~= 4 and samples ~= 2 then
		samples = 1
		self.samples = 1
	end

	local depth = self.depth
	local msaa = self.msaaColor
	local sizedOk = depth ~= nil
		and depth.width == canvas.width
		and depth.height == canvas.height
		and self.targetSamples == samples
	if samples > 1 then
		sizedOk = sizedOk and msaa ~= nil and msaa.width == canvas.width and msaa.height == canvas.height
	end
	if sizedOk and self.depthView ~= nil then
		return
	end

	local function build(sampleCount: number): boolean
		self.msaaColor = nil
		if sampleCount > 1 then
			local okM, msaaTex = pcall(function()
				return GPUTexture.new({
					width = canvas.width,
					height = canvas.height,
					format = canvas.format,
					renderTarget = true,
					sampleCount = sampleCount,
					label = "vehicle-msaa",
				})
			end)
			if not okM or msaaTex == nil then
				return false
			end
			self.msaaColor = msaaTex
		end
		local okD, depthTex = pcall(function()
			return GPUTexture.new({
				width = canvas.width,
				height = canvas.height,
				format = "depth32float",
				renderTarget = true,
				sampleCount = sampleCount,
				label = "vehicle-depth",
			})
		end)
		if not okD or depthTex == nil then
			self.msaaColor = nil
			return false
		end
		self.depth = depthTex
		-- Match main.luau: plain view() is more stable with MSAA than depth-only
		self.depthView = depthTex:view()
		self.targetSamples = sampleCount
		return self.depthView ~= nil
	end

	if not build(samples) then
		if samples > 1 then
			print(string.format("msaa %dx targets failed — falling back to 1x", samples))
			self.samples = 1
			self.pipelineSamples = -1 -- force pipeline rebuild
			if not build(1) then
				print("depth target failed")
				self.depth = nil
				self.depthView = nil
				self.msaaColor = nil
				self.targetSamples = 0
			end
		else
			print("depth target failed")
			self.depth = nil
			self.depthView = nil
			self.targetSamples = 0
		end
	end
end

-- Car OBB (XZ) vs crate (circle approx), impulse push + spin.
local function resolveCarCrates(self: Vehicle3D, dt: number)
	local cosY = math.cos(self.yaw)
	local sinY = math.sin(self.yaw)
	local forwardX, forwardZ = cosY, -sinY
	local rightX, rightZ = sinY, cosY
	local carY = self.y + CHASSIS_OY
	local carHy = CHASSIS_HY + 0.35

	for _, box in self.crates do
		-- Skip if vertically separated
		if math.abs(box.y - carY) > box.hy + carHy then
			continue
		end
		local dx = box.x - self.x
		local dz = box.z - self.z
		local lx = dx * forwardX + dz * forwardZ
		local lz = dx * rightX + dz * rightZ
		local nearestX = clamp(lx, -CHASSIS_HX, CHASSIS_HX)
		local nearestZ = clamp(lz, -CHASSIS_HZ, CHASSIS_HZ)
		local ox = lx - nearestX
		local oz = lz - nearestZ
		local dist = math.sqrt(ox * ox + oz * oz)
		local hitR = math.sqrt(box.hx * box.hx + box.hz * box.hz) * 0.92
		if dist < hitR and dist > 1e-4 then
			local nxL = ox / dist
			local nzL = oz / dist
			local nx = nxL * forwardX + nzL * rightX
			local nz = nxL * forwardZ + nzL * rightZ
			local pen = hitR - dist
			-- Separate: mostly move the crate, nudge the car a little
			local boxShare = 0.78
			box.x += nx * pen * boxShare
			box.z += nz * pen * boxShare
			self.x -= nx * pen * (1 - boxShare)
			self.z -= nz * pen * (1 - boxShare)

			local relVx = self.vx - box.vx
			local relVz = self.vz - box.vz
			local closing = relVx * nx + relVz * nz
			if closing > 0 then
				-- Car is moving into the crate
				local invMass = 1 / CAR_MASS + 1 / box.mass
				local j = closing * 1.35 / invMass
				local jCar = j / CAR_MASS
				local jBox = j / box.mass
				self.vx -= nx * jCar * 0.55
				self.vz -= nz * jCar * 0.55
				box.vx += nx * jBox
				box.vz += nz * jBox
				-- Torque on crate from off-center hit
				local rx = box.x - self.x
				local rz = box.z - self.z
				box.yawVel += (rx * (nz * jBox) - rz * (nx * jBox)) * 0.35
				if closing > 3.5 and self.raceStarted then
					local hit = clamp(closing * 0.06, 0.12, 0.7)
					addShake(self, hit)
					self.whiteFlash = math.max(self.whiteFlash, hit * 0.55)
					spawnJuice(self, box.x, box.y + box.hy, box.z, 5, 4 + closing * 0.35, 0.35, 0.35, 255, 200, 90)
				end
			end
		end
	end
end

-- Solid under-ramp + tip wall. Skip when the car is riding ON the plank top.
local function resolveCarRampBlocks(self: Vehicle3D)
	local carY = self.y + CHASSIS_OY
	local carHy = CHASSIS_HY + 0.3
	local carHx = CHASSIS_HX + 0.12
	local carHz = CHASSIS_HZ + 0.12
	local cosY = math.cos(self.yaw)
	local sinY = math.sin(self.yaw)
	local carBottom = carY - carHy
	local surfaceHere = groundHeight(self.x, self.z)
	-- Sample near tip: if chassis is at/above deck height, allow hang-over (real car tip)
	local tipDeck = RAMP_HEIGHT + CONTACT_EPS
	local hangingOverTip = self.x > RAMP_X1 - 0.8 and carBottom > tipDeck - 0.85

	for _, box in self.rampBlocks do
		local boxTop = box.y + box.hy
		local isTipWall = box.x > RAMP_X1
		-- On the plank top — wheels/suspension handle it
		if surfaceHere > 0.02 and carBottom >= surfaceHere - 0.65 then
			continue
		end
		-- Hanging past the lip at deck height: do NOT shove (lets the car snag / tip / launch)
		if isTipWall and hangingOverTip then
			continue
		end
		if carBottom >= boxTop - 0.25 then
			continue
		end
		if math.abs(box.y - carY) > box.hy + carHy then
			continue
		end
		local dx = self.x - box.x
		local dz = self.z - box.z
		local extX = math.abs(cosY) * carHx + math.abs(sinY) * carHz
		local extZ = math.abs(sinY) * carHx + math.abs(cosY) * carHz
		local overlapX = box.hx + extX - math.abs(dx)
		local overlapZ = box.hz + extZ - math.abs(dz)
		if overlapX > 0 and overlapZ > 0 then
			if overlapX < overlapZ * 1.35 then
				local sx = if dx >= 0 then 1 else -1
				if self.x > (RAMP_X0 + RAMP_X1) * 0.5 and dx < 0 then
					sx = -1
				end
				self.x += sx * overlapX
				if (sx > 0 and self.vx < 0) or (sx < 0 and self.vx > 0) then
					self.vx *= -0.35
				else
					self.vx *= 0.35
				end
			else
				local sz = if dz >= 0 then 1 else -1
				self.z += sz * overlapZ
				if (sz > 0 and self.vz < 0) or (sz < 0 and self.vz > 0) then
					self.vz *= -0.35
				else
					self.vz *= 0.35
				end
			end
		end
	end
end

local function resolveCrateCrates(self: Vehicle3D)
	local crates = self.crates
	for i = 1, #crates do
		local a = crates[i]
		for j = i + 1, #crates do
			local b = crates[j]
			if math.abs(a.y - b.y) > a.hy + b.hy then
				continue
			end
			local dx = b.x - a.x
			local dz = b.z - a.z
			local dist = math.sqrt(dx * dx + dz * dz)
			local minDist = (math.sqrt(a.hx * a.hx + a.hz * a.hz) + math.sqrt(b.hx * b.hx + b.hz * b.hz)) * 0.85
			if dist < minDist and dist > 1e-4 then
				local nx = dx / dist
				local nz = dz / dist
				local pen = minDist - dist
				local inv = 1 / a.mass + 1 / b.mass
				a.x -= nx * pen * (1 / a.mass) / inv
				a.z -= nz * pen * (1 / a.mass) / inv
				b.x += nx * pen * (1 / b.mass) / inv
				b.z += nz * pen * (1 / b.mass) / inv
				local rel = (a.vx - b.vx) * nx + (a.vz - b.vz) * nz
				if rel > 0 then
					local impulse = rel * 0.9 / inv
					a.vx -= nx * impulse / a.mass
					a.vz -= nz * impulse / a.mass
					b.vx += nx * impulse / b.mass
					b.vz += nz * impulse / b.mass
				end
			end
		end
	end
end

local function stepCrates(self: Vehicle3D, dt: number)
	for _, box in self.crates do
		box.vy -= GRAVITY * dt
		box.x += box.vx * dt
		box.y += box.vy * dt
		box.z += box.vz * dt
		box.yaw += box.yawVel * dt
		-- Ground (flat or ramp)
		local ground = box.hy + groundHeight(box.x, box.z)
		if box.y < ground then
			box.y = ground
			if box.vy < 0 then
				box.vy = 0
			end
			-- Slide friction on ground
			box.vx *= math.exp(-BOX_FRICTION * dt)
			box.vz *= math.exp(-BOX_FRICTION * dt)
			box.yawVel *= math.exp(-BOX_ANG_DAMP * dt)
		end
		-- Soft speed clamp so crates don't fly forever
		local spd = math.sqrt(box.vx * box.vx + box.vz * box.vz)
		if spd > 22 then
			box.vx *= 22 / spd
			box.vz *= 22 / spd
		end
	end
	resolveCrateCrates(self)
end

function init(self: Vehicle3D, context: Context): boolean
	print("3D vehicle — W/S gas, A/D steer, Shift NOS, Space drift · B debug · T tune · C iso · naik ramp dari BAWAH (+X)")
	print(
		string.format(
			"sizes: chassis %.2fx%.2fx%.2f  body %.2fx%.2fx%.2f  cabin %.2fx%.2fx%.2f  wheel r=%.2f track=%.2f base=%.2f",
			CHASSIS_HX * 2,
			CHASSIS_HY * 2,
			CHASSIS_HZ * 2,
			BODY_HX * 2,
			BODY_HY * 2,
			BODY_HZ * 2,
			CABIN_HX * 2,
			CABIN_HY * 2,
			CABIN_HZ * 2,
			WHEEL_RADIUS,
			WHEEL_OZ * 2,
			WHEEL_OX * 2
		)
	)
	self.context = context
	self.samples = chooseBestSamples(context)
	self.pipelineSamples = 0
	self.targetSamples = 0
	self.msaaColor = nil
	if self.samples > 1 then
		print(string.format("antialias MSAA %dx (MSAA_SAMPLES in vehicle.luau)", self.samples))
	else
		print("antialias OFF — set MSAA_SAMPLES=2 or 4 near top of vehicle.luau")
	end
	self.ubo = GPUBuffer.new({
		size = MAX_DRAWS * UNIFORM_STRIDE,
		usage = "uniform",
	})
	self.shadowUbo = GPUBuffer.new({
		size = MAX_SHADOWS * UNIFORM_STRIDE,
		usage = "uniform",
	})
	self.planarUbo = GPUBuffer.new({
		size = MAX_PLANAR * UNIFORM_STRIDE,
		usage = "uniform",
	})
	self.boxMesh = makeBoxMesh()
	self.shadowDiscMesh = makeShadowDiscMesh(28)
	self.crates = spawnCrates()
	self.rampBlocks = buildRampBlocks()
	print(string.format("spawned %d pushable crates · ramp + solid underfill", #self.crates))
	-- ban.glb cylinder axle is +Y; rotate so axle aligns with vehicle local Z (spin axis)
	self.wheelMeshOrient = Mat4.fromRotationX(math.pi * 0.5)
	self.wheelMeshRadius = 1
	self.wheelParts = {}
	local blob = context:blob("ban")
	if blob then
		local loaded = wheel_glb.load(blob.data)
		self.wheelMeshRadius = loaded.radius
		for _, part in loaded.parts do
			table.insert(self.wheelParts, {
				mesh = {
					vertex = GPUBuffer.new({
						size = buffer.len(part.vertices),
						usage = "vertex",
						data = part.vertices,
						immutable = true,
					}),
					index = GPUBuffer.new({
						size = buffer.len(part.indices),
						usage = "index",
						data = part.indices,
						immutable = true,
					}),
					indexCount = part.indexCount,
				},
				r = part.r,
				g = part.g,
				b = part.b,
			})
		end
		print(string.format("using ban.glb wheels (%d parts), meshRadius=%.3f", #self.wheelParts, self.wheelMeshRadius))
	else
		print("ban.glb blob missing — wheels fall back to boxes")
	end

	-- Upper body from mobil.glb (replaces box body + cabin)
	self.bodyParts = {}
	self.bodyMeshSizeX = 1
	self.bodyMeshSizeY = 1
	self.bodyMeshSizeZ = 1
	-- GLB often Y-up / -Z forward → rotate so +X is forward like the vehicle
	self.bodyMeshOrient = Mat4.fromRotationY(-math.pi * 0.5)
	self.bodyMeshScale = 1
	self.bodyMeshLift = BODY_OY
	local bodyBlob = context:blob("mobil")
	if bodyBlob then
		local loaded = wheel_glb.load(bodyBlob.data)
		self.bodyMeshSizeX = loaded.sizeX
		self.bodyMeshSizeY = loaded.sizeY
		self.bodyMeshSizeZ = loaded.sizeZ
		-- After Ry(-90): mesh Z → car length (X), mesh X → car width (Z)
			local targetLen = CHASSIS_HX * 2.35
			local targetWid = CHASSIS_HZ * 2.2
			local sLen = targetLen / math.max(loaded.sizeZ, 0.01)
			local sWid = targetWid / math.max(loaded.sizeX, 0.01)
			self.bodyMeshScale = math.min(sLen, sWid)
			local halfH = loaded.sizeY * 0.5 * self.bodyMeshScale
			-- Slightly lower so body sits into the wheel wells
			self.bodyMeshLift = (CHASSIS_OY + CHASSIS_HY * 0.35) + halfH * 0.85
		for _, part in loaded.parts do
			table.insert(self.bodyParts, {
				mesh = {
					vertex = GPUBuffer.new({
						size = buffer.len(part.vertices),
						usage = "vertex",
						data = part.vertices,
						immutable = true,
					}),
					index = GPUBuffer.new({
						size = buffer.len(part.indices),
						usage = "index",
						data = part.indices,
						immutable = true,
					}),
					indexCount = part.indexCount,
				},
				r = part.r,
				g = part.g,
				b = part.b,
			})
		end
		print(
			string.format(
				"using mobil.glb body (%d parts) size=%.2fx%.2fx%.2f scale=%.3f lift=%.3f",
				#self.bodyParts,
				loaded.sizeX,
				loaded.sizeY,
				loaded.sizeZ,
				self.bodyMeshScale,
				self.bodyMeshLift
			)
		)
	else
		print("mobil.glb blob missing — body falls back to boxes")
	end
	self.x = 0
	self.y = WHEEL_RADIUS + CONTACT_EPS + SUSP_REST
	self.z = 0
	self.yaw = 0
	self.vx = 0
	self.vy = 0
	self.vz = 0
	self.localSpeed = 0
	self.steerAngle = 0
	self.bodyPitch = 0
	self.bodyPitchVel = 0
	self.bodyRoll = 0
	self.bodyRollVel = 0
	self.bodySquash = 1
	self.camShake = 0
	self.fovKick = 0
	self.squashPunch = 0
	self.whiteFlash = 0
	self.prevBoost = 0
	self.airTime = 0
	self.juiceEmit = 0
	self.juiceParticles = {}
	self.showDebug = false
	self.paused = false
	self.showTune = false
	self.showLook = false
	self.tune = makeTune()
	self.look = makeLook()
	self.tuneDrag = 0
	self.lookDrag = 0
	self.wasOnRamp = false
	self.launched = false
	self.camOffset = v3(10, 8, 12)
	self.camLookOffset = v3(0, 0.5, 0)
	self.camIso = false
	self.camOrthoSize = 14
	self.raceStarted = false
	self.camBlend = 0
	self.camIntroAngle = 0
	print("HOME CAM — press ENTER / START or W to race")
	-- ox > 0 = front (X forward)
	self.wheels = {
		{ ox = WHEEL_OX, oz = WHEEL_OZ, radius = WHEEL_RADIUS, suspension = SUSP_REST, suspensionVel = 0, inContact = true, spin = 0, isFront = true, wx = 0, wz = 0, groundY = 0, hubY = WHEEL_RADIUS },
		{ ox = WHEEL_OX, oz = -WHEEL_OZ, radius = WHEEL_RADIUS, suspension = SUSP_REST, suspensionVel = 0, inContact = true, spin = 0, isFront = true, wx = 0, wz = 0, groundY = 0, hubY = WHEEL_RADIUS },
		{ ox = -WHEEL_OX, oz = WHEEL_OZ, radius = WHEEL_RADIUS, suspension = SUSP_REST, suspensionVel = 0, inContact = true, spin = 0, isFront = false, wx = 0, wz = 0, groundY = 0, hubY = WHEEL_RADIUS },
		{ ox = -WHEEL_OX, oz = -WHEEL_OZ, radius = WHEEL_RADIUS, suspension = SUSP_REST, suspensionVel = 0, inContact = true, spin = 0, isFront = false, wx = 0, wz = 0, groundY = 0, hubY = WHEEL_RADIUS },
	}
	return true
end

function resize(self: Vehicle3D, size: Vector, scale: number?)
	self.size = size
	local s = 1
	if type(scale) == "number" and scale == scale and scale > 0 then
		s = scale
	end
	self.scale = s
	local w = math.max(1, math.floor(size.x * self.scale))
	local h = math.max(1, math.floor(size.y * self.scale))
	self.canvas:resize(w, h)
	self.depth = nil
	self.depthView = nil
	self.msaaColor = nil
	self.targetSamples = 0
end

function keyboardEvent(self: Vehicle3D, event: KeyboardEvent): boolean
	local down = event.phase ~= "up"
	local key = event.key

	if key == KEY.W or key == KEY.UP then
		self.keysW = down
		return true
	elseif key == KEY.S or key == KEY.DOWN then
		self.keysS = down
		return true
	elseif key == KEY.A or key == KEY.LEFT then
		self.keysA = down
		return true
	elseif key == KEY.D or key == KEY.RIGHT then
		self.keysD = down
		return true
	elseif key == KEY.SHIFT_L or key == KEY.SHIFT_R then
		self.boost = if down then 1 else 0
		return true
	elseif key == KEY.SPACE then
		self.drift = if down then 1 else 0
		return true
	elseif key == KEY.B then
		if down then
			self.showDebug = not self.showDebug
			print(if self.showDebug then "contact guides ON" else "contact guides OFF")
		end
		return true
	elseif key == KEY.T then
		if down then
			self.showTune = not self.showTune
			self.tuneDrag = 0
			if self.showTune then
				self.showLook = false
				self.lookDrag = 0
				printTuneLegend(self)
			else
				print("tune panel OFF")
			end
		end
		return true
	elseif key == KEY.O then
		if down then
			toggleLook(self)
		end
		return true
	elseif key == KEY.C then
		if down then
			toggleCamIso(self)
		end
		return true
	elseif key == KEY.P then
		if down then
			togglePause(self)
		end
		return true
	elseif key == KEY.ENTER then
		if down then
			startRace(self)
		end
		return true
	elseif key == KEY.R then
		if down then
			restartRace(self)
		end
		return true
	end

	return false
end

function pointerDown(self: Vehicle3D, event: PointerEvent)
	local px = event.position.x
	local py = event.position.y
	if startTabHit(self, px, py) then
		startRace(self)
		event:hit()
		return
	end
	if restartTabHit(self, px, py) then
		restartRace(self)
		event:hit()
		return
	end
	if isoTabHit(self, px, py) then
		toggleCamIso(self)
		event:hit()
		return
	end
	if pauseTabHit(self, px, py) then
		togglePause(self)
		event:hit()
		return
	end
	if lookTabHit(self, px, py) then
		toggleLook(self)
		event:hit()
		return
	end
	if tuneTabHit(self, px, py) then
		self.showTune = not self.showTune
		self.tuneDrag = 0
		if self.showTune then
			self.showLook = false
			self.lookDrag = 0
			printTuneLegend(self)
		else
			print("tune panel OFF")
		end
		event:hit()
		return
	end
	local lookIdx = lookHitIndex(self, px, py)
	if lookIdx > 0 then
		self.lookDrag = lookIdx
		setLookFromX(self, lookIdx, px)
		event:hit()
		return
	end
	local idx = tuneHitIndex(self, px, py)
	if idx > 0 then
		self.tuneDrag = idx
		setTuneFromX(self, idx, px)
		event:hit()
	end
end

function pointerMove(self: Vehicle3D, event: PointerEvent)
	if self.lookDrag > 0 then
		setLookFromX(self, self.lookDrag, event.position.x)
		event:hit()
		return
	end
	if self.tuneDrag > 0 then
		setTuneFromX(self, self.tuneDrag, event.position.x)
		event:hit()
	end
end

function pointerUp(self: Vehicle3D, event: PointerEvent)
	if self.lookDrag > 0 then
		self.lookDrag = 0
		event:hit()
		return
	end
	if self.tuneDrag > 0 then
		self.tuneDrag = 0
		event:hit()
	end
end

function pointerExit(self: Vehicle3D, _event: PointerEvent)
	self.tuneDrag = 0
	self.lookDrag = 0
end

function advance(self: Vehicle3D, seconds: number): boolean
	local dt = math.min(seconds, 1 / 30)

	-- Debug pause: freeze sim (physics + intro orbit), still draw
	if self.paused then
		self.gas = 0
		self.steer = 0
		return true
	end

	-- Intro timer (START pulse) + blend toward gameplay cam
	self.camIntroAngle += dt
	if not self.raceStarted then
		self.camBlend = 0
	else
		self.camBlend = math.min(1, self.camBlend + dt / 1.15)
	end

	self.gas = 0
	self.steer = 0
	-- Lock driving until race starts (showcase pose)
	if self.raceStarted then
		if self.keysW then
			self.gas += 1
		end
		if self.keysS then
			self.gas -= 1
		end
		if self.keysA then
			self.steer += 1
		end
		if self.keysD then
			self.steer -= 1
		end
	elseif self.keysW then
		-- Gas also starts the race (like arcade racers)
		startRace(self)
	end

	if not self.raceStarted then
		self.gas = 0
		self.steer = 0
		self.boost = 0
		self.drift = 0
		self.vx = 0
		self.vz = 0
		self.vy = 0
	end

	-- Local axes from yaw (X = forward, Z = right)
	local cosY = math.cos(self.yaw)
	local sinY = math.sin(self.yaw)
	local forwardX = cosY
	local forwardZ = -sinY
	local rightX = sinY
	local rightZ = cosY

	local topSpeed = if self.boost > 0 then TOP_SPEED_BOOST else TOP_SPEED
	local speed = math.sqrt(self.vx * self.vx + self.vz * self.vz)
	local overflow = math.max(0, speed - topSpeed)
	-- Split early so launch torque uses current forward speed
	local forwardSpeed = self.vx * forwardX + self.vz * forwardZ
	local lateralSpeed = self.vx * rightX + self.vz * rightZ
	-- Low-gear punch: slam throttle from standstill ("jengat")
	local launch = 1 + ENGINE_LAUNCH * (1 - clamp(math.abs(forwardSpeed) / 7, 0, 1))
	local engine = self.gas * ENGINE * launch * (1 + self.boost * (BOOST_MULT - 1)) / (1 + overflow * 0.06)

	local contactCount = 0
	for i = 1, #self.wheels do
		if self.wheels[i].inContact then
			contactCount += 1
		end
	end
	local contactRatio = contactCount / 4

	-- Front wheels angle (visual + turn rate)
	local targetSteer = self.steer * STEER_MAX
	self.steerAngle += (targetSteer - self.steerAngle) * math.min(1, STEER_LERP * dt)

	-- Engine + long drag along facing; kill sideways slip (grip), unless drifting
	-- Front axle bias: planted nose gets FRONT_GRIP multiplier (turn bite + stick)
	local frontPlant = 0
	for i = 1, #self.wheels do
		local wh = self.wheels[i]
		if wh.isFront and wh.inContact then
			frontPlant += 1
		end
	end
	local frontBias = if self.drift > 0 then 1 else (1 + (FRONT_GRIP - 1) * (frontPlant / 2))
	local grip = (if self.drift > 0 then LATERAL_GRIP_DRIFT else LATERAL_GRIP) * frontBias
	local longDrag = if self.drift > 0 then DRIFT_DRAG else DRAG
	forwardSpeed += engine * contactRatio * dt
	forwardSpeed *= math.exp(-longDrag * dt)
	lateralSpeed *= math.exp(-grip * contactRatio * dt)

	self.vx = forwardX * forwardSpeed + rightX * lateralSpeed
	self.vz = forwardZ * forwardSpeed + rightZ * lateralSpeed

	-- Yaw from front steer, pivoted on the REAR axle (not chassis midpoint).
	-- Long wheelbase → slower turn rate (bicycle model ≈ v*tan(δ)/L).
	local steerMult = if self.drift > 0 then DRIFT_STEER_MULT else 1
	local speedSteer = clamp(1.05 - math.abs(forwardSpeed) / math.max(topSpeed, 1) * 0.35, 0.55, 1)
	local rollFactor = clamp(math.abs(forwardSpeed) / 1.6, 0, 1)
	local gripContact = math.max(contactRatio, if self.launched then 0 else 0.65)
	local wheelbase = math.max(WHEEL_OX * 2, 0.5)
	local baseScale = 2.3 / wheelbase -- default JARAK was 2.3
	local steerAmount = self.steerAngle * STEER_SPEED * FRONT_GRIP * steerMult * speedSteer * rollFactor * gripContact * baseScale
	if self.drift > 0 then
		steerAmount += self.steer * 1.8 * clamp(math.abs(forwardSpeed) / 5, 0.2, 1) * gripContact * self.drift
	end
	if forwardSpeed < 0 then
		steerAmount = -steerAmount
	end
	local dYaw = steerAmount * dt
	if dYaw ~= 0 then
		-- Rear axle world position (ox = -WHEEL_OX)
		local pivotX = self.x - cosY * WHEEL_OX
		local pivotZ = self.z + sinY * WHEEL_OX
		local relX = self.x - pivotX
		local relZ = self.z - pivotZ
		local c = math.cos(dYaw)
		local s = math.sin(dYaw)
		-- Orbit chassis center around rear axle
		self.x = pivotX + (relX * c + relZ * s)
		self.z = pivotZ + (-relX * s + relZ * c)

		local nx = self.vx * c + self.vz * s
		local nz = -self.vx * s + self.vz * c
		if self.drift > 0 then
			-- Drift: slip allowed; pivot softens toward mid so the rear can swing out
			local slide = 0.5
			self.vx = self.vx * slide + nx * (1 - slide)
			self.vz = self.vz * slide + nz * (1 - slide)
		else
			self.vx = nx
			self.vz = nz
		end
		self.yaw += dYaw
	end

	cosY = math.cos(self.yaw)
	sinY = math.sin(self.yaw)
	forwardX = cosY
	forwardZ = -sinY
	rightX = sinY
	rightZ = cosY

	-- Scrub remaining lateral slip hard when not drifting
	forwardSpeed = self.vx * forwardX + self.vz * forwardZ
	lateralSpeed = self.vx * rightX + self.vz * rightZ
	local scrub = if self.drift > 0 then grip * 0.45 else grip * 1.15
	lateralSpeed *= math.exp(-scrub * gripContact * dt)
	self.vx = forwardX * forwardSpeed + rightX * lateralSpeed
	self.vz = forwardZ * forwardSpeed + rightZ * lateralSpeed

	-- Gravity + 4-wheel spring suspension (real car: climb continuous, hang/tip at lips).
	self.vy -= GRAVITY * dt
	local cosW = math.cos(self.yaw)
	local sinW = math.sin(self.yaw)
	local sinP = math.sin(self.bodyPitch)
	local cosP = math.cos(self.bodyPitch)
	local sinR = math.sin(self.bodyRoll)
	local cosR = math.cos(self.bodyRoll)

	-- Gravity pulls DOWN the ramp when planted (car-like, not glued hover)
	local slopeHere = groundSlope(self.x, self.z)
	if contactRatio > 0.25 and slopeHere ~= 0 and not self.launched then
		local along = slopeHere / math.sqrt(1 + slopeHere * slopeHere)
		self.vx -= along * GRAVITY * 0.55 * contactRatio * dt
	end

	self.x += self.vx * dt
	self.z += self.vz * dt
	resolveCarRampBlocks(self)

	-- Sample each wheel contact. Continuous slopes always plant; only reject cliff walls.
	local onRampNow = false
	local plant = { 0.0, 0.0, 0.0, 0.0 }
	local plantOk = { false, false, false, false }
	local frontOn = false
	local rearOn = false
	for i = 1, #self.wheels do
		local w = self.wheels[i]
		local wx = self.x + cosW * w.ox + sinW * w.oz
		local wz = self.z + -sinW * w.ox + cosW * w.oz
		local gh = groundHeight(wx, wz)
		w.wx = wx
		w.wz = wz
		w.groundY = gh
		if gh > 0.02 then
			onRampNow = true
		end
		local plantHubY = gh + w.radius + CONTACT_EPS
		plant[i] = plantHubY

		local mountY = self.y + w.ox * sinP - w.oz * sinR
		local length = mountY - plantHubY
		-- Reachable if within suspension travel (generous) OR gentle climb from last hub
		local climbOk = plantHubY <= w.hubY + MAX_STEP_UP
		local reachOk = length <= SUSP_MAX + 0.55
		-- Bottom-out: surface above mount still counts — spring will shove chassis up
		local ok = climbOk and (reachOk or plantHubY > mountY - SUSP_MIN)
		-- Far below (air after tip): don't magically stick to ground under cliff
		if self.launched and plantHubY < self.y - SUSP_MAX - 1.2 then
			ok = false
		end
		plantOk[i] = ok
		if ok and gh > 0.02 then
			if w.isFront then
				frontOn = true
			else
				rearOn = true
			end
		end
	end
	self.wasOnRamp = onRampNow

	-- Natural tip: front left the plank while rear still on it — no forced launch impulse
	local frontX = self.x + cosW * WHEEL_OX
	local frontGh = groundHeight(frontX, self.z + -sinW * WHEEL_OX)
	if not self.launched and rearOn and not frontOn and frontX > RAMP_X1 - 0.05 and frontGh <= 0.01 then
		self.launched = true
		-- Keep along-slope vertical speed so a fast run flies; slow run just hangs
		local keepUp = math.max(forwardSpeed, 0) * slopeHere * 0.85
		if keepUp > 0.5 then
			self.vy = math.max(self.vy, keepUp)
		end
	end

	local forceY = 0.0
	local torquePitch = 0.0
	local torqueRoll = 0.0
	local springsHit = 0
	local floorY = -1e9
	local avgSlope = 0.0
	for i = 1, #self.wheels do
		local w = self.wheels[i]
		local plantHubY = plant[i]
		local mountY = self.y + w.ox * sinP - w.oz * sinR
		local mountVy = self.vy + w.ox * cosP * self.bodyPitchVel - w.oz * cosR * self.bodyRollVel
		local length = mountY - plantHubY
		if plantOk[i] and length <= SUSP_MAX + 0.55 then
			local useLen = clamp(length, SUSP_MIN * 0.35, SUSP_MAX)
			local compress = SUSP_REST - useLen
			local f = SUSP_STIFF * compress - SUSP_DAMP * mountVy
			if length < SUSP_MIN then
				-- Bottom-out: hard shove up the chassis (this is how you climb)
				f += (SUSP_MIN - length) * SUSP_STIFF * 8
			end
			forceY += f
			torquePitch += f * w.ox
			torqueRoll += -f * w.oz
			w.inContact = true
			w.hubY = plantHubY
			w.suspension = clamp(length, SUSP_MIN, SUSP_MAX)
			springsHit += 1
			avgSlope += groundSlope(w.wx, w.wz)
			local thisFloor = plantHubY + SUSP_MIN
			if thisFloor > floorY then
				floorY = thisFloor
			end
		else
			w.inContact = false
			w.hubY = mountY - SUSP_MAX
			w.suspension = SUSP_MAX
		end
		w.spin -= forwardSpeed / math.max(w.radius, 0.1) * dt
	end
	if springsHit > 0 then
		avgSlope /= springsHit
	end

	self.vy += (forceY / CAR_MASS) * dt
	-- Stick to the road: blend vertical speed toward slope-following when planted
	if springsHit >= 2 and not self.launched and math.abs(avgSlope) > 0.02 then
		local followVy = forwardSpeed * avgSlope
		self.vy = self.vy * 0.35 + followVy * 0.65
	end
	if self.vy < -20 then
		self.vy = -20
	end
	if self.vy > 22 then
		self.vy = 22
	end

	self.bodyPitchVel += (torquePitch / PITCH_INERTIA) * dt
	self.bodyRollVel += (torqueRoll / ROLL_INERTIA) * dt
	self.bodyPitchVel *= math.exp(-ANG_DAMP * dt)
	self.bodyRollVel *= math.exp(-ANG_DAMP * dt)

	self.y += self.vy * dt
	self.bodyPitch += self.bodyPitchVel * dt
	self.bodyRoll += self.bodyRollVel * dt

	-- Align body pitch toward contact plane (front vs rear hubs) — car sits ON the road
	if springsHit >= 2 then
		local fHub, rHub, fN, rN = 0.0, 0.0, 0, 0
		for i = 1, #self.wheels do
			local w = self.wheels[i]
			if w.inContact then
				if w.isFront then
					fHub += w.hubY
					fN += 1
				else
					rHub += w.hubY
					rN += 1
				end
			end
		end
		if fN > 0 and rN > 0 then
			local terrainPitch = math.atan2((fHub / fN) - (rHub / rN), WHEEL_OX * 2)
			self.bodyPitch += (terrainPitch - self.bodyPitch) * math.min(1, 10 * dt)
		end
	end

	self.bodyPitch = clamp(self.bodyPitch, -0.95, 0.95)
	self.bodyRoll = clamp(self.bodyRoll, -0.6, 0.6)

	if springsHit > 0 and self.y < floorY then
		self.y = floorY
		if self.vy < 0 then
			self.vy = 0
		end
	end

	if self.launched then
		self.airTime += dt
	end

	if self.launched and springsHit >= 3 and self.vy <= 1.5 then
		local impact = math.max(-self.vy, 2 + self.airTime * 3)
		addShake(self, clamp(impact * 0.05, 0.18, 0.9))
		self.squashPunch = math.max(self.squashPunch, clamp(0.14 + impact * 0.015, 0.14, 0.32))
		self.whiteFlash = math.max(self.whiteFlash, clamp(impact * 0.03, 0.08, 0.35))
		for i = 1, 4 do
			local w = self.wheels[i]
			spawnJuice(self, w.wx, w.hubY - w.radius * 0.2, w.wz, 4, 3.5, 0.4, 0.4, 200, 190, 160)
		end
		self.launched = false
		self.airTime = 0
	end

	if self.y < -2 then
		self.y = SUSP_REST + WHEEL_RADIUS
		self.vy = 0
		self.launched = false
		self.airTime = 0
	end

	sinP = math.sin(self.bodyPitch)
	sinR = math.sin(self.bodyRoll)
	for i = 1, #self.wheels do
		local w = self.wheels[i]
		local mountY = self.y + w.ox * sinP - w.oz * sinR
		if w.inContact and plantOk[i] then
			w.hubY = plant[i]
			w.suspension = clamp(mountY - plant[i], SUSP_MIN, SUSP_MAX)
		else
			w.inContact = false
			w.hubY = mountY - SUSP_MAX
			w.suspension = SUSP_MAX
		end
	end

	resolveCarCrates(self, dt)
	stepCrates(self, dt)

	-- Extra lean from throttle / steering (weight transfer)
	local localFwd = self.vx * forwardX + self.vz * forwardZ
	local localRight = self.vx * rightX + self.vz * rightZ
	local localAx = (localFwd - self.localSpeed) / math.max(dt, 1e-4)
	self.localSpeed = localFwd
	local localAz = localRight

	local extraPitch = clamp(
		localAx * 0.008 + self.gas * LEAN_PITCH_EXTRA * (1 + self.boost * 0.3) * launch * 0.45,
		-LEAN_PITCH_EXTRA,
		LEAN_PITCH_EXTRA
	)
	local extraRoll = clamp(
		-localAz * 0.04 - self.steerAngle * LEAN_ROLL_EXTRA * clamp(speed / 7, 0, 1),
		-LEAN_ROLL_EXTRA,
		LEAN_ROLL_EXTRA
	)
	self.bodyPitch += extraPitch * math.min(1, 6 * dt)
	self.bodyRoll += (extraRoll - self.bodyRoll * 0.12) * math.min(1, 5 * dt)

	local targetSquash = 1 - clamp((-self.vy) * 0.008 + math.abs(localAx) * 0.001, -0.08, 0.12) - self.squashPunch
	self.bodySquash += (targetSquash - self.bodySquash) * 7 * dt

	-- Juice: NOS punch, drift smoke, boost trail
	if self.boost > 0 and self.prevBoost <= 0 and self.raceStarted then
		self.fovKick = math.max(self.fovKick, 0.4)
		addShake(self, 0.22)
		self.whiteFlash = math.max(self.whiteFlash, 0.18)
		spawnJuice(self, self.x, self.y + 0.4, self.z, 8, 6, 0.3, 0.28, 255, 120, 60)
	end
	if self.boost > 0 and self.raceStarted then
		self.fovKick = math.max(self.fovKick, 0.12)
		if self.juiceEmit > 0.045 then
			self.juiceEmit = 0
			local bx = self.x - forwardX * 1.4
			local bz = self.z - forwardZ * 1.4
			spawnJuice(self, bx, self.y + 0.25, bz, 2, 5, 0.25, 0.22, 255, 160, 70)
		end
	end
	if self.drift > 0 and self.raceStarted and speed > 5 then
		if self.juiceEmit > 0.05 then
			self.juiceEmit = 0
			for i = 3, 4 do
				local w = self.wheels[i]
				spawnJuice(self, w.wx, w.hubY - w.radius * 0.35, w.wz, 2, 2.2, 0.45, 0.5, 180, 180, 185)
			end
		end
	end
	self.prevBoost = self.boost

	if self.raceStarted then
		stepJuice(self, dt)
	else
		self.camShake = 0
		self.fovKick = 0
		self.squashPunch = 0
		self.whiteFlash = 0
		while #self.juiceParticles > 0 do
			table.remove(self.juiceParticles)
		end
	end

	return true
end

local function setBoxCorners(out: { Vec3 }, hx: number, hy: number, hz: number)
	out[1].x, out[1].y, out[1].z = -hx, -hy, -hz
	out[2].x, out[2].y, out[2].z = hx, -hy, -hz
	out[3].x, out[3].y, out[3].z = hx, -hy, hz
	out[4].x, out[4].y, out[4].z = -hx, -hy, hz
	out[5].x, out[5].y, out[5].z = -hx, hy, -hz
	out[6].x, out[6].y, out[6].z = hx, hy, -hz
	out[7].x, out[7].y, out[7].z = hx, hy, hz
	out[8].x, out[8].y, out[8].z = -hx, hy, hz
end

local function transformCorners(model: Mat4, localCorners: { Vec3 }, world: { Vec3 })
	for i = 1, 8 do
		local p = localCorners[i]
		local wp = model:transformPoint(p.x, p.y, p.z)
		world[i].x = wp.x
		world[i].y = wp.y
		world[i].z = wp.z
	end
end

local BOX_EDGES = {
	{ 1, 2 },
	{ 2, 3 },
	{ 3, 4 },
	{ 4, 1 },
	{ 5, 6 },
	{ 6, 7 },
	{ 7, 8 },
	{ 8, 5 },
	{ 1, 5 },
	{ 2, 6 },
	{ 3, 7 },
	{ 4, 8 },
}

local function drawLine2(
	path: Path,
	renderer: Renderer,
	paint: Paint,
	a: Vector,
	b: Vector
)
	path:reset()
	path:moveTo(a)
	path:lineTo(b)
	renderer:drawPath(path, paint)
end

local function drawJuiceOverlay(self: Vehicle3D, renderer: Renderer, viewProj: Mat4, screenW: number, screenH: number)
	local path = self.path
	local paint = self.uiFill
	for _, p in self.juiceParticles do
		local pt, depth = project(viewProj, { x = p.wx, y = p.wy, z = p.wz }, screenW, screenH)
		if depth < 1 then
			local t = clamp(p.life / math.max(p.maxLife, 1e-3), 0, 1)
			local s = p.size * (0.55 + 0.7 * t) * 18
			paint.color = Color.rgba(p.r, p.g, p.b, math.floor(210 * t * t))
			paint.style = "fill"
			drawRect(path, renderer, paint, pt.x - s * 0.5, pt.y - s * 0.5, s, s)
		end
	end

	local spd = math.sqrt(self.vx * self.vx + self.vz * self.vz)
	local lineAmt = 0
	if self.raceStarted then
		if self.boost > 0 then
			lineAmt = 0.55 + self.fovKick
		elseif spd > 12 then
			lineAmt = clamp((spd - 12) / 14, 0, 0.45)
		end
	end
	if lineAmt > 0.05 then
		paint.style = "stroke"
		paint.thickness = 1.5
		local n = math.floor(6 + lineAmt * 10)
		for i = 1, n do
			local side = if i % 2 == 0 then -1 else 1
			local y = screenH * (0.12 + (i / n) * 0.76)
			local len = (40 + lineAmt * 90) * (0.6 + (i % 3) * 0.2)
			local x0 = if side < 0 then 8 else screenW - 8
			paint.color = Color.rgba(255, 240, 220, math.floor(40 + 90 * lineAmt))
			drawLine2(path, renderer, paint, Vector.xy(x0, y), Vector.xy(x0 + side * len, y + side * 4))
		end
	end

	if self.whiteFlash > 0.01 then
		paint.style = "fill"
		paint.color = Color.rgba(255, 230, 180, math.floor(90 * self.whiteFlash))
		drawRect(path, renderer, paint, 0, 0, screenW, screenH)
	end
end

local function drawArrow2(
	path: Path,
	renderer: Renderer,
	stroke: Paint,
	fill: Paint,
	a: Vector,
	b: Vector,
	color: Color
)
	stroke.color = color
	stroke.style = "stroke"
	stroke.thickness = 2.2
	drawLine2(path, renderer, stroke, a, b)

	local dx = b.x - a.x
	local dy = b.y - a.y
	local len = math.sqrt(dx * dx + dy * dy)
	if len < 8 then
		return
	end
	local nx = dx / len
	local ny = dy / len
	local px = -ny
	local py = nx
	local tip = 11
	local half = 5
	path:reset()
	path:moveTo(b)
	path:lineTo(Vector.xy(b.x - nx * tip + px * half, b.y - ny * tip + py * half))
	path:lineTo(Vector.xy(b.x - nx * tip - px * half, b.y - ny * tip - py * half))
	path:close()
	fill.color = color
	fill.style = "fill"
	renderer:drawPath(path, fill)
end

local function drawWireBox(
	path: Path,
	renderer: Renderer,
	paint: Paint,
	viewProj: Mat4,
	model: Mat4,
	hx: number,
	hy: number,
	hz: number,
	screenW: number,
	screenH: number,
	localCorners: { Vec3 },
	world: { Vec3 },
	color: Color
)
	setBoxCorners(localCorners, hx, hy, hz)
	transformCorners(model, localCorners, world)
	paint.color = color
	paint.style = "stroke"
	paint.thickness = 1.6
	for i = 1, #BOX_EDGES do
		local e = BOX_EDGES[i]
		local a, _da = project(viewProj, world[e[1]], screenW, screenH)
		local b, _db = project(viewProj, world[e[2]], screenW, screenH)
		drawLine2(path, renderer, paint, a, b)
	end
end

local function drawDimArrow(
	path: Path,
	renderer: Renderer,
	stroke: Paint,
	fill: Paint,
	viewProj: Mat4,
	a: Vec3,
	b: Vec3,
	screenW: number,
	screenH: number,
	color: Color
)
	local pa, _da = project(viewProj, a, screenW, screenH)
	local pb, _db = project(viewProj, b, screenW, screenH)
	drawArrow2(path, renderer, stroke, fill, pa, pb, color)
	-- tick marks at ends
	local dx = pb.x - pa.x
	local dy = pb.y - pa.y
	local len = math.sqrt(dx * dx + dy * dy)
	if len < 1 then
		return
	end
	local px = -dy / len * 6
	local py = dx / len * 6
	stroke.color = color
	stroke.style = "stroke"
	stroke.thickness = 1.8
	drawLine2(path, renderer, stroke, Vector.xy(pa.x - px, pa.y - py), Vector.xy(pa.x + px, pa.y + py))
	drawLine2(path, renderer, stroke, Vector.xy(pb.x - px, pb.y - py), Vector.xy(pb.x + px, pb.y + py))
end

local function worldFromLocal(model: Mat4, lx: number, ly: number, lz: number): Vec3
	local p = model:transformPoint(lx, ly, lz)
	return v3(p.x, p.y, p.z)
end

local function drawDebugOverlay(
	self: Vehicle3D,
	renderer: Renderer,
	viewProj: Mat4,
	chassisModel: Mat4,
	bodyModel: Mat4,
	screenW: number,
	screenH: number,
	localCorners: { Vec3 },
	world: { Vec3 }
)
	local stroke = self.debugPaint
	local fill = self.edgePaint
	local path = self.path

	-- Local RGB axes at chassis origin
	local origin = worldFromLocal(chassisModel, 0, 0, 0)
	local axX = worldFromLocal(chassisModel, AXIS_LEN, 0, 0)
	local axY = worldFromLocal(chassisModel, 0, AXIS_LEN * 0.7, 0)
	local axZ = worldFromLocal(chassisModel, 0, 0, AXIS_LEN)
	local o2, _ = project(viewProj, origin, screenW, screenH)
	local x2, _ = project(viewProj, axX, screenW, screenH)
	local y2, _ = project(viewProj, axY, screenW, screenH)
	local z2, _ = project(viewProj, axZ, screenW, screenH)
	drawArrow2(path, renderer, stroke, fill, o2, x2, Color.rgb(255, 70, 70)) -- X forward
	drawArrow2(path, renderer, stroke, fill, o2, y2, Color.rgb(90, 220, 110)) -- Y up
	drawArrow2(path, renderer, stroke, fill, o2, z2, Color.rgb(80, 160, 255)) -- Z right

	-- Wire boxes
	drawWireBox(
		path,
		renderer,
		stroke,
		viewProj,
		chassisModel * Mat4.fromTranslation(0, CHASSIS_OY, 0),
		CHASSIS_HX,
		CHASSIS_HY,
		CHASSIS_HZ,
		screenW,
		screenH,
		localCorners,
		world,
		Color.rgba(255, 220, 80, 220)
	)
	drawWireBox(
		path,
		renderer,
		stroke,
		viewProj,
		bodyModel * Mat4.fromTranslation(BODY_OX, BODY_OY, 0),
		BODY_HX,
		BODY_HY,
		BODY_HZ,
		screenW,
		screenH,
		localCorners,
		world,
		Color.rgba(255, 120, 160, 200)
	)
	drawWireBox(
		path,
		renderer,
		stroke,
		viewProj,
		bodyModel * Mat4.fromTranslation(CABIN_OX, CABIN_OY, 0),
		CABIN_HX,
		CABIN_HY,
		CABIN_HZ,
		screenW,
		screenH,
		localCorners,
		world,
		Color.rgba(140, 220, 255, 200)
	)

	-- Chassis length / width / height dimension arrows (offset outside the box)
	local dimY = CHASSIS_OY - CHASSIS_HY - 0.25
	local dimZ = CHASSIS_HZ + 0.35
	local dimX = CHASSIS_HX + 0.35
	drawDimArrow(
		path,
		renderer,
		stroke,
		fill,
		viewProj,
		worldFromLocal(chassisModel, -CHASSIS_HX, dimY, dimZ),
		worldFromLocal(chassisModel, CHASSIS_HX, dimY, dimZ),
		screenW,
		screenH,
		Color.rgb(255, 230, 90)
	) -- length 2.70
	drawDimArrow(
		path,
		renderer,
		stroke,
		fill,
		viewProj,
		worldFromLocal(chassisModel, -dimX, dimY, -CHASSIS_HZ),
		worldFromLocal(chassisModel, -dimX, dimY, CHASSIS_HZ),
		screenW,
		screenH,
		Color.rgb(120, 200, 255)
	) -- width 1.80
	drawDimArrow(
		path,
		renderer,
		stroke,
		fill,
		viewProj,
		worldFromLocal(chassisModel, dimX, CHASSIS_OY - CHASSIS_HY, dimZ),
		worldFromLocal(chassisModel, dimX, CHASSIS_OY + CHASSIS_HY, dimZ),
		screenW,
		screenH,
		Color.rgb(120, 255, 160)
	) -- height 0.56

	-- Wheelbase (front–rear) and track (left–right) at ground
	drawDimArrow(
		path,
		renderer,
		stroke,
		fill,
		viewProj,
		worldFromLocal(chassisModel, -WHEEL_OX, 0.02, WHEEL_OZ + 0.45),
		worldFromLocal(chassisModel, WHEEL_OX, 0.02, WHEEL_OZ + 0.45),
		screenW,
		screenH,
		Color.rgb(255, 160, 60)
	) -- wheelbase 2.30
	drawDimArrow(
		path,
		renderer,
		stroke,
		fill,
		viewProj,
		worldFromLocal(chassisModel, WHEEL_OX + 0.45, 0.02, -WHEEL_OZ),
		worldFromLocal(chassisModel, WHEEL_OX + 0.45, 0.02, WHEEL_OZ),
		screenW,
		screenH,
		Color.rgb(200, 120, 255)
	) -- track 1.70

	for i = 1, 4 do
		local wh = self.wheels[i]
		local wx = wh.wx
		local wz = wh.wz
		local hubY = wh.hubY
		local gh = wh.groundY
		local contactY = gh + CONTACT_EPS
		local nx, ny, nz = groundNormal(wx, wz)
		local contactCol = if wh.inContact then Color.rgb(80, 255, 140) else Color.rgb(255, 90, 90)

		-- Contact point on collider surface (magenta cross)
		local contact = v3(wx, contactY, wz)
		local c2, _ = project(viewProj, contact, screenW, screenH)
		local cL, _ = project(viewProj, v3(wx - 0.25, contactY, wz), screenW, screenH)
		local cR, _ = project(viewProj, v3(wx + 0.25, contactY, wz), screenW, screenH)
		local cF, _ = project(viewProj, v3(wx, contactY, wz - 0.25), screenW, screenH)
		local cB, _ = project(viewProj, v3(wx, contactY, wz + 0.25), screenW, screenH)
		stroke.color = Color.rgb(255, 60, 220)
		stroke.style = "stroke"
		stroke.thickness = 2.4
		drawLine2(path, renderer, stroke, cL, cR)
		drawLine2(path, renderer, stroke, cF, cB)

		-- Tire bottom → contact (should be ~0 when planted)
		local tireBottom = v3(wx - nx * wh.radius, hubY - ny * wh.radius, wz - nz * wh.radius)
		local tb2, _ = project(viewProj, tireBottom, screenW, screenH)
		stroke.color = Color.rgb(255, 220, 40)
		stroke.thickness = 2
		drawLine2(path, renderer, stroke, tb2, c2)

		-- Surface normal guide
		local nTip = v3(wx + nx * 0.9, contactY + ny * 0.9, wz + nz * 0.9)
		local n2, _ = project(viewProj, nTip, screenW, screenH)
		drawArrow2(path, renderer, stroke, fill, c2, n2, Color.rgb(120, 255, 255))

		-- Suspension ray: chassis mount → hub → contact
		local mount = worldFromLocal(chassisModel, wh.ox, 0, wh.oz)
		local hub = v3(wx, hubY, wz)
		local m2, _ = project(viewProj, mount, screenW, screenH)
		local h2, _ = project(viewProj, hub, screenW, screenH)
		stroke.color = Color.rgba(255, 255, 255, 180)
		stroke.style = "stroke"
		stroke.thickness = 1.4
		drawLine2(path, renderer, stroke, m2, h2)
		stroke.color = contactCol
		stroke.thickness = 2.5
		drawLine2(path, renderer, stroke, h2, c2)

		-- Hub cross + radius arrows
		local wheelYaw = self.yaw + (if wh.isFront then self.steerAngle else 0)
		local cW = math.cos(wheelYaw)
		local sW = math.sin(wheelYaw)
		local rUp = v3(wx + nx * wh.radius, hubY + ny * wh.radius, wz + nz * wh.radius)
		local rFwd = v3(wx + cW * wh.radius, hubY, wz - sW * wh.radius)
		drawDimArrow(path, renderer, stroke, fill, viewProj, hub, rUp, screenW, screenH, Color.rgb(255, 200, 80))
		drawDimArrow(path, renderer, stroke, fill, viewProj, hub, rFwd, screenW, screenH, Color.rgb(255, 140, 60))

		-- Wheel rim circle in the wheel plane
		stroke.color = Color.rgba(255, 220, 100, 200)
		stroke.style = "stroke"
		stroke.thickness = 1.5
		local segs = 20
		local prev: Vector? = nil
		for s = 0, segs do
			local ang = (s / segs) * math.pi * 2
			local lx = math.cos(ang) * wh.radius
			local ly = math.sin(ang) * wh.radius
			local px = wx + cW * lx
			local py = hubY + ly
			local pz = wz - sW * lx
			local pt, _ = project(viewProj, v3(px, py, pz), screenW, screenH)
			if prev ~= nil then
				drawLine2(path, renderer, stroke, prev, pt)
			end
			prev = pt
		end

		-- Hub diamond
		fill.color = contactCol
		fill.style = "fill"
		path:reset()
		path:moveTo(Vector.xy(h2.x + 3.5, h2.y))
		path:lineTo(Vector.xy(h2.x, h2.y + 3.5))
		path:lineTo(Vector.xy(h2.x - 3.5, h2.y))
		path:lineTo(Vector.xy(h2.x, h2.y - 3.5))
		path:close()
		renderer:drawPath(path, fill)

		-- Contact diamond (smaller)
		fill.color = Color.rgb(255, 60, 220)
		path:reset()
		path:moveTo(Vector.xy(c2.x + 2.5, c2.y))
		path:lineTo(Vector.xy(c2.x, c2.y + 2.5))
		path:lineTo(Vector.xy(c2.x - 2.5, c2.y))
		path:lineTo(Vector.xy(c2.x, c2.y - 2.5))
		path:close()
		renderer:drawPath(path, fill)
	end

	-- Ramp collider surface guide (matches groundHeight)
	stroke.color = Color.rgba(80, 255, 160, 220)
	stroke.style = "stroke"
	stroke.thickness = 2.2
	local midZ = (RAMP_Z0 + RAMP_Z1) * 0.5
	local prevR: Vector? = nil
	for si = 0, 28 do
		local x = RAMP_X0 + (si / 28) * RAMP_LEN
		local y = groundHeight(x, midZ) + CONTACT_EPS
		local pt, _ = project(viewProj, v3(x, y, midZ), screenW, screenH)
		if prevR ~= nil then
			drawLine2(path, renderer, stroke, prevR, pt)
		end
		prevR = pt
	end
	-- Ramp edges
	stroke.color = Color.rgba(80, 200, 255, 200)
	stroke.thickness = 1.6
	for _, edgeZ in { RAMP_Z0, RAMP_Z1 } do
		prevR = nil
		for si = 0, 28 do
			local x = RAMP_X0 + (si / 28) * RAMP_LEN
			local y = groundHeight(x, edgeZ) + CONTACT_EPS
			local pt, _ = project(viewProj, v3(x, y, edgeZ), screenW, screenH)
			if prevR ~= nil then
				drawLine2(path, renderer, stroke, prevR, pt)
			end
			prevR = pt
		end
	end
	-- Flat ground sample ring under car
	stroke.color = Color.rgba(255, 255, 100, 160)
	stroke.thickness = 1.2
	local ringPrev: Vector? = nil
	for si = 0, 24 do
		local ang = (si / 24) * math.pi * 2
		local rx = self.x + math.cos(ang) * 2.2
		local rz = self.z + math.sin(ang) * 2.2
		local ry = groundHeight(rx, rz) + CONTACT_EPS
		local pt, _ = project(viewProj, v3(rx, ry, rz), screenW, screenH)
		if ringPrev ~= nil then
			drawLine2(path, renderer, stroke, ringPrev, pt)
		end
		ringPrev = pt
	end

	stroke.style = "fill"
	fill.style = "fill"
end

function draw(self: Vehicle3D, renderer: Renderer)
	local w = self.size.x
	local h = self.size.y
	local aspect = w / math.max(h, 1)

	self.path:reset()
	self.path:moveTo(Vector.xy(0, 0))
	self.path:lineTo(Vector.xy(w, 0))
	self.path:lineTo(Vector.xy(w, h))
	self.path:lineTo(Vector.xy(0, h))
	self.path:close()
	-- Unreal-editor style dark viewport
	self.groundPaint.color = Color.rgb(48, 110, 72)
	renderer:drawPath(self.path, self.groundPaint)

	-- Camera: home showcase → gameplay (or ISO)
	local eye: Vector
	local target: Vector
	local view: Mat4
	local proj: Mat4
	local cosY = math.cos(self.yaw)
	local sinY = math.sin(self.yaw)

	-- Gameplay camera targets
	local playTarget = Vector.xyz(
		self.x + self.camLookOffset.x,
		self.y + self.camLookOffset.y,
		self.z + self.camLookOffset.z
	)
	local playEye = Vector.xyz(
		self.x + self.camOffset.x,
		self.y + self.camOffset.y,
		self.z + self.camOffset.z
	)
	-- Screen shake juice
	if self.camShake > 0.01 then
		local t = self.camIntroAngle * 40
		local amp = self.camShake * 0.55
		playEye = Vector.xyz(
			playEye.x + math.sin(t * 1.7) * amp,
			playEye.y + math.cos(t * 2.1) * amp * 0.65,
			playEye.z + math.sin(t * 1.3 + 1.2) * amp
		)
		playTarget = Vector.xyz(
			playTarget.x + math.sin(t * 1.9) * amp * 0.35,
			playTarget.y + math.cos(t * 1.5) * amp * 0.25,
			playTarget.z + math.sin(t * 2.3) * amp * 0.35
		)
	end

	-- Home / title cam: fixed side view, car sits still (no orbit)
	local hx = 0.4
	local hy = 1.5
	local hz = 7.2
	local homeOx = cosY * hx + sinY * hz
	local homeOz = -sinY * hx + cosY * hz
	local homeEye = Vector.xyz(self.x + homeOx, self.y + hy, self.z + homeOz)
	local homeTarget = Vector.xyz(
		self.x,
		self.y + 0.5,
		self.z
	)

	local blend = self.camBlend
	-- Smoothstep
	blend = blend * blend * (3 - 2 * blend)

	if self.camIso and self.raceStarted and blend > 0.95 then
		local dist = 32
		local elev = math.rad(35.264)
		local azim = math.rad(45)
		local ox = dist * math.cos(elev) * math.sin(azim)
		local oy = dist * math.sin(elev)
		local oz = dist * math.cos(elev) * math.cos(azim)
		eye = Vector.xyz(self.x + ox, self.y + oy, self.z + oz)
		target = playTarget
		view = Mat4.lookAt(eye, target, Vector.xyz(0, 1, 0))
		local halfH = self.camOrthoSize
		local halfW = halfH * aspect
		proj = Mat4.ortho(-halfW, halfW, -halfH, halfH, 0.5, 200)
	else
		eye = Vector.xyz(
			homeEye.x + (playEye.x - homeEye.x) * blend,
			homeEye.y + (playEye.y - homeEye.y) * blend,
			homeEye.z + (playEye.z - homeEye.z) * blend
		)
		target = Vector.xyz(
			homeTarget.x + (playTarget.x - homeTarget.x) * blend,
			homeTarget.y + (playTarget.y - homeTarget.y) * blend,
			homeTarget.z + (playTarget.z - homeTarget.z) * blend
		)
		view = Mat4.lookAt(eye, target, Vector.xyz(0, 1, 0))
		local fov = math.rad(30 + 12 * blend + self.fovKick * 22)
		proj = Mat4.perspective(fov, aspect, 0.15, 120)
	end
	local viewProj = proj * view
	self.drawEyeX = eye.x
	self.drawEyeY = eye.y
	self.drawEyeZ = eye.z

	-- Chassis follows terrain pitch/roll (from wheel heights); wheels stay planted separately
	local chassisModel = Mat4.fromTranslation(self.x, self.y, self.z)
		* Mat4.fromRotationY(self.yaw)
		* Mat4.fromRotationZ(self.bodyPitch)
		* Mat4.fromRotationX(self.bodyRoll)
	local bodyModel = chassisModel
		* Mat4.fromScale(1 / math.sqrt(self.bodySquash), self.bodySquash, 1 / math.sqrt(self.bodySquash))

	-- GPU: cutting-mat ground + toon meshes (outline then shade)
	if ensurePipeline(self) then
		ensureRenderTargets(self)
		local pipeline = self.pipeline
		local outlinePipeline = self.outlinePipeline
		local shadowPipeline = self.shadowPipeline
		local planarPipeline = self.planarPipeline
		local groundPipeline = self.groundPipeline
		local groundUbo = self.groundUbo
		local groundBind = self.groundBind
		local ubo = self.ubo
		local shadowUbo = self.shadowUbo
		local planarUbo = self.planarUbo
		local depthView = self.depthView
		local boxMesh = self.boxMesh
		local msaaColor = self.msaaColor
		if pipeline and outlinePipeline and shadowPipeline and planarPipeline and groundPipeline and groundUbo and groundBind and ubo and shadowUbo and planarUbo and depthView and boxMesh and self.canvas.width > 0 then
			local groundHalf = 70
			local groundModel = Mat4.fromTranslation(self.x, -0.02, self.z) * Mat4.fromScale(groundHalf, 0.02, groundHalf)
			writeGroundUniform(
				self.groundCpu,
				viewProj * groundModel,
				groundModel,
				0.55,
				5,
				groundHalf * 0.72,
				groundHalf * 0.98
			)
			groundUbo:write(self.groundCpu, 0, 0, 256)

			-- Simple shape shadows only (ellipse under each object — no mesh clone)
			self.shadowCursor = 0
			self.planarCursor = 0
			local hasBodyGlb = #self.bodyParts > 0
			local chassisM = chassisModel * Mat4.fromTranslation(0, CHASSIS_OY, 0) * Mat4.fromScale(CHASSIS_HX, CHASSIS_HY, CHASSIS_HZ)
			local bodyM = bodyModel * Mat4.fromTranslation(BODY_OX, BODY_OY, 0) * Mat4.fromScale(BODY_HX, BODY_HY, BODY_HZ)
			local cabinM = bodyModel * Mat4.fromTranslation(CABIN_OX, CABIN_OY, 0) * Mat4.fromScale(CABIN_HX, CABIN_HY, CABIN_HZ)
			local bodyGlbM = bodyModel
				* Mat4.fromTranslation(0, self.bodyMeshLift, 0)
				* self.bodyMeshOrient
				* Mat4.fromScale(self.bodyMeshScale, self.bodyMeshScale, self.bodyMeshScale)

			-- One oval under the car
			queueContactShadow(
				self,
				viewProj,
				self.x,
				self.y + BODY_OY,
				self.z,
				CHASSIS_HX * 1.35,
				CHASSIS_HZ * 1.25,
				self.yaw,
				0.34
			)
			for i = 1, 4 do
				local wh = self.wheels[i]
				queueContactShadow(self, viewProj, wh.wx, wh.hubY, wh.wz, wh.radius * 1.1, wh.radius * 0.75, self.yaw, 0.22)
			end
			for _, crate in self.crates do
				queueContactShadow(
					self,
					viewProj,
					crate.x,
					crate.y,
					crate.z,
					crate.hx * 1.2,
					crate.hz * 1.2,
					crate.yaw,
					0.3
				)
			end
			do
				local midX = (RAMP_X0 + RAMP_X1) * 0.5
				local midZ = (RAMP_Z0 + RAMP_Z1) * 0.5
				queueContactShadow(
					self,
					viewProj,
					midX,
					RAMP_HEIGHT * 0.5,
					midZ,
					RAMP_LEN * 0.5,
					(RAMP_Z1 - RAMP_Z0) * 0.5,
					0,
					0.2
				)
			end

			local meshScale = WHEEL_RADIUS / math.max(self.wheelMeshRadius, 0.01)
			local hasGlb = #self.wheelParts > 0

			self.drawCursor = 0
			-- Keep a thin under-tray only when using box body; mobil.glb replaces upper body
			if not hasBodyGlb then
				queueDraw(
					self,
					boxMesh,
					chassisM,
					viewProj,
					0.22,
					0.25,
					0.32
				)
			else
				-- Subtle dark underbody so wheels don't float visually
				queueDraw(
					self,
					boxMesh,
					chassisModel * Mat4.fromTranslation(0, CHASSIS_OY * 0.5, 0) * Mat4.fromScale(CHASSIS_HX * 0.85, CHASSIS_HY * 0.45, CHASSIS_HZ * 0.75),
					viewProj,
					0.12,
					0.13,
					0.16
				)
			end
			if hasBodyGlb then
				for _, part in self.bodyParts do
					queueDraw(self, part.mesh, bodyGlbM, viewProj, part.r, part.g, part.b)
				end
			else
				queueDraw(
					self,
					boxMesh,
					bodyM,
					viewProj,
					0.86,
					0.27,
					0.35
				)
				queueDraw(
					self,
					boxMesh,
					cabinM,
					viewProj,
					0.14,
					0.16,
					0.21
				)
			end

			for i = 1, 4 do
				local wh = self.wheels[i]
				local wheelYaw = self.yaw + (if wh.isFront then self.steerAngle else 0)
				local slopeAng = math.atan(groundSlope(wh.wx, wh.wz))
				local wheelModel = Mat4.fromTranslation(wh.wx, wh.hubY, wh.wz)
					* Mat4.fromRotationY(wheelYaw)
					* Mat4.fromRotationZ(slopeAng + wh.spin)
				if hasGlb then
					local model = wheelModel * self.wheelMeshOrient * Mat4.fromScale(meshScale, meshScale, meshScale)
					for _, part in self.wheelParts do
						queueDraw(self, part.mesh, model, viewProj, part.r, part.g, part.b)
					end
				else
					queueDraw(
						self,
						boxMesh,
						wheelModel * Mat4.fromScale(wh.radius * 0.95, wh.radius * 0.95, WHEEL_HALF_WIDTH),
						viewProj,
						0.1,
						0.1,
						0.12
					)
				end
			end

			for _, crate in self.crates do
				queueDraw(
					self,
					boxMesh,
					Mat4.fromTranslation(crate.x, crate.y, crate.z)
						* Mat4.fromRotationY(crate.yaw)
						* Mat4.fromScale(crate.hx, crate.hy, crate.hz),
					viewProj,
					crate.r,
					crate.g,
					crate.b
				)
			end

			-- Under-ramp solid (kolong) + tip wall, then smooth plank on top
			do
				local midX = (RAMP_X0 + RAMP_X1) * 0.5
				local midZ = (RAMP_Z0 + RAMP_Z1) * 0.5
				local halfW = (RAMP_Z1 - RAMP_Z0) * 0.5
				local hyp = math.sqrt(RAMP_LEN * RAMP_LEN + RAMP_HEIGHT * RAMP_HEIGHT)
				local angle = math.atan(RAMP_HEIGHT / RAMP_LEN)
				local thick = RAMP_THICK
				local topCx, topCy = midX, RAMP_HEIGHT * 0.5
				local upX, upY = -math.sin(angle), math.cos(angle)
				local bx = topCx - upX * (thick * 0.5)
				local by = topCy - upY * (thick * 0.5)
				-- Kolong fill + tip wall first
				for _, blk in self.rampBlocks do
					queueDraw(
						self,
						boxMesh,
						Mat4.fromTranslation(blk.x, blk.y, blk.z) * Mat4.fromScale(blk.hx, blk.hy, blk.hz),
						viewProj,
						blk.r,
						blk.g,
						blk.b
					)
				end
				-- Drive surface plank
				local rampModel = Mat4.fromTranslation(bx, by, midZ)
					* Mat4.fromRotationZ(angle)
					* Mat4.fromScale(hyp * 0.5, thick * 0.5, halfW)
				queueDraw(self, boxMesh, rampModel, viewProj, 0.55, 0.58, 0.62)
				local wallH = 0.55
				queueDraw(
					self,
					boxMesh,
					Mat4.fromTranslation(bx, by + upY * (wallH * 0.35), RAMP_Z0 - 0.18)
						* Mat4.fromRotationZ(angle)
						* Mat4.fromScale(hyp * 0.5, wallH * 0.5, 0.14),
					viewProj,
					0.95,
					0.55,
					0.2
				)
				queueDraw(
					self,
					boxMesh,
					Mat4.fromTranslation(bx, by + upY * (wallH * 0.35), RAMP_Z1 + 0.18)
						* Mat4.fromRotationZ(angle)
						* Mat4.fromScale(hyp * 0.5, wallH * 0.5, 0.14),
					viewProj,
					0.95,
					0.55,
					0.2
				)
				for i = 0, 2 do
					local cx = RAMP_X0 - 3.5 + i * 1.1
					queueDraw(
						self,
						boxMesh,
						Mat4.fromTranslation(cx, 0.04, midZ) * Mat4.fromScale(0.35, 0.04, 1.4),
						viewProj,
						1.0,
						0.75,
						0.15
					)
				end
			end

			local drawn = self.drawCursor
			local shadows = self.shadowCursor
			local planars = self.planarCursor
			if drawn > 0 then
				ubo:write(self.uboCpu, 0, 0, drawn * UNIFORM_STRIDE)
			end
			if shadows > 0 then
				shadowUbo:write(self.shadowCpu, 0, 0, shadows * UNIFORM_STRIDE)
			end
			if planars > 0 then
				planarUbo:write(self.planarCpu, 0, 0, planars * UNIFORM_STRIDE)
			end
			local clearColor = { 0.078, 0.086, 0.157, 1 }
			local colorArr: any
			if msaaColor ~= nil and self.samples > 1 then
				colorArr = {
					{
						view = msaaColor:view(),
						resolveTarget = self.canvas:colorView(),
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
			local pass = self.canvas:beginRenderPass({
				color = colorArr,
				depthStencil = {
					view = depthView,
					depthLoadOp = "clear",
					depthStoreOp = "discard",
					depthClearValue = 1,
				},
			})
			pass:setViewport(0, 0, self.canvas.width, self.canvas.height)
			-- Ground first
			pass:setPipeline(groundPipeline)
			pass:setBindGroup(0, groundBind)
			pass:setVertexBuffer(0, boxMesh.vertex)
			pass:setIndexBuffer(boxMesh.index, "uint16")
			pass:drawIndexed(boxMesh.indexCount)
			-- Planar projected car silhouette (sunlight clone)
			pass:setPipeline(planarPipeline)
			for pi = 1, planars do
				local mesh = self.planarMeshes[pi]
				pass:setBindGroup(0, self.planarBindGroups[pi])
				pass:setVertexBuffer(0, mesh.vertex)
				pass:setIndexBuffer(mesh.index, "uint16")
				pass:drawIndexed(mesh.indexCount)
			end
			-- Soft contact blobs on the ground
			pass:setPipeline(shadowPipeline)
			for si = 1, shadows do
				local mesh = self.shadowMeshes[si]
				pass:setBindGroup(0, self.shadowBindGroups[si])
				pass:setVertexBuffer(0, mesh.vertex)
				pass:setIndexBuffer(mesh.index, "uint16")
				pass:drawIndexed(mesh.indexCount)
			end
			-- Outline (inverted hull, cull front) — skip when OUT.W ≈ 0
			if lookVal(self, "outlineW", 3.8) > 0.05 then
				pass:setPipeline(outlinePipeline)
				for di = 1, drawn do
					local mesh = self.drawMeshes[di]
					pass:setBindGroup(0, self.bindGroups[di])
					pass:setVertexBuffer(0, mesh.vertex)
					pass:setIndexBuffer(mesh.index, "uint16")
					pass:drawIndexed(mesh.indexCount)
				end
			end
			-- Toon mesh shade
			pass:setPipeline(pipeline)
			for di = 1, drawn do
				local mesh = self.drawMeshes[di]
				pass:setBindGroup(0, self.bindGroups[di])
				pass:setVertexBuffer(0, mesh.vertex)
				pass:setIndexBuffer(mesh.index, "uint16")
				pass:drawIndexed(mesh.indexCount)
			end
			pass:finish()

			local image = self.canvas.image
			if image then
				renderer:save()
				renderer:transform(Mat2D.withScale(1 / self.scale, 1 / self.scale))
				renderer:drawImage(image, self.sampler, "srcOver", 1)
				renderer:restore()
			end
		end
	end

	local scratchWorld: { Vec3 } = {
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
	}
	local scratchLocal: { Vec3 } = {
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
		v3(0, 0, 0),
	}

	if self.showDebug then
		drawDebugOverlay(self, renderer, viewProj, chassisModel, bodyModel, w, h, scratchLocal, scratchWorld)
	end
	drawTunePanel(self, renderer)
	drawLookPanel(self, renderer)
	drawStartPrompt(self, renderer)
	if self.raceStarted then
		drawJuiceOverlay(self, renderer, viewProj, w, h)
	end
end

return function(context: Context): Layout<Vehicle3D>
	return {
		context = context,
		canvas = context:gpuCanvas(),
		sampler = ImageSampler("clamp", "clamp", "bilinear"),
		size = Vector.xy(800, 500),
		scale = 1,
		path = Path.new(),
		groundPaint = Paint.with({ color = Color.rgb(48, 110, 72) }),
		chassisPaint = Paint.with({ color = Color.rgb(48, 54, 68) }),
		bodyPaint = Paint.with({ color = Color.rgb(220, 70, 88) }),
		cabinPaint = Paint.with({ color = Color.rgb(36, 42, 54) }),
		wheelPaint = Paint.with({ color = Color.rgb(24, 24, 28) }),
		hubPaint = Paint.with({ color = Color.rgb(150, 155, 165) }),
		edgePaint = Paint.with({ color = Color.rgb(70, 110, 80), style = "stroke", thickness = 1.5 }),
		debugPaint = Paint.with({ color = Color.rgb(255, 220, 80), style = "stroke", thickness = 1.6 }),
		uiPaint = Paint.with({ color = Color.rgba(12, 16, 24, 210), style = "fill" }),
		uiFill = Paint.with({ color = Color.rgb(90, 200, 255), style = "fill" }),

		pipeline = nil,
		outlinePipeline = nil,
		shadowPipeline = nil,
		shadowUbo = nil,
		shadowCpu = buffer.create(MAX_SHADOWS * UNIFORM_STRIDE),
		shadowBindGroups = {},
		shadowMeshes = {},
		shadowCursor = 0,
		planarPipeline = nil,
		planarUbo = nil,
		planarCpu = buffer.create(MAX_PLANAR * UNIFORM_STRIDE),
		planarBindGroups = {},
		planarMeshes = {},
		planarCursor = 0,
		drawEyeX = 0,
		drawEyeY = 8,
		drawEyeZ = 12,
		groundPipeline = nil,
		groundUbo = nil,
		groundBind = nil,
		groundCpu = buffer.create(256),
		depth = nil,
		depthView = nil,
		msaaColor = nil,
		samples = 1,
		pipelineSamples = 0,
		targetSamples = 0,
		ubo = nil,
		uboCpu = buffer.create(MAX_DRAWS * UNIFORM_STRIDE),
		bindGroups = {},
		drawMeshes = {},
		drawCursor = 0,
		boxMesh = nil,
		shadowDiscMesh = nil,
		wheelParts = {},
		wheelMeshRadius = 1,
		wheelMeshOrient = Mat4.identity(),
		bodyParts = {},
		bodyMeshSizeX = 1,
		bodyMeshSizeY = 1,
		bodyMeshSizeZ = 1,
		bodyMeshOrient = Mat4.identity(),
		bodyMeshScale = 1,
		bodyMeshLift = 0.35,
		crates = {},
		rampBlocks = {},

		gas = 0,
		steer = 0,
		steerAngle = 0,
		boost = 0,
		drift = 0,
		keysW = false,
		keysS = false,
		keysA = false,
		keysD = false,
		showDebug = false,
		paused = false,
		showTune = false,
		showLook = false,
		tune = {},
		look = {},
		tuneDrag = 0,
		lookDrag = 0,

		x = 0,
		y = 1.1,
		z = 0,
		yaw = 0,
		vx = 0,
		vy = 0,
		vz = 0,
		localSpeed = 0,

		wheels = {},

		bodyPitch = 0,
		bodyPitchVel = 0,
		bodyRoll = 0,
		bodyRollVel = 0,
		bodySquash = 1,

		camShake = 0,
		fovKick = 0,
		squashPunch = 0,
		whiteFlash = 0,
		prevBoost = 0,
		airTime = 0,
		juiceEmit = 0,
		juiceParticles = {},

		camOffset = { x = 10, y = 8, z = 12 },
		camLookOffset = { x = 0, y = 0.5, z = 0 },
		camIso = false,
		camOrthoSize = 14,
		raceStarted = false,
		camBlend = 0,
		camIntroAngle = 0,
		wasOnRamp = false,
		launched = false,

		init = init,
		resize = resize,
		keyboardEvent = keyboardEvent,
		pointerDown = pointerDown,
		pointerMove = pointerMove,
		pointerUp = pointerUp,
		pointerExit = pointerExit,
		advance = advance,
		draw = draw,
	}
end
