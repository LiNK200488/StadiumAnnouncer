-- Stadium Announcer - clean Generation 2 runtime.
--
-- This module intentionally keeps the Gen 2 path small and generation-specific.
-- It does not inherit Gen 1 battle-screen timing assumptions. Gen 2 emits some
-- battle events from the engine Battle object and some UI-facing events from a
-- wrapper whose `.battle` field points at that engine object, so all event
-- matching goes through normalizeBattle().

local namespace = ...
local mod = namespace.mod

local Announcer = {}

local VOICE_ROOT = "assets/gen2"
local PLAYBACK_GAIN = 1.25
local CLIP_COUNT = 1387
local GAP_SECONDS = 0.10
local MAX_QUEUE = 8

-- Gen 1 flavor-parity beats, mapped to Stadium 2 lines with the same meaning.
-- First-move commentary is released on the proven Gen 2 move-presentation seam;
-- flow and decision-idle lines only claim genuinely quiet decision time.
local FLOW_IDLE_SECONDS = 0.8
local FLOW_EVERY_MOVES = 2
local FIRST_MOVE = { 836, 837 }
local FLOW = { 1065, 1066, 1067, 1068, 1069, 1070, 1071 }
local DECISION_IDLE_SECONDS = 10
local DECISION_IDLE = { 1062, 1063, 1064 }

local CRITICAL = { 892, 893, 894, 895, 896, 897 }
local SUPER_EFFECTIVE = { 898, 899, 900, 901, 902, 903, 904 }
local NOT_EFFECTIVE = { 905, 906, 907, 908 }
local STATUS_CLIP = {
  SLP = 961, SLEEP = 961,
  FRZ = 963, FREEZE = 963, FROZEN = 963,
  PAR = 964, PARALYSIS = 964, PARALYZED = 964,
  CONF = 965, CONFUSION = 965, CONFUSED = 965,
  PSN = 966, POISON = 966, POISONED = 966,
  BRN = 967, BURN = 967, BURNED = 967,
}
local FAINT = { 1033, 1034, 1035, 1036, 1037, 1038, 1039 }
local ONE_HIT_KO = { 1040, 1041, 1042, 1049 }
local DOUBLE_KO = { 1053, 1054, 1058 }
local LAST_POKEMON_FAINTED = 1059
local REMAINING_THREE_TWO = { 1140, 1142 }
local REMAINING_THREE_ONE = { 1141, 1145 }
local REMAINING_TWO_EACH = 1143
local REMAINING_TWO_ONE = { 1144, 1146 }
local REMAINING_ONE_EACH = { 1147, 1164 }
-- Temporarily disabled. Keep this pool here for a future post-KO replacement
-- commentary pass without wiring it into live battles yet.
-- local POST_KO_REPLACEMENT = { 1156, 1157, 1158, 1159, 1160, 1161 }
local VOLUNTARY_SWITCH = { 868, 869, 870, 871, 872, 873, 874, 875 }
local ATTACK_MISSED = { 973, 974, 975, 976, 977, 978, 979, 980, 981 }
local NO_EFFECT = { 982, 983, 984, 985 }
local STAT_UP = {
  ATTACK = { 1219, 1226 }, DEFENSE = { 1220, 1227 }, SPEED = { 1221, 1228 },
  ["SPCL.ATK"] = { 1222, 1229 }, ["SPCL.DEF"] = { 1223, 1230 },
  ACCURACY = { 1224, 1231 }, EVASION = { 1225, 1232 },
}
local STAT_DOWN = {
  ATTACK = 988, DEFENSE = 989, ["SPCL.ATK"] = 990, ["SPCL.DEF"] = 991,
  ACCURACY = 992, EVASION = 993, SPEED = 994,
}
local HP_RESTORED = 1216
local REST_SLEEP = 1217
local STATUS_CURED = 1218
local LIGHT_SCREEN_ACTIVE = 1233
local REFLECT_ACTIVE = 1234
local LIGHT_SCREEN_END = 1235
local REFLECT_END = 1236
local SUBSTITUTE_BROKEN = { 1244, 1245 }
local TRAPPED_CANNOT_ESCAPE = 1249
local DISABLE_SUCCESS = { 1251, 1252 }
local DISABLE_END = 1253
local PERISH_SONG_START = 1328
local PERISH_SONG_COUNT_ONE = 1329
local SAFEGUARD_START = 1334
local SAFEGUARD_ACTIVE = 1335
local SAFEGUARD_END = 1336
local SPIKES_SET = 1343
local FUTURE_SIGHT_START = 1348
local FUTURE_SIGHT_HIT = 1349
local WEATHER_RAIN_START = { 1311, 1312 }
local WEATHER_RAIN_TURN = { 1313, 1314 }
local WEATHER_RAIN_END = 1315
local WEATHER_SUN_START = { 1316, 1319 }
local WEATHER_SUN_TURN = 1317
local WEATHER_SUN_END = 1318
local WEATHER_SAND_START = 1320
local WEATHER_SAND_TURN = { 1321, 1322, 1324 }
local WEATHER_SAND_END = 1323
local WEATHER_SAND_DAMAGE = 1325
local HELD_HP_GENERIC = 1332
local HELD_STATUS_GENERIC = 1333
local HELD_ITEM_GENERIC = 1357
local HELD_PP_RESTORED = 1358
local HELD_HP_LUCKY = 1364
local BERRY_STATUS = {
  PSNCUREBERRY = 1365, PRZCUREBERRY = 1366, BURNT_BERRY = 1367,
  ICE_BERRY = 1368, BITTER_BERRY = 1369, MINT_BERRY = 1370,
  MIRACLEBERRY = 1371,
}
local BERRY_HP = {
  BERRY_JUICE = 1372, BERRY = 1373, GOLD_BERRY = 1374,
}
local MYSTERY_BERRY = 1375
local LEFTOVERS = 1376
local SLEEP_TURN = { 1254, 1255, 1256 }
local FREEZE_TURN = { 1257, 1258 }
local PARALYSIS_TURN = { 1260, 1261, 1262, 1263 }
local STATUS_RESIDUAL_DAMAGE = { 1267, 1268 }
local CONFUSION_SELF_HIT = 1269
local CONFUSION_TURN = { 1270, 1271, 1272 }
local CONFUSION_END = 1273
local SUBSTITUTE_CREATED = 1276
local FLY_CHARGE = { 1277, 1278 }
local DIG_CHARGE = { 1280, 1281 }
local GENERIC_CHARGE = 1284
local BIDE_CHARGE = { 1285, 1286 }
local BIDE_RELEASE = 1287
local TRANSFORM_SUCCESS = 1275
local ENCORE_START = 1296
local ENCORE_END = 1297
local FLINCH = 1299
local CURSE_START = 1306
local CURSE_DAMAGE = 1308
local CURSE_STAT_TRADEOFF = 1309
local BELLY_DRUM = 1310
local ENDURE_START = { 1337, 1338 }
local ENDURE_SURVIVED = 1339
local MOVE_FLY = 19
local MOVE_DIG = 91
local MOVE_LIGHT_SCREEN = 113
local MOVE_REFLECT = 115
local MOVE_REST = 156
local MOVE_TRANSFORM = 144
local MOVE_CURSE = 174
local MOVE_BELLY_DRUM = 187
local MOVE_ENDURE = 203
local MOVE_ENCORE = 227
local HEALING_MOVES = {
  [105] = true, -- Recover
  [135] = true, -- Softboiled
  [208] = true, -- Milk Drink
  [234] = true, -- Morning Sun
  [235] = true, -- Synthesis
  [236] = true, -- Moonlight
}
local BATTLE_END_GENERIC = 1002

-- Verified against src/battle/gen2/Battle.lua's Battle.GYM_LEADER_CLASSES.
-- These are the exact Gen 2 trainer class IDs considered a Gym Leader,
-- Elite Four member, Champion, or Red by the game itself.
local MAJOR_TRAINER_CLASS = {
  FALKNER = true, WHITNEY = true, BUGSY = true, MORTY = true,
  PRYCE = true, JASMINE = true, CHUCK = true, CLAIR = true,
  WILL = true, BRUNO = true, KAREN = true, KOGA = true,
  CHAMPION = true, RED = true,
  BROCK = true, MISTY = true, LT_SURGE = true, ERIKA = true,
  JANINE = true, SABRINA = true, BLAINE = true, BLUE = true,
}

-- Stadium 2 also has dedicated encounter intros for the Rival and Team Rocket
-- Executives. Include those identity-safe opponents in the default
-- "GYM / ELITE 4 / CHAMPION" scope as requested, without redefining the
-- game's own Gym Leader class set above.
local DEFAULT_SCOPE_EXTRA_TRAINER_CLASS = {
  RIVAL1 = true,
  RIVAL2 = true,
  EXECUTIVEM = true,
  EXECUTIVEF = true,
}

-- Stadium 2's named encounter intros. Only lines whose opponent identity
-- matches an actual Crystal trainer class are wired here; Stadium-specific
-- Gym Leader Castle underlings (Chaz, Lois, Rita, etc.) are intentionally not
-- guessed onto unrelated in-game trainers. Rival / Rocket Executive lines
-- are also included in the default featured-opponent scope.
local SPECIAL_TRAINER_INTRO = {
  FALKNER = 546,
  BUGSY = 549,
  WHITNEY = 552,
  MORTY = 555,
  CHUCK = 557,
  JASMINE = 558,
  PRYCE = 565,
  CLAIR = 568,
  WILL = 569,
  KOGA = 570,
  BRUNO = 571,
  KAREN = 572,
  CHAMPION = 573, -- Lance
  LT_SURGE = 574,
  SABRINA = 575,
  MISTY = 576,
  ERIKA = 577,
  JANINE = 578,
  BROCK = 579,
  BLAINE = 580,
  BLUE = 581,
  RED = 582,
  RIVAL1 = 583,
  RIVAL2 = 583,
  EXECUTIVEM = 562,
  EXECUTIVEF = 562,
}

local PRIORITY = {
  ambient = 10,
  intro = 75,
  move = 20,
  damage = 40,
  status = 55,
  mechanic = 58,
  stat = 50,
  sendout = 70,
  faint = 80,
  switch = 65,
  result = 90,
}

local state = {
  engineBattle = nil,
  uiBattle = nil,
  active = false,
  current = nil,
  currentIndex = nil,
  currentPriority = nil,
  queue = {},
  gap = 0,
  idle = 0,
  flowMoves = 0,
  flowPending = false,
  flowIndex = 0,
  decisionIdle = 0,
  decisionFingerprint = nil,
  decisionPrompted = false,
  decisionIndex = 0,
  moveCount = 0,
  lastChoices = {},
  packChecked = false,
  packReady = false,
  packError = nil,
  missing = {},
  loadErrors = {},
  starts = 0,
  openingIntroClip = nil,
  openingIntroClass = nil,
  pendingNames = { player = nil, enemy = nil },
  announcedSpecies = { player = nil, enemy = nil },
  pendingMoves = {},
  pendingFaints = {},
  pendingBattleEnd = nil,
  faintLineLatch = nil,
  oneHitKoArmed = false,
  suppressedFaintLines = 0,
  remainingCountKey = nil,
  moveLineLatch = nil,
  renderedMoveLine = nil,
  renderedMoveLineSeen = nil,
  outcomeLineLatch = nil,
  statLineLatch = nil,
  mechanicLineLatch = nil,
  weatherLineLatch = nil,
  heldItemLineLatch = nil,
  ongoingStatusLineLatch = nil,
  curseTradeoffSerial = nil,
  presentedMove = nil,
}

local function logInfo(text)
  local logger = namespace.log or mod.log
  if logger and logger.info then pcall(logger.info, logger, text) end
end

local commentaryRandomSeed = nil

local function seedCommentaryRandom()
  local fine = 0
  if love and love.timer and love.timer.getTime then
    local ok, value = pcall(love.timer.getTime)
    if ok and type(value) == "number" then fine = value end
  elseif os and os.clock then
    local ok, value = pcall(os.clock)
    if ok and type(value) == "number" then fine = value end
  end

  local epoch = 0
  if os and os.time then
    local ok, value = pcall(os.time)
    if ok and type(value) == "number" then epoch = value end
  end

  local seed = (math.floor(fine * 1000000) + epoch) % 2147483647
  if seed <= 0 then seed = 1 end
  return seed
end

-- Private Park-Miller stream for interchangeable commentary selection. This deliberately does
-- not consume the game's battle RNG (or Lua/LÖVE's shared global RNG).
local function nextCommentaryRandom()
  local seed = commentaryRandomSeed or seedCommentaryRandom()
  local hi = math.floor(seed / 127773)
  local lo = seed - hi * 127773
  local value = 16807 * lo - 2836 * hi
  if value <= 0 then value = value + 2147483647 end
  commentaryRandomSeed = value
  return value
end

local function randomChoiceIndex(count, previous)
  if count <= 0 then return nil end
  if count == 1 then return 1 end

  -- A two-clip pool gets a random starting point, then alternates from there.
  -- This keeps both clips in rotation without always forcing the same clip to
  -- be first. Larger pools remain random while avoiding an immediate repeat.
  if count == 2 then
    if previous == 1 then return 2 end
    if previous == 2 then return 1 end
    return (nextCommentaryRandom() % 2) + 1
  end

  local at = (nextCommentaryRandom() % count) + 1
  if previous and previous >= 1 and previous <= count and at == previous then
    local offset = (nextCommentaryRandom() % (count - 1)) + 1
    at = ((previous - 1 + offset) % count) + 1
  end
  return at
end

local function enabled()
  return true
end

local function scope()
  if not (mod.options and mod.options.get) then return "gym" end
  local value = mod.options:get("announcer_scope")
  if value == "all" or value == "trainer" then return value end
  return "gym"
end

-- Gen 2 has both the engine battle and a UI wrapper in circulation. Always
-- reduce either shape to the engine object before comparing event ownership.
local function normalizeBattle(battle)
  if type(battle) ~= "table" then return battle end
  local inner = rawget(battle, "battle")
  if type(inner) == "table" and inner ~= battle then
    -- UI BattleState wraps the engine Battle in `.battle`.
    if inner.player ~= nil or inner.enemy ~= nil or inner.party ~= nil
        or inner.enemyParty ~= nil then
      return inner
    end
  end
  return battle
end

local function battleKind(engine, event)
  if event and event.kind then return tostring(event.kind) end
  if engine and engine.wild ~= nil then return engine.wild and "wild" or "trainer" end
  return nil
end

local function trainerClass(engine, event)
  local trainer = engine and engine.trainer
  local value = trainer and (trainer.classId or trainer.class)
  if type(value) == "number" and trainer and trainer.className then
    value = trainer.className
  end
  if value == nil and event then value = event.trainerId end
  if value == nil and trainer then value = trainer.id end
  if value == nil then return nil end

  local id = tostring(value):upper():gsub("[%s%-%.]+", "_")
  if MAJOR_TRAINER_CLASS[id] or SPECIAL_TRAINER_INTRO[id] then return id end

  -- The UI-side battle.started event carries trainer.id (for example
  -- FALKNER1) while the engine-side event carries classId (FALKNER). The
  -- engine object normally gives us classId directly, but this prefix fallback
  -- keeps the classifier correct if a modded caller only exposes the roster ID.
  for class in pairs(SPECIAL_TRAINER_INTRO) do
    if id:sub(1, #class) == class then return class end
  end
  return id
end

local function eligible(engine, event)
  if not engine then return false end
  local selected = scope()
  if selected == "all" then return true end
  local kind = battleKind(engine, event)
  if selected == "trainer" then return kind ~= "wild" end
  if kind == "wild" then return false end
  -- Default scope: verified Gym/Elite/Champion/Red classes plus the Rival
  -- and Team Rocket Executive classes that have dedicated Stadium 2 intros.
  local class = trainerClass(engine, event)
  return MAJOR_TRAINER_CLASS[class] == true
      or DEFAULT_SCOPE_EXTRA_TRAINER_CLASS[class] == true
end

local function specialTrainerIntro(engine, event)
  if battleKind(engine, event) == "wild" then return nil, nil end
  local class = trainerClass(engine, event)
  return SPECIAL_TRAINER_INTRO[class], class
end

local function clipRelative(index)
  return ("%s/%04d.wav"):format(VOICE_ROOT, index)
end

local function packReady()
  if state.packChecked then return state.packReady end
  state.packChecked = true

  local ok, marker = pcall(mod.read, mod, VOICE_ROOT .. "/voicepack.json")
  if not ok or type(marker) ~= "string" then
    state.packError = "voicepack.json unreadable"
    return false
  end
  if not marker:match('"clip_count"%s*:%s*1387') then
    state.packError = "voicepack clip_count is not 1387"
    return false
  end

  -- Validate an actual known announcer WAV too. This catches package/path
  -- mistakes immediately instead of declaring the pack ready from JSON alone.
  local testOk, bytes = pcall(mod.read, mod, clipRelative(836))
  if not testOk or type(bytes) ~= "string" or #bytes < 44
      or bytes:sub(1, 4) ~= "RIFF" or bytes:sub(9, 12) ~= "WAVE" then
    state.packError = "assets/gen2/0836.wav unreadable or invalid"
    return false
  end

  state.packReady = true
  return true
end

local function stopSource(source)
  if source and source.stop then pcall(source.stop, source) end
end

local function resetPlayback()
  stopSource(state.current)
  state.current = nil
  state.currentIndex = nil
  state.currentPriority = nil
  state.queue = {}
  state.gap = 0
  state.idle = 0
  state.flowMoves = 0
  state.flowPending = false
  state.flowIndex = 0
  state.decisionIdle = 0
  state.decisionFingerprint = nil
  state.decisionPrompted = false
  state.decisionIndex = 0
  state.moveCount = 0
  state.lastChoices = {}
  state.openingIntroClip = nil
  state.openingIntroClass = nil
  state.pendingNames = { player = nil, enemy = nil }
  state.announcedSpecies = { player = nil, enemy = nil }
  state.pendingMoves = {}
  state.pendingFaints = {}
  state.pendingBattleEnd = nil
  state.faintLineLatch = nil
  state.oneHitKoArmed = false
  state.suppressedFaintLines = 0
  state.remainingCountKey = nil
  state.moveLineLatch = nil
  state.renderedMoveLine = nil
  state.renderedMoveLineSeen = nil
  state.outcomeLineLatch = nil
  state.statLineLatch = nil
  state.mechanicLineLatch = nil
  state.weatherLineLatch = nil
  state.heldItemLineLatch = nil
  state.ongoingStatusLineLatch = nil
  state.curseTradeoffSerial = nil
  state.presentedMove = nil
end

local function wavSoundData(bytes)
  if not (love and love.sound and love.sound.newSoundData) then
    return nil, "love.sound.newSoundData unavailable"
  end
  if type(bytes) ~= "string" or bytes:sub(1, 4) ~= "RIFF"
      or bytes:sub(9, 12) ~= "WAVE" then
    return nil, "invalid WAV header"
  end

  local function u16(at)
    local a, b = bytes:byte(at, at + 1)
    if not (a and b) then return nil end
    return a + b * 256
  end
  local function u32(at)
    local a, b, c, d = bytes:byte(at, at + 3)
    if not (a and b and c and d) then return nil end
    return a + b * 256 + c * 65536 + d * 16777216
  end

  local at = 13
  local channels, rate, bits, encoding, dataAt, dataSize
  while at + 7 <= #bytes do
    local kind = bytes:sub(at, at + 3)
    local size = u32(at + 4)
    if not size or at + 7 + size > #bytes then return nil, "truncated WAV" end
    if kind == "fmt " and size >= 16 then
      encoding = u16(at + 8)
      channels = u16(at + 10)
      rate = u32(at + 12)
      bits = u16(at + 22)
    elseif kind == "data" then
      dataAt, dataSize = at + 8, size
    end
    at = at + 8 + size + (size % 2)
  end

  if encoding ~= 1 or channels ~= 1 or rate ~= 16000 or bits ~= 16 or not dataAt then
    return nil, "expected PCM mono 16-bit 16000 Hz WAV"
  end

  local samples = math.floor(dataSize / 2)
  local ok, sound = pcall(love.sound.newSoundData, samples, rate, bits, channels)
  if not ok or not sound then return nil, tostring(sound) end

  for i = 0, samples - 1 do
    local lo, hi = bytes:byte(dataAt + i * 2, dataAt + i * 2 + 1)
    local value = lo + hi * 256
    if value >= 32768 then value = value - 65536 end
    -- LÖVE Source:setVolume tops out at 1.0, so Gen 2's extra announcer
    -- loudness is applied while decoding the WAV rather than by modifying the
    -- packaged audio assets. Clamp explicitly to avoid out-of-range samples.
    local sample = (value / 32768) * PLAYBACK_GAIN
    if sample > 1 then sample = 1 elseif sample < -1 then sample = -1 end
    sound:setSample(i, sample)
  end
  return sound
end

local function loadSource(index)
  if state.missing[index] then return nil end
  if not (love and love.audio and love.audio.newSource) then
    state.loadErrors[index] = "love.audio.newSource unavailable"
    return nil
  end

  local ok, bytes = pcall(mod.read, mod, clipRelative(index))
  if not ok or type(bytes) ~= "string" or #bytes == 0 then
    state.missing[index] = true
    state.loadErrors[index] = "clip unreadable: " .. clipRelative(index)
    return nil
  end

  local sound, err = wavSoundData(bytes)
  if not sound then
    state.missing[index] = true
    state.loadErrors[index] = err or "WAV decode failed"
    return nil
  end

  local sourceOk, source = pcall(love.audio.newSource, sound, "static")
  if not sourceOk or not source then
    state.missing[index] = true
    state.loadErrors[index] = tostring(source)
    return nil
  end
  return source
end

local function currentStillPlaying()
  if not state.current then return false end
  local ok, playing = pcall(state.current.isPlaying, state.current)
  if ok and playing then return true end
  local finishedIndex = state.currentIndex
  state.current = nil
  state.currentIndex = nil
  state.currentPriority = nil
  if finishedIndex ~= nil and finishedIndex == state.openingIntroClip then
    state.openingIntroClip = nil
    state.openingIntroClass = nil
  end
  state.gap = GAP_SECONDS
  return false
end

local function startNext()
  if currentStillPlaying() or state.gap > 0 then return end
  while #state.queue > 0 do
    local item = table.remove(state.queue, 1)
    local source = loadSource(item.index)
    if source then
      local ok = pcall(source.play, source)
      if ok then
        state.current = source
        state.currentIndex = item.index
        state.currentPriority = item.priority
        return
      end
      state.missing[item.index] = true
      state.loadErrors[item.index] = "source.play failed"
    end
  end
end

local function alreadyQueued(index, key)
  if state.currentIndex == index then return true end
  for _, item in ipairs(state.queue) do
    if item.index == index or (key and item.key == key) then return true end
  end
  return false
end

local function enqueue(index, priority, key)
  if type(index) ~= "number" or index < 0 or index >= CLIP_COUNT then return false end
  if not enabled() or not packReady() or alreadyQueued(index, key) then return false end

  local item = { index = index, priority = priority or 0, key = key }
  if #state.queue >= MAX_QUEUE then table.remove(state.queue, 1) end
  state.queue[#state.queue + 1] = item
  startNext() -- playback starts from the event itself; update() is not required to kick it off
  return true
end

local function randomChoice(name, clips)
  local n = #clips
  if n == 0 then return nil end
  local at = randomChoiceIndex(n, state.lastChoices[name])
  state.lastChoices[name] = at
  return clips[at]
end

local function noteMoveForFlow()
  state.flowMoves = state.flowMoves + 1
  if state.flowMoves >= FLOW_EVERY_MOVES then
    state.flowMoves = 0
    state.flowPending = true
  end
end

local function quietDecisionPhase()
  local ui = state.uiBattle
  if type(ui) ~= "table" then return false end
  return ui.phase == "menu" or ui.phase == "moves"
end

local function startFlowCommentary()
  if not state.flowPending or not quietDecisionPhase()
      or state.current or #state.queue > 0 or #state.pendingMoves > 0
      or #state.pendingFaints > 0 or state.gap > 0 then
    return false
  end
  state.flowPending = false
  state.flowIndex = randomChoiceIndex(#FLOW, state.flowIndex)
  return enqueue(FLOW[state.flowIndex], PRIORITY.ambient,
    "battle_flow:" .. tostring(state.starts) .. ":" .. tostring(state.flowIndex))
end

local function gameInputPending(game)
  local queue = game and game.input and game.input.pressQueue
  return type(queue) == "table" and #queue > 0
end

local function decisionFingerprint(game)
  local ui = state.uiBattle
  local engine = state.engineBattle
  if not state.active or type(ui) ~= "table" or not engine then return nil end

  -- Party, Pack, and other pushed screens can leave the underlying battle in
  -- menu phase. Only count idle time while the battle screen itself owns input.
  local liveGame = game or ui.game
  local stack = liveGame and liveGame.stack
  if stack and type(stack.top) == "function" then
    local ok, top = pcall(stack.top, stack)
    if ok and top ~= ui then return nil end
  end

  if ui.phase == "menu" then
    local player = engine.player
    local hp = player and tonumber(player.hp or (player.mon and player.mon.hp))
    if hp and hp <= 0 then return nil end
    return "menu:" .. tostring(ui.menuIndex or 1)
  elseif ui.phase == "moves" then
    return "moves:" .. tostring(ui.moveIndex or 1)
  end
  return nil
end

local function updateDecisionIdle(dt, game)
  local fingerprint = decisionFingerprint(game)
  if not fingerprint then
    state.decisionIdle = 0
    state.decisionFingerprint = nil
    state.decisionPrompted = false
    return
  end

  local active = gameInputPending(game or (state.uiBattle and state.uiBattle.game))
  if active or fingerprint ~= state.decisionFingerprint then
    state.decisionIdle = 0
    state.decisionPrompted = false
  end
  state.decisionFingerprint = fingerprint
  if active or state.decisionPrompted then return end

  state.decisionIdle = state.decisionIdle + math.max(0, tonumber(dt) or 0)
  if state.decisionIdle < DECISION_IDLE_SECONDS then return end

  -- As in Gen 1, never stack an idle prompt behind real battle commentary. The
  -- same unchanged decision may claim the gap once the announcer is truly quiet.
  if state.current or #state.queue > 0 or #state.pendingMoves > 0
      or #state.pendingFaints > 0 or state.gap > 0 then return end
  state.decisionIndex = randomChoiceIndex(#DECISION_IDLE, state.decisionIndex)
  if enqueue(DECISION_IDLE[state.decisionIndex], PRIORITY.ambient,
      "decision_idle:" .. tostring(state.starts)) then
    state.decisionPrompted = true
  end
end

local function sameBattle(battle)
  return state.active and normalizeBattle(battle) == state.engineBattle
end

local function tableDex(value)
  if type(value) ~= "table" then return nil end
  for _, key in ipairs({ "dex", "dexNo", "dexNumber", "pokedex", "nationalDex", "nationalDexNo", "num", "number", "index" }) do
    local n = tonumber(value[key])
    if n and n >= 1 and n <= 251 then return n end
  end
  return nil
end

local function speciesValue(battler)
  if type(battler) ~= "table" then return battler end
  local mon = battler.mon or battler
  return mon.species or mon.speciesId or mon.id or mon
end

local function dexFor(engine, battler, eventSpecies)
  -- Gen 2 mons store species as the symbolic key used by data.pokemon
  -- (for example "CHIKORITA"). The canonical National Dex number lives on
  -- data.pokemon[species].dex. Do not guess from array position or fall back to
  -- an unrelated announcer line when resolution fails.
  local value = eventSpecies ~= nil and eventSpecies or speciesValue(battler)

  local direct = tonumber(value)
  if direct and direct >= 1 and direct <= 251 then return direct end

  if type(value) == "table" then
    local n = tableDex(value)
    if n then return n end
    value = value.species or value.id or value.key or value.name
  end

  local pokemon = engine and engine.data and engine.data.pokemon
  if type(pokemon) == "table" and value ~= nil then
    local def = pokemon[value]
    local dex = def and tonumber(def.dex)
    if dex and dex >= 1 and dex <= 251 then return dex end

    -- Compatibility only for unusual modded data sets keyed numerically.
    for _, candidate in pairs(pokemon) do
      if type(candidate) == "table"
          and (candidate.id == value or candidate.name == value or candidate.key == value) then
        dex = tonumber(candidate.dex)
        if dex and dex >= 1 and dex <= 251 then return dex end
      end
    end
  end
  return nil
end

local function moveIndexFor(engine, payload)
  local move = payload and (payload.move or payload.moveDef)
  if type(move) == "number" and move >= 1 and move <= 251 then return move end
  if type(move) == "table" then
    for _, key in ipairs({ "index", "moveIndex", "num", "number" }) do
      local n = tonumber(move[key])
      if n and n >= 1 and n <= 251 then return n end
    end
  end

  local moveId = payload and (payload.moveId or (type(move) == "table" and move.id) or move)
  local moves = engine and engine.data and engine.data.moves
  if type(moves) == "table" and moveId ~= nil then
    for i = 1, 251 do
      local def = moves[i]
      if def == move then return i end
      if type(def) == "table" and (def.id == moveId or def.name == moveId or def.key == moveId) then
        return i
      end
    end
  end
  return nil
end

local function sideBattler(engine, side)
  if not engine then return nil end
  if side == "player" or side == 1 then return engine.player end
  if side == "enemy" or side == 2 then return engine.enemy end
  return nil
end

local function effectiveness(payload)
  local mult = tonumber(payload and (payload.typeMult or payload.effectiveness))
  if not mult then return nil end
  -- Gen 1 compatibility scale uses 10 as neutral; Gen 2 native may use 1.0.
  if mult > 4 then return mult / 10 end
  return mult
end

local function sideFor(engine, battler, side)
  if battler == (engine and engine.player) then return "player" end
  if battler == (engine and engine.enemy) then return "enemy" end
  if type(side) == "table" then
    if side.battler == battler or side.active == battler or side.mon == battler then
      if side == (engine and engine.sides and engine.sides[1]) then return "player" end
      if side == (engine and engine.sides and engine.sides[2]) then return "enemy" end
    end
    if side.isPlayer == true then return "player" end
    if side.isPlayer == false then return "enemy" end
  end
  if side == "player" or side == 1 then return "player" end
  if side == "enemy" or side == 2 then return "enemy" end
  return nil
end

local function queueName(side, battler, eventSpecies, key, beforeClip, requireUiSendOut)
  local dex = dexFor(state.engineBattle, battler, eventSpecies)
  if not (side and dex) then return false end
  state.pendingNames[side] = {
    dex = dex,
    battler = battler,
    species = speciesValue(battler) or eventSpecies,
    key = key or (side .. "_species"),
    beforeClip = beforeClip,
    requireUiSendOut = requireUiSendOut and true or false,
    seenUiSendOut = false,
  }
  return true
end

local function sameUiSendOut(send, pending, side)
  if type(send) ~= "table" or send.side ~= side then return false end
  if pending.battler ~= nil and send.mon == pending.battler then return true end
  local species = speciesValue(send.mon)
  return species ~= nil and species == pending.species
end

local function uiSideReady(side, pending)
  local ui = state.uiBattle
  if type(ui) ~= "table" then return false end

  -- Gen 2's pure battle engine resolves the turn before the UI presents it.
  -- A mid-battle battler_switched event can therefore arrive while the OLD
  -- Pokemon is still visibly standing there with its HUD up.  For switched-in
  -- names, do not accept that existing HUD as proof of presentation: first
  -- observe the UI arm the matching send-out (pendingSendOut/afterSendOut), then
  -- wait for that send-out animation/cry/HUD update to finish.
  if pending and pending.requireUiSendOut then
    if sameUiSendOut(ui.pendingSendOut, pending, side)
        or sameUiSendOut(ui.afterSendOut, pending, side) then
      pending.seenUiSendOut = true
    end
    if not pending.seenUiSendOut then return false end
    if sameUiSendOut(ui.pendingSendOut, pending, side) then return false end
  end

  -- afterSendOut remains armed through the reveal/cry/send-out animation.
  -- Waiting for it to clear places the Stadium name call after the Pokemon is
  -- actually on the field instead of at the engine event that scheduled it.
  if ui.afterSendOut ~= nil then return false end
  if side == "enemy" then return ui.showEnemyHud == true end
  if side == "player" then return ui.showPlayerHud == true end
  return false
end

local function releaseOpeningIntroForEnemyName()
  -- Named Stadium 2 trainer intros are long (often 8-14 seconds), while the
  -- Crystal send-out presentation can finish sooner. Preserve the already-
  -- verified species-name timing: let the intro play as early/long as the game
  -- permits, but if it is still talking when the foe is actually on the field,
  -- the exact enemy name takes over rather than being delayed several seconds.
  if state.openingIntroClip and state.currentIndex == state.openingIntroClip then
    stopSource(state.current)
    state.current = nil
    state.currentIndex = nil
    state.currentPriority = nil
    state.gap = 0
    state.openingIntroClip = nil
    state.openingIntroClass = nil
    return true
  end
  return false
end

local function flushPendingNames()
  if not state.active then return end
  for _, side in ipairs({ "enemy", "player" }) do
    local pending = state.pendingNames[side]
    if pending and uiSideReady(side, pending) then
      if state.announcedSpecies[side] ~= pending.species then
        if side == "enemy" then releaseOpeningIntroForEnemyName() end
        if pending.beforeClip then
          enqueue(pending.beforeClip, PRIORITY.switch, "switch:" .. side .. ":" .. tostring(pending.species))
        end
        enqueue(584 + pending.dex, PRIORITY.sendout, pending.key)
        state.announcedSpecies[side] = pending.species
      end
      state.pendingNames[side] = nil
    end
  end
end

function Announcer.beginBattle(battle, event)
  local engine = normalizeBattle(battle)
  if not enabled() or not eligible(engine, event) then return false end
  if not packReady() then
    logInfo("Stadium 2 announcer disabled: " .. tostring(state.packError or "voice pack unavailable"))
    return false
  end

  -- Gen 2 raises battle.started from both the engine and the UI BattleState.
  -- The second form is valuable because it exposes the real send-out timing.
  if state.active and state.engineBattle == engine then
    if battle ~= engine then state.uiBattle = battle end
    return true
  end

  resetPlayback()
  state.engineBattle = engine
  state.uiBattle = (battle ~= engine) and battle or nil
  state.active = true
  state.starts = state.starts + 1

  -- Play only an identity-safe Stadium 2 encounter intro. These clips are
  -- keyed by the verified Crystal trainer class, not by display-name guessing.
  local introClip, introClass = specialTrainerIntro(engine, event)
  if introClip then
    state.openingIntroClip = introClip
    state.openingIntroClass = introClass
    enqueue(introClip, PRIORITY.intro,
      "trainer_intro:" .. tostring(introClass) .. ":" .. tostring(state.starts))
  end

  -- Do NOT play a generic fallback here. 0836 is literally "Here's the first
  -- move" and must only ever belong to move-flow commentary. Instead arm the
  -- two initial species names and let update() release each one when the Gen 2
  -- UI confirms that side's send-out has completed.
  if battleKind(engine, event) == "wild" then
    queueName("enemy", engine and engine.enemy, event and event.species, "initial_wild_species")
  else
    queueName("enemy", engine and engine.enemy, event and event.species, "initial_enemy_species")
  end
  queueName("player", engine and engine.player, nil, "initial_player_species")
  return true
end

function Announcer.battlerSwitched(payload)
  if not payload or not sameBattle(payload.battle) then return false end
  local engine = state.engineBattle
  local battler = payload.battler or payload.mon
  local side = sideFor(engine, battler, payload.side)
  if not side then return false end
  -- The engine event fires when the active mon changes, before the UI has
  -- necessarily completed the recall/send-out sequence. Arm the name now and
  -- release it from update() only after the HUD/send-out latch says it is live.
  state.announcedSpecies[side] = nil

  -- Only a living Pokemon being withdrawn is a voluntary switch. Replacements
  -- after a faint already have their own KO/send-out flow and should not get a
  -- bogus "Pokemon Switch" line. The switch call is held until the new mon is
  -- actually on the field, immediately before its species-name call.
  local previous = payload.previous
  local previousMon = type(previous) == "table" and (previous.mon or previous) or nil
  local voluntary = previousMon and tonumber(previousMon.hp or 0) > 0
  local beforeClip = voluntary and randomChoice("voluntary_switch", VOLUNTARY_SWITCH) or nil
  return queueName(side, battler or sideBattler(engine, side), payload.species,
    "switch_species:" .. side, beforeClip, true)
end

local function moveDisplayName(payload)
  local move = payload and (payload.move or payload.moveDef)
  if type(move) == "table" then
    return move.name or move.id or payload.moveId
  end
  return payload and (payload.moveId or move)
end

local function normalizeMoveLine(text)
  return tostring(text or ""):upper():gsub("[%c]+", " "):gsub("%s+", " ")
end

local function flushPendingMoves()
  if not state.active or #state.pendingMoves == 0 then return end
  local ui = state.uiBattle
  if type(ui) ~= "table" then return end

  -- input.step runs before the Gen 2 battle screen advances its presentation
  -- queue. Most damaging moves leave the "X used MOVE!" line visible long
  -- enough for the next input tick, but short status moves (notably Protect
  -- and Spikes) can move on before that sampler sees it. battle.overlay latches
  -- the line that was actually rendered; consume that one-shot render latch
  -- first, then fall back to the ordinary UI message for long-lived lines.
  local message = state.renderedMoveLine
  if message ~= nil then
    state.renderedMoveLine = nil
  elseif ui.phase == "resolving" then
    message = normalizeMoveLine(ui.message)
  else
    return
  end

  if message == "" then
    state.moveLineLatch = nil
    return
  end
  if state.moveLineLatch ~= nil then
    if message == state.moveLineLatch then return end
    state.moveLineLatch = nil
  end
  if not message:find(" USED ", 1, true) then return end

  -- The engine resolves a whole turn before the UI replays it. If an unusually
  -- short move line escaped both samplers, leaving that stale move at the head
  -- would block every later move announcement. Match the currently presented
  -- line against the pending turn in order and discard only older entries that
  -- provably precede the line now on screen. This is recovery, not timing: a
  -- normally observed move still follows the exact same presentation seam.
  local matchAt = nil
  for i, candidate in ipairs(state.pendingMoves) do
    local name = normalizeMoveLine(candidate and candidate.name)
    if name ~= "" and message:find(name, 1, true) then
      matchAt = i
      break
    end
  end
  if not matchAt then
    local first = state.pendingMoves[1]
    if first and normalizeMoveLine(first.name) == "" then matchAt = 1 end
  end
  if not matchAt then return end
  while matchAt > 1 do
    table.remove(state.pendingMoves, 1)
    matchAt = matchAt - 1
  end

  local pending = state.pendingMoves[1]
  if not pending then return end
  table.remove(state.pendingMoves, 1)
  state.presentedMove = {
    index = pending.index,
    serial = pending.serial,
    side = pending.side,
    damageReaction = pending.damageReaction,
  }
  pending.damageReaction = nil
  state.outcomeLineLatch = nil

  -- Match Gen 1's first-move behavior, but release it from Gen 2's already
  -- proven "X used MOVE!" presentation seam instead of the early engine hook.
  state.moveCount = state.moveCount + 1
  if state.moveCount == 1 then
    enqueue(randomChoice("first_move", FIRST_MOVE), PRIORITY.move,
      "first_move:" .. tostring(state.starts))
  end
  enqueue(264 + pending.index, PRIORITY.move,
    "move:" .. tostring(pending.index) .. ":" .. tostring(pending.serial))
  noteMoveForFlow()

  -- Damage/result hooks fire during engine resolution, before the Gen 2 UI
  -- reaches this move line. Keep the reaction attached to the presented move,
  -- but do NOT enqueue it yet: the UI later displays the exact critical / type
  -- effectiveness text. flushPresentedMoveOutcome() releases the Stadium line
  -- only when that corresponding cart message is actually on screen.

  state.moveLineLatch = message
end

local function flushPresentedMoveOutcome()
  if not state.active or not state.presentedMove then return end
  local ui = state.uiBattle
  if type(ui) ~= "table" or ui.phase ~= "resolving" then return end

  local message = normalizeMoveLine(ui.message)
  if message == "" then
    state.outcomeLineLatch = nil
    return
  end
  if state.outcomeLineLatch == message then return end

  -- These are exact Gen 2 battle-text seams, not guesses from damage=0. A type
  -- immunity prints "It doesn't affect X..."; an accuracy miss prints
  -- "X's attack missed!". Both occur after the UI has presented the move line,
  -- so queueing here guarantees MOVE NAME -> MISS/NO EFFECT ordering.
  local clip, key
  local reaction = state.presentedMove.damageReaction

  -- Engine damage hooks tell us WHICH reaction belongs to this move; the live
  -- UI message tells us WHEN to say it. Gen 2 prints critical/effectiveness as
  -- separate battle-text events after the hit animation. Waiting for those
  -- exact presentation seams prevents the announcer from saying the result
  -- before the matching text appears.
  if reaction and reaction.key:find("critical:", 1, true) == 1
      and message:find("A CRITICAL HIT!", 1, true) then
    clip, key = reaction.index, reaction.key
  elseif reaction and reaction.key:find("super_effective:", 1, true) == 1
      and message:find("SUPER-", 1, true)
      and message:find("EFFECTIVE!", 1, true) then
    clip, key = reaction.index, reaction.key
  elseif reaction and reaction.key:find("not_effective:", 1, true) == 1
      and message:find("IT'S NOT VERY", 1, true)
      and message:find("EFFECTIVE", 1, true) then
    clip, key = reaction.index, reaction.key
  elseif message:find("IT DOESN'T AFFECT ", 1, true) then
    clip = randomChoice("no_effect", NO_EFFECT)
    key = "no_effect:" .. tostring(state.presentedMove.serial)
  elseif message:find(" ATTACK MISSED!", 1, true) then
    clip = randomChoice("attack_missed", ATTACK_MISSED)
    key = "attack_missed:" .. tostring(state.presentedMove.serial)
  end

  if clip then
    enqueue(clip, PRIORITY.damage, key)
    state.outcomeLineLatch = message
    state.presentedMove = nil
  end
end

local function flushPresentedMechanics()
  if not state.active then return end
  local ui = state.uiBattle
  if type(ui) ~= "table" or ui.phase ~= "resolving" then return end

  -- Presentation-synchronized Gen 2 mechanics. These lines are emitted by the
  -- battle engine during resolution but only become visible later through the
  -- UI queue. Trigger from the live message so commentary follows the move
  -- name and the actual on-screen result instead of racing ahead of it.
  local message = normalizeMoveLine(ui.message)
  if message == "" then
    state.mechanicLineLatch = nil
    return
  end
  if state.mechanicLineLatch == message then return end

  local move = state.presentedMove and state.presentedMove.index or nil
  local clip, key

  -- Light Screen and Reflect deliberately reuse the cart's ordinary
  -- "SPCL.DEF rose" / "DEFENSE rose" messages. Disambiguate them by the
  -- move that is currently being presented so they do not get mistaken for
  -- normal stat-stage boosts.
  if move == MOVE_LIGHT_SCREEN and message:find("'S SPCL.DEF ROSE!", 1, true) then
    clip, key = LIGHT_SCREEN_ACTIVE, "light_screen_active"
  elseif move == MOVE_REFLECT and message:find("'S DEFENSE ROSE!", 1, true) then
    clip, key = REFLECT_ACTIVE, "reflect_active"

  -- Screen expiration is explicit Gen 2 battle text and is independent of the
  -- move currently being presented.
  elseif message:find("POKEMON'S LIGHT SCREEN FELL!", 1, true)
      or message:find("POKÉMON'S LIGHT SCREEN FELL!", 1, true) then
    clip, key = LIGHT_SCREEN_END, "light_screen_end"
  elseif message:find("POKEMON'S REFLECT FADED!", 1, true)
      or message:find("POKÉMON'S REFLECT FADED!", 1, true) then
    clip, key = REFLECT_END, "reflect_end"

  -- Recover-family moves all converge on the cart's RegainedHealthText. Rest
  -- has its own Stadium call below and is intentionally excluded here.
  elseif move and HEALING_MOVES[move]
      and message:find(" REGAINED HEALTH!", 1, true) then
    clip, key = HP_RESTORED, "hp_restored:" .. tostring(state.presentedMove.serial)

  -- Rest's exact Gen 2 result text says either "went to sleep" or "fell
  -- asleep and became healthy". Use its dedicated Stadium line; when Rest also
  -- cures a pre-existing condition, queue the verified cure line immediately
  -- after it.
  elseif move == MOVE_REST
      and (message:find(" WENT TO SLEEP!", 1, true)
        or message:find(" FELL ASLEEP AND BECAME HEALTHY!", 1, true)) then
    enqueue(REST_SLEEP, PRIORITY.mechanic,
      "rest_sleep:" .. tostring(state.presentedMove.serial))
    if message:find(" FELL ASLEEP AND BECAME HEALTHY!", 1, true) then
      enqueue(STATUS_CURED, PRIORITY.mechanic,
        "rest_cure:" .. tostring(state.presentedMove.serial))
    end
    state.mechanicLineLatch = message
    return

  -- A substitute break has an exact engine/UI message; randomly choose between the two verified
  -- Stadium 2 variants rather than guessing from damage or substitute HP.
  elseif message:find("'S SUBSTITUTE BROKE!", 1, true) then
    clip, key = randomChoice("substitute_broken", SUBSTITUTE_BROKEN), "substitute_broken"

  -- Gen 2 mechanics with unique presentation text. These do not need engine-
  -- time guesses: each hook fires only when the corresponding result is on
  -- screen.
  elseif message:find(" MADE A SUBSTITUTE!", 1, true) then
    clip, key = SUBSTITUTE_CREATED,
      "substitute_created:" .. tostring(state.presentedMove and state.presentedMove.serial or message)

  -- Fly and Dig share Gen 2's charge machinery. Current engine source uses
  -- the EFFECT_FLY charge text for the semi-invulnerable charge path, so use
  -- the presented move ID to keep the Stadium call semantically correct even
  -- if DIG is rendered with the generic/flying charge text in this engine
  -- revision. If a later engine revision restores the explicit DIG text, the
  -- second predicate continues to work without changing the mapping.
  elseif move == MOVE_FLY and message:find(" FLEW UP HIGH!", 1, true) then
    clip, key = randomChoice("fly_charge", FLY_CHARGE),
      "fly_charge:" .. tostring(state.presentedMove.serial)
  elseif move == MOVE_DIG
      and (message:find(" DUG A HOLE!", 1, true)
        or message:find(" FLEW UP HIGH!", 1, true)) then
    clip, key = randomChoice("dig_charge", DIG_CHARGE),
      "dig_charge:" .. tostring(state.presentedMove.serial)

  -- The remaining two-turn charge messages are unique presentation seams.
  -- Stadium 2 has a generic charging-power reaction that fits these without
  -- inventing a move-specific state predicate.
  elseif message:find(" MADE A WHIRLWIND!", 1, true)
      or message:find(" TOOK IN SUNLIGHT!", 1, true)
      or message:find(" LOWERED ITS HEAD!", 1, true)
      or message:find(" IS GLOWING!", 1, true) then
    clip, key = GENERIC_CHARGE,
      "charge_move:" .. tostring(state.presentedMove and state.presentedMove.serial or message)

  -- Bide's continuation and release have explicit engine messages. They are
  -- safe to trigger by text alone because no other Gen 2 mechanic emits these
  -- phrases. Rotate the two storing variants and use the dedicated release
  -- call when the stored attack is unleashed.
  elseif message:find(" IS STORING ENERGY!", 1, true) then
    clip, key = randomChoice("bide_charge", BIDE_CHARGE), "bide_charge:" .. message
  elseif message:find(" UNLEASHED ENERGY!", 1, true) then
    clip, key = BIDE_RELEASE, "bide_release:" .. message

  elseif move == MOVE_TRANSFORM and message:find(" TRANSFORMED INTO ", 1, true) then
    clip, key = TRANSFORM_SUCCESS,
      "transform_success:" .. tostring(state.presentedMove.serial)

  elseif move == MOVE_ENCORE and message:find(" GOT AN ENCORE!", 1, true) then
    clip, key = ENCORE_START,
      "encore_start:" .. tostring(state.presentedMove.serial)
  elseif message:find("'S ENCORE ENDED!", 1, true) then
    clip, key = ENCORE_END, "encore_end"

  elseif message:find(" FLINCHED!", 1, true) then
    clip, key = FLINCH, "flinch"

  -- Non-Ghost Curse is presented as three ordinary stat-stage messages. Treat
  -- that three-line sequence as one Curse mechanic and suppress generic stat
  -- commentary for it below. Ghost Curse has its own explicit result text and
  -- residual-damage text.
  elseif move == MOVE_CURSE
      and (message:find("'S SPEED FELL!", 1, true)
        or message:find("'S ATTACK ROSE!", 1, true)
        or message:find("'S DEFENSE ROSE!", 1, true)) then
    local serial = state.presentedMove.serial
    if state.curseTradeoffSerial ~= serial then
      clip, key = CURSE_STAT_TRADEOFF, "curse_stat_tradeoff:" .. tostring(serial)
      state.curseTradeoffSerial = serial
    end
  elseif move == MOVE_CURSE
      and message:find(" CUT ITS OWN HP AND PUT A CURSE ON ", 1, true) then
    clip, key = CURSE_START,
      "curse_start:" .. tostring(state.presentedMove.serial)
  elseif message:find("'S HURT BY THE CURSE!", 1, true) then
    clip, key = CURSE_DAMAGE, "curse_damage"

  elseif move == MOVE_BELLY_DRUM and message:find("MAXIMIZED ATTACK!", 1, true) then
    clip, key = BELLY_DRUM,
      "belly_drum:" .. tostring(state.presentedMove.serial)

  elseif move == MOVE_ENDURE and message:find(" BRACED ITSELF!", 1, true) then
    clip, key = randomChoice("endure_start", ENDURE_START),
      "endure_start:" .. tostring(state.presentedMove.serial)
  elseif message:find(" ENDURED THE HIT!", 1, true) then
    clip, key = ENDURE_SURVIVED, "endure_survived"

  elseif message:find("BOTH POK", 1, true)
      and message:find("FAINT IN 3 TURNS!", 1, true) then
    clip, key = PERISH_SONG_START, "perish_song_start"
  elseif message:find("'S PERISH COUNT IS 1!", 1, true) then
    clip, key = PERISH_SONG_COUNT_ONE, "perish_song_count_one"

  elseif message:find("'S COVERED BY A VEIL!", 1, true) then
    clip, key = SAFEGUARD_START, "safeguard_start"
  elseif message:find(" IS PROTECTED BY SAFEGUARD!", 1, true) then
    clip, key = SAFEGUARD_ACTIVE, "safeguard_active"
  elseif message:find("'S SAFEGUARD FADED!", 1, true) then
    clip, key = SAFEGUARD_END, "safeguard_end"

  elseif message:find("SPIKES WERE SCATTERED ALL AROUND!", 1, true) then
    clip, key = SPIKES_SET, "spikes_set"

  elseif message:find(" FORESAW AN ATTACK!", 1, true) then
    clip, key = FUTURE_SIGHT_START, "future_sight_start"
  elseif message:find(" TOOK THE FUTURE SIGHT ATTACK!", 1, true) then
    clip, key = FUTURE_SIGHT_HIT, "future_sight_hit"

  elseif message:find(" CAN'T ESCAPE NOW!", 1, true) then
    clip, key = TRAPPED_CANNOT_ESCAPE, "mean_look_trap"

  elseif message:find(" WAS DISABLED!", 1, true) then
    clip, key = randomChoice("disable_success", DISABLE_SUCCESS), "disable_success"
  elseif message:find("'S MOVE IS NO LONGER DISABLED!", 1, true) then
    clip, key = DISABLE_END, "disable_end"
  end

  if clip then
    enqueue(clip, PRIORITY.mechanic, key)
    state.mechanicLineLatch = message
  end
end


local function flushPresentedWeatherAndItems()
  if not state.active then return end
  local ui = state.uiBattle
  if type(ui) ~= "table" or ui.phase ~= "resolving" then return end

  local message = normalizeMoveLine(ui.message)
  if message == "" then
    state.weatherLineLatch = nil
    state.heldItemLineLatch = nil
    return
  end

  -- Exact Gen 2 weather presentation text. Start/continue/end lines come from
  -- Battle's weather events/messages; sandstorm damage has its own message.
  if state.weatherLineLatch ~= message then
    local clip, key
    if message:find("STARTED TO RAIN!", 1, true) then
      clip, key = randomChoice("weather_rain_start", WEATHER_RAIN_START), "weather_rain_start"
    elseif message:find("RAIN CONTINUES TO FALL.", 1, true)
        or message:find("RAIN CONTINUES TO FALL!", 1, true) then
      clip, key = randomChoice("weather_rain_turn", WEATHER_RAIN_TURN), "weather_rain_turn"
    elseif message:find("THE RAIN STOPPED.", 1, true)
        or message:find("THE RAIN STOPPED!", 1, true) then
      clip, key = WEATHER_RAIN_END, "weather_rain_end"
    elseif message:find("THE SUNLIGHT GOT BRIGHT!", 1, true)
        or message:find("SUNLIGHT TURNED HARSH!", 1, true) then
      clip, key = randomChoice("weather_sun_start", WEATHER_SUN_START), "weather_sun_start"
    elseif message:find("THE SUNLIGHT IS STRONG.", 1, true)
        or message:find("THE SUNLIGHT IS STRONG!", 1, true) then
      clip, key = WEATHER_SUN_TURN, "weather_sun_turn"
    elseif message:find("THE SUNLIGHT FADED.", 1, true)
        or message:find("THE SUNLIGHT FADED!", 1, true) then
      clip, key = WEATHER_SUN_END, "weather_sun_end"
    elseif message:find("A SANDSTORM BREWED!", 1, true)
        or message:find("SANDSTORM STARTED!", 1, true) then
      clip, key = WEATHER_SAND_START, "weather_sand_start"
    elseif message:find("THE SANDSTORM RAGES.", 1, true)
        or message:find("THE SANDSTORM RAGES!", 1, true) then
      clip, key = randomChoice("weather_sand_turn", WEATHER_SAND_TURN), "weather_sand_turn"
    elseif message:find("THE SANDSTORM SUBSIDED.", 1, true)
        or message:find("THE SANDSTORM SUBSIDED!", 1, true) then
      clip, key = WEATHER_SAND_END, "weather_sand_end"
    elseif message:find(" IS BUFFETED BY THE SANDSTORM!", 1, true) then
      clip, key = WEATHER_SAND_DAMAGE, "weather_sand_damage"
    end
    if clip then
      enqueue(clip, PRIORITY.mechanic, key)
      state.weatherLineLatch = message
      return
    end
  end

  if state.heldItemLineLatch == message then return end

  -- Held-item result text names the consumed/active item. Match exact Gen 2
  -- item names so Stadium's item-specific berry calls are never guessed from
  -- HP/status changes alone.
  local clip, key
  if message:find("'S LEFTOVERS RESTORED HEALTH!", 1, true) then
    clip, key = LEFTOVERS, "held_leftovers"
  elseif message:find(" ATE THE BERRY JUICE!", 1, true) then
    clip, key = BERRY_HP.BERRY_JUICE, "held_berry_juice"
  elseif message:find(" ATE THE GOLD BERRY!", 1, true) then
    clip, key = BERRY_HP.GOLD_BERRY, "held_gold_berry"
  elseif message:find(" ATE THE BERRY!", 1, true) then
    clip, key = BERRY_HP.BERRY, "held_berry"
  elseif message:find("'S MYSTERY BERRY", 1, true) then
    clip, key = MYSTERY_BERRY, "held_mystery_berry"
  else
    for item, itemClip in pairs(BERRY_STATUS) do
      -- Item records normally expose cart display names (some are compact,
      -- e.g. PSNCUREBERRY), so accept both the literal id and a spaced form.
      local spaced = item:gsub("_", " ")
      if message:find("'S " .. item .. " CURED ITS STATUS!", 1, true)
          or message:find("'S " .. item .. " CURED ITS CONFUSION!", 1, true)
          or message:find("'S " .. spaced .. " CURED ITS STATUS!", 1, true)
          or message:find("'S " .. spaced .. " CURED ITS CONFUSION!", 1, true) then
        clip, key = itemClip, "held_status:" .. item
        break
      end
    end
  end

  if clip then
    enqueue(clip, PRIORITY.mechanic, key)
    state.heldItemLineLatch = message
  end
end

local function flushPresentedOngoingStatus()
  if not state.active then return end
  local ui = state.uiBattle
  if type(ui) ~= "table" or ui.phase ~= "resolving" then return end

  local message = normalizeMoveLine(ui.message)
  if message == "" then
    state.ongoingStatusLineLatch = nil
    return
  end
  if state.ongoingStatusLineLatch == message then return end

  -- Gen 2's turn-denial and residual-status messages are explicit UI seams.
  -- Trigger only from those displayed lines so these calls happen when the
  -- player sees the condition act, never from the earlier engine state change.
  local clip, key
  if message:find(" IS FAST ASLEEP!", 1, true) then
    clip, key = randomChoice("sleep_turn", SLEEP_TURN), "sleep_turn"
  elseif message:find(" IS FROZEN SOLID!", 1, true) then
    clip, key = randomChoice("freeze_turn", FREEZE_TURN), "freeze_turn"
  elseif message:find("'S FULLY PARALYZED!", 1, true) then
    clip, key = randomChoice("paralysis_turn", PARALYSIS_TURN), "paralysis_turn"
  elseif message:find(" IS HURT BY POISON!", 1, true)
      or message:find(" IS HURT BY ITS BURN!", 1, true)
      or message:find("'S HURT BY THE BURN!", 1, true) then
    clip, key = randomChoice("status_residual_damage", STATUS_RESIDUAL_DAMAGE),
      "status_residual_damage"
  elseif message:find("IT HURT ITSELF IN ITS CONFUSION!", 1, true) then
    clip, key = CONFUSION_SELF_HIT, "confusion_self_hit"
  elseif message:find(" IS CONFUSED!", 1, true) then
    clip, key = randomChoice("confusion_turn", CONFUSION_TURN), "confusion_turn"
  elseif message:find("'S CONFUSED NO MORE!", 1, true) then
    clip, key = CONFUSION_END, "confusion_end"
  end

  if clip then
    enqueue(clip, PRIORITY.status, key)
    state.ongoingStatusLineLatch = message
  end
end

local function flushPresentedStatChange()
  if not state.active then return end
  local ui = state.uiBattle
  if type(ui) ~= "table" or ui.phase ~= "resolving" then return end

  -- Gen 2 emits a dedicated `stage` queue event with the exact cart message,
  -- but the public mod event API does not expose that event directly. The UI
  -- message is therefore the presentation seam, just as it is for move/miss
  -- synchronization. Only the canonical rose/fell strings are accepted.
  local message = normalizeMoveLine(ui.message)

  -- Light Screen and Reflect print stat-like text but do not change stat
  -- stages. Their dedicated commentary is handled above using the exact move
  -- identity, so never also announce them as ordinary Defense/Sp.Def boosts.
  local presented = state.presentedMove and state.presentedMove.index or nil
  if presented == MOVE_LIGHT_SCREEN or presented == MOVE_REFLECT
      or presented == MOVE_CURSE then return end
  if message == "" then
    state.statLineLatch = nil
    return
  end
  if state.statLineLatch == message then return end

  local stat
  for _, label in ipairs({ "SPCL.ATK", "SPCL.DEF", "ATTACK", "DEFENSE",
      "SPEED", "ACCURACY", "EVASION" }) do
    if message:find("'S " .. label .. " ", 1, true) then
      stat = label
      break
    end
  end
  if not stat then return end

  local clip, key
  if message:find(" SHARPLY ROSE!", 1, true) or message:find(" ROSE!", 1, true) then
    local pool = STAT_UP[stat]
    if pool then
      clip = message:find(" SHARPLY ROSE!", 1, true) and pool[2] or pool[1]
      key = "stat_up:" .. stat
    end
  elseif message:find(" SHARPLY FELL!", 1, true) or message:find(" FELL!", 1, true) then
    clip = STAT_DOWN[stat]
    key = clip and ("stat_down:" .. stat) or nil
  end

  if clip then
    enqueue(clip, PRIORITY.stat, key)
    state.statLineLatch = message
  end
end

function Announcer.observeBattleRender(battle)
  if not state.active or type(battle) ~= "table" then return false end
  if normalizeBattle(battle) ~= state.engineBattle then return false end

  -- battle.overlay runs after the Gen 2 battle has actually been drawn. Latch
  -- only the move-use line here; queue/audio mutation remains in update() on
  -- the next logic tick, mirroring the proven Gen 1 render-latch pattern.
  state.uiBattle = battle
  local message = normalizeMoveLine(battle.message)
  if message == "" or not message:find(" USED ", 1, true) then
    state.renderedMoveLineSeen = nil
    return false
  end
  if message == state.renderedMoveLineSeen then return false end
  state.renderedMoveLineSeen = message
  state.renderedMoveLine = message
  return true
end

function Announcer.moveUsed(payload)
  if not payload or not sameBattle(payload.battle) then return false end
  local index = moveIndexFor(state.engineBattle, payload)
  if not index then return false end

  -- Do not play from the engine callback. It is intentionally ahead of the
  -- visual battle queue. Store every move in turn order; update() synchronizes
  -- each one to the actual Gen 2 "used MOVE" presentation line.
  state.pendingMoves[#state.pendingMoves + 1] = {
    index = index,
    name = moveDisplayName(payload),
    side = sideFor(state.engineBattle, payload.user, payload.side),
    serial = state.starts .. ":" .. tostring(#state.pendingMoves + 1),
  }
  return true
end

function Announcer.damageDealt(payload)
  if not payload or not sameBattle(payload.battle) then return false end

  local reactionIndex, reactionKey
  local critical = payload.crit
  if critical == nil then critical = payload.critical end
  if critical then
    reactionIndex = randomChoice("critical", CRITICAL)
    reactionKey = "critical"
  else
    local mult = effectiveness(payload)
    if mult and mult > 1 then
      reactionIndex = randomChoice("super", SUPER_EFFECTIVE)
      reactionKey = "super_effective"
    elseif mult and mult > 0 and mult < 1 then
      reactionIndex = randomChoice("resist", NOT_EFFECTIVE)
      reactionKey = "not_effective"
    end
  end
  if not reactionIndex then return false end

  -- battle.damage_dealt is emitted while the engine resolves the turn, which
  -- is earlier than the UI's "used MOVE" presentation. Associate the reaction
  -- with the newest unresolved move. flushPendingMoves() will enqueue the move
  -- name first and this reaction second when that UI line actually appears.
  local payloadMove = moveIndexFor(state.engineBattle, payload)
  for i = #state.pendingMoves, 1, -1 do
    local pending = state.pendingMoves[i]
    if not pending.damageReaction
        and (not payloadMove or pending.index == payloadMove) then
      pending.damageReaction = {
        index = reactionIndex,
        key = reactionKey .. ":" .. tostring(pending.serial),
      }
      return true
    end
  end

  -- Delayed damage that is not owned by a currently presented move (for
  -- example Future Sight) has no move-name seam to wait for. Preserve the
  -- reaction rather than dropping it.
  return enqueue(reactionIndex, PRIORITY.damage, reactionKey .. ":orphan")
end

function Announcer.statusInflicted(payload)
  if not payload or not sameBattle(payload.battle) then return false end
  local status = payload.status or payload.kind or payload.condition
  status = status and tostring(status):upper() or nil

  -- Rest emits the normal sleep status hook during engine resolution, before
  -- the UI reaches Rest's own result text. Suppress the generic "fell asleep"
  -- Stadium call in that one case; flushPresentedMechanics() will play the
  -- dedicated Rest line at the correct presentation time instead.
  if status == "SLP" or status == "SLEEP" then
    local pending = state.pendingMoves[#state.pendingMoves]
    local move = (pending and pending.index)
      or (state.presentedMove and state.presentedMove.index)
    if move == MOVE_REST then return true end
  end

  local clip = status and STATUS_CLIP[status]
  if not clip then return false end
  return enqueue(clip, PRIORITY.status, "status:" .. status)
end

local function usableTeamCount(side)
  local engine = state.engineBattle
  local party = side == "player" and engine and engine.party
    or side == "enemy" and engine and engine.enemyParty
  if type(party) ~= "table" then return nil, nil end
  local total, usable = 0, 0
  for _, mon in ipairs(party) do
    if type(mon) == "table" then
      total = total + 1
      if (tonumber(mon.hp) or 0) > 0 then usable = usable + 1 end
    end
  end
  return usable, total
end

local function pendingDoubleKo()
  local player, enemy
  for i, item in ipairs(state.pendingFaints) do
    if item.side == "player" and not player then player = i end
    if item.side == "enemy" and not enemy then enemy = i end
  end
  return player, enemy
end

local function removePendingFaint(index)
  if index and state.pendingFaints[index] then
    return table.remove(state.pendingFaints, index)
  end
  return nil
end

-- Stadium 2 has exact remaining-team callouts for the 3/2/1 combinations
-- used by Stadium teams. Directional pairs are treated as unordered count
-- states: e.g. 1140 ("3 to 2") and 1142 ("2 to 3") both describe the exact
-- same {3,2} remaining-team state without assigning either number to player or
-- enemy. This avoids guessing the announcer's screen-side ordering while still
-- using every count line whose spoken content is literally true.
local function enqueueExactRemainingCount()
  local player = usableTeamCount("player")
  local enemy = usableTeamCount("enemy")
  if not player or not enemy then return false end

  local hi, lo = math.max(player, enemy), math.min(player, enemy)
  local key = tostring(hi) .. "v" .. tostring(lo)
  if key == state.remainingCountKey then return false end

  local clip
  if hi == 3 and lo == 2 then
    clip = randomChoice("remaining_three_two", REMAINING_THREE_TWO)
  elseif hi == 3 and lo == 1 then
    clip = randomChoice("remaining_three_one", REMAINING_THREE_ONE)
  elseif hi == 2 and lo == 2 then
    clip = REMAINING_TWO_EACH
  elseif hi == 2 and lo == 1 then
    clip = randomChoice("remaining_two_one", REMAINING_TWO_ONE)
  elseif hi == 1 and lo == 1 then
    clip = randomChoice("remaining_one_each", REMAINING_ONE_EACH)
  else
    return false
  end

  state.remainingCountKey = key
  return enqueue(clip, PRIORITY.faint - 1, "remaining_count:" .. key .. ":" .. tostring(state.starts))
end

local function flushPresentedFaints()
  if not state.active then return end
  local ui = state.uiBattle
  if type(ui) ~= "table" or ui.phase ~= "resolving" then return end

  local message = normalizeMoveLine(ui.message)
  if message == "" then
    state.faintLineLatch = nil
    return
  end

  -- The Gen 2 engine explicitly presents this line for OHKO moves before the
  -- faint event reaches the screen. Arm the next faint so Stadium can use its
  -- dedicated one-hit-KO pool at the actual faint presentation seam.
  if message:find("IT'S A ONE-HIT KO!", 1, true) then
    state.oneHitKoArmed = true
    return
  end

  if not message:find(" FAINTED!", 1, true) then return end
  if state.faintLineLatch == message then return end
  state.faintLineLatch = message

  if state.suppressedFaintLines > 0 then
    state.suppressedFaintLines = state.suppressedFaintLines - 1
    return
  end
  if #state.pendingFaints == 0 then return end

  -- The engine resolves the full turn before BattleState presents its queue,
  -- so a true double KO has both faint callbacks pending before the first
  -- post-slide "fainted!" line is visible. Announce it once and suppress the
  -- second faint line rather than calling two ordinary KOs.
  local playerIndex, enemyIndex = pendingDoubleKo()
  if playerIndex and enemyIndex then
    local hi, lo = math.max(playerIndex, enemyIndex), math.min(playerIndex, enemyIndex)
    removePendingFaint(hi)
    removePendingFaint(lo)
    state.oneHitKoArmed = false
    state.suppressedFaintLines = 1
    enqueue(randomChoice("double_ko", DOUBLE_KO), PRIORITY.faint,
      "double_ko:" .. tostring(state.starts))
    enqueueExactRemainingCount()
    return
  end

  local pending = removePendingFaint(1)
  if not pending then return end

  local clip, key
  if state.oneHitKoArmed then
    clip, key = randomChoice("one_hit_ko", ONE_HIT_KO), "one_hit_ko"
    state.oneHitKoArmed = false
  elseif pending.lastPokemon then
    clip, key = LAST_POKEMON_FAINTED, "last_pokemon_fainted:" .. tostring(pending.side)
  else
    clip, key = randomChoice("faint", FAINT), "faint:" .. tostring(pending.side)
  end
  enqueue(clip, PRIORITY.faint, key .. ":" .. tostring(state.starts))
  enqueueExactRemainingCount()

  -- Post-KO replacement commentary is intentionally disabled for now. Keep the
  -- original wiring commented out so clips 1156-1161 can be revisited later
  -- without losing the known context/timing seam.
  -- if pending.replacementExpected then
  --   enqueue(randomChoice("post_ko_replacement", POST_KO_REPLACEMENT), PRIORITY.faint - 2,
  --     "post_ko_replacement:" .. tostring(pending.side) .. ":" .. tostring(state.starts))
  -- end
end

function Announcer.fainted(payload)
  if not payload or not sameBattle(payload.battle) then return false end

  -- battle.fainted is an engine-time callback. Gen 2's BattleState first runs
  -- MonFaintedAnimation and only then shows the faint text, so queue metadata
  -- here and let update() release the call on that UI seam.
  local side = sideFor(state.engineBattle, payload.battler, payload.side)
  if not side then return false end
  local usable, total = usableTeamCount(side)
  state.pendingFaints[#state.pendingFaints + 1] = {
    side = side,
    battler = payload.battler,
    lastPokemon = total and total > 1 and usable == 0 or false,
    replacementExpected = usable ~= nil and usable > 0 or false,
  }
  return true
end

function Announcer.finishBattle(payload)
  if not payload or not sameBattle(payload.battle) then return false end

  local rawBattle = payload.battle
  local wrapped = type(rawBattle) == "table" and rawget(rawBattle, "battle")
  local isUiEnd = type(wrapped) == "table" and wrapped == state.engineBattle
  local result = payload.result

  -- Gen 2 raises battle.ended twice at two deliberately different seams:
  --   1) Battle:endBattle() in the pure engine, as soon as the outcome is
  --      decided; the UI may still have faint/EXP/result events to present.
  --   2) BattleState at the actual screen-exit seam, with payload.battle being
  --      the UI wrapper whose `.battle` is the same engine object.
  -- Do not tear down on the engine-time callback. Keeping the battle active is
  -- what lets the final post-animation "fainted!" line flush its pending KO.
  if not isUiEnd then
    state.pendingBattleEnd = { result = result }
    return true
  end

  -- The UI-end callback occurs only after its presentation queue has drained,
  -- so every final faint seam has already had a chance to enqueue commentary.
  -- Append the generic Stadium result line after those calls, then release the
  -- battle references. The audio queue itself is intentionally allowed to
  -- finish after state.active becomes false.
  local finalResult = result or (state.pendingBattleEnd and state.pendingBattleEnd.result)
  if finalResult ~= "run" and finalResult ~= "escape" then
    enqueue(BATTLE_END_GENERIC, PRIORITY.result, "battle_end:" .. tostring(state.starts))
  end
  state.pendingBattleEnd = nil
  state.active = false
  state.engineBattle = nil
  state.uiBattle = nil
  return true
end

function Announcer.update(dt, game)
  if not enabled() then
    resetPlayback()
    return
  end

  flushPendingNames()
  flushPendingMoves()
  flushPresentedMoveOutcome()
  flushPresentedMechanics()
  flushPresentedWeatherAndItems()
  flushPresentedOngoingStatus()
  flushPresentedFaints()
  flushPresentedStatChange()

  if state.current then
    currentStillPlaying()
  end
  if not state.current and state.gap > 0 then
    state.gap = math.max(0, state.gap - math.max(0, tonumber(dt) or 0))
  end

  updateDecisionIdle(dt, game)

  -- Gen 1's flow beat becomes eligible after every two presented moves, then
  -- waits for a short genuinely quiet gap. Keep the same cadence here while
  -- requiring Gen 2 to be back at an actual player decision screen.
  if state.flowPending and quietDecisionPhase() and not state.current
      and #state.queue == 0 and #state.pendingMoves == 0
      and #state.pendingFaints == 0 and state.gap <= 0 then
    state.idle = state.idle + math.max(0, tonumber(dt) or 0)
    if state.idle >= FLOW_IDLE_SECONDS then
      state.idle = 0
      startFlowCommentary()
    end
  else
    state.idle = 0
  end

  if not state.current and state.gap <= 0 then startNext() end
end

function Announcer.stop()
  resetPlayback()
  state.active = false
  state.engineBattle = nil
  state.uiBattle = nil
end

function Announcer.status()
  local errors = {}
  for index, message in pairs(state.loadErrors) do
    errors[#errors + 1] = { index = index, error = message }
  end
  table.sort(errors, function(a, b) return a.index < b.index end)
  return {
    packReady = packReady(),
    packError = state.packError,
    active = state.active,
    starts = state.starts,
    openingIntroClip = state.openingIntroClip,
    openingIntroClass = state.openingIntroClass,
    current = state.currentIndex,
    queued = #state.queue,
    missing = state.missing,
    loadErrors = errors,
    engineBattle = state.engineBattle ~= nil,
    uiBattle = state.uiBattle ~= nil,
    pendingNames = state.pendingNames,
    announcedSpecies = state.announcedSpecies,
    pendingMoves = state.pendingMoves,
    moveLineLatch = state.moveLineLatch,
    renderedMoveLine = state.renderedMoveLine,
    outcomeLineLatch = state.outcomeLineLatch,
    weatherLineLatch = state.weatherLineLatch,
    heldItemLineLatch = state.heldItemLineLatch,
    ongoingStatusLineLatch = state.ongoingStatusLineLatch,
    pendingFaints = #state.pendingFaints,
    pendingBattleEnd = state.pendingBattleEnd,
    faintLineLatch = state.faintLineLatch,
    oneHitKoArmed = state.oneHitKoArmed,
    remainingCountKey = state.remainingCountKey,
    curseTradeoffSerial = state.curseTradeoffSerial,
    presentedMove = state.presentedMove,
    moveCount = state.moveCount,
    flowPending = state.flowPending,
    flowMoves = state.flowMoves,
    decisionIdle = state.decisionIdle,
    decisionPrompted = state.decisionPrompted,
  }
end

Announcer.PRIORITY = PRIORITY
Announcer.MAJOR_TRAINER_CLASS = MAJOR_TRAINER_CLASS
Announcer.SPECIAL_TRAINER_INTRO = SPECIAL_TRAINER_INTRO
Announcer.FIRST_MOVE = FIRST_MOVE
Announcer.FLOW = FLOW
Announcer.FLOW_IDLE_SECONDS = FLOW_IDLE_SECONDS
Announcer.FLOW_EVERY_MOVES = FLOW_EVERY_MOVES
Announcer.DECISION_IDLE = DECISION_IDLE
Announcer.DECISION_IDLE_SECONDS = DECISION_IDLE_SECONDS
Announcer.CRITICAL = CRITICAL
Announcer.SUPER_EFFECTIVE = SUPER_EFFECTIVE
Announcer.NOT_EFFECTIVE = NOT_EFFECTIVE
Announcer.STATUS_CLIP = STATUS_CLIP
Announcer.REMAINING_THREE_TWO = REMAINING_THREE_TWO
Announcer.REMAINING_THREE_ONE = REMAINING_THREE_ONE
Announcer.REMAINING_TWO_EACH = REMAINING_TWO_EACH
Announcer.REMAINING_TWO_ONE = REMAINING_TWO_ONE
Announcer.REMAINING_ONE_EACH = REMAINING_ONE_EACH
Announcer.STAT_UP = STAT_UP
Announcer.STAT_DOWN = STAT_DOWN
Announcer.HP_RESTORED = HP_RESTORED
Announcer.REST_SLEEP = REST_SLEEP
Announcer.STATUS_CURED = STATUS_CURED
Announcer.LIGHT_SCREEN_ACTIVE = LIGHT_SCREEN_ACTIVE
Announcer.REFLECT_ACTIVE = REFLECT_ACTIVE
Announcer.LIGHT_SCREEN_END = LIGHT_SCREEN_END
Announcer.REFLECT_END = REFLECT_END
Announcer.SUBSTITUTE_BROKEN = SUBSTITUTE_BROKEN
Announcer.WEATHER_SYNC = true
Announcer.HELD_ITEM_SYNC = true
Announcer.WEATHER_RAIN_START = WEATHER_RAIN_START
Announcer.WEATHER_RAIN_TURN = WEATHER_RAIN_TURN
Announcer.WEATHER_RAIN_END = WEATHER_RAIN_END
Announcer.WEATHER_SUN_START = WEATHER_SUN_START
Announcer.WEATHER_SUN_TURN = WEATHER_SUN_TURN
Announcer.WEATHER_SUN_END = WEATHER_SUN_END
Announcer.WEATHER_SAND_START = WEATHER_SAND_START
Announcer.WEATHER_SAND_TURN = WEATHER_SAND_TURN
Announcer.WEATHER_SAND_END = WEATHER_SAND_END
Announcer.WEATHER_SAND_DAMAGE = WEATHER_SAND_DAMAGE
Announcer.BERRY_STATUS = BERRY_STATUS
Announcer.BERRY_HP = BERRY_HP
Announcer.MYSTERY_BERRY = MYSTERY_BERRY
Announcer.LEFTOVERS = LEFTOVERS
Announcer.ONGOING_STATUS_SYNC = true
Announcer.SLEEP_TURN = SLEEP_TURN
Announcer.FREEZE_TURN = FREEZE_TURN
Announcer.PARALYSIS_TURN = PARALYSIS_TURN
Announcer.STATUS_RESIDUAL_DAMAGE = STATUS_RESIDUAL_DAMAGE
Announcer.CONFUSION_SELF_HIT = CONFUSION_SELF_HIT
Announcer.CONFUSION_TURN = CONFUSION_TURN
Announcer.CONFUSION_END = CONFUSION_END
Announcer.BATTLE_END_GENERIC = BATTLE_END_GENERIC
Announcer.CLIP_COUNT = CLIP_COUNT
Announcer.clipRelative = clipRelative
Announcer.normalizeBattle = normalizeBattle
Announcer.scope = scope
Announcer.eligible = eligible
Announcer.trainerClass = trainerClass
Announcer.specialTrainerIntro = specialTrainerIntro
Announcer.EXACT_ONLY = true
Announcer.CLEAN_GEN2_RUNTIME = true
Announcer.SENDOUT_SYNC = true
Announcer.MOVE_DISPLAY_SYNC = true
Announcer.DAMAGE_REACTION_SYNC = true
Announcer.SWITCH_COMMENTARY_SYNC = true
Announcer.MISS_NO_EFFECT_SYNC = true
Announcer.RECOVERY_SCREEN_SETUP_SYNC = true
Announcer.VOLUNTARY_SWITCH = VOLUNTARY_SWITCH
Announcer.ATTACK_MISSED = ATTACK_MISSED
Announcer.NO_EFFECT = NO_EFFECT

return Announcer
