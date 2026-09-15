local name, pockets = ...

local settings = {}

function settings:Init()
    self.category, self.layout = Settings.RegisterVerticalLayoutCategory(name)
    Settings.RegisterAddOnCategory(self.category)
    self:addTrackCheckBox()
    self:addShowGoldFrameCheckBox()
end

function settings:addTrackCheckBox()
    local setting = self:registerTrackSetting()
    self.trackInitializer = Settings.CreateCheckbox(self.category, setting,
        pockets.strings.settingsTrackPickPocketTooltip)
end

function settings:addShowGoldFrameCheckBox()
    local setting = self:registerShowGoldFrameSetting()
    self.goldFrameInitializer = Settings.CreateCheckbox(self.category, setting,
        pockets.strings.settingsShowGoldFrameTooltip)
    self.goldFrameInitializer:SetParentInitializer(self.trackInitializer,
        function()
            return pockets.config:IsTrackingEnabled()
        end)
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
            if pockets.gold then
                pockets.gold:updateVisibility()
            end
        end
    )
end

function settings:registerShowGoldFrameSetting()
    return Settings.RegisterProxySetting(
        self.category,
        "showGoldFrame",
        Settings.VarType.Boolean,
        pockets.strings.settingsShowGoldFrame,
        true,
        function()
            return pockets.config:IsShowGoldFrameEnabled()
        end,
        function(value)
            if not pockets.config:IsTrackingEnabled() then
                return
            end
            pockets.config:SetShowGoldFrame(value)
            if pockets.gold then
                pockets.gold:updateVisibility()
            end
        end
    )
end

pockets.settings = settings