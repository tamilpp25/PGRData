---@class XUiGuildWarTips:XLuaUi
local XUiGuildWarTips = XLuaUiManager.Register(XLuaUi, "UiGuildWarTips")

function XUiGuildWarTips:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnConfirm, self.OnClickSelectDifficulty)
end

function XUiGuildWarTips:OnClickSelectDifficulty()
    self:Close()
    XLuaUiManager.Open("UiGuildWarSelect")
end

return XUiGuildWarTips
