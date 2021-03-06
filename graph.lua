local utils = require("utils")
local Widget = require("widget")
local graphlib = require("OCGraphLib/graphlib")

local Graph = utils.makeClass(function(self, x, y, width, height, data, maxval)
    self:__initBase(Widget(x, y, width, height, true))
    self.data = data or {}
    self.maxval = maxval
end)

function Graph:setData(data)
    self.data = data
    self.shouldUpdate = true
end

function Graph:pushValue(val)
    graphlib.cycleTable(self.data, val)
    self.shouldUpdate = true
end

function Graph:update(gpu)
    graphlib.drawGraph(self.data, 1, 1, self.width, self.height, self.maxval)
end

return Graph