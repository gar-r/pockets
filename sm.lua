local _, pockets = ...

local PICK_POCKET = 921
local AMBUSH = 8676

local STATE_PICK_POCKET = 1
local STATE_LOOTING = 2
local STATE_OPENER = 3

local transitions = {
    UNIT_SPELLCAST_SUCCEEDED = { STATE_LOOTING, STATE_OPENER, nil },
    UNIT_SPELLCAST_FAILED = { STATE_OPENER, STATE_OPENER, nil },
    UNIT_SPELLCAST_FAILED_QUIET = { STATE_OPENER, STATE_OPENER, nil },
    PLAYER_REGEN_ENABLED = { nil, nil, STATE_PICK_POCKET },
    PLAYER_REGEN_DISABLED = { STATE_OPENER, STATE_OPENER, nil },
    PLAYER_TARGET_CHANGED = { nil, STATE_PICK_POCKET, STATE_PICK_POCKET },
    LOOT_CLOSED = { nil, STATE_OPENER, nil },
}

local sm = {
    frame = CreateFrame("Frame"),
    state = STATE_PICK_POCKET,
}

function sm:Init()
    for e in pairs(transitions) do
        self.frame:RegisterEvent(e)
    end
    self.frame:SetScript("OnEvent", function(_, event, ...)
        if transitions[event] then
            local next = transitions[event][sm.state]
            if next then
                if not self[event]
                    or self[event] and self[event](self, ...) then
                    self.state = next
                    print("state changed: " .. next)
                end
            end
        end
    end)
end

function sm:UNIT_SPELLCAST_SUCCEEDED(unit, _, spellId)
    if unit == "player" and spellId == PICK_POCKET then
        return true -- only transition when the player casts pick pocket
    end
end

pockets.sm = sm
