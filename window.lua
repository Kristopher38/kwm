local utils = require("utils")
local Widget = require("widget")
local component = require("component")
local inspect = require("inspect")

local Window = utils.makeClass(function(self, sizex, sizey, posx, posy, title)
    self:__initBase(Widget(sizex, sizey, posx, posy, true))
    self.title = title or ""
    self.internalHandlers = {
        onStartDrag = self.internalOnStartDrag,
        onDrag = self.internalOnDrag,
        onRelease = self.internalOnDrop
    }
end)

Window.type = "window"
Window.focusable = true

function Window:setTitle(str)
    self.title = str or ""
    self.shouldUpdate = true
end

function Window:update(gpu)
    gpu.setBackground(0xB4B4B4)
    gpu.fill(1, 1, self.sizex, self.sizey, " ")
    gpu.setBackground(0x143CC8)
    gpu.setForeground(0xFFFFFF)
    gpu.set(1, 1, " " .. self.title .. string.rep(" ", self.sizex - #self.title))
end

function Window:internalOnDrop(evt)
    self.isDragged = false
    evt.skip = true
end

function Window:internalOnDrag(evt)
    if evt.prevDrag.y == self.posy then
        self:setPos(self.posx - evt.relativex, self.posy - evt.relativey)
        self.isDragged = true
        evt.skip = true
    end
end

function Window:internalOnStartDrag(evt)
    self:internalOnDrag(evt)
end

return Window