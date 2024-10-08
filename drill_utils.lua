--drill_utils.lua
local drill_utils = {}

-- Function to calculate the number of resource tiles a drill covers and divide productivity accordingly
local function calculate_resource_tile_count_and_productivity(drill, resource_entities)
    local total_resource_tiles = 0
    local resource_tile_count = {} -- Tracks the number of tiles for each resource type

    -- Calculate the total number of resource tiles the drill covers
    for _, resource in pairs(resource_entities) do
        local resource_name = resource.name
        if not resource_tile_count[resource_name] then
            resource_tile_count[resource_name] = 0
        end
        resource_tile_count[resource_name] = resource_tile_count[resource_name] + 1
        total_resource_tiles = total_resource_tiles + 1
    end

    -- For each resource, determine its share of the productivity and speed
    local resource_productivity_share = {}
    for resource_name, tile_count in pairs(resource_tile_count) do
        resource_productivity_share[resource_name] = tile_count / total_resource_tiles
    end

    return resource_tile_count, resource_productivity_share
end


-- Function to fetch mined resources being exploited by drills on the surface
function drill_utils.get_mined_resources(surface, display_mode)
    local resources = {}
    local resource_drill_count = {} -- To track how many drills overlap each resource entity

    -- Ensure the surface is valid before proceeding
    if not surface then
        game.print("Error: Surface is nil or invalid.")
        return resources
    end

    -- Find all mining drills on the surface
    local drills = surface.find_entities_filtered { type = "mining-drill" }

    if not drills then
        game.print("Error: No drills found on the surface!")
        return resources -- Return empty resources to prevent further errors
    end

    -- First pass: Count how many drills overlap each resource entity
    for _, drill in pairs(drills) do
        local mining_area = {
            left_top = { x = drill.position.x - drill.prototype.mining_drill_radius, y = drill.position.y - drill.prototype.mining_drill_radius },
            right_bottom = { x = drill.position.x + drill.prototype.mining_drill_radius, y = drill.position.y + drill.prototype.mining_drill_radius }
        }

        local resource_entities = surface.find_entities_filtered { area = mining_area, type = "resource" }

        for _, resource in pairs(resource_entities) do
            local resource_key = resource.position.x .. "_" .. resource.position.y -- Use position as a unique key
            if not resource_drill_count[resource_key] then
                resource_drill_count[resource_key] = 0
            end
            resource_drill_count[resource_key] = resource_drill_count[resource_key] + 1
        end
    end

    -- Second pass: Calculate resources based on mode (per second, per minute, or total)
    for _, drill in pairs(drills) do
        local mining_area = {
            left_top = { x = drill.position.x - drill.prototype.mining_drill_radius, y = drill.position.y - drill.prototype.mining_drill_radius },
            right_bottom = { x = drill.position.x + drill.prototype.mining_drill_radius, y = drill.position.y + drill.prototype.mining_drill_radius }
        }

        local resource_entities = surface.find_entities_filtered { area = mining_area, type = "resource" }
        local base_mining_speed = drill.prototype.mining_speed or 1 -- Default to 1 if mining speed is missing
        local actual_mining_speed = base_mining_speed

        -- Apply speed bonuses from effects (if applicable)
        local effects = drill.effects
        local speed_bonus = 0
        if effects and effects.speed then
            speed_bonus = effects.speed.bonus or 0
            actual_mining_speed = base_mining_speed * (1 + speed_bonus)
        end

        -- Calculate tile counts and productivity share for each resource type
        local resource_tile_count, resource_productivity_share = calculate_resource_tile_count_and_productivity(drill,
            resource_entities)

        -- Keep track of resource types already processed for this drill
        local processed_resource_types = {}

        -- Loop through the resource entities mined by this drill
        for _, resource in pairs(resource_entities) do
            local resource_name = resource.name
            local resource_key = resource.position.x .. "_" .. resource.position.y

            local resource_prototype = resource.prototype

            if resource_prototype.infinite_resource then
                -- Handle infinite resources per resource entity
                if not resources[resource_name] then
                    resources[resource_name] = { total_amount = 0, drill_count = 0 }
                end

                local drill_overlap_count = resource_drill_count[resource_key] or 1

                local normal_amount = resource_prototype.normal_resource_amount or 1
                local ratio = resource.amount / normal_amount

                local base_productivity = drill.prototype.base_productivity or 0
                local productivity_bonus = drill.productivity_bonus or 0
                local effective_productivity = 1 + base_productivity + productivity_bonus

                local yield_per_second = (resource_prototype.infinite_depletion_resource_amount * ratio) *
                actual_mining_speed * effective_productivity / drill_overlap_count

                -- Add the yield per second and total amount for infinite resources based on display mode
                if display_mode == "second" then
                    resources[resource_name].total_amount = resources[resource_name].total_amount + yield_per_second
                elseif display_mode == "minute" then
                    resources[resource_name].total_amount = resources[resource_name].total_amount +
                    (yield_per_second * 60)
                else
                    -- For total, sum the total resource amount left in the resource entity
                    resources[resource_name].total_amount = resources[resource_name].total_amount +
                    resource.amount / drill_overlap_count
                end

                -- Increment the drill count for this resource
                resources[resource_name].drill_count = resources[resource_name].drill_count + 1
            else
                -- Handle finite resources per resource type per drill
                if not processed_resource_types[resource_name] then
                    processed_resource_types[resource_name] = true -- Mark the resource type as processed for this drill

                    -- Gather all resource entities of this type under the drill
                    local resource_entities_of_type = {}
                    local total_drill_overlap_count = 0

                    for _, res in pairs(resource_entities) do
                        if res.name == resource_name then
                            table.insert(resource_entities_of_type, res)
                            local res_key = res.position.x .. "_" .. res.position.y
                            local drill_overlap_count = resource_drill_count[res_key] or 1
                            total_drill_overlap_count = total_drill_overlap_count + drill_overlap_count
                        end
                    end

                    local num_resource_tiles = #resource_entities_of_type
                    local average_drill_overlap_count = total_drill_overlap_count / num_resource_tiles

                    -- Calculate the extraction rate per drill, adjusted by productivity share and overlap
                    local amount_per_mining_operation = resource_prototype.mineable_properties.products[1].amount or 1
                    local base_productivity = drill.prototype.base_productivity or 0
                    local productivity_bonus = drill.productivity_bonus or 0
                    local effective_productivity = 1 + base_productivity + productivity_bonus

                    local productivity_share = resource_productivity_share[resource_name] or 1

                    local extraction_rate_per_drill = actual_mining_speed * amount_per_mining_operation *
                    effective_productivity * productivity_share
                    local adjusted_extraction_rate_per_drill = extraction_rate_per_drill / average_drill_overlap_count

                    -- Initialize the resource in the resources table if it's not already there
                    if not resources[resource_name] then
                        resources[resource_name] = { total_amount = 0, drill_count = 0 }
                    end

                    -- Add the extraction rate based on the display mode
                    if display_mode == "second" then
                        resources[resource_name].total_amount = resources[resource_name].total_amount +
                        adjusted_extraction_rate_per_drill
                    elseif display_mode == "minute" then
                        resources[resource_name].total_amount = resources[resource_name].total_amount +
                        (adjusted_extraction_rate_per_drill * 60)
                    else
                        -- For total, sum the total resource amount left in the resource entities
                        local total_resource_amount = 0
                        for _, res in pairs(resource_entities_of_type) do
                            total_resource_amount = total_resource_amount + res.amount
                        end
                        resources[resource_name].total_amount = resources[resource_name].total_amount +
                        total_resource_amount
                    end

                    -- Increment the drill count for this resource
                    resources[resource_name].drill_count = resources[resource_name].drill_count + 1
                end
            end
        end
    end

    return resources
end

-- Function to fetch drill data for each resource and drill type
function drill_utils.get_drill_data(surface)
    local drill_data = {}
    local tracked_resources = {} -- Track resources mined by specific drills

    -- Find all mining drills on the surface
    local drills = surface.find_entities_filtered { type = "mining-drill" }

    -- Loop through drills to associate them with mined resources
    for _, drill in pairs(drills) do
        local drill_type = drill.name -- Get the type of drill

        local mining_area = {
            left_top = { x = drill.position.x - drill.prototype.mining_drill_radius, y = drill.position.y - drill.prototype.mining_drill_radius },
            right_bottom = { x = drill.position.x + drill.prototype.mining_drill_radius, y = drill.position.y + drill.prototype.mining_drill_radius }
        }

        -- Find all resources in the drill's mining area
        local resources = surface.find_entities_filtered { area = mining_area, type = "resource" }

        for _, resource in pairs(resources) do
            local resource_name = resource.name

            -- Initialize the resource in drill_data if it's not already there
            if not drill_data[resource_name] then
                drill_data[resource_name] = {}
            end

            -- Ensure the drill is only counted once for each resource
            if not tracked_resources[resource_name] then
                tracked_resources[resource_name] = {}
            end

            -- Only increment the count if the drill has not been counted for this resource
            if not tracked_resources[resource_name][drill.unit_number] then
                tracked_resources[resource_name][drill.unit_number] = true -- Mark the drill as counted for this resource
                drill_data[resource_name][drill_type] = (drill_data[resource_name][drill_type] or 0) + 1
            end
        end
    end

    return drill_data
end

return drill_utils
