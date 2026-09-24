-- ParticlePopUp — Layout
--
-- Burst particle pop-up. Setiap particle adalah instance artboard lain
-- (bintang, coin, hati, spark, dll). Kamu yang tentukan kapan meledak,
-- ke arah mana, gravitasi ke mana, seberapa cepat, seberapa lama, dan
-- berapa banyak.
--
-- Cara pakai di Rive:
--   1. Assets → + → Script → tipe Layout → paste file ini.
--   2. Taruh layout di artboard utama, ukuran sesuai area efek.
--   3. Bind `particleArtboard` ke artboard SATU keping particle.
--      Opsional: `particleArtboardB` untuk variasi visual kedua.
--   4. Trigger pop:
--        • toggle Inspector boolean `pop` (false → true), atau
--        • View Model Trigger bernama `pop`, atau
--        • klik layout (`clickToPop`), atau
--        • `autoPop` / `loop`.
--   5. View Model Trigger `clear` mematikan semua particle yang masih hidup.
--
-- Opsional di View Model keping particle:
--   Number `opacity` / `mainOpacity` (0..1)  → fade in/out
--   Number `life` / `progress` (0..1)        → animasi di dalam keping
--
-- Opsional di View Model host:
--   Number `alive`  → diisi jumlah particle yang sedang tampil
--
-- Sudut: 0 = kanan, -90 = atas, 90 = bawah, 180 = kiri. (Y+ ke bawah)

type Piece = {
  instance: Artboard<nil>,
  x: number,
  y: number,
  vx: number,
  vy: number,
  rotation: number,
  spin: number,
  baseScale: number,
  flipX: number,
  flipY: number,
  age: number,
  lifetime: number,
  spawnWait: number,
  fallWait: number,
  bornAt: number,
  seed: number,
  cx: number,
  cy: number,
  active: boolean,
}

type ParticlePopUpData = {
  -- Artboard visual tiap particle. Wajib di-bind.
  particleArtboard: Input<Artboard<nil>>,
  -- Artboard kedua (opsional). Dipakai acak menurut `artboardMix`.
  particleArtboardB: Input<Artboard<nil>>,
  -- 0 = selalu A, 1 = selalu B, 0.5 = 50/50.
  artboardMix: Input<number>,

  -- Jumlah particle per pop (juga ukuran pool).
  count: Input<number>,

  -- Rising edge (false → true) menembakkan pop. Tahan true tidak retrigger.
  pop: Input<boolean>,
  -- Pop otomatis sekali setelah init (tetap hormati `popDelay`).
  autoPop: Input<boolean>,
  -- Pop berulang setiap `loopInterval` detik.
  loop: Input<boolean>,
  loopInterval: Input<number>,
  -- Delay detik setelah trigger sebelum particle pertama terbang.
  popDelay: Input<number>,
  -- Master on/off. False = tidak spawn baru; yang sudah terbang tetap jalan.
  enabled: Input<boolean>,

  -- Arah tembak dalam derajat. -90 = naik, 0 = kanan, 90 = turun.
  burstAngle: Input<number>,
  -- Lebar kerucut derajat di sekitar burstAngle. 0 = garis, 360 = lingkaran.
  spreadAngle: Input<number>,
  -- true = sebar merata di kerucut, false = acak.
  evenSpread: Input<boolean>,
  -- Kecepatan awal pop, pixel per detik.
  burstSpeed: Input<number>,
  -- Random extra speed 0..1 (0.3 = ±30%).
  speedJitter: Input<number>,

  -- Kekuatan gravitasi, pixel/detik². 0 = tanpa gravitasi.
  gravity: Input<number>,
  -- Arah gravitasi derajat. 90 = ke bawah, -90 = ke atas, 0 = ke kanan.
  gravityAngle: Input<number>,
  -- Detik particle terbang dulu sebelum gravitasi mulai menarik.
  gravityDelay: Input<number>,

  -- Lama hidup particle setelah muncul, detik. Ini "panjang" pop-nya.
  lifetime: Input<number>,
  -- Random extra lifetime 0..1.
  lifetimeJitter: Input<number>,

  -- Offset spawn dari pusat layout. +X kanan, +Y bawah.
  originX: Input<number>,
  originY: Input<number>,
  -- Area spawn. 0,0 = titik. Box / circle / ring menurut `emitterShape`.
  emitterWidth: Input<number>,
  emitterHeight: Input<number>,
  -- 0 = box, 1 = circle, 2 = ring (tepi lingkaran).
  emitterShape: Input<number>,
  -- Jeda detik antar particle dalam 1 gelombang (0 = serentak).
  stagger: Input<number>,
  -- Pecah 1 pop jadi beberapa gelombang.
  burstWaves: Input<number>,
  -- Jeda detik antar gelombang.
  waveDelay: Input<number>,
  -- true = pop baru tidak mematikan particle lama (bisa tumpuk).
  additive: Input<boolean>,

  -- Angin: kekuatan (px/s²) + arah derajat.
  wind: Input<number>,
  windAngle: Input<number>,
  -- Drag udara 0..1. Tinggi = cepat melambat.
  drag: Input<number>,
  -- Goyangan acak (px/s²). Hidupkan untuk debu / spark organik.
  turbulence: Input<number>,
  turbulenceSpeed: Input<number>,
  -- Percepatan menjauh (+) / ke dalam (−) dari origin, px/s².
  radialAccel: Input<number>,
  -- Percepatan tegak lurus (pusaran / swirl), px/s².
  tangentialAccel: Input<number>,
  -- Pantul di tepi layout.
  bounce: Input<boolean>,
  -- 0..1, sisa kecepatan setelah pantul. 1 = elastis.
  bounceDamp: Input<number>,
  -- Matikan particle yang keluar dari layout.
  killOffscreen: Input<boolean>,

  -- Skala acak tiap keping (relatif ukuran artboard sumber).
  minScale: Input<number>,
  maxScale: Input<number>,
  -- Pengali skala di awal hidup (0.2 = muncul dari kecil).
  startScale: Input<number>,
  -- Pengali skala di akhir hidup (0 = menyusut hilang).
  endScale: Input<number>,
  -- Overshoot pop (1 = tidak, 1.45 = membesar 45% lalu settle).
  popOvershoot: Input<number>,
  -- Detik sampai puncak overshoot, lalu settle.
  popOvershootTime: Input<number>,
  -- Stetch sepanjang arah gerak. 0 = off. 0.002 = halus.
  stretch: Input<number>,
  -- Spin derajat per detik. Tanda diacak per keping.
  spin: Input<number>,
  spinJitter: Input<number>,
  -- true = rotasi mengikuti arah kecepatan.
  alignToVelocity: Input<boolean>,
  -- Offset derajat kalau artboard tidak menghadap kanan.
  alignOffset: Input<number>,
  -- Acak flip horizontal / vertikal.
  randomFlip: Input<boolean>,
  -- Progress hidup 0..1 saat fade-in selesai. 0 = langsung full.
  fadeInEnd: Input<number>,
  -- Progress hidup 0..1 saat fade-out mulai. 1 = tidak fade, langsung hilang.
  fadeStart: Input<number>,
  -- true = instance artboard di-reset tiap spawn (animasi keping mulai dari 0).
  restartAnim: Input<boolean>,
  -- true = particle baru digambar di atas yang lama.
  newestOnTop: Input<boolean>,

  -- Klik layout = pop. Kalau `clickSetsOrigin`, spawn di posisi klik.
  clickToPop: Input<boolean>,
  clickSetsOrigin: Input<boolean>,
  -- 0 = acak tiap kali. Angka lain = burst reproducible.
  seed: Input<number>,
  -- Slow-mo / fast-forward simulasi. 1 = normal.
  timeScale: Input<number>,

  pieces: { Piece },
  width: number,
  height: number,

  _artboardRef: Artboard<nil>?,
  _artboardBRef: Artboard<nil>?,
  _wasPop: boolean,
  _pendingPop: boolean,
  _popWait: number,
  _loopWait: number,
  _didAutoPop: boolean,
  _time: number,
  _rngState: number,
  _burstIndex: number,
  _useClickOrigin: boolean,
  _originOverrideX: number,
  _originOverrideY: number,
  _vm: ViewModel?,
  _popTrigger: any,
  _clearTrigger: any,
  _aliveNumber: any,
}

local DEG = math.pi / 180
local MAX_PARTICLES = 256
local OFFSCREEN_MARGIN = 48

local function clamp(v: number, lo: number, hi: number): number
  if v < lo then
    return lo
  end
  if v > hi then
    return hi
  end
  return v
end

local function lerp(a: number, b: number, t: number): number
  return a + (b - a) * t
end

local function nextRand(self: ParticlePopUpData): number
  if self.seed == 0 then
    return math.random()
  end
  self._rngState = (self._rngState * 1664525 + 1013904223) % 4294967296
  return self._rngState / 4294967296
end

local function randomRange(
  self: ParticlePopUpData,
  min: number,
  max: number
): number
  return min + nextRand(self) * (max - min)
end

local function setPieceNumber(
  ab: Artboard<nil>,
  names: { string },
  value: number
)
  local data = ab.data :: any
  if not data then
    return
  end
  for i = 1, #names do
    local n = data:getNumber(names[i])
    if n then
      n.value = value
      return
    end
  end
end

local function setPieceOpacity(ab: Artboard<nil>, opacity01: number)
  setPieceNumber(ab, { 'opacity', 'mainOpacity' }, opacity01)
end

local function setPieceLife(ab: Artboard<nil>, life01: number)
  setPieceNumber(ab, { 'life', 'progress' }, life01)
end

local function pieceTransform(
  x: number,
  y: number,
  rotation: number,
  sx: number,
  sy: number,
  hw: number,
  hh: number
): Mat2D
  local c = math.cos(rotation)
  local s = math.sin(rotation)
  local rot = Mat2D.values(c, s, -s, c, 0, 0)
  return Mat2D.withTranslation(x, y)
    * rot
    * Mat2D.withScale(sx, sy)
    * Mat2D.withTranslation(-hw, -hh)
end

local function pickArtboard(self: ParticlePopUpData): Artboard<nil>?
  local a = self.particleArtboard
  local b = self.particleArtboardB
  if b and nextRand(self) < clamp(self.artboardMix, 0, 1) then
    return b
  end
  return a
end

local function syncArtboard(self: ParticlePopUpData)
  if
    self.particleArtboard ~= self._artboardRef
    or self.particleArtboardB ~= self._artboardBRef
  then
    self._artboardRef = self.particleArtboard
    self._artboardBRef = self.particleArtboardB
    self.pieces = {}
  end
end

local function poolCap(self: ParticlePopUpData): number
  local count = math.clamp(math.floor(self.count), 0, MAX_PARTICLES)
  if self.additive then
    return math.min(MAX_PARTICLES, math.max(count, count * 3))
  end
  return count
end

local function makePiece(self: ParticlePopUpData): Piece?
  local src = self.particleArtboard
  if not src then
    return nil
  end
  return {
    instance = src:instance(),
    x = 0,
    y = 0,
    vx = 0,
    vy = 0,
    rotation = 0,
    spin = 0,
    baseScale = 1,
    flipX = 1,
    flipY = 1,
    age = 0,
    lifetime = 1,
    spawnWait = 0,
    fallWait = 0,
    bornAt = 0,
    seed = 0,
    cx = 0,
    cy = 0,
    active = false,
  }
end

local function ensurePool(self: ParticlePopUpData)
  if not self.particleArtboard then
    return
  end

  local target = poolCap(self)
  while #self.pieces < target do
    local p = makePiece(self)
    if not p then
      return
    end
    table.insert(self.pieces, p)
  end

  for i = target + 1, #self.pieces do
    self.pieces[i].active = false
  end
end

local function spawnPosition(self: ParticlePopUpData): (number, number)
  local ox = self.width * 0.5 + self.originX
  local oy = self.height * 0.5 + self.originY
  if self._useClickOrigin then
    ox = self._originOverrideX
    oy = self._originOverrideY
  end

  local ew = math.max(0, self.emitterWidth)
  local eh = math.max(0, self.emitterHeight)
  local shape = math.floor(self.emitterShape + 0.5)

  if shape <= 0 then
    return ox + randomRange(self, -ew, ew) * 0.5,
      oy + randomRange(self, -eh, eh) * 0.5
  end

  local rx = math.max(ew, eh) * 0.5
  if rx <= 0 then
    return ox, oy
  end

  local angle = randomRange(self, 0, math.pi * 2)
  local r = rx
  if shape == 1 then
    r = rx * math.sqrt(nextRand(self))
  end
  local aspect = 1
  if eh > 0.001 and ew > 0.001 then
    aspect = eh / ew
  end
  return ox + math.cos(angle) * r, oy + math.sin(angle) * r * aspect
end

local function armPiece(
  self: ParticlePopUpData,
  p: Piece,
  index: number,
  total: number
)
  if self.restartAnim or not p.instance then
    local src = pickArtboard(self)
    if src then
      p.instance = src:instance()
    end
  end

  p.x, p.y = spawnPosition(self)
  p.cx = p.x
  p.cy = p.y

  local halfSpread = math.max(0, self.spreadAngle) * 0.5 * DEG
  local angle
  if self.evenSpread and total > 1 then
    local t = (index - 0.5) / total
    angle = self.burstAngle * DEG + (t - 0.5) * self.spreadAngle * DEG
  else
    angle = self.burstAngle * DEG + randomRange(self, -halfSpread, halfSpread)
  end

  local jitter = clamp(self.speedJitter, 0, 1)
  local speed = math.max(0, self.burstSpeed)
    * randomRange(self, 1 - jitter, 1 + jitter)
  p.vx = math.cos(angle) * speed
  p.vy = math.sin(angle) * speed

  local spinJitter = clamp(self.spinJitter, 0, 1)
  local spinDeg = self.spin * randomRange(self, 1 - spinJitter, 1 + spinJitter)
  if nextRand(self) < 0.5 then
    spinDeg = -spinDeg
  end
  p.spin = spinDeg * DEG

  if self.alignToVelocity then
    p.rotation = math.atan2(p.vy, p.vx) + self.alignOffset * DEG
  else
    p.rotation = randomRange(self, 0, math.pi * 2)
  end

  local minS = math.max(0.01, self.minScale)
  local maxS = math.max(minS, self.maxScale)
  p.baseScale = randomRange(self, minS, maxS)

  p.flipX = 1
  p.flipY = 1
  if self.randomFlip then
    if nextRand(self) < 0.5 then
      p.flipX = -1
    end
    if nextRand(self) < 0.5 then
      p.flipY = -1
    end
  end

  local lifeJitter = clamp(self.lifetimeJitter, 0, 1)
  p.lifetime = math.max(0.05, self.lifetime)
    * randomRange(self, 1 - lifeJitter, 1 + lifeJitter)
  p.age = 0
  p.bornAt = self._time
  p.seed = nextRand(self) * 1000
  p.fallWait = math.max(0, self.gravityDelay)
  p.active = true

  local waves = math.max(1, math.floor(self.burstWaves + 0.5))
  local perWave = math.max(1, math.ceil(total / waves))
  local waveIndex = math.floor((index - 1) / perWave)
  local indexInWave = (index - 1) % perWave
  p.spawnWait = math.max(0, self.stagger) * indexInWave
    + math.max(0, self.waveDelay) * waveIndex

  setPieceOpacity(p.instance, 0)
  setPieceLife(p.instance, 0)
end

local function takeFreePiece(self: ParticlePopUpData, cap: number): Piece?
  local oldest: Piece? = nil
  local oldestBorn = math.huge

  for i = 1, cap do
    local p = self.pieces[i]
    if p and not p.active then
      return p
    end
    if p and p.bornAt < oldestBorn then
      oldestBorn = p.bornAt
      oldest = p
    end
  end

  return oldest
end

local function fireBurst(self: ParticlePopUpData)
  ensurePool(self)
  if not self.particleArtboard then
    return
  end

  self._burstIndex += 1
  if self.seed ~= 0 then
    self._rngState = math.abs(self.seed) * 9973 + self._burstIndex * 7919
  end

  local count = math.clamp(math.floor(self.count), 0, MAX_PARTICLES)
  local cap = math.min(poolCap(self), #self.pieces)

  if not self.additive then
    for i = 1, #self.pieces do
      self.pieces[i].active = false
    end
    local n = math.min(count, cap)
    for i = 1, n do
      armPiece(self, self.pieces[i], i, n)
    end
  else
    for i = 1, count do
      local p = takeFreePiece(self, cap)
      if p then
        armPiece(self, p, i, count)
      end
    end
  end

  self._loopWait = math.max(0.05, self.loopInterval)
  self._useClickOrigin = false
end

local function requestPop(self: ParticlePopUpData)
  if not self.enabled then
    return
  end
  self._pendingPop = true
  self._popWait = math.max(0, self.popDelay)
end

local function clearAll(self: ParticlePopUpData)
  for i = 1, #self.pieces do
    self.pieces[i].active = false
  end
  self._pendingPop = false
end

local function bindHostVm(self: ParticlePopUpData, context: Context)
  local vm = context:viewModel()
  if not vm then
    return
  end

  local popTrigger = vm:getTrigger('pop')
  if popTrigger then
    popTrigger:addListener(function()
      requestPop(self)
    end)
  end

  local clearTrigger = vm:getTrigger('clear')
  if clearTrigger then
    clearTrigger:addListener(function()
      clearAll(self)
    end)
  end

  self._vm = vm
  self._popTrigger = popTrigger
  self._clearTrigger = clearTrigger
  self._aliveNumber = vm:getNumber('alive')
end

local function overshootMul(
  age: number,
  peakTime: number,
  amount: number
): number
  if peakTime <= 0 or amount <= 1 then
    return 1
  end
  local t = age / peakTime
  if t >= 2 then
    return 1
  end
  if t < 1 then
    return 1 + (amount - 1) * t
  end
  return amount + (1 - amount) * (t - 1)
end

local function lifeOpacity(
  t: number,
  fadeInEnd: number,
  fadeStart: number
): number
  local fadeIn = clamp(fadeInEnd, 0, 1)
  local fadeOut = clamp(fadeStart, 0, 1)
  if fadeOut < fadeIn then
    fadeOut = fadeIn
  end

  local op = 1
  if fadeIn > 0 and t < fadeIn then
    op = t / fadeIn
  end
  if fadeOut < 1 and t > fadeOut then
    op = op * (1 - (t - fadeOut) / (1 - fadeOut))
  end
  return clamp(op, 0, 1)
end

function init(self: ParticlePopUpData, context: Context): boolean
  self.pieces = {}
  self._artboardRef = self.particleArtboard
  self._artboardBRef = self.particleArtboardB
  self._wasPop = self.pop
  self._pendingPop = false
  self._popWait = 0
  self._loopWait = 0
  self._didAutoPop = false
  self._time = 0
  self._rngState = math.abs(self.seed)
  self._burstIndex = 0
  self._useClickOrigin = false
  self._originOverrideX = 0
  self._originOverrideY = 0
  bindHostVm(self, context)
  return true
end

function resize(self: ParticlePopUpData, size: Vector)
  self.width = size.x
  self.height = size.y
end

function measure(self: ParticlePopUpData): Vector
  return Vector.xy(400, 400)
end

function update(self: ParticlePopUpData)
  if self.pop and not self._wasPop then
    requestPop(self)
  end
  self._wasPop = self.pop
end

function pointerDown(self: ParticlePopUpData, event: PointerEvent)
  if not self.clickToPop or not self.enabled then
    return
  end
  if self.clickSetsOrigin then
    self._useClickOrigin = true
    self._originOverrideX = event.position.x
    self._originOverrideY = event.position.y
  end
  requestPop(self)
  event:hit()
end

function advance(self: ParticlePopUpData, seconds: number): boolean
  local dt = math.min(math.max(0, seconds * math.max(0, self.timeScale)), 0.05)
  self._time += dt

  syncArtboard(self)
  ensurePool(self)

  if self.enabled and self.autoPop and not self._didAutoPop then
    self._didAutoPop = true
    requestPop(self)
  end

  if self._pendingPop then
    self._popWait -= dt
    if self._popWait <= 0 then
      self._pendingPop = false
      fireBurst(self)
    end
  elseif self.enabled and self.loop then
    self._loopWait -= dt
    if self._loopWait <= 0 then
      requestPop(self)
    end
  end

  local g = self.gravity
  local gAng = self.gravityAngle * DEG
  local gx = math.cos(gAng) * g
  local gy = math.sin(gAng) * g

  local w = self.wind
  local wAng = self.windAngle * DEG
  local wx = math.cos(wAng) * w
  local wy = math.sin(wAng) * w

  local drag = clamp(self.drag, 0, 1)
  local dragFactor = 1 - drag * dt
  if dragFactor < 0 then
    dragFactor = 0
  end

  local turb = self.turbulence
  local turbSpeed = self.turbulenceSpeed
  local radial = self.radialAccel
  local tangential = self.tangentialAccel
  local bounceOn = self.bounce
  local bounceDamp = clamp(self.bounceDamp, 0, 1)
  local killOff = self.killOffscreen
  local fadeInEnd = self.fadeInEnd
  local fadeStart = self.fadeStart
  local cap = math.min(poolCap(self), #self.pieces)
  local alive = 0

  for i = 1, cap do
    local p = self.pieces[i]
    if p.active then
      if p.spawnWait > 0 then
        p.spawnWait -= dt
      else
        p.age += dt
        p.instance:advance(dt)

        local ax = 0
        local ay = 0
        if p.fallWait > 0 then
          p.fallWait -= dt
        else
          ax += gx + wx
          ay += gy + wy
        end

        if turb ~= 0 then
          local ts = p.seed + p.age * turbSpeed
          ax += math.sin(ts) * turb
          ay += math.cos(ts * 1.31) * turb
        end

        if radial ~= 0 or tangential ~= 0 then
          local dx = p.x - p.cx
          local dy = p.y - p.cy
          local len = math.sqrt(dx * dx + dy * dy)
          if len > 0.001 then
            local nx = dx / len
            local ny = dy / len
            ax += nx * radial - ny * tangential
            ay += ny * radial + nx * tangential
          end
        end

        p.vx = (p.vx + ax * dt) * dragFactor
        p.vy = (p.vy + ay * dt) * dragFactor
        p.x += p.vx * dt
        p.y += p.vy * dt

        if self.alignToVelocity then
          local spd = p.vx * p.vx + p.vy * p.vy
          if spd > 4 then
            p.rotation = math.atan2(p.vy, p.vx) + self.alignOffset * DEG
          end
        else
          p.rotation += p.spin * dt
        end

        if bounceOn then
          if p.x < 0 then
            p.x = 0
            p.vx = math.abs(p.vx) * bounceDamp
          elseif p.x > self.width then
            p.x = self.width
            p.vx = -math.abs(p.vx) * bounceDamp
          end
          if p.y < 0 then
            p.y = 0
            p.vy = math.abs(p.vy) * bounceDamp
          elseif p.y > self.height then
            p.y = self.height
            p.vy = -math.abs(p.vy) * bounceDamp
          end
        elseif
          killOff
          and (
            p.x < -OFFSCREEN_MARGIN
            or p.y < -OFFSCREEN_MARGIN
            or p.x > self.width + OFFSCREEN_MARGIN
            or p.y > self.height + OFFSCREEN_MARGIN
          )
        then
          p.active = false
        end

        if p.active then
          if p.age >= p.lifetime then
            p.active = false
          else
            local t = clamp(p.age / p.lifetime, 0, 1)
            setPieceOpacity(p.instance, lifeOpacity(t, fadeInEnd, fadeStart))
            setPieceLife(p.instance, t)
            alive += 1
          end
        end
      end
    end
  end

  if self._aliveNumber then
    self._aliveNumber.value = alive
  end

  return true
end

local function drawPiece(
  renderer: Renderer,
  p: Piece,
  startScale: number,
  endScale: number,
  popAmt: number,
  popTime: number,
  stretch: number
)
  if not (p.active and p.spawnWait <= 0) then
    return
  end
  local inst = p.instance
  local hw = inst.width * 0.5
  local hh = inst.height * 0.5
  local t = clamp(p.age / p.lifetime, 0, 1)
  local scale = p.baseScale
    * lerp(startScale, endScale, t)
    * overshootMul(p.age, popTime, popAmt)
  local sx = scale * p.flipX
  local sy = scale * p.flipY
  if stretch > 0 then
    local spd = math.sqrt(p.vx * p.vx + p.vy * p.vy)
    sx = sx * (1 + spd * stretch)
  end

  renderer:save()
  renderer:transform(pieceTransform(p.x, p.y, p.rotation, sx, sy, hw, hh))
  inst:draw(renderer)
  renderer:restore()
end

function draw(self: ParticlePopUpData, renderer: Renderer)
  local cap = math.min(poolCap(self), #self.pieces)
  local startScale = self.startScale
  local endScale = self.endScale
  local popAmt = math.max(1, self.popOvershoot)
  local popTime = math.max(0, self.popOvershootTime)
  local stretch = math.max(0, self.stretch)

  if self.newestOnTop then
    for i = cap, 1, -1 do
      drawPiece(
        renderer,
        self.pieces[i],
        startScale,
        endScale,
        popAmt,
        popTime,
        stretch
      )
    end
  else
    for i = 1, cap do
      drawPiece(
        renderer,
        self.pieces[i],
        startScale,
        endScale,
        popAmt,
        popTime,
        stretch
      )
    end
  end
end

return function(): Layout<ParticlePopUpData>
  return {
    particleArtboard = late(),
    particleArtboardB = late(),
    artboardMix = 0.5,
    count = 28,

    pop = false,
    autoPop = false,
    loop = false,
    loopInterval = 1.6,
    popDelay = 0,
    enabled = true,

    burstAngle = -90,
    spreadAngle = 55,
    evenSpread = false,
    burstSpeed = 460,
    speedJitter = 0.35,

    gravity = 980,
    gravityAngle = 90,
    gravityDelay = 0.08,

    lifetime = 1.35,
    lifetimeJitter = 0.2,

    originX = 0,
    originY = 0,
    emitterWidth = 10,
    emitterHeight = 10,
    emitterShape = 0,
    stagger = 0.008,
    burstWaves = 1,
    waveDelay = 0.06,
    additive = true,

    wind = 0,
    windAngle = 0,
    drag = 0.28,
    turbulence = 0,
    turbulenceSpeed = 8,
    radialAccel = 0,
    tangentialAccel = 0,
    bounce = false,
    bounceDamp = 0.45,
    killOffscreen = false,

    minScale = 0.55,
    maxScale = 1.15,
    startScale = 0.35,
    endScale = 0.7,
    popOvershoot = 1.35,
    popOvershootTime = 0.12,
    stretch = 0,
    spin = 380,
    spinJitter = 0.5,
    alignToVelocity = false,
    alignOffset = 0,
    randomFlip = true,
    fadeInEnd = 0.06,
    fadeStart = 0.62,
    restartAnim = true,
    newestOnTop = true,

    clickToPop = false,
    clickSetsOrigin = true,
    seed = 0,
    timeScale = 1,

    pieces = {},
    width = 100,
    height = 100,
    _artboardRef = nil,
    _artboardBRef = nil,
    _wasPop = false,
    _pendingPop = false,
    _popWait = 0,
    _loopWait = 0,
    _didAutoPop = false,
    _time = 0,
    _rngState = 0,
    _burstIndex = 0,
    _useClickOrigin = false,
    _originOverrideX = 0,
    _originOverrideY = 0,
    _vm = nil,
    _popTrigger = nil,
    _clearTrigger = nil,
    _aliveNumber = nil,

    init = init,
    measure = measure,
    resize = resize,
    update = update,
    pointerDown = pointerDown,
    advance = advance,
    draw = draw,
  }
end
