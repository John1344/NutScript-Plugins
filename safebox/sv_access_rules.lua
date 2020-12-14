local PLUGIN = PLUGIN or nut.plugin.list.safebox -- Please don't rename plugin folder else PLUGIN variable will be nil in NS beta
if (!PLUGIN) then
	ErrorNoHalt( 'safebox plugin directory may have been changed and thus it causes lua errors. Please name it "safebox"\n' )
end

local PROHIBITED_ACTIONS = {
	["Equip"] = true,
	["EquipUn"] = true,
}

function PLUGIN:CanPlayerInteractItem(client, action, itemObject, data)
	if (nut.version != "2.0") then return end
	
	local inventory = nut.item.inventories[itemObject.invID]

	if (inventory and inventory.isSafebox == true) then
		if (PROHIBITED_ACTIONS[action]) then
			return false, "forbiddenActionStorage"
		end
	end
end

local MAX_ACTION_DISTANCE = 128
local RULES = {
	AccessIfStorageReceiver = function(inventory, action, context)
		-- Ensure correct storage entity and player.
		local client = context.client
		if (not IsValid(client)) then return end

		local char = client:getChar()
		if (not char) then return end

		local safeboxData = PLUGIN.charInventoryIDs[char:getID()]
		if (not safeboxData) then return end
		local safeboxInvID = safeboxData[1]

		local storageInv = nut.item.inventories[safeboxInvID]

		local storage = context.safebox or client.nutSafeboxEntity
		if (not IsValid(storage)) then return end
		if (storageInv ~= inventory) then return end

		-- If the player is too far away from storage, then ignore.
		local distance = storage:GetPos():Distance(client:GetPos())
		if (distance > MAX_ACTION_DISTANCE) then return false end

		-- Allow if the player is a receiver of the storage.
		if (storage.receivers[client]) then
			return true
		end
	end
}

function PLUGIN:SafeboxInventorySet(inventory)
	inventory:addAccessRule(RULES.AccessIfStorageReceiver)
end

return RULES
