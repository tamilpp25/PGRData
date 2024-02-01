---@class XUiGoldenMinerReportGrid : XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerReportGrid = XClass(XUiNode, "XUiGoldenMinerReportGrid")

function XUiGoldenMinerReportGrid:Refresh(icon, txtScore)
    if self.RImgTool then
        self.RImgTool:SetRawImage(icon)
    end
    if self.TxtTool then
        self.TxtTool.text = txtScore
    end
end

return XUiGoldenMinerReportGrid