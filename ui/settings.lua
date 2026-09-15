local name, pockets = ...

local settings = {}

function settings:Init()
    self.category, self.layout = Settings.RegisterVerticalLayoutCategory(name)
    Settings.RegisterAddOnCategory(self.category)
    self:addTrackCheckBox()
    self:addShowGoldFrameCheckBox()
    self:addResetOnLoginCheckBox()
    self:addResetGoldButton()
end

function settings:addResetGoldButton()
    local initializer = Settings.CreateElementInitializer("SettingButtonControlTemplate", {
        name = pockets.strings.settingsResetTotalGold,
        buttonText = pockets.strings.settingsResetTotalGold,
        buttonClick = function()
            self:confirmResetTotalGold()
        end,
        tooltip = pockets.strings.settingsResetTotalGoldTooltip,
    })
    Settings.RegisterInitializer(self.category, initializer)
end

function settings:confirmResetTotalGold()
    StaticPopup_ShowCustomGenericConfirmation({
        text = pockets.strings.settingsResetTotalGoldConfirm,
        acceptText = pockets.strings.settingsResetTotalGoldAccept,
        cancelText = pockets.strings.settingsResetTotalGoldCancel,
        showAlert = true,
        callback = function()
            pockets.config:ResetTotalGold()
        end,
    })
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

function settings:addResetOnLoginCheckBox()
    local setting = self:registerResetOnLoginSetting()
    self.resetOnLoginInitializer = Settings.CreateCheckbox(self.category, setting,
        pockets.strings.settingsResetOnLoginTooltip)
    self.resetOnLoginInitializer:SetParentInitializer(self.trackInitializer,
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

function settings:registerResetOnLoginSetting()
    return Settings.RegisterProxySetting(
        self.category,
        "resetOnLogin",
        Settings.VarType.Boolean,
        pockets.strings.settingsResetOnLogin,
        true,
        function()
            return pockets.config:IsResetOnLoginEnabled()
        end,
        function(value)
            if not pockets.config:IsTrackingEnabled() then
                return
            end
            pockets.config:SetResetOnLoginEnabled(value)
        end
    )
end

pockets.settings = settings