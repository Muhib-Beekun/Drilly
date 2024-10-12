local drill_utils = require("drill_utils")
local gui = require("gui.gui")

script.on_event(defines.events.on_tick, function(event)
    if not global.drills then
        game.print("[Drilly Mod] Warning: global.minable_entities not initialized at tick time. Initializing now.")
        drill_utils.initialize_drills()
    end

    local total_drills = #global.drill_unit_numbers
    if total_drills == 0 then
        -- Empty drills list, prompt a full refresh
        drill_utils.initialize_drills()
        total_drills = #global.drill_unit_numbers
        if total_drills == 0 then
            return -- No drills to process
        end
    end

    local drilly_refresh_enabled = settings.global["drilly-refresh-enabled"].value

    local force_update = global.force_update

    -- Do not run if auto refresh is false
    if not drilly_refresh_enabled and not force_update then
        return
    end

    -- Get the interval in minutes and convert to ticks
    local refresh_interval_minutes = settings.global["drilly-refresh-interval-minutes"].value or
        5    -- Default to 5 minute
    local refresh_interval_ticks = refresh_interval_minutes *
        3600 -- 60 seconds * 60 ticks per second

    local drills_per_tick = math.ceil(total_drills / refresh_interval_ticks)
    global.drills_per_tick = drills_per_tick

    for i = 1, drills_per_tick do
        local index = global.drill_processing_index or 1
        if index > total_drills then
            global.drill_processing_index = 1
            index = 1
            global.force_update = false
        end

        local unit_number = global.drill_unit_numbers[index]
        local drill_data = global.drills[unit_number]
        if drill_data then
            drill_utils.update_drill_data(drill_data)
        end

        global.drill_processing_index = global.drill_processing_index + 1
    end

    -- Update progress bar every second
    if event.tick % 60 == 0 then
        for _, player in pairs(game.connected_players) do
            if player.gui.screen.drill_inspector_frame then
                gui.update_drill_count(player)
                gui.update_surface_dropdown(player)
                gui.update_progress_bar(player, global.drill_processing_index - 1, total_drills)
            end
        end
    end
end)
