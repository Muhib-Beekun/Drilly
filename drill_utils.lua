local drill_utils = {}

-- Function to fetch all resources being mined on the surface
function drill_utils.get_all_resources(surface)
    local resources = {}

    -- Find all resources on the surface
    local resource_entities = surface.find_entities_filtered{type = "resource"}

    -- Loop through resources to collect their total amounts and counts
    for _, resource in pairs(resource_entities) do
        local resource_name = resource.name
        if not resources[resource_name] then
            resources[resource_name] = {total_amount = 0}
        end
        resources[resource_name].total_amount = resources[resource_name].total_amount + resource.amount
    end

    return resources
end

-- Function to fetch drill data for each resource and drill type
function drill_utils.get_drill_data(surface)
    local drill_data = {}

    -- Find all mining drills on the surface (dynamic type detection)
    local drills = surface.find_entities_filtered{type = "mining-drill"}

    -- Loop through drills to associate them with mined resources
    for _, drill in pairs(drills) do
        local drill_type = drill.name  -- Get the type of drill (e.g., electric-mining-drill, burner-mining-drill)

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
    end

    return drill_data
end

return drill_utils
