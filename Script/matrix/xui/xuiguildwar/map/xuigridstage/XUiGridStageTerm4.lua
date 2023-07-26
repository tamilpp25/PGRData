local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")

-- 四期Boss
---@class XUiGridStageTerm4:XUiGridStage
local XUiGridStageTerm4 = XClass(XUiGridStage, "XUiGridStageTerm4")

function XUiGridStageTerm4:OnBtnStageClick(selectedNodeId)
    if self.IsPathEdit then
        self.Base:AddPath(self.StageNode:GetId(), self)
    else
        if self.StageNode:GetIsPlayerNode() then
            XLuaUiManager.Open("UiGuildWarTerm4Panel", self.StageNode)
        else
            XLuaUiManager.Open("UiGuildWarStageDetail", self.StageNode, false)
        end
    end
end

return XUiGridStageTerm4