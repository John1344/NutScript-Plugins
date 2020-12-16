PLUGIN.name = "Backpacks"
PLUGIN.author = "John"
PLUGIN.desc = "Adds backpacks"

PLUGIN.bagInstances = PLUGIN.bagInstances or {}

PLUGIN.bagUniqueIDs = {
    [1] = {
        model = "models/fallout 3/backpack_1.mdl",
        pos = Vector(-6.90, -4.10, 1.61),
		ang = Angle(176.101, 75.099, 86.679),
        bone = "ValveBiped.Bip01_Spine4"
    },
    [2] = {
        model = "models/fallout 3/backpack_2.mdl",
        pos = Vector(-11.05, -4, 1.37),
		ang = Angle(174.086, 70.797, 89.162),
        bone = "ValveBiped.Bip01_Spine4"
    },
    [3] = {
        model = "models/fallout 3/backpack_6.mdl",
        pos = Vector(-11.76, -8.15, 3.03),
		ang = Angle(180.226, 76.497, 88.528),
        bone = "ValveBiped.Bip01_Spine4"
    }
}

nut.util.include("sv_plugin.lua")
nut.util.include("cl_plugin.lua")