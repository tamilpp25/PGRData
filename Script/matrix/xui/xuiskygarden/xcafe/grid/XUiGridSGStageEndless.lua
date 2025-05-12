---@class XUiGridSGStageEndless : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiPanelSGStageList
---@field _Control XSkyGardenCafeControl
local XUiGridSGStageEndless = XClass(XUiNode, "XUiGridSGStageEndless")

function XUiGridSGStageEndless:OnStart()
    self:InitCb()
    self:InitView()
end

function XUiGridSGStageEndless:InitCb()
    self.BtnGiveup.CallBack = function() 
        self:OnBtnGiveupClick()
    end
end

function XUiGridSGStageEndless:InitView()
end

function XUiGridSGStageEndless:Refresh()
    local stageId = self._Control:GetInChallengeStage()
    if stageId and stageId > 0 then
        self.PanelOngoing.gameObject:SetActiveEx(true)
        self.PanelNormal.gameObject:SetActiveEx(false)
        local info = self._Control:GetStageInfo(stageId)
        self.TxtOngoing.text = info:GetScore()
    else
        self.PanelOngoing.gameObject:SetActiveEx(false)
        self.PanelNormal.gameObject:SetActiveEx(true)
        self.TxtHistory.text = self._Control:GetHighestChallengeScore()
    end
end

function XUiGridSGStageEndless:OnBtnGiveupClick()
    --todo CodeMoon 放弃关卡
end

return XUiGridSGStageEndless
