---@class XUiSkyGardenShoppingStreetPopupConfirmation : XLuaUi
---@field BtnClose XUiComponent.XUiButton
---@field BtnYes XUiComponent.XUiButton
---@field BtnCancel XUiComponent.XUiButton
---@field TxtDetail UnityEngine.UI.Text
---@field TxtTitle UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetPopupConfirmation = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetPopupConfirmation")

--region 生命周期
function XUiSkyGardenShoppingStreetPopupConfirmation:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetPopupConfirmation:OnStart(params)
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
function XUiSkyGardenShoppingStreetPopupConfirmation:OnDoCancel()
    self:Close()
    if self.CancelCallback then self.CancelCallback() end
end

--region 按钮事件
function XUiSkyGardenShoppingStreetPopupConfirmation:OnBtnCloseClick()
    self:OnDoCancel()
end

function XUiSkyGardenShoppingStreetPopupConfirmation:OnBtnYesClick()
    self:Close()
    if self.SureCallback then self.SureCallback() end
end

function XUiSkyGardenShoppingStreetPopupConfirmation:OnBtnCancelClick()
    self:OnDoCancel()
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetPopupConfirmation:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnYes.CallBack = function() self:OnBtnYesClick() end
    self.BtnCancel.CallBack = function() self:OnBtnCancelClick() end
end
--endregion

return XUiSkyGardenShoppingStreetPopupConfirmation
