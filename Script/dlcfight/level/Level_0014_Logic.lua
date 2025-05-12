--- Hun01连战
local XLevelBossFight0014 = XDlcScriptManager.RegLevelLogicScript(0014, "XLevelBossFight0014")
local Config = require("Level/LevelConfig/Hunt01BossFightConfig") -- 读取场景物体的配置数据,作为实例存在本地
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelBossFight0014:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()
    --const
    self._currentPhaseMemKey = 1101

    self._worldId = self._proxy:GetWorldId()
    if Config.Boss[self._worldId] == nil then
        self._worldId = 2
    end

    --{{{npc
    self._playerFocusAnchorDic = {}
    self._blackDragonRespawnId = Config.Boss[self._worldId].BlackDragon
    self._wightDragonRespawnId = Config.Boss[self._worldId].WightDragon
    self._wightDragonHackSoundFx = 8002103
    self._wightDragonBornSoundFx = 8002104
    self._spearFatalitySoundFx = 8002105
    self._bossHidePos = { x = 60, y = -200, z = 60 }
    self._bossBornPos = { x = 64, y = 1.95, z = 72.1 }
    self._bossBornRot = { x = 0, y = 180, z = 0 }
    self._blackDragonNpcId = nil ---boss的id
    self._wightDragonNpcId = nil ---boss的id
    self._playerNpcContainer = XPlayerNpcContainer.New(self._proxy)
    self._playerRescueDict = {}
    --}}}

    --{{{objects
    self._deathZonePlaceId = 9999
    self._outwardsDeathZonePlaceId = 9998 ---暂时用来应对玩家挤出空气墙的处理
    self._bossLockTrigger = 17 ---boss等待区域，用于开关玩家自动锁定boss的判断
    self._bossReadyTrigger = 18 ---boss停留在场地中央等待跳跳乐开始的区域
    --}}}

    --{{{跳跳乐参数
    self._playerCompleteJumpFun = {} ---每名玩家是否通过跳跳乐
    self._bossEndureMagicId = 8001035
    self._removeBossEndureMagicId = 8001036
    self._jumpFunStartSignMagicId = 5990130
    self._jumpFunEndSignMagicId = 5990131
    self._jumpFunDefeatTimeLimit = 60 ---跳跳乐时限
    --}}}
    self._bgmTrack = 1
    self._bgmCurrentTrack = 1

    self._debug = false
end

---脚本初始化，自动执行
function XLevelBossFight0014:Init()
    self:InitPhase()
    self:InitBlackDragon()
    self:InitPlayer()
    self:InitListen()
end

---@param dt number @ delta time
function XLevelBossFight0014:Update(dt)
    self._timer:Update(dt)
    self:OnUpdatePhase(dt)
    self:ProcessDebugInput()
    self:BgmTrackControl(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevelBossFight0014:HandleEvent(eventType, eventArgs)
    XLevelBossFight0014.Super.HandleEvent(self, eventType, eventArgs)
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
        if eventArgs.HostSceneObjectPlaceId == self._deathZonePlaceId and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then --死亡区域
            self._proxy:ResetNpcToSafePoint(eventArgs.EnteredActorUUID)
        end
        if eventArgs.HostSceneObjectPlaceId == self._outwardsDeathZonePlaceId
            and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID)
            and eventArgs.TriggerState == ETriggerState.Exit then --外部死亡区域，一个临时解决方案

            self._proxy:ResetNpcToCheckPoint(eventArgs.EnteredActorUUID)
            XLog.Warning("注意！npc " .. tostring(eventArgs.EnteredActorUUID) .. "穿到战斗场景外了")
        end
    end

    if eventType == EWorldEvent.Behavior2ScriptMsg
        and (eventArgs.NpcUUID == self._blackDragonNpcId
            or eventArgs.NpcUUID == self._wightDragonNpcId) then
        if eventArgs.MsgType == 1001
            and (self._proxy:CheckNpc(self._blackDragonNpcId)
                or self._proxy:CheckNpc(self._wightDragonNpcId))then
            --临时天基
            self:SpearFatality()
        elseif eventArgs.MsgType == 100 then
            --设置空气墙碰撞
            --self:EnableAirWallToNpc(eventArgs.Int[1], eventArgs.Int[2] == 0)
        elseif eventArgs.MsgType == 800101 then
            --躲黑龙大招的跳跳乐
        end
    end

end

--{{{Init
function XLevelBossFight0014:InitPhase()
    --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    self._lastPhase = 0
    self._phaseStartedDelayTranslate = false ---阶段延迟跳转需要设置为true
    self._phaseTimeCount = 0

    --phase0 关卡开始

    --phase5 正常进行游戏
    --phase10 连战转换
    self._centerTowerRaise = nil
    self._centerTowerMoving = nil
    self._confirmCenterTowerDown = false
    self._centerTowerWaitToDo = false
    self._towersSequences = {}
    self._specialTowerSequences = {}
    self._confirmTowersDown = false

    --phase11 开始白龙入场演出

    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化关卡阶段参数完成")
end

function XLevelBossFight0014:InitBlackDragon()

    --生成怪物
    self._blackDragonNpcId = self._proxy:GenerateNpc(self._blackDragonRespawnId, ENpcCampType.Camp2, self._bossBornPos, self._bossBornRot)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>召唤npc黑龙完成")
end

function XLevelBossFight0014:InitWightDragon()
    --生成怪物
    self._wightDragonNpcId = self._proxy:GenerateNpc(self._wightDragonRespawnId, ENpcCampType.Camp2, self._bossHidePos, self._bossBornRot)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>召唤npc白龙完成")
end

function XLevelBossFight0014:InitPlayer()
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

function XLevelBossFight0014:InitListen()
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.FightHuntQteStatusMsg)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractComplete)
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkill)
    self._proxy:RegisterEvent(EWorldEvent.NpcExitSkill)
    self._proxy:RegisterEvent(EWorldEvent.Behavior2ScriptMsg) --行为树传递到脚本的消息
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化其他监听内容完成")
end
--}}}

function XLevelBossFight0014:OnPlayerNpcCreate(npc)
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    self._proxy:SetSceneColliderIgnoreCollision(npc, "MonsterAirWall", -1, true) --用于限制boss在场边活动的空气墙
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注册角色技能监听：" .. npc)
    XLog.Debug(self._playerFocusAnchorDic)
end

function XLevelBossFight0014:OnPlayerNpcDestroy(npc)
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注销角色技能监听：" .. npc)
end

function XLevelBossFight0014:ProcessDebugInput()
    if self._debug then
        if self._proxy:IsKeyDown(ENpcOperationKey.Ball11) then
            self._proxy:ApplyMagic(self._playerNpcContainer._localPlayerNpcId, self._playerNpcContainer._localPlayerNpcId, self._wightDragonHackSoundFx, 1)
        elseif self._proxy:IsKeyDown(ENpcOperationKey.Ball12) then
            self._proxy:ApplyMagic(self._playerNpcContainer._localPlayerNpcId, self._playerNpcContainer._localPlayerNpcId, self._wightDragonBornSoundFx, 1)
        elseif self._proxy:IsKeyDown(ENpcOperationKey.Ball10) then
            if self._proxy:CheckNpc(self._blackDragonNpcId) then
                self._proxy:NpcDie(self._blackDragonNpcId)
            end
        elseif self._proxy:IsKeyDown(ENpcOperationKey.Ball9) then
            self:SpearFatality()
        end
    end
end



---跳转关卡阶段
function XLevelBossFight0014:SetPhase(phase)
    if phase == self._currentPhase then
        return
    end

    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, self.phase)

    self._lastPhase = self._currentPhase
    self._currentPhase = phase
    self._phaseTimeCount = 0

    self._proxy:SetLevelMemoryInt(self._currentPhaseMemKey, self._currentPhase)
end

---当前关卡阶段需要一直执行的逻辑在这里实现。一般用作执行判断、执行持续性的功能、跳转阶段
function XLevelBossFight0014:OnUpdatePhase(dt)
    if self._phaseTimeCount == nil then
        self._phaseTimeCount = 0
    end
    self._phaseTimeCount = self._phaseTimeCount + dt
    if self._currentPhase == 0 then

    elseif self._currentPhase == 1 then

    elseif self._currentPhase == 3 then

    elseif self._currentPhase == 4 then

    elseif self._currentPhase == 10 then
            self:SetPhase(11)
    elseif self._currentPhase == 11 then
        if self._phaseTimeCount > 8 then
            self:SetPhase(12)
        end
    elseif self._currentPhase == 12 then
        if not self._proxy:CheckNpc(self._wightDragonNpcId) and self._phaseTimeCount > 10 then
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>检测到boss死亡")
            self._proxy:SettleFight(true)
            self._proxy:FinishFight()
        end
    end

    if self._currentPhase == 0 and self._phaseTimeCount > 10 then
        if not self._proxy:CheckNpc(self._blackDragonNpcId) then
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>检测到boss死亡")
            if self._worldId >= 13 then
                self:SetPhase(12)
            else
                self:SetPhase(10)
            end
        end
    elseif not (self._currentPhase == 0) and self._currentPhase < 10 then
        if not self._proxy:CheckNpc(self._blackDragonNpcId) then
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>检测到boss死亡")
            if self._worldId >= 13 then
                self:SetPhase(12)
            else
                self:SetPhase(10)
            end
        end
    end
end

---进入一个关卡阶段时需要做的事情在这里实现。一般用作设置阶段所需的环境
function XLevelBossFight0014:OnEnterPhase(phase)
    if phase == 1 then
        --通知boss就位
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>进入阶段1，通知boss就位")
    elseif phase == 2 then
        --开始跳跳乐
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>跳跳乐开始")

    elseif phase == 3 then
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>飞龙在天！")
    elseif phase == 4 then
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>亢龙有悔！")
    elseif phase == 10 then
        -- 如果玩家在phase2、3等进入，锁定还没有恢复，需要处理
        -- 塔可能没降，或者序列会继续执行，需要处理
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>准备造假！")
    elseif phase == 11 then
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>异度入侵！")
        for _, npc in pairs(self._playerNpcList) do
            self._proxy:ApplyMagic(npc, npc, 5990140, 1)
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>层层加码！" .. tostring(npc))
        end
        --self._timer:Schedule(4, self, self.PlayHackSoundFx, self._playerNpcContainer._localPlayerNpcId)
        self:PlayHackSoundFx(self._playerNpcContainer._localPlayerNpcId)
        --self._timer:Schedule(5,true,self._proxy:SetFakeSettleActive)
    elseif phase == 12 then
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>天外来客！")
        self:WightDragonIntro()
    end
end

---退出一个关卡阶段时需要做的事情在这里实现。一般用作收拾本阶段的环境
function XLevelBossFight0014:OnExitPhase(phase)
    if phase == 0 then
    elseif phase == 1 then
    elseif phase == 2 then

    elseif phase == 3 then

    elseif phase == 4 then

    end
end

---关卡阶段改变时需要执行的逻辑，一般用于通知外部
function XLevelBossFight0014:OnPhaseChanged(lastPhase, nextPhase)
end

---处理阶段相关的事件响应、状态检测、信息获取
function XLevelBossFight0014:HandlePhaseEvent(eventType, eventArgs)
    if self._currentPhase == 0 then

    elseif self._currentPhase == 1 then

    elseif self._currentPhase == 2 then

    end
end

function XLevelBossFight0014:SpearFatalityDamage()
    if self._proxy:CheckNpc(self._blackDragonNpcId) then
        self._proxy:ApplyMagic(self._blackDragonNpcId, self._blackDragonNpcId, 5990132, 1) --10%血量上限的真实伤害
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>天基流程，造成10%伤害")
    end
end

---天基演出流程
function XLevelBossFight0014:SpearFatality()
    for _, npc in pairs(self._playerNpcList) do
        self._proxy:ApplyMagic(npc, npc, 5000003, 1)
        self._timer:Schedule(0.5, self, self.RemoveBlackScreen, npc)
    end
    self:SetFightUiActive(false)
    self._timer:Schedule(11, self, self.SetFightUiActive, true)
    self._timer:Schedule(0.5, self, self.PlaySpearFatality)

    self:EnablePlatforms(true)
    self._timer:Schedule(13, self, self.EnablePlatforms, false)
end

function XLevelBossFight0014:RemoveBlackScreen(npc)
    self._proxy:ApplyMagic(npc, npc, 5000006, 1)
end

function XLevelBossFight0014:PlaySpearFatality()
    if self._proxy:CheckNpc(self._blackDragonNpcId) then
        self._proxy:PlayCameraTimeline("SprearFatality01", self._blackDragonNpcId, 0, 0, 0)
        self._timer:Schedule(10.5, nil, function()
            self._proxy:StopCameraTimeline("SprearFatality01", self._blackDragonNpcId)
        end)
        self._proxy:ApplyMagic(self._blackDragonNpcId, self._blackDragonNpcId, self._spearFatalitySoundFx, 1)
    elseif self._proxy:CheckNpc(self._wightDragonNpcId) then
        self._proxy:PlayCameraTimeline("SprearFatality01", self._wightDragonNpcId, 0, 0, 0)
        self._timer:Schedule(10.5, nil, function()
            self._proxy:StopCameraTimeline("SprearFatality01", self._wightDragonNpcId)
        end)
        self._proxy:ApplyMagic(self._wightDragonNpcId, self._wightDragonNpcId, self._spearFatalitySoundFx, 1)
    end
end
--- 使bgm track 插值到目标值
function XLevelBossFight0014:BgmTrackControl(dt)
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

function XLevelBossFight0014:PlayHackSoundFx(npc)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>播放Hack音效")
    self._proxy:ApplyMagic(npc, npc, self._wightDragonHackSoundFx, 1)
end

function XLevelBossFight0014:WightDragonIntro()
    -- 白龙入场镜头+特效timeline
    self._proxy:SwitchSceneTimeline(1, true)
    self._timer:Schedule(11.1, 1, function(id, state)
        self._proxy:SwitchSceneTimeline(id, state)
    end, false)
    -- 召唤白龙，并在特效落地的时候放到位置上
    self:InitWightDragon()
    self._timer:Schedule(8.17, self._wightDragonNpcId,
    function(npcId, pos)
        self._proxy:SetNpcPosition(npcId, pos)
    end, self._bossBornPos)
    self._proxy:ApplyMagic(self._wightDragonNpcId, self._wightDragonNpcId, 8002015, 1) -- 卡住白龙ai
    self._timer:Schedule(11.1, self, self.ReleaseWightDragon)
    -- 塔击毁的timeline
    self._proxy:PlaySceneAnimation(4)
    -- 气氛变化timeline
    self._timer:Schedule(0.5, 2,
        function(id, state)
            self._proxy:SwitchSceneTimeline(id, state)
    end, true)
    -- UI开关
    self:SetFightUiActive(false)
    self._timer:Schedule(11.1, self, self.SetFightUiActive, true)
    -- 音效
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>播放白龙入场音效")
    self._proxy:ApplyMagic(
            self._playerNpcContainer._localPlayerNpcId,
            self._playerNpcContainer._localPlayerNpcId,
            self._wightDragonBornSoundFx,
            1
    )
end

function XLevelBossFight0014:ReleaseWightDragon()
    -- 释放白龙ai
    self._proxy:ApplyMagic(
            self._wightDragonNpcId,
            self._wightDragonNpcId,
            8002016,
            1)
end

function XLevelBossFight0014:SetFightUiActive(active)
    for _, npc in pairs(self._playerNpcList) do
        if active then
            self._proxy:ApplyMagic(npc, npc, 5000008)
        else
            self._proxy:ApplyMagic(npc, npc, 5000007)
        end
    end
end

---Npc是否处在濒死状态
function XLevelBossFight0014:IsNpcDying(npcId)
    return self._proxy:CheckNpcAction(npcId, ENpcAction.Dying)
end

---Npc是否死亡
function XLevelBossFight0014:IsNpcDead(npcId)
    return self._proxy:CheckNpcAction(npcId, ENpcAction.Dying) or self._proxy:CheckNpcAction(npcId, ENpcAction.Death)
end

function XLevelBossFight0014:Terminate()

end

return XLevelBossFight0014