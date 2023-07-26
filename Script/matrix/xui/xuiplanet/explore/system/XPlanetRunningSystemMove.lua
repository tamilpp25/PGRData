local MOVE_STATUS = XPlanetExploreConfigs.MOVE_STATUS

---@class XPlanetRunningSystemMove
local XPlanetRunningSystemMove = XClass(nil, "XPlanetRunningSystemMove")

---@param explore XPlanetRunningExplore
---@param entity XPlanetRunningExploreEntity
function XPlanetRunningSystemMove:Update(explore, entity, deltaTime)
    local movement = entity.Move
    local remainTime = deltaTime

    if movement.Status == MOVE_STATUS.START then
        remainTime = self:UpdateMoveStartData(explore, entity, movement, remainTime)
        movement.Status = MOVE_STATUS.WALK
    end

    if movement.Status == MOVE_STATUS.WALK then
        local positionStart = movement.PositionStart
        local positionTarget = movement.PositionTarget

        movement.Duration = movement.Duration + deltaTime

        local distance = (movement.Duration / movement.DurationExpected) * movement.Distance
        local positionCurrent
        local isArrived = false
        if distance >= movement.Distance then
            isArrived = true
            positionCurrent = positionTarget
        else
            positionCurrent = entity.Move.Direction * distance + positionStart
        end
        movement.PositionCurrent = positionCurrent
        local model = explore:GetModel(entity.Id)
        if model then
            model:SetLocalPosition(positionCurrent)
        end

        -- 到达下一个格子
        if isArrived then
            remainTime = movement.Duration - movement.DurationExpected
            movement.Status = XPlanetExploreConfigs.MOVE_STATUS.END
            movement.Duration = 0
            movement.TileIdCurrent = movement.TileIdEnd
            entity.Move.Direction = false
        else
            remainTime = 0
        end
        return remainTime
    end

    if movement.Status == MOVE_STATUS.END then
        movement.Status = MOVE_STATUS.IDLE
        return remainTime
    end

    return remainTime
end

function XPlanetRunningSystemMove:GetDistance(...)
    local distancePow2 = self:GetDistancePow2(...)
    return math.sqrt(distancePow2)
end

function XPlanetRunningSystemMove:GetDistancePow2(p1, p2)
    local x = p1.x - p2.x
    local y = p1.y - p2.y
    local z = p1.z - p2.z
    local distance = x ^ 2 + y ^ 2 + z ^ 2
    return distance
end

function XPlanetRunningSystemMove:IsEqual(p1, p2)
    local distance = self:GetDistancePow2(p1, p2)
    local isEqual = distance < 0.0001
    return isEqual
end

---@param explore XPlanetRunningExplore
---@param entity XPlanetRunningExploreEntity
---@param movement XPlanetRunningComponentMove
function XPlanetRunningSystemMove:UpdateMoveStartData(explore, entity, movement, remainTime)
    movement = movement or entity.Move
    if movement.TileIdCurrent then
        movement.TileIdStart = movement.TileIdCurrent
    end
    local tileIdNext = explore.Scene:GetNextRoadTileId(movement.TileIdStart)
    movement.TileIdEnd = tileIdNext
    if tileIdNext == 0 then
        movement.Status = MOVE_STATUS.NONE
        remainTime = 0
        return remainTime
    end

    local positionStart = explore.Scene:GetTileHeightPosition(movement.TileIdStart)
    local positionTarget
    if entity.Camp.CampType == XPlanetExploreConfigs.CAMP.BOSS then    -- 怪物反方向朝向
        local beforeTileId = explore.Scene:GetBeforeRoadTileId(movement.TileIdStart)
        positionTarget = explore.Scene:GetTileHeightPosition(beforeTileId)
    else
        positionTarget = explore.Scene:GetTileHeightPosition(movement.TileIdEnd)
    end
    movement.PositionStart = positionStart
    movement.PositionTarget = positionTarget
    movement.Direction = (positionTarget - positionStart).normalized

    movement.Duration = 0
    movement.Distance = self:GetDistance(positionStart, positionTarget)

    if entity.Rotation then
        local up = explore.Scene:GetTileUp(movement.TileIdEnd)
        local forward = positionTarget - positionStart
        local rotation = CS.UnityEngine.Quaternion.LookRotation(forward, up);
        entity.Rotation.RotationTo = rotation
    end
    return remainTime
end

return XPlanetRunningSystemMove