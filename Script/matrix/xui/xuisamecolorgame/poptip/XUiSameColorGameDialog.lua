---@class XUiSameColorGameDialog:XLuaUi
local XUiSameColorGameDialog = XLuaUiManager.Register(XLuaUi, "UiSameColorGameDialog")

function XUiSameColorGameDialog:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.Close)
end

function XUiSameColorGameDialog:OnStart(title, content)
    self.TxtTitle.text = title
    self.TxtInfo.text = content
end