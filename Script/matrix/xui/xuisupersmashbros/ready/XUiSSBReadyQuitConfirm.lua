
local XUiSSBReadyQuitConfirm = XLuaUiManager.Register(XLuaUi, "UiSuperSmashBrosDialog")

function XUiSSBReadyQuitConfirm:OnStart(title, content, onRedCb, onConfirmCb)
    self.OnRedCb = onRedCb
    self.OnConfirmCb = onConfirmCb
    self.BtnTcanchaungRed.CallBack = function() self:OnClickRed() end
    self.BtnConfirm.CallBack = function() self:OnClickConfirm() end
    self.BtnTanchuangClose.CallBack = function() self:OnClickClose() end
    self.TxtTitle.text = title
    self.TxtInfo.text = content
end

function XUiSSBReadyQuitConfirm:OnClickRed()
    self:Close()
    if self.OnRedCb then
        self.OnRedCb()
    end
end

function XUiSSBReadyQuitConfirm:OnClickConfirm()
    self:Close()
    if self.OnConfirmCb then
        self.OnConfirmCb()
    end
end

function XUiSSBReadyQuitConfirm:OnClickClose()
    self:Close()
end