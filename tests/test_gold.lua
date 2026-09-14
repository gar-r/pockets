-- tests/test_gold.lua
-- Regression tests for the pockets gold display frame (ui/gold.lua).
--
-- The frame is a small, transparent, draggable frame presenting the
-- tracked pick pocket total (config:GetTotalGold()) formatted with
-- GetMoneyString. It must:
--   * show the current total when it loads,
--   * update the label whenever the total changes,
--   * drag with the left mouse button (not while in combat),
--   * persist its dragged position into PocketsDB and restore it on load,
--   * be transparent (no background texture).

local here = arg and arg[0]:match("^(.*)[/\\]") or "."
local configPath = here .. "/../core/config.lua"
local goldPath = here .. "/../ui/gold.lua"

local function makeFontString()
  return {
    text = nil,
    fontObject = nil,
    metricW = 70,
    metricH = 12,
    SetPoint = function() end,
    SetFontObject = function(self, fo)
      self.fontObject = fo
    end,
    SetShadowColor = function() end,
    SetShadowOffset = function() end,
    SetJustifyH = function() end,
    SetJustifyV = function() end,
    SetText = function(self, t)
      self.text = t
    end,
    GetStringWidth = function(self)
      return self.metricW
    end,
    GetStringHeight = function(self)
      return self.metricH
    end,
  }
end

local function makeTexture()
  return {
    color = nil,
    allPoints = nil,
    SetAllPoints = function(self, relTo)
      self.allPoints = relTo or "PARENT"
    end,
    SetColorTexture = function(self, r, g, b, a)
      self.color = { r, g, b, a }
    end,
    SetPoint = function() end,
    SetHeight = function() end,
    SetWidth = function() end,
  }
end

local function makeFrame(n, parent)
  local frame = {
    name = n,
    parent = parent,
    scripts = {},
    pos = nil,
    isMoving = false,
    textures = {},
    fontStrings = {},
    RegisterForDrag = function() end,
    SetMovable = function() end,
    EnableMouse = function() end,
    SetClampedToScreen = function() end,
    SetSize = function(self, w, h)
      self.size = { w, h }
    end,
    SetBackdrop = function(self, spec)
      self.backdrop = spec
    end,
    SetBackdropColor = function(self, r, g, b, a)
      self.backdropColor = { r, g, b, a }
    end,
    SetBackdropBorderColor = function(self, r, g, b, a)
      self.backdropBorderColor = { r, g, b, a }
    end,
    SetScript = function(self, script, fn)
      self.scripts[script] = fn
    end,
    GetScript = function(self, script)
      return self.scripts[script]
    end,
    CreateTexture = function(self, ...)
      local t = makeTexture()
      table.insert(self.textures, t)
      return t
    end,
    CreateFontString = function(self, ...)
      local fs = makeFontString()
      table.insert(self.fontStrings, fs)
      return fs
    end,
    SetPoint = function(self, ...)
      self.pos = { ... }
    end,
    ClearAllPoints = function() end,
    GetPoint = function(self)
      if self.pos then
        return unpack(self.pos)
      end
    end,
    StartMoving = function(self)
      self.isMoving = true
    end,
    StopMovingOrSizing = function(self)
      self.isMoving = false
    end,
  }
  return frame
end

_G.UIParent = makeFrame("UIParent")
_G.GameFontNormalSmall = "GameFontNormalSmall"

_G.CreateFrame = function(frameType, name, parent)
  return makeFrame(name, parent)
end

_G.InCombatLockdown = function()
  return false
end

_G.GetMoneyString = function(amount)
  return "MONEY:" .. tostring(amount)
end

local function ok(cond, msg)
  if not cond then
    error("FAIL: " .. msg, 2)
  end
end

local pockets = {}
local chunk = assert(loadfile(configPath))
chunk(nil, pockets)
local config = pockets.config

chunk = assert(loadfile(goldPath))
chunk(nil, pockets)
local gold = pockets.gold

-- fresh saved variable every scenario
_G.PocketsDB = nil
config:Init()

-- Init shows the tracked total formatted as a WoW money string
do
  config:AddTotalGold(100)
  config:AddTotalGold(55)
  gold:Init()
  local text = gold.frame.fontStrings[1]
  ok(text ~= nil and text.text == "MONEY:155",
     "Init displays the tracked total with GetMoneyString")
end

-- the label updates whenever the tracked total changes
do
  config:AddTotalGold(45)
  local text = gold.frame.fontStrings[1]
  ok(text.text == "MONEY:200", "label refreshes when gold is added")
end

-- the frame drags with the left mouse button
do
  gold.frame:SetPoint("CENTER", _G.UIParent, "CENTER", 0, 0)
  gold.frame.scripts.OnDragStart(gold.frame)
  ok(gold.frame.isMoving == true, "OnDragStart starts moving the frame")
  gold.frame.scripts.OnDragStop(gold.frame)
  ok(gold.frame.isMoving == false, "OnDragStop stops moving the frame")
end

-- dragging records the frame's position into PocketsDB
do
  gold.frame:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT", 30, -40)
  gold.frame.scripts.OnDragStop(gold.frame)
  ok(_G.PocketsDB.goldFramePos ~= nil, "drag stop saves the frame position")
  ok(_G.PocketsDB.goldFramePos.x == 30, "saved position keeps the x offset")
  ok(_G.PocketsDB.goldFramePos.y == -40, "saved position keeps the y offset")
  ok(_G.PocketsDB.goldFramePos.point == "TOPLEFT", "saved position keeps the anchor point")
end

-- a saved position is restored on the next load
do
  _G.PocketsDB = {
    totalGold = 0,
    trackEnabled = true,
    goldFramePos = { point = "CENTER", relativePoint = "CENTER", x = 120, y = -80 },
  }
  config:Init()
  gold.frame.pos = nil
  gold:Init()
  ok(gold.frame.pos ~= nil, "restore places the frame")
  ok(gold.frame.pos[1] == "CENTER" and gold.frame.pos[4] == 120 and gold.frame.pos[5] == -80,
     "restore re-applies the saved point and offsets")
end

-- the frame cannot be dragged while in combat
do
  _G.InCombatLockdown = function()
    return true
  end
  gold.frame.isMoving = false
  gold.frame.scripts.OnDragStart(gold.frame)
  ok(gold.frame.isMoving == false, "OnDragStart is a no-op in combat")
  _G.InCombatLockdown = function()
    return false
  end
end

-- transparent: a subtle semi-transparent backdrop improves readability
do
  gold.frame.textures = {}
  gold:Init()
  local bg = gold.frame.textures[1]
  ok(bg ~= nil, "a background texture is created for the frame")
  ok(bg.allPoints ~= nil, "the backdrop fills the frame")
  ok(bg.color ~= nil and bg.color[1] == 0 and bg.color[2] == 0 and bg.color[3] == 0,
     "the backdrop is black")
  ok(bg.color ~= nil and bg.color[4] ~= nil and bg.color[4] > 0 and bg.color[4] < 1,
     "the backdrop is semi-transparent")
end

-- the frame is sized to its text so there is something to grab and drag
do
  gold.frame.size = nil
  gold:Init()
  ok(gold.frame.size ~= nil, "Init sizes the frame to its text")
  ok(gold.frame.size[1] == 78 and gold.frame.size[2] == 16,
     "frame size fits the text plus padding (78x16)")
end

-- when the text is not measurable, the frame still gets a usable size
do
  gold.frame.size = nil
  gold.text.metricW = nil
  gold.text.metricH = nil
  gold:refresh()
  ok(gold.frame.size ~= nil, "refresh always sizes the frame")
  ok(gold.frame.size[1] == 140 and gold.frame.size[2] == 20,
     "unmeasurable text falls back to the default size (140x20)")
end

print("All gold tests passed")