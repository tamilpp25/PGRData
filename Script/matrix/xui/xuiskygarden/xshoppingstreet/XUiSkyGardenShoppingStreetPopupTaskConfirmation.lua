---@class XUiSkyGardenShoppingStreetPopupTaskConfirmation : XLuaUi
---@field BtnClose XUiComponent.XUiButton
---@field BtnYes XUiComponent.XUiButton
---@field BtnCancel XUiComponent.XUiButton
---@field TxtDetail UnityEngine.UI.Text
---@field TxtTitle UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetPopupTaskConfirmation = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetPopupTaskConfirmation")

--region 生命周期
function XUiSkyGardenShoppingStreetPopupTaskConfirmation:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetPopupTaskConfirmation:OnStart(params)
    self.TxtDetail.text = params.Tips
    self.CancelCallback = params.CancelCallback
    self.SureCallback = params.SureCallback

    if not string.IsNilOrEmpty(params.Title) then
        self.TxtTitle.text = params.Title
    else
        self.TxtTitle.text = XMVCA.XBigWorldService:GetText("CommmonTipsTitle")
    end
    if not string.IsNilOrEmpty(params.CancelText) then
        self.BtnCancel:SetNameByGroup(0, params.CancelText)
    end
    if not string.IsNilOrEmpty(params.SureText) then
        self.BtnYes:SetNameByGroup(0, params.SureText)
    end
end
--endregion
function XUiSkyGardenShoppingStreetPopupTaskConfirmation:OnDoCancel()
    self:Close()
    if self.CancelCallback then self.CancelCallback() end
end

--region 按钮事件
function XUiSkyGardenShoppingStreetPopupTaskConfirmation:OnBtnCloseClick()
    self:OnDoCancel()
end

function XUiSkyGardenShoppingStreetPopupTaskConfirmation:OnBtnYesClick()
    self:Close()
    if self.SureCallback then self.SureCallback() end
end

function XUiSkyGardenShoppingStreetPopupTaskConfirmation:OnBtnCancelClick()
    self:OnDoCancel()
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetPopupTaskConfirmation:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnYes.CallBack = function() self:OnBtnYesClick() end
    self.BtnCancel.CallBack = function() self:OnBtnCancelClick() end
end
--endregion

return XUiSkyGardenShoppingStreetPopupTaskConfirmation
