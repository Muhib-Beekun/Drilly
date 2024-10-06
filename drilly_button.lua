local mod_gui = require("mod-gui")

local drilly_button = {}

-- Create the Drilly button with a check if it already exists
function drilly_button.create_drilly_button_if_needed(player)
    local button_flow = mod_gui.get_button_flow(player)
    
    -- Check if the Drilly button already exists
    if not button_flow.drilly_button then
        local button = button_flow.add{
            type = "sprite-button",
            name = "drilly_button",
            sprite = "drilly_icon",
            tooltip = "Open Drilly",
            style = mod_gui.button_style
        }
        return button
    end
end

return drilly_button
