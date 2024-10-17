-- control.lua

require("gui.gui_events")
require("scripts.on_tick")
require("scripts.on_remove")
require("scripts.on_create")


local drilly_button = require("gui.drilly_button")
local gui = require("gui.gui")
local drill_manager = require("scripts.drills.drill_manager")

-- Add the Drilly button when the game is initialized (new game or first mod load)
script.on_init(function()
    drill_manager.initialize_drills()
    for _, player in pairs(game.players) do
        if player.gui.screen.drill_inspector_frame then
            player.gui.screen.drill_inspector_frame.destroy()
        end
        drilly_button.create_drilly_button_if_needed(player)
        gui.update_drilly_surface_dropdown(player)
    end
end)

-- Handle changes when a game is loaded or mods are updated
script.on_configuration_changed(function(event)
    drill_manager.initialize_drills()
    for _, player in pairs(game.players) do
        if player.gui.screen.drill_inspector_frame then
            player.gui.screen.drill_inspector_frame.destroy()
        end
        drilly_button.create_drilly_button_if_needed(player)
        gui.update_drilly_surface_dropdown(player)
    end
end)

-- Handle changes when a player joins
script.on_event(defines.events.on_player_joined_game, function(event)
    drill_manager.initialize_drills()
    local player = game.get_player(event.player_index)
    if player.gui.screen.drill_inspector_frame then
        player.gui.screen.drill_inspector_frame.destroy()
    end
    drilly_button.create_drilly_button_if_needed(player)
    gui.update_drilly_surface_dropdown(player)
end
)

script.on_event(defines.events.on_player_created, function(event)
    drill_manager.initialize_drills()
    local player = game.get_player(event.player_index)
    if player then
        if player.gui.screen.drill_inspector_frame then
            player.gui.screen.drill_inspector_frame.destroy()
        end
        drilly_button.create_drilly_button_if_needed(player)
        gui.update_drilly_surface_dropdown(player)
    end
end)
