local XLevelScript90001 = XDlcScriptManager.RegLevelLogicScript(90001, "XLevel90001") --注册脚本类到管理器（逻辑脚本注册

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScript90001:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end

function XLevelScript90001:Init() --初始化逻辑
    self._tempLevelSwitcherUUID = self._proxy:GetSceneObjectUUID(self._tempLevelSwitcherPlaceId)

    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
end

---@param dt number @ delta time
function XLevelScript90001:Update(dt) --每帧更新逻辑
    self:OnUpdatePhase(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript90001:HandleEvent(eventType, eventArgs) --事件响应逻辑
end

function XLevelScript90001:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

function XLevelScript90001:InitPhase() --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    self._lastPhase = 0
end

function XLevelScript90001:SetPhase(phase) --跳转关卡阶段
    if phase == self._currentPhase then
        return
    end

    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, self.phase)

    self._lastPhase = self._currentPhase
    self._currentPhase = phase
end

function XLevelScript90001:OnEnterPhase(phase) --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
end
---@param dt number @ delta time
function XLevelScript90001:OnUpdatePhase(dt) --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
end

function XLevelScript90001:OnExitPhase(phase) --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
end

function XLevelScript90001:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end

function XLevelScript90001:HandlePhaseEvent(eventType, eventArgs) --处理阶段相关的事件响应，一般在这里跳转关卡阶段
end

return XLevelScript90001