local name, pockets = ...

local settings = {}

function settings:Init()
    self.category, self.layout = Settings.RegisterVerticalLayoutCategory(name)
    Settings.RegisterAddOnCategory(self.category)
end

--function settings:CreateProxiedCheckBox(text, tooltip, variable)
--    local setting = Settings.RegisterAddOnSetting(self.category, variable, variable, PocketsDB,
--        Settings.VarType.Boolean, text, self.defaults[variable])
--    Settings.CreateCheckbox(self.category, setting, tooltip)
--end

pockets.settings = settings
