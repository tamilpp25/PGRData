---@class XRogueSimCommodityAdds
local XRogueSimCommodityAdds = XClass(nil, "XRogueSimCommodityAdds")

function XRogueSimCommodityAdds:Ctor()
    -- 货物类型
    self.CommodityId = 0
    -- 加成屬性集
    ---@type table<number, number> key是CommodityAttrType value是加成值
    self.Attrs = {}
end

function XRogueSimCommodityAdds:UpdateCommodityAddsData(data)
    self.CommodityId = data.CommodityId or 0
    self.Attrs = data.Attrs or {}
end

-- 获取属性加成值
function XRogueSimCommodityAdds:GetAttr(attrType)
    return self.Attrs[attrType] or 0
end

return XRogueSimCommodityAdds
