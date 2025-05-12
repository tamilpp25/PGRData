---@field _Control XMusicGameActivityControl
---@class XUiMusicGameActivityPopupVolSet : XLuaUi
local XUiMusicGameActivityPopupVolSet = XLuaUiManager.Register(XLuaUi, "UiMusicGameActivityPopupVolSet")

function XUiMusicGameActivityPopupVolSet:OnAwake()
    self:InitButton()
end

function XUiMusicGameActivityPopupVolSet:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnGo, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnSet, self.OnBtnSet)
end

function XUiMusicGameActivityPopupVolSet:OnBtnSet()
    XLuaUiManager.PopThenOpen("UiSet")
end

function XUiMusicGameActivityPopupVolSet:OnDestroy()
    local isToggleChoose = self.BtnNoWarning:GetToggleState()
    if isToggleChoose then
        self._Control:SetIsToggleChoose(true)
    end
end

return XUiMusicGameActivityPopupVolSet
