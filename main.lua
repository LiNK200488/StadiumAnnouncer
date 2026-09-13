-- Stadium Announcer: generation-aware Pokemon Stadium commentary.
local mod = ...
local modules = {}
local namespace = { mod = mod, path = mod.path, engineRequire = require }

local function moduleChunk(name)
  local rel = "lib/" .. name .. ".lua"
  local source = mod:read(rel)
  if not source then error("STADIUM_ANNOUNCER: missing " .. rel, 0) end
  local chunk, err = load(source, "@" .. mod.path .. "/" .. rel)
  if not chunk then error(err, 0) end
  return chunk
end

function namespace.require(name)
  if modules[name] ~= nil then return modules[name] end
  modules[name] = moduleChunk(name)(namespace)
  return modules[name]
end

local Announcer = namespace.require("AnnouncerSelector")

mod.exports.version = "2.0.0"
mod.exports.activeGeneration = Announcer.activeGeneration
mod.exports.activeVersion = Announcer.activeVersion
mod.exports.announcerModule = Announcer.moduleName
mod.exports.announcerStatus = Announcer.status

mod.options:define({
  { key="announcer_scope", label="ANNOUNCER BATTLES", type="choice", default="gym", choices={
    { "GYM / ELITE 4 / CHAMPION", "gym" },
    { "ALL TRAINER BATTLES", "trainer" },
    { "ALL BATTLES", "all" },
  } },
})

mod.hooks:wrap("input.step", function(next, game, dt)
  local result = next(game, dt)
  Announcer.update(dt, game)
  return result
end)

-- Both generations use the rendered battle state only as a presentation
-- latch. Gen 1 uses it for the proven opening enemy-name seam; Gen 2 uses it
-- to retain very short "used MOVE" lines (for example Protect / Spikes) until
-- the next logic tick. Neither implementation mutates audio queues while draw
-- is running.
if Announcer.observeBattleRender then
  mod.hooks:wrap("battle.overlay", function(next, battle)
    local result = next(battle)
    Announcer.observeBattleRender(battle)
    return result
  end)
end

mod.events:on("battle.started", function(payload)
  Announcer.beginBattle(payload and payload.battle, payload)
end)
mod.events:on("battle.move_used", function(payload) Announcer.moveUsed(payload) end)
mod.events:on("battle.damage_dealt", function(payload) Announcer.damageDealt(payload) end)
mod.events:on("battle.battler_switched", function(payload) Announcer.battlerSwitched(payload) end)
mod.events:on("battle.status_inflicted", function(payload) Announcer.statusInflicted(payload) end)
mod.events:on("battle.fainted", function(payload) Announcer.fainted(payload) end)
mod.events:on("battle.ended", function(payload) Announcer.finishBattle(payload) end)
