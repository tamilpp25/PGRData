local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridFpsGameReward : XUiNode 活动章节奖励
---@field Parent XUiFpsGameChapter
---@field _Control XFpsGameControl
local XUiGridFpsGameReward = XClass(XUiNode, "XUiGridFpsGameReward")

local Reward = XEnumConst.FpsGame.Reward

function XUiGridFpsGameReward:OnStart(chapterId, rewardConfig)
    self._ChapterId = chapterId
    self._RewardConfig = rewardConfig
    self._RewardItems = XRewardManager.GetRewardList(self._RewardConfig.RewardId)
    ---@type XUiGridCommon
    self._Item1 = XUiGridCommon.New(self.Parent, self.GridItem1)
    ---@type XUiGridCommon
    self._Item2 = XUiGridCommon.New(self.Parent, self.GridItem2)

    if self._RewardItems[1] then
        self._Item1:Refresh(self._RewardItems[1])
    else
        XLog.Error("RewardId:" .. self._RewardConfig.RewardId .. "配置错误 奖励不足两个")
    end
    if self._RewardItems[2] then
        self._Item2:Refresh(self._RewardItems[2])
    else
        XLog.Error("RewardId:" .. self._RewardConfig.RewardId .. "配置错误 奖励不足两个")
    end

    self.TxtValue.text = self._RewardConfig.Star
    self.BtnReceive.CallBack = handler(self, self.OnBtnReceiveClick)
end

function XUiGridFpsGameReward:Refresh()
    local cur = self._Control:GetProgress(self._ChapterId)
    if cur >= self._RewardConfig.Star then
        if self._Control:IsRewardGain(self._ChapterId, self._RewardConfig.Id) then
            self._State = Reward.Rewarded
        else
            self._State = Reward.CanReward
        end
    else
        self._State = Reward.None
    end

    self.BtnReceive.gameObject:SetActiveEx(self._State == Reward.CanReward)
    self.PanelEffect1.gameObject:SetActiveEx(self._State == Reward.CanReward)
    self.PanelEffect2.gameObject:SetActiveEx(self._State == Reward.CanReward)
    self._Item1:SetReceived(self._State == Reward.Rewarded)
    self._Item2:SetReceived(self._State == Reward.Rewarded)
    self.ImgPoint1.gameObject:SetActiveEx(self._State ~= Reward.None and self._ChapterId == XEnumConst.FpsGame.Story)
    self.ImgPointRed.gameObject:SetActiveEx(self._State ~= Reward.None and self._ChapterId == XEnumConst.FpsGame.Challenge)
    self.ImgPoint2.gameObject:SetActiveEx(self._State == Reward.None)
end

function XUiGridFpsGameReward:GetState()
    return self._State
end

function XUiGridFpsGameReward:OnBtnReceiveClick()
    self._Control:FpsGameGetChapterRewardRequest(self._ChapterId, function()
        self.Parent:RefreshReward()
    end)
end

return XUiGridFpsGameReward