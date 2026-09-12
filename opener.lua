local _, pockets = ...

local PICK_POCKET = 921

local opener = {}

local function createSecureButton(spell, spellId)
  local name = "Pockets_" .. spell
  local type = "SecureActionButtonTemplate"
  local btn = CreateFrame("Button", name, UIParent, type)
  btn:RegisterForClicks("AnyUp", "AnyDown")
  btn:SetAttribute("useOnKeyDown", false)
  btn:SetAttribute("type1", "spell")
  btn:SetAttribute("spell1", spellId)
  btn:Hide()
  return btn
end

function opener:new(spell, spellId)
  local o = {
    spell = spell,            -- spell name
    spellId = spellId,        -- opener spell identifier
    currentSpellId = spellId, -- spell identifier currently displayed
    btn = createSecureButton(spell, spellId),
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function opener:SetSpell(isPickPocket)
  local newSpellId = isPickPocket and PICK_POCKET or self.spellId
  if self.currentSpellId == newSpellId then
    return
  end
  self.pendingPick = newSpellId
  self:syncSpell()
end

function opener:syncSpell()
  if InCombatLockdown() then
    self:deferSync()
    return
  end
  -- set the spell on the secure button
  self.btn:SetAttribute("spell1", self.pendingPick)
  self.currentSpellId = self.pendingPick
end

function opener:deferSync()
  if self.syncing then
    return
  end
  self.syncing = true
  local btn = self.btn
  btn:SetScript("OnUpdate", function()
    if InCombatLockdown() then
      return
    end
    btn:SetScript("OnUpdate", nil)
    self.syncing = false
    self:syncSpell()
  end)
end

pockets.opener = opener
pockets.openers = {
  AMBUSH = opener:new("Ambush", 8676),
  CHEAP_SHOT = opener:new("Cheap_Shot", 1833),
  GARROTE = opener:new("Garrote", 703),
  SHADOWSTRIKE = opener:new("Shadowstrike", 185438),
  SAP = opener:new("Sap", 6770),
}
