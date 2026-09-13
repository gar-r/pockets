local name, pockets = ...

local settings = {}

local function totalGoldName()
    return pockets.strings.settingsTotalGold ..
        ": " .. GetMoneyString(pockets.config:GetTotalGold())
end

function settings:Init()
    self.category, self.layout = Settings.RegisterVerticalLayoutCategory(name)
    Settings.RegisterAddOnCategory(self.category)
    self:addTrackCheckBox()
    self:addTotalGoldLabel()
    self:registerPanelRefresh()
end

function settings:addTrackCheckBox()
    local setting = Settings.RegisterProxySetting(
        self.category,
        "trackEnabled",
        Settings.VarType.Boolean,
        pockets.strings.settingsTrackPickPocket,
        true,
        function() return pockets.config:IsTrackingEnabled() end,
        function(value) pockets.config:SetTrackingEnabled(value) end
    )
    Settings.CreateCheckbox(self.category, setting,
        pockets.strings.settingsTrackPickPocketTooltip)
end

-- The gold total row re-reads the current value whenever it is (re)drawn
function settings:addTotalGoldLabel()
    local initializer = CreateSettingsListSectionHeaderInitializer("")
    local title
    local function refresh()
        if title then
            title:SetTextToFit(totalGoldName())
        end
    end
    local originalInitFrame = initializer.InitFrame
    function initializer:InitFrame(frame)
        self.data.name = totalGoldName()
        originalInitFrame(self, frame)
        title = frame.Title
        refresh()
    end
    initializer:AddShownPredicate(function()
        return pockets.config:IsTrackingEnabled()
    end)
    self.refreshLabel = refresh
    self.layout:AddInitializer(initializer)
end

-- ScrollBox elements are recycled, so the row's InitFrame only runs once;
-- push the current value in whenever the settings panel shows our category.
function settings:registerPanelRefresh()
    EventRegistry:RegisterCallback("Settings.CategoryChanged", function(_, category)
        if category == self.category then
            self.refreshLabel()
        end
    end, self)
    EventRegistry:RegisterFrameEventAndCallback("SETTINGS_PANEL_OPEN", function()
        self.refreshLabel()
    end, self)
end

pockets.settings = settings
