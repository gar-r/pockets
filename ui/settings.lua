local name, pockets = ...

local settings = {}

function settings:Init()
    self.category, self.layout = Settings.RegisterVerticalLayoutCategory(name)
    Settings.RegisterAddOnCategory(self.category)
    self:addTotalGoldLabel()
end

-- Refreshable informational row, updated each time the panel is drawn
function settings:addTotalGoldLabel()
    local initializer = CreateSettingsListSectionHeaderInitializer("")
    local originalInitFrame = initializer.InitFrame
    function initializer:InitFrame(frame)
        self.data.name = pockets.strings.settingsTotalGold ..
            ": " .. GetMoneyString(pockets.config.db.totalGold)
        originalInitFrame(self, frame)
    end
    self.layout:AddInitializer(initializer)
end

--function settings:CreateProxiedCheckBox(text, tooltip, variable)
--    local setting = Settings.RegisterAddOnSetting(self.category, variable, variable, PocketsDB,
--        Settings.VarType.Boolean, text, self.defaults[variable])
--    Settings.CreateCheckbox(self.category, setting, tooltip)
--end

pockets.settings = settings
