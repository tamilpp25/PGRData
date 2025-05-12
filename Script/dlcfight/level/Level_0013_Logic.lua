--- Hun01第一场boss战正式关卡 黑龙崩岳
local XLevelBossFightHunt01 = XDlcScriptManager.RegLevelLogicScript(0013, "XLevelBossFightHunt01")
local Config = require("Level/LevelConfig/Hunt01BossFightConfig") -- 读取场景物体的配置数据,作为实例存在本地
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")

local Profiler = require("XLua/perf/profiler")

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelBossFightHunt01:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()

    --检测有没有成功获取proxy的C#函数（服务端战斗环境下）
    --local functionNames = {}
    --local i = 1
    --local meta = getmetatable(self._proxy)
    --for key, value in pairs(meta) do
    --    if type(value) == "function" then
    --        functionNames[#functionNames + 1] = key
    --    end
    --    i = i + 1
    --end
    --local allFuncNames = table.concat(functionNames, "\n");
    --XLog.Debug("self._proxy meta all function names:", allFuncNames)

    self._worldId = self._proxy:GetWorldId()
    if Config.Boss[self._worldId] == nil then
        self._worldId = 2
    end

    --{{{npc
    self._playerFocusAnchorDic = {}
    self._blackDragonRespawnId = Config.Boss[self._worldId].BlackDragon
    self._spearFatalitySoundFx = 8002105
    self._bossBornPos = { x = 64, y = 1.95, z = 72.1 }
    self._bossBornRot = { x = 0, y = 180, z = 0 }
    self._blackDragonNpcId = nil ---boss的id
    self._playerNpcContainer = XPlayerNpcContainer.New(self._proxy)
    self._localPlayerNpcUUID = 0
    --}}}

    --{{{objects
    self._deathZonePlaceId = 409999
    self._outwardsDeathZonePlaceId = 409998 ---暂时用来应对玩家挤出空气墙的处理
    --}}}

    self._bgmTrack = 1
    self._bgmCurrentTrack = 1

    self._debug = false
end

---脚本初始化，自动执行
function XLevelBossFightHunt01:Init()
    self:InitPhase()
    --Profiler.start()
    --self:InitBlackDragon()
    self:InitPlayer()
    self:InitListen()
    --XLog.Debug("[Level0013] Init performance:" .. Profiler.report())
    --Profiler.stop()
end

---@param dt number @ delta time
function XLevelBossFightHunt01:Update(dt)
    self._timer:Update(dt)
    self:OnUpdatePhase(dt)
    self:ProcessDebugInput()
    self:BgmTrackControl(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevelBossFightHunt01:HandleEvent(eventType, eventArgs)
    self:HandlePhaseEvent(eventType, eventArgs)
    self._playerNpcContainer:HandleEvent(eventType, eventArgs)

    if eventType == EWorldEvent.ActorTrigger then
        --XLog.Debug("XLevelBossFight1 SceneObjectTriggerEvent:"
        --        .. " TouchType " .. tostring(eventArgs.TouchType)
        --        .. " EnteredActorUUID " .. tostring(eventArgs.EnteredActorUUID)
        --        .. " HostSceneObjectPlaceId " .. tostring(eventArgs.HostSceneObjectPlaceId)
        --        .. " TriggerId " .. tostring(eventArgs.TriggerId)
        --        .. " TriggerState " .. tostring(eventArgs.TriggerState)
        --        .. " Log自关卡"
        --)
        if eventArgs.HostSceneObjectPlaceId == self._deathZonePlaceId and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then --死亡区域
            self._proxy:ResetNpcToSafePoint(eventArgs.EnteredActorUUID)
        end
        if eventArgs.HostSceneObjectPlaceId == self._outwardsDeathZonePlaceId
            and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID)
            and eventArgs.TriggerState == ETriggerState.Exit then --外部死亡区域，一个临时解决方案

            self._proxy:ResetNpcToCheckPoint(eventArgs.EnteredActorUUID)
            XLog.Warning("注意！npc ".. tostring(eventArgs.EnteredActorUUID).."穿到战斗场景外了")
        end
    end

    if eventType == EWorldEvent.Behavior2ScriptMsg then
        if eventArgs.MsgType == 1001 and self._proxy:CheckNpc(self._blackDragonNpcId) then
            --临时天基
            self:SpearFatality()
        elseif eventArgs.MsgType == 100 then
            --设置空气墙碰撞
        end

    elseif eventType == EWorldEvent.NpcDie then
        if eventArgs.NpcId == self._blackDragonNpcId then
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>检测到boss死亡")
            self._proxy:SettleFight(true)
            self._proxy:FinishFight()
            self._hasFinishedFight = true
        end
    end

    --if eventType == EWorldEvent.NpcAddBuff then
    --    XLog.Debug(string.format("Npc:%d Add buff:%d|%d", eventArgs.NpcUUID, eventArgs.BuffId, eventArgs.BuffTableId))
    --    local kindsStr = ""
    --    for i = 1, #eventArgs.BuffKinds do
    --        kindsStr = kindsStr .. tostring(eventArgs.BuffKinds[i])
    --    end
    --    XLog.Debug("\tBuffKinds: " .. kindsStr)
    --elseif eventType == EWorldEvent.NpcRemoveBuff then
    --    XLog.Debug(string.format("Npc:%d Remove buff:%d|%d", eventArgs.NpcUUID, eventArgs.BuffId, eventArgs.BuffTableId))
    --    local kindsStr = ""
    --    for i = 1, #eventArgs.BuffKinds do
    --        kindsStr = kindsStr .. tostring(eventArgs.BuffKinds[i])
    --    end
    --    XLog.Debug("\tBuffKinds: " .. kindsStr)
    --end

end

--{{{Init
function XLevelBossFightHunt01:InitPhase()
    --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    self._lastPhase = 0
    self._phaseTimeCount = 0

    self._hasFinishedFight = false

    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化关卡阶段参数完成")
end

function XLevelBossFightHunt01:InitBlackDragon()
    --生成怪物
    self._blackDragonNpcId = self._proxy:GenerateNpc(self._blackDragonRespawnId, ENpcCampType.Camp2, self._bossBornPos, self._bossBornRot)
    self._proxy:SetNpcPosition(self._blackDragonNpcId,{0,-100,0})
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>召唤npc黑龙完成")
end

function XLevelBossFightHunt01:InitPlayer()
    self._playerNpcContainer:Init(
            function(npc)
                self:OnPlayerNpcCreate(npc)
            end,
            function(npc)
                XLog.Debug("关卡0013 self" .. tostring(self))
                self:OnPlayerNpcDestroy(npc)
            end
    )
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化关卡用玩家参数完成 "
        .. tostring(self._playerNpcList) .. " " .. tostring(self._playerCount))
    self._localPlayerNpcUUID = self._proxy:GetLocalPlayerNpcId()
end

function XLevelBossFightHunt01:InitListen()
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.FightHuntQteStatusMsg)
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkill)
    self._proxy:RegisterEvent(EWorldEvent.NpcExitSkill)
    self._proxy:RegisterEvent(EWorldEvent.Behavior2ScriptMsg) --行为树传递到脚本的消息
    --self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    --self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化其他监听内容完成")
end
--}}}

function XLevelBossFightHunt01:OnPlayerNpcCreate(npc)
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    self._proxy:SetSceneColliderIgnoreCollision(npc, "MonsterAirWall", -1, true) --用于限制boss在场边活动的空气墙
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注册角色技能监听：" .. npc)
    XLog.Debug(self._playerFocusAnchorDic)
end

function XLevelBossFightHunt01:OnPlayerNpcDestroy(npc)
    XLog.Debug("关卡0013 self._playerFocusAnchorDic：" .. tostring(self._playerFocusAnchorDic))
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注销角色技能监听：" .. npc)
end

function XLevelBossFightHunt01:ProcessDebugInput()
    if self._debug then
        if self._proxy:IsKeyDown(ENpcOperationKey.Ball8) then --输入系统重构接入InputMap后没有添加9~12号球操作的输入映射，先改为8号用着
            self:SpearFatality()
        elseif self._proxy:IsKeyDown(ENpcOperationKey.Ball10) then
            if self._proxy:CheckNpc(self._blackDragonNpcId) then
                self._proxy:NpcDie(self._blackDragonNpcId)
            end

        end
    end
end

---跳转关卡阶段
function XLevelBossFightHunt01:SetPhase(phase)
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
function XLevelBossFightHunt01:OnUpdatePhase(dt)
    self._phaseTimeCount = self._phaseTimeCount + dt

    if self._hasFinishedFight then
        return
    end
end

---进入一个关卡阶段时需要做的事情在这里实现。一般用作设置阶段所需的环境
function XLevelBossFightHunt01:OnEnterPhase(phase)
    if phase == 1 then
    end
end

---退出一个关卡阶段时需要做的事情在这里实现。一般用作收拾本阶段的环境
function XLevelBossFightHunt01:OnExitPhase(phase)
    if phase == 0 then
    elseif phase == 1 then
    end
end

---关卡阶段改变时需要执行的逻辑，一般用于通知外部
function XLevelBossFightHunt01:OnPhaseChanged(lastPhase, nextPhase)

end

---处理阶段相关的事件响应、状态检测、信息获取
function XLevelBossFightHunt01:HandlePhaseEvent(eventType, eventArgs)
    if self._currentPhase == 0 then
        if eventType == EWorldEvent.Behavior2ScriptMsg then --todo:需二次判断确认BehaviorMsg来源Npc正确
        end
    end
end

function XLevelBossFightHunt01:SpearFatalityDamage()
    if self._proxy:CheckNpc(self._blackDragonNpcId) then
        self._proxy:ApplyMagic(self._blackDragonNpcId, self._blackDragonNpcId, 5990132, 1) --10%血量上限的真实伤害
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>天基流程，造成10%伤害")
    end
end

---天基演出流程
function XLevelBossFightHunt01:SpearFatality()
    for _, npc in pairs(self._playerNpcList) do
        self._proxy:ApplyMagic(npc, npc, 5000003, 1)
        self._timer:Schedule(0.5, self, self.RemoveBlackScreen, npc)
    end
    self:SetFightUiActive(false)
    self._timer:Schedule(11, self, self.SetFightUiActive, true)

    self._timer:Schedule(0.5, self, self.PlaySpearFatality)
end

function XLevelBossFightHunt01:RemoveBlackScreen(npc)
    self._proxy:ApplyMagic(npc, npc, 5000006, 1)
end

function XLevelBossFightHunt01:PlaySpearFatality()
    if self._proxy:CheckNpc(self._blackDragonNpcId) then
        self._proxy:PlayCameraTimeline("SprearFatality01", self._blackDragonNpcId, 0, 0, 0)
        self._timer:Schedule(10.5, "SprearFatality01",
        function(name, npc) self._proxy:StopCameraTimeline(name, npc)  end, self._blackDragonNpcId)
        self._proxy:ApplyMagic(self._blackDragonNpcId, self._blackDragonNpcId, self._spearFatalitySoundFx, 1)
    end
end

--- 使bgm track 插值到目标值
function XLevelBossFightHunt01:BgmTrackControl(dt)
    if not (self._bgmCurrentTrack == self._bgmTrack) then
        if self._bgmTrack > self._bgmCurrentTrack then
            if self._bgmCurrentTrack + dt * 0.2 <= self._bgmTrack then
                self._bgmCurrentTrack = self._bgmCurrentTrack + dt * 0.2
            else
                self._bgmCurrentTrack = self._bgmTrack
            end
        else
            if self._bgmCurrentTrack - dt * 0.2 >= self._bgmTrack then
                self._bgmCurrentTrack = self._bgmCurrentTrack - dt * 0.2
            else
                self._bgmCurrentTrack = self._bgmTrack
            end
        end
        self._proxy:SetBgmAisacControl("AisacControl03", self._bgmCurrentTrack)
    end
end

function XLevelBossFightHunt01:SetFightUiActive(active)
    for _, npc in pairs(self._playerNpcList) do
        if active then
            self._proxy:ApplyMagic(npc, npc, 5000008)
        else
            self._proxy:ApplyMagic(npc, npc, 5000007)
        end
    end
end

---Npc是否处在濒死状态
function XLevelBossFightHunt01:IsNpcDying(npcId)
    return self._proxy:CheckNpcAction(npcId, ENpcAction.Dying)
end

---Npc是否死亡
function XLevelBossFightHunt01:IsNpcDead(npcId)
    return self._proxy:CheckNpcAction(npcId, ENpcAction.Dying) or self._proxy:CheckNpcAction(npcId, ENpcAction.Death)
end

function XLevelBossFightHunt01:Terminate()
    self._proxy:UnregisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:UnregisterEvent(EWorldEvent.FightHuntQteStatusMsg)
    self._proxy:UnregisterEvent(EWorldEvent.NpcCastSkill)
    self._proxy:UnregisterEvent(EWorldEvent.NpcExitSkill)
    self._proxy:UnregisterEvent(EWorldEvent.Behavior2ScriptMsg) --行为树传递到脚本的消息
    self._proxy = nil

end

return XLevelBossFightHunt01