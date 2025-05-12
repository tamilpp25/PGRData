---@class XLevelScript4008
local XLevelScript4008 = XDlcScriptManager.RegLevelLogicScript(4008, "XLevelScript4008")
---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScript4008:Ctor(proxy)
    self._levelId = 0
end

function XLevelScript4008:Init()
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self:InitPhase()
end

---@param dt number delta time
function XLevelScript4008:Update(dt)
    self:OnUpdatePhase(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript4008:HandleEvent(eventType, eventArgs)
    self:HandlePhaseEvent(eventType, eventArgs)
end

function XLevelScript4008:Terminate()
    self._proxy:TempStopLevelPlayerTimerUi()
end

--region Phase 关卡阶段

local GamePhase = {
    None = 0,
    GameReady = 1,
    GamePlay = 2,
    GameEnd = 3,
}
function XLevelScript4008:InitPhase() --初始化关卡各个阶段的相关变量
    self._currentPhase = GamePhase.None
    self._lastPhase = GamePhase.None
    self._levelId = self._proxy:GetCurrentLevelId() -- 关卡ID(4008新手引导，4009普通)
    if self._levelId == 4008 then
        self._transformBoxPlaceId = 8
        self._playTime = 50
        self._winTriggerPlaceId = 26
        self._winNpc   = 1
        self._startPos = { x = 490.45, y = 150.55, z = 1334.78 }
        self._startAirWallPlaceId = 30
        self._startNpc = 2
        self._looseNpc = 3
        self._teachTime= 1.5

    elseif self._levelId == 4009 then
        self._transformBoxPlaceId = 100021
        self._playTime = 60
        self._winTriggerPlaceId = 100005
        self._winNpc   = 100001
        self._startPos = { x = 409.4, y = 106.6, z = 992.04 }
        self._startAirWallPlaceId = 100040
        self._startNpc = 100002
        self._looseNpc   = 100003

    elseif self._levelId == 4010 then
        self._transformBoxPlaceId = 200014
        self._playTime = 60
        self._winTriggerPlaceId = 200045
        self._winNpc   = 200001
        self._startPos = { x = 170, y = 83, z = 1088 }
        self._startAirWallPlaceId = 200009
        self._startNpc   = 200002
        self._looseNpc   = 200003

    end
    self._winNpcUUID = self._proxy:GetNpcUUID(self._winNpc)         --隐藏结算npc
    self._proxy:SetNpcActive(self._winNpcUUID, false)
    self._looseNpcUUID = self._proxy:GetNpcUUID(self._looseNpc)
    self._proxy:SetNpcActive(self._looseNpcUUID, false)
    self._startNpcUUID = self._proxy:GetNpcUUID(self._startNpc)
    self._proxy:SetSceneObjectActive(self._startAirWallPlaceId, true)   --初始化墙
    self:SetPhase(GamePhase.GameReady)
end

function XLevelScript4008:SetPhase(phase) --跳转关卡阶段
    if phase == self._currentPhase then
        return
    end
    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, phase)
    self._lastPhase = self._currentPhase
    self._currentPhase = phase
end

function XLevelScript4008:OnEnterPhase(phase)        --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
    if phase == GamePhase.GamePlay then                          --游戏开始阶段
        self._proxy:StartLevelPlayTimer(self._playTime, true)
    end
    if phase == GamePhase.GameEnd then                          --游戏结算阶段
        local curTime = self._proxy:GetLevelPlayTimerCurTime()
        self._proxy:TempStopLevelPlayerTimerUi()
        if curTime > 0 then
            self._proxy:SetNpcActive(self._winNpcUUID, true)     --胜利显示npc1
        elseif curTime <= 0 then
            self._proxy:SetNpcActive(self._looseNpcUUID, true)   --失败显示npc2
        end
    end
end

function XLevelScript4008:OnUpdatePhase(dt) --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
    if self._levelId == 4008 and self._teachTime >= 0 then
        self._teachTime = self._teachTime - dt
        if self._teachTime <= 0 then
            self._proxy:ShowBigWorldTeach(2001)
        end
    end

    if self._currentPhase == GamePhase.GamePlay then     -- 开始阶段倒计时逻辑
        if self._proxy:GetLevelPlayTimerCurTime() <= 0 then
            self:SetPhase(GamePhase.GameEnd)
        end
    end
end

function XLevelScript4008:OnExitPhase(phase) --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
    if phase == GamePhase.GameReady then

    elseif phase == GamePhase.GamePlay then
    end
end

function XLevelScript4008:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end

function XLevelScript4008:HandlePhaseEvent(eventType, eventArgs) --处理阶段相关的事件响应，一般在这里跳转关卡阶段
    if eventType == EWorldEvent.ActorTrigger then
        if eventArgs.HostSceneObjectPlaceId == self._winTriggerPlaceId and eventArgs.TriggerState == ETriggerState.Enter then        --到达终点触发结束流程
            self:SetPhase(GamePhase.GameEnd)
        end

        if eventArgs.HostSceneObjectPlaceId == self._transformBoxPlaceId and eventArgs.TriggerState == ETriggerState.Enter then          --死区传送回出发点
            local playerNpcUUID = self._proxy:GetLocalPlayerNpcId() --获取玩家npc
            XScriptTool.DoTeleportNpcPosWithBlackScreen(self._proxy, playerNpcUUID, self._startPos)            
        end
    end
    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) then
            if eventArgs.TargetId == self._winNpcUUID or eventArgs.TargetId == self._looseNpcUUID then                                   --无论胜负返回空花
                self._proxy:ExitInstanceLevel(false)                     --退出时不保存进度
            elseif eventArgs.TargetId == self._startNpcUUID then
                self._proxy:SetNpcActive(self._startNpcUUID, false) --交互起始npc后隐藏起始npc，和透明阻挡
                self._proxy:SetSceneObjectActive(self._startAirWallPlaceId, false)
                self:SetPhase(GamePhase.GamePlay)
            end
        end
    end
end
--endregion Phase 关卡阶段


return XLevelScript4008
