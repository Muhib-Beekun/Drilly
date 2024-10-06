local drill_utils = {}

-- Function to fetch mined resources being exploited by drills on the surface
function drill_utils.get_mined_resources(surface)
    local resources = {}
    local resource_drill_count = {} -- To track how many drills overlap each resource

    -- Ensure the surface is valid before proceeding
    if not surface then
        game.print("Error: Surface is nil or invalid.")
        return resources
    end

    -- Find all mining drills on the surface
    local drills = surface.find_entities_filtered { type = "mining-drill" }

    -- Check if drills is nil
    if not drills then
        game.print("Error: No drills found on the surface!")
        return resources -- Return empty resources to prevent further errors
    end

    -- First pass: Count how many drills overlap each resource
    for _, drill in pairs(drills) do
        -- Check if drill.prototype and drill.prototype.mining_drill_radius are valid
        if not drill.prototype or not drill.prototype.mining_drill_radius then
            game.print("Error: Drill prototype or mining drill radius is nil for drill at position: " ..
                drill.position.x .. ", " .. drill.position.y)
            goto continue
        end

        local mining_area = {
            left_top = { x = drill.position.x - drill.prototype.mining_drill_radius, y = drill.position.y - drill.prototype.mining_drill_radius },
            right_bottom = { x = drill.position.x + drill.prototype.mining_drill_radius, y = drill.position.y + drill.prototype.mining_drill_radius }
        }

        -- Find all resources in the drill's mining area
        local resource_entities = surface.find_entities_filtered { area = mining_area, type = "resource" }

        -- Check if resource_entities is nil
        if not resource_entities then
            game.print("Error: No resources found in the mining area!")
            goto continue -- Skip to the next drill if no resources found
        end

        -- Loop through the resources mined by this drill
        for _, resource in pairs(resource_entities) do
            local resource_key = resource.position.x .. "_" .. resource.position.y -- Use position as a unique key
            if not resource_drill_count[resource_key] then
                resource_drill_count[resource_key] = 0
            end
            -- Increment the number of drills overlapping this resource
            resource_drill_count[resource_key] = resource_drill_count[resource_key] + 1
        end

        ::continue::
    end

    -- Second pass: Sum resources, dividing by the number of overlapping drills
    for _, drill in pairs(drills) do
        if not drill.prototype or not drill.prototype.mining_drill_radius then
            game.print("Skipping drill at position: " ..
                drill.position.x .. ", " .. drill.position.y .. " due to invalid prototype or radius.")
            goto continue_second_pass
        end

        local mining_area = {
            left_top = { x = drill.position.x - drill.prototype.mining_drill_radius, y = drill.position.y - drill.prototype.mining_drill_radius },
            right_bottom = { x = drill.position.x + drill.prototype.mining_drill_radius, y = drill.position.y + drill.prototype.mining_drill_radius }
        }

        -- Find all resources in the drill's mining area
        local resource_entities = surface.find_entities_filtered { area = mining_area, type = "resource" }

        -- Check if resource_entities is nil again
        if not resource_entities then
            game.print("Error: No resources found in the second pass for this drill.")
            goto continue_second_pass
        end

        -- Loop through the resources mined by this drill
        for _, resource in pairs(resource_entities) do
            local resource_name = resource.name
            local resource_key = resource.position.x .. "_" .. resource.position.y -- Use position as a unique key

            if not resources[resource_name] then
                resources[resource_name] = { total_amount = 0, drill_count = 0 }
            end

            -- Divide the resource amount by the number of drills that overlap it
            local drill_overlap_count = resource_drill_count[resource_key]
            if not drill_overlap_count then
                game.print("Error: No drill overlap count found for resource " .. resource_name)
                drill_overlap_count = 1 -- Fallback to avoid division by nil
            end
            local divided_amount = resource.amount / drill_overlap_count

            -- Check if the resource is infinite or finite
            -- Check if the resource is infinite or finite
            if resource.prototype.infinite_resource then
                -- Infinite resource: calculate ratio of amount to normal_resource_amount
                local normal_amount = resource.prototype.normal_resource_amount or 1 -- Default to 1 if missing
                local ratio = resource.amount / normal_amount

                -- Calculate yield per second
                local yield_per_second = resource.prototype.infinite_depletion_resource_amount * ratio

                -- Add the yield per second and total amount for infinite resources
                resources[resource_name].total_amount = resources[resource_name].total_amount + yield_per_second
            else
                -- Finite resource: sum the amount
                resources[resource_name].total_amount = resources[resource_name].total_amount + divided_amount
            end

            --resources[resource_name].total_amount = resources[resource_name].total_amount + divided_amount
            resources[resource_name].drill_count = resources[resource_name].drill_count + 1
        end

        ::continue_second_pass::
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
