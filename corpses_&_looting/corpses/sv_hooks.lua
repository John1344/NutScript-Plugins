local PLUGIN = PLUGIN

-- Make player loot on death
function PLUGIN:DoPlayerDeath( victim, attacker, dmg )

	local char = victim:getChar()

	if ( not char ) then return end

	local corpse = PLUGIN:MakeCorpseFromVictim(victim)

	if ( IsValid(corpse) ) then
		hook.Run("OnCorpseCreated", corpse, victim, char)

		if ( victim:IsOnFire() ) then
			corpse:Ignite(8)
		end
	end

end

-- Disable player's default corpses
function PLUGIN:PlayerDeath( victim, inflictor, attacker )

	local OldRagdoll = victim:GetRagdollEntity()
	if ( IsValid(OldRagdoll) ) then OldRagdoll:Remove() end

end

-- Aplly victim movement on corpse
function PLUGIN:SetupBones(corpse, victim)

	local victim_vel = victim:GetVelocity() / 5
	local num = corpse:GetPhysicsObjectCount() - 1

	for i = 0, num do
		local physObj = corpse:GetPhysicsObjectNum(i)

		if ( IsValid(physObj) ) then
			if ( victim_vel ) then
				physObj:SetVelocity(victim_vel)
			end

			local boneId = corpse:TranslatePhysBoneToBone(i)
			if ( boneId ) then
				local pos, ang = victim:GetBonePosition(boneId)

				physObj:SetPos(pos)
				physObj:SetAngles(ang)
			end
		end
	end
	
end

function PLUGIN:AttachTo(entity, otherEntity)
	constraint.Weld(entity, otherEntity, 0, 0, 0, false)

	entity:DeleteOnRemove( otherEntity )
	otherEntity:DeleteOnRemove( entity )
end

-- Make a little prop to carry the corpse from Hands swep
function PLUGIN:MakeHandle(ent)

	ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	-- Prop hitbox
	local prop = ents.Create("prop_physics")
	prop:SetModel("models/hunter/blocks/cube025x025x025.mdl")
	prop:SetPos(ent:GetPos())
	prop:SetCollisionGroup(COLLISION_GROUP_WORLD)
	prop:SetNoDraw(true)
	
	prop:Spawn()
	prop:Activate()

	PLUGIN:AttachTo(prop, ent)

end

local VARS_TO_CLONE = {
	"Model",
	"Pos",
	"Angles",
	"Color",
	"Skin",
}

local Entity = FindMetaTable("Entity")

-- Make an entity look like another
function PLUGIN:CloneVarsOn( ent1, ent2 )
	-- Vars
	for _, v in pairs( VARS_TO_CLONE ) do
        local get = Entity["Get"..v]
        local set = Entity["Set"..v]
            
        set(ent2, get(ent1))
    end

	-- Tables
	local bgs = ent1:GetBodyGroups()
	if ( bgs ) then
	   
		for _, v in pairs( bgs ) do
			local bgId = v.id
			local bgValue = ent1:GetBodygroup( bgId )

			if ( bgValue > 0 ) then
				ent2:SetBodygroup( bgId, bgValue )
			end
		end
		
	end

	local mats = ent1:GetMaterials()
	for k, v in pairs( mats ) do
		ent2:SetSubMaterial(k - 1, ent1:GetSubMaterial(k - 1))
	end
end

-- Create a corpse from a victim
function PLUGIN:MakeCorpseFromVictim(victim)

	-- Make the corpse
	local corpse = ents.Create("prop_ragdoll")
	corpse:SetNW2Bool("isLootCorpse", true)
	PLUGIN:CloneVarsOn(victim, corpse)

	-- Spawn the corpse
	corpse:Spawn()
	corpse:Activate()

	-- Setup the bones
	PLUGIN:SetupBones(corpse, victim)

	-- Use a prop as hitbox to save net bandwidth
	PLUGIN:MakeHandle(corpse)

	return corpse

end