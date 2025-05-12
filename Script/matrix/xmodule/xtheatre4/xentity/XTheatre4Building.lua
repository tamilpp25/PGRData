---@class XTheatre4Building
local XTheatre4Building = XClass(nil, "XTheatre4Building")

function XTheatre4Building:Ctor()
    -- 建筑Id
    self.BuildingId = 0
    -- 建筑类型
    self.BuildingType = 0
end

-- 服务端通知
function XTheatre4Building:NotifyBuildingData(data)
    self.BuildingId = data.BuildingId or 0
    self.BuildingType = data.BuildingType or 0
end

-- 获取建筑Id
function XTheatre4Building:GetBuildingId()
    return self.BuildingId
end

-- 获取建筑类型
function XTheatre4Building:GetBuildingType()
    return self.BuildingType
end

return XTheatre4Building
