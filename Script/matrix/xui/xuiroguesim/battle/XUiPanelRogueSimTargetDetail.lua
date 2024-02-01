---@class XUiPanelRogueSimTargetDetail : XUiNode
---@field private _Control XRogueSimControl
local XUiPanelRogueSimTargetDetail = XClass(XUiNode, "XUiPanelRogueSimTargetDetail")

function XUiPanelRogueSimTargetDetail:OnStart()
    self.StageId = self._Control:GetCurStageId()
    self:RegisterUiEvents()
end

function XUiPanelRogueSimTargetDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

function XUiPanelRogueSimTargetDetail:Refresh()
    self:RefreshFinishReward()
    self:RefreshStarReward()
end

-- 刷新首通奖励
function XUiPanelRogueSimTargetDetail:RefreshFinishReward()
    local rewardId = self._Control:GetRogueSimStageFirstFinishReward(self.StageId)
    local haveReward = XTool.IsNumberValid(rewardId)
    self.FinishReward.gameObject:SetActiveEx(haveReward)
    if not haveReward then
        return
    end

    local isPass = self._Control:CheckStageIsPass(self.StageId)
    self.FinishReward:GetObject("TxtTitleYes").gameObject:SetActiveEx(isPass)
    self.FinishReward:GetObject("TxtTitleNo").gameObject:SetActiveEx(not isPass)

    local rewards = XRewardManager.GetRewardList(rewardId)
    if not self.FinishRewardGrid then
        local go = self.FinishReward:GetObject("GridReward")
        self.FinishRewardGrid = XUiGridCommon.New(self.Parent, go)
    end
    self.FinishRewardGrid:Refresh(rewards[1])
    self.FinishRewardGrid:SetReceived(isPass)
end

-- 刷新三星奖励
function XUiPanelRogueSimTargetDetail:RefreshStarReward()
    self.StarReward1.gameObject:SetActiveEx(false)
    self.StarReward2.gameObject:SetActiveEx(false)
    self.StarReward3.gameObject:SetActiveEx(false)

    -- 关卡记录三星达成情况
    local starMask = self._Control:GetStageRecordStarMask(self.StageId)
    local count, map = self._Control:GetStageStarCount(starMask)

    -- 关卡记录三星达成情况
    local conditionIds = self._Control:GetRogueSimStageStarConditions(self.StageId)
    local rewardIds = self._Control:GetRogueSimStageStarRewardIds(self.StageId)
    local descs = self._Control:GetRogueSimStageStarDescs(self.StageId)
    for i, conditionId in ipairs(conditionIds) do
        local uiObj = self["StarReward"..i]
        local rewards = XRewardManager.GetRewardList(rewardIds[i])
        local desc = descs[i]
        local isPass = self._Control.ConditionSubControl:CheckCondition(conditionId) -- 当局内是否通过
        local isGetReward = map[i] -- 是否已获得奖励

        uiObj.gameObject:SetActiveEx(true)
        local txtTitleYes = uiObj:GetObject("TxtTitleYes")
        local txtTitleNo = uiObj:GetObject("TxtTitleNo")
        txtTitleYes.text = desc
        txtTitleNo.text = desc
        txtTitleYes.gameObject:SetActiveEx(isPass)
        txtTitleNo.gameObject:SetActiveEx(not isPass)

        local rewardGrid = self["StarRewardGrid"..i]
        if not rewardGrid then
            local go = uiObj:GetObject("GridReward")
            rewardGrid = XUiGridCommon.New(self.Parent, go)
            self["StarRewardGrid"..i] = rewardGrid
        end
        rewardGrid:Refresh(rewards[1])
        rewardGrid:SetReceived(isGetReward)
    end
end

return XUiPanelRogueSimTargetDetail
