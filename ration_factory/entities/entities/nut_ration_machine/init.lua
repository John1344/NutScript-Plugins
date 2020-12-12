local PLUGIN = PLUGIN or nut.plugin.list.ration_factory -- Please don't rename plugin folder else PLUGIN variable will be nil in NS beta
if (!PLUGIN) then
	ErrorNoHalt( 'ration_factory plugin directory may have been changed and thus it causes lua errors. Please name it "ration_factory"\n' )
end

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

local MAX_DIST_MACHINE = 80

function ENT:Initialize()
    self:SetModel("models/props_lab/reciever01b.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
end


function ENT:Use(activator, client)
    if (!IsValid(client)) then return end
    
    local char = client:getChar()
    if (!char) then return end
    
    if ( char:getInv():hasItem("plastic_bag") ) then
        client:setAction("@producingRation", PLUGIN.PRODUCE_TIME)
		client:doStaredAction(self, function() 

			if ( char ) then
                local emptyBag
                
                for k, v in pairs(char:getInv():getItems()) do
                    if (v.uniqueID == "plastic_bag") then
                        emptyBag = v
                        break
                    end
                end

                if ( emptyBag ) then
                    emptyBag:remove()
                   
                    local chance = math.random(0, 100)

                    if (chance < 41) then
                        char:getInv():add("low_ration")
                    elseif (chance < 71) then
                        char:getInv():add("correct_ration")
                    elseif (chance < 91) then
                        char:getInv():add("good_ration")
                    else
                        char:getInv():add("top_ration")
                    end

                    self:EmitSound("items/battery_pickup.wav", 75, 50, 0.75)
                else
                    client:notifyLocalized("dontHavePlasticBags")
                end
			end

		end, PLUGIN.PRODUCE_TIME, function()

			if ( IsValid(client) ) then
				client:setAction()
			end

		end, MAX_DIST_MACHINE)
    else
        client:notifyLocalized("dontHavePlasticBags")
    end
end