local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridAreaWarSpecialRoleReward = XClass(nil, "XUiGridAreaWarSpecialRoleReward")

function XUiGridAreaWarSpecialRoleReward:Ctor(ui, clickCb, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)

    self.PanelDot = self.Transform:FindTransform("PanelDot")
    self.PanelDotEmpty = self.Transform:FindTransform("PanelDotEmpty")

    if self.BtnClick then
        self.BtnClick.CallBack = handler(self, self.OnClick)
    end
end

function XUiGridAreaWarSpecialRoleReward:Refresh(rewardId)
    self.RewardId = rewardId

    --需求解锁数量
    local requireCount = XAreaWarConfigs.GetSpecialRoleRewardUnlockCount(rewardId)
    self.TxtClearCount.text = requireCount
    self.TxtClearCountOn.text = requireCount

    --解锁状态
    local unlockCount = XDataCenter.AreaWarManager.GetUnlockSpecialRoleCount()
    local isClear = unlockCount >= requireCount
    self.TxtClearCountOn.gameObject:SetActiveEx(isClear)
    self.TxtClearCount.gameObject:SetActiveEx(not isClear)

    --奖励物品
    local realRewardId = XAreaWarConfigs.GetSpecialRoleRewardRewardId(rewardId)
    local rewardData = XRewardManager.GetRewardList(realRewardId)
    local reward = rewardData[1] --只显示第一个
    self.RewardGrid = self.RewardGrid or XUiGridCommon.New(self.RootUi, self.GridCommon)
    self.RewardGrid:Refresh(reward)

    --已领取
    local hasGot = XDataCenter.AreaWarManager.IsSpecialRoleRewardHasGot(rewardId)
    self.PanelFinish.gameObject:SetActiveEx(hasGot)

    --可领取
    local canGet = XDataCenter.AreaWarManager.IsSpecialRoleRewardCanGet(rewardId)
    self.PanelEffect.gameObject:SetActiveEx(canGet and not hasGot)

    --进度条（只算当前这一小格的）
    local fillAmount = 0
    local currentFinish = false --当前一小格的进度是否完成
    local lastRewardUnlockCount = XAreaWarConfigs.GetSpecialRoleRewardLastUnlockCount(rewardId)
    local current = unlockCount - lastRewardUnlockCount
    if current > 0 then
        --当前一小格的进度
        local total = requireCount - lastRewardUnlockCount
        fillAmount = current ~= 0 and current / total or 0
        currentFinish = current >= total
    end
    self.ImgFillAmount.fillAmount = fillAmount
    self.PanelDot.gameObject:SetActiveEx(currentFinish)
    self.PanelDotEmpty.gameObject:SetActiveEx(not currentFinish)
end

function XUiGridAreaWarSpecialRoleReward:OnClick()
    if self.ClickCb then
        self.ClickCb(self.RewardId)
    end
end

return XUiGridAreaWarSpecialRoleReward
