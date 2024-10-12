--gui_events.lua

local gui = require("gui.gui")

-- Function to handle GUI clicks (for both refresh and close buttons)
script.on_event(defines.events.on_gui_click, function(event)
    local player = game.get_player(event.player_index)
    if player then
        -- Check if the clicked element is valid
        if event.element and event.element.valid then
            -- Handle refresh button click
            if event.element.name == "refresh_button" then
                global.force_update = true
                global.drill_processing_index = 1

                -- Handle close button click
            elseif event.element.name == "drill_close_button" then
                if player.gui.screen.drill_inspector_frame then
                    player.gui.screen.drill_inspector_frame.destroy()
                end

                -- Handle the custom Drilly button (top-left button)
            elseif event.element.name == "drilly_button" then
                -- Toggle the Drilly GUI
                if player.gui.screen.drill_inspector_frame then
                    player.gui.screen.drill_inspector_frame.destroy() -- Close the GUI if it's open
                else
                    gui.create_gui(player)                            -- Open the GUI if it's not open
                end
            elseif event.element.name == "drilly_time_toggle_button" then
                local time_periods = { "S", "M", "H", "T" }
                local current_index = player.mod_settings["drilly-current-period-index"].value or 1
                current_index = current_index % #time_periods + 1 -- Cycle through indices
                player.mod_settings["drilly-current-period-index"] = { value = current_index }
                event.element.caption = time_periods[current_index]
                -- Update the GUI
                gui.update_drill_count(player)
            end
        end
    end
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    local element = event.element
    local player = game.get_player(event.player_index)

    if element and element.valid and element.name == "surface_dropdown" then
        gui.update_drill_count(player)
    end
end)
