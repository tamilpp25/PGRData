---@class XUiGoldenMinerReportGrid : XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerReportGrid = XClass(XUiNode, "XUiGoldenMinerReportGrid")

function XUiGoldenMinerReportGrid:Refresh(icon, txtScore)
    if self.RImgTool then
        if string.IsNilOrEmpty(icon) then
            self.RImgTool.gameObject:SetActiveEx(false)
        else
            self.RImgTool.gameObject:SetActiveEx(true)
            self.RImgTool:SetRawImage(icon)
        end
    end

    if self.TxtTool then
        if string.IsNilOrEmpty(txtScore) then
            self.TxtTool.gameObject:SetActiveEx(false)
        else
            self.TxtTool.gameObject:SetActiveEx(true)
            self.TxtTool.text = txtScore
        end
    end
end

return XUiGoldenMinerReportGrid