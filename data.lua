-- data.lua
require("styles")
-- require("prototypes.signals")

data:extend({
    {
        type = "sprite",
        name = "drilly_icon",
        filename = "__drilly__/graphics/icons/drilly_icon.png",
        priority = "extra-high",
        size = 128,
        flags = { "gui-icon" }
    }
})
