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
    local header_flow = main_frame.add {
        type = "flow",
        direction = "horizontal",
        name = "header_flow"
    }

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
    local resource_flow = main_frame.add {
        type = "scroll-pane",
        direction = "vertical",
        name = "resource_flow",
        vertical_scroll_policy = "auto"
    }

    resource_flow.style.maximal_height = 600

    local progress_flow = main_frame.add {
        type = "flow",
        direction = "horizontal",
        name = "progress_flow"
    }
    progress_flow.style.vertical_align = "center"

    local progress_bar = progress_flow.add {
        type = "progressbar",
        name = "drill_progress_bar",
        value = 0
    }
    progress_bar.style.horizontally_stretchable = true
    progress_bar.style.width = 200

    local progress_label = progress_flow.add {
        type = "label",
        name = "drill_progress_label",
        caption = "0/0"
    }
    progress_label.style.left_margin = 10

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

    local header_flow = main_frame.header_flow
    local surface_dropdown = header_flow.surface_dropdown
    local selected_surface_name = surface_dropdown.get_item(surface_dropdown.selected_index)

    local resource_flow = main_frame.resource_flow
    resource_flow.clear()

    local period_index = player.mod_settings["drilly-current-period-index"].value or 1
    local display_intervals = { "second", "minute", "hour", "total" }
    local display_interval = display_intervals[period_index]
    local time_button = main_frame.header_flow.drilly_time_toggle_button
    time_button.tooltip = "Toggle time period (Current: " .. display_interval .. ")"


    local surfaces_to_check = {}
    if selected_surface_name == "All" then
        for _, surface in pairs(game.surfaces) do
            surfaces_to_check[surface.index] = true
        end
    else
        local surface = game.surfaces[selected_surface_name]
        if surface then
            surfaces_to_check[surface.index] = true
        end
    end

    -- Aggregate data from global.drills
    local resource_data = {}

    for _, drill_data in pairs(global.drills) do
        local drill = drill_data.entity
        if not (drill and drill.valid) then
            goto continue
        end

        if not surfaces_to_check[drill_data.surface_index] then
            goto continue
        end

        for resource_name, res_info in pairs(drill_data.total_resources) do
            if not resource_data[resource_name] then
                resource_data[resource_name] = {
                    total_amount = 0,
                    drill_counts = {},
                }
            end

            -- Calculate amount based on display interval
            local amount = 0
            if display_interval == "second" then
                amount = res_info.yield_per_second
            elseif display_interval == "minute" then
                amount = res_info.yield_per_second * 60
            elseif display_interval == "hour" then
                amount = res_info.yield_per_second * 3600
            elseif display_interval == "total" then
                amount = res_info.amount
            end

            resource_data[resource_name].total_amount = resource_data[resource_name].total_amount + amount

            -- Update drill counts
            local drill_type = drill_data.name
            local status = drill_data.status
            if not resource_data[resource_name].drill_counts[drill_type] then
                resource_data[resource_name].drill_counts[drill_type] = {}
            end
            if not resource_data[resource_name].drill_counts[drill_type][status] then
                resource_data[resource_name].drill_counts[drill_type][status] = 0
            end
            resource_data[resource_name].drill_counts[drill_type][status] = resource_data[resource_name].drill_counts
                [drill_type][status] + 1
        end

        ::continue::
    end

    -- Build the GUI elements
    for resource_name, data in pairs(resource_data) do
        local resource_line = resource_flow.add { type = "flow", direction = "horizontal" }
        local sprite_type = game.item_prototypes[resource_name] and "item" or "entity"
        local sprite = sprite_type .. "/" .. resource_name

        if display_interval == "total" then
            resource_line.add {
                type = "sprite-button",
                sprite = sprite,
                number = data.total_amount,
                tooltip = resource_name .. ": " .. format_number_with_commas(data.total_amount),
                style = "slot_button"
            }
        else
            local amount_number = tonumber(string.format("%.1f", data.total_amount))
            resource_line.add {
                type = "sprite-button",
                sprite = sprite,
                number = amount_number,
                tooltip = resource_name .. ": " .. format_number_with_commas(data.total_amount),
                style = "slot_button"
            }
        end

        -- Add drill buttons
        for drill_type, statuses in pairs(data.drill_counts) do
            for status, count in pairs(statuses) do
                local status_style = get_status_style(status)
                local status_name = get_status_name(status)

                resource_line.add {
                    type = "sprite-button",
                    sprite = "entity/" .. drill_type,
                    number = count,
                    tooltip = drill_type .. " (" .. status_name .. "): " .. count,
                    style = status_style,
                    -- Optionally include drill positions or other tags
                }
            end
        end
    end
end

-- Function to update the progress bar
function gui.update_progress_bar(player, current_index, total_drills)
    local main_frame = player.gui.screen.drill_inspector_frame
    if not main_frame then
        return
    end

    local progress_flow = main_frame.progress_flow
    if not progress_flow then
        return
    end

    local progress_bar = progress_flow.drill_progress_bar
    local progress_label = progress_flow.drill_progress_label

    if progress_bar and progress_label then
        local progress = current_index / total_drills
        progress_bar.value = progress
        progress_label.caption = string.format("%d/%d", current_index, total_drills)
    end
end

return gui
