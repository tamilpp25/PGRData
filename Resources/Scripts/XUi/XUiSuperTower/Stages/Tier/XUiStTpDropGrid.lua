local BasePluginsGrid = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
--===========================
--超级爬塔爬塔准备界面插件掉落控件
--===========================
local XUiStTpDropGrid = XClass(BasePluginsGrid, "XUiStTpDropGrid")

function XUiStTpDropGrid:RefreshData(prePluginData)
    self.TxtTier.text = prePluginData.Name
    self.PluginCfg = XSuperTowerConfigs.GetPluginCfgById(prePluginData.PluginId)
    self:RefreshCfg(self.PluginCfg)
end

return XUiStTpDropGrid