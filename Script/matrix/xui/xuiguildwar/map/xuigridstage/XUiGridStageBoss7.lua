local XUiGridStage = require("XUi/XUiGuildWar/Map/XUiGridStage/XUiGridStage")

--- 7期boss
---@class XUiGridStageBoss7: XUiGridStage
local XUiGridStageBoss7 = XClass(XUiGridStage, 'XUiGridStageBoss7')

function XUiGridStageBoss7:OnBtnStageClick()
    if self.IsPathEdit then
        self.Base:AddPath(self.StageNode:GetId(), self)
    else
        if self.StageNode:GetIsPlayerNode() then
            XLuaUiManager.Open("UiGuildWarBoss7Panel", self.StageNode)
        else
            XLuaUiManager.Open("UiGuildWarStageDetail", self.StageNode, false)
        end
    end
end

return XUiGridStageBoss7