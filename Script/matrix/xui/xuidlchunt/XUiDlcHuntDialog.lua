---@class XUiDlcHuntDialog:XLuaUi
local XUiDlcHuntDialog = XLuaUiManager.Register(XLuaUi, "UiDlcHuntDialog")

function XUiDlcHuntDialog:Ctor()
    self._CallbackConfirm = false
    self._CallbackCancel = false
end

function XUiDlcHuntDialog:OnAwake()
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
end

function XUiDlcHuntDialog:OnStart(title, content, callbackConfirm, callbackCancel)
    if content then
        self.TxtInfoNormal.text = content
    end
    if title then
        self.TxtTitle.text = title
    end
    self._CallbackConfirm = callbackConfirm
    self._CallbackCancel = callbackCancel
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_Big)
end

function XUiDlcHuntDialog:OnBtnConfirmClick()
    self:Close()
    if self._CallbackConfirm then
        self._CallbackConfirm()
    end
end

function XUiDlcHuntDialog:OnBtnCloseClick()
    self:Close()
    if self._CallbackCancel then
        self._CallbackCancel()
    end
end

return XUiDlcHuntDialog
