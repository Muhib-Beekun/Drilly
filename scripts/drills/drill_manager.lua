-- drill_manager.lua
local resource_manager = require("scripts.resources.resource_manager")
local drill_calculations = require("scripts.drills.drill_calculations")


local drill_manager = {}

-- Initialize the storage tables
function drill_manager.initialize_drills()
    if not storage then
        storage = {}
    end
    storage.drills = storage.drills or {}
    storage.drill_unit_numbers = storage.drill_unit_numbers or {}
    storage.drill_processing_index = 1                                                  -- Force restart of drill processing loop
    storage.force_update = true                                                         -- Force restart of drill processing loop
    storage.surface_data = storage.surface_data or {}                                   -- For caching per-surface data
    storage.minable_entities = storage.minable_entities or
        {}                                                                              -- Initialize global minable entities table
    storage.temporary_alerts = storage.temporary_alerts or {}                           -- Initialize temporary alerts
    storage.player_data = storage.player_data or {}                                     -- initialize Player Data
    for _, surface in pairs(game.surfaces) do
        storage.surface_data[surface.index] = storage.surface_data[surface.index] or {} -- Initialize per-surface data

        local drills = surface.find_entities_filtered { type = "mining-drill", force = game.forces.player }

        for _, drill in pairs(drills) do
            if drill.valid and not storage.drills[drill.unit_number] then
                drill_manager.add_drill(drill)
            end
        end
    end

    -- Remove drills that no longer exist
    for _, drill_data in pairs(storage.drills) do
        local drill = drill_data.entity
        if not (drill and drill.valid) then
            drill_manager.remove_drill(drill)
        end
    end
end

function drill_manager.add_drill(drill)
    local drill_data = {
        entity = drill,
        unit_number = drill.unit_number,
        name = drill.name,
        position = drill.position,
        surface_index = drill.surface.index,
        yield_per_second = 0,
        total_resources = {}, -- { [resource_name] = { amount = <number>, yield_per_second = <number> } }
        status = drill.status,
        last_updated_tick = game.tick,
    }
    storage.drills[drill.unit_number] = drill_data
    table.insert(storage.drill_unit_numbers, drill.unit_number)

    local new_surface_name = drill.surface.name

    -- Update the drilly_surface_dropdown for each player
    for _, player in pairs(game.players) do
        local main_frame = player.gui.screen.drill_inspector_frame
        if main_frame and main_frame.header_flow and main_frame.header_flow.drilly_surface_dropdown then
            local header_flow = main_frame.header_flow
            local drilly_surface_dropdown = header_flow.drilly_surface_dropdown
            if drilly_surface_dropdown then
                local current_items = drilly_surface_dropdown.items
                -- Check if the new surface is already in the dropdown
                local surface_exists = false
                for _, item in ipairs(current_items) do
                    if item == new_surface_name then
                        surface_exists = true
                        break
                    end
                end
                if not surface_exists then
                    -- Append the new surface to the list
                    table.insert(current_items, new_surface_name)
                    -- Extract the first two special items
                    local special_items = { current_items[1], current_items[2] } -- "By Surface" and "Aggregate"
                    -- Collect the surface names from the dropdown
                    local surface_items = {}
                    for i = 3, #current_items do
                        table.insert(surface_items, current_items[i])
                    end
                    -- Sort the surface names alphabetically
                    table.sort(surface_items)
                    -- Recombine the lists
                    local updated_items = special_items
                    for _, surface_name in ipairs(surface_items) do
                        table.insert(updated_items, surface_name)
                    end
                    -- Update the dropdown items
                    drilly_surface_dropdown.items = updated_items
                end
            end
        end
    end

    local resource_entities = resource_manager.get_resource_entities(drill)

    -- Update minable_entities
    resource_manager.update_minable_entities_for_drill(drill, true, resource_entities)
end

-- Function to remove a drill from storage.drills
function drill_manager.remove_drill(drill)
    if not drill then return end
    storage.drills[drill.unit_number] = nil
    -- Remove from unit_numbers list
    for i, unit_number in ipairs(storage.drill_unit_numbers) do
        if unit_number == drill.unit_number then
            table.remove(storage.drill_unit_numbers, i)
            break
        end
    end
    local resource_entities = resource_manager.get_resource_entities(drill)

    -- Update storage.minable_entities to remove the drill from any resource entities it covers
    resource_manager.update_minable_entities_for_drill(drill, false, resource_entities)
end

-- Function to update a single drill's data
function drill_manager.update_drill_data(drill_data)
    if not storage.minable_entities then
        game.print(
            "[Drilly Mod] Warning: storage.minable_entities not initialized at UpdateDrillData. Initializing now.")
        drill_manager.initialize_drills()
    end

    local drill = drill_data.entity
    if not (drill and drill.valid) then
        -- Remove invalid drills
        drill_manager.remove_drill(drill)
        return
    end

    -- Retrieve the current status of the drill
    local current_status = drill.status

    -- Determine if an update is necessary
    local needs_update = false

    if storage.force_update then
        needs_update = true
    elseif current_status == defines.entity_status.working then
        needs_update = true
    elseif drill_data.yield_per_second == 0 then
        needs_update = true
    elseif drill_data.status ~= current_status then
        needs_update = true
    end

    -- If no update is needed, exit the function
    if not needs_update then
        return
    end


    -- Update status
    drill_data.status = drill.status

    -- Update productivity bonus
    local productivity_bonus = drill.productivity_bonus or 0
    drill_data.productivity_bonus = 1 + productivity_bonus

    -- Get the list of resource entities covered by this drill
    local resource_entities = resource_manager.get_resource_entities(drill)

    -- Filter resources that the drill can mine
    local mining_categories = drill.prototype.resource_categories
    local valid_resources = {}
    for _, resource in pairs(resource_entities) do
        if mining_categories[resource.prototype.resource_category] then
            local resource_name = resource.name
            if settings.global["drilly-group-deep-resources"].value then
                resource_name = resource_name:gsub("^deep%-", "")
            end
            valid_resources[resource_name] = valid_resources[resource_name] or {}
            table.insert(valid_resources[resource_name], resource)
        end
    end

    -- If no valid resources, set yield per second to zero
    if next(valid_resources) == nil then
        drill_data.yield_per_second = 0
        drill_data.total_resources = {}
        drill_data.last_updated_tick = game.tick
        return
    end

    -- Calculate yield per second per resource
    local total_yield_per_second = 0
    local total_resources = {}
    for resource_name, resources in pairs(valid_resources) do
        -- Choose one resource entity to use in calculations
        -- Calculate yield per second for this resource
        local yield_per_second = 0
        if script.active_mods["space-exploration"] and drill.name == "se-core-miner-drill" then
            yield_per_second = drill_calculations.calculate_core_miner_yield(drill, resources[1])
        else
            yield_per_second = drill_calculations.calculate_regular_miner_yield(drill, resources[1])
        end

        -- Adjust the yield per second based on the fraction of resource tiles
        local num_tiles_R = #resources
        local total_resource_tiles = 0
        for _, res_list in pairs(valid_resources) do
            total_resource_tiles = total_resource_tiles + #res_list
        end
        local fraction_R = num_tiles_R / total_resource_tiles

        -- Adjust the yield per second for this resource
        local frac_yield_per_second = yield_per_second * fraction_R

        total_yield_per_second = total_yield_per_second + frac_yield_per_second

        -- Sum total amounts of this resource, adjusting for overlapping drills
        local total_amount = 0
        for _, resource in pairs(resources) do
            local resource_key = (resource.surface.index .. "_" .. resource.position.x .. "_" .. resource.position.y)
            if not storage.minable_entities[resource_key] then
                resource_manager.update_minable_entities_for_drill(drill, true, resource_entities)
            end
            local drills_covering = storage.minable_entities[resource_key] and
                storage.minable_entities[resource_key].drills or {}
            local num_drills_covering = 0
            for _ in pairs(drills_covering) do
                num_drills_covering = num_drills_covering + 1
            end
            -- Adjust the resource amount by dividing by the number of drills covering it
            local adjusted_amount = (resource.amount or 0) / num_drills_covering
            total_amount = total_amount + adjusted_amount
        end


        -- Store per-resource data
        total_resources[resource_name] = {
            amount = total_amount * drill_data.productivity_bonus,
            yield_per_second = yield_per_second,
        }
    end

    drill_data.yield_per_second = total_yield_per_second
    drill_data.total_resources = total_resources
    drill_data.last_updated_tick = game.tick
end

-- Function to search drills based on resource, status, and surface
function drill_manager.search_drills(resource, status, surface, drill_type)
    local filtered_drills = {}

    for _, drill in pairs(storage.drills) do
        local drill_entity = drill.entity
        if drill_entity and drill_entity.valid then
            local drill_status = drill.status

            local drill_surface = game.surfaces[drill_entity.surface.name]
            -- Check if the drill's status matches
            if tostring(drill_status) == tostring(status) then
                -- Check drill type
                if drill_type == nil or drill_type == drill_entity.name then
                    -- Check if the drill extracts the specified resource
                    if drill.total_resources and drill.total_resources[resource] then
                        -- Check surface criteria
                        if surface == "Aggregate" then
                            table.insert(filtered_drills, drill)
                        elseif surface == drill_surface.name then
                            table.insert(filtered_drills, drill)
                        end
                    end
                end
            end
        end
    end
    return filtered_drills
end

return drill_manager
