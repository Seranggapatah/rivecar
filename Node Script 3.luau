-- CoinBurst — Layout
--
-- Koin muncul dari satu titik, menyebar rata membentuk lingkaran, berhenti
-- sebentar, lalu semuanya terbang berkumpul ke titik lain (default: naik).
-- Tiap koin adalah instance artboard lain.
--
-- Cara pakai di Rive:
--   1. Assets → + → Script → tipe Layout → paste file ini.
--   2. Taruh layout di artboard. Ukuran layout harus menutup titik muncul
--      DAN titik kumpul, supaya koin tidak kepotong.
--   3. Bind `coinArtboard` ke artboard SATU keping koin.
--      Kalau belum di-bind, lingkaran emas dipakai sebagai preview.
--   4. Nyalakan `play` (false → true) untuk sekali putar.
--      Tahan true tidak mengulang. Matikan lalu nyalakan lagi, atau hidupkan `loop`.
--      View Model Trigger bernama `play` juga bisa menembak efek yang sama.
--   5. `count` = jumlah koin.
--   6. `originX` / `originY` = titik muncul. `gatherX` / `gatherY` = titik kumpul.
--      Keduanya offset dari tengah layout. +X kanan, +Y bawah.
--      Supaya koin "naik", `gatherY` harus lebih kecil dari `originY`.
--
-- Koin menyusut dan memudar sendiri saat masuk ke titik kumpul, lalu hilang.
-- Opsional di View Model artboard koin:
--   Number `opacity` / `mainOpacity` (0..1) → ikut diisi 0..1 kalau animasi koin butuh.

type Coin = {
  instance: Artboard<nil>?,
  radiusMul: number,
  scale: number,
  spin: number,
  rotation: number,
  x: number,
  y: number,
  drawScale: number,
  opacity: number,
}

type CoinBurstData = {
  -- Artboard visual tiap koin.
  coinArtboard: Input<Artboard<nil>>,

  -- Jumlah koin dalam satu putaran.
  count: Input<number>,

  -- Rising edge (false → true) memulai efek. Tahan true tidak mengulang.
  play: Input<boolean>,
  -- Ulangi terus. Jeda setelah koin sampai, sebelum putaran berikutnya.
  loop: Input<boolean>,
  loopDelay: Input<number>,
  -- true = instance artboard dibuat ulang tiap putaran (animasi koin mulai dari 0).
  restartAnim: Input<boolean>,

  -- Titik muncul, offset dari tengah layout. +X kanan, +Y bawah.
  originX: Input<number>,
  originY: Input<number>,
  -- Titik kumpul, offset yang sama. Nilai Y lebih kecil = lebih ke atas.
  gatherX: Input<number>,
  gatherY: Input<number>,

  -- Jari-jari lingkaran sebar, dalam pixel.
  spreadRadius: Input<number>,
  -- 0 = lingkaran sempurna. 0.2 = tiap koin ±20% jari-jari.
  radiusJitter: Input<number>,
  -- Putar seluruh lingkaran, derajat. -90 = satu koin di atas.
  startAngle: Input<number>,

  -- Lama menyebar, berhenti, dan terbang ke titik kumpul (detik).
  spreadTime: Input<number>,
  holdTime: Input<number>,
  collectTime: Input<number>,

  -- Lengkungan saat terbang ke titik kumpul, pixel. 0 = garis lurus.
  arc: Input<number>,

  -- Skala acak tiap koin, relatif ukuran artboard sumber.
  minScale: Input<number>,
  maxScale: Input<number>,
  -- Skala di titik kumpul, pengali dari skala koin. 0.2 = menyusut jadi 20%.
  endScale: Input<number>,
  -- Putar koin, derajat per detik. Berhenti saat fase diam. Tanda diacak.
  spin: Input<number>,

  coins: { Coin },
  width: number,
  height: number,

  _artRef: Artboard<nil>?,
  _phase: string,
  _phaseTime: number,
  _wasPlay: boolean,
  _pending: boolean,
  _loopWait: number,
  _vm: ViewModel?,
  _playTrigger: any,
  _coinPath: Path?,
  _coinPaint: Paint?,
}

local DEG = math.pi / 180
local TWO_PI = math.pi * 2
local MAX_COINS = 96
local CIRCLE_K = 0.5522847498307936

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

local function easeOutCubic(t: number): number
  local u = 1 - t
  return 1 - u * u * u
end

local function easeInOutCubic(t: number): number
  if t < 0.5 then
    return 4 * t * t * t
  end
  local u = -2 * t + 2
  return 1 - (u * u * u) / 2
end

local function addCircle(path: Path, cx: number, cy: number, radius: number)
  local k = radius * CIRCLE_K
  path:moveTo(Vector.xy(cx + radius, cy))
  path:cubicTo(
    Vector.xy(cx + radius, cy + k),
    Vector.xy(cx + k, cy + radius),
    Vector.xy(cx, cy + radius)
  )
  path:cubicTo(
    Vector.xy(cx - k, cy + radius),
    Vector.xy(cx - radius, cy + k),
    Vector.xy(cx - radius, cy)
  )
  path:cubicTo(
    Vector.xy(cx - radius, cy - k),
    Vector.xy(cx - k, cy - radius),
    Vector.xy(cx, cy - radius)
  )
  path:cubicTo(
    Vector.xy(cx + k, cy - radius),
    Vector.xy(cx + radius, cy - k),
    Vector.xy(cx + radius, cy)
  )
  path:close()
end

local function setPieceOpacity(ab: Artboard<nil>, opacity01: number)
  local data = ab.data :: any
  if not data then
    return
  end
  local op = data:getNumber('opacity') or data:getNumber('mainOpacity')
  if op then
    op.value = opacity01
  end
end

local function coinTransform(
  x: number,
  y: number,
  rotation: number,
  scale: number,
  hw: number,
  hh: number
): Mat2D
  local c = math.cos(rotation)
  local s = math.sin(rotation)
  local rot = Mat2D.values(c, s, -s, c, 0, 0)
  return Mat2D.withTranslation(x, y)
    * rot
    * Mat2D.withScale(scale, scale)
    * Mat2D.withTranslation(-hw, -hh)
end

local function coinCount(self: CoinBurstData): number
  return math.clamp(math.floor(self.count), 0, MAX_COINS)
end

local function originPoint(self: CoinBurstData): (number, number)
  return self.width * 0.5 + self.originX, self.height * 0.5 + self.originY
end

local function gatherPoint(self: CoinBurstData): (number, number)
  return self.width * 0.5 + self.gatherX, self.height * 0.5 + self.gatherY
end

local function ringAngle(
  self: CoinBurstData,
  index: number,
  total: number
): number
  local n = total
  if n < 1 then
    n = 1
  end
  return self.startAngle * DEG + ((index - 1) / n) * TWO_PI
end

local function syncArtboard(self: CoinBurstData)
  if self.coinArtboard ~= self._artRef then
    self._artRef = self.coinArtboard
    self.coins = {}
  end
end

local function ensurePool(self: CoinBurstData)
  local art = self.coinArtboard
  local target = coinCount(self)

  while #self.coins < target do
    local inst: Artboard<nil>? = nil
    if art then
      inst = art:instance()
    end
    table.insert(self.coins, {
      instance = inst,
      radiusMul = 1,
      scale = 1,
      spin = 0,
      rotation = 0,
      x = 0,
      y = 0,
      drawScale = 1,
      opacity = 1,
    })
  end
end

local function armCoins(self: CoinBurstData)
  ensurePool(self)
  local n = math.min(coinCount(self), #self.coins)
  local jitter = clamp(self.radiusJitter, 0, 0.85)
  local minS = math.max(0.05, self.minScale)
  local maxS = math.max(minS, self.maxScale)
  local spin = self.spin * DEG
  local art = self.coinArtboard

  for i = 1, n do
    local c = self.coins[i]
    if self.restartAnim and art then
      c.instance = art:instance()
    end

    c.radiusMul = 1 + (math.random() * 2 - 1) * jitter
    if c.radiusMul < 0.25 then
      c.radiusMul = 0.25
    end
    c.scale = minS + math.random() * (maxS - minS)

    local dir = 1
    if math.random() < 0.5 then
      dir = -1
    end
    c.spin = spin * dir * (0.7 + math.random() * 0.6)
    c.rotation = math.random() * TWO_PI
    if c.instance then
      setPieceOpacity(c.instance, 1)
    end
  end
end

local function startBurst(self: CoinBurstData)
  if coinCount(self) <= 0 then
    return
  end
  armCoins(self)
  self._phase = 'spread'
  self._phaseTime = 0
end

local function advancePhase(self: CoinBurstData)
  for _ = 1, 3 do
    if self._phase == 'spread' then
      local dur = math.max(0, self.spreadTime)
      if self._phaseTime >= dur then
        self._phaseTime -= dur
        self._phase = 'hold'
      else
        return
      end
    elseif self._phase == 'hold' then
      local dur = math.max(0, self.holdTime)
      if self._phaseTime >= dur then
        self._phaseTime -= dur
        self._phase = 'collect'
      else
        return
      end
    elseif self._phase == 'collect' then
      local dur = math.max(0, self.collectTime)
      if self._phaseTime >= dur then
        self._phase = 'idle'
        self._phaseTime = 0
        self._loopWait = math.max(0, self.loopDelay)
      end
      return
    else
      return
    end
  end
end

-- Posisi koin dari fase yang sedang jalan. Spread mendarat di lingkaran,
-- hold diam di situ, collect melengkung ke titik kumpul sambil menyusut.
local function sampleCoin(
  self: CoinBurstData,
  index: number,
  total: number,
  c: Coin
): (number, number, number, number)
  local ox, oy = originPoint(self)
  local radius = math.max(0, self.spreadRadius) * c.radiusMul
  local ang = ringAngle(self, index, total)
  local sx = ox + math.cos(ang) * radius
  local sy = oy + math.sin(ang) * radius
  local base = c.scale

  if self._phase == 'spread' then
    local t = 1
    if self.spreadTime > 0 then
      t = clamp(self._phaseTime / self.spreadTime, 0, 1)
    end
    local e = easeOutCubic(t)
    return lerp(ox, sx, e), lerp(oy, sy, e), lerp(base * 0.2, base, e), 1
  end

  if self._phase == 'hold' then
    return sx, sy, base, 1
  end

  local t = 1
  if self.collectTime > 0 then
    t = clamp(self._phaseTime / self.collectTime, 0, 1)
  end
  local e = easeInOutCubic(t)
  local gx, gy = gatherPoint(self)
  local x = lerp(sx, gx, e)
  local y = lerp(sy, gy, e)

  local dx = gx - sx
  local dy = gy - sy
  local len = math.sqrt(dx * dx + dy * dy)
  if len > 0.001 and self.arc ~= 0 then
    local px = -dy / len
    local py = dx / len
    local side = 1
    local cross = (sx - ox) * dy - (sy - oy) * dx
    if cross < 0 then
      side = -1
    end
    local bend = math.sin(t * math.pi) * self.arc * side
    x += px * bend
    y += py * bend
  end

  local endMul = math.max(0, self.endScale)
  local scale = lerp(base, base * endMul, e)
  local opacity = 1
  local fadeAt = 0.72
  if t > fadeAt then
    opacity = 1 - (t - fadeAt) / (1 - fadeAt)
  end
  return x, y, scale, clamp(opacity, 0, 1)
end

local function bindPlayTrigger(self: CoinBurstData, context: Context)
  local vm = context:viewModel()
  if not vm then
    return
  end
  local playTrigger = vm:getTrigger('play')
  if playTrigger then
    playTrigger:addListener(function()
      self._pending = true
    end)
  end
  self._vm = vm
  self._playTrigger = playTrigger
end

function init(self: CoinBurstData, context: Context): boolean
  self.coins = {}
  self._artRef = self.coinArtboard
  self._phase = 'idle'
  self._phaseTime = 0
  self._wasPlay = false
  self._pending = false
  self._loopWait = 0
  self.width = 100
  self.height = 100

  local path = Path.new()
  addCircle(path, 0, 0, 8)
  self._coinPath = path
  self._coinPaint =
    Paint.with({ style = 'fill', color = Color.rgba(244, 188, 52, 255) })

  bindPlayTrigger(self, context)
  return true
end

function resize(self: CoinBurstData, size: Vector)
  self.width = size.x
  self.height = size.y
end

function measure(self: CoinBurstData): Vector
  return Vector.xy(400, 400)
end

function advance(self: CoinBurstData, seconds: number): boolean
  local dt = math.min(math.max(0, seconds), 0.05)

  syncArtboard(self)
  ensurePool(self)

  local started = false
  if self._pending or (self.play and not self._wasPlay) then
    self._pending = false
    startBurst(self)
    started = true
  end
  self._wasPlay = self.play

  if not started and self._phase == 'idle' and self.loop then
    self._loopWait -= dt
    if self._loopWait <= 0 then
      startBurst(self)
    end
  end

  if self._phase ~= 'idle' then
    self._phaseTime += dt
    advancePhase(self)
  end

  if self._phase ~= 'idle' then
    local n = math.min(coinCount(self), #self.coins)
    local spinning = self._phase ~= 'hold'
    for i = 1, n do
      local c = self.coins[i]
      if spinning then
        c.rotation += c.spin * dt
      end
      local x, y, scale, opacity = sampleCoin(self, i, n, c)
      c.x = x
      c.y = y
      c.drawScale = scale
      c.opacity = opacity
      if c.instance then
        c.instance:advance(dt)
        setPieceOpacity(c.instance, opacity)
      end
    end
  end

  return true
end

function draw(self: CoinBurstData, renderer: Renderer)
  if self._phase == 'idle' then
    return
  end

  local n = math.min(coinCount(self), #self.coins)
  for i = 1, n do
    local c = self.coins[i]
    if c.opacity > 0.01 and c.drawScale > 0.01 then
      local inst = c.instance
      renderer:save()
      renderer:modulateOpacity(c.opacity)
      if inst then
        local hw = inst.width * 0.5
        local hh = inst.height * 0.5
        renderer:transform(
          coinTransform(c.x, c.y, c.rotation, c.drawScale, hw, hh)
        )
        inst:draw(renderer)
      elseif self._coinPath and self._coinPaint then
        renderer:transform(
          Mat2D.withTranslation(c.x, c.y)
            * Mat2D.withScale(c.drawScale, c.drawScale)
        )
        renderer:drawPath(self._coinPath, self._coinPaint)
      end
      renderer:restore()
    end
  end
end

return function(): Layout<CoinBurstData>
  return {
    coinArtboard = late(),
    count = 12,
    play = false,
    loop = false,
    loopDelay = 0.55,
    restartAnim = true,

    originX = 0,
    originY = 0,
    gatherX = 0,
    gatherY = -170,

    spreadRadius = 120,
    radiusJitter = 0,
    startAngle = -90,

    spreadTime = 0.4,
    holdTime = 0.28,
    collectTime = 0.5,

    arc = 36,
    minScale = 0.9,
    maxScale = 1.1,
    endScale = 0.22,
    spin = 200,

    coins = {},
    width = 100,
    height = 100,
    _artRef = nil,
    _phase = 'idle',
    _phaseTime = 0,
    _wasPlay = false,
    _pending = false,
    _loopWait = 0,
    _vm = nil,
    _playTrigger = nil,
    _coinPath = nil,
    _coinPaint = nil,

    init = init,
    measure = measure,
    resize = resize,
    advance = advance,
    draw = draw,
  }
end
