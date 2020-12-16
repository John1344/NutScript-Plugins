local PLUGIN = PLUGIN


--[[ Loot creation ]]--

function PLUGIN:OnCorpseCreated(corpse, victim, char)

	local victimInventory = char:getInv()
	local victimMoney = char:getMoney()

	PLUGIN:CreateInventory(victim, victimInventory, corpse, victimInventory.w, victimInventory.h)

	PLUGIN:TransferMoney(victim, corpse)

	function corpse:LootThink()
		if ( CurTime() < (self.NextTraceCheck or 0) ) then return end

		if ( self.Searchers ) then
			for k, _ in pairs(self.Searchers) do
				if ( PLUGIN:EyeTrace(k) ~= self ) then
					PLUGIN:CloseCorpse(k, false)
				end
			end
		end
		
		self.NextTraceCheck = CurTime() + 0.1
	end
	hook.Add("Think", corpse, corpse.LootThink)

end

function PLUGIN:CreateInventory(victim, victimInventory, corpse, width, height)

	if ( nut.inventory && nut.inventory.instance ) then -- Nutscript 1.1 beta
		nut.inventory.instance("grid", {w = width, h = height})
			:next(function(inventory)
				if (IsValid(corpse)) then
					inventory.isCorpse = true
					
					corpse:SetVar("LootInv", inventory)
					corpse:CallOnRemove("RemoveLootInv", function(ent)

						local lootInv = ent:GetVar("LootInv")
						local invId = lootInv:getID()

						if ( not ent.nutIsSafe and lootInv ) then
							nut.item.inventories[invId] = nil
							nut.db.query("DELETE FROM nut_items WHERE _invID = " .. invId)
							nut.db.query("DELETE FROM nut_inventories WHERE _invID = " .. invId)
						end
					end)

					PLUGIN:TransferInventory(victim, victimInventory, inventory)
					hook.Run("CorpseInventorySet", corpse, inventory)
					
				end
			end, function(err)
				ErrorNoHalt(
					"Unable to create corpse entity for "..client:Name().."\n"..
					err.."\n"
				)
				if (IsValid(storage)) then
					corpse:Remove()
				end
			end)
	elseif ( nut.item.newInv ) then
		nut.item.newInv(0, "corpse", function(inventory)
			inventory.w = width
			inventory.h = height
			inventory.isCorpse = true

			corpse:SetVar("LootInv", inventory)
			corpse:CallOnRemove("RemoveLootInv", function(ent)
				local lootInv = ent:GetVar("LootInv")

				if ( lootInv ) then
					local invId = lootInv:getID()
							
					if (invId) then
						nut.inventory.deleteByID(invId)
					end
				end
			end)

			PLUGIN:TransferInventory(victim, victimInventory, inventory)
		end)
	end
end

-- Force nutscript item transfer in 1.1
function PLUGIN:CanItemBeTransfered(item, curInv, inventory)
	if (self.forceItemTransfer) then
		self.forceItemTransfer = false
		return true
	end
end

function PLUGIN:TransferInventory(fromPlayer, from, to)
	local fromChar = fromPlayer:getChar()

	if (nut.version == "2.0") then
		
		for k, v in pairs(from:getItems()) do
			if ( fromPlayer and v:getData("equip") ) then
				if (v.functions.EquipUn) then
					v.player = fromPlayer
					v.functions.EquipUn.onRun(v)
					v.player = nil
				end
			end

			if (v.invID == from:getID()) then -- Don't transfer items inside bags but keep them in bags instead
				from:removeItem(v:getID(), true)
					:next(function()
						return to:add(v, v.data.x, v.data.y)
					end)
					:catch(function(err)
						return from:add(v, v.data.x, v.data.y)
					end)
			end
		end
	else

		for k, v in pairs(from:getItems(true)) do --only main
			if ( fromPlayer and v:getData("equip") ) then
				if (v.functions.EquipUn) then
					v.player = fromPlayer
					v.functions.EquipUn.onRun(v)
					v.player = nil
				end
			end

			self.forceItemTransfer = true
			local status, result = to:add(v:getID(), nil, nil, v.gridX, v.gridY, false)

			if (status) then
				from:remove(v:getID(), false, true)
			end
		end
		
	end
end

function PLUGIN:TransferMoney(victim, corpse)

	local char = victim:getChar()
	local money = char:getMoney()

	corpse:SetVar("LootMoney", money)
	char:setMoney(0)

end

--[[ Corpse opening ]]--

function PLUGIN:RegSearcher(corpse, client)

	if ( not corpse.Searchers ) then
		corpse.Searchers = {}
	end
	corpse.Searchers[client] = true

	client:SetVar("LootCorpse", corpse)

end

function PLUGIN:UnregSearcher(corpse, client)

	if ( corpse.Searchers ) then
		corpse.Searchers[client] = nil
	end

	client:SetVar("LootCorpse", nil)

end

function PLUGIN:CloseCorpse(client, share)

	local corpse = client:GetVar("LootCorpse")

	if ( IsValid(corpse) ) then

		PLUGIN:UnregSearcher(corpse, client)
		client.nutCorpseEntity = nil

		if ( share ) then
			netstream.Start(client, "lootExit")
		end

	end

end

netstream.Hook("lootExit", function(client)
	PLUGIN:CloseCorpse(client)
end)

function PLUGIN:OpenCorpse(corpse, client)

	if ( IsValid(corpse) ) then
		local inv = corpse:GetVar("LootInv")

		if ( inv ) then

			PLUGIN:RegSearcher(corpse, client)
			client.nutCorpseEntity = corpse

			inv:sync(client)
			netstream.Start(client, "lootOpen", inv:getID(), corpse:GetVar("LootMoney"))
		end
	end

end

-- Stared action to open the inventory of a corpse
netstream.Hook("lootOpen", function(client)

	if ( not IsValid(client) ) then return end

	local corpse = PLUGIN:EyeTrace(client)

	if ( IsValid(corpse) and corpse:IsCorpse() ) then

		client:setAction("@corpseSearching", 1)
		client:doStaredAction(corpse, function() 

			if ( IsValid(corpse) ) then
				PLUGIN:OpenCorpse(corpse, client)
			end

		end, 1, function()

			if ( IsValid(client) ) then
				client:setAction()
			end

		end, PLUGIN.corpseMaxDist)

	end

end)


--[[ Money management ]]--

function PLUGIN:ShareCorpseMoney(corpse)

	local searchers = corpse.Searchers

	if ( searchers ) then

		netstream.Start(searchers, "lootMoney", corpse:GetVar("LootMoney"))

	end

end

function PLUGIN:WidthdrawMoney(client, corpse, amount)

	local oldCorpseMoney = corpse:GetVar("LootMoney")

	if ( amount <= oldCorpseMoney ) then

		corpse:SetVar("LootMoney", oldCorpseMoney - amount)
		PLUGIN:ShareCorpseMoney(corpse)

		local char = client:getChar()
		char:giveMoney(amount)

	end

end

netstream.Hook("lootWdMny", function(client, amount)

	if ( not isnumber(amount) ) then return end
	if ( not IsValid(client) ) then return end

	local corpse = client:GetVar("LootCorpse")
	if ( not IsValid(corpse) ) then return end

	PLUGIN:WidthdrawMoney(client, corpse, amount)

end)

function PLUGIN:DepositMoney(client, corpse, amount)

	local char = client:getChar()
	local oldCharMoney = char:getMoney()

	if ( amount <= oldCharMoney ) then

		local oldCorpseMoney = corpse:GetVar("LootMoney")
		corpse:SetVar("LootMoney", oldCorpseMoney + amount)
		PLUGIN:ShareCorpseMoney(corpse)

		char:takeMoney(amount)

	end

end

netstream.Hook("lootDpMny", function(client, amount)

	if ( not isnumber(amount) ) then return end
	if ( not IsValid(client) ) then return end

	local corpse = client:GetVar("LootCorpse")
	if ( not IsValid(corpse) ) then return end

	PLUGIN:DepositMoney(client, corpse, amount)

end)
