-- Stadium Announcer: Pokemon Stadium voice lines only for Gen1Recomp.
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
local Announcer = namespace.require("Announcer")
mod.exports.version = "1.0.3"
mod.exports.announcerStatus = Announcer.status
mod.options:define({
  { key="announcer", label="STADIUM ANNOUNCER", type="toggle", default=true },
  { key="announcer_scope", label="ANNOUNCER BATTLES", type="choice", default="gym", choices={
    { "GYM / ELITE 4 / CHAMPION", "gym" }, { "ALL TRAINER BATTLES", "trainer" }, { "ALL BATTLES", "all" },
  } },
})
mod.hooks:wrap("input.step", function(next, game, dt)
  local result = next(game, dt)
  Announcer.update(dt, game)
  return result
end)
mod.events:on("battle.started", function(payload) Announcer.beginBattle(payload and payload.battle) end)
mod.events:on("battle.move_used", function(payload) Announcer.moveUsed(payload) end)
mod.events:on("battle.damage_dealt", function(payload) Announcer.damageDealt(payload) end)
mod.events:on("battle.battler_switched", function(payload) Announcer.battlerSwitched(payload) end)
mod.events:on("battle.status_inflicted", function(payload) Announcer.statusInflicted(payload) end)
mod.events:on("battle.fainted", function(payload) Announcer.fainted(payload) end)
mod.events:on("battle.ended", function(payload) Announcer.finishBattle(payload) end)
