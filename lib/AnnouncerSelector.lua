-- Select the announcer implementation that belongs to the active cartridge.
-- Red / Blue / Yellow -> Pokemon Stadium (Gen1)
-- Gold / Silver / Crystal -> Pokemon Stadium 2 (Gen2)

local namespace = ...
local GameVersion = namespace.engineRequire("src.core.GameVersion")

local generation = GameVersion.generation and GameVersion.generation() or 1
local version = GameVersion.get and GameVersion.get() or nil

local moduleName
if generation == 2
    or version == "gold" or version == "silver" or version == "crystal" then
  moduleName = "Gen2Announcer"
else
  moduleName = "Gen1Announcer"
end

local Announcer = namespace.require(moduleName)
Announcer.activeGeneration = generation
Announcer.activeVersion = version
Announcer.moduleName = moduleName

return Announcer
