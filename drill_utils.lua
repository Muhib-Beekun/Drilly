-- drill_utils.lua

local drill_utils = {}

-- Initialize the global tables
function drill_utils.initialize_drills()
    game.print("initialize_drills")
    global.drills = global.drills or {}
    global.drill_unit_numbers = global.drill_unit_numbers or {}
    global.drill_processing_index = global.drill_processing_index or 1
    global.initial_update = global.initial_update or true
    global.surface_data = global.surface_data or {}                                   -- For caching per-surface data
    global.minable_entities = global.minable_entities or
        {}                                                                            -- Initialize global minable entities table
    for _, surface in pairs(game.surfaces) do
        global.surface_data[surface.index] = global.surface_data[surface.index] or {} -- Initialize per-surface data

        local drills = surface.find_entities_filtered { type = "mining-drill", force = game.forces.player }

        for _, drill in pairs(drills) do
            if drill.valid and not global.drills[drill.unit_number] then
                drill_utils.add_drill(drill)
            end
        end
    end

    -- Remove drills that no longer exist
    for unit_number, drill_data in pairs(global.drills) do
        local drill = drill_data.entity
        if not (drill and drill.valid) then
            drill_utils.remove_drill(drill)
        end
    end
end

-- Function to add a drill to global.drills
function drill_utils.add_drill(drill)
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
    global.drills[drill.unit_number] = drill_data
    table.insert(global.drill_unit_numbers, drill.unit_number)

    local resource_entities = drill_utils.get_resource_entities(drill)

    -- Update minable_entities
    drill_utils.update_minable_entities_for_drill(drill, true, resource_entities)
end

-- Function to remove a drill from global.drills
function drill_utils.remove_drill(drill)
    global.drills[drill.unit_number] = nil
    -- Remove from unit_numbers list
    for i, unit_number in ipairs(global.drill_unit_numbers) do
        if unit_number == drill.unit_number then
            table.remove(global.drill_unit_numbers, i)
            break
        end
    end
    local resource_entities = drill_utils.get_resource_entities(drill)

    -- Update global.minable_entities to remove the drill from any resource entities it covers
    drill_utils.update_minable_entities_for_drill(drill, false, resource_entities)
end

-- Function to update a single drill's data
function drill_utils.update_drill_data(drill_data)
    if not global.minable_entities then
        game.print("[Drilly Mod] Warning: global.minable_entities not initialized at UpdateDrillData. Initializing now.")
        drill_utils.initialize_drills()
    end

    local drill = drill_data.entity
    if not (drill and drill.valid) then
        -- Remove invalid drills
        drill_utils.remove_drill(drill)
        return
    end

    -- Retrieve the current status of the drill
    local current_status = drill.status

    -- Determine if an update is necessary
    local needs_update = false

    if global.initial_update then
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
    local base_productivity = drill.prototype.base_productivity or 0
    local productivity_bonus = drill.productivity_bonus or 0
    drill_data.productivity_bonus = 1 + base_productivity + productivity_bonus

    -- Get the list of resource entities covered by this drill
    local resource_entities = drill_utils.get_resource_entities(drill)

    -- Filter resources that the drill can mine
    local mining_categories = drill.prototype.resource_categories
    local valid_resources = {}
    for _, resource in pairs(resource_entities) do
        if mining_categories[resource.prototype.resource_category] then
            local resource_name = resource.name
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
        local resource = resources[1]

        -- Calculate yield per second for this resource
        local yield_per_second = 0
        if script.active_mods["space-exploration"] and drill.name == "se-core-miner-drill" then
            yield_per_second = drill_utils.calculate_core_miner_yield(drill, resource)
        else
            yield_per_second = drill_utils.calculate_regular_miner_yield(drill, resource)
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
        for _, res in pairs(resources) do
            local resource_key = (res.surface.index .. "_" .. res.position.x .. "_" .. res.position.y)
            if not global.minable_entities[resource_key] then
                drill_utils.update_minable_entities_for_drill(drill, true, resource_entities)
            end
            local drills_covering = global.minable_entities[resource_key] and
                global.minable_entities[resource_key].drills or {}
            local num_drills_covering = 0
            for _ in pairs(drills_covering) do
                num_drills_covering = num_drills_covering + 1
            end
            -- Adjust the resource amount by dividing by the number of drills covering it
            local adjusted_amount = (res.amount or 0) / num_drills_covering
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

-- Function to calculate yield per second for regular miners
function drill_utils.calculate_regular_miner_yield(drill, resource)
    local resource_prototype = resource.prototype
    local base_mining_speed = drill.prototype.mining_speed or 1
    local mining_time = resource_prototype.mineable_properties.mining_time or 1
    local products = resource_prototype.mineable_properties.products
    local amount_per_mining_op = 1 -- Default to 1 if not specified

    -- Handle products with variable amounts
    if products and products[1] then
        local product = products[1]
        amount_per_mining_op = product.amount or ((product.amount_min + product.amount_max) / 2) or 1
    end

    -- Apply speed bonuses
    local speed_bonus = drill.speed_bonus or 0
    local actual_mining_speed = base_mining_speed * (1 + speed_bonus)

    -- Apply productivity bonuses
    local base_productivity = drill.prototype.base_productivity or 0
    local productivity_bonus = drill.productivity_bonus or 0
    local effective_productivity = 1 + base_productivity + productivity_bonus


    local yield_per_second = 0

    if resource_prototype.infinite_resource then
        -- Infinite resource yield calculation
        local normal_resource_amount = resource_prototype.normal_resource_amount or 1000
        local depletion_amount = resource_prototype.infinite_depletion_resource_amount or 1

        -- Calculate the yield multiplier based on resource amount
        local resource_amount = resource.amount
        local yield_multiplier = (resource_amount / normal_resource_amount)
        if yield_multiplier < depletion_amount / normal_resource_amount then
            yield_multiplier = depletion_amount / normal_resource_amount
        end

        yield_per_second = (actual_mining_speed * amount_per_mining_op * yield_multiplier * effective_productivity) /
            mining_time
    else
        -- Finite resource yield calculation
        yield_per_second = ((actual_mining_speed * amount_per_mining_op * effective_productivity) / mining_time) or 0
    end

    return yield_per_second
end

-- Function to calculate yield per second for core miners (Space Exploration)
function drill_utils.calculate_core_miner_yield(drill, resource)
    local surface = drill.surface
    local surface_index = surface.index
    local force = drill.force

    -- Initialize per-surface cache if not present
    if not global.surface_data[surface_index] then
        global.surface_data[surface_index] = {}
    end

    local surface_cache = global.surface_data[surface_index]

    -- Update core miner efficiency if needed
    if not surface_cache.core_miner_efficiency or game.tick > (surface_cache.core_miner_efficiency_updated_tick or 0) + 600 then
        -- Update every 600 ticks (10 seconds)
        local all_core_drills = surface.find_entities_filtered {
            type = "mining-drill",
            name = "se-core-miner-drill",
            force = force
        }
        local N = math.max(1, #all_core_drills)
        local core_miner_efficiency = math.sqrt(N) / N

        surface_cache.core_miner_efficiency = core_miner_efficiency
        surface_cache.core_miner_efficiency_updated_tick = game.tick
    end

    -- Update zone yield multiplier if not set
    if surface_cache.zone_yield_multiplier == nil then
        surface_cache.zone_yield_multiplier = 1 -- Default multiplier
        if remote.interfaces["space-exploration"] and remote.interfaces["space-exploration"]["get_zone_from_surface_index"] then
            local zone = remote.call("space-exploration", "get_zone_from_surface_index",
                { surface_index = surface.index })
            if zone and zone.radius then
                surface_cache.zone_yield_multiplier = (zone.radius + 5000) / 5000
            end
        end
    end

    local core_miner_efficiency = surface_cache.core_miner_efficiency
    local zone_yield_multiplier = surface_cache.zone_yield_multiplier

    local resource_prototype = resource.prototype
    local base_mining_speed = drill.prototype.mining_speed or 1
    local mining_time = resource_prototype.mineable_properties.mining_time or 1
    local products = resource_prototype.mineable_properties.products
    local amount_per_mining_op = 1 -- Default to 1 if not specified

    -- Handle products with variable amounts
    if products and products[1] then
        local product = products[1]
        amount_per_mining_op = product.amount or ((product.amount_min + product.amount_max) / 2) or 1
    end

    -- Apply speed bonuses
    local speed_bonus = drill.speed_bonus or 0
    local actual_mining_speed = base_mining_speed * (1 + speed_bonus)

    -- Apply productivity bonuses
    local base_productivity = drill.prototype.base_productivity or 0
    local productivity_bonus = drill.productivity_bonus or 0
    local effective_productivity = 1 + base_productivity + productivity_bonus

    -- Calculate yield per second
    local base_mining_rate = actual_mining_speed / mining_time
    local yield_per_second = (base_mining_rate * core_miner_efficiency * zone_yield_multiplier * effective_productivity *
        amount_per_mining_op) or 0

    return yield_per_second
end

function drill_utils.update_minable_entities_for_drill(drill, is_adding, resource_entities)
    -- Filter resources that the drill can mine
    local mining_categories = drill.prototype.resource_categories
    for _, resource in pairs(resource_entities) do
        if mining_categories[resource.prototype.resource_category] then
            local resource_key = (resource.surface.index .. "_" .. resource.position.x .. "_" .. resource.position.y)
            if not global.minable_entities[resource_key] then
                global.minable_entities[resource_key] = {
                    entity = resource,
                    drills = {},
                }
            end

            if is_adding then
                -- Add the drill to the list if not already present
                global.minable_entities[resource_key].drills[drill.unit_number] = true
            else
                -- Remove the drill from the list
                global.minable_entities[resource_key].drills[drill.unit_number] = nil
                -- Clean up if no drills left
                if not next(global.minable_entities[resource_key].drills) then
                    global.minable_entities[resource_key] = nil
                end
            end
        end
    end
end

--- Retrieves resource entities within the mining area of a given drill.
-- @param drill LuaEntity - The mining drill entity to inspect.
-- @return table - A list of resource entities found within the drill's mining area.
function drill_utils.get_resource_entities(drill)
    -- Validate the drill entity
    if not drill or not drill.valid then
        log("Error: Invalid drill entity provided to get_resource_entities.")
        return {}
    end

    -- Determine the mining radius of the drill
    local mining_radius = drill.prototype.mining_drill_radius or 0

    -- Define the mining area based on the drill's position and mining radius
    local mining_area = {
        left_top = {
            x = drill.position.x - mining_radius,
            y = drill.position.y - mining_radius
        },
        right_bottom = {
            x = drill.position.x + mining_radius,
            y = drill.position.y + mining_radius
        }
    }

    -- Get the surface (game world layer) where the drill is located
    local surface = drill.surface

    -- Find all resource entities within the mining area
    local resource_entities = surface.find_entities_filtered {
        area = mining_area,
        type = "resource"
    }

    -- Optional: Log the number of resources found for debugging
    log(string.format("Drill #%d found %d resource(s) within its mining area.", drill.unit_number, #resource_entities))

    return resource_entities
end

return drill_utils
