type Particle = {
  instance: Artboard<nil>,
  -- Unit direction the particle travels outward from the center.
  dirX: number,
  dirY: number,
  -- Distance already traveled from the center along (dirX, dirY).
  distance: number,
  speedMultiplier: number,
  active: boolean,
}

type ParticleSystemData = {
  -- Turns particle emission on/off. Existing particles keep moving and
  -- recycling even when this is false; only new spawns are stopped.
  play: Input<boolean>,

  -- Maximum number of particles alive at once (pool size).
  particleCount: Input<number>,

  -- Particles spawned per second while `play` is true.
  spawnRate: Input<number>,

  -- Outward travel speed in pixels per second.
  speed: Input<number>,

  -- How far from the spawn point particles travel before being recycled.
  -- This is the "size" of the spread — bigger values make particles
  -- fly further out before disappearing.
  spreadRadius: Input<number>,

  -- Offset of the spawn point from the center of the layout. Use these
  -- to move where particles are born (e.g. positive originX moves the
  -- spawn point to the right of center, positive originY moves it down).
  originX: Input<number>,
  originY: Input<number>,

  -- The artboard used to render each particle. Swap this with any
  -- artboard in the file (star, leaf, coin, heart, etc) to reuse this
  -- system for a different effect.
  particleArtboard: Input<Artboard<nil>>,

  particles: { Particle },
  spawnAccumulator: number,
  width: number,
  height: number,
}

local function randomRange(min: number, max: number): number
  return min + math.random() * (max - min)
end

-- Grows the particle pool up to `particleCount`, and deactivates any
-- particles beyond the current count (in case it was lowered at runtime).
local function ensurePool(self: ParticleSystemData)
  local target = math.max(0, math.floor(self.particleCount))

  while #self.particles < target do
    table.insert(self.particles, {
      instance = self.particleArtboard:instance(),
      dirX = 1,
      dirY = 0,
      distance = 0,
      speedMultiplier = randomRange(0.85, 1.15),
      active = false,
    })
  end

  for i = target + 1, #self.particles do
    self.particles[i].active = false
  end
end

-- Activates one inactive particle from the pool at the center of the
-- layout, giving it a random outward direction so it spreads evenly in
-- every direction (a full 360 degree circle).
local function spawnParticle(self: ParticleSystemData)
  local target =
    math.min(math.max(0, math.floor(self.particleCount)), #self.particles)

  for i = 1, target do
    local p = self.particles[i]
    if not p.active then
      p.active = true

      local angle = randomRange(0, math.pi * 2)
      p.dirX = math.cos(angle)
      p.dirY = math.sin(angle)
      p.distance = 0
      p.speedMultiplier = randomRange(0.85, 1.15)
      return
    end
  end
end

function init(self: ParticleSystemData, context: Context): boolean
  self.particles = {}
  self.spawnAccumulator = 0
  return true
end

-- Layouts report their allotted size here; we use it to know where the
-- bottom (spawn) and top (recycle) edges are.
function resize(self: ParticleSystemData, size: Vector)
  self.width = size.x
  self.height = size.y
end

-- Provides a sensible default size when this layout is set to "Hug" and has
-- no other content to size itself against, so the system is visible out of
-- the box. If the layout's width/height scale type is set to "Fixed" or
-- "Fill" in the editor, that setting takes priority and this is ignored.
function measure(self: ParticleSystemData): Vector
  return Vector.xy(300, 400)
end

function advance(self: ParticleSystemData, seconds: number): boolean
  ensurePool(self)

  local rate = math.max(0, self.spawnRate)
  if self.play and rate > 0 then
    self.spawnAccumulator = self.spawnAccumulator + seconds * rate
    while self.spawnAccumulator >= 1 do
      spawnParticle(self)
      self.spawnAccumulator = self.spawnAccumulator - 1
    end
  else
    self.spawnAccumulator = 0
  end

  local speed = self.speed
  local radius = math.max(0, self.spreadRadius)
  local target =
    math.min(math.max(0, math.floor(self.particleCount)), #self.particles)

  for i = 1, target do
    local p = self.particles[i]
    if p.active then
      -- Move outward from the center along its direction.
      p.distance = p.distance + speed * p.speedMultiplier * seconds
      p.instance:advance(seconds)

      -- Recycle once it has traveled past the spread radius.
      if p.distance > radius then
        p.active = false
      end
    end
  end

  -- Keep advancing every frame so particles can spawn/recycle continuously.
  return true
end

function draw(self: ParticleSystemData, renderer: Renderer)
  local centerX = self.width * 0.5 + self.originX
  local centerY = self.height * 0.5 + self.originY

  for _, p in ipairs(self.particles) do
    if p.active then
      local x = centerX + p.dirX * p.distance
      local y = centerY + p.dirY * p.distance

      renderer:save()
      renderer:transform(Mat2D.withTranslation(x, y))
      p.instance:draw(renderer)
      renderer:restore()
    end
  end
end

return function(): Layout<ParticleSystemData>
  return {
    play = true,
    particleCount = 20,
    spawnRate = 4,
    speed = 80,
    spreadRadius = 150,
    originX = 0,
    originY = 0,
    particleArtboard = late(),

    particles = {},
    spawnAccumulator = 0,
    width = 100,
    height = 100,

    init = init,
    measure = measure,
    resize = resize,
    advance = advance,
    draw = draw,
  }
end
