local utils = require("utils")

local HWBuffer = utils.makeClass(function(self, gpuProxy, width, height)
    self.width = width
    self.height = height
    self.gpu = gpuProxy
    self.bufferId = self.gpu.allocateBuffer(width, height)
    self.dirty = true
end)

function HWBuffer:draw(col, row, width, height, fromCol, fromRow, destination)
    self.gpu.bitblt(destination, col, row, width, height, self.bufferId, fromCol, fromRow)
    self.dirty = false
end

function HWBuffer:select()
    self.gpu.setActiveBuffer(self.bufferId)
end

function HWBuffer:resize(width, height)
    if self.width ~= width or self.height ~= height then
        local newBuffer = self.gpu.allocateBuffer(width, height)
        self.gpu.bitblt(newBuffer, 1, 1, self.width, self.height, self.bufferId)
        self.gpu.freeBuffer(self.bufferId)
        self.bufferId = newBuffer
        self.width = width
        self.height = height
        self.dirty = true
    end
end

function HWBuffer:markAsDirty()
    self.dirty = true
end

function HWBuffer:destroy()
    self.gpu.freeBuffer(self.bufferId)
end

return HWBuffer