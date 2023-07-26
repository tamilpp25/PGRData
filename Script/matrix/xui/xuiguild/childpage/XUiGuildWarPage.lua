
local XUiGuildWarPage = XClass(nil, "XUiGuildWarPage")
local PAGE_INDEX = 2
function XUiGuildWarPage:Ctor(rootUi)
    self.RootUi = rootUi
    self:CreatePage()
end
--================
--创建子面板控件（默认显示控件）
--================
function XUiGuildWarPage:CreatePage()
    local ui = self.RootUi:LoadChildPrefab("GuildWarSelect", XUiConfigs.GetComponentUrl("UiGuildWarSelect"))
    local panelScript = require("XUi/XUiGuildWar/DifficultSelect/XUiGuildWarSelect")
    self.Panel = panelScript.New(ui, self, self.RootUi)
end
--================
--打开页面
--================
function XUiGuildWarPage:ShowPage(...)
    self.RootUi:SetActiveScene3DBlur(true)
    self.RootUi:UpdateCamera(PAGE_INDEX)
    self.Panel:ShowPanel(...)
end
--================
--页面再次显示时
--================
function XUiGuildWarPage:OnRepeatOpen()
    self.Panel:OnRepeatOpen()
end
--================
--隐藏页面
--================
function XUiGuildWarPage:HidePage()
    self.Panel:HidePanel()
end
--================
--在面板被销毁时
--================
function XUiGuildWarPage:OnDestroy()
    if self.Panel.OnDestroy then self.Panel:OnDestroy() end
end
return XUiGuildWarPage