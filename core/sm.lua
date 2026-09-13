local _, pockets = ...

local PICK_POCKET = 921

-- States in the SM
local STATE_PICK_POCKET = 1
local STATE_LOOTING = 2
local STATE_OPENER = 3

--[[
-- This data structure contains the state machine's allowed state transitions.
-- Each entry: {
--     [STATE_PICK_POCKET] = nextState,
--     [STATE_LOOTING] = nextState,
--     [STATE_OPENER] = nextState,
-- }
-- nil = no transition from that state
--]]
local transitions = {
  UNIT_SPELLCAST_SUCCEEDED    = { STATE_LOOTING, STATE_OPENER, nil },
  UNIT_SPELLCAST_FAILED       = { STATE_OPENER, nil, nil },
  UNIT_SPELLCAST_FAILED_QUIET = { STATE_OPENER, nil, nil },
  PLAYER_REGEN_ENABLED        = { nil, nil, STATE_PICK_POCKET },
  PLAYER_REGEN_DISABLED       = { STATE_OPENER, STATE_OPENER, nil },
  PLAYER_TARGET_CHANGED       = { nil, STATE_PICK_POCKET, STATE_PICK_POCKET },
  LOOT_CLOSED                 = { nil, STATE_OPENER, nil },
}

local sm = {
  frame = CreateFrame("Frame"),
  state = nil,
  observers = {},
}

sm.STATE = {
  PICK_POCKET = STATE_PICK_POCKET,
  LOOTING = STATE_LOOTING,
  OPENER = STATE_OPENER,
}

function sm:Init()
  self:transition(STATE_PICK_POCKET)

  -- register all events
  for e in pairs(transitions) do
    self.frame:RegisterEvent(e)
  end
  self.frame:SetScript("OnEvent", function(_, event, ...)
    self:handleEvent(event, ...)
  end)
end

function sm:RegisterStateListener(fn)
  table.insert(self.observers, fn)
end

function sm:handleEvent(event, ...)
  if not self:isValidEvent(event) then
    return
  end
  local newState = transitions[event][self.state]
  if newState == nil then
    return
  end
  -- condition for allowing transition to the next state:
  -- no custom event handler defined for the event,
  -- or custom event handler returns true
  if not self[event]
      or self[event] and self[event](self, ...) then
    self:transition(newState)
  end
end

function sm:isValidEvent(event)
  return transitions[event] ~= nil
end

function sm:transition(newState)
  local oldState = self.state
  self.state = newState
  -- notify observers of the state change
  for _, fn in ipairs(self.observers) do
    fn(oldState, newState)
  end
end

function sm:UNIT_SPELLCAST_SUCCEEDED(unit, _, spellId)
  -- only allow next state transition when the player casts pick pocket
  return unit == "player" and spellId == PICK_POCKET
end

function sm:PLAYER_TARGET_CHANGED()
  return not InCombatLockdown()
end

pockets.sm = sm
