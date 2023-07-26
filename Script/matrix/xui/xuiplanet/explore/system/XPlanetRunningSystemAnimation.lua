local ACTION = XPlanetExploreConfigs.ACTION

---@class XPlanetRunningSystemAnimation
local XPlanetRunningSystemAnimation = XClass(nil, "XPlanetRunningSystemAnimation")

---@param explore XPlanetRunningExplore
function XPlanetRunningSystemAnimation:Update(explore)
    local entities = explore.Entities
    for i = 1, #entities do
        local entity = entities[i]
        if entity.Animation then
            if entity.Animation.ActionOnce then
                local model = explore:GetModel(entity.Id)
                local animator = model:GetAnimator()
                if animator then
                    local actionCurrent = self:GetRunningActionName(animator)
                    if actionCurrent == entity.Animation.ActionOnce then
                        local passedTime = self:GetPassedActionTime(animator)
                        if passedTime >= 1 then
                            entity.Animation.Action = ACTION.STAND
                            entity.Animation.ActionOnce = false
                        end
                    else
                        entity.Animation.Action = entity.Animation.ActionOnce
                    end
                end
            end

            local actionTo = entity.Animation.Action
            if actionTo ~= ACTION.None then

                -- 倍速时, 播放奔跑动作
                if actionTo == ACTION.WALK then
                    if explore:IsDoubleTimeScale() then
                        actionTo = ACTION.RUN
                    end
                end

                local actionCurrent = entity.Animation.ActionCurrent
                if actionTo ~= actionCurrent then
                    local model = explore:GetModel(entity.Id)
                    if model then
                        if actionCurrent == ACTION.None then
                            model:PlayAnima(actionTo)
                        elseif actionCurrent == ACTION.SKIP_FIGHT then
                            model:CrossFadeAnim(actionTo, 0.2)
                        elseif actionCurrent == ACTION.STAND and actionTo == ACTION.RUN then
                            model:CrossFadeAnim(actionTo, 0.3)
                        elseif actionCurrent == ACTION.RUN and actionTo == ACTION.STAND then
                            model:CrossFadeAnim(actionTo, 0.2)
                        else
                            model:CrossFadeAnim(actionTo, 0.1)
                        end
                        entity.Animation.ActionCurrent = actionTo
                    end
                    entity.Animation.Action = ACTION.None
                end
            end
        end
    end
end

---@param explore XPlanetRunningExplore
function XPlanetRunningSystemAnimation:ReplayModelAnimation(explore)
    local entities = explore.Entities
    for i = 1, #entities do
        local entity = entities[i]
        if entity.Animation then
            local action = entity.Animation.ActionCurrent
            local model = explore:GetModel(entity.Id)
            if model then
                model:PlayAnima(action)
            end
        end
    end
end

---@param explore XPlanetRunningExplore
function XPlanetRunningSystemAnimation:LetCharacterAction(explore, action, once)
    local entities = explore.Entities
    for i = 1, #entities do
        local entity = entities[i]
        if entity.Animation then
            if entity.Camp.CampType == XPlanetExploreConfigs.CAMP.PLAYER then
                if once then
                    entity.Animation.ActionOnce = action
                else
                    entity.Animation.Action = action
                end
            end
        end
    end
end

-- 当前动作已播放时间
function XPlanetRunningSystemAnimation:GetPassedActionTime(animator)
    local layer = 0
    local stateInfo = animator:GetCurrentAnimatorStateInfo(layer)
    return stateInfo.normalizedTime
end

function XPlanetRunningSystemAnimation:GetRunningActionName(animator)
    local animatorClipInfo, name = self:GetRunningActionClipInfo(animator)
    return name, animatorClipInfo
end

function XPlanetRunningSystemAnimation:GetRunningActionClipInfo(animator)
    local layer = 0
    local stateInfo = animator:GetCurrentAnimatorStateInfo(layer)
    local animatorClipInfos = animator:GetCurrentAnimatorClipInfo(layer)
    if animatorClipInfos.Length <= 0 then
        return nil
    end
    for i = 0, animatorClipInfos.Length - 1 do
        local animatorClipInfo = animatorClipInfos[i]
        local name = animatorClipInfo.clip.name
        if CS.UnityEngine.Animator.StringToHash(name) == stateInfo.shortNameHash then
            return animatorClipInfo, name
        end
    end
    return nil
end

return XPlanetRunningSystemAnimation
