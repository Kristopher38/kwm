local utils = require("utils")
local Renderable = require("renderable")

local Panel = utils.makeClass(function(self, sizex, sizey, posx, posy, color)
    self:__initBase(Renderable(sizex, sizey, posx, posy, true))
    self.color = color or 0xFFFFFF
    self:update()
end)

Panel.type = "panel"
Panel.focusable = false

function Panel:update()
    self:startDraw()

    local gpu = self.gpu
    gpu.setBackground(self.color)
    gpu.fill(1, 1, self.sizex, self.sizey, " ")

    self:endDraw()
end

function Panel:setColor(color)
    self.color = color
    self.shouldUpdate = true
end

return Panel