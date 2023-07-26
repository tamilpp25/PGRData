---@class XUiGridTurntableProgressReward : XUiNode
---@field Parent XUiTurntableMain
---@field _Control XTurntableControl
local XUiGridTurntableProgressReward = XClass(XUiNode, "UiGridTurntableProgressReward")

function XUiGridTurntableProgressReward:OnStart()
    ---@type XUiGridCommon
    self._Grid = XUiGridCommon.New(self.Parent, self.Reward)
end

function XUiGridTurntableProgressReward:Init(index, rewardId, progress)
    self._RewardIndex = index
    self._RewardId = rewardId
    self._Progress = progress
    self._ForbidGain = false
    self:Update()
end

function XUiGridTurntableProgressReward:Update()
    local rewardItems = XRewardManager.GetRewardList(self._RewardId)
    local reward = rewardItems[1]
    self._ItemId = reward.TemplateId
    self._Grid:Refresh(reward)
    self._Grid:SetProxyClickFunc(function()
        self:OnClick()
    end)
    self._CanGain = self._Control:CanProgressRewardGain(self._RewardIndex)
    self._HasGain = self._Control:IsProgressRewardGain(self._RewardIndex)
    self.PanelEffect.gameObject:SetActiveEx(self._CanGain)
    self.ImgRe.gameObject:SetActiveEx(self._HasGain)
    self.TxtValue.text = self._Progress
end

function XUiGridTurntableProgressReward:OnClick()
    if self._ForbidGain then
        return  -- 转盘正在旋转时不可领取奖励
    end
    if not self._CanGain or self._HasGain then
        XLuaUiManager.Open("UiTip", self._ItemId)
        return
    end
    self._Control:RequestGainAccumulateReward(function(rewards)
        self.Parent:UpdateProgress()
        XUiManager.OpenUiObtain(rewards or {})
    end)
end

function XUiGridTurntableProgressReward:GetIsGain()
    return self._HasGain
end

function XUiGridTurntableProgressReward:SetForbidGain(bo)
    self._ForbidGain = bo
end

return XUiGridTurntableProgressReward