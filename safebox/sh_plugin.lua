local PLUGIN = PLUGIN

PLUGIN.name = "Safebox"
PLUGIN.author = "John (base from Cheesenut)"
PLUGIN.desc = "Allows to store precious items forever"

nut.util.include("sv_storage.lua")
nut.util.include("sv_networking.lua")
nut.util.include("sv_access_rules.lua")
nut.util.include("cl_networking.lua")

if (CLIENT) then
	function PLUGIN:transferItem(itemID)
		if (not nut.item.instances[itemID]) then return end
		net.Start("nutSafeboxTransfer")
			net.WriteUInt(itemID, 32)
		net.SendToServer()
	end
	
	netstream.Hook("safeboxMoney", function(value)
		PLUGIN.curMoney = value

		if ( IsValid(PLUGIN.widthdrawText) ) then
			PLUGIN.widthdrawText:SetText( nut.currency.get(value) )
		end
	end)
	
	local function widthdrawMoney(panel)
		
		local entry = PLUGIN.widthdrawEntry
		local value = tonumber(entry:GetValue()) or 0
	
		if ( PLUGIN.curMoney >= value and value > 0 ) then
			
			surface.PlaySound("hgn/crussaria/items/itm_gold_up.wav")
			netstream.Start("safeboxWdMny", value)
			entry:SetValue(0)
			
		elseif ( value < 0  ) then
			
			nut.util.notify(L("safeboxInvalid"))
			entry:SetValue(0)
			
		elseif (value == 0) then
			
			entry:SetValue(0)
			
		else
			nut.util.notify(L("safeboxNotEnough"))
			entry:SetValue(0)
		end
	
	end
	
	local function depositMoney(panel)
	
		local entry = PLUGIN.depositEntry
		local value = tonumber(entry:GetValue()) or 0
	
		if ( value and value > 0 ) then
	
			if ( LocalPlayer():getChar():hasMoney(value) ) then
	
				surface.PlaySound("hgn/crussaria/items/itm_gold_down.wav")
				netstream.Start("safeboxDpMny", value)
				entry:SetValue(0)
	
			else
	
				nut.util.notify(L("safeboxCharMoney"))
				entry:SetValue(0)
	
			end
	
		else
	
			entry:SetValue(0)
	
			if (value < 0) then
				nut.util.notify(L("safeboxInvalid"))
			end

		end
	
	end

	function PLUGIN:safeboxOpenNut1_1(storage, safeboxInvId, money)
		self.curMoney = money

		-- Number of pixels between the local inventory and storage inventory.
		local PADDING = 4

		if ( not isnumber(safeboxInvId) ) then return end

		-- Get the inventory for the player and storage.
		local localInv =
			LocalPlayer():getChar() and LocalPlayer():getChar():getInv()
		local storageInv = nut.item.inventories[safeboxInvId]
		if (not localInv or not storageInv) then
			return self:exitSafebox()
		end

		-- Player inventory
		nut.gui.inv1 = vgui.Create("nutInventory")
		local localInvPanel = nut.gui.inv1
		localInvPanel:SetTitle(L"inv")
		localInvPanel:setInventory(localInv)

		nut.gui["inv"..safeboxInvId] = vgui.Create("nutInventory")
		local storageInvPanel = nut.gui["inv"..safeboxInvId]
		storageInvPanel:SetTitle("Safebox")
		storageInvPanel:setInventory(storageInv)

		local w, h = localInvPanel:GetSize()
		localInvPanel:SetSize(w, h + 75)

		w, h = storageInvPanel:GetSize()
		storageInvPanel:SetSize(w, h + 75)

		PLUGIN.depositText = localInvPanel:Add("DLabel")
		PLUGIN.depositText:Dock(BOTTOM)
		PLUGIN.depositText:DockMargin(0, 0, localInvPanel:GetWide()/2, 0)
		PLUGIN.depositText:SetTextColor(color_white)
		PLUGIN.depositText:SetFont("nutGenericFont")
		PLUGIN.depositText:SetText( nut.currency.get(LocalPlayer():getChar():getMoney()) )
		PLUGIN.depositText.Think = function()

			local char = LocalPlayer():getChar()

			if ( char and IsValid(storage) ) then
				PLUGIN.depositText:SetText( nut.currency.get(char:getMoney()) )
			else
				localInvPanel:Close()
			end

		end

		PLUGIN.depositEntry = localInvPanel:Add("DTextEntry")
		PLUGIN.depositEntry:Dock(BOTTOM)
		PLUGIN.depositEntry:SetNumeric(true)
		PLUGIN.depositEntry:DockMargin(localInvPanel:GetWide()/2, 0, 0, 0)
		PLUGIN.depositEntry:SetValue(0)
		PLUGIN.depositEntry.OnEnter = depositMoney

		PLUGIN.depositButton = localInvPanel:Add("DButton")
		PLUGIN.depositButton:Dock(BOTTOM)
		PLUGIN.depositButton:DockMargin(localInvPanel:GetWide()/2, 40, 0, -40)
		PLUGIN.depositButton:SetTextColor( Color( 255, 255, 255 ) )
		PLUGIN.depositButton:SetText(L"safeboxDeposit")
		PLUGIN.depositButton.DoClick = depositMoney

		PLUGIN.widthdrawText = storageInvPanel:Add("DLabel")
		PLUGIN.widthdrawText:Dock(BOTTOM)
		PLUGIN.widthdrawText:DockMargin(0, 0, storageInvPanel:GetWide()/2, 0)
		PLUGIN.widthdrawText:SetTextColor(color_white)
		PLUGIN.widthdrawText:SetFont("nutGenericFont")
		PLUGIN.widthdrawText:SetText( nut.currency.get(PLUGIN.curMoney) )

		PLUGIN.widthdrawEntry = storageInvPanel:Add("DTextEntry")
		PLUGIN.widthdrawEntry:Dock(BOTTOM)
		PLUGIN.widthdrawEntry:SetNumeric(true)
		PLUGIN.widthdrawEntry:DockMargin(storageInvPanel:GetWide()/2, 0, 0, 0)
		PLUGIN.widthdrawEntry:SetValue(PLUGIN.curMoney or 0)
		PLUGIN.widthdrawEntry.OnEnter = widthdrawMoney

		PLUGIN.widthdrawButton = storageInvPanel:Add("DButton")
		PLUGIN.widthdrawButton:Dock(BOTTOM)
		PLUGIN.widthdrawButton:DockMargin(storageInvPanel:GetWide()/2, 40, 0, -40)
		PLUGIN.widthdrawButton:SetTextColor( Color( 255, 255, 255 ) )
		PLUGIN.widthdrawButton:SetText(L"safeboxWithdraw")
		PLUGIN.widthdrawButton.DoClick = widthdrawMoney

		-- Allow the inventory panels to close.
		localInvPanel:ShowCloseButton(true)
		storageInvPanel:ShowCloseButton(true)

		-- Put the two panels, side by side, in the middle.
		local extraWidth = (storageInvPanel:GetWide() + PADDING) / 2
		localInvPanel:Center()
		storageInvPanel:Center()
		localInvPanel.x = localInvPanel.x + extraWidth
		storageInvPanel:MoveLeftOf(localInvPanel, PADDING)

		-- Signal that the user left the inventory if either closes.
		local firstToRemove = true
		localInvPanel.oldOnRemove = localInvPanel.OnRemove
		storageInvPanel.oldOnRemove = storageInvPanel.OnRemove

		local function exitStorageOnRemove(panel)
			if (firstToRemove) then
				firstToRemove = false
				PLUGIN:exitSafebox()
				local otherPanel =
					panel == localInvPanel and storageInvPanel or localInvPanel
				if (IsValid(otherPanel)) then otherPanel:Remove() end
			end
			panel:oldOnRemove()
		end

		hook.Run("OnCreateSafeboxPanel", localInvPanel, storageInvPanel, storage)

		localInvPanel.OnRemove = exitStorageOnRemove
		storageInvPanel.OnRemove = exitStorageOnRemove
	end

	function PLUGIN:safeboxOpenNut1_1_beta(storage, safeboxInvId, money)
		self.curMoney = money

		-- Number of pixels between the local inventory and storage inventory.
		local PADDING = 4

		if ( not isnumber(safeboxInvId) ) then return end

		-- Get the inventory for the player and storage.
		local localInv =
			LocalPlayer():getChar() and LocalPlayer():getChar():getInv()
		local storageInv = nut.item.inventories[safeboxInvId]
		if (not localInv or not storageInv) then
			return self:exitSafebox()
		end

		-- Show both the storage and inventory.
		local localInvPanel = localInv:show()
		local storageInvPanel = storageInv:show()
		storageInvPanel:SetTitle("Safebox")

		local w, h = localInvPanel:GetSize()
		localInvPanel:SetSize(w, h + 75)

		w, h = storageInvPanel:GetSize()
		storageInvPanel:SetSize(w, h + 75)

		PLUGIN.depositText = localInvPanel:Add("DLabel")
		PLUGIN.depositText:Dock(BOTTOM)
		PLUGIN.depositText:DockMargin(0, 0, localInvPanel:GetWide()/2, 0)
		PLUGIN.depositText:SetTextColor(color_white)
		PLUGIN.depositText:SetFont("nutGenericFont")
		PLUGIN.depositText:SetText( nut.currency.get(LocalPlayer():getChar():getMoney()) )
		PLUGIN.depositText.Think = function()

			local char = LocalPlayer():getChar()

			if ( char and IsValid(storage) ) then
				PLUGIN.depositText:SetText( nut.currency.get(char:getMoney()) )
			else
				localInvPanel:Close()
			end

		end

		PLUGIN.depositEntry = localInvPanel:Add("DTextEntry")
		PLUGIN.depositEntry:Dock(BOTTOM)
		PLUGIN.depositEntry:SetNumeric(true)
		PLUGIN.depositEntry:DockMargin(localInvPanel:GetWide()/2, 0, 0, 0)
		PLUGIN.depositEntry:SetValue(0)
		PLUGIN.depositEntry.OnEnter = depositMoney

		PLUGIN.depositButton = localInvPanel:Add("DButton")
		PLUGIN.depositButton:Dock(BOTTOM)
		PLUGIN.depositButton:DockMargin(localInvPanel:GetWide()/2, 40, 0, -40)
		PLUGIN.depositButton:SetTextColor( Color( 255, 255, 255 ) )
		PLUGIN.depositButton:SetText(L"safeboxDeposit")
		PLUGIN.depositButton.DoClick = depositMoney

		PLUGIN.widthdrawText = storageInvPanel:Add("DLabel")
		PLUGIN.widthdrawText:Dock(BOTTOM)
		PLUGIN.widthdrawText:DockMargin(0, 0, storageInvPanel:GetWide()/2, 0)
		PLUGIN.widthdrawText:SetTextColor(color_white)
		PLUGIN.widthdrawText:SetFont("nutGenericFont")
		PLUGIN.widthdrawText:SetText( nut.currency.get(PLUGIN.curMoney) )

		PLUGIN.widthdrawEntry = storageInvPanel:Add("DTextEntry")
		PLUGIN.widthdrawEntry:Dock(BOTTOM)
		PLUGIN.widthdrawEntry:SetNumeric(true)
		PLUGIN.widthdrawEntry:DockMargin(storageInvPanel:GetWide()/2, 0, 0, 0)
		PLUGIN.widthdrawEntry:SetValue(PLUGIN.curMoney or 0)
		PLUGIN.widthdrawEntry.OnEnter = widthdrawMoney

		PLUGIN.widthdrawButton = storageInvPanel:Add("DButton")
		PLUGIN.widthdrawButton:Dock(BOTTOM)
		PLUGIN.widthdrawButton:DockMargin(storageInvPanel:GetWide()/2, 40, 0, -40)
		PLUGIN.widthdrawButton:SetTextColor( Color( 255, 255, 255 ) )
		PLUGIN.widthdrawButton:SetText(L"safeboxWithdraw")
		PLUGIN.widthdrawButton.DoClick = widthdrawMoney

		-- Allow the inventory panels to close.
		localInvPanel:ShowCloseButton(true)
		storageInvPanel:ShowCloseButton(true)

		-- Put the two panels, side by side, in the middle.
		local extraWidth = (storageInvPanel:GetWide() + PADDING) / 2
		localInvPanel:Center()
		storageInvPanel:Center()
		localInvPanel.x = localInvPanel.x + extraWidth
		storageInvPanel:MoveLeftOf(localInvPanel, PADDING)

		-- Signal that the user left the inventory if either closes.
		local firstToRemove = true
		localInvPanel.oldOnRemove = localInvPanel.OnRemove
		storageInvPanel.oldOnRemove = storageInvPanel.OnRemove

		local function exitStorageOnRemove(panel)
			if (firstToRemove) then
				firstToRemove = false
				PLUGIN:exitSafebox()
				local otherPanel =
					panel == localInvPanel and storageInvPanel or localInvPanel
				if (IsValid(otherPanel)) then otherPanel:Remove() end
			end
			panel:oldOnRemove()
		end

		hook.Run("OnCreateSafeboxPanel", localInvPanel, storageInvPanel, storage)

		localInvPanel.OnRemove = exitStorageOnRemove
		storageInvPanel.OnRemove = exitStorageOnRemove
	end

	function PLUGIN:SafeboxOpen(storage, safeboxInvId, money)
		if (nut.version == "2.0") then
			self:safeboxOpenNut1_1_beta(storage, safeboxInvId, money)
		else
			self:safeboxOpenNut1_1(storage, safeboxInvId, money)
		end
	end
end