local ActionType = CS.XPlanetRunning.XPlanetRunningFight.XPlanetRunningActionType
local ATTACK_STATUS = XPlanetExploreConfigs.ATTACK_STATUS
local DURATION_MOVE_PREPARE = 0.35
local DURATION_MOVE_FORWARD = 0.09
local DURATION_MOVE_ANIMATION = 0.06
local DURATION_MOVE_BACKWARD = 0.4
local TRACK = {
    LAUNCHER = "Launcher",
    TARGET = "Target",
    LAUNCHER_MOVE = "LauncherMove",
}

---@class XUiPlanetRunningSystemAction
local XUiPlanetRunningSystemAction = XClass(nil, "XUiPlanetRunningSystemAction")

---@param action XUiPlanetRunningAction
function XUiPlanetRunningSystemAction:Update(deltaTime, action, fight)
    if action.ActionType == ActionType.Attack then
        return self:UpdateAttack(deltaTime, action, fight)
    end
    return false
end

---@param action XUiPlanetRunningActionAttack
---@param fight XUiPlanetRunningFight
function XUiPlanetRunningSystemAction:UpdateAttack(deltaTime, action, fight)
    local uiEntities = fight.UiEntities

    if action.Status == ATTACK_STATUS.NONE then
        action.Status = ATTACK_STATUS.MOVE_PREPARE

        local launcherId = action.LauncherId
        local targetId = action.TargetId
        action.Duration = 0

        local launcher = uiEntities[launcherId]
        local target = uiEntities[targetId]
        if not launcher or not target then
            action.Status = ATTACK_STATUS.END
            return
        end

        local holderLauncher = launcher.Transform.parent:GetComponent("Animator")
        fight.TimelineHelper:SetBindingTarget(TRACK.LAUNCHER, holderLauncher)
        fight.TimelineHelper:SetBindingTarget(TRACK.LAUNCHER_MOVE, holderLauncher)
        local holderTarget = target.Transform.parent:GetComponent("Animator")
        fight.TimelineHelper:SetBindingTarget(TRACK.TARGET, holderTarget)

        --action.IsPlayingTimeline = true
        fight.TimelineHelper:Play(function()
            --action.IsPlayingTimeline = false
        end)

        return true
    end

    -- 先向后
    if action.Status == ATTACK_STATUS.MOVE_PREPARE then
        local launcherId = action.LauncherId
        local targetId = action.TargetId
        local launcher = uiEntities[launcherId]
        local target = uiEntities[targetId]

        if action.Duration == 0 then
            if launcher then
                if action.IsCritical then
                    launcher:ShowCritical()
                else
                    local targetEntity = fight.ObjFight:GetEntity(targetId)
                    if action.Hurt == targetEntity.Attribute.LifeThisGame then
                        launcher:ShowSeckill()
                    end
                end
                launcher:ShowEffectMove()
            end
        end

        action.Duration = action.Duration + deltaTime

        if not launcher or not target then
            launcher:ResetPosition()
            action.Status = ATTACK_STATUS.MOVE_FORWARD
            return
        end

        local startPosition = launcher.Position
        local attackPosition = target.PositionAttacker
        local distanceBackward = 50
        local targetPosition = startPosition + (startPosition - attackPosition).normalized * distanceBackward

        if action.Duration >= DURATION_MOVE_PREPARE then
            launcher:SetPosition(targetPosition)
            action.Status = ATTACK_STATUS.MOVE_FORWARD
            action.Duration = 0

            -- 提高ui层级
            self:SetUiOnTop(launcher.Transform.parent.parent.transform)
            self:SetUiOnTop(launcher.Transform.parent.parent.parent.transform)
            launcher:SetOrderInLayerAttack()
            return true
        end

        local progress = action.Duration / DURATION_MOVE_PREPARE

        local currentPosition = (targetPosition - startPosition) * progress + startPosition
        launcher:SetPosition(currentPosition)

        return true
    end

    if action.Status == ATTACK_STATUS.MOVE_FORWARD then
        local launcherId = action.LauncherId
        local targetId = action.TargetId
        local launcher = uiEntities[launcherId]
        local target = uiEntities[targetId]

        action.Duration = action.Duration + deltaTime

        if not launcher or not target then
            launcher:ResetPosition()
            action.Status = ATTACK_STATUS.ANIMATION
            return
        end

        local progress = action.Duration / DURATION_MOVE_FORWARD
        if target and progress > 0.85 then
            target:ShowEffectBeAttack()
        end
        
        local targetPosition = target.PositionAttacker
        if action.Duration >= DURATION_MOVE_FORWARD then
            launcher:SetPosition(targetPosition)
            action.Status = ATTACK_STATUS.ANIMATION
            action.Duration = 0
            return true
        end

        local startPosition = launcher.Position
        local currentPosition = (targetPosition - startPosition) * progress + startPosition
        launcher:SetPosition(currentPosition)
        return true
    end

    if action.Status == ATTACK_STATUS.ANIMATION then
        if action.Duration == 0 then
            local targetId = action.TargetId
            local targetEntity = fight.ObjFight:GetEntity(targetId)
            local target = uiEntities[targetId]
            if target then
                target:SetHp(targetEntity)
                target:SetHurt(action.Hurt)
            end
        end

        action.Duration = action.Duration + deltaTime
        if action.Duration >= DURATION_MOVE_ANIMATION then
            action.Status = ATTACK_STATUS.MOVE_BACKWARD
            action.Duration = 0
            return true
        end

        return true
    end

    if action.Status == ATTACK_STATUS.MOVE_BACKWARD then
        local launcherId = action.LauncherId
        local targetId = action.TargetId
        action.Duration = action.Duration + deltaTime

        local launcher = uiEntities[launcherId]
        local target = uiEntities[targetId]
        if not launcher or not target then
            launcher:ResetPosition()
            action.Status = ATTACK_STATUS.END
            return
        end

        local targetPosition = launcher.Position
        if action.Duration >= DURATION_MOVE_BACKWARD then
            launcher:ResetPosition()
            action.Status = ATTACK_STATUS.END
            action.Duration = 0
            target:HideHurt()
            launcher:HideCritical()
            launcher:HideSeckill()
            launcher:HideEffectMove()
            launcher:SetOrderInLayerNormal()
            target:HideEffectBeAttack()
            return true
        end

        local startPosition = target.PositionAttacker
        local progress = action.Duration / DURATION_MOVE_BACKWARD

        local currentPosition = (targetPosition - startPosition) * progress + startPosition
        launcher:SetPosition(currentPosition)
        return true
    end

    if action.Status == ATTACK_STATUS.END then
        -- 等待动画播完
        if action.IsPlayingTimeline then
            return true
        end
        return false
    end
end

function XUiPlanetRunningSystemAction:SetUiOnTop(transform)
    local index = transform.parent.childCount - 1
    transform:SetSiblingIndex(index)
end

return XUiPlanetRunningSystemAction