-- settings.lua

data:extend({
    {
        type = "int-setting",
        name = "drilly-refresh-interval-minutes",
        setting_type = "runtime-global",
        default_value = 5,
        minimum_value = 1,
        maximum_value = 60,
        order = "a"
    },
    {
        type = "bool-setting",
        name = "drilly-refresh-enabled",
        setting_type = "runtime-global",
        default_value = true,
        order = "b"
    },
    {
        type = "bool-setting",
        name = "drilly-group-deep-resources",
        setting_type = "runtime-global",
        default_value = false,
        order = "c",
    },
    {
        type = "int-setting",
        name = "drilly-max-drills-per-tick",
        setting_type = "runtime-global",
        default_value = 10,
        minimum_value = 1,
        order = "d"
    },
    {
        type = "int-setting",
        name = "drilly-current-period-index",
        setting_type = "runtime-per-user",
        default_value = 1,
        allowed_values = { 1, 2, 3, 4 },
        hidden = true
    },
    {
        type = "bool-setting",
        name = "drilly-auto-mark-deconstruction",
        setting_type = "runtime-global",
        default_value = true,
        order = "e",
    }
})
