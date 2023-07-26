---@class XUiReformListPanelStageGrid
local XUiReformListPanelStageGrid = XClass(nil, "XUiReformListPanelStageGrid")

function XUiReformListPanelStageGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiReformListPanelStageGrid:Update(icon)
    self.RImgIcon:SetRawImage(icon)
end

return XUiReformListPanelStageGrid
