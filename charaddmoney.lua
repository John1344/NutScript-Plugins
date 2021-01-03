PLUGIN.name = "Add money"
PLUGIN.author = "github.com/John1344"
PLUGIN.desc = "Adds /charaddmoney command"

nut.command.add("charaddmoney", {
	adminOnly = true,
	syntax = "<string target> <number amount>",
	onRun = function(client, arguments)
		local amount = tonumber(arguments[2])

		if (!amount or !isnumber(amount) or amount < 0) then
			return "@invalidArg", 2
		end

		local target = nut.command.findPlayer(client, arguments[1])

		if (IsValid(target)) then
			local char = target:getChar()
			
			if (char and amount) then
				amount = math.Round(amount)
				char:giveMoney(amount)
				client:notify("You gave "..nut.currency.get(amount).." to "..target:Name())
			end
		end
	end
})