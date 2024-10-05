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

-- Function: Highlight the drill's mining area
local function highlight_mining_area(drill, mining_radius, player)
    local bounding_box = {
        left_top = {x = drill.position.x - mining_radius, y = drill.position.y - mining_radius},
        right_bottom = {x = drill.position.x + mining_radius, y = drill.position.y + mining_radius}
    }

    -- Create a highlight box for the mining area
    player.surface.create_entity{
        name = "highlight-box",
        bounding_box = bounding_box,
        position = drill.position,
        box_type = "electricity",
        time_to_live = 180,
        render_player_index = player.index
    }

    -- Create flying text to mark the drill's location
    player.surface.create_entity{
        name = "flying-text",
        position = drill.position,
        text = "Drill Here",
        color = {r = 1, g = 0.5, b = 0}
    }

    return bounding_box
end

-- Function: Summarize resources in the mining area
local function summarize_resources(drill, bounding_box, player)
    local resources = drill.surface.find_entities_filtered{
        area = bounding_box,
        type = "resource"
    }

    local resource_summary = {}

    -- Accumulate resources found in the bounding box
    for _, resource in pairs(resources) do
        if resource_summary[resource.name] then
            resource_summary[resource.name].amount = resource_summary[resource.name].amount + resource.amount
            resource_summary[resource.name].drills[drill.unit_number] = true
        else
            resource_summary[resource.name] = {amount = resource.amount, drills = {[drill.unit_number] = true}}
        end
    end

    -- Print the summary of resources found
    if next(resource_summary) then
        player.print("Resources within the drill's mining area:")
        for resource_name, data in pairs(resource_summary) do
            player.print(resource_name .. ": " .. format_number_with_commas(data.amount) .. " units")
        end
    else
        player.print("No resources found within the drill's mining area.")
    end
end

-- Function: Inspect the nearest mining drill
local function inspect_drill(player)
    -- Find the nearest mining drill within a 100-tile radius
    local drill = player.surface.find_entities_filtered{
        type = "mining-drill", 
        position = player.position, 
        radius = 100
    }[1]

    if not drill then
        player.print("No mining drill found within a 100-tile radius.")
        return
    end

    -- Retrieve the mining radius from the drill's prototype
    local drill_prototype = drill.prototype
    local mining_radius = drill_prototype.mining_drill_radius
    if not mining_radius then
        player.print("Error: Mining drill radius not available for this drill.")
        return
    end

    -- Display basic information and zoom to the drill
    player.print("Pinging location of mining drill with entity number: " .. drill.unit_number)
    player.print("Position: x = " .. drill.position.x .. ", y = " .. drill.position.y)
    player.zoom_to_world(drill.position, 0.5)

    -- Highlight the mining area and summarize resources
    local bounding_box = highlight_mining_area(drill, mining_radius, player)
    summarize_resources(drill, bounding_box, player)
end

-- Register the /inspect_drill command
commands.add_command("inspect_drill", "Inspects the nearest mining drill.", function(event)
    local player = game.get_player(event.player_index)
    if player then
        inspect_drill(player)
    end
end)

-- Function to create the GUI for the player
local function create_gui(player)
    -- Check if the GUI already exists
    if player.gui.top.drill_inspector_frame then
        player.gui.top.drill_inspector_frame.destroy()
    end

    -- Create a new frame for the GUI
    local frame = player.gui.top.add{type = "frame", name = "drill_inspector_frame", caption = "Drill Inspector"}
    local dropdown_flow = frame.add{type = "flow", direction = "horizontal"}
    
    -- Add surface dropdown
    local surface_dropdown = dropdown_flow.add{type = "drop-down", name = "surface_dropdown", items = {}}
    for _, surface in pairs(game.surfaces) do
        surface_dropdown.add_item(surface.name)
    end

    -- Add resource type dropdown
    local resource_dropdown = dropdown_flow.add{type = "drop-down", name = "resource_dropdown", items = {}}
    for _, resource in pairs(game.entity_prototypes) do
        if resource.type == "resource" then
            resource_dropdown.add_item(resource.name)
        end
    end

    -- Add a button to refresh the GUI
    frame.add{type = "button", name = "refresh_button", caption = "Refresh"}

    -- Add a label to display the count
    frame.add{type = "label", name = "drill_count_label", caption = "Drills mining: 0"}
end

-- Function to update the drill count for the selected resource and surface
local function update_drill_count(player)
    -- Get the selected surface and resource from the dropdowns
    local surface_name = player.gui.top.drill_inspector_frame.surface_dropdown.get_item(player.gui.top.drill_inspector_frame.surface_dropdown.selected_index)
    local resource_name = player.gui.top.drill_inspector_frame.resource_dropdown.get_item(player.gui.top.drill_inspector_frame.resource_dropdown.selected_index)

    if not surface_name or not resource_name then
        player.print("Please select a surface and resource.")
        return
    end

    local surface = game.surfaces[surface_name]
    local drill_count = 0

    -- Find all mining drills on the selected surface
    local drills = surface.find_entities_filtered{name = "electric-mining-drill"}

    -- Count the number of drills mining the selected resource
    for _, drill in pairs(drills) do
        local mining_area = {
            left_top = {x = drill.position.x - drill.prototype.mining_drill_radius, y = drill.position.y - drill.prototype.mining_drill_radius},
            right_bottom = {x = drill.position.x + drill.prototype.mining_drill_radius, y = drill.position.y + drill.prototype.mining_drill_radius}
        }

        local resources = surface.find_entities_filtered{
            area = mining_area,
            type = "resource",
            name = resource_name
        }

        if #resources > 0 then
            drill_count = drill_count + 1
        end
    end

    -- Update the label with the count
    player.gui.top.drill_inspector_frame.drill_count_label.caption = "Drills mining: " .. drill_count
end

-- Event handler for refreshing the GUI
script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "refresh_button" then
        update_drill_count(game.get_player(event.player_index))
    end
end)

-- Command to open the GUI
commands.add_command("drill_inspector", "Opens the drill inspector GUI", function(event)
    local player = game.get_player(event.player_index)
    if player then
        create_gui(player)
    end
end)
