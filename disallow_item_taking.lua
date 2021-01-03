PLUGIN.name = "Disallow item taking"
PLUGIN.author = "github.com/John1344"
PLUGIN.desc = "Adds /disallowitemtaking command"

nut.command.add("disallowitemtaking", {
	adminOnly = true,
	onRun = function (client, arguments)
        local eyeTrace = client:GetEyeTrace().Entity

        if (eyeTrace:GetClass() == "nut_item") then
            local item = nut.item.instances[eyeTrace.nutItemID]

            if (item) then
                nut.item.instances[eyeTrace.nutItemID]:setData("cannotTake", true)

                client:notify("Success")
                return
            end
        end

		client:notify("Something went wrong")
	end
})

nut.command.add("allowitemtaking", {
	adminOnly = true,
	onRun = function (client, arguments)
        local eyeTrace = client:GetEyeTrace().Entity

        if (eyeTrace:GetClass() == "nut_item") then
            local item = nut.item.instances[eyeTrace.nutItemID]

            if (item) then
                nut.item.instances[eyeTrace.nutItemID]:setData("cannotTake", nil)

                client:notify("Success")
                return
            end
        end

		client:notify("Something went wrong")
	end
})

function PLUGIN:CanPlayerTakeItem(client, item)
    if (type(item) != "Entity") then
        if (item:getData("cannotTake") == true) then
            return false
        end
	end
end