local PLUGIN = PLUGIN or nut.plugin.list.bags_with_clothing -- Please don't rename plugin folder else PLUGIN variable will be nil in NS beta
if (!PLUGIN) then
	ErrorNoHalt( 'bags_with_clothing plugin directory may have been changed and thus it causes lua errors. Please name it "bags_with_clothing"\n' )
end

if (nut.version == "2.0") then
	-- Nutscript 1.1 beta
	local INVENTORY_TYPE_ID = "grid"

	ITEM.name = "Bag"
	ITEM.desc = "A bag to hold more items."
	ITEM.model = "models/props_c17/suitcase001a.mdl"
	ITEM.category = "Storage"
	ITEM.isBag = true

	-- The size of the inventory held by this item.
	ITEM.invWidth = 2
	ITEM.invHeight = 2

	ITEM.functions.View = {
		icon = "icon16/briefcase.png",
		onClick = function(item)
			local inventory = item:getInv()
			if (not inventory) then return false end

			local panel = nut.gui["inv"..inventory:getID()]
			local parent = item.invID and nut.gui["inv"..item.invID] or nil

			if (IsValid(panel)) then
				panel:Remove()
			end

			if (inventory) then
				local panel = nut.inventory.show(inventory, parent)
				if (IsValid(panel)) then
					panel:ShowCloseButton(true)
					panel:SetTitle(item:getName())
				end
			else
				local itemID = item:getID()
				local index = item:getData("id", "nil")
				ErrorNoHalt(
					"Invalid inventory "..index.." for bag item "..itemID.."\n"
				)
			end
			return false
		end,
		onCanRun = function(item)
			return !IsValid(item.entity) and item:getInv()
		end
	}

	function ITEM:onInstanced()
		local data = {
			item = self:getID(),
			w = self.invWidth,
			h = self.invHeight
		}
		nut.inventory.instance(INVENTORY_TYPE_ID, data)
			:next(function(inventory)
				self:setData("id", inventory:getID())
				hook.Run("SetupBagInventoryAccessRules", inventory)
				inventory:sync()
				self:resolveInvAwaiters(inventory)
			end)

		-- Determine if the bag is in a player inventory if so bonemerge a backpack model
		local owner = self:getOwner()

		if (IsValid(owner) && owner:IsPlayer() && owner:getChar()) then
			netstream.Start(player.GetAll(), "ns_bagWear", owner, self.bagUniqueID)
			PLUGIN.bagInstances[owner] = self.bagUniqueID
		end
	end

	function ITEM:onRestored()
		local invID = self:getData("id")
		if (invID) then
			nut.inventory.loadByID(invID)
				:next(function(inventory)
					hook.Run("SetupBagInventoryAccessRules", inventory)
					self:resolveInvAwaiters(inventory)
				end)
		end
	end

	function ITEM:onRemoved()
		local invID = self:getData("id")
		if (invID) then
			nut.inventory.deleteByID(invID)
		end

		-- Determine if the bag is in a player inventory if so bonemerge a backpack model
		local owner = self:getOwner()

		if (IsValid(owner) && owner:IsPlayer() && owner:getChar()) then
			netstream.Start(player.GetAll(), "ns_bagTakeOff", owner)
			PLUGIN.bagInstances[owner] = nil
		end
	end

	function ITEM:getInv()
		return nut.inventory.instances[self:getData("id")]
	end

	function ITEM:onSync(recipient)
		local inventory = self:getInv()
		if (inventory) then
			inventory:sync(recipient)
		end
	end

	function ITEM.postHooks:drop()
		local invID = self:getData("id")
		if (invID) then
			net.Start("nutInventoryDelete")
				net.WriteType(invID)
			net.Send(self.player)
		end
	end

	function ITEM:onCombine(other)
		local client = self.player
		local invID = self:getInv() and self:getInv():getID() or nil
		if (not invID) then return end

		-- If other item was combined onto this item, put it in the bag.
		local res = hook.Run(
			"HandleItemTransferRequest",
			client,
			other:getID(),
			nil,
			nil,
			invID
		)
		if (not res) then return end

		-- If an attempt was made, either report the error or make a
		-- "success" sound.
		res:next(function(res)
			if (not IsValid(client)) then return end
			if (istable(res) and type(res.error) == "string") then
				return client:notifyLocalized(res.error)
			end
			client:EmitSound(unpack(SOUND_BAG_RESPONSE))
		end)
	end

	if (SERVER) then
		function ITEM:onDisposed()
			local inventory = self:getInv()
			if (inventory) then
				inventory:destroy()
			end
		end

		function ITEM:resolveInvAwaiters(inventory)
			if (self.awaitingInv) then
				for _, d in ipairs(self.awaitingInv) do
					d:resolve(inventory)
				end
				self.awaitingInv = nil
			end
		end

		function ITEM:awaitInv()
			local d = deferred.new()
			local inventory = self:getInv()

			if (inventory) then
				d:resolve(inventory)
			else
				self.awaitingInv = self.awaitingInv or {}
				self.awaitingInv[#self.awaitingInv + 1] = d
			end

			return d
		end
	end
else
	-- Nutscript 1.1
	ITEM.name = "Bag"
	ITEM.desc = "A bag to hold items."
	ITEM.model = "models/props_c17/suitcase001a.mdl"
	ITEM.category = "Storage"
	ITEM.width = 2
	ITEM.height = 2
	ITEM.invWidth = 4
	ITEM.invHeight = 2
	ITEM.isBag = true
	ITEM.functions.View = {
		icon = "icon16/briefcase.png",
		onClick = function(item)
			local index = item:getData("id")

			if (index) then
				local panel = nut.gui["inv"..index]
				local parent = item.invID and nut.gui["inv"..item.invID] or nil
				local inventory = nut.item.inventories[index]
				
				if (IsValid(panel)) then
					panel:Remove()
				end

				if (inventory and inventory.slots) then
					panel = vgui.Create("nutInventory", parent)
					panel:setInventory(inventory)
					panel:ShowCloseButton(true)
					panel:SetTitle(item.getName and item:getName() or L(item.name))

					nut.gui["inv"..index] = panel
				else
					ErrorNoHalt("[NutScript] Attempt to view an uninitialized inventory '"..index.."'\n")
				end
			end

			return false
		end,
		onCanRun = function(item)
			return !IsValid(item.entity) and item:getData("id")
		end
	}

	-- Called when a new instance of this item has been made.
	function ITEM:onInstanced(invID, x, y)
		local inventory = nut.item.inventories[invID]

		nut.item.newInv(inventory and inventory.owner or 0, self.uniqueID, function(inventory)
			inventory.vars.isBag = self.uniqueID
			self:setData("id", inventory:getID())
		end)

		-- Determine if the bag is in a player inventory if so bonemerge a backpack model
		local owner = self:getOwner()

		if (IsValid(owner) && owner:IsPlayer() && owner:getChar()) then
			netstream.Start(player.GetAll(), "ns_bagWear", owner, self.bagUniqueID)
			PLUGIN.bagInstances[owner] = self.bagUniqueID
		end
	end

	function ITEM:getInv()
		local index = self:getData("id")

		if (index) then
			return nut.item.inventories[index]
		end
	end

	-- Called when the item first appears for a client.
	function ITEM:onSendData()
		local index = self:getData("id")

		if (index) then
			local inventory = nut.item.inventories[index]

			if (inventory) then
				inventory.vars.isBag = self.uniqueID
				inventory:sync(self.player)
			else
				local owner = self.player:getChar():getID()

				nut.item.restoreInv(self:getData("id"), self.invWidth, self.invHeight, function(inventory)
					inventory.vars.isBag = self.uniqueID
					inventory:setOwner(owner, true)
				end)
			end
		else
			local inventory = nut.item.inventories[self.invID]
			local client = self.player

			nut.item.newInv(self.player:getChar():getID(), self.uniqueID, function(inventory)
				self:setData("id", inventory:getID())
			end)
		end
	end

	ITEM.postHooks.drop = function(item, result)
		local index = item:getData("id")

		nut.db.query("UPDATE nut_inventories SET _charID = 0 WHERE _invID = "..index)
		netstream.Start(item.player, "nutBagDrop", index)
	end

	if (CLIENT) then
		netstream.Hook("nutBagDrop", function(index)
			local panel = nut.gui["inv"..index]

			if (panel and panel:IsVisible()) then
				panel:Close()
			end
		end)
	end

	-- Called before the item is permanently deleted.
	function ITEM:onRemoved()
		local index = self:getData("id")

		if (index) then
			nut.db.query("DELETE FROM nut_items WHERE _invID = "..index)
			nut.db.query("DELETE FROM nut_inventories WHERE _invID = "..index)
		end

		-- Determine if the bag is in a player inventory if so bonemerge a backpack model
		local owner = self:getOwner()

		if (IsValid(owner) && owner:IsPlayer() && owner:getChar()) then
			netstream.Start(player.GetAll(), "ns_bagTakeOff", owner)
			PLUGIN.bagInstances[owner] = nil
		end
	end

	-- Called when the item should tell whether or not it can be transfered between inventories.
	function ITEM:onCanBeTransfered(oldInventory, newInventory)
		local index = self:getData("id")

		if (newInventory) then
			if (newInventory.vars and newInventory.vars.isBag) then
				return false
			end

			local index2 = newInventory:getID()

			if (index == index2) then
				return false
			end

			for k, v in pairs(self:getInv():getItems()) do
				if (v:getData("id") == index2) then
					return false
				end
			end
		end
		
		return !newInventory or newInventory:getID() != oldInventory:getID() or newInventory.vars.isBag
	end

	-- Called after the item is registered into the item tables.
	function ITEM:onRegistered()
		nut.item.registerInv(self.uniqueID, self.invWidth, self.invHeight, true)
	end
end