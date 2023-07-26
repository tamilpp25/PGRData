---@class XDlcHuntItem
local XDlcHuntItem = XClass(nil, "XDlcHuntItem")

function XDlcHuntItem:Ctor()
    self._ItemId = 0
    self._Amount = 0
end

function XDlcHuntItem:GetItemId()
    return self._ItemId
end

function XDlcHuntItem:GetIcon()
    return XItemConfigs.GetItemIconById(self:GetItemId())
end

function XDlcHuntItem:GetAmount()
    return self._Amount
end

function XDlcHuntItem:SetAmount(value)
    self._Amount = value
end

function XDlcHuntItem:SetItemId(itemId)
    self._ItemId = itemId
end

function XDlcHuntItem:GetCapacity()
    return XDlcHuntChipConfigs.ITEM_CAPACITY
end

function XDlcHuntItem:GetQuality()
    return XItemConfigs.GetQualityById(self:GetItemId())
end

function XDlcHuntItem:GetQualityColor()
    local quality = self:GetQuality()
    local color = XDlcHuntChipConfigs.GetQualityColor(quality)
    return color
end

return XDlcHuntItem