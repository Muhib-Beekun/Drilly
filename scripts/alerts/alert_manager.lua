local alert_manager = {}

alert_manager.icons = {
    ["green"] = { type = "fluid", name = "drilly-green-alert" },
    ["yellow"] = { type = "fluid", name = "drilly-yellow-alert" },
    ["red"] = { type = "fluid", name = "drilly-red-alert" },
}

-- Helper to get alert icon based on status
function alert_manager.get_alert_icon(status)
    if tostring(status) == tostring(defines.entity_status.working) then
        return alert_manager.icons["green"]
    elseif (tostring(status) == tostring(defines.entity_status.waiting_for_space_in_destination)) or
        (tostring(status) == tostring(defines.entity_status.low_input_fluid)) then
        return alert_manager.icons["yellow"]
    else
        return alert_manager.icons["red"]
    end
end

-- Function to create a temporary alert
function alert_manager.create_temporary_alert(player_index, drill, status)
    local player = game.get_player(player_index)
    if not drill or not drill.entity.valid then return end

    local icon = alert_manager.get_alert_icon(status)
    local message = { "", "Temporary Alert: ", drill.name, " is ", status }

    -- Add custom alert
    player.add_custom_alert(drill.entity, icon, message, true)

    -- Initialize tracking table
    global.temporary_alerts = global.temporary_alerts or {}
    global.temporary_alerts[player_index] = global.temporary_alerts[player_index] or {}

    local unit_number = drill.entity.unit_number
    if not global.temporary_alerts[player_index][unit_number] then
        global.temporary_alerts[player_index][unit_number] = drill
    end
end

-- Function to remove a temporary alert
function alert_manager.remove_temporary_alert(player_index, drill)
    local player = game.get_player(player_index)
    if not drill or not drill.entity.valid then return end

    -- Initialize the global.temporary_alerts table if not present
    global.temporary_alerts = global.temporary_alerts or {}
    global.temporary_alerts[player_index] = global.temporary_alerts[player_index] or {}

    local unit_number = drill.entity.unit_number
    if global.temporary_alerts[player_index][unit_number] then
        -- Remove the alert from the player
        player.remove_alert({ entity = drill.entity })

        -- Remove the drill from the tracking table
        global.temporary_alerts[player_index][unit_number] = nil
    end
end

return alert_manager
