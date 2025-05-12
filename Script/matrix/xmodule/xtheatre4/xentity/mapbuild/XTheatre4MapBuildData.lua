---@class XTheatre4MapBuildData
local XTheatre4MapBuildData = XClass(nil, "XTheatre4MapBuildData")

function XTheatre4MapBuildData:Ctor()
    -- 是否在建造中
    self.IsBuilding = false
    -- 效果Id
    self.EffectId = 0
    -- 效果类型
    self.EffectType = 0
    -- 地图Id
    self.MapId = 0
    -- 格子Id
    self.GridId = 0
    -- 格子X坐标
    self.PosX = 0
    -- 格子Y坐标
    self.PosY = 0
end

function XTheatre4MapBuildData:SetIsBuilding(isBuilding)
    self.IsBuilding = isBuilding
end

function XTheatre4MapBuildData:SetEffectId(effectId)
    self.EffectId = effectId
end

function XTheatre4MapBuildData:SetEffectType(effectType)
    self.EffectType = effectType
end

function XTheatre4MapBuildData:SetMapId(mapId)
    self.MapId = mapId
end

function XTheatre4MapBuildData:SetGridData(gridId, posX, posY)
    self.GridId = gridId
    self.PosX = posX
    self.PosY = posY
end

function XTheatre4MapBuildData:GetIsBuilding()
    return self.IsBuilding
end

function XTheatre4MapBuildData:GetEffectId()
    return self.EffectId
end

function XTheatre4MapBuildData:GetEffectType()
    return self.EffectType
end

function XTheatre4MapBuildData:GetMapId()
    return self.MapId
end

function XTheatre4MapBuildData:GetGridId()
    return self.GridId
end

function XTheatre4MapBuildData:GetPosX()
    return self.PosX
end

function XTheatre4MapBuildData:GetPosY()
    return self.PosY
end

function XTheatre4MapBuildData:CheckIsSelectGrid()
    return self.MapId > 0 and self.GridId > 0
end

return XTheatre4MapBuildData
