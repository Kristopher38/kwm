local utils = require("utils")
local Widget = require("widget")

local Panel = utils.makeClass(function(self, x, y, width, height, color)
    self:__initBase(Widget(x, y, width, height, true))
    self.color = color or 0xFFFFFF
end)

Panel.type = "panel"
Panel.focusable = false

function Panel:update(gpu)
    gpu.setBackground(self.color)
    gpu.fill(1, 1, self.width, self.height, " ")
end

function Panel:setColor(color)
    self.color = color
    self.shouldUpdate = true
end

return Panel