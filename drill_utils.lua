local drill_utils = {}

-- Function to count the number of drills mining the given resource on the selected surface
function drill_utils.count_drills_on_surface(surface, resource_name)
    local drill_count = 0

    -- Find all mining drills on the selected surface
    local drills = surface.find_entities_filtered{name = "electric-mining-drill"}

    -- Count the number of drills mining the selected resource
    for _, drill in pairs(drills) do
        local mining_area = {
            left_top = {x = drill.position.x - drill.prototype.mining_drill_radius, y = drill.position.y - drill.prototype.mining_drill_radius},
            right_bottom = {x = drill.position.x + drill.prototype.mining_drill_radius, y = drill.position.y + drill.prototype.mining_drill_radius}
        }

        local resources = surface.find_entities_filtered{
            area = mining_area,
            type = "resource",
            name = resource_name
        }

        if #resources > 0 then
            drill_count = drill_count + 1
        end
    end

    return drill_count
end

return drill_utils
