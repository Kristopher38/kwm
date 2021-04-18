local utils = require("utils")
local Widget = require("widget")
local event = require("event")

local Input = utils.makeClass(function(self, sizex, sizey, posx, posy, placeholder, color, textBgColor, textFgColor)
    self:__initBase(Widget(sizex, sizey, posx, posy, true))
    self.placeholder = placeholder or ""
    self.text = ""
    self.color = color or 0x000000
    self.textFgColor = textFgColor or 0xFFFFFF
    self.textBgColor = textBgColor or 0x000000
    self.curPos = 0
    self.blinkState = false
    self.blinkInterval = 0.5
    self.internalHandlers = {
        onFocus = self.internalOnFocusClick,
        onClick = self.internalOnFocusClick,
        onBlur = self.internalOnBlur,
        onKeyDown = self.internalOnKeyDown,
    }
    self.blinkTimer = function()
        self.blinkState = not self.blinkState
        self.shouldUpdate = true
    end
    self.blinkTimerId = -1
end)

Input.type = "input"
Input.focusable = true

function Input:update(gpu)
    if #self.text > 0 or self.focused then
        gpu.setBackground(self.textBgColor)
        gpu.setForeground(self.textFgColor)
        gpu.set(1, 1, self.text)
        gpu.setBackground(self.color)
        gpu.set(#self.text + 1, 1, string.rep(" ", self.sizex - #self.text))
        
        if self.blinkState then
            -- inverted colors for cursor - this is correct
            gpu.setBackground(self.textFgColor)
            gpu.setForeground(self.textBgColor)
            if self.curPos < #self.text then
                gpu.set(self.curPos + 1, 1, string.sub(self.text, self.curPos + 1, self.curPos + 1))
            else
                gpu.set(self.curPos + 1, 1, " ")
            end
        end
    else
        gpu.setBackground(self.color)
        gpu.setForeground(0x808080) -- gray
        gpu.set(1, 1, self.placeholder .. string.rep(" ", self.sizex - #self.text))
    end
end

function Input:forceBlinkOn()
    if self.focused then
        event.cancel(self.blinkTimerId)
    end
    self.blinkTimerId = event.timer(self.blinkInterval, self.blinkTimer, math.huge)
    self.blinkState = true
end

function Input:internalOnFocusClick(evt)
    self:forceBlinkOn()
    self.curPos = math.min(#self.text, evt.localx)
    self.shouldUpdate = true
end

function Input:internalOnBlur(evt)
    event.cancel(self.blinkTimerId)
    self.blinkState = false
    self.shouldUpdate = true
end

function Input:internalOnKeyDown(evt)
    self:forceBlinkOn()
    if evt.code == 14 then -- backspace
        self.text = #self.text >= self.curPos and
            string.sub(self.text, 1, math.max(0, self.curPos - 1)) .. string.sub(self.text, self.curPos + 1) or
            string.sub(self.text, 1, math.max(0, #self.text - 1))
        self.curPos = math.max(0, self.curPos - 1)
    elseif evt.code == 203 then -- left arrow
        self.curPos = math.max(0, self.curPos - 1)
    elseif evt.code == 205 then -- right arrow
        self.curPos = math.min(#self.text, self.curPos + 1)
    else
        self.text = string.sub(self.text, 1, self.curPos) .. string.char(evt.char) .. string.sub(self.text, self.curPos + 1)
        self.curPos = self.curPos + 1
    end
    self.shouldUpdate = true
end

return Input