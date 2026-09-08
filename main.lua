local name, pockets = ...

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
	self[event](self)
end)

function frame:PLAYER_LOGIN()
	print(name .. ": Hello, World!")
end

pockets.addonName = name
