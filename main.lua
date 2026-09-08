local name, pockets = ...

local config = pockets.config     -- config variables
local settings = pockets.settings -- settings ui
local sm = pockets.sm             -- statem machine

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
  if self[event] then
    self[event](self, ...)
  end
end)

function frame:ADDON_LOADED(addonName)
    if name == addonName then
        config:Init()
        settings:Init()
        sm:Init()
    end
end
