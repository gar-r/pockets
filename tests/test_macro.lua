-- tests/test_macro.lua
-- Regression tests for the pockets macro helper (ui/macro.lua).
--
-- The helper creates or updates a macro named "Pockets" that clicks the
-- selected opener's secure button (`/click Pockets_<Spell>`). It must:
--   * build the two-line macro body (#showtooltip + /click) for each opener,
--   * find an existing "Pockets" macro among account + character macros,
--   * create a new macro with the opener's spell icon when none exists,
--   * update the existing macro in place when one already exists,
--   * refuse to run while in combat,
--   * report failure when the macro list is full.

local here = arg and arg[0]:match("^(.*)[/\\]") or "."
local macroPath = here .. "/../ui/macro.lua"

local function ok(cond, msg)
  if not cond then
    error("FAIL: " .. msg, 2)
  end
end

-- mock WoW globals, reset between scenarios
_G.GetNumMacros = function()
  return 0, 0
end
_G.GetMacroInfo = function()
  return nil
end
_G.CreateMacro = function()
  return 1
end
_G.EditMacro = function() end
_G.InCombatLockdown = function()
  return false
end
_G.C_Spell = {
  GetSpellInfo = function(spellId)
    return { name = "test", iconID = 123 + spellId, spellID = spellId }
  end,
}

local calls = {
  create = {},
  edit = {},
}

_G.CreateMacro = function(name, icon, body, perCharacter)
  table.insert(calls.create, { name = name, icon = icon, body = body, perCharacter = perCharacter })
  return #calls.create
end
_G.EditMacro = function(index, name, icon, body)
  table.insert(calls.edit, { index = index, name = name, icon = icon, body = body })
  return index
end

local function makeOpener(spell, spellId)
  return { spell = spell, spellId = spellId }
end

local pockets = {
  openers = {
    AMBUSH = makeOpener("Ambush", 8676),
    CHEAP_SHOT = makeOpener("Cheap_Shot", 1833),
    GARROTE = makeOpener("Garrote", 703),
    SHADOWSTRIKE = makeOpener("Shadowstrike", 185438),
    SAP = makeOpener("Sap", 6770),
  },
  strings = {},
}

local chunk = assert(loadfile(macroPath))
chunk(nil, pockets)
local macro = pockets.macro

-- buildBody produces the two-line click macro for each opener
do
  local expected = {
    AMBUSH = "#showtooltip Ambush\n/click Pockets_Ambush",
    CHEAP_SHOT = "#showtooltip Cheap Shot\n/click Pockets_Cheap_Shot",
    GARROTE = "#showtooltip Garrote\n/click Pockets_Garrote",
    SHADOWSTRIKE = "#showtooltip Shadowstrike\n/click Pockets_Shadowstrike",
    SAP = "#showtooltip Sap\n/click Pockets_Sap",
  }
  for key, body in pairs(expected) do
    ok(macro.buildBody(key) == body, "buildBody generates the correct body for " .. key)
  end
end

-- buildBody returns nil for an unknown opener
do
  ok(macro.buildBody("NOT_REAL") == nil, "buildBody returns nil for an unknown opener")
end

-- findExistingMacro returns nil when no "Pockets" macro exists
do
  _G.GetNumMacros = function()
    return 3, 2
  end
  _G.GetMacroInfo = function(index)
    local names = { "Fight", "Flee", "Drink", "Eat", "Sleep" }
    return names[index]
  end
  ok(macro.findExistingMacro() == nil, "findExistingMacro returns nil when absent")
end

-- findExistingMacro finds an account-wide "Pockets" macro
do
  _G.GetNumMacros = function()
    return 3, 0
  end
  _G.GetMacroInfo = function(index)
    local names = { "Fight", "Pockets", "Drink" }
    return names[index]
  end
  ok(macro.findExistingMacro() == 2, "findExistingMacro finds the account 'Pockets' macro")
end

-- findExistingMacro finds a character-only "Pockets" macro
do
  _G.GetNumMacros = function()
    return 2, 3
  end
  _G.GetMacroInfo = function(index)
    local names = { "Fight", "Flee", "Drink", "Pockets", "Sleep" }
    return names[index]
  end
  ok(macro.findExistingMacro() == 4, "findExistingMacro finds the character 'Pockets' macro")
end

-- creating a macro from the default selection writes the right body and icon
do
  _G.GetNumMacros = function()
    return 0, 0
  end
  _G.GetMacroInfo = function()
    return nil
  end
  macro.selectedOpener = "AMBUSH"
  calls.create = {}
  local okCreate, result = macro.createOrUpdateMacro()
  ok(okCreate == true, "createOrUpdateMacro reports success on create")
  ok(result == "created", "create path reports 'created'")
  ok(#calls.create == 1, "CreateMacro is called once when no macro exists")
  ok(calls.create[1].name == "Pockets", "CreateMacro uses the 'Pockets' name")
  ok(calls.create[1].icon == 8799, "CreateMacro uses the opener's spell icon")
  ok(calls.create[1].body == "#showtooltip Ambush\n/click Pockets_Ambush",
     "CreateMacro writes the selected opener's body")
end

-- a macro with an underscore in its spell keeps the underscore in /click
do
  _G.GetNumMacros = function()
    return 0, 0
  end
  _G.GetMacroInfo = function()
    return nil
  end
  macro.selectedOpener = "CHEAP_SHOT"
  calls.create = {}
  local okCreate, result = macro.createOrUpdateMacro()
  ok(okCreate == true and result == "created", "create path works for Cheap Shot")
  ok(calls.create[1].body == "#showtooltip Cheap Shot\n/click Pockets_Cheap_Shot",
     "Cheap Shot body keeps the underscore in /click but not in #showtooltip")
end

-- an existing "Pockets" macro is updated in place, not duplicated
do
  _G.GetNumMacros = function()
    return 5, 0
  end
  _G.GetMacroInfo = function(index)
    local names = { "Fight", "Pockets", "Drink", "Eat", "Sleep" }
    return names[index]
  end
  macro.selectedOpener = "GARROTE"
  calls.create = {}
  calls.edit = {}
  local okCreate, result = macro.createOrUpdateMacro()
  ok(okCreate == true and result == "updated", "update path reports 'updated'")
  ok(#calls.create == 0, "update path does not call CreateMacro")
  ok(#calls.edit == 1, "update path calls EditMacro once")
  ok(calls.edit[1].index == 2, "EditMacro targets the found macro index")
  ok(calls.edit[1].body == "#showtooltip Garrote\n/click Pockets_Garrote",
     "EditMacro writes the selected opener's body")
end

-- an unknown selection short-circuits before touching the macro list
do
  macro.selectedOpener = "NOT_REAL"
  calls.create = {}
  calls.edit = {}
  local okCreate, result = macro.createOrUpdateMacro()
  ok(okCreate == false and result == "no_selection", "unknown selection reports 'no_selection'")
  ok(#calls.create == 0 and #calls.edit == 0, "no macro calls happen for an unknown selection")
end

-- creating is blocked while in combat
do
  _G.InCombatLockdown = function()
    return true
  end
  macro.selectedOpener = "SAP"
  calls.create = {}
  local okCreate, result = macro.createOrUpdateMacro()
  ok(okCreate == false and result == "combat", "in combat reports 'combat'")
  ok(#calls.create == 0, "no macro is created while in combat")
  _G.InCombatLockdown = function()
    return false
  end
end

-- a full macro list reports failure
do
  _G.GetNumMacros = function()
    return 0, 0
  end
  _G.CreateMacro = function()
    return nil
  end
  macro.selectedOpener = "SAP"
  local okCreate, result = macro.createOrUpdateMacro()
  ok(okCreate == false and result == "full", "full macro list reports 'full'")
end

-- a missing spell icon falls back to the question mark icon
do
  _G.CreateMacro = function(name, icon, body, perCharacter)
    table.insert(calls.create, { name = name, icon = icon, body = body, perCharacter = perCharacter })
    return 1
  end
  _G.C_Spell.GetSpellInfo = function()
    return nil
  end
  macro.selectedOpener = "SAP"
  calls.create = {}
  local okCreate, result = macro.createOrUpdateMacro()
  ok(okCreate == true and result == "created", "create succeeds without spell info")
  ok(calls.create[1].icon == "INV_Misc_QuestionMark", "missing icon falls back to the question mark")
end

print("All macro tests passed")