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
        type = "string-setting",
        name = "drilly-resource-interval",
        setting_type = "runtime-per-user",
        allowed_values = { "second", "minute", "total" },
        default_value = "second",
        order = "c"
    }
})
