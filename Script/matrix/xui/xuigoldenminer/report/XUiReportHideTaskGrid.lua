---@class XUiReportHideTaskGrid : XUiNode
local XUiReportHideTaskGrid = XClass(XUiNode, "XUiReportHideTaskGrid")

function XUiReportHideTaskGrid:Refresh(isFinish)
    if self.Img02 then
        self.Img02.gameObject:SetActiveEx(not isFinish)
    end
end

return XUiReportHideTaskGrid