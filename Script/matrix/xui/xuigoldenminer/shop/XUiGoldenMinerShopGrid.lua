---@class XUiGoldenMinerShopGrid : XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerShopGrid = XClass(XUiNode, "XUiGoldenMinerShopGrid")

function XUiGoldenMinerShopGrid:OnStart(buyCb)
    self.BuyCallback = buyCb
    self.DataDb = self._Control:GetMainDb()
    self:InitBuff()
    self:Init()
    self:AddListener()
end

--region Data - Init
function XUiGoldenMinerShopGrid:InitBuff()
    local percent = XEnumConst.GOLDEN_MINER.PERCENT
    local ownBuffDic = self._Control:GetOwnBuffDic()
    --飞船升级打折
    local buffList = ownBuffDic[XEnumConst.GOLDEN_MINER.BUFF_TYPE.SKIP_DISCOUNT]
    local skipDiscount = buffList and buffList[1]
    self.SkipDiscount = skipDiscount and skipDiscount / percent or 1
    --购买道具打折
    buffList = ownBuffDic[XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHOP_DISCOUNT]
    local shopDiscount = buffList and buffList[1]
    self.ShopDiscount = shopDiscount and shopDiscount / percent or 1
end
--endregion

--region Ui - ObjInit
function XUiGoldenMinerShopGrid:Init()
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
function XUiGoldenMinerShopGrid:Refresh(itemId, upgradeLocalId, index)
    self.ItemId = itemId
    self.UpgradeLocalId = upgradeLocalId
    self.UpgradeId = self._Control:GetCfgUpgradeIdByLocalId(upgradeLocalId)
    self.Index = index

    self:UpdateCommon()

    if upgradeLocalId then
        self:UpdateUpgrade()
    else
        self:UpdateItem()
    end
end

function XUiGoldenMinerShopGrid:RefreshPriceColor(prices)
    local isCanBuy = prices and prices <= self.DataDb:GetStageScores()
    self.TxtNewPrice.color = self._Control:GetClientShopItemPriceColor(isCanBuy)
end

function XUiGoldenMinerShopGrid:UpdateCommon()
    local scoreIcon = self._Control:GetClientScoreIcon()
    self.RImgPrice:SetRawImage(scoreIcon)
    self.RImgPrice.gameObject:SetActiveEx(true)
    self.ImgLock.gameObject:SetActiveEx(false)
    self.DiscountTag.gameObject:SetActiveEx(false)
    self.PanelPrice1.gameObject:SetActiveEx(true)
    self.TextSellOut.text = self._Control:GetClientShopUpgradeBuyTxt(false)
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
function XUiGoldenMinerShopGrid:UpdateItem()
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

    local icon = self._Control:GetCfgItemIcon(itemId)
    self.ItemRImgIcon:SetRawImage(icon)

    self.TxtName.text = self._Control:GetCfgItemName(itemId)
    self.TxtLimitLable.text = self._Control:GetCfgItemDescribe(itemId)
    self.ImgSellOut.gameObject:SetActiveEx(isBuy)
    self.PanelLevel.gameObject:SetActiveEx(false)

    self:RefreshPriceColor(prices)
end
--endregion

--region Ui - UpgradeGrid
---刷新飞碟升级项
function XUiGoldenMinerShopGrid:UpdateUpgrade()
    local upgradeId = self.UpgradeId
    local upgradeLocalId = self.UpgradeLocalId
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(upgradeId)
    self.CurClientLevelIndex = upgradeStrengthen:GetClientLevelIndex(upgradeId)
    self.CurLevelIndex = upgradeStrengthen:GetLevelIndex(upgradeId)

    -- 升级介绍
    self.TxtName.text = self._Control:GetCfgUpgradeLocalName(upgradeLocalId)
    self.TxtLimitLable.text = self._Control:GetCfgUpgradeLocalDescribe(upgradeLocalId)
    -- 升级图标
    local icon = self._Control:GetCfgUpgradeLocalIcon(upgradeLocalId)
    self.ItemRImgIcon:SetRawImage(icon)

    local type = self._Control:GetCfgUpgradeType(upgradeId)
    self.TextSellOut.text = self._Control:GetClientShopUpgradeBuyTxt(type == XEnumConst.GOLDEN_MINER.UPGRADE_TYPE.SAME_REPLACE)
    if type == XEnumConst.GOLDEN_MINER.UPGRADE_TYPE.LEVEL then
        self:_UpdateUpgradeLevel(upgradeId)
    elseif type == XEnumConst.GOLDEN_MINER.UPGRADE_TYPE.SAME_BUY then
        self:_UpdateUpgradeSameBuy(upgradeId, upgradeLocalId)
    elseif type == XEnumConst.GOLDEN_MINER.UPGRADE_TYPE.SAME_REPLACE then
        self:_UpdateUpgradeSameReplace(upgradeId, upgradeLocalId)
    end
end

function XUiGoldenMinerShopGrid:_UpdateUpgradeLevel(upgradeId)
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(upgradeId)
    local nextLevelIndex = upgradeStrengthen:GetNextClientLevelIndex()
    local originPrices = self._Control:GetCfgUpgradeCfgCosts(upgradeId, nextLevelIndex)
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
function XUiGoldenMinerShopGrid:_UpdateUpgradeSameBuy(upgradeId, upgradeLocalId)
    local indexConfig = self._Control:GetCfgUpgradeLocalIdIndex(upgradeId, upgradeLocalId)
    local originPrices = self._Control:GetCfgUpgradeCfgCosts(upgradeId, indexConfig)
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

function XUiGoldenMinerShopGrid:_UpdateUpgradeSameReplace(upgradeId, upgradeLocalId)
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(upgradeId)
    local indexConfig = self._Control:GetCfgUpgradeLocalIdIndex(upgradeId, upgradeLocalId)
    local levelIndexServer = indexConfig - 1
    local curLevelIndex = self.CurLevelIndex
    local isCanUpgrade = curLevelIndex ~= levelIndexServer
    local originPrices = self._Control:GetCfgUpgradeCfgCosts(upgradeId, indexConfig)
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

function XUiGoldenMinerShopGrid:CheckUpgradeCanBuy()
    local type = self._Control:GetCfgUpgradeType(self.UpgradeId)
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(self.UpgradeId)
    local nextLevelIndex = upgradeStrengthen:GetNextClientLevelIndex()
    local originPrices = self._Control:GetCfgUpgradeCfgCosts(self.UpgradeId, nextLevelIndex)
    local indexConfig = self._Control:GetCfgUpgradeLocalIdIndex(self.UpgradeId, self.UpgradeLocalId)
    local levelIndexServer = indexConfig - 1
    local curLevelIndex = self.CurLevelIndex
    local isCanUpgrade
    
    if type == XEnumConst.GOLDEN_MINER.UPGRADE_TYPE.LEVEL then
        isCanUpgrade = originPrices and true or false
        if not isCanUpgrade then
            XUiManager.TipErrorWithKey("GoldenMinerAlreadyMaxLvTip")
        end
    elseif type == XEnumConst.GOLDEN_MINER.UPGRADE_TYPE.SAME_BUY then
        isCanUpgrade = curLevelIndex ~= levelIndexServer
        if not isCanUpgrade then
            XUiManager.TipErrorWithKey("GoldenMinerAlreadyEquipTip")
        end
    elseif type == XEnumConst.GOLDEN_MINER.UPGRADE_TYPE.SAME_REPLACE then
        isCanUpgrade = curLevelIndex ~= levelIndexServer
        if not isCanUpgrade then
            XUiManager.TipErrorWithKey("GoldenMinerAlreadyEquipTip")
        end
    end
    return isCanUpgrade
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerShopGrid:AddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClick)
end

function XUiGoldenMinerShopGrid:OnBtnBuyClick()
    if XTool.IsNumberValid(self.ItemId) then
        self:_BuyItem()
    elseif XTool.IsNumberValid(self.UpgradeId) then
        self:_BuyUpgrade()
    end
end

function XUiGoldenMinerShopGrid:_BuyUpgrade()
    if not self:CheckUpgradeCanBuy() then
        return
    end
    local levelIndex = 0
    local type = self._Control:GetCfgUpgradeType(self.UpgradeId)
    local upgradeStrengthen = self.DataDb:GetUpgradeStrengthen(self.UpgradeId)
    if type == XEnumConst.GOLDEN_MINER.UPGRADE_TYPE.LEVEL then
        levelIndex = upgradeStrengthen:GetNextClientLevelIndex()
    else
        levelIndex = self._Control:GetCfgUpgradeLocalIdIndex(self.UpgradeId, self.UpgradeLocalId)
    end
    local originPrices = self._Control:GetCfgUpgradeCfgCosts(self.UpgradeId, levelIndex)
    local prices = originPrices and math.ceil(originPrices * self.SkipDiscount)
    local isBuy = not XTool.IsNumberValid(originPrices) or upgradeStrengthen:CheckIsBuy(levelIndex)
    
    local title = XUiHelper.GetText("GoldenMinerBuyHookTitle")
    local content = XUiHelper.GetText("GoldenMinerBuyHookContent", prices,
            self._Control:GetCfgUpgradeLocalName(self.UpgradeLocalId))
    local sureCb = function()
        self._Control:RequestGoldenMinerShipUpgrade(self.UpgradeId, self.CurClientLevelIndex, function()
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

function XUiGoldenMinerShopGrid:_BuyItem()
    local itemId = self.ItemId
    local emptyItemIndex
    if self._Control:GetCfgItemType(itemId) == XEnumConst.GOLDEN_MINER.ITEM_TYPE.NORMAL_ITEM then
        emptyItemIndex = self.DataDb:GetEmptyItemIndex()
        if not emptyItemIndex then
            XUiManager.TipErrorWithKey("GoldenMinerItemAlreadyMax")
            return
        end
    end
    
    self._Control:RequestGoldenMinerShopBuy(self.Index, emptyItemIndex, function()
        self:UpdateItem()
        if self.BuyCallback then
            self.BuyCallback()
        end
    end)
end
--endregion

return XUiGoldenMinerShopGrid