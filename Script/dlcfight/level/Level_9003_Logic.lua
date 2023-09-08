--- 场地控制验证关卡
local XLevelBossFightStage = XDlcScriptManager.RegLevelLogicScript(9003, "XLevelBossFightStage")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs
local Config = require("Level/LevelConfig/Hunt01BossFightConfig") -- 读取场景物体的配置数据,作为实例存在本地
local Tool = require("Level/Common/XLevelTools")
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")

---注册使用到的虚拟相机
local _cameraResRefTable = {
}

---获取虚拟相机动态加载内容
function XLevelBossFightStage.GetCameraResRefTable()
    return _cameraResRefTable
end

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelBossFightStage:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()

    --{{{nps
    self._playerList = nil ---储存玩家引用的数组
    self._localPlayerNpcId = nil ---运行脚本的主机玩家
    self._playerCount = 1 ---这局有多少玩家
    self._playerRescueDict = {}
    self._playerNpcContainer = XPlayerNpcContainer.New()
    --}}}

    --{{{objects
    self._towers = {}
    self._switches = {
        {
            placeId = 3000,
            agent = nil,
            object = self,
            func = self.TestSwitchStartJumpFun,
            param = nil,
            times = -1,
            defaultEnable = true
        },
    }
    --}}}
    self._centerTowerEffectPlayer = 1001

    self._timer = nil ---延时计时器

    self._bgmTrack = 0.5

end

---脚本初始化，自动执行
function XLevelBossFightStage:Init()
    self:InitPhase()
    self:InitPlayer()
    self:InitTower()
    self:InitSwitch()
    self:InitListen()
    self:InitStageStateMachine()
end

---@param dt number @ delta time
function XLevelBossFightStage:Update(dt)
    self._timer:Update(dt)
    self:OnUpdatePhase(dt)
    self:PlayerInteract()
    self:OnInteractButton()
    self:BgmTrackControl(dt)
    self:StageStateMachineUpdate(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevelBossFightStage:HandleEvent(eventType, eventArgs)
    XLevelBossFightStage.Super.HandleEvent(self, eventType, eventArgs)
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
        --测试用
        -- 玩家进入交互trigger

    elseif eventType == EScriptEvent.NpcCastSkill then
        XLog.Debug(string.format("Level listen npc:%d cast skill:%d to target:%d",
                eventArgs.LauncherId, eventArgs.SkillId, eventArgs.TargetId))
    elseif eventType == EScriptEvent.NpcInteractComplete then
        --交互完成
        self:OnNpcInteractComplete(eventArgs)
    end


    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
end

--{{{Init
function XLevelBossFightStage:InitPhase()
    self._currentPhase = 0
    self._lastPhase = 0
    self._phaseStartedDelayTranslate = false ---阶段延迟跳转需要设置为true
    self._phaseTimeCount = 0

    self._centerTowerRaise = nil
    self._centerTowerMoving = nil
    self._confirmCenterTowerDown = false
    self._waitTime = 0
    self._towersSequences = {}
    self._confirmTowersDown = false

    self._stageState = StageState.Close

    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化关卡阶段参数完成")
end

function XLevelBossFightStage:InitPlayer()
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

function XLevelBossFightStage:InitTower()
    self._towers = Tool.InitTower(Config.Towers)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化场景中塔完成")
end

function XLevelBossFightStage:InitSwitch()
    self._switches = Tool.InitSwitch(self._switches)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化场景中开关完成")
end

function XLevelBossFightStage:InitListen()
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化其他监听内容完成")
end
--}}}

function XLevelBossFightStage:OnPlayerNpcCreate(npc)
    self._proxy:RegisterNpcEvent(EScriptEvent.NpcCastSkill, npc)
    self._proxy:RegisterNpcEvent(EScriptEvent.NpcExitSkill, npc)
    XLog.Debug("<color=#F0D800>[SceneTest01]</color>注册角色技能监听：" .. npc)
    XLog.Debug(self._playerFocusAnchorDic)
end

function XLevelBossFightStage:OnPlayerNpcDestroy(npc)
    self._proxy:UnregisterNpcEvent(EScriptEvent.NpcCastSkill, npc)
    self._proxy:UnregisterNpcEvent(EScriptEvent.NpcExitSkill, npc)
    XLog.Debug("<color=#F0D800>[SceneTest01]</color>注销角色技能监听：" .. npc)
end

---@param npcA number
---@param npcB number
---@param dist number @distance
function XLevelBossFightStage:CheckPlayerInteract(npcA, npcB, dist)
    if npcA == npcB then
        return
    end

    local inRange = FuncSet.CheckNpcDistance(npcA, npcB, dist)
    if not self:IsNpcDead(npcA) and inRange and self:IsNpcDead(npcB) then
        if self._playerRescueDict[npcA] == nil then
            XLog.Debug(string.format("------NpcA:%d  NpcB:%d SwitchInteractButton ", npcA, npcB, dist) .. tostring(true))
            FuncSet.SwitchInteractButton(npcA, true)
            self._playerRescueDict[npcA] = npcB
        end
    else
        if self._playerRescueDict[npcA] == npcB then
            XLog.Debug(string.format("------NpcA:%d  NpcB:%d SwitchInteractButton ", npcA, npcB, dist) .. tostring(false))
            FuncSet.SwitchInteractButton(npcA, false)
            self._playerRescueDict[npcA] = nil
        end
    end
end

---@param npc number
function XLevelBossFightStage:IsNpcDead(npc)
    return FuncSet.CheckNpcAction(npc, ENpcAction.Dying) or FuncSet.CheckNpcAction(npc, ENpcAction.Death) -- dying or death
end

---@param eventArgs StatusSyncFight.NpcEventArgs
function XLevelBossFightStage:OnNpcInteractComplete(eventArgs)
    local npc = eventArgs.NpcId
    FuncSet.RebornNpc(npc, self._playerRescueDict[npc]) --复活救援对象
    FuncSet.SwitchInteractButton(npc, false) --关闭救援者的交互按钮
    self._playerRescueDict[npc] = nil --清除救援对象记录
end

function XLevelBossFightStage:OnInteractButton()
    if self._debug then
        if FuncSet.IsKeyDown(ENpcOperationKey.Ball11) then
            if FuncSet.CheckNpc(self._blackDragonNpcId) then
                FuncSet.PlayCameraTimeline("SprearFatality01", self._blackDragonNpcId, 0, 0, 0)
            end
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball12) then
            if FuncSet.CheckNpc(self._blackDragonNpcId) then
                FuncSet.StopCameraTimeline("SprearFatality01", self._blackDragonNpcId)
            end
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball10) then
            if FuncSet.CheckNpc(self._blackDragonNpcId) then
                FuncSet.NpcDie(self._blackDragonNpcId)
            end
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball9) then
            for _, npc in pairs(self._playerNpcList) do
                FuncSet.ApplyMagic(npc, npc, 5990140, 1)
            end
        end
    end
end

local StageState = {
    Close = 1,
    JumpFun = 2,
    Boss = 3,
}

function XLevelBossFightStage:InitStageStateMachine()

end

function XLevelBossFightStage:StageStateMachineUpdate(dt)

end

function XLevelBossFightStage:Terminate()

end

return XLevelBossFightStage