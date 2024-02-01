local XSpecialTrainActionRandom = require("XUi/XUiSpecialTrainBreakthrough/XSpecialTrainActionRandom")
---@class XPanelRoleListActionRandom:XSpecialTrainActionRandom
local XPanelRoleListActionRandom = XClass(XSpecialTrainActionRandom, "XPanelRoleListActionRandom")

function XPanelRoleListActionRandom:Ctor()
    ---@type XUiPanelRoleModel[]
    self._PanelRoleModelList = false
end

---@param animator UnityEngine.Animator
---@param actionArray string[]|nil 当状态机配置好Parameters时可不传, By zlb
function XPanelRoleListActionRandom:SetAnimatorByPanelRoleModelList(animator, actionArray, panelRoleModelList)
    self._Animator = animator
    local actionArrayFromParam = self:_GetActionArrayByParam(animator)
    if #actionArrayFromParam > 0 then
        self._ActionArray = actionArrayFromParam
    else
        self._ActionArray = actionArray
    end
    self._PanelRoleModelList = panelRoleModelList
end

function XPanelRoleListActionRandom:Play()
    self:_RandomIdleDuration()
    self:_PlayRandomAnimation()
    self._IdleActionName = self:_GetRunningActionName(self._Animator)
    -- 第一次播放，间隔总是1秒
    self._IdleTime = self._TimeToPlayAction - 1
end

function XPanelRoleListActionRandom:Stop()
    self.Super:Stop()
    self._PanelRoleModelList = false
end

function XPanelRoleListActionRandom:_PlayNextAction()
    local nextActionName = self:_GetNextAction()
    if not nextActionName then
        return false
    end
    if self._PanelRoleModelList then
        for _, panelRoleModel in ipairs(self._PanelRoleModelList) do
            panelRoleModel:CrossFadeAnim(nextActionName, self._CrossFadeTime)
        end
    end
    return true
end

return XPanelRoleListActionRandom
