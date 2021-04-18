local utils = require("utils")
local Renderable = require("renderable")

local Button = utils.makeClass(function(self, sizex, sizey, posx, posy, label, releasedColor, pressedColor, textBgColor, textFgColor)
    self:__initBase(Renderable(sizex, sizey, posx, posy, true))
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
    gpu.fill(1, 1, self.sizex, self.sizey, " ")
    gpu.setBackground(self.textBgColor)
    gpu.setForeground(self.textFgColor)
    gpu.set((self.sizex - #self.label) // 2 + 1, self.sizey // 2 + 1, self.label)
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