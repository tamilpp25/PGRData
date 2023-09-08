--- Hun01连战
local XLevelBossFight0014 = XDlcScriptManager.RegLevelLogicScript(0014, "XLevelBossFight0014")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs
local Config = require("Level/LevelConfig/Hunt01BossFightConfig") -- 读取场景物体的配置数据,作为实例存在本地
local Tool = require("Level/Common/XLevelTools")
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelBossFight0014:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()
    --const
    self._currentPhaseMemKey = 1101

    self._worldId = FuncSet.GetWorldId()
    if Config.Boss[self._worldId] == nil then
        self._worldId = 2
    end

    --{{{npc
    self._playerFocusAnchorDic = {}
    self._blackDragonRespawnId = Config.Boss[self._worldId].BlackDragon
    self._blackDragonBossRefId = 1 --黑龙boss生成记录的引用id
    self._wightDragonRespawnId = Config.Boss[self._worldId].WightDragon
    self._wightDragonBossRefId = 2 --白龙boss生成记录的引用id
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
    self._towers = {}
    --[[    self._switches = {
            {
                placeId = 3000,
                agent = nil,
                object = self,
                func = self.TestSwitchStartJumpFun,
                param = nil,
                times = -1,
                defaultEnable = true
            },
        }]]
    self._deathZonePlaceId = 9999
    self._outwardsDeathZonePlaceId = 9998 ---暂时用来应对玩家挤出空气墙的处理
    self._bossLockTrigger = 17 ---boss等待区域，用于开关玩家自动锁定boss的判断
    self._bossReadyTrigger = 18 ---boss停留在场地中央等待跳跳乐开始的区域
    self._centerTowerEffectPlayer = 1001
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
    self:InitTower()
    --self:InitSwitch()
    self:InitListen()
end

---@param dt number @ delta time
function XLevelBossFight0014:Update(dt)
    self._timer:Update(dt)
    self:OnUpdatePhase(dt)
    self:PlayerInteract()
    self:OnInteractButton()
    self:BgmTrackControl(dt)
end

function XLevelBossFight0014:OnInteractButton()
    if self._debug then
        if FuncSet.IsKeyDown(ENpcOperationKey.Ball11) then
            FuncSet.ApplyMagic(self._playerNpcContainer._localPlayerNpcId, self._playerNpcContainer._localPlayerNpcId, self._wightDragonHackSoundFx, 1)
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball12) then
            FuncSet.ApplyMagic(self._playerNpcContainer._localPlayerNpcId, self._playerNpcContainer._localPlayerNpcId, self._wightDragonBornSoundFx, 1)
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball10) then
            if FuncSet.CheckNpc(self._blackDragonNpcId) then
                FuncSet.NpcDie(self._blackDragonNpcId)
            end
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball9) then
            self:SpearFatality()
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XLevelBossFight0014:HandleEvent(eventType, eventArgs)
    XLevelBossFight0014.Super.HandleEvent(self, eventType, eventArgs)
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
        if eventArgs.SceneObjectId == self._deathZonePlaceId and FuncSet.IsPlayerNpc(eventArgs.SourceActorId) then --死亡区域
            FuncSet.ResetNpcToSafePoint(eventArgs.SourceActorId)
        end
        if eventArgs.SceneObjectId == self._outwardsDeathZonePlaceId
            and FuncSet.IsPlayerNpc(eventArgs.SourceActorId)
            and eventArgs.TriggerState == ESceneObjectTriggerState.Exit then --外部死亡区域，一个临时解决方案

            FuncSet.ResetNpcToCheckPoint(eventArgs.SourceActorId)
            XLog.Warning("注意！npc " .. tostring(eventArgs.SourceActorId) .. "穿到战斗场景外了")
        end
    elseif eventType == EScriptEvent.NpcInteractComplete then
        --交互完成
        self:OnNpcInteractComplete(eventArgs)
    end

    if eventType == EScriptEvent.Behavior2ScriptMsg then
        if eventArgs.MsgType == 1001 and (FuncSet.CheckNpc(self._blackDragonNpcId) or FuncSet.CheckNpc(self._wightDragonNpcId))then
            --临时天基
            self:SpearFatality()
        elseif eventArgs.MsgType == 100 then
            --设置空气墙碰撞
            self:EnableAirWallToNpc(eventArgs.Int[1], eventArgs.Int[2] == 0)
        elseif eventArgs.MsgType == 800101 then
            --躲黑龙大招的跳跳乐
            for _, sequence in pairs(Config.Sequence) do
                self:SpecialTowerControl(sequence.tower, sequence.raise, sequence.delayTime)
            end
        end
    end

end

---主控端转移时的关卡状态恢复
function XLevelBossFight0014:GainControl()
    self:Init()

    local currentPhase = FuncSet.GetLevelMemoryInt(self._currentPhaseMemKey)
    if currentPhase > 0 then
        self:SetPhase(currentPhase)
    end
end

--{{{Init
function XLevelBossFight0014:InitPhase()
    --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    self._lastPhase = 0
    self._phaseStartedDelayTranslate = false ---阶段延迟跳转需要设置为true
    self._phaseTimeCount = 0

    --phase0 关卡开始，啥都没操作,检测是否进入跳跳乐

    --phase1 令黑龙准备跳跳乐，检测是否就位
    self._bossCanCastSkillTime = 0
    self._bossHasCastSkill = false
    self._bossIsReady = false

    --phase2 跳跳乐
    self._jumpFunCompletePlayerCount = 0 ---通过了跳跳乐的玩家数量

    --phase3 跳跳乐结束，龙飞天开大
    self._phase3TimeLimit = 28
    --phase4 跳跳乐结束，龙被玩家暴打
    self._phase4TimeLimit = 15
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
    local id = FuncSet.GetGeneratedNpc(self._blackDragonBossRefId)
    --生成怪物
    if id <= 0 then
        --防止断线重连时重复创建怪物
        self._blackDragonNpcId = FuncSet.GenerateNpc(self._blackDragonBossRefId, self._blackDragonRespawnId, ENpcCampType.Camp2, self._bossBornPos, self._bossBornRot)
    else
        self._blackDragonNpcId = id
    end
    self._proxy:RegisterBehavior2ScriptMsgEvent(self._blackDragonNpcId)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>召唤npc黑龙完成")
end

function XLevelBossFight0014:InitWightDragon()
    --生成怪物
    local id = FuncSet.GetGeneratedNpc(self._wightDragonBossRefId)
    if id <= 0 then
        --防止断线重连时重复创建怪物
        self._wightDragonNpcId = FuncSet.GenerateNpc(self._wightDragonBossRefId, self._wightDragonRespawnId, ENpcCampType.Camp2, self._bossHidePos, self._bossBornRot)
    else
        self._wightDragonNpcId = id
    end
    self._proxy:RegisterBehavior2ScriptMsgEvent(self._wightDragonNpcId)
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

function XLevelBossFight0014:InitTower()
    self._towers = Tool.InitTower(Config.Towers)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化场景中塔完成")
end

function XLevelBossFight0014:InitSwitch()
    self._switches = Tool.InitSwitch(self._switches)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化场景中开关完成")
end

function XLevelBossFight0014:InitListen()
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectTrigger)
    self._proxy:RegisterEvent(EWorldEvent.FightHuntQteStatusMsg)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractComplete)
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkill)
    self._proxy:RegisterEvent(EWorldEvent.NpcExitSkill)
    self._proxy:RegisterEvent(EWorldEvent.Behavior2ScriptMsg) --行为树传递到脚本的消息
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化其他监听内容完成")
end
--}}}

function XLevelBossFight0014:OnPlayerNpcCreate(npc)
    self._playerFocusAnchorDic[npc] = nil ---注册每名玩家当前选中的勾点
    self._playerCompleteJumpFun[npc] = false

    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    FuncSet.SetSceneColliderIgnoreCollision(npc, "MonsterAirWall", -1, true) --用于限制boss在场边活动的空气墙
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注册角色技能监听：" .. npc)
    XLog.Debug(self._playerFocusAnchorDic)
end

function XLevelBossFight0014:OnPlayerNpcDestroy(npc)
    self._playerFocusAnchorDic[npc] = nil
    self._playerCompleteJumpFun[npc] = nil
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注销角色技能监听：" .. npc)
end

---玩家之间的交互
function XLevelBossFight0014:PlayerInteract()
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
function XLevelBossFight0014:CheckPlayerRescueInteract(launcher, target, dist)
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
function XLevelBossFight0014:OnNpcInteractComplete(eventArgs)
    local npc = eventArgs.NpcId
    local target = self._playerRescueDict[npc]
    if target then
        FuncSet.RebornNpc(npc, target) --复活救援对象
        self._playerRescueDict[npc] = nil --清除救援对象记录
    end
    FuncSet.CloseInteraction(npc, false) --关闭救援者的交互按钮
end

---Npc是否处在濒死状态
function XLevelBossFight0014:IsNpcDying(npcId)
    return FuncSet.CheckNpcAction(npcId, ENpcAction.Dying)
end

---Npc是否死亡
function XLevelBossFight0014:IsNpcDead(npcId)
    return FuncSet.CheckNpcAction(npcId, ENpcAction.Dying) or FuncSet.CheckNpcAction(npcId, ENpcAction.Death)
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

    FuncSet.SetLevelMemoryInt(self._currentPhaseMemKey, self._currentPhase)
end

---当前关卡阶段需要一直执行的逻辑在这里实现。一般用作执行判断、执行持续性的功能、跳转阶段
function XLevelBossFight0014:OnUpdatePhase(dt)
    if self._phaseTimeCount == nil then
        self._phaseTimeCount = 0
    end
    self._phaseTimeCount = self._phaseTimeCount + dt
    if self._currentPhase == 0 then
        --[[        -- 检测条件，如果满足则进入阶段1，通知boss就位
                if self:JumpFunStartCheck() then
                    self:SetPhase(1)
                end]]
    elseif self._currentPhase == 1 then
        if not self._bossHasCastSkill then
            --持续放技能
            self:BossCastReadySwoop()
        end
        if self._bossIsReady and self._bossHasCastSkill and FuncSet.CheckCanCastSkill(self._blackDragonNpcId) then
            self:SetPhase(2)
        end
    elseif self._currentPhase == 2 then
        --此段逻辑无效，改为检测跳跳乐结束事件来执行
        --self:JumpFunProgress(dt)
        --[[        if self:JumpFunEndCheck() then
                    if self._jumpFunCompletePlayerCount < 3 then
                        self:SetPhase(3)
                    else
                        self:SetPhase(4)
                    end
                end]]
    elseif self._currentPhase == 3 then
        if self._phaseTimeCount >= self._phase3TimeLimit then
            self:SetPhase(5)
        end
    elseif self._currentPhase == 4 then
        if self._phaseTimeCount >= self._phase4TimeLimit then
            self:SetPhase(5)
        end
    elseif self._currentPhase == 10 then
        self:FixLevelStateUpdate()
        self:CheckLevelStateFixed()
        if --[[self._waitTime <= self._phaseTimeCount
                and ]]self._confirmCenterTowerDown
                and self._confirmTowersDown then
            self:SetPhase(11)
        end
    elseif self._currentPhase == 11 then
        if self._phaseTimeCount > 8 then
            self:SetPhase(12)
        end
    elseif self._currentPhase == 12 then
        if not FuncSet.CheckNpc(self._wightDragonNpcId) and self._phaseTimeCount > 10 then
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>检测到boss死亡")
            FuncSet.FinishFight(true)
        end
    end

    if self._currentPhase == 0 and self._phaseTimeCount > 10 then
        if not FuncSet.CheckNpc(self._blackDragonNpcId) then
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>检测到boss死亡")
            if self._worldId >= 13 then
                self:SetPhase(12)
            else
                self:SetPhase(10)
            end
        end
    elseif not (self._currentPhase == 0) and self._currentPhase < 10 then
        if not FuncSet.CheckNpc(self._blackDragonNpcId) then
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
        self:LetBossReady()
    elseif phase == 2 then
        --开始跳跳乐
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>跳跳乐开始")

        self:StartJumpFun()
    elseif phase == 3 then
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>飞龙在天！")
        self:BossFly()
    elseif phase == 4 then
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>亢龙有悔！")
        self:BossNotFly()
    elseif phase == 10 then
        -- 如果玩家在phase2、3等进入，锁定还没有恢复，需要处理
        -- 塔可能没降，或者序列会继续执行，需要处理
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>准备造假！")
        self:FixLevelState()
    elseif phase == 11 then
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>异度入侵！")
        for _, npc in pairs(self._playerNpcList) do
            FuncSet.ApplyMagic(npc, npc, 5990140, 1)
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>层层加码！" .. tostring(npc))
        end
        --self._timer:Schedule(4, self, self.PlayHackSoundFx, self._playerNpcContainer._localPlayerNpcId)
        self:PlayHackSoundFx(self._playerNpcContainer._localPlayerNpcId)
        --self._timer:Schedule(5,true,FuncSet.SetFakeSettleActive)
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
        self:OnJumpFunEnd()
    elseif phase == 3 then
        self:OnBossFlyEnd()
    elseif phase == 4 then
        self:OnBossFlyEnd()
    end
end

---关卡阶段改变时需要执行的逻辑，一般用于通知外部
function XLevelBossFight0014:OnPhaseChanged(lastPhase, nextPhase)
end

---处理阶段相关的事件响应、状态检测、信息获取
function XLevelBossFight0014:HandlePhaseEvent(eventType, eventArgs)
    if self._currentPhase == 0 then
        if eventType == EWorldEvent.Behavior2ScriptMsg then
            if eventArgs.MsgType == 800100 then
                self:SetPhase(1)
            end
        end
    elseif self._currentPhase == 1 then
        if eventType == EWorldEvent.SceneObjectTrigger
            and eventArgs.SceneObjectId == self._bossReadyTrigger
            and eventArgs.TriggerState == 1
            and eventArgs.SourceActorId == self._blackDragonNpcId then --boss跳到中央塔的位置的检测

            --self:SetPhase(2)
            self._bossIsReady = true
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>boss已就位")
        end
    elseif self._currentPhase == 2 then
        if eventType == EWorldEvent.NpcCastSkill then
            if eventArgs.SkillId == 100241 or eventArgs.SkillId == 101439 or eventArgs.SkillId == 100736 then
                -- 玩家放出对勾点猎锚第一段 读取玩家猎矛勾选的对象
                self._playerFocusAnchorDic[eventArgs.LauncherId] = FuncSet.GetNpcNoteInt(eventArgs.LauncherId, 25003)
                --XLog.Debug("关卡缓存玩家" .. tostring(eventArgs.LauncherId) .. "勾取对象： " .. tostring(self._playerFocusAnchorDic[eventArgs.LauncherId]))

            elseif eventArgs.SkillId == 100242 or eventArgs.SkillId == 101440 or eventArgs.SkillId == 100737 then
                -- 玩家放出对勾点猎锚第二段 升起勾选目标下一步的塔
                if self._playerFocusAnchorDic[eventArgs.LauncherId] ~= nil and self._towers[self._playerFocusAnchorDic[eventArgs.LauncherId]].next ~= nil then
                    for _, nextTower in pairs(self._towers[self._playerFocusAnchorDic[eventArgs.LauncherId]].next) do
                        self:TowerControl(nextTower, true, 0.1)
                    end
                end
            elseif (eventArgs.SkillId == 100227 or eventArgs.SkillId == 101435 or eventArgs.SkillId == 100720) and eventArgs.TargetId == self._blackDragonNpcId then
                -- 玩家放出对boss猎锚第一段
                self:PlayerSetAnchorToBoss(eventArgs.LauncherId)
            end
        end

        if eventType == EWorldEvent.FightHuntQteStatusMsg then
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>检测到结束事件")
            if eventArgs.Status == 0 then
                XLog.Debug("<color=#F0D800>[SceneHunt01]</color>空")
            elseif eventArgs.Status == 1 then
                XLog.Debug("<color=#F0D800>[SceneHunt01]</color>进行中")
            elseif eventArgs.Status == 2 then
                XLog.Debug("<color=#F0D800>[SceneHunt01]</color>时间结束")
                self:SetPhase(3)
            elseif eventArgs.Status == 3 then
                XLog.Debug("<color=#F0D800>[SceneHunt01]</color>打够伤害")
                self:SetPhase(4)
            end
        end
    end
end

---临时用开关控制跳跳乐环节的方法
function XLevelBossFight0014:TestSwitchStartJumpFun()
    if FuncSet.CheckNpc(self._blackDragonNpcId) then
        local bossState = FuncSet.GetNpcNoteInt(self._blackDragonNpcId, 5001) --boss状态层
        local bossAngry = FuncSet.GetNpcNoteInt(self._blackDragonNpcId, 50) --boss愤怒状态
        if (bossState == 0 or bossState == 1) and bossAngry ~= 10 then
            self:SetPhase(1)
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>临时开始跳跳乐方法执行")
        end
    end
end

---检查跳跳乐是否开始，每帧执行
function XLevelBossFight0014:JumpFunStartCheck()
    ---关卡时间>=X
    ---boss血量<=Y%
    ---boss没有狂暴
    if FuncSet.CheckNpc(self._blackDragonNpcId) then
        local bossHpRate = FuncSet.GetNpcAttribRate(self._blackDragonNpcId, 0) --boss血量百分比
        local bossState = FuncSet.GetNpcNoteInt(self._blackDragonNpcId, 5001) --boss状态层
        local bossAngry = FuncSet.GetNpcNoteInt(self._blackDragonNpcId, 50) --boss愤怒状态
        if bossHpRate <= 0.4 and (bossState == 0 or bossState == 1) and bossAngry ~= 10 then
            return true
        end
    end
end

---告诉boss去就位了，就位以后才是正式的跳跳乐。并关闭玩家锁定功能
function XLevelBossFight0014:LetBossReady()
    if FuncSet.CheckNpc(self._blackDragonNpcId) then
        FuncSet.SetNpcNoteFloat3(self._blackDragonNpcId, 9001, 60, 0, 60)
        FuncSet.ApplyMagic(self._blackDragonNpcId, self._blackDragonNpcId, self._bossEndureMagicId, 1)
    end
    -- 通知玩家跳跳乐开始
    for _, npc in pairs(self._playerNpcList) do
        FuncSet.ApplyMagic(npc, npc, self._jumpFunStartSignMagicId, 1)
    end

    --boss无视跳跳乐用的弹出collider
    FuncSet.SetSceneColliderIgnoreCollision(self._blackDragonNpcId, "DynamicBlock", -1, true)

    --场地中央开始把玩家弹开
    FuncSet.PlaySceneAnimation(5)
end

---对坐标点放技能
function XLevelBossFight0014:BossCastReadySwoop()
    if FuncSet.CheckNpcAction(self._blackDragonNpcId, ENpcAction.Move) and FuncSet.CheckCanCastSkill(self._blackDragonNpcId) then
        FuncSet.CastSkillToPosition(self._blackDragonNpcId, 8001097, 60, 0, 60)
        if self._bossCanCastSkillTime == 0 then
            self._bossCanCastSkillTime = self._phaseTimeCount
            XLog.Debug("<color=#F0D800>[SceneHunt01]</color>boss释放技能指令开始发出")
        end
    end

    if self._phaseTimeCount - self._bossCanCastSkillTime > 3 then
        self._bossHasCastSkill = true
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>boss释放技能指令停止")
    end
end

---开始跳跳乐
function XLevelBossFight0014:StartJumpFun()
    --中央塔升起
    self._timer:Schedule(3, self, self.CenterTowerControl, true)--中央塔升起

    --周围的塔升起
    self:TowerControl(2, true, 6)
    self:TowerControl(3, true, 6)
    self:TowerControl(4, true, 6)

    --怪物大吼
    FuncSet.CastSkill(self._blackDragonNpcId, 8001001)
    self:BossRoarMissile()
    -- 怪物开始蓄力，可以被qte
    self:BigSkill(1)

    --bgm切轨
    self._bgmTrack = 0

    --关闭弹出玩家的碰撞体
    self._timer:Schedule(8, 6, FuncSet.PlaySceneAnimation)

    --开始QTE
    FuncSet.UpdateRoleCountQTETime(15, 10, 5)
    self._timer:Schedule(3, 30, FuncSet.AddQTETime)

    --开启平台可钩
    self:EnablePlatforms(true)
end

function XLevelBossFight0014:BossRoarMissile()
    if FuncSet.CheckNpc(self._blackDragonNpcId) then
        for _, npc in pairs(self._playerNpcList) do
            if FuncSet.CheckNpc(npc) then
                FuncSet.LaunchMissile(self._blackDragonNpcId, npc, 800100101)
                --XLog.Debug("发子弹发子弹发子弹发子弹发子弹发子弹")
            end
        end
    end
end

---boss在跳跳乐期间的动作管理
function XLevelBossFight0014:BigSkill(param)
    if FuncSet.CheckNpc(self._blackDragonNpcId) then
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>令boss 90000 = " .. param)
        FuncSet.SetNpcNoteInt(self._blackDragonNpcId, 90000, param)
        --XLog.Debug("<color=#F0D800>[SceneHunt01]</color>验证boss 90000 = " .. FuncSet.GetNpcNoteInt(self._blackDragonNpcId,90000))
    end
end

---跳跳乐过程中响应
function XLevelBossFight0014:JumpFunProgress()
    -- 预计是玩家勾中boss之后延长本阶段剩余时间
end

---跳跳乐期间有玩家勾中boss处理
function XLevelBossFight0014:PlayerSetAnchorToBoss(playerId)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>有玩家勾中boss了，跳跳乐进度推进")
    local completeCount = 0
    self._playerCompleteJumpFun[playerId] = true --掉线情况已处理
    for _, v in pairs(self._playerCompleteJumpFun) do
        if v then
            completeCount = completeCount + 1
        end
    end
    self._jumpFunCompletePlayerCount = completeCount

    --从体验上来讲，这里的这个逻辑缺乏可视化内容，是反直觉的，还是不要添加一个三名玩家钉上去立马整大活儿的玩法。
    --[[    if completeCount >= 3 then
            self._timer:Schedule(3,4,FuncSet.SetPhase)
        end]]
end

---跳跳乐结束判断
function XLevelBossFight0014:JumpFunEndCheck()
    --[[    if self._phaseTimeCount >= self._jumpFunDefeatTimeLimit then
            --超时结束
            return true
        end]]
end

function XLevelBossFight0014:OnJumpFunEnd()
    self:BigSkill(0)

    --中央塔落下
    self:CenterTowerControl(false)

    -- bgm切轨
    self._bgmTrack = 1

    FuncSet.UpdateRoleCountQTETime(-1, -1, -1)
end

---boss飞上天开大
function XLevelBossFight0014:BossFly()
    --怪物放大绝
    self._timer:Schedule(5.0, self, self.BigSkill, 10)

    --塔升降序列
    for _, sequence in pairs(Config.Sequence) do
        self:SpecialTowerControl(sequence.tower, sequence.raise, sequence.delayTime)
    end

    --关闭外围空气墙对boss的限制
    self:EnableAirWallToNpc(false, self._blackDragonNpcId)
end

---boss落地挨打
function XLevelBossFight0014:BossNotFly()
    --怪物蓄力失败受击
    self._timer:Schedule(3.5, self, self.BigSkill, 20)

    --所有塔一起降下
    for tower, data in pairs(self._towers) do
        if data.type ~= 14 then
            self:TowerControl(tower, false, 5)
        end
    end
    self:EnablePlatforms(false)

    --天基
    self._timer:Schedule(5, self, self.SpearFatality)
    self._timer:Schedule(13.5, self, self.SpearFatalityDamage)
end

function XLevelBossFight0014:SpearFatalityDamage()
    if FuncSet.CheckNpc(self._blackDragonNpcId) then
        FuncSet.ApplyMagic(self._blackDragonNpcId, self._blackDragonNpcId, 5990132, 1) --10%血量上限的真实伤害
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>天基流程，造成10%伤害")
    end
end

---天基演出流程
function XLevelBossFight0014:SpearFatality()
    for _, npc in pairs(self._playerNpcList) do
        FuncSet.ApplyMagic(npc, npc, 5000003, 1)
        self._timer:Schedule(0.5, self, self.RemoveBlackScreen, npc)
    end
    self:SetFightUiActive(false)
    self._timer:Schedule(11, self, self.SetFightUiActive, true)
    self._timer:Schedule(0.5, self, self.PlaySpearFatality)

    self:EnablePlatforms(true)
    self._timer:Schedule(13, self, self.EnablePlatforms, false)
end

function XLevelBossFight0014:RemoveBlackScreen(npc)
    FuncSet.ApplyMagic(npc, npc, 5000006, 1)
end

function XLevelBossFight0014:PlaySpearFatality()
    if FuncSet.CheckNpc(self._blackDragonNpcId) then
        FuncSet.PlayCameraTimeline("SprearFatality01", self._blackDragonNpcId, 0, 0, 0)
        self._timer:Schedule(10.5, "SprearFatality01", FuncSet.StopCameraTimeline, self._blackDragonNpcId)
        FuncSet.ApplyMagic(self._blackDragonNpcId, self._blackDragonNpcId, self._spearFatalitySoundFx, 1)
    elseif FuncSet.CheckNpc(self._wightDragonNpcId) then
        FuncSet.PlayCameraTimeline("SprearFatality01", self._wightDragonNpcId, 0, 0, 0)
        self._timer:Schedule(10.5, "SprearFatality01", FuncSet.StopCameraTimeline, self._wightDragonNpcId)
        FuncSet.ApplyMagic(self._wightDragonNpcId, self._wightDragonNpcId, self._spearFatalitySoundFx, 1)
    end
end

function XLevelBossFight0014:OnBossFlyEnd()
    --玩家回复锁定能力
    for _, npc in pairs(self._playerNpcList) do
        FuncSet.ApplyMagic(npc, npc, self._jumpFunEndSignMagicId, 1) --to remove jump fun start sign
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>npc" .. npc .. "恢复锁定能力")
    end
    --释放boss
    if FuncSet.CheckNpc(self._blackDragonNpcId) then
        FuncSet.SetNpcNoteFloat3(self._blackDragonNpcId, 9001, 0, 0, 0)
        FuncSet.ApplyMagic(self._blackDragonNpcId, self._blackDragonNpcId, self._removeBossEndureMagicId, 1)
    end

    --恢复外围空气墙对boss的限制
    self:EnableAirWallToNpc(true, self._blackDragonNpcId)

    --关闭平台可勾
    self:EnablePlatforms(false)
end

function XLevelBossFight0014:EnableAirWallToNpc(enable, npc)
    FuncSet.SetSceneColliderIgnoreCollision(npc, "AirWalls", -1, enable)
    FuncSet.SetSceneColliderIgnoreCollision(npc, "OuterAirWall", -1, enable)
    FuncSet.SetSceneColliderIgnoreCollision(npc, "MonsterAirWall", -1, enable)
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
        FuncSet.SetBgmAisacControl("AisacControl03", self._bgmCurrentTrack)
    end
end

function XLevelBossFight0014:CenterTowerControl(raise)
    if self._centerTowerMoving then
        --运动过程中收到指令会令运动结束以后立刻执行相反运动，或者取消这个命令
        if raise == self._centerTowerRaise then
            --指令目标和当前运动目标相同，则取消命令
            XLog.Debug("CenterTower运行中收到指令，和当前目标一致")
            self._centerTowerWaitToDo = false
        else
            --指令目标和当前运动目标相反，则记录一个命令
            XLog.Debug("CenterTower运行中收到指令，和当前目标相反")
            self._centerTowerWaitToDo = true
        end
        return
    elseif raise == self._centerTowerRaise then
        --目标状态和当前状态一致
        XLog.Debug("CenterTower收到指令，和当前状态一致")
        return
    end

    if raise then
        FuncSet.PlaySceneAnimation(1)
        self._timer:Schedule(2.6, self, self.OnCenterTowerMoveEnd)
        self._timer:Schedule(2.3, self._centerTowerEffectPlayer, FuncSet.DoSceneObjectAction, 2001) --中央塔升起结束特效
    else
        FuncSet.PlaySceneAnimation(2)
        self._timer:Schedule(3, self, self.OnCenterTowerMoveEnd)
        self._timer:Schedule(2.7, self._centerTowerEffectPlayer, FuncSet.DoSceneObjectAction, 2001) --中央塔降下结束特效
    end

    FuncSet.DoSceneObjectAction(self._centerTowerEffectPlayer, 2002) --开始移动的特效

    self._centerTowerRaise = raise
    self._centerTowerMoving = true

end
---中央塔升起结束回调
function XLevelBossFight0014:OnCenterTowerMoveEnd()
    XLog.Debug("CenterTower运动结束回调")

    self._centerTowerMoving = false
    if self._centerTowerWaitToDo then
        self._centerTowerWaitToDo = false
        self:CenterTowerControl(not self._centerTowerRaise)
    end
end
---注册的行动会被直接顶掉，执行的行动按tower里自己的逻辑判断
function XLevelBossFight0014:TowerControl(tower, raise, delay)
    if self._towersSequences[tower] ~= nil then
        self._timer:Cancel(self._towersSequences[tower])
        self._towersSequences[tower] = nil
    end

    if delay ~= nil then
        local id = self._timer:Schedule(delay, self._towers[tower].agent, self._towers[tower].agent.TowerMove, raise)
        self._towersSequences[tower] = id
        --self._specialTowerSequences[id] = true
    else
        self._towers[tower].agent:TowerMove(raise)
    end
end
---注册的行动不会被顶掉，如果要确认场地关闭需要对注册内容进行清空
function XLevelBossFight0014:SpecialTowerControl(tower, raise, delay)
    if delay ~= nil then
        local id = self._timer:Schedule(delay, self._towers[tower].agent, self._towers[tower].agent.TowerMove, raise)
        --self._towersSequences[tower] = id
        table.insert(self._specialTowerSequences, id)
    else
        self._towers[tower].agent:TowerMove(raise)
    end
end
---清空注册的塔行动
function XLevelBossFight0014:CancelSpecialTowerSequences()
    for _, id in pairs(self._specialTowerSequences) do
        self._timer:Cancel(id)
    end
end
function XLevelBossFight0014:FixLevelState()
    --玩家回复锁定能力
    for _, npc in pairs(self._playerNpcList) do
        FuncSet.ApplyMagic(npc, npc, self._jumpFunEndSignMagicId, 1) --to remove jump fun start sign
        XLog.Debug("<color=#F0D800>[SceneHunt01]</color>npc" .. npc .. "恢复锁定能力")
    end

    self:CancelSpecialTowerSequences()
    --所有塔一起降下
    for tower, data in pairs(self._towers) do
        if data.type ~= 14 then
            self:TowerControl(tower, false)
        end
    end
end

function XLevelBossFight0014:FixLevelStateUpdate()
    if not self._confirmCenterTowerDown then
        if not self._centerTowerMoving then
            if self._centerTowerRaise then
                self:CenterTowerControl(false)
            end
        end
    end
end

function XLevelBossFight0014:CheckLevelStateFixed()
    if not self._centerTowerRaise and not self._centerTowerMoving then
        self._confirmCenterTowerDown = true
        --XLog.Debug("<color=#F0D800>[SceneHunt01]</color>检测到中央塔已降下")
    else
        self._confirmCenterTowerDown = false
    end

    for _, tower in pairs(self._towers) do
        if tower.agent.raised or tower.agent._raising then
            self._confirmTowersDown = false
            return
        end
    end
    self._confirmTowersDown = true
    --XLog.Debug("<color=#F0D800>[SceneHunt01]</color>检测到所有塔已降下")
end

function XLevelBossFight0014:PlayHackSoundFx(npc)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>播放Hack音效")
    FuncSet.ApplyMagic(npc, npc, self._wightDragonHackSoundFx, 1)
end

function XLevelBossFight0014:WightDragonIntro()
    -- 白龙入场镜头+特效timeline
    FuncSet.SwitchSceneTimeline(1, true)
    self._timer:Schedule(11.1, 1, FuncSet.SwitchSceneTimeline, false)
    -- 召唤白龙，并在特效落地的时候放到位置上
    self:InitWightDragon()
    self._timer:Schedule(8.17, self._wightDragonNpcId, FuncSet.SetNpcPosition, self._bossBornPos)
    FuncSet.ApplyMagic(self._wightDragonNpcId, self._wightDragonNpcId, 8002015, 1) -- 卡住白龙ai
    self._timer:Schedule(11.1, self, self.ReleaseWightDragon)
    -- 塔击毁的timeline
    FuncSet.PlaySceneAnimation(4)
    -- 气氛变化timeline
    self._timer:Schedule(0.5, 2, FuncSet.SwitchSceneTimeline, true)
    -- UI开关
    self:SetFightUiActive(false)
    self._timer:Schedule(11.1, self, self.SetFightUiActive, true)
    -- 音效
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>播放白龙入场音效")
    FuncSet.ApplyMagic(
            self._playerNpcContainer._localPlayerNpcId,
            self._playerNpcContainer._localPlayerNpcId,
            self._wightDragonBornSoundFx,
            1
    )
end

function XLevelBossFight0014:ReleaseWightDragon()
    -- 释放白龙ai
    FuncSet.ApplyMagic(
            self._wightDragonNpcId,
            self._wightDragonNpcId,
            8002016,
            1)
end

function XLevelBossFight0014:SetFightUiActive(active)
    for _, npc in pairs(self._playerNpcList) do
        if active then
            FuncSet.ApplyMagic(npc, npc, 5000008)
        else
            FuncSet.ApplyMagic(npc, npc, 5000007)
        end
    end
end

function XLevelBossFight0014:EnablePlatforms(enable)
    for _, plat in pairs(self._towers) do
        if plat.type == 14 then
            plat.agent:HookableEnable(enable)
        end
    end
end

function XLevelBossFight0014:Terminate()

end

return XLevelBossFight0014