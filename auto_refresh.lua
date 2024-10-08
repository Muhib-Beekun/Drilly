--auto_refresh.lua

local gui = require("gui")

-- Function to automatically update drill count based on global settings
local function auto_refresh_drill_count(event)
    -- Check if global settings for auto-refresh are enabled
    local enable_auto_refresh = settings.global["drilly-enable-auto-refresh"].value

    -- Only proceed if auto-refresh is enabled
    if enable_auto_refresh then
        -- Loop through all connected players and update the drill count
        for _, player in pairs(game.players) do
            if player and player.connected then
                -- Check if the Drilly frame exists for the player
                if player.gui.screen.drill_inspector_frame then
                    -- Trigger the drill count update
                    gui.update_drill_count(player)
                end
            end
        end
    end
end

-- Function to start a recurring event based on the interval from global settings
local function start_auto_refresh()
    -- Remove any existing event to prevent duplicates
    script.on_nth_tick(nil)

    -- Check global settings for auto-refresh interval
    local enable_auto_refresh = settings.global["drilly-enable-auto-refresh"].value
    local interval_in_minutes = settings.global["drilly-auto-refresh-interval"].value

    -- Only set up the auto-refresh if it's enabled
    if enable_auto_refresh and interval_in_minutes then
        local interval_in_ticks = interval_in_minutes * 3600 -- Convert minutes to ticks
        script.on_nth_tick(interval_in_ticks, auto_refresh_drill_count)
        game.print("Drilly auto-refresh set to every " .. interval_in_minutes .. " minute(s).")
    else
        game.print("No valid interval found for auto-refresh or it is disabled.")
    end
end

return {
    start_auto_refresh = start_auto_refresh,
    auto_refresh_drill_count = auto_refresh_drill_count
}
