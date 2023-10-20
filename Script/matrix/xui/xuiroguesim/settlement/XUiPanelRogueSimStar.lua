---@class XUiPanelRogueSimStar : XUiNode
---@field private _Control XRogueSimControl
---@field private Parent XUiRogueSimSettlement
local XUiPanelRogueSimStar = XClass(XUiNode, "XUiPanelRogueSimStar")

function XUiPanelRogueSimStar:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    ---@type XUiGridCommon[]
    self.GridRewardList = {}
end

function XUiPanelRogueSimStar:Refresh()
    local stageId = self._Control:GetStageSettleStageId()
    if not XTool.IsNumberValid(stageId) then
        return
    end
    self.StageId = stageId
    self.IsStageFinished = self._Control:CheckIsStageFinishedSettle()
    self:RefreshFinishReward()
    self:RefreshStarReward()
end

-- 刷新首通奖励
function XUiPanelRogueSimStar:RefreshFinishReward()
    local rewardId = self._Control:GetRogueSimStageFirstFinishReward(self.StageId)
    local haveReward = XTool.IsNumberValid(rewardId)
    self.FinishReward.gameObject:SetActiveEx(haveReward)
    if not haveReward then
        return
    end
    -- 通关
    local isPass = self._Control:CheckStageIsPass(self.StageId)
    self.FinishReward:GetObject("TxtTitleYes").gameObject:SetActiveEx(isPass)
    self.FinishReward:GetObject("TxtTitleNo").gameObject:SetActiveEx(not isPass)
    -- 奖励
    local rewards = XRewardManager.GetRewardList(rewardId)
    if not self.FinishRewardGrid then
        local go = self.FinishReward:GetObject("GridReward")
        self.FinishRewardGrid = XUiGridCommon.New(self.Parent, go)
    end
    self.FinishRewardGrid:Refresh(rewards[1])
    self.FinishRewardGrid:SetReceived(isPass)
end

function XUiPanelRogueSimStar:HideStarReward()
    self.StarReward1.gameObject:SetActiveEx(false)
    self.StarReward2.gameObject:SetActiveEx(false)
    self.StarReward3.gameObject:SetActiveEx(false)
end

-- 刷新星级奖励
function XUiPanelRogueSimStar:RefreshStarReward()
    self:HideStarReward()
    -- 关卡记录三星达成情况
    local starMask = self._Control:GetStageRecordStarMask(self.StageId)
    local _, map = self._Control:GetStageStarCount(starMask)
    -- 奖励Ids
    local rewardIds = self._Control:GetRogueSimStageStarRewardIds(self.StageId)
    -- 描述
    local descs = self._Control:GetRogueSimStageStarDescs(self.StageId)
    -- 条件
    local starConditions = self._Control:GetRogueSimStageStarConditions(self.StageId)
    for i, conditionId in ipairs(starConditions) do
        -- 描述
        local desc = descs[i]
        -- 奖励
        local rewardId = rewardIds[i]
        -- 当前关卡条件是否完成
        local isConditionFinished = self._Control:GetStageSettleStarConditionFinished(conditionId)
        -- 是否已领取奖励
        local isGetReward = map[i]

        local uiObj = self["StarReward" .. i]
        uiObj.gameObject:SetActiveEx(true)
        uiObj:GetObject("TxtTitleYes").gameObject:SetActiveEx(isConditionFinished and self.IsStageFinished)
        uiObj:GetObject("TxtTitleNo").gameObject:SetActiveEx(not isConditionFinished or not self.IsStageFinished)
        uiObj:GetObject("TxtTitleYes").text = desc
        uiObj:GetObject("TxtTitleNo").text = desc
        local rewards = XRewardManager.GetRewardList(rewardId)
        local rewardGrid = self.GridRewardList[i]
        if not rewardGrid then
            local go = uiObj:GetObject("GridReward")
            rewardGrid = XUiGridCommon.New(self.Parent, go)
            self.GridRewardList[i] = rewardGrid
        end
        rewardGrid:Refresh(rewards[1])
        rewardGrid:SetReceived(isGetReward)
    end
end

function XUiPanelRogueSimStar:OnBtnCloseClick()
    self.Parent:OpenPanelSettle()
end

return XUiPanelRogueSimStar
