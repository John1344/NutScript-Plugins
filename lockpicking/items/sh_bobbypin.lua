local PLUGIN = PLUGIN or nut.plugin.list.lockpicking -- Please don't rename plugin folder else PLUGIN variable will be nil in NS beta
if (!PLUGIN) then
	ErrorNoHalt( 'Lockpicking plugin directory may have been changed and thus it causes lua errors. Please name it "lockpicking"\n' )
end

local ITEM = ITEM

ITEM.name = "Bobby pin box"
ITEM.desc = "A box that contains bobbypins used to lockpick."
ITEM.model = "models/props_lab/box01a.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.price = 90
ITEM.isStackable = false
--
ITEM.isBobbypinBox = true
ITEM.pinAmount = 4
ITEM.solidity = 1
ITEM.pinHealth = 100
ITEM.flag = "y"


function ITEM:GetQuantity()
	return self:getData("quantity", ITEM.pinAmount)
end

function ITEM:SetQuantity(n)
	self:setData("quantity", n)
end


function ITEM:BreakPin()
	local oldQuantity = self:GetQuantity()

	if ( oldQuantity == 1 ) then
		self:remove()
		return false
	else
		self:setData("health", ITEM.pinHealth)
		self:SetQuantity(oldQuantity - 1)
		return true
	end
end


local conditions = {
	[85] = {"lpExcellent", {0, 179, 0}},
	[55] = {"lpWell", {255, 255, 0}},
	[35] = {"lpWeak", {255, 140, 26}},
	[25] = {"lpBad", {255, 51, 0}},
	[0] = {"lpVBad", {102, 0, 0}}
}

function ITEM:GetCondition()
	local condition = conditions[0]
	local health = self:getData("health", ITEM.pinHealth)

	for k, v in SortedPairs(conditions) do
		if ( health >= k ) then
			condition = v
		else
			break
		end
	end

	return condition[1], condition[2]
end


function ITEM:IsInBusinnessMenu()
	return (self:getID() == 0)
end

function ITEM:getDesc()
	local desc = self.desc

	if ( self:IsInBusinnessMenu() ) then
		return desc
	else
		local newDesc = ""

		if ( desc and desc ~= "" and desc ~= "noDesc" ) then
			newDesc = desc.."\n"
		end

		local state, color = self:GetCondition()
		local localizedText = L("lpCondition", L(state))

		newDesc = newDesc.."<color="..color[1]..", "..color[2]..", "..color[3]..">"..localizedText.."</color>"
		return newDesc
	end
end

function ITEM:paintOver(item, w, h)
	local quantity = item:GetQuantity()
	draw.SimpleText(quantity, "DermaDefault", 5, h-5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 1, color_black)
end

local function IsDoorLocked(ent)
	return ent:GetSaveTable().m_bLocked or ent.locked or false
end

local function getDoorLockpicker(door)
	local s = door.LockpickSession

	if (s) then
		return s.Player
	end
end

ITEM.functions.use = {
	name = "lpPick",
	tip = "useTip",
	icon = "icon16/wrench.png",
	onRun = function(item)
		local client = item.player
		local ent = PLUGIN:GetEntityLookedAt(client, PLUGIN.CONFIG.MaxLookDistance)

		if ( not IsDoorLocked(ent) ) then
			--ply:notifyLocalized("lpNotLocked")
			return false
		elseif ( getDoorLockpicker(ent) ) then
			--ply:notifyLocalized("lpAlrLpcked")
			return false
		end

		local s = PLUGIN:StartSession(ent, client, item)

		if (type(s) == "string") then
			client:notify(s)
		end
		
		return false
	end,
	onCanRun = function(item)
		local ply; if (SERVER) then ply = item.player else ply = LocalPlayer() end
		local ent = PLUGIN:GetEntityLookedAt(ply, PLUGIN.CONFIG.MaxLookDistance)

		if ( not IsValid(ent) or not ent:isDoor() ) then
			return false
		end

		if ( SERVER ) then
			if ( not IsDoorLocked(ent) ) then
				ply:notifyLocalized("lpNotLocked")
				return false
			elseif ( getDoorLockpicker(ent) ) then
				ply:notifyLocalized("lpAlrLpcked")
				return false
			end
		end

		return true
	end
}


function ITEM:onRemoved()
    local s = self.LockpickSession

	if ( s ) then
		s:Stop()
	end
end