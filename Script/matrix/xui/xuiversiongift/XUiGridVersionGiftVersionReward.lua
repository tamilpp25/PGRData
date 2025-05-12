local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--- 版本奖励
---@class XUiGridVersionGiftVersionReward: XUiNode
---@field private _Control XVersionGiftControl
---@field GridReward XUiGridCommon
local XUiGridVersionGiftVersionReward = XClass(XUiNode, 'XUiGridVersionGiftVersionReward')

function XUiGridVersionGiftVersionReward:OnStart()
    self.Btn.CallBack = handler(self, self.OnBtnClick)
end

function XUiGridVersionGiftVersionReward:Refresh()
    local isGot = self._Control:GetIsGotVersionGiftReward()

    if not self.GridReward then
        self.GridReward = XUiGridCommon.New(self.Parent, self.Grid256New)
    end

    local rewardId = self._Control:GetActivityVersionGiftRewardId()

    if XTool.IsNumberValid(rewardId) then
        local rewardList = XRewardManager.GetRewardList(rewardId)
        self.GridReward:Refresh(rewardList[1])
        self.GridReward:SetReceived(isGot)
    end

    self.Btn:ShowReddot(not isGot)
end

function XUiGridVersionGiftVersionReward:OnBtnClick()
    self.Parent:OpenPanelVersionGiftGet()
end

return XUiGridVersionGiftVersionReward