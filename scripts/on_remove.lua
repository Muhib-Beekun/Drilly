--on_remove.lua

local drill_manager = require("scripts.drills.drill_manager")

-- Handle when a drill is removed
script.on_event(defines.events.on_robot_mined_entity,
    function(event)
        local entity = event.entity
        if entity and entity.valid and entity.type == "mining-drill" then
            drill_manager.remove_drill(entity)
        end
        if entity and entity.valid and entity.type == "resource" then
            local resource_key = (entity.surface.index .. "_" .. entity.position.x .. "_" .. entity.position.y)
            storage.minable_entities[resource_key] = nil
        end
    end
)

-- Handle when a drill is removed
script.on_event(
    defines.events.on_player_mined_entity,
    function(event)
        local entity = event.entity
        if entity and entity.valid and entity.type == "mining-drill" then
            drill_manager.remove_drill(entity)
        end
        if entity and entity.valid and entity.type == "resource" then
            local resource_key = (entity.surface.index .. "_" .. entity.position.x .. "_" .. entity.position.y)
            storage.minable_entities[resource_key] = nil
        end
    end
)

-- Handle when a drill is removed
script.on_event(
    defines.events.on_entity_died,
    function(event)
        local entity = event.entity
        if entity and entity.valid and entity.type == "mining-drill" then
            drill_manager.remove_drill(entity)
        end
        if entity and entity.valid and entity.type == "resource" then
            local resource_key = (entity.surface.index .. "_" .. entity.position.x .. "_" .. entity.position.y)
            storage.minable_entities[resource_key] = nil
        end
    end
)
