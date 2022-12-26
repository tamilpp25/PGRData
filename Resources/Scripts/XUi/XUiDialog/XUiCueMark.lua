local stringGsub = string.gsub

local XUiCueMark = XLuaUiManager.Register(XLuaUi, "UiCueMark")

function XUiCueMark:OnAwake()
    self:AutoAddListener()
end

function XUiCueMark:OnStart(title, content, content2, closeCallback, sureCallback, hintInfo)
    if title then
        self.TxtTitle.text = title
        self.TxtTitle.gameObject:SetActiveEx(true)
    else
        self.TxtTitle.gameObject:SetActiveEx(false)
    end

    if content then
        self.TxtContent.text = content
        self.TxtContent.gameObject:SetActiveEx(true)
    else
        self.TxtContent.gameObject:SetActiveEx(false)
    end

    if content2 then
        self.TxtContent2.text = content2
        self.TxtContent2.gameObject:SetActiveEx(true)
    else
        self.TxtContent2.gameObject:SetActiveEx(false)
    end

    self.OkCallBack = sureCallback
    self.CancelCallBack = closeCallback

    if hintInfo then
        self.SetHintCb = hintInfo.SetHintCb

        local isSelect = hintInfo.Status == true
        self.BtnHint:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
        self.BtnHint.gameObject:SetActiveEx(true)
    else
        self.BtnHint.gameObject:SetActiveEx(false)
    end
end

function XUiCueMark:AutoAddListener()
    self:RegisterClickEvent(self.BtnTcanchaungBlue, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnTcanchaungBlack, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnHint, self.OnBtnHintClick)
end

function XUiCueMark:OnBtnConfirmClick()
    self:Close()
    if self.OkCallBack then
        self.OkCallBack()
    end
end

function XUiCueMark:OnBtnCloseClick()
    self:Close()
end

function XUiCueMark:OnBtnHintClick()
    local isSelect = self.BtnHint.ButtonState == CS.UiButtonState.Select
    if self.SetHintCb then
        self.SetHintCb(isSelect)
    end
end