local XTemple2EditorControl = require("XModule/XTemple2/XTemple2EditorControl")

---@class XTemple2EditorBlockControl : XTemple2EditorControl
---@field private _Model XTemple2Model
local XTemple2EditorBlockControl = XClass(XTemple2EditorControl, "XTemple2EditorBlockControl")

function XTemple2EditorBlockControl:SetBlockBeingEdited(block)
    if block then
        local game = self:GetGame()
        game:GetMap():InitFromBlock(block)
        XTemple2EditorControl.SetBlockBeingEdited(self, block)
    end
end

function XTemple2EditorBlockControl:ConfirmBlockBeingEdited()
    local block = self._BlockBeingEdited
    if block then
        local map = self:GetGame():GetMap()
        block:SetGridsFromMap(map)
    end
end

return XTemple2EditorBlockControl