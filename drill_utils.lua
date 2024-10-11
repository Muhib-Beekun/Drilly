-- drill_utils.lua

local drill_utils = {}

-- Initialize the global tables
function drill_utils.initialize_drills()
    global.drills = {}
    global.drill_unit_numbers = {}
    global.drill_processing_index = 1
    global.surface_data = {} -- For caching per-surface data

    for _, surface in pairs(game.surfaces) do
        local drills = surface.find_entities_filtered { type = "mining-drill", force = game.forces.player }
        global.surface_data[surface.index] = {} -- Initialize per-surface data

        for _, drill in pairs(drills) do
            if drill.valid then
                drill_utils.add_drill(drill)
            end
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
end

-- Function to update a single drill's data
function drill_utils.update_drill_data(drill_data)
    local drill = drill_data.entity
    if not (drill and drill.valid) then
        -- Remove invalid drills
        drill_utils.remove_drill(drill)
        return
    end

    -- Update status
    drill_data.status = drill.status

    -- Calculate mining area
    local mining_radius = drill.prototype.mining_drill_radius or 0
    local mining_area = {
        left_top = { x = drill.position.x - mining_radius, y = drill.position.y - mining_radius },
        right_bottom = { x = drill.position.x + mining_radius, y = drill.position.y + mining_radius }
    }

    local surface = drill.surface
    local resource_entities = surface.find_entities_filtered { area = mining_area, type = "resource" }

    -- Filter resources that the drill can mine
    local mining_categories = drill.prototype.resource_categories
    local valid_resources = {}
    for _, resource in pairs(resource_entities) do
        if mining_categories[resource.prototype.resource_category] then
            valid_resources[resource.name] = resource
        end
    end

    -- If no valid resources, set yield per second to zero
    if next(valid_resources) == nil then
        drill_data.yield_per_second = 0
        drill_data.total_resources = {}
        drill_data.last_updated_tick = game.tick
        return
    end

    -- Choose any valid resource to calculate yield per second
    local resource_name = next(valid_resources)
    local resource = valid_resources[resource_name]

    -- Calculate yield per second for the drill
    local yield_per_second = 0

    if script.active_mods["space-exploration"] and drill.name == "se-core-miner-drill" then
        yield_per_second = drill_utils.calculate_core_miner_yield(drill, resource)
    else
        yield_per_second = drill_utils.calculate_regular_miner_yield(drill, resource)
    end

    -- Sum total resource amounts (without duplication)
    local total_resources = {}
    local total_amounts = {}
    for _, resource in pairs(valid_resources) do
        local r_name = resource.name
        total_amounts[r_name] = (total_amounts[r_name] or 0) + (resource.amount or 0)
    end

    drill_data.yield_per_second = yield_per_second
    drill_data.total_resources = total_amounts
    drill_data.productivity_bonus = drill.effects and drill.effects.productivity and drill.effects.productivity.bonus or
        0
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
    local speed_bonus = drill.effects and drill.effects.speed and drill.effects.speed.bonus or 0
    local actual_mining_speed = base_mining_speed * (1 + speed_bonus)

    -- Apply productivity bonuses
    local base_productivity = drill.prototype.base_productivity or 0
    local productivity_bonus = drill.effects and drill.effects.productivity and drill.effects.productivity.bonus or 0
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
        yield_per_second = (actual_mining_speed * amount_per_mining_op * effective_productivity) / mining_time
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
    local speed_bonus = drill.effects and drill.effects.speed and drill.effects.speed.bonus or 0
    local actual_mining_speed = base_mining_speed * (1 + speed_bonus)

    -- Apply productivity bonuses
    local base_productivity = drill.prototype.base_productivity or 0
    local productivity_bonus = drill.effects and drill.effects.productivity and drill.effects.productivity.bonus or 0
    local effective_productivity = 1 + base_productivity + productivity_bonus

    -- Calculate yield per second
    local base_mining_rate = actual_mining_speed / mining_time
    local yield_per_second = base_mining_rate * core_miner_efficiency * zone_yield_multiplier * effective_productivity *
        amount_per_mining_op

    return yield_per_second
end

-- Function to count the number of drills covering a resource tile
function drill_utils.count_drills_covering_resource(resource)
    local surface = resource.surface
    local resource_position = resource.position

    -- Define search area around the resource position
    local search_radius = 10 -- Adjust as needed for performance
    local area = {
        left_top = { x = resource_position.x - search_radius, y = resource_position.y - search_radius },
        right_bottom = { x = resource_position.x + search_radius, y = resource_position.y + search_radius }
    }

    -- Find mining drills in the area
    local nearby_drills = surface.find_entities_filtered { area = area, type = "mining-drill" }

    local count = 0

    for _, drill in pairs(nearby_drills) do
        if drill.valid then
            -- Get drill mining area
            local mining_radius = drill.prototype.mining_drill_radius or 0
            local mining_area = {
                left_top = { x = drill.position.x - mining_radius, y = drill.position.y - mining_radius },
                right_bottom = { x = drill.position.x + mining_radius, y = drill.position.y + mining_radius }
            }

            -- Check if resource position is within the mining area
            if resource_position.x >= mining_area.left_top.x and resource_position.x <= mining_area.right_bottom.x
                and resource_position.y >= mining_area.left_top.y and resource_position.y <= mining_area.right_bottom.y then
                -- Check if the drill can mine this resource
                local mining_categories = drill.prototype.resource_categories
                if mining_categories[resource.prototype.resource_category] then
                    count = count + 1
                end
            end
        end
    end

    -- Ensure count is at least 1 to avoid division by zero
    if count == 0 then
        count = 1
    end

    return count
end

return drill_utils
