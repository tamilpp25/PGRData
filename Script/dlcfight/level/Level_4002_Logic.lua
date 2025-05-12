local XLevelScript4002 = XDlcScriptManager.RegLevelLogicScript(4002, "XLevel4002") --注册脚本类到管理器（逻辑脚本注册

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScript4002:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。

    self._tempLevelSwitcherPlaceId = 1
end

function XLevelScript4002:Init() --初始化逻辑
    self._tempLevelSwitcherUUID = self._proxy:GetSceneObjectUUID(self._tempLevelSwitcherPlaceId)

    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
end

---@param dt number @ delta time
function XLevelScript4002:Update(dt) --每帧更新逻辑
    self:OnUpdatePhase(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript4002:HandleEvent(eventType, eventArgs) --事件响应逻辑
    self:HandlePhaseEvent(eventType, eventArgs)

    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) then --是玩家发起的交互
            if eventArgs.TargetId == self._tempLevelSwitcherUUID then
                local pos = {x = 575.5166, y = 145.0198, z = 1338.368}
                self._proxy:SwitchLevel(4001, pos)
            end
        end
    end
end

function XLevelScript4002:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

function XLevelScript4002:InitPhase() --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    self._lastPhase = 0
end

function XLevelScript4002:SetPhase(phase) --跳转关卡阶段
    if phase == self._currentPhase then
        return
    end

    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, self.phase)

    self._lastPhase = self._currentPhase
    self._currentPhase = phase
end

function XLevelScript4002:OnEnterPhase(phase) --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
end
---@param dt number @ delta time
function XLevelScript4002:OnUpdatePhase(dt) --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
end

function XLevelScript4002:OnExitPhase(phase) --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
end

function XLevelScript4002:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end

function XLevelScript4002:HandlePhaseEvent(eventType, eventArgs) --处理阶段相关的事件响应，一般在这里跳转关卡阶段
end

return XLevelScript4002