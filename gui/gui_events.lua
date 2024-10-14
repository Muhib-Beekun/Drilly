--gui_events.lua

local gui = require("gui.gui")
local drill_utils = require("drill_utils")

-- Event handler for GUI hover
script.on_event(defines.events.on_gui_hover, function(event)
    local player = game.get_player(event.player_index)
    local element = event.element
    if not element then return end

    -- Pattern matching with updated separator (hyphen)
    local resource, status, surface, drill_type = string.match(event.element.name,
        "drilly_([^_]+)_([^_]+)_([^_]+)_([^_]+)")
    if resource and status and surface and drill_type then
        local drills = drill_utils.search_drills(resource, status, surface, drill_type)
        for _, drill in ipairs(drills) do
            drill_utils.create_temporary_alert(event.player_index, drill)
        end
    else
        player.print("[Drilly Mod] Error: Unable to parse button name correctly.")
    end
end)

-- Event handler for GUI leave
script.on_event(defines.events.on_gui_leave, function(event)
    local player = game.get_player(event.player_index)
    local element = event.element
    if not element then return end

    -- Pattern matching with updated separator (hyphen)
    local resource, status, surface, drill_type = string.match(event.element.name,
        "drilly_([^_]+)_([^_]+)_([^_]+)_([^_]+)")
    if resource and status and surface and drill_type then
        -- Remove temporary alerts based on resource, status, surface
        local player_alerts = global.temporary_alerts and global.temporary_alerts[event.player_index]
        if player_alerts then
            for _, drill in pairs(player_alerts) do
                drill_utils.remove_temporary_alert(event.player_index, drill)
            end
        end
    else
        player.print("[Drilly Mod] Error: Unable to parse button name correctly.")
    end
end)

-- Function to handle GUI clicks (for both refresh and close buttons)
script.on_event(defines.events.on_gui_click, function(event)
    local player = game.get_player(event.player_index)
    if player then
        -- Check if the clicked element is valid
        if event.element and event.element.valid then
            -- Handle refresh button click
            if event.element.name == "refresh_button" then
                global.force_update = true
                global.drill_processing_index = 1

                -- Handle close button click
            elseif event.element.name == "drill_close_button" then
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
                local drills = drill_utils.search_drills(resource, status, surface, drill_type)

                global.player_data[player.index] = global.player_data[player.index] or {}

                global.player_data[player.index].drilly_drill_index = global.player_data[player.index]
                    .drilly_drill_index or {}

                -- Generate a unique key to store the index for this specific drill type
                local key = resource .. "_" .. status .. "_" .. surface .. "_" .. drill_type

                -- If this key doesn't exist, initialize it to 1
                global.player_data[player.index].drilly_drill_index[key] = global.player_data[player.index]
                    .drilly_drill_index[key] or 1

                -- Get the current drill index
                local current_drill_index = global.player_data[player.index].drilly_drill_index[key]

                -- Safety check to ensure the current drill index is within the valid range
                if current_drill_index < 1 or current_drill_index > #drills then
                    current_drill_index = 1 -- Reset to 1 if the index is out of range
                end

                -- Select the drill based on the current index
                local drill = drills[current_drill_index]

                -- Make sure `drill.entity` is a valid entity
                if drill and drill.entity and drill.entity.valid then
                    local entity = drill.entity
                    local player_surface = player.surface.name

                    if script.active_mods["space-exploration"] and not (player_surface == surface) then
                        remote.call("space-exploration", "remote_view_start",
                            {
                                player = player,
                                zone_name = surface,
                                position = drill.entity.position,
                                location_name =
                                "Point of Interest",
                                freeze_history = true
                            })
                    end


                    player.zoom_to_world(entity.position, 0.5)

                    entity.surface.create_entity {
                        name = "flying-text",
                        position = drill.entity.position,
                        text = "Drill Here",
                        color = { r = 1, g = 0.5, b = 0 }
                    }
                else
                    player.print("[Drilly Mod] Warning: Drill entity is invalid or not found.")
                end

                -- Update the index, wrapping back to 1 if we reach the end of the drill list
                if #drills > 0 then
                    global.player_data[player.index].drilly_drill_index[key] = current_drill_index + 1
                    if global.player_data[player.index].drilly_drill_index[key] > #drills then
                        global.player_data[player.index].drilly_drill_index[key] = 1 -- Reset to the first drill when reaching the end
                    end
                end
            end
        end
    end
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    local element = event.element
    local player = game.get_player(event.player_index)

    if element and element.valid and element.name == "surface_dropdown" then
        gui.update_drill_count(player)
    end
end)
