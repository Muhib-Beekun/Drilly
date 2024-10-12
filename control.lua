-- control.lua

require("gui.gui_events")
require("scripts.drilly_inspect_drill")
require("scripts.on_tick")
require("scripts.on_remove")
require("scripts.on_create")

local drilly_button = require("gui.drilly_button")
local gui = require("gui.gui")
local drill_utils = require("drill_utils")

-- Add the Drilly button when the game is initialized (new game or first mod load)
script.on_init(function()
    game.print("script.on_init initialized Drilly mod")
    drill_utils.initialize_drills()
    for _, player in pairs(game.players) do
        drilly_button.create_drilly_button_if_needed(player)
        gui.update_surface_dropdown(player)
    end
end)

-- Handle changes when a game is loaded or mods are updated
script.on_configuration_changed(function(event)
    game.print("script.on_configuration_changed initialized Drilly mod")
    drill_utils.initialize_drills()
    for _, player in pairs(game.players) do
        drilly_button.create_drilly_button_if_needed(player)
        gui.update_surface_dropdown(player)
    end
end)

-- Handle changes when a player joins
script.on_event(defines.events.on_player_joined_game, function(event)
    game.print("events.on_player_joined_game initialized Drilly mod")
    drill_utils.initialize_drills()
    local player = game.get_player(event.player_index)
    drilly_button.create_drilly_button_if_needed(player)
    gui.update_surface_dropdown(player)
end
)

script.on_event(defines.events.on_player_created, function(event)
    game.print("events.on_player_created initialized Drilly mod")
    drill_utils.initialize_drills()
    local player = game.get_player(event.player_index)
    if player then
        drilly_button.create_drilly_button_if_needed(player)
        gui.update_surface_dropdown(player)
    end
end)
