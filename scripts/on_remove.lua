-- on_remove.lua
local drill_manager = require("scripts.drills.drill_manager")

local function handle_drill_removed(entity)
    if entity and entity.valid and entity.type == "mining-drill" then
        drill_manager.remove_drill(entity, true)
    end
end

script.on_event(defines.events.on_robot_mined_entity, function(event)
    handle_drill_removed(event.entity)
end)

script.on_event(defines.events.on_player_mined_entity, function(event)
    handle_drill_removed(event.entity)
end)

script.on_event(defines.events.on_entity_died, function(event)
    handle_drill_removed(event.entity)
end)
