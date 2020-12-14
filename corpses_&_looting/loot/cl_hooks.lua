local PLUGIN = PLUGIN

--[[ Vars management ]]--

local corpses_vars = {
	"Entity",
	"Inventory",
	"Money",
	"Name"
}

for _, v in pairs(corpses_vars) do
	local name = "Cur"..v
	AccessorFunc(PLUGIN, name, name)
end

function PLUGIN:EraseVars()
	for _, v in pairs(corpses_vars) do
		PLUGIN["SetCur"..v](PLUGIN, nil)
	end
end

--[[ Loot interface ]]--

PLUGIN.nextTrace = PLUGIN.nextTrace or 0
-- Request corpse opening to server when pressing E on a corpse
function PLUGIN:KeyPress(_, key)

	if ( key == IN_USE and CurTime() > PLUGIN.nextTrace ) then
		local entLooked = PLUGIN:EyeTrace(LocalPlayer())

		if ( IsValid(entLooked) and entLooked:IsCorpse() ) then
			PLUGIN:SetCurEntity(entLooked)

			netstream.Start("lootOpen")
		end

		PLUGIN.nextTrace = CurTime() + 0.5
	end

end

function PLUGIN:SetCorpseMoney(value)
	PLUGIN:SetCurMoney(value)

	if ( IsValid(PLUGIN.widthdrawText) ) then
		PLUGIN.widthdrawText:SetText( nut.currency.get(value) )
	end
end

netstream.Hook("lootMoney", function(value)
	PLUGIN:SetCorpseMoney(value)
end)

local function withdrawMoney(panel)
	
	local entry = PLUGIN.widthdrawEntry
	local value = tonumber(entry:GetValue()) or 0

	if ( PLUGIN:GetCurMoney() >= value and value > 0 ) then
		
		surface.PlaySound("hgn/crussaria/items/itm_gold_up.wav")
		netstream.Start("lootWdMny", value)
		entry:SetValue(0)
		
	elseif ( value < 0  ) then
		
		nut.util.notify(L("corpseInvalid"))
		entry:SetValue(0)
		
	elseif ( value == 0 ) then
		
		entry:SetValue(0)
		
	else
		nut.util.notify(L("corpseNotEnough"))
		entry:SetValue(0)
	end

end

local function depositMoney(panel)

	local entry = PLUGIN.depositEntry
	local value = tonumber(entry:GetValue()) or 0

	if ( value and value > 0 ) then

		if ( LocalPlayer():getChar():hasMoney(value) ) then

			surface.PlaySound("hgn/crussaria/items/itm_gold_down.wav")
			netstream.Start("lootDpMny", value)
			entry:SetValue(0)

		else

			nut.util.notify(L("corpseCharMoney"))
			entry:SetValue(0)

		end

	else

		entry:SetValue(0)
	
		if (value < 0) then
			nut.util.notify(L("corpseInvalid"))
		end

	end

end

-- Display loot panel
function PLUGIN:DisplayInventoryNut1_1_beta()
	local char = LocalPlayer():getChar()
	if (!char) then return end

	local localInv = LocalPlayer():getChar():getInv()
	if (!localInv) then return end
	
	PLUGIN.localInvPanel = localInv:show()
	PLUGIN.localInvPanel:ShowCloseButton(true)
	PLUGIN.localInvPanel:SetDraggable(false)

	local oldClose = PLUGIN.localInvPanel.OnClose
	PLUGIN.localInvPanel.OnClose = function()
		
		if (IsValid(PLUGIN.lootingInvPanel) and !IsValid(nut.gui.menu)) then
			PLUGIN.lootingInvPanel:Remove()
		end

		netstream.Start("lootExit")

		oldClose()
	end


	local w, h = PLUGIN.localInvPanel:GetSize()

	PLUGIN.localInvPanel:SetSize(w, h + 75)

	PLUGIN.depositText = PLUGIN.localInvPanel:Add("DLabel")
	PLUGIN.depositText:Dock(BOTTOM)
	PLUGIN.depositText:DockMargin(0, 0, PLUGIN.localInvPanel:GetWide()/2, 0)
	PLUGIN.depositText:SetTextColor(color_white)
	PLUGIN.depositText:SetFont("nutGenericFont")
	PLUGIN.depositText:SetText( nut.currency.get(LocalPlayer():getChar():getMoney()) )
	PLUGIN.depositText.Think = function()

		local char = LocalPlayer():getChar()

		if ( char and IsValid(PLUGIN:GetCurEntity()) ) then
			PLUGIN.depositText:SetText( nut.currency.get(char:getMoney()) )
		else
			PLUGIN.localInvPanel:Close()
		end

	end

	PLUGIN.depositEntry = PLUGIN.localInvPanel:Add("DTextEntry")
	PLUGIN.depositEntry:Dock(BOTTOM)
	PLUGIN.depositEntry:SetNumeric(true)
	PLUGIN.depositEntry:DockMargin(PLUGIN.localInvPanel:GetWide()/2, 0, 0, 0)
	PLUGIN.depositEntry:SetValue(0)
	PLUGIN.depositEntry.OnEnter = depositMoney

	PLUGIN.depositButton = PLUGIN.localInvPanel:Add("DButton")
	PLUGIN.depositButton:Dock(BOTTOM)
	PLUGIN.depositButton:DockMargin(PLUGIN.localInvPanel:GetWide()/2, 40, 0, -40)
	PLUGIN.depositButton:SetTextColor( Color( 255, 255, 255 ) )
	PLUGIN.depositButton:SetText(L"corpsePut")
	PLUGIN.depositButton.DoClick = depositMoney
	
	-- Victim loot
	local inventory = PLUGIN:GetCurInventory()

	PLUGIN.lootingInvPanel = inventory:show()
	PLUGIN.lootingInvPanel:ShowCloseButton(true)
	PLUGIN.lootingInvPanel:SetDraggable(false)
	PLUGIN.lootingInvPanel:SetTitle(L"corpseTitle")
	PLUGIN.lootingInvPanel:MoveLeftOf(PLUGIN.localInvPanel, 4)
	PLUGIN.lootingInvPanel.OnClose = function(this)

		if (IsValid(PLUGIN.localInvPanel) and !IsValid(nut.gui.menu)) then
			PLUGIN.localInvPanel:Remove()
		end

		netstream.Start("lootExit")
	end

	w, h = PLUGIN.lootingInvPanel:GetSize()

	PLUGIN.lootingInvPanel:SetSize(w, h + 75)

	PLUGIN.widthdrawText = PLUGIN.lootingInvPanel:Add("DLabel")
	PLUGIN.widthdrawText:Dock(BOTTOM)
	PLUGIN.widthdrawText:DockMargin(0, 0, PLUGIN.lootingInvPanel:GetWide()/2, 0)
	PLUGIN.widthdrawText:SetTextColor(color_white)
	PLUGIN.widthdrawText:SetFont("nutGenericFont")

	PLUGIN.widthdrawEntry = PLUGIN.lootingInvPanel:Add("DTextEntry")
	PLUGIN.widthdrawEntry:Dock(BOTTOM)
	PLUGIN.widthdrawEntry:SetNumeric(true)
	PLUGIN.widthdrawEntry:DockMargin(PLUGIN.lootingInvPanel:GetWide()/2, 0, 0, 0)
	PLUGIN.widthdrawEntry:SetValue(PLUGIN:GetCurMoney() or 0)
	PLUGIN.widthdrawEntry.OnEnter = withdrawMoney

	PLUGIN.widthdrawButton = PLUGIN.lootingInvPanel:Add("DButton")
	PLUGIN.widthdrawButton:Dock(BOTTOM)
	PLUGIN.widthdrawButton:DockMargin(PLUGIN.lootingInvPanel:GetWide()/2, 40, 0, -40)
	PLUGIN.widthdrawButton:SetTextColor( Color( 255, 255, 255 ) )
	PLUGIN.widthdrawButton:SetText(L"corpseTake")
	PLUGIN.widthdrawButton.DoClick = withdrawMoney

	nut.gui["inv"..inventory:getID()] = PLUGIN.lootingInvPanel

	PLUGIN.lootingInvPanel:SetPos(ScrW() / 2 - PLUGIN.lootingInvPanel:GetWide() - 2, 0)
	PLUGIN.localInvPanel:SetPos(ScrW() / 2 + 2, 0)
	PLUGIN.lootingInvPanel:CenterVertical()
	PLUGIN.localInvPanel:CenterVertical()
end

-- Display loot panel
function PLUGIN:DisplayInventoryNut1_1()
	local char = LocalPlayer():getChar()
	if (!char) then return end

	local localInv = LocalPlayer():getChar():getInv()
	if (!localInv) then return end
	
	nut.gui.inv1 = vgui.Create("nutInventory")
	PLUGIN.localInvPanel = nut.gui.inv1
	PLUGIN.localInvPanel:SetTitle(L"inv")
	PLUGIN.localInvPanel:setInventory(localInv)
	PLUGIN.localInvPanel:ShowCloseButton(true)
	PLUGIN.localInvPanel:SetDraggable(false)

	local oldClose = PLUGIN.localInvPanel.OnClose
	PLUGIN.localInvPanel.OnClose = function()
		
		if (IsValid(PLUGIN.lootingInvPanel) and !IsValid(nut.gui.menu)) then
			PLUGIN.lootingInvPanel:Remove()
		end

		netstream.Start("lootExit")

		oldClose()
	end


	local w, h = PLUGIN.localInvPanel:GetSize()

	PLUGIN.localInvPanel:SetSize(w, h + 75)

	PLUGIN.depositText = PLUGIN.localInvPanel:Add("DLabel")
	PLUGIN.depositText:Dock(BOTTOM)
	PLUGIN.depositText:DockMargin(0, 0, PLUGIN.localInvPanel:GetWide()/2, 0)
	PLUGIN.depositText:SetTextColor(color_white)
	PLUGIN.depositText:SetFont("nutGenericFont")
	PLUGIN.depositText:SetText( nut.currency.get(LocalPlayer():getChar():getMoney()) )
	PLUGIN.depositText.Think = function()

		local char = LocalPlayer():getChar()

		if ( char and IsValid(PLUGIN:GetCurEntity()) ) then
			PLUGIN.depositText:SetText( nut.currency.get(char:getMoney()) )
		else
			PLUGIN.localInvPanel:Close()
		end

	end

	PLUGIN.depositEntry = PLUGIN.localInvPanel:Add("DTextEntry")
	PLUGIN.depositEntry:Dock(BOTTOM)
	PLUGIN.depositEntry:SetNumeric(true)
	PLUGIN.depositEntry:DockMargin(PLUGIN.localInvPanel:GetWide()/2, 0, 0, 0)
	PLUGIN.depositEntry:SetValue(0)
	PLUGIN.depositEntry.OnEnter = depositMoney

	PLUGIN.depositButton = PLUGIN.localInvPanel:Add("DButton")
	PLUGIN.depositButton:Dock(BOTTOM)
	PLUGIN.depositButton:DockMargin(PLUGIN.localInvPanel:GetWide()/2, 40, 0, -40)
	PLUGIN.depositButton:SetTextColor( Color( 255, 255, 255 ) )
	PLUGIN.depositButton:SetText(L"corpsePut")
	PLUGIN.depositButton.DoClick = depositMoney
	
	-- Victim loot
	local inventory = PLUGIN:GetCurInventory()

	PLUGIN.lootingInvPanel = vgui.Create("nutInventory")
	PLUGIN.lootingInvPanel:SetTitle(L"corpseTitle")
	PLUGIN.lootingInvPanel:setInventory(inventory)
	PLUGIN.lootingInvPanel:ShowCloseButton(true)
	PLUGIN.lootingInvPanel:SetDraggable(false)
	PLUGIN.lootingInvPanel:MoveLeftOf(PLUGIN.localInvPanel, 4)
	PLUGIN.lootingInvPanel.OnClose = function(this)

		if (IsValid(PLUGIN.localInvPanel) and !IsValid(nut.gui.menu)) then
			PLUGIN.localInvPanel:Remove()
		end

		netstream.Start("lootExit")
	end

	w, h = PLUGIN.lootingInvPanel:GetSize()

	PLUGIN.lootingInvPanel:SetSize(w, h + 75)

	PLUGIN.widthdrawText = PLUGIN.lootingInvPanel:Add("DLabel")
	PLUGIN.widthdrawText:Dock(BOTTOM)
	PLUGIN.widthdrawText:DockMargin(0, 0, PLUGIN.lootingInvPanel:GetWide()/2, 0)
	PLUGIN.widthdrawText:SetTextColor(color_white)
	PLUGIN.widthdrawText:SetFont("nutGenericFont")

	PLUGIN.widthdrawEntry = PLUGIN.lootingInvPanel:Add("DTextEntry")
	PLUGIN.widthdrawEntry:Dock(BOTTOM)
	PLUGIN.widthdrawEntry:SetNumeric(true)
	PLUGIN.widthdrawEntry:DockMargin(PLUGIN.lootingInvPanel:GetWide()/2, 0, 0, 0)
	PLUGIN.widthdrawEntry:SetValue(PLUGIN:GetCurMoney() or 0)
	PLUGIN.widthdrawEntry.OnEnter = withdrawMoney

	PLUGIN.widthdrawButton = PLUGIN.lootingInvPanel:Add("DButton")
	PLUGIN.widthdrawButton:Dock(BOTTOM)
	PLUGIN.widthdrawButton:DockMargin(PLUGIN.lootingInvPanel:GetWide()/2, 40, 0, -40)
	PLUGIN.widthdrawButton:SetTextColor( Color( 255, 255, 255 ) )
	PLUGIN.widthdrawButton:SetText(L"corpseTake")
	PLUGIN.widthdrawButton.DoClick = withdrawMoney

	nut.gui["inv"..inventory:getID()] = PLUGIN.lootingInvPanel

	PLUGIN.lootingInvPanel:SetPos(ScrW() / 2 - PLUGIN.lootingInvPanel:GetWide() - 2, 0)
	PLUGIN.localInvPanel:SetPos(ScrW() / 2 + 2, 0)
	PLUGIN.lootingInvPanel:CenterVertical()
	PLUGIN.localInvPanel:CenterVertical()
end

-- Stared action to open the inventory of a corpse
netstream.Hook("lootOpen", function(invId, money)

	local corpse = PLUGIN:GetCurEntity()
	local inventory = nut.item.inventories[invId]

	if ( IsValid(corpse) and inventory and isnumber(money) ) then

		PLUGIN:SetCurInventory(inventory)

		if (nut.version == "2.0") then
			PLUGIN:DisplayInventoryNut1_1_beta()
		else
			PLUGIN:DisplayInventoryNut1_1()
		end
		
		PLUGIN:SetCorpseMoney(money)

	end

end)

if (CLIENT) then
	function PLUGIN:transferItem(itemID)
		if (not nut.item.instances[itemID]) then return end
		net.Start("nutCorpseTransfer")
			net.WriteUInt(itemID, 32)
		net.SendToServer()
	end
end