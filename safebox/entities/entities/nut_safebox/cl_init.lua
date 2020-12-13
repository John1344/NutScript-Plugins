include("shared.lua")

ENT.DrawEntityInfo = true

local COLOR_LOCKED = Color(242, 38, 19)
local COLOR_UNLOCKED = Color(135, 211, 124)
local toScreen = FindMetaTable("Vector").ToScreen
local colorAlpha = ColorAlpha
local drawText = nut.util.drawText
local configGet = nut.config.get

function ENT:onDrawEntityInfo(alpha)
	local locked = self.getNetVar(self, "locked", false)
	local position = toScreen(self.LocalToWorld(self, self.OBBCenter(self)))
	local x, y = position.x, position.y

	y = y - 20
	local tx, ty = nut.util.drawText(locked and "" or "", x, y, colorAlpha(locked and COLOR_LOCKED or COLOR_UNLOCKED, alpha), 1, 1, "nutIconsMedium", alpha * 0.65)
	y = y + ty*.9

	local tx, ty = drawText(L("Safebox"), x, y, colorAlpha(configGet("color"), alpha), 1, 1, nil, alpha * 0.65)
	y = y + ty + 1

	drawText(L(""), x, y, colorAlpha(color_white, alpha), 1, 1, nil, alpha * 0.65)
end
