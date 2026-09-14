local _, pockets = ...

local config = pockets.config
local sm = pockets.sm

local tracker = {
  frame = CreateFrame("Frame"),
}

function tracker:Init()
  self.frame:RegisterEvent("PLAYER_MONEY")
  self.frame:SetScript("OnEvent", function (_, event)
    if event == "PLAYER_MONEY" then
      self:onPlayerMoney()
    end
  end)
  sm:RegisterStateListener(function(oldState, newState)
    self:onStateChanged(oldState, newState)
  end)
end

function tracker:onStateChanged(_, newState)
  if not config:IsTrackingEnabled() then
    return
  end
  if newState == sm.STATE.LOOTING then
    self.snapshot = GetMoney()
    C_Timer.After(1, function ()
      self.snapshot = nil
    end)
  end
end

function tracker:onPlayerMoney()
  if self.snapshot then
    local delta = GetMoney() - self.snapshot
    self.snapshot = nil
    config:AddTotalGold(delta)
  end
end

pockets.tracker = tracker
