local UiGoldenMinerDialog = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerDialog")


function UiGoldenMinerDialog:OnAwake()
    self:InitBtnCallBack()
end

function UiGoldenMinerDialog:OnStart(title, content, closeCallback, sureCallback, data)
    local sureText, closeText
    if data then
        sureText = data.sureText
        closeText = data.closeText
    end
    
    if title then
        self.TxtTitle.text = title
    end
    if content then
        self.TxtInfoNormal.text = string.gsub(content, "\\n", "\n")
    end
    if sureText then
        self.BtnConfirm:SetNameByGroup(0, sureText)
    end
    if closeText then
        self.BtnClose:SetNameByGroup(0, closeText)
    end
    self.CloseCallback = closeCallback
    self.SureCallback = sureCallback
end

function UiGoldenMinerDialog:InitBtnCallBack()
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
end

function UiGoldenMinerDialog:OnBtnCloseClick()
    self:Close()
    if self.CloseCallback then
        self.CloseCallback()
    end

    self.CloseCallback = nil
    self.SureCallback = nil
end

function UiGoldenMinerDialog:OnBtnConfirmClick()
    self:Close()
    if self.SureCallback then
        self.SureCallback()
    end

    self.CloseCallback = nil
    self.SureCallback = nil
end