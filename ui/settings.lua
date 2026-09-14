local name, pockets = ...

local settings = {}

function settings:Init()
    self.category, self.layout = Settings.RegisterVerticalLayoutCategory(name)
    Settings.RegisterAddOnCategory(self.category)
    self:addTrackCheckBox()
end

function settings:addTrackCheckBox()
    local setting = self:registerTrackSetting()
    Settings.CreateCheckbox(self.category, setting,
        pockets.strings.settingsTrackPickPocketTooltip)
end

function settings:registerTrackSetting()
    return Settings.RegisterProxySetting(
        self.category,
        "trackEnabled",
        Settings.VarType.Boolean,
        pockets.strings.settingsTrackPickPocket,
        true,
        function()
            return pockets.config:IsTrackingEnabled()
        end,
        function(value)
            pockets.config:SetTrackingEnabled(value)
        end
    )
end

pockets.settings = settings
