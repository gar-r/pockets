local _, pockets = ...

local config = pockets.config
local sm = pockets.sm

local tracker = {}

function tracker:Init()
  sm:RegisterStateListener(function(oldState, newState)
    self:onStateChanged(oldState, newState)
  end)
end

function tracker:onStateChanged(oldState, newState)
  if newState == sm.STATE.LOOTING then
    -- snapshot player money when the pickpocket loot window opens
    self.baseMoney = GetMoney()
    return
  end
  if oldState == sm.STATE.LOOTING then
    -- the loot window closed without a transition to the next loot window:
    -- whatever positive delta happened in between is pickpocket gold
    config:AddTotalGold(GetMoney() - self.baseMoney)
    self.baseMoney = nil
  end
end

pockets.tracker = tracker