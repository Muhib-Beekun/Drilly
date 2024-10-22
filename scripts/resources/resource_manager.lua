local resource_manager = {}


function resource_manager.update_minable_entities_for_drill(drill, is_adding, resource_entities)
    -- Filter resources that the drill can mine
    local mining_categories = drill.prototype.resource_categories
    for _, resource in pairs(resource_entities) do
        if mining_categories[resource.prototype.resource_category] then
            local resource_key = (resource.surface.index .. "_" .. resource.position.x .. "_" .. resource.position.y)
            if not storage.minable_entities[resource_key] then
                storage.minable_entities[resource_key] = {
                    entity = resource,
                    drills = {},
                }
            end

            if is_adding then
                -- Add the drill to the list if not already present
                storage.minable_entities[resource_key].drills[drill.unit_number] = true
            else
                -- Remove the drill from the list
                storage.minable_entities[resource_key].drills[drill.unit_number] = nil
                -- Clean up if no drills left
                if not next(storage.minable_entities[resource_key].drills) then
                    storage.minable_entities[resource_key] = nil
                end
            end
        end
    end
end

--- Retrieves resource entities within the mining area of a given drill.
-- @param drill LuaEntity - The mining drill entity to inspect.
-- @return table - A list of resource entities found within the drill's mining area.
function resource_manager.get_resource_entities(drill)
    -- Validate the drill entity
    if not drill or not drill.valid then
        game.print("[Drilly Mod] Warning: Invalid drill entity provided to get_resource_entities.")
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

    return resource_entities
end

return resource_manager
