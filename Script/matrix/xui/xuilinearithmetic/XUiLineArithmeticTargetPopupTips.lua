---@class XUiLineArithmeticTargetPopupTips : XLuaUi
---@field _Control XLineArithmeticControl
local XUiLineArithmeticTargetPopupTips = XLuaUiManager.Register(XLuaUi, "UiLineArithmeticTargetPopupTips")

function XUiLineArithmeticTargetPopupTips:Ctor()
    self._Callback = false
end

function XUiLineArithmeticTargetPopupTips:OnStart(callback, text)
    self._Callback = callback
    if text then
        self.Txt.text = text
    end
end

function XUiLineArithmeticTargetPopupTips:OnAwake()
    self:RegisterClickEvent(self.BtnNext, self.OnClickYes)
    self:RegisterClickEvent(self.BtnAgain, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.Close)
end

function XUiLineArithmeticTargetPopupTips:OnClickYes()
    self:Close()
    if self._Callback then
        self._Callback()
    end
end

return XUiLineArithmeticTargetPopupTips