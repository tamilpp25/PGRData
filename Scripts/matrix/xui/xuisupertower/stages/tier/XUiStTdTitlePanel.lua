local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--=====================
--爬塔掉落页面标题面板
--=====================
local XUiStTdTitlePanel = XClass(Base, "XUiStTdTitlePanel")
local SHOW_TYPE = {
    Enhance = 1, --增益页面
    Plugin = 2, --插件掉落页面
}
local TYPE_NAME = {
    [SHOW_TYPE.Enhance] = "Enhance",
    [SHOW_TYPE.Plugin] = "Plugin",
}

function XUiStTdTitlePanel:OnShowPanel()
    self:Refresh()
end

function XUiStTdTitlePanel:Refresh()
    self.TxtTitleMain.text = CS.XTextManager.GetText("STTd".. TYPE_NAME[self.RootUi.ShowType] .. "TitleMain")
    self.TxtTitleSub.text = CS.XTextManager.GetText("STTd".. TYPE_NAME[self.RootUi.ShowType] .. "TitleSub")
end

return XUiStTdTitlePanel