-- styles.lua

local styles = data.raw["gui-style"]["default"]

styles.drilly_red_button = {
    type = "button_style",
    parent = "slot_button",
    default_graphical_set = {
        base = {
            filename = "__core__/graphics/gui.png",
            position = { 148, 36 }, -- Position for the yellow button background
            corner_size = 8,
        }
    },
    hovered_graphical_set = {
        base = {
            filename = "__core__/graphics/gui.png",
            position = { 111, 36 }, -- Position for the hovered state
            corner_size = 8,
        }
    },
    clicked_graphical_set = {
        base = {
            filename = "__core__/graphics/gui.png",
            position = { 111, 36 }, -- Position for the clicked state
            corner_size = 8,
        }
    },
}

styles.drilly_green_button = {
    type = "button_style",
    parent = "slot_button",
    default_graphical_set = {
        base = {
            filename = "__core__/graphics/gui.png",
            position = { 148, 108 }, -- Position for the yellow button background
            corner_size = 8,
        }
    },
    hovered_graphical_set = {
        base = {
            filename = "__core__/graphics/gui.png",
            position = { 111, 108 }, -- Position for the hovered state
            corner_size = 8,
        }
    },
    clicked_graphical_set = {
        base = {
            filename = "__core__/graphics/gui.png",
            position = { 111, 108 }, -- Position for the clicked state
            corner_size = 8,
        }
    },
}

styles.drilly_yellow_button = {
    type = "button_style",
    parent = "slot_button",
    default_graphical_set = {
        base = {
            filename = "__core__/graphics/gui.png",
            position = { 148, 72 }, -- Position for the yellow button background
            corner_size = 8,
        }
    },
    hovered_graphical_set = {
        base = {
            filename = "__core__/graphics/gui.png",
            position = { 112, 72 }, -- Position for the hovered state
            corner_size = 8,
        }
    },
    clicked_graphical_set = {
        base = {
            filename = "__core__/graphics/gui.png",
            position = { 112, 72 }, -- Position for the clicked state
            corner_size = 8,
        }
    },
}
