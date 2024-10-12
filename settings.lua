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
        type = "int-setting",
        name = "drilly-current-period-index",
        setting_type = "runtime-per-user",
        default_value = 1,
        allowed_values = { 1, 2, 3, 4 },
        hidden = true
    }
})
