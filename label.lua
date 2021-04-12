local utils = require("utils")
local Renderable = require("renderable")

local Label = utils.makeClass(function(self, posx, posy, text, fgcolor, bgcolor)
    self:__initBase(Renderable(#(text or ""), 1, posx, posy, true))
    self.text = text or ""
    self.fgcolor = fgcolor or 0xFFFFFF
    self.bgcolor = bgcolor or 0x000000
    self:update()
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

function Label:update()
    self:startDraw()
    local gpu = self.gpu
    gpu.setForeground(self.fgcolor)
    gpu.setBackground(self.bgcolor)
    gpu.set(1, 1, self.text)
    self:endDraw()
end

return Label