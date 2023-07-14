---@class XTheatre3NodeShopItem
local XTheatre3NodeShopItem = XClass(nil, "XTheatre3NodeShopItem")

function XTheatre3NodeShopItem:Ctor()
    ---@type number XEnumConst.THEATRE3.NodeShopItemType
    self.ShopItemType = 0
    self.Uid = 0
    self.ItemId = 0
    self.ItemBoxId = 0
    self.EquipBoxId = 0
    self.IsBuy = false
    self.IsLock = false
    self.Price = 0          -- 原价
    self.DiscountPrice = 0  -- 打折后价格
end

--region DataUpdate
function XTheatre3NodeShopItem:SetBuy()
    self.IsBuy = true
end
--endregion

--region Getter
function XTheatre3NodeShopItem:GetUid()
    return self.Uid
end

function XTheatre3NodeShopItem:GetItemId()
    return self.ItemId
end

function XTheatre3NodeShopItem:GetItemBoxId()
    return self.ItemBoxId
end

function XTheatre3NodeShopItem:GetEquipBoxId()
    return self.EquipBoxId
end

function XTheatre3NodeShopItem:GetEventStepTemplateId()
    if self:CheckType(XEnumConst.THEATRE3.NodeShopItemType.Item) then
        return self:GetItemId()
    elseif self:CheckType(XEnumConst.THEATRE3.NodeShopItemType.EquipBox) then
        return self:GetEquipBoxId()
    elseif self:CheckType(XEnumConst.THEATRE3.NodeShopItemType.ItemBox) then
        return self:GetItemBoxId()
    end
    return self.ItemId
end

function XTheatre3NodeShopItem:GetEventStepType()
    if self:CheckType(XEnumConst.THEATRE3.NodeShopItemType.Item) then
        return XEnumConst.THEATRE3.EventStepItemType.InnerItem
    elseif self:CheckType(XEnumConst.THEATRE3.NodeShopItemType.EquipBox) then
        return XEnumConst.THEATRE3.EventStepItemType.EquipBox
    elseif self:CheckType(XEnumConst.THEATRE3.NodeShopItemType.ItemBox) then
        return XEnumConst.THEATRE3.EventStepItemType.ItemBox
    end
    return XEnumConst.THEATRE3.EventStepItemType.InnerItem
end

function XTheatre3NodeShopItem:GetPrice()
    if self:CheckIsHaveDiscount() then
        return self.DiscountPrice
    end
    return self.Price
end

---打折
function XTheatre3NodeShopItem:GetDiscount()
    if self:CheckIsHaveDiscount() then
        return string.format("%0.1f", self.DiscountPrice / self.Price * 10)
    end
    return 10
end
--endregion

--region Checker
---@param type number XEnumConst.THEATRE3.NodeShopItemType
function XTheatre3NodeShopItem:CheckType(type)
    return self.ShopItemType == type
end

function XTheatre3NodeShopItem:CheckIsBuy()
    return self.IsBuy
end

function XTheatre3NodeShopItem:CheckIsLock()
    return self.IsLock
end

function XTheatre3NodeShopItem:CheckIsHaveDiscount()
    return XTool.IsNumberValid(self.DiscountPrice) and self.DiscountPrice ~= self.Price
end
--endregion

function XTheatre3NodeShopItem:NotifyData(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    self.ShopItemType = data.ItemType
    self.Uid = data.Uid
    self.ItemId = data.ItemId
    self.ItemBoxId = data.ItemBoxId
    self.EquipBoxId = data.EquipBoxId
    self.IsBuy = XTool.IsNumberValid(data.IsBuy)
    self.IsLock = XTool.IsNumberValid(data.IsLock)
    self.Price = data.Price
    self.DiscountPrice = data.DiscountPrice
end

return XTheatre3NodeShopItem