---@class XUiUserLogoffDialog:XLuaUi
local XUiUserLogoffDialog = XLuaUiManager.Register(XLuaUi, "UiUserLogoffDialog")

function XUiUserLogoffDialog:OnAwake()
    self.BtnConfirm.CallBack = function() self:Close() end
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end

return XUiUserLogoffDialog