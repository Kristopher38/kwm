local utils = require("utils")
local HWBuffer = require("HWBuffer")
local component = require("component")
local defaultGpu = component.gpu

local Renderable = utils.makeClass(function(self, sizex, sizey, posx, posy, buffered, gpuProxy)
    self.sizex = sizex
    self.sizey = sizey
    self.posx = posx
    self.posy = posy
    self.gpu = gpuProxy and gpuProxy or defaultGpu
    self.buffered = buffered
    self.shouldUpdate = false
    self.parent = nil
    self.focused = nil
    if buffered then
        self.gpuBuf = HWBuffer(self.gpu, sizex, sizey)
    end
    self.children = {}
end)

Renderable.type = "renderable"
--Renderable.focusable = false

function Renderable:setPos(x, y)
    -- TODO: repaint area that was previously covered by the widget in a saner manner
    self.gpuBuf:markAsDirty()
    local parent = self.parent
    while parent do
        if parent.buffered then
            parent.gpuBuf:markAsDirty()
        end
        for i = 1, #parent.children do
            if parent.children[i].buffered then
                parent.children[i].gpuBuf:markAsDirty()
            end
        end
        parent = parent.parent
    end

    self.posx = x
    self.posy = y
    self.shouldUpdate = true
end

function Renderable:setSize(x, y)
    self.sizex = x
    self.sizey = y
    self.gpuBuf:resize(x, y)
end

local function isPointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px < rx + rw and py >= ry and py < ry + rh
end

local function callHandlers(evt, child, evtType)
    if child.internalHandlers and type(child.internalHandlers[evtType]) == "function" then
        child.internalHandlers[evtType](child, evt)
    end
    if type(child[evtType]) == "function" then
        child[evtType](child, evt)
    end
end

function Renderable:draw(force, parentx, parenty, parenttx, parentty, parentsw, parentsh)
    if self.shouldUpdate then
        self.shouldUpdate = false
        self:updateWrapper()
    end
    local dirty = self.buffered and self.gpuBuf.dirty
    -- calculate widget's absolute position from relative position and parent offset
    parentx = parentx or self.posx
    parenty = parenty or self.posx
    parenttx = parenttx or self.posx
    parentty = parentty or self.posx
    parentsw = parentsw or self.sizex
    parentsh = parentsh or self.sizey
    local absolutex = self.posx + (parentx or 0)
    local absolutey = self.posy + (parenty or 0)

    local sx = absolutex < parenttx and parenttx - absolutex or 0
    local sy = absolutey < parentty and parentty - absolutey or 0
    local tx = absolutex > parenttx and absolutex or parenttx
    local ty = absolutey > parentty and absolutey or parentty
    local sw = absolutex < parentx and math.max(0, math.min(self.sizex - sx, parenttx + parentsw - tx)) or math.max(0, math.min(self.sizex, parenttx + parentsw - tx))
    local sh = absolutey < parenty and math.max(0, math.min(self.sizey - sy, parentty + parentsh - ty)) or math.max(0, math.min(self.sizey, parentty + parentsh - ty))

    if self.buffered and (self.gpuBuf.dirty or force) then
        if self.type == "panel" then
            --print(string.format("parentx: %d, parenty: %d, self.sizex: %d, self.sizey: %d, self.posx: %d, self.posy: %d, absolutex: %d, absolutey: %d, tx: %d, ty: %d, sx: %d, sy: %d, sw: %d, sh: %d\n",
            --  parentx, parenty, self.sizex, self.sizey, self.posx, self.posy, absolutex, absolutey, tx, ty, sx, sy, sw, sh))
        end
        self.gpuBuf:draw(tx + 1, ty + 1, sw, sh, sy + 1, sx + 1)
    end
    for i = 1, #self.children do
        self.children[i]:draw(force or dirty, absolutex, absolutey, tx, ty, sw, sh)
    end
end

function Renderable:destroy()
    for i = 1, #self.children do
        self.children[i]:destroy()
    end
    if self.buffered then
        self.gpuBuf:destroy()
    end
end

function Renderable:addChild(child)
    child.parent = self
    self.children[#self.children+1] = child
    child:updateWrapper()
end

function Renderable:propagateEvent(ws, evt, absolutex, absolutey)
    for i = 1, #self.children do
        local child = self.children[i]
        -- calculate child's absolute position from it's relative position and parent offset
        -- if absolutex and absolutey are missing assume we're in toplevel container (usually Workspace)
        local childAbsx = child.posx + (absolutex or self.posx)
        local childAbsy = child.posy + (absolutey or self.posy)
        local targeted = evt.x and evt.y and isPointInRect(evt.x, evt.y, childAbsx, childAbsy, child.sizex, child.sizey)

        if targeted then
            evt.localx = evt.x - childAbsx
            evt.localy = evt.y - childAbsy
            child:propagateEvent(ws, evt, childAbsx, childAbsy)
            if evt.skip then
                return
            end
        end

        if evt.type == "touch" then
            if not targeted and child.focused then
                child:propagateEvent(ws, evt, childAbsx, childAbsy)
                callHandlers(evt, child, "onBlur")
                child.focused = false
                --ws.focusedWidgets[child] = nil
            elseif targeted and child.focusable and not child.focused then
                child.focused = true
                --ws.focusedWidgets[child] = child
                callHandlers(evt, child, "onFocus")
            end
            
            if targeted then
                callHandlers(evt, child, "onClick")
            end
        elseif evt.type == "drop" then
            child:propagateEvent(ws, evt, childAbsx, childAbsy)
            if targeted then
                callHandlers(evt, child, "onRelease")
            elseif evt.startDrag.widget == child then
                callHandlers(evt, evt.startDrag.widget, "onRelease")
            end
        end

        -- first drag event
        if evt.prevDrag and isPointInRect(evt.prevDrag.x, evt.prevDrag.y, childAbsx, childAbsy, child.sizex, child.sizey) then
            if evt.type == "drag" or evt.type == "dragStart" then
                callHandlers(evt, child, "onStartDrag")
            end
            if evt.type == "dragStart" then
                -- guarantee only downmost widget in the hierarchy as being dragged
                if not evt.startDrag.widget then
                    evt.startDrag.widget = child
                end
            end
        end
        if evt.type == "key_down" then
            child:propagateEvent(ws, evt, childAbsx, childAbsy)
            if child.focused then
                callHandlers(evt, child, "onKeyDown")
            end
        end
    end
end

function Renderable:updateWrapper()
    self.gpuBuf:select()
    self:update(self.gpu)
    self.gpu.setActiveBuffer(0)
    self.gpuBuf:markAsDirty()
end

function Renderable:startDraw()
    self.gpuBuf:select()
end

function Renderable:endDraw()
    self.gpu.setActiveBuffer(0)
    self.gpuBuf:markAsDirty()
end

-- pure virtual function - inheriting classes should override this and implement widget drawing in it
function Renderable:update() end

return Renderable