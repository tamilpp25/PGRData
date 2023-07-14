local XGoldenMinerItemBase = XClass(nil, "XGoldenMinerItemBase")

function XGoldenMinerItemBase:Ctor(itemId)
    self:SetItemId(itemId)
end

function XGoldenMinerItemBase:SetItemId(itemId)
    self._ItemId = itemId   --道具Id
end

function XGoldenMinerItemBase:GetItemId()
    return self._ItemId
end

return XGoldenMinerItemBase