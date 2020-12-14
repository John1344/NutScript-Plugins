local PLUGIN = PLUGIN or nut.plugin.list.safebox -- Please don't rename plugin folder else PLUGIN variable will be nil in NS beta
if (!PLUGIN) then
	ErrorNoHalt( 'safebox plugin directory may have been changed and thus it causes lua errors. Please name it "safebox"\n' )
end

include("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local DEFAULT_LOCK_SOUND = "doors/default_locked.wav"
local DEFAULT_OPEN_SOUND = "items/ammocrate_open.wav"
local OPEN_TIME = 0.7

function ENT:Initialize()
	self:SetModel("models/items/ammocrate_grenade.mdl")
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self.receivers = {}
	
	if (isfunction(self.PostInitialize)) then
		self:PostInitialize()
	end

	self:PhysicsInit(SOLID_VPHYSICS)
	local physObj = self:GetPhysicsObject()

	if (IsValid(physObj)) then
		physObj:EnableMotion(true)
		physObj:Wake()
	end
end

function ENT:openInv(activator)
	local char = activator:getChar()

	self:ResetSequence("Close")

	timer.Create("CloseLid"..self:EntIndex(), 2, 1, function()
		if (IsValid(self)) then
			self:ResetSequence("Open")
		end
	end)

	activator:setAction(L("@safeboxOpening", activator), OPEN_TIME, function()
		if (activator:GetPos():Distance(self:GetPos()) > 96) then
			activator.nutSafeboxEntity = nil
			return
		end

		self.receivers[activator] = true

		local data = PLUGIN.charInventoryIDs[char:getID()]

		if (data) then
			local invID = data[1]
			local inv = nut.item.inventories[invID]

			if (inv) then
				inv:sync(activator)

				net.Start("nutSafeboxOpen")
					net.WriteEntity(self)
					net.WriteUInt(invID, 32)
					net.WriteFloat(data[2] or 0 , 32)
				net.Send(activator)
		
				self:EmitSound(DEFAULT_OPEN_SOUND)

			else
				if (nut.inventory && nut.inventory.loadByID) then
					nut.inventory.loadByID(invID)
					:next(function(inventory)
						if (inventory) then
							inventory.isSafebox = true
							PLUGIN:SafeboxInventorySet(inventory)

							inventory:sync(activator)

							net.Start("nutSafeboxOpen")
								net.WriteEntity(self)
								net.WriteUInt(invID, 32)
								net.WriteFloat(data[2] or 0 , 32)
							net.Send(activator)
					
							self:EmitSound(DEFAULT_OPEN_SOUND)
						end
					end)
				elseif ( nut.item.restoreInv ) then
					local width = data[3]
					local height = data[4]

					nut.item.restoreInv(invID, width, height, function(inventory, badItemsUniqueID)
						if (inventory) then
							inventory.isSafebox = true

							inventory:sync(activator)

							net.Start("nutSafeboxOpen")
								net.WriteEntity(self)
								net.WriteUInt(invID, 32)
								net.WriteFloat(data[2] or 0 , 32)
							net.Send(activator)
					
							self:EmitSound(DEFAULT_OPEN_SOUND)
						end
					end)
				end
			end
		else
			local width = 5
			local height = 3

			if ( nut.inventory && nut.inventory.instance ) then -- Nutscript 1.1 beta
				nut.inventory.instance("grid", {w=width, h=height})
				:next(function(inventory)
					inventory.isSafebox = true
					PLUGIN:SafeboxInventorySet(inventory)

					PLUGIN.charInventoryIDs[char:getID()] = {inventory:getID(), 0, width, height}
					PLUGIN:saveStorage()

					inventory:sync(activator)

					net.Start("nutSafeboxOpen")
						net.WriteEntity(self)
						net.WriteUInt(inventory:getID(), 32)
						net.WriteFloat(0 , 32)
					net.Send(activator)
			
					self:EmitSound(DEFAULT_OPEN_SOUND)
				end, function(err)
					ErrorNoHalt(
						"Unable to create safebox inventory for "..client:Name().."\n"..
						err.."\n"
					)
				end)
			elseif ( nut.item.newInv ) then -- Nutscript 1.1
				nut.item.newInv(0, "safebox", function(inventory)
					inventory.w = width
					inventory.h = height
					inventory.isSafebox = true

					PLUGIN.charInventoryIDs[char:getID()] = {inventory:getID(), 0, width, height}

					inventory:sync(activator)

					net.Start("nutSafeboxOpen")
						net.WriteEntity(self)
						net.WriteUInt(inventory:getID(), 32)
						net.WriteFloat(0 , 32)
					net.Send(activator)
			
					self:EmitSound(DEFAULT_OPEN_SOUND)
				end)
			end
		end
	end)
end

function ENT:Use(activator)
	local char = activator:getChar()
	if (not char) then return end
	if ((activator.nutNextOpen or 0) > CurTime()) then return end
	if (IsValid(activator.nutSafeboxEntity)) then return end

	activator.nutSafeboxEntity = self

	self:openInv(activator)

	activator.nutNextOpen = CurTime() + OPEN_TIME * 1.5
end
