---@class XUiPurchaseQuickBuy : XLuaUi
---@field BtnConfirm XUiComponent.XUiButton
---@field BtnCancel XUiComponent.XUiButton
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field TxtNumber1 UnityEngine.UI.Text
---@field TxtNumber2 UnityEngine.UI.Text
---@field TxtConsumeTips UnityEngine.UI.Text
---@field IconConsume1 UnityEngine.UI.RawImage
local XUiPurchaseQuickBuy = XLuaUiManager.Register(XLuaUi, "UiPurchaseQuickBuy")

function XUiPurchaseQuickBuy:Ctor()
	self._PayKey = nil
end

--region 生命周期
function XUiPurchaseQuickBuy:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiPurchaseQuickBuy:OnStart(payCount)
    local config, index = XDataCenter.PurchaseManager.GetPayConfigByDifferenceCount(payCount)

    if not config then
        self:Close()
        return
    end

    self._PayKey = config.Key
    self._Index = index
    self:_Refresh(payCount, config)
end
--endregion

--region 按钮事件
function XUiPurchaseQuickBuy:OnBtnConfirmClick()
	XEventManager.DispatchEvent(XEventId.EVENT_PURCHASE_QUICK_BUY_PAY)
    XDataCenter.PayManager.Pay(self._PayKey)
    self:Close()
end

function XUiPurchaseQuickBuy:OnBtnCancelClick()
	self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_PURCHASE_QUICK_BUY_SKIP, self._Index)
end

function XUiPurchaseQuickBuy:OnBtnTanchuangCloseClick()
	self:Close()
end

--endregion

--region 私有方法
function XUiPurchaseQuickBuy:_RegisterButtonClicks()
    --在此处注册按钮事件
	self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick, true)
	self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick, true)
	self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick, true)
end

function XUiPurchaseQuickBuy:_Refresh(payCount, config)
    self.TxtNumber1.text = XUiHelper.GetText("PayQuickBuyNumber", payCount)
    self.TxtNumber2.text = XUiHelper.GetText("PayQuickBuyNumber", config.Amount)
    self.IconConsume1:SetRawImage(XPurchaseConfigs.GetIconPathByIconName(config.Icon).AssetPath)
    self.TxtConsumeTips.text = XUiHelper.GetText("PayQuickBuyDesc", config.MoneyCard, config.Amount)
    self.BtnConfirm:SetNameByGroup(0, XUiHelper.GetText("PayQuickBuyAmount", config.Amount))
end
--endregion

return XUiPurchaseQuickBuy
