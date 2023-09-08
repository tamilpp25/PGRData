local XLevelScriptXXX = XDlcScriptManager.RegLevelScript(0000, "XLevelXXX") --注册脚本类到管理器

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScriptXXX:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end

function XLevelScriptXXX:Init() --初始化逻辑

end

---@param dt number @ delta time
function XLevelScriptXXX:Update(dt) --每帧更新逻辑

end

---@param eventType number
---@param eventArgs userdata
function XLevelScriptXXX:HandleEvent(eventType, eventArgs) --事件响应逻辑
    self:HandlePhaseEvent(eventType, eventArgs)
end

function XLevelScriptXXX:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

function XLevelScriptXXX:InitPhase() --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    self._lastPhase = 0
    self._phase1HasStartDelayTranslate = false
end

function XLevelScriptXXX:SetPhase(phase) --跳转关卡阶段
    if phase == self._currentPhase then
        return
    end

    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, self.phase)

    self._lastPhase = self._currentPhase
    self._currentPhase = phase
end

function XLevelScriptXXX:OnEnterPhase(phase) --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
    if phase == 1 then

    elseif phase == 2 then

    end
end

function XLevelScriptXXX:OnUpdatePhase() --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
    if self._currentPhase == 1 then

    end
end

function XLevelScriptXXX:OnExitPhase(phase) --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
    if phase == 1 then
        self._phase1HasStartDelayTranslate = false --有可能再次回到phase1，故重置
    end
end

function XLevelScriptXXX:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end

function XLevelScriptXXX:HandlePhaseEvent(eventType, eventArgs) --处理阶段相关的事件响应，一般在这里跳转关卡阶段
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

return XLevelScriptXXX