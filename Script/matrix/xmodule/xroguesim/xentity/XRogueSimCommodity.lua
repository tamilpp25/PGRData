---@class XRogueSimCommodity
local XRogueSimCommodity = XClass(nil, "XRogueSimCommodity")

function XRogueSimCommodity:Ctor()
    self.Id = 0
    self.Count = 0
    -- 持久属性
    ---@type table<number, number> key是CommodityAttrType value是加成值
    self.Attrs = {}
end

function XRogueSimCommodity:UpdateCommodityData(data)
    self.Id = data.Id or 0
    self.Count = data.Count or 0
    self.Attrs = data.Attrs or {}
end

function XRogueSimCommodity:GetCount()
    return self.Count
end

return XRogueSimCommodity
