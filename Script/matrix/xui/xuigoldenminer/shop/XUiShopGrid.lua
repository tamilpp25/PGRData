local XUiShopGrid = XClass(nil, "XUiShopGrid")

function XUiShopGrid:Ctor(ui, rootUi, buyCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.BuyCallback = buyCb
    XTool.InitUiObject(self)

    self.DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    self:InitBuff()
    self:Init()
    self:AddListener()
end

function XUiShopGrid:InitBuff()
    local percent = XGoldenMinerConfigs.Percent
    local ownBuffDic = XDataCenter.GoldenMinerManager.GetOwnBuffDic()
    --飞船升级打折
    local buffList = ownBuffDic[XGoldenMinerConfigs.BuffType.GoldenMinerSkipDiscount]
    local skipDiscount = buffList and buffList[1]
    self.SkipDiscount = skipDiscount and skipDiscount / percent or 1
    --购买道具打折
    buffList = ownBuffDic[XGoldenMinerConfigs.BuffType.GoldenMinerShopDiscount]
    local shopDiscount = buffList and buffList[1]
    self.ShopDiscount = shopDiscount and shopDiscount / percent or 1
end

function XUiShopGrid:Init()
    local gridTransform = self.GridCommon.transform
    self.ItemRImgIcon = XUiHelper.TryGetComponent(gridTransform, "RImgIcon", "RawImage")
    self.TxtName = XUiHelper.TryGetComponent(gridTransform, "TxtName", "Text")
    local imgQuality = XUiHelper.TryGetComponent(gridTransform, "ImgQuality")
    local panelTxt = XUiHelper.TryGetComponent(gridTransform, "PanelTxt")
    imgQuality.gameObject:SetActiveEx(false)
    panelTxt.gameObject:SetActiveEx(false)
    self.TxtLock.text = ""
end

--itemId：GoldenMinerItem表的Id
--upgradeLocalId：GoldenMinerUpgradeLocal表的Id
function XUiShopGrid:Refresh(itemId, upgradeLocalId, index)
    self.ItemId = itemId
    self.UpgradeLocalId = upgradeLocalId
    self.UpgradeId = XGoldenMinerConfigs.GetUpgradeId(upgradeLocalId)
    self.Index = index

    self:UpdateCommon()

    if upgradeLocalId then
        self:UpdateUpgrade()
        return
    end

    self:UpdateItem()
end

function XUiShopGrid:UpdateCommon()
    local scoreIcon = XGoldenMinerConfigs.GetScoreIcon()
    self.RImgPrice:SetRawImage(scoreIcon)
    self.RImgPrice.gameObject:SetActiveEx(true)
    self.ImgLock.gameObject:SetActiveEx(false)
end

--刷新道具
function XUiShopGrid:UpdateItem()
    local itemId = self.ItemId
    if not XTool.IsNumberValid(itemId) then
        self.ImgLock.gameObject:SetActiveEx(true)
        return
    end

    local index = self.Index
    local goldenMinerCommodityDb = self.DataDb:GetMinerShopDbByIndex(index)
    local originPrices = goldenMinerCommodityDb:GetPrices()
    local prices = originPrices and math.ceil(originPrices * self.ShopDiscount)
    self.TxtNewPrice.text = prices or ""
    self.TxtSaleRate.text = originPrices or ""
    self.TxtSaleRate.gameObject:SetActiveEx(prices ~= originPrices)

    local icon = XGoldenMinerConfigs.GetItemIcon(itemId)
    self.ItemRImgIcon:SetRawImage(icon)

    self.TxtName.text = XGoldenMinerConfigs.GetItemName(itemId)
    self.TxtLimitLable.text = XGoldenMinerConfigs.GetItemDescribe(itemId)
    self.ImgSellOut.gameObject:SetActiveEx(self.DataDb:IsItemAlreadyBuy(index))
    self.PanelLevel.gameObject:SetActiveEx(false)
end

--刷新飞碟升级项
function XUiShopGrid:UpdateUpgrade()
    local upgradeId = self.UpgradeId
    local upgradeLocalId = self.UpgradeLocalId
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(upgradeId)
    self.CurClientLevelIndex = upgradeStrengthen:GetClientLevelIndex(upgradeId)
    self.CurLevelIndex = upgradeStrengthen:GetLevelIndex(upgradeId)

    self.TxtName.text = XGoldenMinerConfigs.GetUpgradeLocalName(upgradeLocalId)
    self.TxtLimitLable.text = XGoldenMinerConfigs.GetUpgradeLocalDescribe(upgradeLocalId)

    local icon = XGoldenMinerConfigs.GetUpgradeLocalIcon(upgradeLocalId)
    self.ItemRImgIcon:SetRawImage(icon)

    local type = XGoldenMinerConfigs.GetUpgradeType(upgradeId)
    if XTool.IsNumberValid(type) then
        self:UpdateUpgradeSpecial(type)
        return
    end

    local nextLevelIndex = upgradeStrengthen:GetNextClientLevelIndex()
    local originPrices = XGoldenMinerConfigs.GetUpgradeCosts(upgradeId, nextLevelIndex)
    local prices = originPrices and math.ceil(originPrices * self.SkipDiscount)
    self.TxtNewPrice.text = prices or ""
    self.TxtSaleRate.text = originPrices or ""
    self.TxtSaleRate.gameObject:SetActiveEx(prices ~= originPrices)

    local isCanUpgrade = originPrices and true or false
    self.RImgPrice.gameObject:SetActiveEx(isCanUpgrade)
    self.ImgSellOut.gameObject:SetActiveEx(not isCanUpgrade)

    self.TextLevel.text = isCanUpgrade and XUiHelper.GetText("GoldenMinerShopTextLv", self.CurClientLevelIndex, nextLevelIndex) or XUiHelper.GetText("GoldenMinerAlreadyMaxLv")
    self.PanelLevel.gameObject:SetActiveEx(true)
end

--有类型区分的飞碟特殊刷新
function XUiShopGrid:UpdateUpgradeSpecial(type)
    local isCanUpgrade
    local upgradeId = self.UpgradeId
    local upgradeLocalId = self.UpgradeLocalId
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(upgradeId)
    local indexConfig = XGoldenMinerConfigs.GetUpgradeLocalIdIndex(upgradeId, upgradeLocalId)
    local originPrices = XGoldenMinerConfigs.GetUpgradeCosts(upgradeId, indexConfig)
    local prices = originPrices and math.ceil(originPrices * self.SkipDiscount)
    local levelIndexServer = indexConfig - 1
    local curLevelIndex = self.CurLevelIndex
    self.CurClientLevelIndex = levelIndexServer

    if type == XGoldenMinerConfigs.UpgradeType.Falcula then
        isCanUpgrade = curLevelIndex ~= levelIndexServer
        self.RImgPrice.gameObject:SetActiveEx(isCanUpgrade)
        self.ImgSellOut.gameObject:SetActiveEx(not isCanUpgrade)
        self.PanelLevel.gameObject:SetActiveEx(false)
    end

    self.TxtNewPrice.text = isCanUpgrade and prices or ""
    self.TxtSaleRate.text = isCanUpgrade and originPrices or ""
    self.TxtSaleRate.gameObject:SetActiveEx(prices ~= originPrices)
end

function XUiShopGrid:AddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick)
end

function XUiShopGrid:OnBtnBuyClick()
    if XTool.IsNumberValid(self.ItemId) then
        self:BuyItem()
    elseif XTool.IsNumberValid(self.UpgradeId) then
        self:BuyUpgrade()
    end
end

function XUiShopGrid:BuyUpgrade()
    XDataCenter.GoldenMinerManager.RequestGoldenMinerShipUpgrade(self.UpgradeId, self.CurClientLevelIndex, function()
        if self.BuyCallback then
            self.BuyCallback()
        end
    end)
end

function XUiShopGrid:BuyItem()
    local itemId = self.ItemId
    local emptyItemIndex
    if XGoldenMinerConfigs.GetItemType(itemId) == XGoldenMinerConfigs.ItemType.NormalItem then
        emptyItemIndex = self.DataDb:GetEmptyItemIndex()
        if not emptyItemIndex then
            XUiManager.TipErrorWithKey("GoldenMinerItemAlreadyMax")
            return
        end
    end

    XDataCenter.GoldenMinerManager.RequestGoldenMinerShopBuy(self.Index, emptyItemIndex, function()
        self:UpdateItem()
        if self.BuyCallback then
            self.BuyCallback()
        end
    end)
end

return XUiShopGrid