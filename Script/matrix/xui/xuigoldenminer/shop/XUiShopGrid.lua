---@class XGoldenMinerShopGrid
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

--region Data - Init
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
--endregion

--region Ui - ObjInit
function XUiShopGrid:Init()
    local gridTransform = self.GridCommon.transform
    local imgQuality = XUiHelper.TryGetComponent(gridTransform, "ImgQuality")
    local panelTxt = XUiHelper.TryGetComponent(gridTransform, "PanelTxt")
    imgQuality.gameObject:SetActiveEx(false)
    panelTxt.gameObject:SetActiveEx(false)
    self.TxtLock.text = ""
    self.ItemRImgIcon = XUiHelper.TryGetComponent(gridTransform, "RImgIcon", "RawImage")
    self.TxtName = XUiHelper.TryGetComponent(gridTransform, "TxtName", "Text")
    if self.DiscountTag then
        self.DiscountTag.gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - Refresh
---@param itemId number GoldenMinerItem表的Id
---@param upgradeLocalId number GoldenMinerUpgradeLocal表的Id
function XUiShopGrid:Refresh(itemId, upgradeLocalId, index)
    self.ItemId = itemId
    self.UpgradeLocalId = upgradeLocalId
    self.UpgradeId = XGoldenMinerConfigs.GetUpgradeId(upgradeLocalId)
    self.Index = index

    self:UpdateCommon()

    if upgradeLocalId then
        self:UpdateUpgrade()
    else
        self:UpdateItem()
    end
end

function XUiShopGrid:RefreshPriceColor(prices)
    local isCanBuy = prices and prices <= self.DataDb:GetStageScores()
    self.TxtNewPrice.color = XGoldenMinerConfigs.GetShopItemPriceColor(isCanBuy)
end

function XUiShopGrid:UpdateCommon()
    local scoreIcon = XGoldenMinerConfigs.GetScoreIcon()
    self.RImgPrice:SetRawImage(scoreIcon)
    self.RImgPrice.gameObject:SetActiveEx(true)
    self.ImgLock.gameObject:SetActiveEx(false)
    self.DiscountTag.gameObject:SetActiveEx(false)
    self.PanelPrice1.gameObject:SetActiveEx(true)
    self.TextSellOut.text = XGoldenMinerConfigs.GetShopUpgradeBuyTxt(false)
    self.ImgSellOut.gameObject:SetActiveEx(false)
    if self.PanelFulllevel then
        self.PanelFulllevel.gameObject:SetActiveEx(false)
        self.PanelInuse.gameObject:SetActiveEx(false)
        self.PanelReplace.gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - ItemGrid
---刷新道具
function XUiShopGrid:UpdateItem()
    local itemId = self.ItemId
    if not XTool.IsNumberValid(itemId) then
        self.ImgLock.gameObject:SetActiveEx(true)
        return
    end
    
    local index = self.Index
    local isBuy = self.DataDb:IsItemAlreadyBuy(index)
    -- 价格&折扣
    local goldenMinerCommodityDb = self.DataDb:GetMinerShopDbByIndex(index)
    local originPrices = goldenMinerCommodityDb:GetPrices()
    local prices = originPrices and math.ceil(originPrices * self.ShopDiscount)
    self.TxtNewPrice.text = prices or ""
    self.TxtSaleRate.text = originPrices or ""
    self.TxtSaleRate.gameObject:SetActiveEx(prices ~= originPrices)
    if self.DiscountTag and self.ShopDiscount ~= 1 then
        self.DiscountTag.gameObject:SetActiveEx(not isBuy)
        self.TxtDiscountTag.text = (self.ShopDiscount * 10) .. XUiHelper.GetText("Snap")
    end

    local icon = XGoldenMinerConfigs.GetItemIcon(itemId)
    self.ItemRImgIcon:SetRawImage(icon)

    self.TxtName.text = XGoldenMinerConfigs.GetItemName(itemId)
    self.TxtLimitLable.text = XGoldenMinerConfigs.GetItemDescribe(itemId)
    self.ImgSellOut.gameObject:SetActiveEx(isBuy)
    self.PanelLevel.gameObject:SetActiveEx(false)

    self:RefreshPriceColor(prices)
end
--endregion

--region Ui - UpgradeGrid
---刷新飞碟升级项
function XUiShopGrid:UpdateUpgrade()
    local upgradeId = self.UpgradeId
    local upgradeLocalId = self.UpgradeLocalId
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(upgradeId)
    self.CurClientLevelIndex = upgradeStrengthen:GetClientLevelIndex(upgradeId)
    self.CurLevelIndex = upgradeStrengthen:GetLevelIndex(upgradeId)

    -- 升级介绍
    self.TxtName.text = XGoldenMinerConfigs.GetUpgradeLocalName(upgradeLocalId)
    self.TxtLimitLable.text = XGoldenMinerConfigs.GetUpgradeLocalDescribe(upgradeLocalId)
    -- 升级图标
    local icon = XGoldenMinerConfigs.GetUpgradeLocalIcon(upgradeLocalId)
    self.ItemRImgIcon:SetRawImage(icon)

    local type = XGoldenMinerConfigs.GetUpgradeType(upgradeId)
    self.TextSellOut.text = XGoldenMinerConfigs.GetShopUpgradeBuyTxt(type == XGoldenMinerConfigs.UpgradeType.SameReplace)
    if type == XGoldenMinerConfigs.UpgradeType.Level then
        self:_UpdateUpgradeLevel(upgradeId)
    elseif type == XGoldenMinerConfigs.UpgradeType.SameBuy then
        self:_UpdateUpgradeSameBuy(upgradeId, upgradeLocalId)
    elseif type == XGoldenMinerConfigs.UpgradeType.SameReplace then
        self:_UpdateUpgradeSameReplace(upgradeId, upgradeLocalId)
    end
end

function XUiShopGrid:_UpdateUpgradeLevel(upgradeId)
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(upgradeId)
    local nextLevelIndex = upgradeStrengthen:GetNextClientLevelIndex()
    local originPrices = XGoldenMinerConfigs.GetUpgradeCosts(upgradeId, nextLevelIndex)
    local prices = originPrices and math.ceil(originPrices * self.SkipDiscount)
    local isCanUpgrade = originPrices and true or false
    self.TxtNewPrice.text = prices or ""
    self.TxtSaleRate.text = originPrices or ""
    self.TextLevel.text = isCanUpgrade and XUiHelper.GetText("GoldenMinerShopTextLv", self.CurClientLevelIndex, nextLevelIndex)
            or XUiHelper.GetText("GoldenMinerAlreadyMaxLv")
    self.TxtSaleRate.gameObject:SetActiveEx(prices ~= originPrices)
    self.RImgPrice.gameObject:SetActiveEx(isCanUpgrade)
    self.PanelLevel.gameObject:SetActiveEx(isCanUpgrade)
    if self.PanelFulllevel then
        self.PanelFulllevel.gameObject:SetActiveEx(not isCanUpgrade)
    end
    -- 折扣
    if self.DiscountTag and self.SkipDiscount ~= 1 then
        self.DiscountTag.gameObject:SetActiveEx(isCanUpgrade)
        self.TxtDiscountTag.text = (self.SkipDiscount * 10) .. XUiHelper.GetText("Snap")
    end

    self:RefreshPriceColor(prices)
end

---有类型区分的飞碟特殊刷新
function XUiShopGrid:_UpdateUpgradeSameBuy(upgradeId, upgradeLocalId)
    local indexConfig = XGoldenMinerConfigs.GetUpgradeLocalIdIndex(upgradeId, upgradeLocalId)
    local originPrices = XGoldenMinerConfigs.GetUpgradeCosts(upgradeId, indexConfig)
    local prices = originPrices and math.ceil(originPrices * self.SkipDiscount)
    local levelIndexServer = indexConfig - 1
    local curLevelIndex = self.CurLevelIndex
    local isCanUpgrade = curLevelIndex ~= levelIndexServer

    self.CurClientLevelIndex = levelIndexServer
    self.TxtNewPrice.text = isCanUpgrade and prices or ""
    self.TxtSaleRate.text = isCanUpgrade and originPrices or ""
    self.RImgPrice.gameObject:SetActiveEx(isCanUpgrade)
    self.ImgSellOut.gameObject:SetActiveEx(not isCanUpgrade)
    self.PanelLevel.gameObject:SetActiveEx(false)
    self.TxtSaleRate.gameObject:SetActiveEx(prices ~= originPrices)-- 折扣
    if self.DiscountTag and self.SkipDiscount ~= 1 then
        self.DiscountTag.gameObject:SetActiveEx(isCanUpgrade)
        self.TxtDiscountTag.text = (self.SkipDiscount * 10) .. XUiHelper.GetText("Snap")
    end

    self:RefreshPriceColor(prices)
end

function XUiShopGrid:_UpdateUpgradeSameReplace(upgradeId, upgradeLocalId)
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(upgradeId)
    local indexConfig = XGoldenMinerConfigs.GetUpgradeLocalIdIndex(upgradeId, upgradeLocalId)
    local levelIndexServer = indexConfig - 1
    local curLevelIndex = self.CurLevelIndex
    local isCanUpgrade = curLevelIndex ~= levelIndexServer
    local originPrices = XGoldenMinerConfigs.GetUpgradeCosts(upgradeId, indexConfig)
    local isBuy = not XTool.IsNumberValid(originPrices) or upgradeStrengthen:CheckIsBuy(indexConfig) 

    if not isBuy then
        local prices = originPrices and math.ceil(originPrices * self.SkipDiscount)
        self.TxtNewPrice.text = isCanUpgrade and prices or ""
        self.TxtSaleRate.text = isCanUpgrade and originPrices or ""
        self.TxtSaleRate.gameObject:SetActiveEx(prices ~= originPrices)-- 折扣
        self:RefreshPriceColor(prices)
    else
        self.PanelPrice1.gameObject:SetActiveEx(false)
        if self.PanelInuse then
            self.PanelInuse.gameObject:SetActiveEx(not isCanUpgrade)
            self.PanelReplace.gameObject:SetActiveEx(isCanUpgrade)
        end
    end

    self.CurClientLevelIndex = levelIndexServer
    self.RImgPrice.gameObject:SetActiveEx(isCanUpgrade)
    --self.ImgSellOut.gameObject:SetActiveEx(not isCanUpgrade)
    self.PanelLevel.gameObject:SetActiveEx(false)
    if self.DiscountTag and self.SkipDiscount ~= 1 then
        self.DiscountTag.gameObject:SetActiveEx(isCanUpgrade)
        self.TxtDiscountTag.text = (self.SkipDiscount * 10) .. XUiHelper.GetText("Snap")
    end
end

function XUiShopGrid:CheckUpgradeCanBuy()
    local type = XGoldenMinerConfigs.GetUpgradeType(self.UpgradeId)
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(self.UpgradeId)
    local nextLevelIndex = upgradeStrengthen:GetNextClientLevelIndex()
    local originPrices = XGoldenMinerConfigs.GetUpgradeCosts(self.UpgradeId, nextLevelIndex)
    local indexConfig = XGoldenMinerConfigs.GetUpgradeLocalIdIndex(self.UpgradeId, self.UpgradeLocalId)
    local levelIndexServer = indexConfig - 1
    local curLevelIndex = self.CurLevelIndex
    local isCanUpgrade
    
    if type == XGoldenMinerConfigs.UpgradeType.Level then
        isCanUpgrade = originPrices and true or false
        if not isCanUpgrade then
            XUiManager.TipErrorWithKey("GoldenMinerAlreadyMaxLvTip")
        end
    elseif type == XGoldenMinerConfigs.UpgradeType.SameBuy then
        isCanUpgrade = curLevelIndex ~= levelIndexServer
        if not isCanUpgrade then
            XUiManager.TipErrorWithKey("GoldenMinerAlreadyEquipTip")
        end
    elseif type == XGoldenMinerConfigs.UpgradeType.SameReplace then
        isCanUpgrade = curLevelIndex ~= levelIndexServer
        if not isCanUpgrade then
            XUiManager.TipErrorWithKey("GoldenMinerAlreadyEquipTip")
        end
    end
    return isCanUpgrade
end
--endregion

--region Ui - BtnListener
function XUiShopGrid:AddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick)
end

function XUiShopGrid:OnBtnBuyClick()
    if XTool.IsNumberValid(self.ItemId) then
        self:_BuyItem()
    elseif XTool.IsNumberValid(self.UpgradeId) then
        self:_BuyUpgrade()
    end
end

function XUiShopGrid:_BuyUpgrade()
    if not self:CheckUpgradeCanBuy() then
        return
    end
    local levelIndex = 0
    local type = XGoldenMinerConfigs.GetUpgradeType(self.UpgradeId)
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(self.UpgradeId)
    if type == XGoldenMinerConfigs.UpgradeType.Level then
        levelIndex = upgradeStrengthen:GetNextClientLevelIndex()
    else
        levelIndex = XGoldenMinerConfigs.GetUpgradeLocalIdIndex(self.UpgradeId, self.UpgradeLocalId)
    end
    local originPrices = XGoldenMinerConfigs.GetUpgradeCosts(self.UpgradeId, levelIndex)
    local prices = originPrices and math.ceil(originPrices * self.SkipDiscount)
    local isBuy = not XTool.IsNumberValid(originPrices) or upgradeStrengthen:CheckIsBuy(levelIndex)
    
    local title = XUiHelper.GetText("GoldenMinerBuyHookTitle")
    local content = XUiHelper.GetText("GoldenMinerBuyHookContent", prices,
            XGoldenMinerConfigs.GetUpgradeLocalName(self.UpgradeLocalId))
    local sureCb = function()
        XDataCenter.GoldenMinerManager.RequestGoldenMinerShipUpgrade(self.UpgradeId, self.CurClientLevelIndex, function()
            if self.BuyCallback then
                self.BuyCallback()
            end
        end)
    end
    if isBuy then
        sureCb()
    else
        XLuaUiManager.Open("UiGoldenMinerDialog", title, content, nil, sureCb)
    end
end

function XUiShopGrid:_BuyItem()
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
--endregion

return XUiShopGrid