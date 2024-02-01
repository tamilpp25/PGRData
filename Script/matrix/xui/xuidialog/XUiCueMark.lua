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
        self.IsNeedClose = hintInfo.IsNeedClose
        
        if hintInfo.HintText and hintInfo.HintText ~= "" then
            self.TxtHint.text = hintInfo.HintText
        end 
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
    if self.CancelCallBack then
        self.CancelCallBack()
    end
end

function XUiCueMark:OnBtnHintClick()
    local isSelect = self.BtnHint.ButtonState == CS.UiButtonState.Select
    if self.SetHintCb then
        self.SetHintCb(isSelect)
    end
    -- 点击今日不再提示，同时关闭提示界面
    if self.IsNeedClose and isSelect then
        self:OnBtnCloseClick()
    end
end

return XUiCueMark