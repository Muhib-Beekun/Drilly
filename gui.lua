--gui.lua

local drill_utils = require("drill_utils")

local gui = {}

-- Utility: Format numbers with commas
local function format_number_with_commas(number)
    local formatted = tostring(number)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Function to get the status name from the status value
local function get_status_name(status_value)
    for name, value in pairs(defines.entity_status) do
        if value == status_value then
            return name
        end
    end
    return "Unknown status"
end

-- Function to map drill status to a style (color)
local function get_status_style(status_value)
    if status_value == defines.entity_status.working then
        return "drilly_green_slot_button"
    elseif status_value == defines.entity_status.waiting_for_space_in_destination or
        status_value == defines.entity_status.low_input_fluid then
        return "drilly_yellow_slot_button"
    elseif status_value == defines.entity_status.no_power or
        status_value == defines.entity_status.no_minable_resources or
        status_value == defines.entity_status.missing_required_fluid or
        status_value == defines.entity_status.no_fuel then
        return "drilly_red_slot_button"
    else
        return "slot_button" -- Default style (grey)
    end
end

-- Function to create the GUI for the player (including surfaces in dropdown)
function gui.create_gui(player)
    -- Destroy the old GUI if it exists
    if player.gui.screen.drill_inspector_frame then
        player.gui.screen.drill_inspector_frame.destroy()
    end

    -- Create the main frame
    local main_frame = player.gui.screen.add {
        type = "frame",
        direction = "vertical", -- Vertical stacking to reduce horizontal space
        name = "drill_inspector_frame",
        caption = "Drilly"
    }

    -- Create a flow for the header (dropdown, refresh icon, and close button)
    local header_flow = main_frame.add { type = "flow", direction = "horizontal" }

    -- Add surface dropdown with an "All" option and default to the current surface
    local surface_dropdown = header_flow.add {
        type = "drop-down",
        name = "surface_dropdown",
        items = { "All" },
        selected_index = 1,
        style = "dropdown",
    }
    surface_dropdown.style.width = 150
    surface_dropdown.style.height = 30

    -- Add all available surfaces to the dropdown
    local index_counter = 2
    for _, surface in pairs(game.surfaces) do
        surface_dropdown.add_item(surface.name)
        if surface.name == player.surface.name then
            surface_dropdown.selected_index = index_counter -- Select the current surface by default
        end
        index_counter = index_counter + 1
    end

    -- Add time period toggle button
    local time_periods = { "S", "M", "H", "T" }
    local current_period_index = player.mod_settings["drilly-current-period-index"].value or 1
    local time_button = header_flow.add {
        type = "sprite-button",
        name = "drilly_time_toggle_button",
        caption = time_periods[current_period_index],
        tooltip = "Toggle time period",
        style = "button"
    }
    time_button.style.width = 30
    time_button.style.height = 30
    time_button.style.padding = -10


    -- Add a green refresh icon button next to the dropdown
    local refresh_button = header_flow.add {
        type = "sprite-button",
        name = "refresh_button",
        sprite = "utility/refresh",
        tooltip = "Refresh",
        style = "green_button"
    }
    refresh_button.style.width = 30
    refresh_button.style.height = 30
    refresh_button.style.padding = 2

    -- Add a close button
    local close_button = header_flow.add {
        type = "sprite-button",
        name = "drill_close_button",
        sprite = "utility/close_fat", -- Close button to hide Drilly
        tooltip = "Close Drilly",
        style = "red_button"
    }
    close_button.style.width = 30
    close_button.style.height = 30
    close_button.style.padding = -5

    -- Create a vertical layout for the resource table within the frame
    local resource_flow = main_frame.add { type = "flow", direction = "vertical" }

    -- Fetch and display mined resources for the current surface
    gui.update_drill_count(player)
end

-- Function to update the drill count for all resources and drill types
function gui.update_drill_count(player)
    local main_frame = player.gui.screen.drill_inspector_frame
    if not main_frame then
        player.print("Error: Drilly frame not found.")
        return
    end

    local header_flow = main_frame.children[1]
    local surface_dropdown = header_flow.children[1]
    local selected_surface_name = surface_dropdown.get_item(surface_dropdown.selected_index)

    local resource_flow = main_frame.children[2]
    local surfaces_to_check = {}

    if selected_surface_name == "All" then
        for _, surface in pairs(game.surfaces) do
            table.insert(surfaces_to_check, surface)
        end
    else
        table.insert(surfaces_to_check, game.surfaces[selected_surface_name])
    end

    -- Get user-selected display interval (seconds/minutes/total)
    -- local display_interval = player.mod_settings["drilly-resource-interval"].value

    local period_index = player.mod_settings["drilly-current-period-index"].value or 1
    local display_intervals = { "second", "minute", "hour", "total" }
    player.print(display_intervals[period_index])
    local display_interval = display_intervals[period_index]


    resource_flow.clear()

    for _, surface in pairs(surfaces_to_check) do
        local resources = drill_utils.get_mined_resources(surface, display_interval, player)
        local drill_data = drill_utils.get_drill_data(surface, player)

        for resource_name, resource_data in pairs(resources) do
            local resource_line = resource_flow.add { type = "flow", direction = "horizontal" }
            local sprite_type = game.item_prototypes[resource_name] and "item" or "entity"
            local sprite = sprite_type .. "/" .. resource_name

            resource_line.add {
                type = "sprite-button",
                sprite = sprite,
                number = string.format("%.1f", resource_data.total_amount), -- Show the extraction rate or total
                tooltip = resource_name .. ": " .. format_number_with_commas(resource_data.total_amount) ..
                    (display_interval == "minute" and " units/min" or (display_interval == "second" and " units/s" or " total units"))
            }

            if drill_data[resource_name] then
                for drill_type, status_counts in pairs(drill_data[resource_name]) do
                    for drill_status, count in pairs(status_counts) do
                        local status_style = get_status_style(drill_status)
                        local status_name = get_status_name(drill_status)

                        resource_line.add {
                            type = "sprite-button",
                            sprite = "entity/" .. drill_type,
                            number = count,
                            tooltip = drill_type .. " (" .. status_name .. "): " .. count,
                            style = status_style
                        }
                    end
                end
            end
        end
    end
end

return gui
