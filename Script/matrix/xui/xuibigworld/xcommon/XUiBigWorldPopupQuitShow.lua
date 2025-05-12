---@class XUiBigWorldPopupQuitShow : XBigWorldUi
---@field BtnConfirm XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field TxtInfoNormal UnityEngine.UI.Text
---@field TxtTitle UnityEngine.UI.Text
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field BtnTips UnityEngine.UI.Toggle
---@field TxtTips UnityEngine.UI.Text
local XUiBigWorldPopupQuitShow = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupQuitShow")

local Operator = {
    Sure = 1,
    Cancel = 2,
    Close = 3,
}

function XUiBigWorldPopupQuitShow:OnAwake()
    self:_RegisterButtonClicks()
end

---@param data XBWPopupQuitConfirmData
function XUiBigWorldPopupQuitShow:OnStart(data)
    self._Data = data

    self:_RefreshTitle()
    self:_RefreshClick()
end

function XUiBigWorldPopupQuitShow:OnBtnConfirmClick()
    self:_NotifyClose(Operator.Sure)
end

function XUiBigWorldPopupQuitShow:OnBtnCloseClick()
    self:_NotifyClose(Operator.Cancel)
end

function XUiBigWorldPopupQuitShow:OnBtnTanchuangCloseClick()
    self:_NotifyClose(Operator.Close)
end

function XUiBigWorldPopupQuitShow:_NotifyClose(operator)
    if self._Data.IsNotify then
        local isSure = operator == Operator.Sure

        XMVCA.XBigWorldUI:SendQuitConfirmPopupCloseCommand(isSure)
    end

    local data = self._Data

    XLuaUiManager.CloseWithCallback(self.Name, function()
        if operator == Operator.Sure then
            data:InvokeSureClick()
        elseif operator == Operator.Cancel then
            data:InvokeCancelClick()
        else
            data:InvokeCloseClick()
        end
        data:Clear()
    end)
end

function XUiBigWorldPopupQuitShow:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnConfirm.CallBack = Handler(self, self.OnBtnConfirmClick)
    self.BtnClose.CallBack = Handler(self, self.OnBtnCloseClick)
    self.BtnTanchuangClose.CallBack = Handler(self, self.OnBtnTanchuangCloseClick)
end

function XUiBigWorldPopupQuitShow:_RefreshTitle()
    local data = self._Data

    self.TxtInfoNormal.text = data.Tips or ""
    self.TxtTitle.text = data:GetValidTitle()
end

function XUiBigWorldPopupQuitShow:_RefreshClick()
    local data = self._Data
    local cancelText = data:GetCancelClickText()
    local sureText = data:GetSureClickText()

    if not string.IsNilOrEmpty(cancelText) then
        self.BtnClose:SetNameByGroup(0, cancelText)
    end
    if not string.IsNilOrEmpty(sureText) then
        self.BtnConfirm:SetNameByGroup(0, sureText)
    end

    self.BtnConfirm.gameObject:SetActiveEx(data.SureClickData.IsActive)
    self.BtnClose.gameObject:SetActiveEx(data.CancelClickData.IsActive)
    self.BtnTanchuangClose.gameObject:SetActiveEx(data.CloseClickData.IsActive)
end

return XUiBigWorldPopupQuitShow
