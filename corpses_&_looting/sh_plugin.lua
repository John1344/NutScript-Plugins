PLUGIN.name = "Looting"
PLUGIN.author = "github.com/John1344"
PLUGIN.desc = "Allows to search players corpses."
PLUGIN.corpseMaxDist = 80

-- Includes
local dir = PLUGIN.folder.."/"

nut.util.includeDir(dir.."corpses", true, true)
nut.util.include("loot/sv_hooks.lua")
nut.util.include("loot/sv_networking.lua")
nut.util.include("loot/sv_access_rules.lua")
nut.util.include("loot/cl_hooks.lua")