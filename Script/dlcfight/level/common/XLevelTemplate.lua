local XLevelTemplate = XClass(nil, "XLevelProgress")
local XLevelTools = require("Level/Common/XLevelTools")

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelTemplate:Ctor(proxy)
    self._proxy = proxy
    self._timer = XLevelTools.NewTimer()

    self._localPlayerNpcId = self._proxy:GetLocalPlayerNpcId()
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkill)
    self:InitPhase()
end

function XLevelTemplate:InitPhase() --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    self._lastPhase = 0
    self._phase1HasStartDelayTranslate = false
end

function XLevelTemplate:SetPhase(phase) --跳转关卡阶段
    if phase == self._currentPhase then
        return
    end

    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, self.phase)

    self._lastPhase = self._currentPhase
    self._currentPhase = phase
end

function XLevelTemplate:OnEnterPhase(phase) --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
    if phase == 1 then

    elseif phase == 2 then

    end
end

function XLevelTemplate:OnUpdatePhase() --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
    if self._currentPhase == 1 then

    end
end

function XLevelTemplate:OnExitPhase(phase) --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
    if phase == 1 then
        self._phase1HasStartDelayTranslate = false --有可能再次回到phase1，故重置
    end
end

function XLevelTemplate:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end

function XLevelTemplate:HandleEvent(eventType, eventArgs)
    self:HandlePhaseEvent(eventType, eventArgs)
end

function XLevelTemplate:HandlePhaseEvent(eventType, eventArgs) --处理阶段相关的事件响应，一般在这里跳转关卡阶段
    if self._currentPhase == 1 then
        if eventType == EWorldEvent.NpcCastSkill
            and eventArgs.LauncherId == self._localPlayerNpcId
            and not self._phase1HasStartDelayTranslate then

            XLevelTools.TimerSetDelayFunction(self._timer, self, 1.0, self.SetPhase, self._currentPhase + 1)
            self._phase1HasStartDelayTranslate = true
        end
    elseif self._currentPhase == 2 then

    end
end

return XLevelTemplate