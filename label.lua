local utils = require("utils")
local Widget = require("widget")

local Label = utils.makeClass(function(self, x, y, text, fgcolor, bgcolor)
    self:__initBase(Widget(x, y, #(text or ""), 1, true))
    self.text = text or ""
    self.fgcolor = fgcolor or 0xFFFFFF
    self.bgcolor = bgcolor or 0x000000
end)

Label.type = "label"
Label.focusable = false

function Label:setText(text)
    self.text = text or ""
    self:setSize(#self.text, 1)
    self.shouldUpdate = true
end

function Label:setFgColor(color)
    self.fgcolor = color
    self.shouldUpdate = true
end

function Label:setBgColor(color)
    self.bgcolor = color
    self.shouldUpdate = true
end

function Label:update(gpu)
    gpu.setForeground(self.fgcolor)
    gpu.setBackground(self.bgcolor)
    gpu.set(1, 1, self.text)
end

return Label