net.Receive("nutSafeboxOpen", function()
	local entity = net.ReadEntity()
	local safeboxInvID = net.ReadUInt( 32 )
	local money = net.ReadFloat()
	hook.Run("SafeboxOpen", entity, safeboxInvID, money)
end)

function PLUGIN:exitSafebox()
	net.Start("nutSafeboxExit")
	net.SendToServer()
end
