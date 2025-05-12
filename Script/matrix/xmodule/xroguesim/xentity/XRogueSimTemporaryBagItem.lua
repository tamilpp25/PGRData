---@class XRogueSimTemporaryBagItem
local XRogueSimTemporaryBagItem = XClass(nil, "XRogueSimTemporaryBagItem")

function XRogueSimTemporaryBagItem:Ctor()
    self.Id = 0
    self.Count = 0
    self.RewardType = -1
end

function XRogueSimTemporaryBagItem:UpdateTemporaryBagItem(data)
    self.Id = data.Id or 0
    self.Count = data.Count or 0
    self.RewardType = data.RewardType or -1
end

function XRogueSimTemporaryBagItem:GetId()
    return self.Id
end

function XRogueSimTemporaryBagItem:GetCount()
    return self.Count
end

function XRogueSimTemporaryBagItem:GetRewardType()
    return self.RewardType
end

return XRogueSimTemporaryBagItem
