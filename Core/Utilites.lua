SD = {}

function SD.shortNumber(n)
	if n == nil then
		return ""
	end

    if n >= 10^6 then
        return string.format("%.1fm", n / 10^6)
    elseif n >= 10^3 then
        return string.format("%.1fk", n / 10^3)
	end
	return string.format("%d", n)
end

function SD.printTable(table)
	for key, value in pairs(table) do
		DEFAULT_CHAT_FRAME:AddMessage("|cFFffff00SpellDamage:|r " .. key .. " -> " .. value)
	end
end