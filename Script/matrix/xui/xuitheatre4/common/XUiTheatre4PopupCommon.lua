-- 通用提示弹窗
---@class XUiTheatre4PopupCommon : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4PopupCommon = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupCommon")

function XUiTheatre4PopupCommon:OnAwake()
    self:RegisterUiEvents()
end

---@deprecated data 额外参数
---@param data { SureText:string, CancelText:string, IsShowCheck:boolean, CheckKey:string, IsHideCancel:boolean }
function XUiTheatre4PopupCommon:OnStart(title, content, sureCallback, cancelCallback, data)
    local sureText, cancelText
    self.IsShowCheck = false
    self.CheckKey = ""
    self.IsHideCancel = false
    if data then
        sureText = data.SureText
        cancelText = data.CancelText
        self.IsShowCheck = data.IsShowCheck
        self.CheckKey = data.CheckKey
        self.IsHideCancel = data.IsHideCancel or false
    end
    if sureText then
        self.BtnSure:SetNameByGroup(0, sureText)
    end
    if cancelText then
        self.BtnCancel:SetNameByGroup(0, cancelText)
    end
    self.BtnCancel.gameObject:SetActiveEx(not self.IsHideCancel)
    if self.IsShowCheck then
        self.BtnCheck.gameObject:SetActiveEx(true)
        self.BtnCheck:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnCheck.gameObject:SetActiveEx(false)
    end
    if self.IsShowCheck and not string.IsNilOrEmpty(self.CheckKey) then
        self.IsCheck = self._Control:CheckTodayDontShowValue(self.CheckKey)
        self.BtnCheck:SetButtonState(self.IsCheck and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
    self.TxtName.text = title
    self.TxtDescription.text = content
    self.SureCallback = sureCallback
    self.CancelCallback = cancelCallback
end

function XUiTheatre4PopupCommon:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSure, self.OnBtnSureClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCheck, self.OnBtnCheckClick)
end

function XUiTheatre4PopupCommon:OnBtnBackClick()
    if self.IsHideCancel then
        return
    end
    XLuaUiManager.CloseWithCallback(self.Name, self.CancelCallback)
end

function XUiTheatre4PopupCommon:OnBtnSureClick()
    if self.IsShowCheck and not string.IsNilOrEmpty(self.CheckKey) then
        self._Control:SaveTodayDontShowValue(self.CheckKey, self.IsCheck)
    end
    XLuaUiManager.CloseWithCallback(self.Name, self.SureCallback)
end

function XUiTheatre4PopupCommon:OnBtnCheckClick()
    self.IsCheck = self.BtnCheck:GetToggleState()
end

return XUiTheatre4PopupCommon
