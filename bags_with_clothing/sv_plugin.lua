resource.AddWorkshop("891790188") -- Fallout 3 Custom Backpacks | www.be-gaming.net

local PLUGIN = PLUGIN

function PLUGIN:PlayerInitialSpawn(ply)
	netstream.Hook(ply, "ns_bagLoad", self.bagInstances)
end

function PLUGIN:PlayerLoadedChar(client, character, lastChar)
    timer.Simple(0.25, function()
        if (lastChar) then
            local bag

            for k, v in pairs(lastChar:getInv():getItems()) do
                if (v.bagUniqueID) then

                    bag = v.bagUniqueID
                    break
                end
            end

            if (bag) then
                netstream.Start(player.GetAll(), "ns_bagTakeOff", client)
                self.bagInstances[client] = nil
            end
        end

        if (character) then
            local bag

            for k, v in pairs(character:getInv():getItems()) do
                if (v.bagUniqueID) then

                    bag = v.bagUniqueID
                    break
                end
            end

            if (bag) then
                netstream.Start(player.GetAll(), "ns_bagWear", client, bag)
                self.bagInstances[client] = bag
            end
        end
    end)
end

function PLUGIN:PlayerDisconnected(ply)
    self.bagInstances[ply] = nil
end

function PLUGIN:OnPlayerInteractItem(client, action, item, result, data)
	if (!item.bagUniqueID) then return end -- if its not a bag we don't care
	
	if (nut.version != "2.0" && action == "drop") then
		netstream.Start(player.GetAll(), "ns_bagTakeOff", client)
		PLUGIN.bagInstances[client] = nil
	elseif (action == "take") then
		netstream.Start(player.GetAll(), "ns_bagWear", client, item.bagUniqueID)
		PLUGIN.bagInstances[client] = item.bagUniqueID
	end
end


local function itemTransfered(itemObject, prevInv, nextInv)
    timer.Simple(0.25, function()
        if ( (itemObject && itemObject.invID == 0 && nextInv == nil) or (nextInv && itemObject && itemObject.invID == nextInv:getID()) ) then
            if (prevInv && ((prevInv.owner) or (prevInv.data && prevInv.data.char && nut.char.loaded[prevInv.data.char]))) then
                local client = (prevInv.owner && player.GetByID(prevInv.owner)) or nut.char.loaded[prevInv.data.char]:getPlayer()

                if (IsValid(client)) then
                    netstream.Start(player.GetAll(), "ns_bagTakeOff", client)
                    PLUGIN.bagInstances[client] = nil
                end
            end

            if (nextInv && ((nextInv.owner) or (nextInv.data && nextInv.data.char && nut.char.loaded[nextInv.data.char]))) then
                local client = (nextInv.owner && player.GetByID(nextInv.owner)) or nut.char.loaded[nextInv.data.char]:getPlayer()

                if (IsValid(client)) then
                    netstream.Start(player.GetAll(), "ns_bagWear", client, itemObject.bagUniqueID)
                    PLUGIN.bagInstances[client] = itemObject.bagUniqueID
                end
            end
        end
    end)
end

--Nut 1.1
function PLUGIN:OnItemTransfered(itemObject, prevInv, nextInv)
    itemTransfered(itemObject, prevInv, nextInv)
end

-- Nut 1.1 beta 
function PLUGIN:CanItemBeTransfered(itemObject, prevInv, nextInv)
    itemTransfered(itemObject, prevInv, nextInv)
end