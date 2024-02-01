---@class XSpecialTrainActionRandom
local XSpecialTrainActionRandom = XClass(nil, "XSpecialTrainActionRandom")

function XSpecialTrainActionRandom:Ctor()
    ---@type UnityEngine.Animator
    self._Animator = false
    self._ActionArray = false
    self._RandomActionArray = false
    ---@type XUiPanelRoleModel
    self._PanelRoleModel = false
    self._LastIndex = false
    self._AnimatorTimer = false
    self._IdleTime = 0
    self._IdleActionName = false
    self._IsRandomTimeToPlay = true
    -- 随机播放动作的间隔
    self._TimeToPlayAction = 0
    self._CrossFadeTime = 0.2
    self._CrossFadeConflictProtectTime = 1
end

---@param animator UnityEngine.Animator
---@param actionArray string[]|nil 当状态机配置好Parameters时可不传, By zlb
function XSpecialTrainActionRandom:SetAnimator(animator, actionArray, panelRoleModel)
    self._Animator = animator
    local actionArrayFromParam = self:_GetActionArrayByParam(animator)
    if #actionArrayFromParam > 0 then
        self._ActionArray = actionArrayFromParam
    else
        self._ActionArray = actionArray
    end
    self._PanelRoleModel = panelRoleModel
end

function XSpecialTrainActionRandom:SetAnimatorWithCustomActionArray(animator, actionArray, panelRoleModel, time)
    self._Animator = animator
    if #actionArray > 0 then
        self._ActionArray = actionArray
    else
        self._ActionArray = self:_GetActionArrayByParam(animator)
    end
    self._PanelRoleModel = panelRoleModel
    if time then
        self._IsRandomTimeToPlay = false
        self._TimeToPlayAction = time
    end
end

function XSpecialTrainActionRandom:Play()
    self:_RandomIdleDuration()
    self:_PlayRandomAnimation()
    self._IdleActionName = self:_GetRunningActionName(self._Animator)
    -- 第一次播放，间隔总是1秒
    self._IdleTime = self._TimeToPlayAction - 1
end

function XSpecialTrainActionRandom:Stop()
    if self._AnimatorTimer then
        XScheduleManager.UnSchedule(self._AnimatorTimer)
    end
    self._Animator = false
    self._ActionArray = false
    self._RandomActionArray = false
    self._PanelRoleModel = false
    self._LastIndex = false
    self._AnimatorTimer = false
    self._IdleTime = 0
    self._IdleActionName = false
    self._TimeToPlayAction = 0
end

-- 策划做了状态机，里面放了要使用的多组动作
function XSpecialTrainActionRandom:_PlayRandomAnimation()
    if self._AnimatorTimer then
        return
    end
    local animator = self._Animator
    self._AnimatorTimer = XScheduleManager.ScheduleForever(function()
        if not animator or XTool.UObjIsNil(animator) then
            self:Stop()
            return
        end

        local currentName, animatorClipInfo = self:_GetRunningActionName(animator)
        if currentName == self._IdleActionName then
            self._IdleTime = self._IdleTime + CS.UnityEngine.Time.deltaTime
            if self._IdleTime > self._TimeToPlayAction then
                -- 融合时间内有事件冲突
                if not self:_IsAnimatorEventConflict(animator, animatorClipInfo) or
                    -- 冲突时间过久，强制播放
                    (self._IdleTime > self._TimeToPlayAction + self._CrossFadeConflictProtectTime) then
                    self._IdleTime = 0
                    self:_PlayNextAction()
                    self:_RandomIdleDuration()
                end
            end
        end
    end, 0)
end

function XSpecialTrainActionRandom:_PlayNextAction()
    local nextActionName = self:_GetNextAction()
    if not nextActionName then
        return false
    end
    if self._PanelRoleModel then
        self._PanelRoleModel:CrossFadeAnim(nextActionName, self._CrossFadeTime)
    end
    return true
end

function XSpecialTrainActionRandom:_GetNextAction()
    local length = #self._ActionArray
    if length == 1 then
        return self._ActionArray[1]
    end
    if length == 0 then
        return false
    end
    self._LastIndex = self:_GetDifferentIndex()
    return self._ActionArray[self._LastIndex]
end

function XSpecialTrainActionRandom:_GetDifferentIndex()
    local index = math.random(1, #self._ActionArray)
    if index == self._LastIndex then
        return self:_GetDifferentIndex()
    end
    return index
end

function XSpecialTrainActionRandom:_GetRunningActionName(animator)
    local animatorClipInfo, name = self:_GetRunningActionClipInfo(animator)
    return name, animatorClipInfo
end

-- 由于使用了crossFade，融合时会同时触发两个动作的事件，导致之前动作的表情，覆盖了之后动作的表情
-- 检查动画事件是否在两个动作融合时间内触发
function XSpecialTrainActionRandom:_IsAnimatorEventConflict(animator, animatorClipInfo)
    if not animatorClipInfo then
        return false
    end
    local passedActionTime = self:_GetPassedActionTime(animator)
    for i = 0, animatorClipInfo.clip.events.Length - 1 do
        local animationEvent = animatorClipInfo.clip.events[i]
        local animationEventTime = animationEvent.time
        if passedActionTime + self._CrossFadeTime > animationEventTime and passedActionTime < animationEventTime then
            return true
        end
    end
    return false
end

-- 当前动作已播放时间
function XSpecialTrainActionRandom:_GetPassedActionTime(animator)
    local layer = 0
    local stateInfo = animator:GetCurrentAnimatorStateInfo(layer)
    return stateInfo.normalizedTime * stateInfo.length
end

function XSpecialTrainActionRandom:_RandomIdleDuration()
    if self._IsRandomTimeToPlay then
        self._TimeToPlayAction = math.random(30, 50) / 10
    end
end

function XSpecialTrainActionRandom:_GetRunningActionClipInfo(animator)
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

function XSpecialTrainActionRandom:_GetActionArrayByParam(animator)
    local actionArray = {}
    local parameters = animator.parameters
    for i = 0, parameters.Length - 1 do
        local param = parameters[i]
        local name = param.name
        actionArray[#actionArray + 1] = name
    end
    return actionArray
end

return XSpecialTrainActionRandom
