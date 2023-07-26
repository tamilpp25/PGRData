---@class XUiGuildWarSelectPage:XLuaUi
local XUiGuildWarSelectPage = XLuaUiManager.Register(XLuaUi, "UiGuildWarSelect")

function XUiGuildWarSelectPage:OnStart()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "GuildWarHelp")
    self:CreatePage()
    self:ShowPage()
end

function XUiGuildWarSelectPage:CreatePage()
    -- 原本XUiGuildWarSelect是挂在XUiGuildWarPage下的子ui, 现将它做成了独立的ui, 但维持原结构不变
    self.Panel = require("XUi/XUiGuildWar/DifficultSelect/XUiGuildWarSelect").New(self.GuildWarSelect)
end

function XUiGuildWarSelectPage:ShowPage()
    self.Panel:ShowPanel()
end

function XUiGuildWarSelectPage:OnDestroy()
    self.Panel:OnDestroy()
    XUiGuildWarSelectPage.Super.OnDestroy(self)
end

function XUiGuildWarSelectPage:OnEnable()
    self.Panel:OnRepeatOpen()
end

return XUiGuildWarSelectPage
