local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridTurntableProgressReward : XUiNode
---@field Parent XUiTurntableMain
---@field _Control XTurntableControl
---@field Transform UnityEngine.Transform
local XUiGridTurntableProgressReward = XClass(XUiNode, "UiGridTurntableProgressReward")

function XUiGridTurntableProgressReward:OnStart()
    ---@type XUiGridCommon
    self._Grid = XUiGridCommon.New(self.Parent, self.Reward)
end

function XUiGridTurntableProgressReward:Init(index, rewardId, progress, isTopShow)
    self._RewardIndex = index
    self._RewardId = rewardId
    self._Progress = progress
    self._ForbidGain = false
    self._IsTopShow = isTopShow
    self:Update()
end

--- 检查是否需要置顶显示
function XUiGridTurntableProgressReward:CheckNeedTopShow()
    if self._IsTopShow then
        -- 如果没领取奖励则需要置顶
        return not self._HasGain
    end
end

function XUiGridTurntableProgressReward:CheckCanTopShow()
    return self._IsTopShow
end

function XUiGridTurntableProgressReward:Update()
    local rewardItems = XRewardManager.GetRewardList(self._RewardId)
    local reward = rewardItems[1]
    self._ItemId = reward.TemplateId
    self._Grid:Refresh(reward)
    self._Grid:SetProxyClickFunc(function()
        return self:OnClick()
    end)
    self._CanGain = self._Control:CanProgressRewardGain(self._RewardIndex)
    self._HasGain = self._Control:IsProgressRewardGain(self._RewardIndex)
    self.PanelEffect.gameObject:SetActiveEx(self._CanGain)
    self.ImgRe.gameObject:SetActiveEx(self._HasGain)
    self.TxtValue.text = self._Progress
end

---@return @是否继续执行显示逻辑
function XUiGridTurntableProgressReward:OnClick()
    if self._ForbidGain then
        return false -- 转盘正在旋转时不可领取奖励
    end
    if not self._CanGain or self._HasGain then
        return true
    end
    self._Control:RequestGainAccumulateReward(function(rewards)
        self.Parent:UpdateProgress()
        XUiManager.OpenUiObtain(rewards or {})
    end)
    return false
end

function XUiGridTurntableProgressReward:GetIsGain()
    return self._HasGain
end

function XUiGridTurntableProgressReward:SetForbidGain(bo)
    self._ForbidGain = bo
end

return XUiGridTurntableProgressReward