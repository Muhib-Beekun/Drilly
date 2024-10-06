local gui = require("gui")

-- Function to handle GUI clicks (for both refresh and close buttons)
script.on_event(defines.events.on_gui_click, function(event)
    local player = game.get_player(event.player_index)

    -- Check if the clicked element is valid
    if event.element and event.element.valid then
        -- Handle refresh button click
        if event.element.name == "refresh_button" then
            gui.update_drill_count(player)

        -- Handle close button click
        elseif event.element.name == "drill_close_button" then
            if player.gui.top.drill_inspector_frame then
                player.gui.top.drill_inspector_frame.destroy()
            end

        -- Handle the custom Drilly button (top-left button)
        elseif event.element.name == "drilly_button" then
            -- Toggle the Drilly GUI
            if player.gui.top.drill_inspector_frame then
                player.gui.top.drill_inspector_frame.destroy()  -- Close the GUI if it's open
            else
                gui.create_gui(player)  -- Open the GUI if it's not open
            end
        end
    end
end)
