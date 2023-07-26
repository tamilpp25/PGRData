--- 白龙boss战
local XLevel0015 = XDlcScriptManager.RegLevelScript(0015, "XLevel0015")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs
local Config = require("XDLCFight/Level/LevelConfig/Hunt01BossFightConfig") -- 读取场景物体的配置数据,作为实例存在本地
local Tool = require("XDLCFight/Level/Common/XLevelTools")
local XPlayerNpcContainer = require("XDLCFight/Level/Common/XPlayerNpcContainer")
local Timer = require("XDLCFight/Level/Common/XTaskScheduler")

local _cameraResRefTable = {

}

function XLevel0015.GetCameraResRefTable()
    return _cameraResRefTable
end

---@param proxy StatusSyncFight.XScriptLuaProxy
function XLevel0015:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()

    self._worldId = FuncSet.GetWorldId()
    if Config.Boss[self._worldId] == nil then
        self._worldId = 2
    end

    self._wightDragonRespawnId = Config.Boss[self._worldId].WightDragon
    self._wightDragonBossRefId = 2
    self._spearFatalitySoundFx = 8002105
    self._bossHidePos = { x = 60, y = -200, z = 60 }
    self._bossBornPos = { x = 60, y = 1.95, z = 60 }
    self._bossBornRot = { x = 0, y = 180, z = 0 }
    self._wightDragonNpcId = nil ---boss的id
    self._playerNpcContainer = XPlayerNpcContainer.New()
    self._playerRescueDict = {}

--[[    self._switches = {
        {
            placeId = 1,
            agent = nil,
            object = self,
            func = self.PlaySceneAnim,
            param = nil,
            times = 1,
            defaultEnable = true
        },
    }]]

    self._deathZonePlaceId = 9999
    self._outwardsDeathZonePlaceId = 9998 ---暂时用来应对玩家挤出空气墙的处理

    self._debug = false
end

function XLevel0015:Init()
    self:InitPhase()
    self:InitWightDragon()
    self:InitPlayer()
    --self:InitSwitch()
    self:InitListen()

end

---@param dt number @ delta time
function XLevel0015:Update(dt)
    self._timer:Update(dt)
    self:OnUpdatePhase(dt)
    self:PlayerInteract()
    self:OnInteractButton()
end

function XLevel0015:OnInteractButton()
    if self._debug then
        if FuncSet.IsKeyDown(ENpcOperationKey.Ball11) then
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball12) then
            self:SpearFatality()
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball10) then
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball9) then
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XLevel0015:HandleEvent(eventType, eventArgs)
    self.Super.HandleEvent(self, eventType, eventArgs)
    self:HandlePhaseEvent(eventType, eventArgs)
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)

    if eventType == EScriptEvent.SceneObjectTrigger then
        --[[        XLog.Debug("XLevelBossFight1 SceneObjectTriggerEvent:"
                        .. " TouchType " .. tostring(eventArgs.TouchType)
                        .. " SourceActorId " .. tostring(eventArgs.SourceActorId)
                        .. " SceneObjectId " .. tostring(eventArgs.SceneObjectId)
                        .. " TriggerId " .. tostring(eventArgs.TriggerId)
                        .. " TriggerState " .. tostring(eventArgs.TriggerState)
                        .. " Log自关卡"
                )]]
        if eventArgs.SceneObjectId == self._deathZonePlaceId and FuncSet.IsPlayerNpc(eventArgs.SourceActorId) then
            FuncSet.ResetNpcToSafePoint(eventArgs.SourceActorId)
        end
        if eventArgs.SceneObjectId == self._outwardsDeathZonePlaceId and FuncSet.IsPlayerNpc(eventArgs.SourceActorId) and eventArgs.TriggerState == ESceneObjectTriggerState.Exit then
            FuncSet.ResetNpcToCheckPoint(eventArgs.SourceActorId)
            XLog.Warning("注意！npc ".. tostring(eventArgs.SourceActorId).."穿到战斗场景外了")
        end
    elseif eventType == EScriptEvent.NpcInteractComplete then
        --交互完成
        self:OnNpcInteractComplete(eventArgs)
    end

    if eventType == EScriptEvent.Behavior2ScriptMsg then
        if eventArgs.MsgType == 1001 and FuncSet.CheckNpc(self._wightDragonNpcId) then
            --天基
            self:SpearFatality()
        elseif eventArgs.MsgType == 100 then
            --设置空气墙碰撞
            self:EnableAirWallToNpc(eventArgs.Int[1], eventArgs.Int[2] == 0)
        end
    end

end

function XLevel0015:GainControl()

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
    local id = FuncSet.GetGeneratedNpc(self._wightDragonBossRefId)
    if id <= 0 then
        --防止断线重连时重复创建怪物
        self._wightDragonNpcId = FuncSet.GenerateNpc(self._wightDragonBossRefId, self._wightDragonRespawnId, ENpcCampType.Camp2, self._bossBornPos, self._bossBornRot)
    else
        self._wightDragonNpcId = id
    end
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

function XLevel0015:InitSwitch()
    self._switches = Tool.InitSwitch(self._switches)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化场景中开关完成")
end

function XLevel0015:InitListen()
    self._proxy:RegisterSceneObjectTriggerEvent(self._deathZonePlaceId, 1) --死区
    self._proxy:RegisterSceneObjectTriggerEvent(self._outwardsDeathZonePlaceId, 1) --外部死区，一个临时解决方案
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化其他监听内容完成")
end

function XLevel0015:OnPlayerNpcCreate(npc)
    self._proxy:RegisterNpcEvent(EScriptEvent.NpcCastSkill, npc)
    self._proxy:RegisterNpcEvent(EScriptEvent.NpcExitSkill, npc)
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    FuncSet.SetSceneColliderIgnoreCollision(npc, "MonsterAirWall", -1, true) --用于限制boss在场边活动的空气墙
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注册角色技能监听：" .. npc)
end

function XLevel0015:OnPlayerNpcDestroy(npc)
    self._proxy:UnregisterNpcEvent(EScriptEvent.NpcCastSkill, npc)
    self._proxy:UnregisterNpcEvent(EScriptEvent.NpcExitSkill, npc)
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注销角色技能监听：" .. npc)
end

---玩家之间的交互
function XLevel0015:PlayerInteract()
    --玩家救援复活交互检测
    for i = 1, #self._playerNpcList do
        local npcA = self._playerNpcList[i]
        for j = 1, #self._playerNpcList do
            local npcB = self._playerNpcList[j]
            self:CheckPlayerRescueInteract(npcA, npcB, 3.5)
        end
    end
end

---玩家救援交互
---@param launcher number
---@param target number
---@param dist number @distance
function XLevel0015:CheckPlayerRescueInteract(launcher, target, dist)
    if target == launcher then
        --不能对自己交互
        return
    end

    local curTarget = self._playerRescueDict[launcher]
    if curTarget ~= nil then
        local isInRange = FuncSet.CheckNpcDistance(launcher, curTarget, dist)
        if not isInRange or self:IsNpcDead(launcher) or not self:IsNpcDying(curTarget) then
            self._playerRescueDict[launcher] = nil
            FuncSet.CloseInteraction(launcher)
            XLog.Debug(string.format("Level CloseInteraction Rescue, launcher:%d  target:%d ", launcher, curTarget, dist))
        end
    else
        local isInRange = FuncSet.CheckNpcDistance(launcher, target, dist)
        if isInRange and not self:IsNpcDead(launcher) and self:IsNpcDying(target) then
            self._playerRescueDict[launcher] = target
            FuncSet.ShowInteraction(launcher, target, FuncSet.GetRescueTime(), EInteractType.Rescue)
            XLog.Debug(string.format("Level ShowInteraction Rescue, launcher:%d  target:%d ", launcher, target, dist))
        end
    end
end

---@param eventArgs StatusSyncFight.NpcEventArgs
function XLevel0015:OnNpcInteractComplete(eventArgs)
    local npc = eventArgs.NpcId
    local target = self._playerRescueDict[npc]
    if target then
        FuncSet.RebornNpc(npc, target) --复活救援对象
        self._playerRescueDict[npc] = nil --清除救援对象记录
    end
    FuncSet.CloseInteraction(npc, false) --关闭救援者的交互按钮
end

---Npc是否处在濒死状态
function XLevel0015:IsNpcDying(npcId)
    return FuncSet.CheckNpcAction(npcId, ENpcAction.Dying)
end

---Npc是否死亡
function XLevel0015:IsNpcDead(npcId)
    return FuncSet.CheckNpcAction(npcId, ENpcAction.Dying) or FuncSet.CheckNpcAction(npcId, ENpcAction.Death)
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
        if not FuncSet.CheckNpc(self._wightDragonNpcId) then
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>检测到boss死亡")
            FuncSet.FinishFight(true)
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
        FuncSet.ApplyMagic(npc, npc, 5000003, 1)
        self._timer:Schedule(0.5, self, self.RemoveBlackScreen, npc)
    end
    self:SetFightUiActive(false)
    self._timer:Schedule(11, self, self.SetFightUiActive, true)

    self._timer:Schedule(0.5, self, self.PlaySpearFatality)
end

function XLevel0015:RemoveBlackScreen(npc)
    FuncSet.ApplyMagic(npc, npc, 5000006, 1)
end

function XLevel0015:PlaySpearFatality()
    if FuncSet.CheckNpc(self._wightDragonNpcId) then
        FuncSet.PlayCameraTimeline("SprearFatality01", self._wightDragonNpcId, 0, 0, 0)
        self._timer:Schedule(10.5, "SprearFatality01", FuncSet.StopCameraTimeline, self._wightDragonNpcId)
        FuncSet.ApplyMagic(self._wightDragonNpcId, self._wightDragonNpcId, self._spearFatalitySoundFx, 1)
    end
end

function XLevel0015:EnableAirWallToNpc(enable, npc)
    FuncSet.SetSceneColliderIgnoreCollision(npc, "AirWalls", -1, enable)
    FuncSet.SetSceneColliderIgnoreCollision(npc, "OuterAirWall", -1, enable)
    FuncSet.SetSceneColliderIgnoreCollision(npc, "MonsterAirWall", -1, enable)
end

function XLevel0015:SetFightUiActive(active)
    for _, npc in pairs(self._playerNpcList) do
        if active then
            FuncSet.ApplyMagic(npc, npc, 5000008)
        else
            FuncSet.ApplyMagic(npc, npc, 5000007)
        end
    end
end

function XLevel0015:Terminate()

end

return XLevel0015