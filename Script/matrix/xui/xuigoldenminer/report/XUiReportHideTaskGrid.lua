---@class XUiReportHideTaskGrid
local XUiReportHideTaskGrid = XClass(nil, "XUiReportHideTaskGrid")

function XUiReportHideTaskGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GameObject:SetActiveEx(true)
end

function XUiReportHideTaskGrid:Refresh(isFinish)
    if self.Img02 then
        self.Img02.gameObject:SetActiveEx(not isFinish)
    end
end

return XUiReportHideTaskGrid