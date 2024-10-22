-- signals.lua

data:extend({
    {
        type = "item-subgroup",
        name = "drilly-alerts",
        group = "signals",
        order = "a[drilly-alerts]",
    },
    -- Green Alert Icon
    {
        type = "fluid",
        name = "drilly-green-alert",
        icon = "__drilly__/graphics/icons/drilly_green_alert.png",
        icon_size = 128,
        icon_mipmaps = 0,
        default_temperature = 15,
        max_temperature = 100,
        heat_capacity = "0.2kJ",
        base_color = { r = 0, g = 1, b = 0 },
        flow_color = { r = 0.7, g = 0.7, b = 0.7 },
        hidden = true,
        auto_barrel = false,
        subgroup = "drilly-alerts",
        order = "a1",
    },

    -- Yellow Alert Icon
    {
        type = "fluid",
        name = "drilly-yellow-alert",
        icon = "__drilly__/graphics/icons/drilly_yellow_alert.png",
        icon_size = 128,
        icon_mipmaps = 0,
        default_temperature = 15,
        max_temperature = 100,
        heat_capacity = "0.2kJ",
        base_color = { r = 1, g = 1, b = 0 },
        flow_color = { r = 0.7, g = 0.7, b = 0.7 },
        hidden = true,
        auto_barrel = false,
        subgroup = "drilly-alerts",
        order = "a2",
    },

    -- Red Alert Icon
    {
        type = "fluid",
        name = "drilly-red-alert",
        icon = "__drilly__/graphics/icons/drilly_red_alert.png",
        icon_size = 128,
        icon_mipmaps = 0,
        default_temperature = 15,
        max_temperature = 100,
        heat_capacity = "0.2kJ",
        base_color = { r = 1, g = 0, b = 0 },
        flow_color = { r = 0.7, g = 0.7, b = 0.7 },
        hidden = true,
        auto_barrel = false,
        subgroup = "drilly-alerts",
        order = "a3",
    },
})
