local PLUGIN = PLUGIN

local function createBag(player, bagUniqueID)
	local bagInfo = PLUGIN.bagUniqueIDs[bagUniqueID]

	local bag = ClientsideModel(bagInfo.model, RENDERGROUP_OPAQUE) -- TO DO search best rendergroup
	bag:SetPos(player:GetPos())
	bag:SetAngles(player:GetAngles())
	bag:SetMoveType(MOVETYPE_NONE)
	local boneId = player:LookupBone( bagInfo.bone )
    if ( !boneId ) then return end

    bag:FollowBone(player, boneId)
	bag:SetLocalPos(bagInfo.pos)
	bag:SetLocalAngles(bagInfo.ang)

	function bag:Think()
        
		local parent = self:GetParent()
		
        if( parent:IsValid() ) then

            if (parent:IsPlayer() && parent:getChar()) then

                if (parent:Alive()) then
                    self.hasSpawned = true
                elseif (self.hasSpawned) then
					self:Remove()
                end

            end

			local noDraw = parent:GetNoDraw()
			
			if (parent == LocalPlayer() && parent:ShouldDrawLocalPlayer() == false) then
				noDraw = true
			end

            if ( noDraw != self.LastDrawState ) then
                self:SetNoDraw( noDraw )
            end
            self.LastDrawState = noDraw

		else
			self:Remove()	-- Handles disconnection -- TO DO test
		end

    end
	hook.Add("Think", bag, bag.Think)
	
	if (player.hl2rpBag) then
		player.hl2rpBag:Remove() -- remove old bag
	end
	player.hl2rpBag = bag
end

netstream.Hook("ns_bagWear", function(owner, bagItem)
	createBag(owner, bagItem)
end)

netstream.Hook("ns_bagTakeOff", function(owner)
	if (IsValid(owner.hl2rpBag)) then
		owner.hl2rpBag:Remove()
	end
end)

netstream.Hook("ns_bagLoad", function(bags)
	for k, v in pairs(bags) do
	
		local ply = Player(k)

		if ( IsValid(ply) ) then
			createBag(ply, v)
		end
	end
end)