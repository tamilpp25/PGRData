local XUiGridSuperTowerShopItem = XClass(nil, "XUiGridSuperTowerShopItem")
local PluginScript = require("XEntity/XSuperTower/Plugin/XSuperTowerPlugin")

function XUiGridSuperTowerShopItem:Ctor(ui, rootUi)
    self.GameObject = ui
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.BtnClick.CallBack = function()
        if not self.Plugin then
            return
        end
        XLuaUiManager.Open("UiSuperTowerPluginDetails", self.Plugin)
    end
end

function XUiGridSuperTowerShopItem:Refresh(itemInfo)
    if not itemInfo then
        return
    end
    local mallPluginConfig     = XSuperTowerConfigs.GetMallPluginConfig(itemInfo.Id)
    local pluginConfig         = XSuperTowerConfigs.GetPluginCfgById(mallPluginConfig.PluginId)
    local mallConfig           = XSuperTowerConfigs.GetMallConfig(mallPluginConfig.MallId)
    local starBg               = XSuperTowerConfigs.GetStarBgByQuality(pluginConfig.Quality)
    local starIcon             = XSuperTowerConfigs.GetStarIconByQuality(pluginConfig.Quality)
    self.Plugin                = PluginScript.New(mallPluginConfig.PluginId)
    self.TxtCostItemCount.text = mallPluginConfig.Price
    self.TxtBuyItemName.text   = pluginConfig.Name
    self.PanelYishouqin.gameObject:SetActiveEx(itemInfo.Sell)
    self.RImgCostItemIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(mallConfig.SpendItemId))
    self.ImgQuality:SetSprite(starIcon)
    self.BgKuang:SetSprite(starBg)
    self.RImgIcon:SetRawImage(pluginConfig.Icon)
end

return XUiGridSuperTowerShopItem