local utils = require("utils")
local event = require("event")
local Renderable = require("renderable")
local component = require("component")
local defaultGpu = component.gpu
local inspect = require("inspect")

local Workspace = utils.makeClass(function(self, sizex, sizey, posx, posy, gpuProxy)
    gpuProxy = gpuProxy or defaultGpu
    local w, h = gpuProxy.getResolution()
    self:__initBase(Renderable(sizex or w, sizey or h, posx or 0, posy or 0, false, gpuProxy))
    self.running = false
    self.bgcolor = 0xFFFFFF
    self.focusedWidgets = {}
    self:update()
end)

Workspace.type = "workspace"
Workspace.focusable = false

function Workspace:start()
    self.running = true
    self:eventLoop()
end

function Workspace:eventLoop()
    local startDrag = {}
    local prevDrag = {}
    while self.running do
        local events = {}
        repeat
            local evt = table.pack(event.pull(0))
            local signal = evt[1]
            if signal == "touch" then
                local parsed = {
                    type = evt[1],
                    screenAddress = evt[2],
                    x = evt[3] - 1,
                    y = evt[4] - 1,
                    button = evt[5],
                    playerName = evt[6],
                    dragging = false,
                    skip = false
                }
                parsed.localx = parsed.x
                parsed.localy = parsed.y
                events[#events+1] = parsed
                startDrag[parsed.playerName] = parsed
                prevDrag[parsed.playerName] = parsed
            elseif signal == "drop" then
                local parsed = {
                    type = evt[1],
                    screenAddress = evt[2],
                    x = evt[3] - 1,
                    y = evt[4] - 1,
                    button = evt[5],
                    playerName = evt[6],
                    startDrag = startDrag[evt[6]],
                    skip = false
                }
                events[#events+1] = parsed
                startDrag[parsed.playerName] = nil
                prevDrag[parsed.playerName] = parsed
            elseif signal == "drag" then
                local parsed = {
                    type = evt[1],
                    screenAddress = evt[2],
                    x = evt[3] - 1,
                    y = evt[4] - 1,
                    button = evt[5],
                    playerName = evt[6],
                    startDrag = startDrag[evt[6]],
                    prevDrag = prevDrag[evt[6]],
                    skip = false
                }
                parsed.relativex = parsed.prevDrag.x - parsed.x
                parsed.relativey = parsed.prevDrag.y - parsed.y
                parsed.type = parsed.startDrag.dragging and parsed.type or "dragStart"
                parsed.startDrag.dragging = true
                prevDrag[parsed.playerName] = parsed
                events[#events+1] = parsed
            elseif signal == "key_down" then
                local parsed = {
                    type = evt[1],
                    keyboardAddress = evt[2],
                    char = evt[3],
                    code = evt[4],
                    playerName = evt[5]
                }
                events[#events+1] = parsed
            end
        until not signal

        -- call event handlers
        for i = 1, #events do
            self:propagateEvent(self, events[i])
        end
        -- draw every child
        self:draw()
    end
end

function Workspace:update()
    --self:startDraw()
    local w, h = self.gpu.getResolution()
    self.gpu.setBackground(0x000000)
    self.gpu.fill(1, 1, w, h, " ")
    --self:endDraw()
end

function Workspace:stop()
    self.running = false
    self:destroy()
end

return Workspace