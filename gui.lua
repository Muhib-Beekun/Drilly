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
    local dropdown_flow = frame.add{type = "flow", direction = "horizontal"}

    -- Add surface dropdown with an explicit name
    local surface_dropdown = dropdown_flow.add{type = "drop-down", name = "surface_dropdown", items = {}}
    for _, surface in pairs(game.surfaces) do
        surface_dropdown.add_item(surface.name)
    end

    -- Add resource type dropdown with an explicit name
    local resource_dropdown = dropdown_flow.add{type = "drop-down", name = "resource_dropdown", items = {}}
    for _, resource in pairs(game.entity_prototypes) do
        if resource.type == "resource" then
            resource_dropdown.add_item(resource.name)
        end
    end

    -- Add a refresh button
    frame.add{type = "button", name = "refresh_button", caption = "Refresh"}

    -- Add a label to display the count
    frame.add{type = "label", name = "drill_count_label", caption = "Drills mining: 0"}

    player.print("Drill Inspector GUI created.")
end

-- Function to update the drill count for the selected resource and surface
function gui.update_drill_count(player)
    local frame = player.gui.top.drill_inspector_frame
    if not frame then
        player.print("Error: Drill inspector frame not found.")
        return
    end

    local dropdown_flow = frame.children[1]
    local surface_dropdown = dropdown_flow.children[1]
    local resource_dropdown = dropdown_flow.children[2]

    local surface_name = surface_dropdown.get_item(surface_dropdown.selected_index)
    local resource_name = resource_dropdown.get_item(resource_dropdown.selected_index)

    if not surface_name or not resource_name then
        player.print("Please select a surface and resource.")
        return
    end

    local drill_count = drill_utils.count_drills_on_surface(game.surfaces[surface_name], resource_name)
    frame.drill_count_label.caption = "Drills mining: " .. drill_count
end

return gui
