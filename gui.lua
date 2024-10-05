local drill_utils = require("drill_utils")

local gui = {}

-- Function to create the GUI for the player
function gui.create_gui(player)
    -- Destroy the old GUI if it exists
    if player.gui.top.drill_inspector_frame then
        player.gui.top.drill_inspector_frame.destroy()
    end

    -- Create the main frame
    local frame = player.gui.top.add{type = "frame", name = "drill_inspector_frame", caption = "Drill Inspector"}
    
    -- Create a vertical layout by using a flow
    local resource_flow = frame.add{type = "flow", direction = "vertical"}

    -- Add refresh button at the top
    frame.add{type = "button", name = "refresh_button", caption = "Refresh"}

    -- Fetch all resources and drill data to display in the GUI
    local resources = drill_utils.get_mined_resources(player.surface)
    local drill_data = drill_utils.get_drill_data(player.surface)

    -- Ensure resources and drill_data are not nil
    if not resources then
        player.print("Error: No resources found.")
        return
    end
    if not drill_data then
        player.print("Error: No drill data found.")
        return
    end

    -- Loop through each resource and add its sprite and drill counts to the flow
    for resource_name, resource_data in pairs(resources) do
        -- Determine if the resource is an item or entity, then set the sprite type
        local sprite_type = game.item_prototypes[resource_name] and "item" or "entity"
        local sprite = sprite_type .. "/" .. resource_name

        -- Add resource sprite with the amount
        resource_flow.add{
            type = "sprite-button",
            sprite = sprite,  -- Display the resource image (entity or item)
            number = resource_data.total_amount  -- Add number to indicate total amount
        }

        -- Add drill sprites for each drill type mining this resource
        if drill_data[resource_name] then
            for drill_type, count in pairs(drill_data[resource_name]) do
                resource_flow.add{
                    type = "sprite-button",
                    sprite = "entity/" .. drill_type,  -- Display the dynamic drill image
                    number = count  -- Display the number of drills mining this resource
                }
            end
        end

        -- Optionally add a label for resource type and drill count
        resource_flow.add{
            type = "label",
            caption = resource_name .. " being mined by drills of different types"
        }
    end

    -- Debugging: Print confirmation of GUI creation
    player.print("Drill Inspector GUI created.")
end

-- Function to update the drill count for all resources and drill types
function gui.update_drill_count(player)
    local frame = player.gui.top.drill_inspector_frame
    if not frame then
        player.print("Error: Drill inspector frame not found.")
        return
    end

    local resource_flow = frame.children[1]

    -- Fetch updated resource and drill data
    local resources = drill_utils.get_mined_resources(player.surface)
    local drill_data = drill_utils.get_drill_data(player.surface)

    -- Ensure resources and drill_data are not nil
    if not resources then
        player.print("Error: No resources found.")
        return
    end
    if not drill_data then
        player.print("Error: No drill data found.")
        return
    end

    -- Clear the flow and rebuild it with updated data
    resource_flow.clear()

    for resource_name, resource_data in pairs(resources) do
        -- Determine if the resource is an item or entity, then set the sprite type
        local sprite_type = game.item_prototypes[resource_name] and "item" or "entity"
        local sprite = sprite_type .. "/" .. resource_name

        -- Update resource sprite with amount
        resource_flow.add{
            type = "sprite-button",
            sprite = sprite,
            number = resource_data.total_amount
        }

        -- Update drill sprites with drill type and drill count
        if drill_data[resource_name] then
            for drill_type, count in pairs(drill_data[resource_name]) do
                resource_flow.add{
                    type = "sprite-button",
                    sprite = "entity/" .. drill_type,
                    number = count
                }
            end
        end

        -- Optionally add a label for resource and drill count
        resource_flow.add{
            type = "label",
            caption = resource_name .. " being mined by drills of different types"
        }
    end
end

return gui
