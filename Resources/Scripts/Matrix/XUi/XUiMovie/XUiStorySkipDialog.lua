local XUiStorySkipDialog = XLuaUiManager.Register(XLuaUi, "UiStorySkipDialog")

function XUiStorySkipDialog:OnAwake()
    self:AddListener()
end

function XUiStorySkipDialog:OnStart(descpription, okCallBack, cancelCallBack)
    self.OkCallBack = okCallBack
    self.CancelCallBack = cancelCallBack
    self.TxtInfo.text = descpription or ""
end

function XUiStorySkipDialog:AddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
end

function XUiStorySkipDialog:OnBtnConfirmClick()
    self:Close()
    if self.OkCallBack then
        self.OkCallBack()
    end
end

function XUiStorySkipDialog:OnBtnCloseClick()
    self:Close()
    if self.CancelCallBack then
        self.CancelCallBack()
    end
end

return XUiStorySkipDialog