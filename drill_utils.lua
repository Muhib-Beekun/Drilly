local drill_utils = {}

-- Function to fetch mined resources being exploited by drills on the surface
function drill_utils.get_mined_resources(surface)
    local resources = {}
    local tracked_drills = {}  -- To prevent double counting

    -- Find all mining drills on the surface
    local drills = surface.find_entities_filtered{type = "mining-drill"}

    -- Loop through drills to collect their mined resources
    for _, drill in pairs(drills) do
        -- Check if the drill has already been counted
        if not tracked_drills[drill.unit_number] then
            local mining_area = {
                left_top = {x = drill.position.x - drill.prototype.mining_drill_radius, y = drill.position.y - drill.prototype.mining_drill_radius},
                right_bottom = {x = drill.position.x + drill.prototype.mining_drill_radius, y = drill.position.y + drill.prototype.mining_drill_radius}
            }

            -- Find all resources in the drill's mining area
            local resource_entities = surface.find_entities_filtered{area = mining_area, type = "resource"}

            -- Loop through the resources mined by this drill
            for _, resource in pairs(resource_entities) do
                local resource_name = resource.name
                if not resources[resource_name] then
                    resources[resource_name] = {total_amount = 0, drill_count = 0}
                end
                resources[resource_name].total_amount = resources[resource_name].total_amount + resource.amount
                -- Count the drill for the resource only once
                resources[resource_name].drill_count = resources[resource_name].drill_count + 1
            end

            -- Mark this drill as counted for all resources in its area
            tracked_drills[drill.unit_number] = true
        end
    end

    return resources
end

-- Function to fetch drill data for each resource and drill type
function drill_utils.get_drill_data(surface)
    local drill_data = {}

    -- Find all mining drills on the surface (dynamic type detection)
    local drills = surface.find_entities_filtered{type = "mining-drill"}
    local tracked_drills = {}

    -- Loop through drills to associate them with mined resources
    for _, drill in pairs(drills) do
        if not tracked_drills[drill.unit_number] then
            local drill_type = drill.name  -- Get the type of drill

            local mining_area = {
                left_top = {x = drill.position.x - drill.prototype.mining_drill_radius, y = drill.position.y - drill.prototype.mining_drill_radius},
                right_bottom = {x = drill.position.x + drill.prototype.mining_drill_radius, y = drill.position.y + drill.prototype.mining_drill_radius}
            }

            -- Find all resources in the drill's mining area
            local resources = surface.find_entities_filtered{area = mining_area, type = "resource"}

            for _, resource in pairs(resources) do
                local resource_name = resource.name
                if not drill_data[resource_name] then
                    drill_data[resource_name] = {}
                end
                -- Increment the count of this drill type for this resource
                drill_data[resource_name][drill_type] = (drill_data[resource_name][drill_type] or 0) + 1
            end

            -- Mark this drill as counted
            tracked_drills[drill.unit_number] = true
        end
    end

    return drill_data
end

return drill_utils
