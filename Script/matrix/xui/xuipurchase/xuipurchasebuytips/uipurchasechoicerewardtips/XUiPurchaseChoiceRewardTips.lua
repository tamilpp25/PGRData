--- 自选礼包的详情页弹窗
---@class XUiPurchaseChoiceRewardTips: XLuaUi
local XUiPurchaseChoiceRewardTips = XLuaUiManager.Register(XLuaUi, 'UiPurchaseChoiceRewardTips')

function XUiPurchaseChoiceRewardTips:OnAwake()
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
end

function XUiPurchaseChoiceRewardTips:OnStart()
    self.Title.text = XUiHelper.ReadTextWithNewLine('PurchaseSelfChoiceTitle')
    self.TxtRule.text = XUiHelper.ReadTextWithNewLine('PurchaseSelfChoiceDesc')
end


return XUiPurchaseChoiceRewardTips