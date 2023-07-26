--肉鸽2.0提示弹窗
local XUiBiancaTheatreEndTips = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreEndTips")

function XUiBiancaTheatreEndTips:OnAwake()
    self:AutoAddListener()
end

function XUiBiancaTheatreEndTips:OnStart(title, content, dialogType, closeCallback, sureCallback, data)
    ---- 处理额外参数 -----
    local sureText, closeText
    if data then
        sureText = data.sureText
        closeText = data.closeText
    end

    if sureText then
        self.BtnSure:SetName(sureText)
    end

    if closeText then
        self.BtnCancel:SetName(closeText)
    end
    ---- end -----
    
    if title then
        self.TxtName.text = title
    end
    self.TxtDescription.text = string.gsub(content, "\\n", "\n")
    self.OkCallBack = sureCallback
    self.CancelCallBack = closeCallback
end

function XUiBiancaTheatreEndTips:OnEnable()
end

function XUiBiancaTheatreEndTips:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.CancelBtnClick)
    self:RegisterClickEvent(self.BtnOk, self.CancelBtnClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.CancelBtnClick)
    self:RegisterClickEvent(self.BtnCancel, self.CancelBtnClick)
    self:RegisterClickEvent(self.BtnSure, self.OkBtnClick)
end

function XUiBiancaTheatreEndTips:OkBtnClick()
    self:EmitSignal("Close", true)
    CsXUiManager.Instance:Close(self.Name)
    if self.OkCallBack then
        self.OkCallBack()
    end

    self.OkCallBack = nil
    self.CancelCallBack = nil
end

function XUiBiancaTheatreEndTips:CancelBtnClick()
    self:EmitSignal("Close", false)
    CsXUiManager.Instance:Close(self.Name)
    if self.CancelCallBack then
        self.CancelCallBack()
    end

    self.OkCallBack = nil
    self.CancelCallBack = nil
end

return XUiBiancaTheatreEndTips
