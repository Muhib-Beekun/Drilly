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
    -- Find the first area-mining-drill on the player's surface
    local drill = player.surface.find_entities_filtered{name="area-mining-drill"}[1]

    if drill then
        -- Print drill information and zoom to the drill
        player.print("Pinging location of area-mining-drill with entity number: " .. drill.unit_number)
        player.print("Position: x = " .. drill.position.x .. ", y = " .. drill.position.y)
        player.zoom_to_world(drill.position, 0.5)

        -- Define the bounding box for the 11x11 mining area centered on the drill
        local bounding_box = {
            left_top = {x = drill.position.x - 5.5, y = drill.position.y - 5.5},
            right_bottom = {x = drill.position.x + 5.5, y = drill.position.y + 5.5}
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

        -- Get the mining target of the drill
        local mining_target = drill.mining_target

        if mining_target then
            local resource_name = mining_target.name
            local resource_amount = format_number_with_commas(mining_target.amount)

            -- Output the drill's mining information
            player.print("The drill is currently mining: " .. resource_name)
            player.print("Amount of ore remaining: " .. resource_amount)
        else
            player.print("This drill is not currently mining any resources.")
        end
    else
        player.print("No area-mining-drill found on this surface.")
    end
end

-- Register a custom console command to inspect drills
commands.add_command("inspect_drill", "Inspects the nearest mining drill.", function(event)
    local player = game.get_player(event.player_index)
    if player then
        inspect_drill(player)
    end
end)
