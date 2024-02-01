--- Hun01第一场boss战正式关卡 黑龙崩岳
local XLevelMultiPlayerTest = XDlcScriptManager.RegLevelLogicScript(9000, "XLevelBossFightHunt01")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs
--local Config = require("Level/LevelConfig/Hunt01BossFightConfig") -- 读取场景物体的配置数据,作为实例存在本地
local Tool = require("Level/Common/XLevelTools")
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelMultiPlayerTest:Ctor(proxy)
    self._proxy = proxy

    --{{{nps
    self._playerList = nil ---储存玩家引用的数组
    self._localPlayerNpcId = nil ---运行脚本的主机玩家
    self._playerCount = 1 ---这局有多少玩家
    self._playerRescueDict = {}
    self._playerNpcContainer = XPlayerNpcContainer.New()
    --}}}

    --{{{objects
    self._switches = {
        {
            placeId = 1,
            agent = nil,
            object = self,
            func = self.SwitchInteract,
            param = nil,
            times = -1,
            defaultEnable = true
        },
    }
    --}}}


    self._timer = nil ---延时计时器

end

---脚本初始化，自动执行
function XLevelMultiPlayerTest:Init()
    -- 获取玩家
    self._localPlayerNpcId = FuncSet.GetLocalPlayerNpcId()
    self._playerNpcContainer:Init()
    self._playerNpcContainer.PlayerNpcCreateCallback = function(npc)
        self:OnPlayerNpcCreate(npc)
    end
    self._playerNpcContainer.PlayerNpcDestroyCallback = function(npc)
        self:OnPlayerNpcDestroy(npc)
    end
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerCount = #self._playerNpcList
    --开始监听玩家
    for _, npc in pairs(self._playerNpcList) do
        self:OnPlayerNpcCreate(npc)
    end
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化关卡用玩家参数完成")

    -- 配置场景中开关
    self._switches = Tool.InitSwitch(self._switches)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化场景中开关完成")

    -- 其他
    self._timer = Tool.NewTimer()
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>初始化其他内容完成")

end

---@param dt number @ delta time
function XLevelMultiPlayerTest:Update(dt)
    Tool.TimerUpdate(self._timer, dt)

    --玩家救援复活交互检测
    for i = 1, #self._playerNpcList do
        local npcA = self._playerNpcList[i]
        for j = 1, #self._playerNpcList do
            local npcB = self._playerNpcList[j]
            self:CheckPlayerInteract(npcA, npcB, 3.5)
        end
    end

end

---@param eventType number
---@param eventArgs userdata
function XLevelMultiPlayerTest:HandleEvent(eventType, eventArgs)
    XLevelMultiPlayerTest.Super.HandleEvent(self, eventType, eventArgs)
    if eventType == EScriptEvent.SceneObjectTrigger then
        --[[        XLog.Debug("XLevelBossFight1 SceneObjectTriggerEvent:"
                        .. " TouchType " .. tostring(eventArgs.TouchType)
                        .. " SourceActorId " .. tostring(eventArgs.SourceActorId)
                        .. " SceneObjectId " .. tostring(eventArgs.SceneObjectId)
                        .. " TriggerId " .. tostring(eventArgs.TriggerId)
                        .. " TriggerState " .. tostring(eventArgs.TriggerState)
                        .. " Log自关卡"
                )]]

    elseif eventType == EScriptEvent.NpcCastSkill then
        XLog.Debug(string.format("Level listen npc:%d cast skill:%d to target:%d",
                eventArgs.LauncherId, eventArgs.SkillId, eventArgs.TargetId))
    elseif eventType == EScriptEvent.NpcInteractComplete then
        --交互完成
        self:OnNpcInteractComplete(eventArgs)
    end

    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
end

function XLevelMultiPlayerTest:OnPlayerNpcCreate(npc)
    self._proxy:RegisterNpcEvent(EScriptEvent.NpcCastSkill, npc)
    self._proxy:RegisterNpcEvent(EScriptEvent.NpcExitSkill, npc)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注册角色技能监听：" .. npc)
    XLog.Debug(self._playerFocusAnchorDic)
end

function XLevelMultiPlayerTest:OnPlayerNpcDestroy(npc)
    self._proxy:UnregisterNpcEvent(EScriptEvent.NpcCastSkill, npc)
    self._proxy:UnregisterNpcEvent(EScriptEvent.NpcExitSkill, npc)
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>注销角色技能监听：" .. npc)
end

---@param npcA number
---@param npcB number
---@param dist number @distance
function XLevelMultiPlayerTest:CheckPlayerInteract(npcA, npcB, dist)
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
function XLevelMultiPlayerTest:IsNpcDead(npc)
    return FuncSet.CheckNpcAction(npc, ENpcAction.Dying) or FuncSet.CheckNpcAction(npc, ENpcAction.Death) -- dying or death
end

---@param eventArgs StatusSyncFight.NpcEventArgs
function XLevelMultiPlayerTest:OnNpcInteractComplete(eventArgs)
    local npc = eventArgs.NpcId
    FuncSet.RebornNpc(npc, self._playerRescueDict[npc]) --复活救援对象
    FuncSet.SwitchInteractButton(npc, false) --关闭救援者的交互按钮
    self._playerRescueDict[npc] = nil --清除救援对象记录
end

function XLevelMultiPlayerTest:SwitchInteract()
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>成功触发")
end

function XLevelMultiPlayerTest:Terminate()

end

return XLevelMultiPlayerTest