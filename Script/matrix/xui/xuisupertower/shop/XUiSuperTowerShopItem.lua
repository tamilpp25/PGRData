local XUiSuperTowerShopItem = XLuaUiManager.Register(XLuaUi, "UiSuperTowerShopItem")
local CSXTextManagerGetText = CS.XTextManager.GetText
function XUiSuperTowerShopItem:OnStart(shopInfo, callback)
    self.ShopInfo = shopInfo
    self.Callback = callback
    self:InitView()
end

function XUiSuperTowerShopItem:OnEnable()

end

function XUiSuperTowerShopItem:OnDisable()

end

function XUiSuperTowerShopItem:OnGetEvents()
    return {
        XEventId.EVENT_ST_SHOP_REFRESH
    }
end

function XUiSuperTowerShopItem:OnNotify(event, ...)
    if event == XEventId.EVENT_ST_SHOP_REFRESH then
        self:Close()
    end
end


function XUiSuperTowerShopItem:InitView()
    local mallPluginConfig = XSuperTowerConfigs.GetMallPluginConfig(self.ShopInfo.Id)
    local mallConfig = XSuperTowerConfigs.GetMallConfig(mallPluginConfig.MallId)
    self.PluginCfg = XSuperTowerConfigs.GetPluginCfgById(mallPluginConfig.PluginId)
    local pluginEntity = XDataCenter.SuperTowerManager.GetBagManager():GetPlugin(mallPluginConfig.PluginId)
    local count = 0
    if pluginEntity then
        count = pluginEntity:GetCount()
    end
    self.TxtOwnCount.text = CSXTextManagerGetText("SuperTowerShopOwnerText", count)
    self.TxtName.text = self.PluginCfg.Name
    self.RImgIcon:SetRawImage(self.PluginCfg.Icon)
    local starBg = XSuperTowerConfigs.GetStarBgByQuality(self.PluginCfg.Quality)
    local starIcon = XSuperTowerConfigs.GetStarIconByQuality(self.PluginCfg.Quality)
    self.ImgQuality:SetSprite(starIcon)
    self.BgKuang:SetSprite(starBg)
    self.RImgCostIcon1:SetRawImage(XDataCenter.ItemManager.GetItemIcon(mallConfig.SpendItemId))
    self.TxtCostCount1.text = mallPluginConfig.Price

    -- 加减按钮和最大数量按钮暂时无用先设置disable状态
    self.BtnAddSelect:SetDisable(true, false)
    self.BtnMinusSelect:SetDisable(true, false)
    self.BtnMax:SetDisable(true, false)
    self:RegisterButtonEvent()
end

function XUiSuperTowerShopItem:RegisterButtonEvent()
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
    self.BtnUse.CallBack = function()
        self:OnClickBtnBuy()
    end
    self.BtnMax.CallBack = function()
        self:OnClickBtnMax()
    end
    self.BtnAddSelect.CallBack = function()
        self:OnClickBtnAdd()
    end
    self.BtnMinusSelect.CallBack = function()
        self:OnClickBtnReduce()
    end
end

function XUiSuperTowerShopItem:OnClickBtnAdd()
    --todo 目前插件购买限制为1，暂时无用
end

function XUiSuperTowerShopItem:OnClickBtnReduce()
    --todo 目前插件购买限制为1，暂时无用
end

function XUiSuperTowerShopItem:OnClickBtnMax()
    --todo 目前插件购买限制为1，暂时无用
end

function XUiSuperTowerShopItem:OnClickBtnBuy()
    local shopManager = XDataCenter.SuperTowerManager.GetShopManager()
    local mallPluginConfig = XSuperTowerConfigs.GetMallPluginConfig(self.ShopInfo.Id)
    local mallConfig = XSuperTowerConfigs.GetMallConfig(mallPluginConfig.MallId)
    local spendItemCount = XDataCenter.ItemManager.GetCount(mallConfig.SpendItemId)
    if spendItemCount < mallPluginConfig.Price then
        XUiManager.TipText("STShopBuyItemNotEnoughTips")
        return
    end
    local bagManager = XDataCenter.SuperTowerManager.GetBagManager()
    if bagManager:GetCurrentCapacity() + self.PluginCfg.Capacity > bagManager:GetMaxCapacity() then
        XUiManager.TipText("STShopOverCapacity")
        return
    end
    shopManager:RequestBugPlugin(self.ShopInfo.Index, 1, function()
        XUiManager.TipText("BuySuccess")
        self:Close()
        if self.Callback then
            self.Callback()
        end
    end)
end

function XUiSuperTowerShopItem:CheckLimit()
    return true
end 