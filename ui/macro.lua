local _, pockets = ...

local MACRO_NAME = "Pockets"

local OPENER_KEYS = { "AMBUSH", "CHEAP_SHOT", "GARROTE", "SHADOWSTRIKE", "SAP" }

local macro = {}
macro.selectedOpener = "AMBUSH"

function macro.buildBody(openerKey)
  local op = pockets.openers[openerKey]
  if not op then
    return nil
  end
  local displayName = op.spell:gsub("_", " ")
  return "#showtooltip " .. displayName .. "\n/click Pockets_" .. op.spell
end

function macro.findExistingMacro()
  local numAccount, numCharacter = GetNumMacros()
  for i = 1, numAccount + numCharacter do
    local name = GetMacroInfo(i)
    if name == MACRO_NAME then
      return i
    end
  end
  return nil
end

function macro.createOrUpdateMacro()
  if InCombatLockdown() then
    return false, "combat"
  end

  local body = macro.buildBody(macro.selectedOpener)
  if not body then
    return false, "no_selection"
  end

  local existingIndex = macro.findExistingMacro()
  if existingIndex then
    EditMacro(existingIndex, nil, nil, body)
    return true, "updated"
  end

  local op = pockets.openers[macro.selectedOpener]
  local spellInfo = C_Spell.GetSpellInfo(op.spellId)
  local icon = spellInfo and spellInfo.iconID or "INV_Misc_QuestionMark"
  local id = CreateMacro(MACRO_NAME, icon, body)
  if id then
    return true, "created"
  end
  return false, "full"
end

function macro:addControls(category)
  self.category = category
  self:addDropdown()
  self:addCreateButton()
end

function macro:addDropdown()
  local setting = Settings.RegisterProxySetting(
    self.category,
    "macroOpener",
    Settings.VarType.String,
    pockets.strings.settingsMacroHelper,
    "AMBUSH",
    function()
      return self.selectedOpener
    end,
    function(value)
      self.selectedOpener = value
    end
  )

  local function getOptions()
    local container = Settings.CreateControlTextContainer()
    for _, key in ipairs(OPENER_KEYS) do
      local op = pockets.openers[key]
      if op then
        container:Add(key, op.spell:gsub("_", " "))
      end
    end
    return container:GetData()
  end

  Settings.CreateDropdown(
    self.category,
    setting,
    getOptions,
    pockets.strings.settingsMacroHelperTooltip
  )
end

function macro:addCreateButton()
  local initializer = Settings.CreateElementInitializer("SettingButtonControlTemplate", {
    name = pockets.strings.settingsMacroCreateButton,
    buttonText = pockets.strings.settingsMacroCreateButton,
    buttonClick = function()
      self:handleCreateClick()
    end,
    tooltip = pockets.strings.settingsMacroCreateTooltip,
  })
  Settings.RegisterInitializer(self.category, initializer)
end

function macro:handleCreateClick()
  local ok, result = self.createOrUpdateMacro()
  if result == "created" then
    print(pockets.strings.settingsMacroCreateSuccess)
  elseif result == "updated" then
    print(pockets.strings.settingsMacroCreateUpdated)
  elseif result == "full" then
    print(pockets.strings.settingsMacroCreateErrorFull)
  elseif result == "combat" then
    print(pockets.strings.settingsMacroCreateErrorInCombat)
  end
end

pockets.macro = macro
