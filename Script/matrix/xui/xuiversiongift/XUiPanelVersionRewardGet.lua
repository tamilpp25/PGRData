--- 版本奖励领取的详情界面
---@class XUiPanelVersionRewardGet: XUiNode
---@field private _Control XVersionGiftControl
local XUiPanelVersionRewardGet = XClass(XUiNode, 'XUiPanelVersionRewardGet')

function XUiPanelVersionRewardGet:OnStart()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.Close)
    self.BtnTongBlack.CallBack = handler(self, self.OnBtnGetClick)
end

function XUiPanelVersionRewardGet:OnEnable()
    self:Refresh()
end

function XUiPanelVersionRewardGet:Refresh()
    self._IsGot = self._Control:GetIsGotVersionGiftReward()

    local rewardId = self._Control:GetActivityVersionGiftRewardId()

    if XTool.IsNumberValid(rewardId) then
        local rewardList = XRewardManager.GetRewardList(rewardId)
        if self.TxtNum then
            self.TxtNum.text = CS.XTextManager.GetText("ShopGridCommonCount", rewardList[1].Count or 0)
        end

        if self.RImIcon then
            self.RImIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(rewardList[1].TemplateId))
        end
    end
    
    self.BtnTongBlack:SetButtonState(self._IsGot and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiPanelVersionRewardGet:OnBtnGetClick()
    if not self._IsGot then
        self._Control:SetTickoutLock(true)
        XMVCA.XVersionGift:DoVersionGiftGetProgressRewardRequest(XEnumConst.VersionGift.RewardType.VersionReward, function(rewardList)
            self.Parent:ClosePanelVersionGiftGet()
            XUiManager.OpenUiObtain(rewardList, nil, function() 
                self._Control:SetTickoutLock(false)
            end)
        end)
    end
end

return XUiPanelVersionRewardGet