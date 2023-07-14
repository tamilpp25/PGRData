local XUiAssertDialog = XLuaUiManager.Register(XLuaUi, "UiAssertDialog")

function XUiAssertDialog:OnAwake()
    self:AutoAddListener()
end

function XUiAssertDialog:OnStart(title, content, dialogType, closeCallback, sureCallback)
    self.TxtInfo.text = content
    self.OkCallBack = sureCallback
    self.CancelCallBack = closeCallback
end

function XUiAssertDialog:AutoAddListener()
    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
end

function XUiAssertDialog:OnBtnConfirmClick()
    self:Close()

    if self.OkCallBack then
        self.OkCallBack()
    end

    self.OkCallBack = nil
    self.CancelCallBack = nil
end