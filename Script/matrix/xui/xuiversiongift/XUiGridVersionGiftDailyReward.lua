local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--- 每日奖励领取的UI
---@class XUiGridVersionGiftDailyReward: XUiNode
---@field private _Control XVersionGiftControl
local XUiGridVersionGiftDailyReward = XClass(XUiNode, 'XUiGridVersionGiftDailyReward')

function XUiGridVersionGiftDailyReward:OnStart()
    self.Btn.CallBack = handler(self, self.OnBtnClick)
end

function XUiGridVersionGiftDailyReward:Refresh()
    local isGot = self._Control:GetIsGotDailyGiftReward()
    
    if not self.GridReward then
        self.GridReward = XUiGridCommon.New(self.Parent, self.Grid256New)
    end
    
    local rewardId = self._Control:GetActivityDailyGiftRewardId()

    if XTool.IsNumberValid(rewardId) then
        local rewardList = XRewardManager.GetRewardList(rewardId)
        self.GridReward:Refresh(rewardList[1])
        self.GridReward:SetReceived(isGot)
    end
    
    self.Btn:ShowReddot(not isGot)
end

function XUiGridVersionGiftDailyReward:OnBtnClick()
    local isGot = self._Control:GetIsGotDailyGiftReward()

    if isGot then
        self.GridReward:OnBtnClickClick()
        return
    else
        self._Control:SetTickoutLock(true)
        XMVCA.XVersionGift:DoVersionGiftGetProgressRewardRequest(XEnumConst.VersionGift.RewardType.DailyReward, function(rewardList)
            self:Refresh()
            XUiManager.OpenUiObtain(rewardList, nil, function()
                self._Control:SetTickoutLock(false)
            end)
        end)
        return
    end
end

return XUiGridVersionGiftDailyReward