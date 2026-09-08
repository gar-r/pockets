local _, pockets = ...

function Pockets_OnAddonCompartmentClick()
    if pockets and pockets.settings and pockets.settings.category then
        Settings.OpenToCategory(pockets.settings.category.ID)
    end
end
