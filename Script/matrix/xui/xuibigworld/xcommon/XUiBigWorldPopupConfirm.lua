---@class XUiBigWorldPopupConfirm : XBigWorldUi
---@field BtnConfirm XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field TxtInfoNormal UnityEngine.UI.Text
---@field TxtTitle UnityEngine.UI.Text
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field BtnTips UnityEngine.UI.Toggle
---@field TxtTips UnityEngine.UI.Text
local XUiBigWorldPopupConfirm = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupConfirm")

local Operator = {
    Sure = 1,
    Cancel = 2,
    Close = 3,
}

-- region 生命周期

function XUiBigWorldPopupConfirm:OnAwake()
    self:_RegisterButtonClicks()
end

---@param data XBWPopupConfirmData
function XUiBigWorldPopupConfirm:OnStart(data)
    ---@type XBWPopupConfirmData
    self._Data = data
    self._IsNoLongerPopup = false

    self:_RefreshTitle()
    self:_RefreshClick()
end

-- endregion

-- region 按钮事件

function XUiBigWorldPopupConfirm:OnBtnConfirmClick()
    self:_NotifyClose(Operator.Sure)
end

function XUiBigWorldPopupConfirm:OnBtnCloseClick()
    self:_NotifyClose(Operator.Cancel)
end

function XUiBigWorldPopupConfirm:OnBtnTanchuangCloseClick()
    self:_NotifyClose(Operator.Close)
end

function XUiBigWorldPopupConfirm:OnToggleClick(isOn)
    self._IsNoLongerPopup = isOn
    self._Data:InvokeToggle(isOn)
end

-- endregion

-- region 私有方法

function XUiBigWorldPopupConfirm:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick, true)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick, true)
    self.BtnTips.onValueChanged:AddListener(Handler(self, self.OnToggleClick))
end

function XUiBigWorldPopupConfirm:_NotifyClose(operator)
    if self._Data.IsNotify then
        local isSure = operator == Operator.Sure

        XMVCA.XBigWorldUI:SendConfirmPopupCloseCommand(self._Data.Key, isSure, self._IsNoLongerPopup and isSure)
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

function XUiBigWorldPopupConfirm:_RefreshTitle()
    local data = self._Data

    self.TxtInfoNormal.text = data.Tips or ""
    self.TxtTitle.text = data:GetValidTitle()
end

function XUiBigWorldPopupConfirm:_RefreshClick()
    local data = self._Data
    local cancelText = data:GetCancelClickText()
    local sureText = data:GetSureClickText()
    local toggleText = data:GetToggleText()

    if not string.IsNilOrEmpty(cancelText) then
        self.BtnClose:SetNameByGroup(0, cancelText)
    end
    if not string.IsNilOrEmpty(sureText) then
        self.BtnConfirm:SetNameByGroup(0, sureText)
    end
    if not string.IsNilOrEmpty(toggleText) and self.TxtTips then
        self.TxtTips.text = toggleText
    end
    self.BtnConfirm.gameObject:SetActiveEx(data.SureClickData.IsActive)
    self.BtnClose.gameObject:SetActiveEx(data.CancelClickData.IsActive)
    self.BtnTanchuangClose.gameObject:SetActiveEx(data.CloseClickData.IsActive)
    self.BtnTips.gameObject:SetActiveEx(data.ToggleData.IsActive)
end

-- endregion

return XUiBigWorldPopupConfirm
