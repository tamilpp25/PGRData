---@class XUiPanelRoleModelAnimationEvent
local XUiPanelRoleModelAnimationEvent = XClass(nil, "XUiPanelRoleModelAnimationEvent")

function XUiPanelRoleModelAnimationEvent:Ctor()
    self._EffectPlayedThisAction = false
end

---@param panelRoleModel XUiPanelRoleModel
function XUiPanelRoleModelAnimationEvent:AddAnimationEventListener(panelRoleModel)
    local model = panelRoleModel:GetCurRoleModel()
    ---@type XAnimationFrameEventManager
    local component = XUiHelper.TryAddComponent(model, typeof(CS.XAnimationFrameEventManager))
    component:SetCallBackPlayEffect(function(params)
        local id = tonumber(params)
        if id then
            local effect = panelRoleModel:GetEffectByKey(id)
            if effect then
                effect.gameObject:SetActiveEx(true)
                if not self._EffectPlayedThisAction then
                    self._EffectPlayedThisAction = {}
                end
                self._EffectPlayedThisAction[id] = true
            end
        end
    end)
    component:SetCallBackStopEffect(function(params)
        local id = tonumber(params)
        if id then
            local effect = panelRoleModel:GetEffectByKey(id)
            if effect then
                effect.gameObject:SetActiveEx(false)
            end
        end
    end)
end

-- 通过动画帧时间播放的特效, 在切换动作时, 需要停止
---@param panelRoleModel XUiPanelRoleModel
function XUiPanelRoleModelAnimationEvent:StopEffectThisAction(panelRoleModel)
    if self._EffectPlayedThisAction then
        for id, _ in pairs(self._EffectPlayedThisAction) do
            local effect = panelRoleModel:GetEffectByKey(id)
            if effect then
                effect.gameObject:SetActiveEx(false)
            end
        end
    end
end

return XUiPanelRoleModelAnimationEvent