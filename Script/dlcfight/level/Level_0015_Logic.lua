--- 白龙boss战
local XLevel0015 = XDlcScriptManager.RegLevelLogicScript(0015, "XLevel0015")
local Config = require("Level/LevelConfig/Hunt01BossFightConfig") -- 读取场景物体的配置数据,作为实例存在本地
local Tool = require("Level/Common/XLevelTools")
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevel0015:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()

    self._worldId = self._proxy:GetWorldId()
    if Config.Boss[self._worldId] == nil then
        self._worldId = 2
    end

    self._wightDragonRespawnId = Config.Boss[self._worldId].WightDragon
    self._spearFatalitySoundFx = 8002105
    self._bossHidePos = { x = 60, y = -200, z = 60 }
    self._bossBornPos = { x = 60, y = 1.95, z = 60 }
    self._bossBornRot = { x = 0, y = 180, z = 0 }
    self._wightDragonNpcId = nil ---boss的id
    self._playerNpcContainer = XPlayerNpcContainer.New()


    self._deathZonePlaceId = 509999
    self._outwardsDeathZonePlaceId = 509998 ---暂时用来应对玩家挤出空气墙的处理

    self._debug = false
end

function XLevel0015:Init()
    self:InitPhase()
    self:InitWightDragon()
    self:InitPlayer()
    self:InitListen()
end

---@param dt number @ delta time
function XLevel0015:Update(dt)
    self._timer:Update(dt)
    self:OnUpdatePhase(dt)
    self:ProcessDebugInput()
end

---@param eventType number
---@param eventArgs userdata
function XLevel0015:HandleEvent(eventType, eventArgs)
    self.Super.HandleEvent(self, eventType, eventArgs)
    self:HandlePhaseEvent(eventType, eventArgs)
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)

    if eventType == EWorldEvent.ActorTrigger then
        --[[        XLog.Debug("XLevelBossFight1 SceneObjectTriggerEvent:"
                        .. " TouchType " .. tostring(eventArgs.TouchType)
                        .. " EnteredActorUUID " .. tostring(eventArgs.EnteredActorUUID)
                        .. " HostSceneObjectPlaceId " .. tostring(eventArgs.HostSceneObjectPlaceId)
                        .. " TriggerId " .. tostring(eventArgs.TriggerId)
                        .. " TriggerState " .. tostring(eventArgs.TriggerState)
                        .. " Log自关卡"
                )]]
        if eventArgs.HostSceneObjectPlaceId == self._deathZonePlaceId and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then
            self._proxy:ResetNpcToSafePoint(eventArgs.EnteredActorUUID)
        end
        if eventArgs.HostSceneObjectPlaceId == self._outwardsDeathZonePlaceId and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) and eventArgs.TriggerState == ETriggerState.Exit then
            self._proxy:ResetNpcToCheckPoint(eventArgs.EnteredActorUUID)
            XLog.Warning("注意！npc ".. tostring(eventArgs.EnteredActorUUID).."穿到战斗场景外了")
        end
    end

    if eventType == EWorldEvent.Behavior2ScriptMsg then
        if eventArgs.MsgType == 1001 and self._proxy:CheckNpc(self._wightDragonNpcId) then
            --天基
            self:SpearFatality()
        elseif eventArgs.MsgType == 100 then
            --设置空气墙碰撞
            self:EnableAirWallToNpc(eventArgs.Int[1], eventArgs.Int[2] == 0)
        end
    end

end

function XLevel0015:InitPhase()
    --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    self._lastPhase = 0
    self._phaseStartedDelayTranslate = false ---阶段延迟跳转需要设置为true
    self._phaseTimeCount = 0

    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化关卡阶段参数完成")
end

function XLevel0015:InitWightDragon()
    --生成怪物
    self._wightDragonNpcId = self._proxy:GenerateNpc(self._wightDragonRespawnId, ENpcCampType.Camp2, self._bossBornPos, self._bossBornRot)
    self._proxy:RegisterBehavior2ScriptMsgEvent(self._wightDragonNpcId)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>召唤npc白龙完成")
end

function XLevel0015:InitPlayer()
    self._playerNpcContainer:Init(
            function(npc)
                self:OnPlayerNpcCreate(npc)
            end,
            function(npc)
                self:OnPlayerNpcDestroy(npc)
            end
    )
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化关卡用玩家参数完成")
end

function XLevel0015:InitListen()
    self._proxy:RegisterSceneObjectTriggerEvent(self._deathZonePlaceId, 1) --死区
    self._proxy:RegisterSceneObjectTriggerEvent(self._outwardsDeathZonePlaceId, 1) --外部死区，一个临时解决方案
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化其他监听内容完成")
end

function XLevel0015:OnPlayerNpcCreate(npc)
    self._proxy:RegisterNpcEvent(EWorldEvent.NpcCastSkill, npc)
    self._proxy:RegisterNpcEvent(EWorldEvent.NpcExitSkill, npc)
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    self._proxy:SetSceneColliderIgnoreCollision(npc, "MonsterAirWall", -1, true) --用于限制boss在场边活动的空气墙
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注册角色技能监听：" .. npc)
end

function XLevel0015:OnPlayerNpcDestroy(npc)
    self._proxy:UnregisterNpcEvent(EWorldEvent.NpcCastSkill, npc)
    self._proxy:UnregisterNpcEvent(EWorldEvent.NpcExitSkill, npc)
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注销角色技能监听：" .. npc)
end

function XLevel0015:ProcessDebugInput()
    if self._debug then
        if self._proxy:IsKeyDown(ENpcOperationKey.Ball11) then
        elseif self._proxy:IsKeyDown(ENpcOperationKey.Ball12) then
            self:SpearFatality()
        elseif self._proxy:IsKeyDown(ENpcOperationKey.Ball10) then
        elseif self._proxy:IsKeyDown(ENpcOperationKey.Ball9) then
        end
    end
end

---跳转关卡阶段
function XLevel0015:SetPhase(phase)
    if phase == self._currentPhase then
        return
    end

    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, self.phase)

    self._lastPhase = self._currentPhase
    self._currentPhase = phase
    self._phaseTimeCount = 0
end

---当前关卡阶段需要一直执行的逻辑在这里实现。一般用作执行判断、执行持续性的功能、跳转阶段
function XLevel0015:OnUpdatePhase(dt)
    if self._phaseTimeCount == nil then
        self._phaseTimeCount = 0
    end
    self._phaseTimeCount = self._phaseTimeCount + dt
    if self._currentPhase == 0 then
        if not self._proxy:CheckNpc(self._wightDragonNpcId) then
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>检测到boss死亡")
            self._proxy:SettleFight(true)
            self._proxy:FinishFight()
        end
    elseif self._currentPhase == 1 then
    end
end

---进入一个关卡阶段时需要做的事情在这里实现。一般用作设置阶段所需的环境
function XLevel0015:OnEnterPhase(phase)
    if phase == 1 then
    elseif phase == 2 then
    end
end

---关卡阶段改变时需要执行的逻辑，一般用于通知外部
function XLevel0015:OnPhaseChanged(lastPhase, nextPhase)
end

---处理阶段相关的事件响应、状态检测、信息获取
function XLevel0015:HandlePhaseEvent(eventType, eventArgs)
    if self._currentPhase == 1 then
    elseif self._currentPhase == 2 then
    end
end

---天基演出流程
function XLevel0015:SpearFatality()
    for _, npc in pairs(self._playerNpcList) do
        self._proxy:ApplyMagic(npc, npc, 5000003, 1)
        self._timer:Schedule(0.5, self, self.RemoveBlackScreen, npc)
    end
    self:SetFightUiActive(false)
    self._timer:Schedule(11, self, self.SetFightUiActive, true)

    self._timer:Schedule(0.5, self, self.PlaySpearFatality)
end

function XLevel0015:RemoveBlackScreen(npc)
    self._proxy:ApplyMagic(npc, npc, 5000006, 1)
end

function XLevel0015:PlaySpearFatality()
    if self._proxy:CheckNpc(self._wightDragonNpcId) then
        self._proxy:PlayCameraTimeline("SprearFatality01", self._wightDragonNpcId, 0, 0, 0)
        self._timer:Schedule(10.5, "SprearFatality01",
            function(name, npcId)
                self._proxy:StopCameraTimeline(name, npcId)
            end, self._wightDragonNpcId)
        self._proxy:ApplyMagic(self._wightDragonNpcId, self._wightDragonNpcId, self._spearFatalitySoundFx, 1)
    end
end

function XLevel0015:EnableAirWallToNpc(enable, npc)
    self._proxy:SetSceneColliderIgnoreCollision(npc, "AirWalls", -1, enable)
    self._proxy:SetSceneColliderIgnoreCollision(npc, "OuterAirWall", -1, enable)
    self._proxy:SetSceneColliderIgnoreCollision(npc, "MonsterAirWall", -1, enable)
end

function XLevel0015:SetFightUiActive(active)
    for _, npc in pairs(self._playerNpcList) do
        if active then
            self._proxy:ApplyMagic(npc, npc, 5000008)
        else
            self._proxy:ApplyMagic(npc, npc, 5000007)
        end
    end
end

---Npc是否处在濒死状态
function XLevel0015:IsNpcDying(npcId)
    return self._proxy:CheckNpcAction(npcId, ENpcAction.Dying)
end

---Npc是否死亡
function XLevel0015:IsNpcDead(npcId)
    return self._proxy:CheckNpcAction(npcId, ENpcAction.Dying) or self._proxy:CheckNpcAction(npcId, ENpcAction.Death)
end

function XLevel0015:Terminate()

end

return XLevel0015