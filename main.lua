local name, pockets = ...

local config = pockets.config     -- config variables
local settings = pockets.settings -- settings ui
local sm = pockets.sm             -- state machine
local openers = pockets.openers   -- opener secure buttons
local tracker = pockets.tracker   -- gold tracker
local gold = pockets.gold         -- gold display frame

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
        openers:Init()
        tracker:Init()
        gold:Init()
    end
end
