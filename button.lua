local utils = require("utils")
local Widget = require("widget")

local Button = utils.makeClass(function(self, x, y, width, height, label, releasedColor, pressedColor, textBgColor, textFgColor)
    self:__initBase(Widget(x, y, width, height, true))
    self.label = label or ""
    self.textFgColor = 0xFFFFFF
    self.textBgColor = 0x000000
    self.relasedColor = 0xAA0000
    self.pressedColor = 0xFF0000
    self.pressed = false
    self.internalHandlers = {
        onClick = self.internalOnClick,
        onRelease = self.internalOnRelease
    }
end)

Button.type = "button"
Button.focusable = true

function Button:update(gpu)
    gpu.setBackground(self.pressed and self.pressedColor or self.relasedColor)
    gpu.fill(1, 1, self.width, self.height, " ")
    gpu.setBackground(self.textBgColor)
    gpu.setForeground(self.textFgColor)
    gpu.set((self.width - #self.label) // 2 + 1, self.height // 2 + 1, self.label)
end

function Button:internalOnClick(evt)
    self.pressed = true
    self.shouldUpdate = true
end

function Button:internalOnRelease(evt)
    self.pressed = false
    self.shouldUpdate = true
end

return Button