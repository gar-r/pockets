-- tests/test_config.lua
-- Regression tests for pockets.config, the single manager for PocketsDB.
--
-- The config module owns the PocketsDB saved variable: it is the only
-- place that reads or writes the raw table, it fills defaults on load,
-- and it exposes typed accessors that other modules use.

local here = arg and arg[0]:match("^(.*)[/\\]") or "."
local configPath = here .. "/../core/config.lua"

_G.PocketsDB = nil

local function ok(cond, msg)
  if not cond then
    error("FAIL: " .. msg, 2)
  end
end

local pockets = {}
local chunk = assert(loadfile(configPath))
chunk(nil, pockets)
local config = pockets.config

-- Init creates the PocketsDB global, links it to config.db, and applies defaults
do
  ok(_G.PocketsDB == nil, "PocketsDB starts unset")
  config:Init()
  ok(_G.PocketsDB ~= nil, "Init assigns the PocketsDB global")
  ok(config.db == _G.PocketsDB, "config.db is the PocketsDB global")
  ok(config.db.totalGold == 0, "totalGold defaults to 0")
  ok(config.db.trackEnabled == true, "trackEnabled defaults to true")
  ok(config.db.showGoldFrame == true, "showGoldFrame defaults to true")
end

-- AddTotalGold accumulates through config, not the raw table
do
  config:AddTotalGold(100)
  config:AddTotalGold(55)
  ok(config:GetTotalGold() == 155, "gold accumulates across calls")
  ok(config.db == _G.PocketsDB and _G.PocketsDB.totalGold == 155,
     "accumulation is written straight into PocketsDB")
end

-- non-positive deltas are ignored
do
  config:AddTotalGold(0)
  config:AddTotalGold(-50)
  ok(config:GetTotalGold() == 155, "zero and negative deltas are ignored")
end

-- disabling tracking stops accumulation but preserves the tally
do
  config:SetTrackingEnabled(false)
  ok(config:IsTrackingEnabled() == false, "tracking can be disabled")
  config:AddTotalGold(100)
  ok(config:GetTotalGold() == 155, "no gold is added while tracking is disabled")

  config:SetTrackingEnabled(true)
  config:AddTotalGold(50)
  ok(config:GetTotalGold() == 205, "accumulation resumes after re-enabling")
end

-- showGoldFrame can be toggled independently and coerced to boolean
do
  ok(config:IsShowGoldFrameEnabled() == true, "showGoldFrame starts enabled")
  config:SetShowGoldFrame(false)
  ok(config:IsShowGoldFrameEnabled() == false, "showGoldFrame can be disabled")
  config:SetShowGoldFrame(true)
  ok(config:IsShowGoldFrameEnabled() == true, "showGoldFrame can be re-enabled")
  config:SetShowGoldFrame(nil)
  ok(config:IsShowGoldFrameEnabled() == false, "showGoldFrame coerces non-boolean to false")
end

-- ResetTotalGold zeroes the tally and notifies listeners
do
  config:AddTotalGold(500)
  local notified
  config:RegisterTotalGoldListener(function(total)
    notified = total
  end)
  config:ResetTotalGold()
  ok(config:GetTotalGold() == 0, "ResetTotalGold zeroes the tally")
  ok(notified == 0, "ResetTotalGold notifies listeners with the new total")
  ok(_G.PocketsDB.totalGold == 0, "ResetTotalGold writes into PocketsDB")
end

-- Init preserves previously saved values instead of overwriting them
do
  _G.PocketsDB = { totalGold = 999, trackEnabled = false, showGoldFrame = false }
  config:Init()
  ok(config.db == _G.PocketsDB, "re-Init re-binds to the existing global")
  ok(config.db.totalGold == 999, "an existing totalGold is preserved")
  ok(config.db.trackEnabled == false, "an existing trackEnabled is preserved")
  ok(config.db.showGoldFrame == false, "an existing showGoldFrame is preserved")
  _G.PocketsDB = nil
end

print("All config tests passed")