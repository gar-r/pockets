-- tests/test_sm.lua
-- Regression tests for the pockets state machine.
--
-- STATE_PICK_POCKET = 1, STATE_LOOTING = 2, STATE_OPENER = 3

local here = arg and arg[0]:match("^(.*)[/\\]") or "."
local smPath = here .. "/../core/sm.lua"

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
  local op = {
    name = name,
    calls = {},
  }
  function op:SetSpell(isPickPocket)
    table.insert(self.calls, isPickPocket)
  end
  return op
end

local openers = { makeOpener("Ambush"), makeOpener("Sap") }
local pockets = { openers = openers }
local chunk = assert(loadfile(smPath))
chunk(nil, pockets)
local sm = pockets.sm

-- wire the openers to the state machine like core/opener.lua opener:Init()
for _, op in ipairs(openers) do
  sm:RegisterStateListener(function(_, newState)
    op:SetSpell(newState ~= sm.STATE.OPENER)
  end)
end

local function lastSpell(op)
  return op.calls[#op.calls]
end

local function ok(cond, msg)
  if not cond then
    error("FAIL: " .. msg, 2)
  end
end

local function is(state)
  local names = { "PICK_POCKET", "LOOTING", "OPENER" }
  ok(
    sm.state == state,
    "expected state " .. (names[state] or state) .. ", got " .. (names[sm.state] or tostring(sm.state))
  )
end

-- successful pick pocket arms the opener only after loot fully closes
do
  sm:Init()
  is(1)
  ok(lastSpell(openers[1]) == true, "initial state arms pick pocket")

  -- pick pocket succeeds
  frame:emit("UNIT_SPELLCAST_SUCCEEDED", "player", "GUID", 921)
  is(2)
  ok(lastSpell(openers[1]) == true, "opener stays on pick pocket while loot is pending")

  -- loot window closes -> only now arm the opener
  frame:emit("LOOT_CLOSED")
  is(3)
  ok(lastSpell(openers[1]) == false, "opener is armed only after loot closes")
end

-- a stray failed cast during looting must not jump ahead to the opener
do
  sm:Init()
  frame:emit("UNIT_SPELLCAST_SUCCEEDED", "player", "GUID", 921)
  is(2)

  frame:emit("UNIT_SPELLCAST_FAILED_QUIET", "player", "GUID", 921)
  is(2)
  ok(lastSpell(openers[1]) == true, "stray failed cast during looting keeps pick pocket armed")

  frame:emit("UNIT_SPELLCAST_FAILED", "player", "GUID", 921)
  is(2)
  ok(lastSpell(openers[1]) == true, "stray failed cast during looting keeps pick pocket armed")

  frame:emit("LOOT_CLOSED")
  is(3)
  ok(lastSpell(openers[1]) == false, "loot closes normally after stray failed casts")
end

-- a failed pick pocket with no loot still allows the opener
do
  sm:Init()
  frame:emit("UNIT_SPELLCAST_FAILED", "player", "GUID", 921)
  is(3)
  ok(lastSpell(openers[1]) == false, "opener is armed after a failed pick pocket")

  sm:Init()
  frame:emit("UNIT_SPELLCAST_FAILED_QUIET", "player", "GUID", 921)
  is(3)
  ok(lastSpell(openers[1]) == false, "opener is armed after a quiet failed pick pocket")
end

-- a registered observer is notified with (oldState, newState) on every transition
do
  sm:Init()
  local seen = {}
  sm:RegisterStateListener(function(oldState, newState)
    table.insert(seen, { old = oldState, new = newState })
  end)

  frame:emit("UNIT_SPELLCAST_SUCCEEDED", "player", "GUID", 921)
  frame:emit("LOOT_CLOSED")

  ok(#seen == 2, "observer was notified once per transition")
  ok(seen[1].old == 1 and seen[1].new == 2, "observer received 1 -> 2")
  ok(seen[2].old == 2 and seen[2].new == 3, "observer received 2 -> 3")
end

-- the public STATE table mirrors the real internal states
do
  sm:Init()
  ok(sm.state == sm.STATE.PICK_POCKET, "STATE.PICK_POCKET matches the initial state")

  frame:emit("UNIT_SPELLCAST_SUCCEEDED", "player", "GUID", 921)
  ok(sm.state == sm.STATE.LOOTING, "STATE.LOOTING matches the looting state")

  frame:emit("LOOT_CLOSED")
  ok(sm.state == sm.STATE.OPENER, "STATE.OPENER matches the opener state")
end

print("All state machine tests passed")