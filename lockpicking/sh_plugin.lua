PLUGIN.name = "Lockpicking"
PLUGIN.author = "github.com/John1344"
PLUGIN.desc = "Allows to pick locks with bobby pins"


PLUGIN.CONFIG = {
    UnlockSize = 4,
    WeakSize = 40,
    UnlockMaxAngle = -90,
    HardMaxAngle = -30,
    TurningSpeed = 90,
    ReleasingSpeed = 200,
    SpamTime = 0.1,
	MaxLookDistance = 50,
	FadeTime = 4
}


-- Lockpick stop messages
PLUGIN.STOP_AFK = 1
PLUGIN.STOP_FAR = 2

PLUGIN.Messages = {
	"lpAfk",
	"lpTooFar"
}

function PLUGIN:GetEntityLookedAt(player, maxDistance)
    local data = {}
    data.filter = player
    data.start = player:GetShootPos()
    data.endpos = data.start + player:GetAimVector()*maxDistance

    return util.TraceLine(data).Entity
end

nut.util.include("sv_plugin.lua")
nut.util.include("cl_plugin.lua")

nut.util.include("ui/cl_interface.lua")
nut.util.include("ui/cl_lp_interface.lua")
nut.util.include("ui/basic/cl_button.lua")
nut.util.include("ui/basic/cl_label.lua")