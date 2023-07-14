---@class XUiGridMapBg
local XUiGridMapBg = XClass(nil, "XUiGridMapBg")

function XUiGridMapBg:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
end

function XUiGridMapBg:SetRoundFinish(finished)
    self.StateNormal.gameObject:SetActiveEx(not finished)
    --self.StateStateFinish.gameObject:SetActiveEx(finished)
end

return XUiGridMapBg