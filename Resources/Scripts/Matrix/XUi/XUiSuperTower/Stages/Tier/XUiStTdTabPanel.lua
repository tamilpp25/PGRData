local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
local SHOW_TYPE = {
    Enhance = 1, --增益页面
    Plugin = 2, --插件掉落页面
}
local TYPE_NAME = {
    [SHOW_TYPE.Enhance] = "Enhance",
    [SHOW_TYPE.Plugin] = "Plugin",
    }
--=====================
--爬塔掉落页面页签面板
--=====================
local XUiStTdTabPanel = XClass(Base, "XUiStTdTabPanel")

function XUiStTdTabPanel:InitPanel()
    self:InitBtnGroup()
end

function XUiStTdTabPanel:InitBtnGroup()
    local btns = {}
    btns[SHOW_TYPE.Enhance] = self.BtnEnhance
    btns[SHOW_TYPE.Plugin] = self.BtnPlugin
    self.BtnGroupTab:Init(btns, function(index) self:SelectIndex(index) end)
end

function XUiStTdTabPanel:SelectIndex(index)
    local func = self["OnClick" .. TYPE_NAME[index]]
    if func then func(self) end
end

function XUiStTdTabPanel:OnClickEnhance()
    self.RootUi:ShowEnhance()
end

function XUiStTdTabPanel:OnClickPlugin()
    self.RootUi:ShowPlugin()
end

function XUiStTdTabPanel:OnShowPanel()
    self.BtnGroupTab:SelectIndex(self.RootUi.ShowType)
end

return XUiStTdTabPanel