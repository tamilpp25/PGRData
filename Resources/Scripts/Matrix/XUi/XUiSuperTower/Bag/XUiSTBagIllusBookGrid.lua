local BasePluginsGrid = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
--===========================
--超级爬塔背包图鉴芯片控件
--===========================
local XUiSTBagIllusBookGrid = XClass(BasePluginsGrid, "XUiSTBagIllusBookGrid")

function XUiSTBagIllusBookGrid:RefreshData(pluginData, index)
    self.Plugin = pluginData.Plugin
    self.RImgIcon:SetRawImage(self.Plugin:GetIcon())
    self.ImgQuality:SetSprite(self.Plugin:GetQualityIcon())
    self.TxtName.text = self.Plugin:GetName()
    self.ImgQualityBg:SetSprite(self.Plugin:GetQualityBg())
    self.Index = index
    self:SetActiveStatus(false)
    self:SetNormalLock(pluginData.IsLock)
end

return XUiSTBagIllusBookGrid