function PLUGIN:SaveData()
	local data = {}

	for _, entity in ipairs(ents.FindByClass("nut_ration_machine")) do
		data[#data + 1] = {
			entity:GetPos(),
			entity:GetAngles(),
		}
	  end
	  
  	self:setData(data)
end

function PLUGIN:LoadData()
    local data = self:getData()

	for _, info in ipairs(data) do
		local position, angles = unpack(info)

		local storage = ents.Create("nut_ration_machine")
		storage:SetPos(position)
		storage:SetAngles(angles)
		storage:Spawn()
		storage:SetSolid(SOLID_VPHYSICS)
		storage:PhysicsInit(SOLID_VPHYSICS)

		local physObject = storage:GetPhysicsObject()

		if (physObject) then
			physObject:EnableMotion()
		end
	end
end