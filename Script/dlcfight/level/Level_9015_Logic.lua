--- 幻影崩岳boss战测试关
local XLevel9015 = XDlcScriptManager.RegLevelLogicScript(9015, "XLevel9015")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs
local Tool = require("Level/Common/XLevelTools")
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
local Timer = require("Level/Common/XTaskScheduler")

local _cameraResRefTable = {

}

function XLevel9015.GetCameraResRefTable()
    return _cameraResRefTable
end

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevel9015:Ctor(proxy)
    self._proxy = proxy
    self._timer = Timer.New()

    self._bossHidePos = { x = 60, y = -200, z = 60 }
    self._bossBornPos = { x = 60, y = 1.95, z = 60 }
    self._bossBornRot = { x = 0, y = 180, z = 0 }
    self._bossId = nil ---boss的id
    self._playerNpcContainer = XPlayerNpcContainer.New()

    self._switches = {
        {
            placeId = 1,
            agent = nil,
            object = self,
            func = self.PlaySceneAnim,
            param = nil,
            times = 1,
            defaultEnable = true
        },
    }

    self._deathZonePlaceId = 9999

    self._debug = false
end

function XLevel9015:Init()
    self:InitPhase()
    self:InitNpc()
    self:InitPlayer()
    --self:InitSwitch()
    self:InitListen()

end

---@param dt number @ delta time
function XLevel9015:Update(dt)
    self._timer:Update(dt)
    self:OnUpdatePhase(dt)
    self:PlayerInteract()
end

---@param eventType number
---@param eventArgs userdata
function XLevel9015:HandleEvent(eventType, eventArgs)
    self.Super.HandleEvent(self, eventType, eventArgs)
    self:HandlePhaseEvent(eventType, eventArgs)

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
    elseif eventType == EScriptEvent.NpcInteractComplete then
        --交互完成
        self:OnNpcInteractComplete(eventArgs)
    end

    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
end

function XLevel9015:InitPhase()
    --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    self._lastPhase = 0
    self._phaseStartedDelayTranslate = false ---阶段延迟跳转需要设置为true
    self._phaseTimeCount = 0

    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化关卡阶段参数完成")
end

function XLevel9015:InitNpc()
    --生成怪物
    self._bossId = FuncSet.GenerateNpc(8004, ENpcCampType.Camp2, self._bossBornPos, self._bossBornRot)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>召唤npc完成")
end

function XLevel9015:InitPlayer()
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

function XLevel9015:InitSwitch()
    self._switches = Tool.InitSwitch(self._switches)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化场景中开关完成")
end

function XLevel9015:InitListen()
    self._proxy:RegisterSceneObjectTriggerEvent(self._deathZonePlaceId, 1) --死区
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化其他监听内容完成")
end

function XLevel9015:OnPlayerNpcCreate(npc)
    self._proxy:RegisterNpcEvent(EScriptEvent.NpcCastSkill, npc)
    self._proxy:RegisterNpcEvent(EScriptEvent.NpcExitSkill, npc)
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注册角色技能监听：" .. npc)
end

function XLevel9015:OnPlayerNpcDestroy(npc)
    self._proxy:UnregisterNpcEvent(EScriptEvent.NpcCastSkill, npc)
    self._proxy:UnregisterNpcEvent(EScriptEvent.NpcExitSkill, npc)
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注销角色技能监听：" .. npc)
end

---玩家之间的交互
function XLevel9015:PlayerInteract()
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
function XLevel9015:CheckPlayerRescueInteract(launcher, target, dist)
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
function XLevel9015:OnNpcInteractComplete(eventArgs)
    local npc = eventArgs.NpcId
    FuncSet.RebornNpc(npc, self._playerRescueDict[npc]) --复活救援对象
    FuncSet.CloseInteraction(npc, false) --关闭救援者的交互按钮
    self._playerRescueDict[npc] = nil --清除救援对象记录
end

---Npc是否处在濒死状态
function XLevel9015:IsNpcDying(npcId)
    return FuncSet.CheckNpcAction(npcId, ENpcAction.Dying)
end

---Npc是否死亡
function XLevel9015:IsNpcDead(npcId)
    return FuncSet.CheckNpcAction(npcId, ENpcAction.Dying) or FuncSet.CheckNpcAction(npcId, ENpcAction.Death)
end

---跳转关卡阶段
function XLevel9015:SetPhase(phase)
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
function XLevel9015:OnUpdatePhase(dt)
    self._phaseTimeCount = self._phaseTimeCount + dt
    if self._currentPhase == 0 then
    elseif self._currentPhase == 1 then
    end
end

---进入一个关卡阶段时需要做的事情在这里实现。一般用作设置阶段所需的环境
function XLevel9015:OnEnterPhase(phase)
    if phase == 1 then
    elseif phase == 2 then
    end
end

---关卡阶段改变时需要执行的逻辑，一般用于通知外部
function XLevel9015:OnPhaseChanged(lastPhase, nextPhase)
end

---处理阶段相关的事件响应、状态检测、信息获取
function XLevel9015:HandlePhaseEvent(eventType, eventArgs)
    if self._currentPhase == 1 then
    elseif self._currentPhase == 2 then
    end
end

function XLevel9015:Terminate()

end

return XLevel9015