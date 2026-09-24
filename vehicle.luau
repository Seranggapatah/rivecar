-- 3D Bruno-style vehicle in Rive: chassis box + 4 ray wheels + body secondary spring.
-- Rive's Renderer is 2D, so we simulate in 3D (Mat4) and project faces to screen.
-- Controls: A/D front wheels, W/S gas, Space jump, Shift boost.
-- Camera: fixed angle, position follows the car (no yaw orbit).

type Vec3 = { x: number, y: number, z: number }

type Wheel = {
	ox: number,
	oz: number,
	radius: number,
	suspension: number,
	suspensionVel: number,
	inContact: boolean,
	spin: number,
	isFront: boolean,
}

type Vehicle3D = {
	size: Vector,
	path: Path,

	groundPaint: Paint,
	chassisPaint: Paint,
	bodyPaint: Paint,
	cabinPaint: Paint,
	wheelPaint: Paint,
	hubPaint: Paint,
	edgePaint: Paint,

	gas: number,
	steer: number,
	steerAngle: number,
	boost: number,
	jumpPressed: boolean,
	keysW: boolean,
	keysS: boolean,
	keysA: boolean,
	keysD: boolean,

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

	-- Fixed camera (same angle always; position follows the car)
	camOffset: Vec3,
	camLookOffset: Vec3,
}

local KEY = {
	A = 65,
	D = 68,
	W = 87,
	S = 83,
	LEFT = 263,
	RIGHT = 262,
	UP = 265,
	DOWN = 264,
	SPACE = 32,
	SHIFT_L = 340,
	SHIFT_R = 344,
}

local ENGINE = 28
local BOOST_MULT = 1.9
local TOP_SPEED = 18
local TOP_SPEED_BOOST = 28
local DRAG = 0.9
local LATERAL_GRIP = 22
local STEER_SPEED = 2.8
local STEER_MAX = 0.7
local STEER_LERP = 16
local GRAVITY = 55
local JUMP_IMPULSE = 18
local SUSP_REST = 0.55
local SUSP_STIFF = 70
local SUSP_DAMP = 9
local BODY_STIFF = 22
local BODY_DAMP = 5.5

local function clamp(v: number, lo: number, hi: number): number
	if v < lo then
		return lo
	end
	if v > hi then
		return hi
	end
	return v
end

local function v3(x: number, y: number, z: number): Vec3
	return { x = x, y = y, z = z }
end

local function fillPoly(path: Path, pts: { Vector }, n: number)
	path:reset()
	if n < 3 then
		return
	end
	path:moveTo(pts[1])
	for i = 2, n do
		path:lineTo(pts[i])
	end
	path:close()
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

function init(self: Vehicle3D, _context: Context): boolean
	print("3D vehicle — W/S gas, A/D front wheels; camera angle fixed, position follows")
	self.x = 0
	self.y = 1.1
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
	-- Same view angle forever; eye/target only translate with the car
	self.camOffset = v3(10, 8, 12)
	self.camLookOffset = v3(0, 0.5, 0)
	-- ox > 0 = front (X forward)
	self.wheels = {
		{ ox = 1.15, oz = 0.85, radius = 0.42, suspension = SUSP_REST, suspensionVel = 0, inContact = true, spin = 0, isFront = true },
		{ ox = 1.15, oz = -0.85, radius = 0.42, suspension = SUSP_REST, suspensionVel = 0, inContact = true, spin = 0, isFront = true },
		{ ox = -1.15, oz = 0.85, radius = 0.42, suspension = SUSP_REST, suspensionVel = 0, inContact = true, spin = 0, isFront = false },
		{ ox = -1.15, oz = -0.85, radius = 0.42, suspension = SUSP_REST, suspensionVel = 0, inContact = true, spin = 0, isFront = false },
	}
	return true
end

function resize(self: Vehicle3D, size: Vector)
	self.size = size
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
		if down and not self.jumpPressed then
			local grounded = false
			for i = 1, #self.wheels do
				if self.wheels[i].inContact then
					grounded = true
					break
				end
			end
			if grounded then
				self.vy += JUMP_IMPULSE
			end
		end
		self.jumpPressed = down
		return true
	end

	return false
end

function pointerDown(self: Vehicle3D, _event: PointerEvent)
end

function pointerMove(self: Vehicle3D, _event: PointerEvent)
end

function pointerUp(self: Vehicle3D, _event: PointerEvent)
end

function pointerExit(self: Vehicle3D, _event: PointerEvent)
end

function advance(self: Vehicle3D, seconds: number): boolean
	local dt = math.min(seconds, 1 / 30)

	self.gas = 0
	if self.keysW then
		self.gas += 1
	end
	if self.keysS then
		self.gas -= 1
	end
	self.steer = 0
	if self.keysA then
		self.steer += 1
	end
	if self.keysD then
		self.steer -= 1
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
	local engine = self.gas * ENGINE * (1 + self.boost * (BOOST_MULT - 1)) / (1 + overflow * 0.08)

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

	-- Split velocity into forward / sideways (tire frame)
	local forwardSpeed = self.vx * forwardX + self.vz * forwardZ
	local lateralSpeed = self.vx * rightX + self.vz * rightZ

	-- Engine + long drag along facing; kill sideways slip (grip)
	forwardSpeed += engine * contactRatio * dt
	forwardSpeed *= math.exp(-DRAG * dt)
	lateralSpeed *= math.exp(-LATERAL_GRIP * contactRatio * dt)

	self.vx = forwardX * forwardSpeed + rightX * lateralSpeed
	self.vz = forwardZ * forwardSpeed + rightZ * lateralSpeed

	-- Yaw from front steer while rolling; rotate velocity with the car (no scrub slide)
	local steerAmount = self.steerAngle * STEER_SPEED * clamp(math.abs(forwardSpeed) / 3.5, 0, 1) * contactRatio
	if forwardSpeed < 0 then
		steerAmount = -steerAmount
	end
	local dYaw = steerAmount * dt
	if dYaw ~= 0 then
		local c = math.cos(dYaw)
		local s = math.sin(dYaw)
		-- Clockwise in XZ when yaw increases (matches forward = (cos, -sin))
		local nx = self.vx * c + self.vz * s
		local nz = -self.vx * s + self.vz * c
		self.vx = nx
		self.vz = nz
		self.yaw += dYaw
	end

	cosY = math.cos(self.yaw)
	sinY = math.sin(self.yaw)
	forwardX = cosY
	forwardZ = -sinY
	rightX = sinY
	rightZ = cosY

	-- One more lateral scrub after turn so residual slip dies
	forwardSpeed = self.vx * forwardX + self.vz * forwardZ
	lateralSpeed = self.vx * rightX + self.vz * rightZ
	lateralSpeed *= math.exp(-LATERAL_GRIP * 0.5 * contactRatio * dt)
	self.vx = forwardX * forwardSpeed + rightX * lateralSpeed
	self.vz = forwardZ * forwardSpeed + rightZ * lateralSpeed

	-- Gravity + suspension rays (ground y = 0)
	self.vy -= GRAVITY * dt
	local forceY = 0
	for i = 1, #self.wheels do
		local w = self.wheels[i]
		local hubY = self.y - w.suspension
		local penetration = w.radius - hubY
		if penetration > 0 then
			w.inContact = true
			local spring = penetration * SUSP_STIFF
			local damp = self.vy * SUSP_DAMP
			forceY += (spring - damp) * 0.25
			local targetSusp = clamp(SUSP_REST - penetration, 0.2, SUSP_REST + 0.15)
			w.suspensionVel += (targetSusp - w.suspension) * 35 * dt
			w.suspensionVel *= math.exp(-12 * dt)
			w.suspension += w.suspensionVel * dt
		else
			w.inContact = false
			w.suspensionVel += (SUSP_REST - w.suspension) * 18 * dt
			w.suspensionVel *= math.exp(-8 * dt)
			w.suspension += w.suspensionVel * dt
		end

		w.spin += forwardSpeed / math.max(w.radius, 0.1) * dt
	end

	self.vy += forceY * dt
	self.x += self.vx * dt
	self.y += self.vy * dt
	self.z += self.vz * dt

	if self.y < 0.4 then
		self.y = 0.4
		if self.vy < 0 then
			self.vy = 0
		end
	end

	-- Local acceleration for secondary body action
	local localFwd = self.vx * forwardX + self.vz * forwardZ
	local localRight = self.vx * rightX + self.vz * rightZ
	local localAx = (localFwd - self.localSpeed) / math.max(dt, 1e-4)
	self.localSpeed = localFwd
	local localAz = localRight -- sideways as roll cue (smoothed below)

	local targetPitch = clamp(-localAx * 0.012 - self.gas * 0.1 * (1 + self.boost * 0.4), -0.5, 0.5)
	local targetRoll = clamp(-localAz * 0.08 - self.steerAngle * 0.35 * clamp(speed / 8, 0, 1), -0.4, 0.4)

	self.bodyPitchVel += (targetPitch - self.bodyPitch) * BODY_STIFF * dt
	self.bodyPitchVel *= math.exp(-BODY_DAMP * dt)
	self.bodyPitch += self.bodyPitchVel * dt

	self.bodyRollVel += (targetRoll - self.bodyRoll) * BODY_STIFF * dt
	self.bodyRollVel *= math.exp(-BODY_DAMP * dt)
	self.bodyRoll += self.bodyRollVel * dt

	local targetSquash = 1 - clamp((-self.vy) * 0.01, -0.15, 0.2)
	self.bodySquash += (targetSquash - self.bodySquash) * 8 * dt

	-- Camera stays fixed — only the car / front wheels move
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
	self.groundPaint.color = Color.rgb(22, 28, 38)
	renderer:drawPath(self.path, self.groundPaint)

	-- Angle locked; position tracks the car (world-offset, no yaw follow)
	local eye = Vector.xyz(
		self.x + self.camOffset.x,
		self.y + self.camOffset.y,
		self.z + self.camOffset.z
	)
	local target = Vector.xyz(
		self.x + self.camLookOffset.x,
		self.y + self.camLookOffset.y,
		self.z + self.camLookOffset.z
	)
	local view = Mat4.lookAt(eye, target, Vector.xyz(0, 1, 0))
	local proj = Mat4.perspective(math.rad(42), aspect, 0.2, 120)
	local viewProj = proj * view

	-- Ground grid
	self.edgePaint.color = Color.rgba(70, 110, 80, 160)
	self.edgePaint.style = "stroke"
	self.edgePaint.thickness = 1.5
	local gridN = 8
	local gridStep = 3
	for gi = -gridN, gridN do
		local p0, _d0 = project(viewProj, v3(gi * gridStep, 0, -gridN * gridStep), w, h)
		local p1, _d1 = project(viewProj, v3(gi * gridStep, 0, gridN * gridStep), w, h)
		local p2, _d2 = project(viewProj, v3(-gridN * gridStep, 0, gi * gridStep), w, h)
		local p3, _d3 = project(viewProj, v3(gridN * gridStep, 0, gi * gridStep), w, h)
		self.path:reset()
		self.path:moveTo(p0)
		self.path:lineTo(p1)
		renderer:drawPath(self.path, self.edgePaint)
		self.path:reset()
		self.path:moveTo(p2)
		self.path:lineTo(p3)
		renderer:drawPath(self.path, self.edgePaint)
	end
	self.edgePaint.style = "fill"

	local chassisModel = Mat4.fromTranslation(self.x, self.y, self.z) * Mat4.fromRotationY(self.yaw)
	local bodyModel = chassisModel
		* Mat4.fromRotationZ(self.bodyPitch)
		* Mat4.fromRotationX(self.bodyRoll)
		* Mat4.fromScale(1 / math.sqrt(self.bodySquash), self.bodySquash, 1 / math.sqrt(self.bodySquash))

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

	local FACE_IDX = {
		{ 1, 2, 3, 4 },
		{ 5, 6, 7, 8 },
		{ 1, 2, 6, 5 },
		{ 4, 3, 7, 8 },
		{ 1, 4, 8, 5 },
		{ 2, 3, 7, 6 },
	}

	type Quad = { depth: number, paint: Paint, p0: Vector, p1: Vector, p2: Vector, p3: Vector }
	local quads: { Quad } = {}
	local qn = 0

	local function pushBox(model: Mat4, hx: number, hy: number, hz: number, paints: { Paint })
		setBoxCorners(scratchLocal, hx, hy, hz)
		transformCorners(model, scratchLocal, scratchWorld)
		for fi = 1, 6 do
			local idx = FACE_IDX[fi]
			local p0, d0 = project(viewProj, scratchWorld[idx[1]], w, h)
			local p1, d1 = project(viewProj, scratchWorld[idx[2]], w, h)
			local p2, d2 = project(viewProj, scratchWorld[idx[3]], w, h)
			local p3, d3 = project(viewProj, scratchWorld[idx[4]], w, h)
			qn += 1
			quads[qn] = {
				depth = (d0 + d1 + d2 + d3) * 0.25,
				paint = paints[((fi - 1) % #paints) + 1],
				p0 = p0,
				p1 = p1,
				p2 = p2,
				p3 = p3,
			}
		end
	end

	local chassisPaints = {
		self.chassisPaint,
		self.chassisPaint,
		self.cabinPaint,
		self.cabinPaint,
		self.cabinPaint,
		self.cabinPaint,
	}
	pushBox(chassisModel * Mat4.fromTranslation(0, -0.15, 0), 1.35, 0.28, 0.9, chassisPaints)

	local bodyPaints = {
		self.bodyPaint,
		self.bodyPaint,
		self.bodyPaint,
		self.bodyPaint,
		self.bodyPaint,
		self.bodyPaint,
	}
	pushBox(bodyModel * Mat4.fromTranslation(0.05, 0.35, 0), 1.2, 0.35, 0.82, bodyPaints)

	local cabinPaints = {
		self.cabinPaint,
		self.cabinPaint,
		self.cabinPaint,
		self.cabinPaint,
		self.cabinPaint,
		self.cabinPaint,
	}
	pushBox(bodyModel * Mat4.fromTranslation(-0.15, 0.85, 0), 0.55, 0.28, 0.7, cabinPaints)

	local cosY = math.cos(self.yaw)
	local sinY = math.sin(self.yaw)
	for i = 1, 4 do
		local wh = self.wheels[i]
		local wx = self.x + cosY * wh.ox + sinY * wh.oz
		local wz = self.z + -sinY * wh.ox + cosY * wh.oz
		local wy = self.y - wh.suspension
		-- Front L/R: yaw = chassis + steerAngle; rear stays straight
		local wheelYaw = self.yaw + (if wh.isFront then self.steerAngle else 0)
		local wheelModel = Mat4.fromTranslation(wx, wy, wz)
			* Mat4.fromRotationY(wheelYaw)
			* Mat4.fromRotationZ(wh.spin)
		local wheelPaints = {
			self.wheelPaint,
			self.hubPaint,
			self.wheelPaint,
			self.wheelPaint,
			self.hubPaint,
			self.hubPaint,
		}
		-- Tire shape: thin on axle (local Z), so Y-steer is obvious
		pushBox(wheelModel, wh.radius * 0.95, wh.radius * 0.95, 0.14, wheelPaints)
	end

	for i = 1, qn do
		local best = i
		for j = i + 1, qn do
			if quads[j].depth > quads[best].depth then
				best = j
			end
		end
		if best ~= i then
			local tmp = quads[i]
			quads[i] = quads[best]
			quads[best] = tmp
		end
	end

	for i = 1, qn do
		local q = quads[i]
		fillPoly(self.path, { q.p0, q.p1, q.p2, q.p3 }, 4)
		renderer:drawPath(self.path, q.paint)
	end
end

return function(_context: Context): Layout<Vehicle3D>
	return {
		size = Vector.xy(800, 500),
		path = Path.new(),
		groundPaint = Paint.with({ color = Color.rgb(22, 28, 38) }),
		chassisPaint = Paint.with({ color = Color.rgb(48, 54, 68) }),
		bodyPaint = Paint.with({ color = Color.rgb(220, 70, 88) }),
		cabinPaint = Paint.with({ color = Color.rgb(36, 42, 54) }),
		wheelPaint = Paint.with({ color = Color.rgb(24, 24, 28) }),
		hubPaint = Paint.with({ color = Color.rgb(150, 155, 165) }),
		edgePaint = Paint.with({ color = Color.rgb(70, 110, 80), style = "stroke", thickness = 1.5 }),

		gas = 0,
		steer = 0,
		steerAngle = 0,
		boost = 0,
		jumpPressed = false,
		keysW = false,
		keysS = false,
		keysA = false,
		keysD = false,

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

		camOffset = { x = 10, y = 8, z = 12 },
		camLookOffset = { x = 0, y = 0.5, z = 0 },

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
