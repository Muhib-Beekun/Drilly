local drill_utils = require("drill_utils")

local gui = {}

-- Function to create the GUI for the player
function gui.create_gui(player)
    -- Destroy the old GUI if it exists
    if player.gui.top.drill_inspector_frame then
        player.gui.top.drill_inspector_frame.destroy()
    end

    -- Create the main frame with a grey background (proper frame element)
    local main_frame = player.gui.top.add{
        type = "frame", 
        direction = "vertical", 
        name = "drill_inspector_frame", 
        caption = "Drilly"
    }

    -- Create a flow for the header (dropdown and refresh icon)
    local header_flow = main_frame.add{type = "flow", direction = "horizontal"}

    -- Add surface dropdown with an "All" option and default to the current surface
    local surface_dropdown = header_flow.add{
        type = "drop-down", 
        name = "surface_dropdown", 
        items = {"All"}, 
        selected_index = 1,
        style = "dropdown",  -- Using the default dropdown style
    }
    surface_dropdown.style.width = 180  -- Set a custom width for the dropdown

    -- Add a green refresh icon button next to the dropdown and set its width smaller
    local refresh_button = header_flow.add{
        type = "sprite-button", 
        name = "refresh_button", 
        sprite = "utility/refresh", 
        tooltip = "Refresh", 
        style = "green_button"  -- Use the predefined green button style
    }
    refresh_button.style.width = 30  -- Set a smaller width for the refresh button
    refresh_button.style.height = 30  -- Set height to keep the proportions
    refresh_button.style.padding = 2  -- Adjust padding to make the icon stay large

    -- Create a vertical layout for the resource table within the frame
    local resource_flow = main_frame.add{type = "flow", direction = "vertical"}

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

    local header_flow = main_frame.children[1] -- Header is the first child
    local surface_dropdown = header_flow.children[1] -- Dropdown is the first child now
    local selected_surface_name = surface_dropdown.get_item(surface_dropdown.selected_index)

    local resource_flow = main_frame.children[2] -- Resource flow is the second item after the header

    -- Determine the surface(s) to inspect
    local surfaces_to_check = {}
    if selected_surface_name == "All" then
        for _, surface in pairs(game.surfaces) do
            table.insert(surfaces_to_check, surface)
        end
    else
        table.insert(surfaces_to_check, game.surfaces[selected_surface_name])
    end

    -- Clear the flow and rebuild it with updated data
    resource_flow.clear()

    for _, surface in pairs(surfaces_to_check) do
        -- Fetch updated resource and drill data for each surface
        local resources = drill_utils.get_mined_resources(surface)
        local drill_data = drill_utils.get_drill_data(surface)

        for resource_name, resource_data in pairs(resources) do
            -- Determine if the resource is an item or entity, then set the sprite type
            local sprite_type = game.item_prototypes[resource_name] and "item" or "entity"
            local sprite = sprite_type .. "/" .. resource_name

            -- Add resource sprite with the amount and set tooltip
            resource_flow.add{
                type = "sprite-button",
                sprite = sprite,
                number = resource_data.total_amount,
                tooltip = resource_name .. ": " .. resource_data.total_amount  -- Tooltip with resource name and count
            }

            -- Add drill sprites for each drill type mining this resource and set tooltips
            if drill_data[resource_name] then
                for drill_type, count in pairs(drill_data[resource_name]) do
                    resource_flow.add{
                        type = "sprite-button",
                        sprite = "entity/" .. drill_type,
                        number = count,
                        tooltip = drill_type .. ": " .. count  -- Tooltip with drill type and count
                    }
                end
            end
        end
    end
end

return gui
