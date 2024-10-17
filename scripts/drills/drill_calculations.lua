local drill_calculations = {}


-- Function to calculate yield per second for regular miners
function drill_calculations.calculate_regular_miner_yield(drill, resource)
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
function drill_calculations.calculate_core_miner_yield(drill, resource)
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

return drill_calculations
