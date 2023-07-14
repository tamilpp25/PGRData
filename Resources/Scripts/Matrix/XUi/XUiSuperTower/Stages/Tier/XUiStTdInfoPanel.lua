local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--=====================
--爬塔掉落页面详细信息面板
--=====================
local XUiStTdInfoPanel = XClass(Base, "XUiStTdInfoPanel")

function XUiStTdInfoPanel:InitPanel()
    local mixGridScript = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerMixGrid")
    self.Grid = mixGridScript.New(self.GridItem)
end

function XUiStTdInfoPanel:OnSelectGrid(cfg)
    self.ItemCfg = cfg
    self:ShowPanel()
end

function XUiStTdInfoPanel:Refresh()
    self:HidePanel()
end

function XUiStTdInfoPanel:OnShowPanel()
    self.Grid:RefreshCfg(self.ItemCfg)
    self.TxtDecs.text = self.ItemCfg.Description
end

return XUiStTdInfoPanel