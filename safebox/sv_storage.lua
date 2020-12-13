local PLUGIN = PLUGIN

PLUGIN.charInventoryIDs = PLUGIN.charInventoryIDs or {}

function PLUGIN:saveStorage()
  	local data = {}

	for _, entity in ipairs(ents.FindByClass("nut_safebox")) do
		data[#data + 1] = {
			entity:GetPos(),
			entity:GetAngles(),
		}
	  end
	  
  	self:setData({self.charInventoryIDs, data})
end

function PLUGIN:SaveData()
	self:saveStorage()
end

function PLUGIN:StorageItemRemoved(entity, inventory)
	self:saveStorage()
end

function PLUGIN:LoadData()
	local gData = self:getData() or {{}, {}}

	self.charInventoryIDs = gData[1] or {}

	local data = gData[2] or {}

	for _, info in ipairs(data) do
		local position, angles = unpack(info)

		local storage = ents.Create("nut_safebox")
		storage:SetPos(position)
		storage:SetAngles(angles)
		storage:Spawn()
		storage:SetSolid(SOLID_VPHYSICS)
		storage:PhysicsInit(SOLID_VPHYSICS)

		local physObject = storage:GetPhysicsObject()

		if (physObject) then
			physObject:EnableMotion()
		end
	end

	self.loadedData = true
end

-- 1.1 beta
function PLUGIN:OnCharacterDelete(client, id)
	local data = self.charInventoryIDs[id]
	if (!data) then return end

	local invId = data[1]

	nut.item.inventories[invId] = nil
	nut.db.query("DELETE FROM nut_items WHERE _invID = " .. invId)
	nut.db.query("DELETE FROM nut_inventories WHERE _invID = " .. invId)

	self.charInventoryIDs[id] = nil
end

-- 1.1
function PLUGIN:OnCharDelete(client, id, CurrentChar)
	local data = self.charInventoryIDs[id]
	if (!data) then return end

	local invId = data[1]

	nut.item.inventories[invId] = nil
	nut.db.query("DELETE FROM nut_items WHERE _invID = " .. invId)
	nut.db.query("DELETE FROM nut_inventories WHERE _invID = " .. invId)

	self.charInventoryIDs[id] = nil
end

--[[ Money management ]]--
function PLUGIN:WidthdrawMoney(client, corpse, amount)
	local data = self.charInventoryIDs[client:getChar():getID()]
	if (!data) then return end

	local oldMoney = data[2]

	if ( amount <= oldMoney ) then

		self.charInventoryIDs[client:getChar():getID()][2] = oldMoney - amount
		netstream.Start(client, "safeboxMoney", self.charInventoryIDs[client:getChar():getID()][2])

		client:getChar():giveMoney(amount)

	end

end

netstream.Hook("safeboxWdMny", function(client, amount)

	if ( not isnumber(amount) ) then return end
	if ( not IsValid(client) ) then return end
	if ( not client:getChar() ) then return end

	local clientSafebox = client.nutSafeboxEntity
	if ( not IsValid(clientSafebox) ) then return end

	local distance = clientSafebox:GetPos():Distance(client:GetPos())
	if (distance > 128) then return false end

	PLUGIN:WidthdrawMoney(client, clientSafebox, amount)

end)

function PLUGIN:DepositMoney(client, corpse, amount)
	local data = self.charInventoryIDs[client:getChar():getID()]
	if (!data) then return end

	local oldMoney = data[2]
	local oldCharMoney = client:getChar():getMoney()

	if ( amount <= oldCharMoney ) then

		self.charInventoryIDs[client:getChar():getID()][2] = oldMoney + amount

		netstream.Start(client, "safeboxMoney", self.charInventoryIDs[client:getChar():getID()][2])

		client:getChar():takeMoney(amount)

	end

end

netstream.Hook("safeboxDpMny", function(client, amount)

	if ( not isnumber(amount) ) then return end
	if ( not IsValid(client) ) then return end
	if ( not client:getChar() ) then return end

	local clientSafebox = client.nutSafeboxEntity
	if ( not IsValid(clientSafebox) ) then return end

	local distance = clientSafebox:GetPos():Distance(client:GetPos())
	if (distance > 128) then return false end

	PLUGIN:DepositMoney(client, clientSafebox, amount)

end)