--gui_events.lua

local gui = require("gui.gui")
local drill_manager = require("scripts.drills.drill_manager")
local alert_manager = require("scripts.alerts.alert_manager")

-- Event handler for GUI hover
script.on_event(defines.events.on_gui_hover, function(event)
    local element = event.element
    if not element then return end
    if not string.find(event.element.name, "^drilly_") then return end
    local player = game.get_player(event.player_index)

    -- Pattern matching with updated separator (hyphen)
    local resource, status, surface, drill_type = string.match(event.element.name,
        "drilly_([^_]+)_([^_]+)_([^_]+)_([^_]+)")
    if resource and status and surface and drill_type then
        local drills = drill_manager.search_drills(resource, status, surface, drill_type)
        for _, drill in ipairs(drills) do
            alert_manager.create_temporary_alert(event.player_index, drill, status)
        end
    else
        player.print("[Drilly Mod] Error: Unable to parse button name correctly.")
    end
end)

-- Event handler for GUI leave
script.on_event(defines.events.on_gui_leave, function(event)
    local element = event.element
    if not element then return end
    if not string.find(event.element.name, "^drilly_") then return end
    local player = game.get_player(event.player_index)

    -- Pattern matching with updated separator (hyphen)
    local resource, status, surface, drill_type = string.match(event.element.name,
        "drilly_([^_]+)_([^_]+)_([^_]+)_([^_]+)")
    if resource and status and surface and drill_type then
        -- Remove temporary alerts based on resource, status, surface
        local player_alerts = storage.temporary_alerts and storage.temporary_alerts[event.player_index]
        if player_alerts then
            for _, drill in pairs(player_alerts) do
                alert_manager.remove_temporary_alert(event.player_index, drill)
            end
        end
    else
        player.print("[Drilly Mod] Error: Unable to parse button name correctly.")
    end
end)

-- Function to handle GUI clicks (for both refresh and close buttons)
script.on_event(defines.events.on_gui_click, function(event)
    local element = event.element
    if not element then return end
    if not string.find(event.element.name, "^drilly_") then return end
    local player = game.get_player(event.player_index)
    if player then
        -- Check if the clicked element is valid
        if event.element and event.element.valid then
            -- Handle refresh button click
            if event.element.name == "drilly_refresh_button" then
                storage.force_update = true
                storage.drill_processing_index = 1

                -- Handle close button click
            elseif event.element.name == "drilly_close_button" then
                if player.gui.screen.drill_inspector_frame then
                    player.gui.screen.drill_inspector_frame.destroy()
                end

                -- Handle the custom Drilly button (top-left button)
            elseif event.element.name == "drilly_button" then
                -- Toggle the Drilly GUI
                if player.gui.screen.drill_inspector_frame then
                    player.gui.screen.drill_inspector_frame.destroy() -- Close the GUI if it's open
                else
                    gui.create_gui(player)                            -- Open the GUI if it's not open
                end
            elseif event.element.name == "drilly_time_toggle_button" then
                local time_periods = { "S", "M", "H", "T" }
                local current_index = player.mod_settings["drilly-current-period-index"].value or 1
                current_index = current_index % #time_periods + 1 -- Cycle through indices
                player.mod_settings["drilly-current-period-index"] = { value = current_index }
                event.element.caption = time_periods[current_index]
                -- Update the GUI
                gui.update_drill_count(player)
            elseif string.find(event.element.name, "^drilly_") then
                local resource, status, surface, drill_type = string.match(event.element.name,
                    "drilly_([^_]+)_([^_]+)_([^_]+)_([^_]+)")
                if not (resource and status and surface and drill_type) then return end

                -- Fetch drills matching the criteria
                local drills = drill_manager.search_drills(resource, status, surface, drill_type)

                storage.player_data[player.index] = storage.player_data[player.index] or {}

                storage.player_data[player.index].drilly_drill_index = storage.player_data[player.index]
                    .drilly_drill_index or {}

                -- Generate a unique key to store the index for this specific drill type
                local key = resource .. "_" .. status .. "_" .. surface .. "_" .. drill_type

                -- If this key doesn't exist, initialize it to 1
                storage.player_data[player.index].drilly_drill_index[key] = storage.player_data[player.index]
                    .drilly_drill_index[key] or 1

                -- Get the current drill index
                local current_drill_index = storage.player_data[player.index].drilly_drill_index[key]

                -- Safety check to ensure the current drill index is within the valid range
                if current_drill_index < 1 or current_drill_index > #drills then
                    current_drill_index = 1 -- Reset to 1 if the index is out of range
                end

                -- Select the drill based on the current index
                local drill = drills[current_drill_index]

                -- Make sure `drill.entity` is a valid entity
                if drill and drill.entity and drill.entity.valid then
                    local entity = drill.entity

                    -- New approach using set_controller for remote view
                    player.set_controller({
                        type = defines.controllers.remote,
                        position = entity.position,
                        surface = entity.surface,
                    })

                    -- Use create_local_flying_text for the specific player
                    player.create_local_flying_text {
                        text = "Drill Here",
                        position = drill.entity.position,
                        color = { r = 1, g = 0.5, b = 0 }
                    }
                else
                    player.print("[Drilly Mod] Warning: Drill entity is invalid or not found.")
                end

                -- Update the index, wrapping back to 1 if we reach the end of the drill list
                if #drills > 0 then
                    storage.player_data[player.index].drilly_drill_index[key] = current_drill_index + 1
                    if storage.player_data[player.index].drilly_drill_index[key] > #drills then
                        storage.player_data[player.index].drilly_drill_index[key] = 1 -- Reset to the first drill when reaching the end
                    end
                end
            end
        end
    end
end)


script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    local element = event.element
    if not element then return end
    if not string.find(event.element.name, "^drilly_") then return end
    local player = game.get_player(event.player_index)

    if element and element.valid and element.name == "drilly_surface_dropdown" then
        gui.update_drill_count(player)
    end
end)
