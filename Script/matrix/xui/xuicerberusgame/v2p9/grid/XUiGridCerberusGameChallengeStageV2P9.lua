---@class XUiGridCerberusGameChallengeStageV2P9
local XUiGridCerberusGameChallengeStageV2P9 = XClass(XUiNode, "XUiGridCerberusGameChallengeStageV2P9")

function XUiGridCerberusGameChallengeStageV2P9:Refresh(stageId)
    self.StageId = stageId
    local xStage = XMVCA.XCerberusGame:GetXStageById(stageId)
    self.XStage = xStage

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.Text.text = stageCfg.Name
    self.Bg:SetRawImage(stageCfg.Icon)
    self.PanelComplete.gameObject:SetActiveEx(xStage:GetIsPassed())
end

return XUiGridCerberusGameChallengeStageV2P9