--on_tick.lua

local gui = require("gui.gui")
local drill_manager = require("scripts.drills.drill_manager")

script.on_event(defines.events.on_tick, function(event)
    -- Ensure storage and drills are initialized
    if not storage then
        storage = {}
        drill_manager.initialize_drills()
    elseif not storage.drills then
        game.print("[Drilly Mod] Initializing drills...")
        drill_manager.initialize_drills()
    end

    -- Retry pending drill updates
    if storage.pending_drill_updates then
        for unit_number, data in pairs(storage.pending_drill_updates) do
            local drill_data = storage.drills[unit_number]
            if drill_data and drill_data.entity and drill_data.entity.valid then
                drill_manager.update_drill_data(drill_data)
                -- Stop retrying if the drill status is no longer "no power"
                if drill_data.status ~= defines.entity_status.no_power then
                    storage.pending_drill_updates[unit_number] = nil
                else
                    -- Decrease retry count
                    data.retries = data.retries - 1
                    if data.retries <= 0 then
                        storage.pending_drill_updates[unit_number] = nil
                    end
                end
            else
                -- Remove invalid drills
                storage.pending_drill_updates[unit_number] = nil
            end
        end
    end

    -- Count total drills
    local total_drills = #storage.drill_unit_numbers

    -- Handle case when no drills exist
    if total_drills == 0 then
        return -- Exit early if no drills exist
    end

    -- Refresh-related settings
    local drilly_refresh_enabled = settings.global["drilly-refresh-enabled"].value
    local force_update = storage.force_update

    if not drilly_refresh_enabled and not force_update then
        return -- Skip processing if refresh is disabled and not forced
    end

    -- Force drill processing
    if force_update then
        storage.process_drills = true
    end

    -- Refresh interval (in ticks)
    local refresh_interval_minutes = settings.global["drilly-refresh-interval-minutes"].value or 5
    local refresh_interval_ticks = refresh_interval_minutes * 3600

    -- Trigger refresh at intervals
    if event.tick % refresh_interval_ticks == 0 then
        storage.process_drills = true
    end

    -- Calculate drills per tick for smoother processing
    if not storage.drills_per_tick or event.tick % 3600 == 0 then
        storage.drills_per_tick = math.max(1, math.ceil(total_drills / refresh_interval_ticks))
        local max_drills_per_tick = settings.global["drilly-max-drills-per-tick"].value or 10
        storage.drills_per_tick = math.min(storage.drills_per_tick, max_drills_per_tick)
    end

    -- Store invalid drills for cleanup
    local invalid_drills = {}

    -- Process drills in batches
    if storage.process_drills then
        for i = 1, storage.drills_per_tick do
            local index = storage.drill_processing_index or 1
            if index > total_drills then
                -- End processing loop
                storage.drill_processing_index = 1
                storage.process_drills = false
                storage.force_update = false
                break
            end

            -- Process drill
            local unit_number = storage.drill_unit_numbers[index]
            local drill_data = storage.drills[unit_number]
            if drill_data and drill_data.entity and drill_data.entity.valid then
                drill_manager.update_drill_data(drill_data)
            else
                table.insert(invalid_drills, unit_number)
            end

            storage.drill_processing_index = storage.drill_processing_index + 1
        end
    end

    -- Cleanup invalid drills outside the loop
    for _, unit_number in ipairs(invalid_drills) do
        drill_manager.remove_drill({ unit_number = unit_number })
    end
    if #invalid_drills > 0 then
        drill_manager.initialize_drills()
        total_drills = #storage.drill_unit_numbers
    end

    -- Update UI elements every second
    if event.tick % 60 == 0 then
        for _, player in pairs(game.connected_players) do
            if player.gui.screen.drill_inspector_frame then
                gui.update_progress_bar(player, storage.drill_processing_index - 1, total_drills)
                gui.update_drill_count(player)
            end
        end
    end

    -- Update dropdown every minute or on forced update
    if event.tick % 3600 == 0 or storage.force_update then
        for _, player in pairs(game.connected_players) do
            if player.gui.screen.drill_inspector_frame then
                gui.update_drilly_surface_dropdown(player)
            end
        end
    end
end)
