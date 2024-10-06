local drill_utils = require("drill_utils")

local gui = {}


-- Function to create the GUI for the player (including surfaces in dropdown)
function gui.create_gui(player)
    -- Destroy the old GUI if it exists
    if player.gui.top.drill_inspector_frame then
        player.gui.top.drill_inspector_frame.destroy()
    end

    -- Create the main frame with a grey background (proper frame element)
    local main_frame = player.gui.top.add {
        type = "frame",
        direction = "vertical",
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
    surface_dropdown.style.width = 180
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
    local main_frame = player.gui.top.drill_inspector_frame
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

    resource_flow.clear()

    for _, surface in pairs(surfaces_to_check) do
        local resources = drill_utils.get_mined_resources(surface)
        local drill_data = drill_utils.get_drill_data(surface)

        for resource_name, resource_data in pairs(resources) do
            local resource_line = resource_flow.add { type = "flow", direction = "horizontal" }
            local sprite_type = game.item_prototypes[resource_name] and "item" or "entity"
            local sprite = sprite_type .. "/" .. resource_name

            resource_line.add {
                type = "sprite-button",
                sprite = sprite,
                number = resource_data.total_amount,
                tooltip = resource_name .. ": " .. resource_data.total_amount
            }

            if drill_data[resource_name] then
                for drill_type, count in pairs(drill_data[resource_name]) do
                    resource_line.add {
                        type = "sprite-button",
                        sprite = "entity/" .. drill_type,
                        number = count,
                        tooltip = drill_type .. ": " .. count
                    }
                end
            end
        end
    end
end

return gui
