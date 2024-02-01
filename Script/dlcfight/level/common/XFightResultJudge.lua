---关卡胜败判定与处理

local XFightResultJudge = XClass(nil, "XFightResultJudge")

---@param proxy StatusSyncFight.XFightScriptProxy
---@param npc number @ local player npc
function XFightResultJudge:Ctor(proxy, npc)
    self._proxy = proxy
    self._localPlayerNpc = npc

    self._proxy:RegisterEvent(EWorldEvent.NpcDie)
    self._proxy:RegisterEvent(EWorldEvent.NpcRevive)
    self._proxy:RegisterEvent(EWorldEvent.FightWin)
    self._proxy:RegisterEvent(EWorldEvent.FightLose)

    self._countTime = 0
    self._fightTimeLimit = self._proxy:GetFightConfig("float", "FightTimeLimit").float --后期在lua这边实现DLC的XConfigManager
end

---@param dt number @delta time
function XFightResultJudge:Update(dt)
    self._countTime = self._countTime + dt
    if self._countTime >= self._fightTimeLimit then
        self._proxy:FinishFight(false, 1)
    end
end

---@param eventType number
---@param eventArgs userdata
function XFightResultJudge:HandleEvent(eventType, eventArgs)
    --on npc die(player/boss
    if eventType == EWorldEvent.NpcDie then
        --self:OnNpcDie(eventArgs.NpcId)
    elseif eventType == EWorldEvent.NpcRevive then
        --self:OnNpcReborn(eventArgs.NpcId)
    elseif eventType == EWorldEvent.FightWin then
        self:OnFightWin()
    elseif eventType == EWorldEvent.FightLose then
        self:OnFightLose()
    end
end

---@param npc number
function XFightResultJudge:OnNpcDie(npc)
    --local npcKind = self._proxy:GetNpcKind(npc)
    --if npcKind == ENpcKind.Player and npc == self._localPlayerNpc then
    --
    --elseif npcKind == ENpcKind.BossMonster then
    --
    --end
end

---@param npc number
function XFightResultJudge:OnNpcReborn(npc)

end

function XFightResultJudge:OnFightWin()

end

function XFightResultJudge:OnFightLose()

end

return XFightResultJudge
