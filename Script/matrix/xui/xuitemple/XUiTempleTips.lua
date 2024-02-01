---@class XUiTempleTips:XLuaUi
local XUiTempleTips = XLuaUiManager.Register(XLuaUi, "UiTempleTips")

function XUiTempleTips:OnAwake()
    self:RegisterClickEvent(self.BtnConfirm, self._Confirm)
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnBg, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self._Callback = false
end

function XUiTempleTips:OnStart(callback, text)
    if text then
        self.TxtInfoNormal.text = XUiHelper.ReplaceTextNewLine(text)
    end
    self._Callback = callback
end

function XUiTempleTips:_Confirm()
    if self._Callback then
        self._Callback()
        self:Close()
    end
end

return XUiTempleTips
