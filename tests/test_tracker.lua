-- tests/test_tracker.lua
-- Regression tests for the pockets pickpocket gold tracker.
--
-- The tracker watches the state machine: gold looted is the delta of
-- GetMoney() across the LOOTING window (STATE_LOOTING = 2).
--
-- The scenarios below form one continuous pickpocket session so the
-- state machine transitions stay realistic: a pickpocket only opens a
-- loot window from STATE_PICK_POCKET, and after looting the opener is
-- armed (STATE_OPENER) until the player changes target or exits combat.

local here = arg and arg[0]:match("^(.*)[/\\]") or "."
local smPath = here .. "/../core/sm.lua"
local trackerPath = here .. "/../core/tracker.lua"

local function makeFrame()
  local frame = {
    events = {},
    handler = nil,
    RegisterEvent = function(self, e)
      self.events[e] = true
    end,
    SetScript = function(self, script, fn)
      if script == "OnEvent" then
        self.handler = fn
      end
    end,
  }
  function frame:emit(event, ...)
    self.handler(self, event, ...)
  end
  return frame
end

local frame = makeFrame()
_G.CreateFrame = function()
  return frame
end

local function makeOpener(name)
  return {
    name = name,
    SetSpell = function() end,
  }
end

local openers = { makeOpener("Ambush"), makeOpener("Sap") }

local money = 0
_G.GetMoney = function()
  return money
end

-- PLAYER_TARGET_CHANGED re-arms pick pocket only when out of combat
_G.InCombatLockdown = function()
  return false
end

local config = { db = { totalGold = 0 } }
local pockets = { openers = openers, config = config }

local chunk = assert(loadfile(smPath))
chunk(nil, pockets)
local sm = pockets.sm
sm:Init()

chunk = assert(loadfile(trackerPath))
chunk(nil, pockets)
local tracker = pockets.tracker
tracker:Init()

local function ok(cond, msg)
  if not cond then
    error("FAIL: " .. msg, 2)
  end
end

-- re-arm the pick pocket state after a loot window closed (target changed)
local function reset()
  frame:emit("PLAYER_TARGET_CHANGED")
end

-- gold gained during the loot window is added once the window closes
do
  money = 100
  frame:emit("UNIT_SPELLCAST_SUCCEEDED", "player", "GUID", 921)
  ok(config.db.totalGold == 0, "no gold counted while the loot window is open")

  money = 355
  frame:emit("LOOT_CLOSED")
  ok(config.db.totalGold == 255, "gold looted during the window is added")

  ok(sm.state == sm.STATE.OPENER, "loot window closed into the opener state")
end

-- an empty loot window adds nothing
do
  reset()
  money = 100
  frame:emit("UNIT_SPELLCAST_SUCCEEDED", "player", "GUID", 921)
  frame:emit("LOOT_CLOSED")
  ok(config.db.totalGold == 255, "a window with no money adds nothing")
end

-- a negative delta is never subtracted (clamped at zero)
do
  reset()
  money = 100
  frame:emit("UNIT_SPELLCAST_SUCCEEDED", "player", "GUID", 921)
  money = 50
  frame:emit("LOOT_CLOSED")
  ok(config.db.totalGold == 255, "a negative delta is ignored")
end

-- aborting the loot window (target changed mid-loot) finalizes looted gold
do
  reset()
  money = 200
  frame:emit("UNIT_SPELLCAST_SUCCEEDED", "player", "GUID", 921)
  money = 220
  frame:emit("PLAYER_TARGET_CHANGED")
  ok(config.db.totalGold == 275, "changing targets finalizes gold already looted")
end

-- repeated pickpockets accumulate
do
  reset()
  money = 0
  frame:emit("UNIT_SPELLCAST_SUCCEEDED", "player", "GUID", 921)
  money = 40
  frame:emit("LOOT_CLOSED")

  reset()
  money = 40
  frame:emit("UNIT_SPELLCAST_SUCCEEDED", "player", "GUID", 921)
  money = 70
  frame:emit("LOOT_CLOSED")

  ok(config.db.totalGold == 345, "repeated pickpockets accumulate")
end

print("All tracker tests passed")