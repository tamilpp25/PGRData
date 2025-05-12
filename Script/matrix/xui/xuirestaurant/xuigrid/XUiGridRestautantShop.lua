local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
---@class XUiGridRestautantShop : XUiGridShop
local XUiGridRestautantShop = XClass(XUiGridShop, "XUiGridRestautantShop")

---@param parent XUiRestaurantShop
function XUiGridRestautantShop:Init(parent, rootUi, uiParams)
    XUiGridShop.Init(self, parent, rootUi, uiParams)
    local haveBuyCountColor = parent._Control:GetShopBuyLimitColor(1)
    local notBuyCountColor = parent._Control:GetShopBuyLimitColor(2)

    if notBuyCountColor then self.TxtLimitLock.color = XUiHelper.Hexcolor2Color(notBuyCountColor) end
    if haveBuyCountColor then self.TxtLimitNormal.color = XUiHelper.Hexcolor2Color(haveBuyCountColor) end
end

---购买次数
function XUiGridRestautantShop:RefreshBuyCount()
    if not self.TxtLimitLock or not self.TxtLimitNormal then
        return
    end

    if self.Data.BuyTimesLimit <= 0 then
        if not self:ShowDiscountCanButAmount() then
            self.TxtLimitLock.gameObject:SetActiveEx(false)
            self.TxtLimitNormal.gameObject:SetActiveEx(false)
        else
            self.TxtLimitLock.gameObject:SetActiveEx(true)
            self.TxtLimitNormal.gameObject:SetActiveEx(true)
        end
    else
        local buynumber = self.Data.BuyTimesLimit - self.Data.TotalBuyTimes
        local limitLabel = XShopConfigs.GetBuyLimitLabel(self.Data.AutoResetClockId)
        local text = string.format(limitLabel, buynumber.."/"..self.Data.BuyTimesLimit)

        self.TxtLimitLock.text = text
        self.TxtLimitLock.gameObject:SetActiveEx(true)
        self.TxtLimitNormal.text = text
        self.TxtLimitNormal.gameObject:SetActiveEx(true)
    end
end

---购买状态
function XUiGridRestautantShop:RefreshShowLock()
    local isLock = self.ConditionDesc ~= nil
    local goodsShowParams = self.Grid:GetGoodsShowParams()

    if self.ImgLock then self.ImgLock.gameObject:SetActiveEx(isLock) end
    if self.PanelLock then self.PanelLock.gameObject:SetActiveEx(isLock) end
    if self.TxtPriceLock then self.TxtPriceLock.gameObject:SetActiveEx(isLock) end
    if self.TxtLimitLock then self.TxtLimitLock.gameObject:SetActiveEx(isLock) end

    if self.PanelNormal then self.PanelNormal.gameObject:SetActiveEx(not isLock) end

    if self.TxtNormalLeftTime and goodsShowParams and goodsShowParams.Name then
        if goodsShowParams.RewardType == XArrangeConfigs.Types.Character then
            self.TxtNormalLeftTime.text = goodsShowParams.TradeName
        else
            self.TxtNormalLeftTime.text = goodsShowParams.Name
        end
    end
    if self.TxtLock then
        if isLock then
            self.TxtLock.text = self.ConditionDesc
            self.TxtLock.gameObject:SetActiveEx(true)
        else
            self.TxtLock.gameObject:SetActiveEx(false)
        end
    end
end

---货币数量及图标
function XUiGridRestautantShop:RefreshPrice()
    local consumeItem = self.Data.ConsumeList[1]
    if not consumeItem then
        self.RImgCoinIconLock.gameObject:SetActiveEx(false)
        self.TxtPriceLock.gameObject:SetActiveEx(false)
        self.RImgCoinIconNormal.gameObject:SetActiveEx(false)
        self.TxtPriceNormal.gameObject:SetActiveEx(false)
        return
    end
    local icon = XDataCenter.ItemManager.GetItemIcon(consumeItem.Id)
    if icon ~= nil then
        self.RImgCoinIconLock:SetRawImage(icon)
        self.RImgCoinIconNormal:SetRawImage(icon)
    end
    local needCount = consumeItem.Count
    local itemCount = XDataCenter.ItemManager.GetCount(consumeItem.Id)
    self.TxtPriceLock.text = needCount
    self.TxtPriceNormal.text = needCount
    if itemCount < needCount then
        if XTool.IsTableEmpty(self.ShopItemTextColor) then
            self.TxtPriceLock.color = CS.UnityEngine.Color(1, 0, 0)
            self.TxtPriceNormal.color = CS.UnityEngine.Color(1, 0, 0)
        else
            self.TxtPriceLock.color = XUiHelper.Hexcolor2Color(self.ShopItemTextColor.CanNotBuyColor)
            self.TxtPriceNormal.color = XUiHelper.Hexcolor2Color(self.ShopItemTextColor.CanNotBuyColor)
        end
    else
        if XTool.IsTableEmpty(self.ShopItemTextColor) then
            self.TxtPriceLock.color = CS.UnityEngine.Color(0, 0, 0)
            self.TxtPriceNormal.color = CS.UnityEngine.Color(0, 0, 0)
        else
            self.TxtPriceLock.color = XUiHelper.Hexcolor2Color(self.ShopItemTextColor.CanBuyColor) --FFF4E8
            self.TxtPriceNormal.color = XUiHelper.Hexcolor2Color(self.ShopItemTextColor.CanBuyColor)
        end
    end
end

---重载：条件判断
function XUiGridRestautantShop:RefreshCondition()
    self.ConditionDesc = nil
    local conditionIds = self.Data.ConditionIds
    if not conditionIds or #conditionIds <= 0 then
        return
    end

    for _, id in pairs(conditionIds) do
        local ret, desc = XConditionManager.CheckCondition(id)
        if not ret then
            self.ConditionDesc = desc
            return
        end
    end
end

---重载：售罄状态刷新
function XUiGridRestautantShop:RefreshSellOut()
    self.ImgSellOut = XUiHelper.TryGetComponent(self.Transform, "ImgSellOut")
    if not self.ImgSellOut then
        return
    end

    if self.Data.BuyTimesLimit <= 0 then
        self.ImgSellOut.gameObject:SetActiveEx(false)
    else
        if self.Data.TotalBuyTimes >= self.Data.BuyTimesLimit then
            self.ImgSellOut.gameObject:SetActiveEx(true)
        else
            self.ImgSellOut.gameObject:SetActiveEx(false)
        end
    end
end

return XUiGridRestautantShop