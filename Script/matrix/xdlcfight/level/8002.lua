local XLevelTestScene = XDlcScriptManager.RegLevelScript(8002, "XLevelTestScene")
--local XFightResultJudge = require("XDLCFight/Level/Common/XFightResultJudge")
local XPlayerNpcContainer = require("XDLCFight/Level/Common/XPlayerNpcContainer")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs

local _cameraResRefTable = {
    --"fightStart",
}

function XLevelTestScene.GetCameraResRefTable()
    return _cameraResRefTable
end

---@param proxy StatusSyncFight.XScriptLuaProxy
function XLevelTestScene:Ctor(proxy)
    self._proxy = proxy
    self._playerNpcContainer = XPlayerNpcContainer.New()
    self._playerNpcList = nil ---@type table<number>
    self._playerRescueDict = {}
end

function XLevelTestScene:Init()
    self._playerNpcContainer:Init()
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()
    self._playerNpcList = FuncSet.GetPlayerNpcList()
    for i = 1, #self._playerNpcList do
        local npc = self._playerNpcList[i]
        self._playerRescueDict[npc] = nil
    end

    --self._fightResultJudge = XFightResultJudge.New(FuncSet.GetLocalPlayerNpcId())
end

---@param dt number @ delta time
function XLevelTestScene:Update(dt)
    for i = 1, #self._playerNpcList do
        local npcA = self._playerNpcList[i]
        for j = 1, #self._playerNpcList do
            local npcB = self._playerNpcList[j]
            self:CheckPlayerInteract(npcA, npcB, 3.5)
        end
    end

    --self._fightResultJudge:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevelTestScene:HandleEvent(eventType, eventArgs)
    self.Super.HandleEvent(self, eventType, eventArgs)
    if eventType == EScriptEvent.NpcInteractComplete then --交互完成
        self:OnNpcInteractComplete(eventArgs)
    end

    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
    --self._fightResultJudge:HandleEvent(eventArgs)
end

function XLevelTestScene:Terminate()
end

---@param npcA number
---@param npcB number
---@param dist number @distance
function XLevelTestScene:CheckPlayerInteract(npcA, npcB, dist)
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
function XLevelTestScene:IsNpcDead(npc)
    return FuncSet.CheckNpcAction(npc, ENpcAction.Dying) or FuncSet.CheckNpcAction(npc, ENpcAction.Death) -- dying or death
end

---@param eventArgs StatusSyncFight.NpcEventArgs
function XLevelTestScene:OnNpcInteractComplete(eventArgs)
    local npc = eventArgs.NpcId
    FuncSet.RebornNpc(npc, self._playerRescueDict[npc]) --复活救援对象
    FuncSet.SwitchInteractButton(npc, false) --关闭救援者的交互按钮
    self._playerRescueDict[npc] = nil --清除救援对象记录
end

return XLevelTestScene