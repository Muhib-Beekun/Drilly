--gui.lua

local drill_utils = require("drill_utils")

local gui = {}

-- Utility: Format numbers with commas
local function format_number_with_commas(number)
    -- Convert the number to string to analyze its decimal part
    local formatted = tostring(number)

    -- Separate integer and decimal parts (if any)
    local integer_part, decimal_part = string.match(formatted, "(%-?%d+)(%.%d+)")

    -- Check if the number has a decimal part
    if decimal_part then
        -- Check the length of the decimal part (excluding the decimal point)
        local decimal_digits = string.sub(decimal_part, 2)
        if #decimal_digits > 4 then
            -- Round the number to 4 decimal places
            formatted = string.format("%.4f", number)
            -- Update the integer and decimal parts after rounding
            integer_part, decimal_part = string.match(formatted, "(%-?%d+)(%.%d+)")
        end
    else
        -- No decimal part, use the integer part as is
        integer_part = formatted
        decimal_part = ""
    end

    -- Insert commas into the integer part
    local k
    local formatted_int = integer_part
    while true do
        formatted_int, k = string.gsub(formatted_int, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end

    -- Reconstruct the formatted number
    return formatted_int .. (decimal_part or "")
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
    local drilly_surface_dropdown = header_flow.add {
        type = "drop-down",
        name = "drilly_surface_dropdown",
        items = { "By Surface", "Aggregate" },
        selected_index = 1,
        style = "dropdown",
    }
    drilly_surface_dropdown.style.width = 150
    drilly_surface_dropdown.style.height = 30


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
    local drilly_refresh_button = header_flow.add {
        type = "sprite-button",
        name = "drilly_refresh_button",
        sprite = "utility/refresh",
        tooltip = "Refresh",
        style = "green_button"
    }
    drilly_refresh_button.style.width = 30
    drilly_refresh_button.style.height = 30
    drilly_refresh_button.style.padding = 2

    -- Add a close button
    local close_button = header_flow.add {
        type = "sprite-button",
        name = "drilly_close_button",
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

    -- Fetch and display mined resources for the current surface
    gui.update_drill_count(player)
end

-- Function to update the drill count for all resources and drill types
function gui.update_drill_count(player)
    local main_frame = player.gui.screen.drill_inspector_frame
    if not main_frame then
        return
    end

    local header_flow = main_frame.header_flow
    local drilly_surface_dropdown = header_flow.drilly_surface_dropdown
    if not drilly_surface_dropdown then
        main_frame.destroy()
        return
    end

    local selected_option = drilly_surface_dropdown.get_item(drilly_surface_dropdown.selected_index)

    local resource_flow = main_frame.resource_flow
    resource_flow.clear()

    local period_index = player.mod_settings["drilly-current-period-index"].value or 1
    local display_intervals = { "second", "minute", "hour", "total" }
    local display_interval = display_intervals[period_index]
    local time_button = main_frame.header_flow.drilly_time_toggle_button
    time_button.tooltip = "Toggle time period (Current: " .. display_interval .. ")"

    -- Aggregate data from global.drills
    local resource_data = {}

    for _, drill_data in pairs(global.drills) do
        local drill = drill_data.entity
        if not (drill and drill.valid) then
            goto continue
        end

        -- Get the surface index and name
        local surface_index = drill_data.surface_index
        local surface_name = game.surfaces[surface_index].name

        local key = nil -- Key for grouping data

        if selected_option == "By Surface" then
            -- Group by surface
            key = surface_name
        elseif selected_option == "Aggregate" then
            -- Combine data from all surfaces
            key = "Aggregate"
        else
            -- Selected a specific surface
            if surface_name ~= selected_option then
                goto continue -- Skip drills not on the selected surface
            end
            key = surface_name
        end

        if not resource_data[key] then
            resource_data[key] = {}
        end

        for resource_name, res_info in pairs(drill_data.total_resources) do
            if not resource_data[key][resource_name] then
                resource_data[key][resource_name] = {
                    total_amount = 0,
                    drill_data_by_type = {},
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

            resource_data[key][resource_name].total_amount = resource_data[key][resource_name].total_amount + amount

            -- Update drill data by type and status
            local drill_type = drill_data.name
            local status = drill_data.status
            local drill_data_by_type = resource_data[key][resource_name].drill_data_by_type

            if not drill_data_by_type[drill_type] then
                drill_data_by_type[drill_type] = {}
            end
            if not drill_data_by_type[drill_type][status] then
                drill_data_by_type[drill_type][status] = 0
            end

            if display_interval == "total" then
                -- Sum drills
                drill_data_by_type[drill_type][status] = drill_data_by_type[drill_type][status] + 1
            else
                -- Sum yields
                local yield_amount = amount -- Already calculated above
                drill_data_by_type[drill_type][status] = drill_data_by_type[drill_type][status] + yield_amount
            end
        end

        ::continue::
    end

    -- Build the GUI elements
    for key, resources in pairs(resource_data) do
        if selected_option == "By Surface" then
            -- Add a label for the surface name
            resource_flow.add { type = "label", caption = "Surface: " .. key, style = "heading_2_label" }
        end

        for resource_name, data in pairs(resources) do
            local resource_line = resource_flow.add { type = "flow", direction = "horizontal" }
            local sprite_type = game.item_prototypes[resource_name] and "item" or "entity"
            local sprite = sprite_type .. "/" .. resource_name

            -- Format the total amount
            local amount_number = tonumber(string.format("%.4f", data.total_amount))
            local formatted_amount = format_number_with_commas(amount_number)

            -- Add the resource button
            resource_line.add {
                type = "sprite-button",
                sprite = sprite,
                number = amount_number,
                tooltip = resource_name .. ": " .. formatted_amount .. (display_interval == "total" and "\nProductivity Bonus Applied" or " per " .. display_interval),
                style = "slot_button"
            }

            -- Add drill buttons
            for drill_type, statuses in pairs(data.drill_data_by_type) do
                for status, value in pairs(statuses) do
                    local status_style = get_status_style(status)
                    local status_name = get_status_name(status)

                    local display_value = tonumber(string.format("%.4f", value))
                    local formatted_value = format_number_with_commas(display_value)
                    local tooltip_suffix = display_interval == "total" and "" or " per " .. display_interval

                    local button_name = string.format("drilly_%s_%s_%s_%s", resource_name, status, key, drill_type)

                    resource_line.add {
                        type = "sprite-button",
                        raise_hover_events = true,
                        name = button_name,
                        sprite = "entity/" .. drill_type,
                        number = display_value,
                        tooltip = drill_type .. " (" .. status_name .. "): " .. formatted_value .. tooltip_suffix,
                        style = status_style,
                    }
                end
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

    if not progress_bar and global.force_update then
        progress_bar = progress_flow.add {
            type = "progressbar",
            name = "drill_progress_bar",
            value = 0
        }
        progress_bar.style.horizontally_stretchable = true
        progress_bar.style.width = 200
    end

    if not progress_label and global.force_update then
        progress_label = progress_flow.add {
            type = "label",
            name = "drill_progress_label",
            caption = "0/0"
        }
        progress_label.style.left_margin = 10
    end

    if progress_label and not global.force_update then
        progress_label.destroy()
    end

    if progress_bar and not global.force_update then
        progress_bar.destroy()
    end

    if not global.force_update then
        return
    end


    if progress_bar and progress_label then
        local progress = current_index / total_drills
        progress_bar.value = progress
        progress_label.caption = string.format("%d/%d", current_index, total_drills)
    end
end

function gui.update_drilly_surface_dropdown(player)
    local main_frame = player.gui.screen.drill_inspector_frame
    if not main_frame then
        return
    end
    local header_flow = main_frame.header_flow
    local drilly_surface_dropdown = header_flow.drilly_surface_dropdown
    if not drilly_surface_dropdown then
        player.print("[Drilly Mod] Error: Drilly surface dropdown not found.")
        return
    end

    -- Get the player's current surface name
    local player_surface_name = player.surface.name

    -- Build the set of surfaces with drills
    local surfaces_with_drills = {}
    for _, drill_data in pairs(global.drills) do
        local surface_index = drill_data.surface_index
        local surface = game.surfaces[surface_index]
        if surface then
            surfaces_with_drills[surface.name] = true
        end
    end

    -- Always include the player's current surface, even if it has no drills
    surfaces_with_drills[player_surface_name] = true

    -- Build the desired list of items
    local desired_items = { "By Surface", "Aggregate" }

    -- Collect and sort surface names
    local surface_names = {}
    for surface_name in pairs(surfaces_with_drills) do
        table.insert(surface_names, surface_name)
    end
    table.sort(surface_names)

    -- Append surface names to the desired items
    for _, surface_name in ipairs(surface_names) do
        table.insert(desired_items, surface_name)
    end

    -- Get the current items in the dropdown
    local current_items = drilly_surface_dropdown.items

    -- Build a map of current items for quick lookup
    local current_items_map = {}
    for index, item in ipairs(current_items) do
        current_items_map[item] = index
    end

    -- Build a map of desired items for quick lookup
    local desired_items_map = {}
    for index, item in ipairs(desired_items) do
        desired_items_map[item] = index
    end

    -- Add new surfaces to the dropdown
    for index, item in ipairs(desired_items) do
        if not current_items_map[item] then
            -- Item is not in the current dropdown, add it at the correct index
            drilly_surface_dropdown.add_item(item, index)
            current_items_map[item] = index
        end
    end

    -- Remove surfaces that are no longer needed
    -- Iterate from the end to avoid index shifting
    for index = #current_items, 1, -1 do
        local item = current_items[index]
        if not desired_items_map[item] and item ~= "By Surface" and item ~= "Aggregate" then
            -- Remove the item
            drilly_surface_dropdown.remove_item(index)
            current_items_map[item] = nil
        end
    end

    -- Ensure the order of items matches the desired order
    for desired_index, desired_item in ipairs(desired_items) do
        local current_item = drilly_surface_dropdown.get_item(desired_index)
        if current_item ~= desired_item then
            -- Update the item at this index
            drilly_surface_dropdown.set_item(desired_index, desired_item)
        end
    end

    -- Update the selected index if necessary
    local selected_index = drilly_surface_dropdown.selected_index
    local selected_item = drilly_surface_dropdown.get_item(selected_index)

    if not desired_items_map[selected_item] then
        -- Selected item has been removed, set selection to "By Surface"
        for index, item in ipairs(drilly_surface_dropdown.items) do
            if item == "By Surface" then
                drilly_surface_dropdown.selected_index = index
                break
            end
        end
    end
end

return gui
