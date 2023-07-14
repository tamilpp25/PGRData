---@class XPlanetRunningSystemRotate
local XPlanetRunningSystemRotate = XClass(nil, "XPlanetRunningSystemRotate")

---@param explore XPlanetRunningExplore
function XPlanetRunningSystemRotate:Update(explore, deltaTime)
    local entities = explore.Entities
    for i = 1, #entities do
        local entity = entities[i]
        self:UpdateEntity(explore, entity, deltaTime)
    end
end

---@param explore XPlanetRunningExplore
---@param entity XPlanetRunningExploreEntity
function XPlanetRunningSystemRotate:UpdateEntity(explore, entity, deltaTime)
    if entity.Rotation then
        if entity.Rotation.RotationTo then
            entity.Rotation.SelfRotationTo = entity.Rotation.RotationTo
            entity.Rotation.RotationTo = false
            entity.Rotation.Duration = 0
            if not entity.Rotation.RotationCurrent then
                entity.Rotation.RotationCurrent = entity.Rotation.SelfRotationTo
            end
            entity.Rotation.SelfRotationFrom = entity.Rotation.RotationCurrent
        end

        if entity.Rotation.SelfRotationTo then
            local duration = entity.Rotation.Duration + deltaTime
            duration = math.min(duration, entity.Rotation.DurationExpected)
            entity.Rotation.Duration = duration
            local t = duration / entity.Rotation.DurationExpected
            local rotation = CS.UnityEngine.Quaternion.Lerp(entity.Rotation.SelfRotationFrom, entity.Rotation.SelfRotationTo, t)

            entity.Rotation.RotationCurrent = rotation

            local model = explore:GetModel(entity.Id)
            if model then
                local transform = model:GetTransform()
                if transform then
                    transform.localRotation = rotation
                end
            end

            if duration >= entity.Rotation.DurationExpected then
                entity.Rotation.Duration = 0
                entity.Rotation.SelfRotationFrom = false
                entity.Rotation.SelfRotationTo = false
            end
        end
    end
end

return XPlanetRunningSystemRotate