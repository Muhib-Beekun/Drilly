-- control.lua

require("gui_events")
local drilly_button = require("drilly_button")
local gui = require("gui")
local drill_utils = require("drill_utils")

-- Add the Drilly button when the game is initialized (new game or first mod load)
script.on_init(function()
    game.print("script.on_init initialized Drilly mod")
    drill_utils.initialize_drills()
    for _, player in pairs(game.players) do
        drilly_button.create_drilly_button_if_needed(player)
        gui.update_surface_dropdown(player)
    end
end)

-- Handle changes when a game is loaded or mods are updated
script.on_configuration_changed(function(event)
    game.print("script.on_configuration_changed initialized Drilly mod")
    drill_utils.initialize_drills()
    for _, player in pairs(game.players) do
        drilly_button.create_drilly_button_if_needed(player)
        gui.update_surface_dropdown(player)
    end
end)

-- Handle changes when a player joins
script.on_event(defines.events.on_player_joined_game, function(event)
    game.print("events.on_player_joined_game initialized Drilly mod")
    drill_utils.initialize_drills()
    local player = game.get_player(event.player_index)
    drilly_button.create_drilly_button_if_needed(player)
    gui.update_surface_dropdown(player)
end
)

script.on_event(defines.events.on_player_created, function(event)
    game.print("events.on_player_created initialized Drilly mod")
    drill_utils.initialize_drills()
    local player = game.get_player(event.player_index)
    if player then
        drilly_button.create_drilly_button_if_needed(player)
        gui.update_surface_dropdown(player)
    end
end)

-- Command to open the drill inspector GUI
commands.add_command("drilly", "Forces the creation of the Drilly button", function(event)
    local player = game.get_player(event.player_index)
    if player then
        drilly_button.create_drilly_button_if_needed(player)
        gui.update_surface_dropdown(player)
    end
end)



script.on_event(defines.events.on_tick, function(event)
    if not global.drills then
        game.print("events.on_tick not global.drills initialized Drilly mod")
        drill_utils.initialize_drills()
    end

    local total_drills = #global.drill_unit_numbers
    if total_drills == 0 then
        -- Empty drills list, prompt a full refresh
        game.print("events.on_tick total_drills == 0 initialized Drilly mod")
        drill_utils.initialize_drills()
        total_drills = #global.drill_unit_numbers
        if total_drills == 0 then
            return -- No drills to process
        end
    end

    -- Get the desired refresh interval in minutes and convert to ticks
    local refresh_interval_minutes = settings.global["drilly-refresh-interval-minutes"].value or 1 -- Default to 1 minute
    local refresh_interval_ticks = refresh_interval_minutes *
        3600                                                                                       -- 60 seconds * 60 ticks per second

    local drills_per_tick = math.ceil(total_drills / refresh_interval_ticks)
    global.drills_per_tick = drills_per_tick

    for i = 1, drills_per_tick do
        local index = global.drill_processing_index or 1
        if index > total_drills then
            global.drill_processing_index = 1
            index = 1
            global.initial_update = false
        end

        local unit_number = global.drill_unit_numbers[index]
        local drill_data = global.drills[unit_number]
        if drill_data then
            drill_utils.update_drill_data(drill_data)
        end

        global.drill_processing_index = global.drill_processing_index + 1
    end

    -- Update progress bar every second
    if event.tick % 60 == 0 then
        for _, player in pairs(game.connected_players) do
            if player.gui.screen.drill_inspector_frame then
                gui.update_drill_count(player)
                gui.update_surface_dropdown(player)
                gui.update_progress_bar(player, global.drill_processing_index - 1, total_drills)
            end
        end
    end
end)

-- Handle when a drill is built
script.on_event({ defines.events.on_built_entity, defines.events.on_robot_built_entity }, function(event)
    local entity = event.created_entity or event.entity
    if entity and entity.valid and entity.type == "mining-drill" then
        drill_utils.add_drill(entity)
    end
end
)

-- Handle when a drill is removed
script.on_event(
    { defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity, defines.events.on_entity_died },
    function(event)
        local entity = event.entity
        if entity and entity.valid and entity.type == "mining-drill" then
            drill_utils.remove_drill(entity)
        end
        if entity and entity.valid and entity.type == "resource" then
            local resource_key = (entity.surface.index .. "_" .. entity.position.x .. "_" .. entity.position.y)
            global.minable_entities[resource_key] = nil
        end
    end
)


--Other functions for cleanup and incoperation later

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
        left_top = { x = drill.position.x - mining_radius, y = drill.position.y - mining_radius },
        right_bottom = { x = drill.position.x + mining_radius, y = drill.position.y + mining_radius }
    }

    -- Create a highlight box for the mining area
    player.surface.create_entity {
        name = "highlight-box",
        bounding_box = bounding_box,
        position = drill.position,
        box_type = "electricity",
        time_to_live = 180,
        render_player_index = player.index
    }

    -- Create flying text to mark the drill's location
    player.surface.create_entity {
        name = "flying-text",
        position = drill.position,
        text = "Drill Here",
        color = { r = 1, g = 0.5, b = 0 }
    }

    return bounding_box
end


-- Function: Summarize resources in the mining area
local function summarize_resources(drill, bounding_box, player)
    local resources = drill.surface.find_entities_filtered {
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
            resource_summary[resource.name] = { amount = resource.amount, drills = { [drill.unit_number] = true } }
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
    local drill = player.surface.find_entities_filtered {
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
