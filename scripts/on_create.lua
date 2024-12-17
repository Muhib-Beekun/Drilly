--on_create.lua

local drill_manager = require("scripts.drills.drill_manager")

-- Handle when a drill is built by the player
script.on_event(defines.events.on_built_entity,
    function(event)
        -- Correctly use event.entity
        local entity = event.entity
        if not entity or not entity.valid then
            game.print('[Drilly Mod] Warning: entity is nil or invalid in on_built_entity event.')
            return
        end


        if entity.type == "mining-drill" then
            drill_manager.add_drill(entity)
        end
    end
)

-- Handle when a drill is built by a robot
script.on_event(defines.events.on_robot_built_entity,
    function(event)
        -- Correctly use event.entity
        local entity = event.entity
        if not entity or not entity.valid then
            game.print('[Drilly Mod] Warning: robot entity is nil or invalid in on_robot_built_entity event.')
            return
        end

        if entity.type == "mining-drill" then
            drill_manager.add_drill(entity)
        end
    end
)
