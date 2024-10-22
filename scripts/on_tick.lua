local gui = require("gui.gui")
local drill_manager = require("scripts.drills.drill_manager")


script.on_event(defines.events.on_tick, function(event)
    if not storage.drills then
        game.print("[Drilly Mod] Warning: storage.minable_entities not initialized at tick time. Initializing now.")
        drill_manager.initialize_drills()
    end

    local total_drills = #storage.drill_unit_numbers
    if total_drills == 0 then
        -- Empty drills list, prompt a full refresh
        drill_manager.initialize_drills()
        total_drills = #storage.drill_unit_numbers
        if total_drills == 0 then
            return -- No drills to process
        end

        storage.process_drills = true
    end

    local drilly_refresh_enabled = settings.global["drilly-refresh-enabled"].value

    local force_update = storage.force_update

    -- Do not run if auto refresh is false
    if not drilly_refresh_enabled and not force_update then
        return
    end

    if force_update then
        storage.process_drills = true
    end

    -- Get the interval in minutes and convert to ticks
    local refresh_interval_minutes = settings.global["drilly-refresh-interval-minutes"].value or
        5    -- Default to 5 minute
    local refresh_interval_ticks = refresh_interval_minutes *
        3600 -- 60 seconds * 60 ticks per second

    if event.tick % refresh_interval_ticks == 0 then
        storage.process_drills = true
    end

    if event.tick % 3600 == 0 or not storage.drills_per_tick then
        storage.drills_per_tick = math.ceil(total_drills / refresh_interval_ticks)

        local max_drills_per_tick = settings.global["drilly-max-drills-per-tick"].value or
            10 -- default to 10 drills per tick
        if (storage.drills_per_tick > max_drills_per_tick) then
            storage.drills_per_tick = max_drills_per_tick
        elseif (storage.drills_per_tick < 1) then
            storage.drills_per_tick = 1
        end
    end

    if storage.process_drills then
        for i = 1, storage.drills_per_tick do
            local index = storage.drill_processing_index or 1
            if index > total_drills then
                storage.drill_processing_index = 1
                index = 1
                storage.force_update = false
                storage.process_drills = false
                break
            end

            local unit_number = storage.drill_unit_numbers[index]
            local drill_data = storage.drills[unit_number]
            if drill_data then
                drill_manager.update_drill_data(drill_data)
            end

            storage.drill_processing_index = storage.drill_processing_index + 1
        end
    end

    -- Update progress bar every second
    if event.tick % 60 == 0 then
        for _, player in pairs(game.connected_players) do
            if storage.force_update or gui.is_progress_bar_enabled(player) then
                if player.gui.screen.drill_inspector_frame then
                    gui.update_progress_bar(player, storage.drill_processing_index - 1, total_drills)
                end
            end
        end
    end

    if event.tick % 60 == 0 then
        for _, player in pairs(game.connected_players) do
            if player.gui.screen.drill_inspector_frame then
                gui.update_drill_count(player)
            end
        end
    end

    if event.tick % 3600 == 0 or storage.force_update then
        for _, player in pairs(game.connected_players) do
            if player.gui.screen.drill_inspector_frame then
                gui.update_drilly_surface_dropdown(player)
            end
        end
    end
end)
