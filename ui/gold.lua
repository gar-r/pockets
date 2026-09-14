local _, pockets = ...

local config = pockets.config

local gold = {
  frame = CreateFrame("Frame", "PocketsGoldFrame", UIParent),
}

local DEFAULT_POINT = "CENTER"
local DEFAULT_RELATIVE_POINT = "CENTER"
local DEFAULT_X = 0
local DEFAULT_Y = -80

local PAD_X = 8
local PAD_Y = 4
local DEFAULT_WIDTH = 140
local DEFAULT_HEIGHT = 20
local BACKDROP_ALPHA = 0.5
local BORDER_ALPHA = 0.35

function gold:Init()
  local f = self.frame
  f:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
  self:createBackdrop()
  self.text = f:CreateFontString(nil, "OVERLAY")
  self.text:SetPoint("CENTER")
  self.text:SetFontObject(GameFontNormalSmall)
  self.text:SetShadowColor(0, 0, 0, 1)
  self.text:SetShadowOffset(1, -1)
  self.text:SetJustifyH("CENTER")
  self.text:SetJustifyV("MIDDLE")

  f:SetMovable(true)
  f:EnableMouse(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(movingFrame)
    if InCombatLockdown() then
      return
    end
    movingFrame:StartMoving()
  end)
  f:SetScript("OnDragStop", function(movingFrame)
    movingFrame:StopMovingOrSizing()
    local point, _, relativePoint, x, y = movingFrame:GetPoint(1)
    PocketsDB.goldFramePos = {
      point = point,
      relativePoint = relativePoint,
      x = x,
      y = y,
    }
  end)

  self:restorePosition()
  config:RegisterTotalGoldListener(function(totalGold)
    self:refresh(totalGold)
  end)
  self:refresh()
end

function gold:createBackdrop()
  local f = self.frame
  self.backdrop = f:CreateTexture(nil, "BACKGROUND")
  self.backdrop:SetAllPoints()
  self.backdrop:SetColorTexture(0, 0, 0, BACKDROP_ALPHA)

  self.border = {}
  local function strip(width, height)
    local t = f:CreateTexture(nil, "ARTWORK")
    t:SetColorTexture(1, 1, 1, BORDER_ALPHA)
    if width then
      t:SetWidth(width)
    end
    if height then
      t:SetHeight(height)
    end
    table.insert(self.border, t)
    return t
  end

  local top = strip(nil, 1)
  top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 1)
  top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 1)

  local bottom = strip(nil, 1)
  bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, -1)
  bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, -1)

  local left = strip(1)
  left:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 0)
  left:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", -1, 0)

  local right = strip(1)
  right:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 0)
  right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, 0)
end

function gold:restorePosition()
  local pos = PocketsDB.goldFramePos
  local f = self.frame
  f:ClearAllPoints()
  if pos then
    f:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
  else
    f:SetPoint(DEFAULT_POINT, UIParent, DEFAULT_RELATIVE_POINT, DEFAULT_X, DEFAULT_Y)
  end
end

function gold:refresh(totalGold)
  self.text:SetText(GetMoneyString(totalGold or config:GetTotalGold()))
  self:sizeToText()
end

function gold:sizeToText()
  local w = self.text:GetStringWidth()
  local h = self.text:GetStringHeight()
  if (w or 0) <= 0 then
    w = DEFAULT_WIDTH - PAD_X
  end
  if (h or 0) <= 0 then
    h = DEFAULT_HEIGHT - PAD_Y
  end
  self.frame:SetSize(w + PAD_X, h + PAD_Y)
end

pockets.gold = gold