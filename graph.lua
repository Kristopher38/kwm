local utils = require("utils")
local Renderable = require("renderable")
local graphlib = require("OCGraphLib/graphlib")

local Graph = utils.makeClass(function(self, sizex, sizey, posx, posy, data, maxval)
    self:__initBase(Renderable(sizex, sizey, posx, posy, true))
    self.data = data or {}
    self.maxval = maxval
    self:update()
end)

function Graph:setData(data)
    self.data = data
    self.shouldUpdate = true
end

function Graph:pushValue(val)
    graphlib.cycleTable(self.data, val)
    self.shouldUpdate = true
end

function Graph:update()
    self:startDraw()

    graphlib.drawGraph(self.data, 1, 1, self.sizex, self.sizey, self.maxval)

    self:endDraw()
end

return Graph