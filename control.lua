-- Function to format numbers with commas
local function format_number_with_commas(number)
    local formatted = tostring(number)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Function to inspect a mining drill
local function inspect_drill(player)
    -- Find the first mining drill on the player's surface
    local drill = player.surface.find_entities_filtered{
        type = "mining-drill", 
        position = player.position, 
        radius = 100
    }[1]

    if drill then
        -- Get the prototype to retrieve the mining radius
        local drill_prototype = drill.prototype
        if not drill_prototype.mining_drill_radius then
            player.print("Error: Mining drill radius not available for this drill.")
            return
        end
        local mining_radius = drill_prototype.mining_drill_radius

        -- Print drill information and zoom to the drill
        player.print("Pinging location of mining drill with entity number: " .. drill.unit_number)
        player.print("Position: x = " .. drill.position.x .. ", y = " .. drill.position.y)
        player.zoom_to_world(drill.position, 0.5)

        -- Define the bounding box based on the actual mining radius
        local bounding_box = {
            left_top = {x = drill.position.x - mining_radius, y = drill.position.y - mining_radius},
            right_bottom = {x = drill.position.x + mining_radius, y = drill.position.y + mining_radius}
        }

        -- Create a highlight box to mark the mining area
        player.surface.create_entity{
            name = "highlight-box",
            bounding_box = bounding_box,
            position = drill.position,
            box_type = "electricity",
            time_to_live = 180,
            render_player_index = player.index
        }

        -- Create flying text to mark the drill
        player.surface.create_entity{
            name = "flying-text",
            position = drill.position,
            text = "Drill Here",
            color = {r = 1, g = 0.5, b = 0}
        }

        -- Find resources in the bounding box
        local resources = drill.surface.find_entities_filtered{
            area = bounding_box,
            type = "resource"
        }

        -- Summarize resources found in the drill's mining area
        local resource_summary = {}
        for _, resource in pairs(resources) do
            if resource_summary[resource.name] then
                resource_summary[resource.name].amount = resource_summary[resource.name].amount + resource.amount
                if not resource_summary[resource.name].drills then
                    resource_summary[resource.name].drills = {}
                end
                resource_summary[resource.name].drills[drill.unit_number] = true
            else
                resource_summary[resource.name] = {amount = resource.amount, drills = {[drill.unit_number] = true}}
            end
        end

        -- Output resource summary
        if next(resource_summary) then
            player.print("Resources within the drill's mining area:")
            for resource_name, data in pairs(resource_summary) do
                player.print(resource_name .. ": " .. format_number_with_commas(data.amount) .. " units")
            end
        else
            player.print("No resources found within the drill's mining area.")
        end
    else
        player.print("No mining drill found within a 100-tile radius.")
    end
end

-- Register a custom console command to inspect drills
commands.add_command("inspect_drill", "Inspects the nearest mining drill.", function(event)
    local player = game.get_player(event.player_index)
    if player then
        inspect_drill(player)
    end
end)
