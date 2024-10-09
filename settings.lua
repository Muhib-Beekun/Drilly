data:extend({
    {
        type = "bool-setting",
        name = "drilly-enable-auto-refresh",
        setting_type = "runtime-global",
        default_value = true,
        order = "a"
    },
    {
        type = "int-setting",
        name = "drilly-auto-refresh-interval",
        setting_type = "runtime-global",
        default_value = 5,
        minimum_value = 1,
        maximum_value = 60,
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
