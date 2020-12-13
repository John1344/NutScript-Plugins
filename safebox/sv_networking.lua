util.AddNetworkString("nutSafeboxOpen")
util.AddNetworkString("nutSafeboxExit")
util.AddNetworkString("nutSafeboxTransfer")

local TRANSFER = "transfer"

local function getValidSafebox(client)
	local storage = client.nutSafeboxEntity
	if (not IsValid(storage)) then return end
	if (client:GetPos():Distance(storage:GetPos()) > 128) then return end
	return storage
end

net.Receive("nutSafeboxExit", function(_, client)
	local storage = client.nutSafeboxEntity
	if (IsValid(storage)) then
		storage.receivers[client] = nil
	end
	client.nutSafeboxEntity = nil
end)