---关卡胜败判定与处理

local XFightResultJudge = XClass(nil, "XFightResultJudge")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs

---@param npc number @ player npc
function XFightResultJudge:Ctor(npc)
    self._localPlayerNpc = npc

    self._countTime = 0
    self._fightTimeLimit = FuncSet.GetFightConfig("float", "FightTimeLimit").float --后期在lua这边实现DLC的XConfigManager
end

---@param dt number @delta time
function XFightResultJudge:Update(dt)
    self._countTime = self._countTime + dt
    if self._countTime >= self._fightTimeLimit then
        FuncSet.FinishFight(false, 1)
    end
end

---@param eventType number
---@param eventArgs userdata
function XFightResultJudge:HandleEvent(eventType, eventArgs)
    --on npc die(player/boss
    if eventType == EScriptEvent.NpcDie then
        --self:OnNpcDie(eventArgs.NpcId)
    elseif eventType == EScriptEvent.NpcReborn then
        --self:OnNpcReborn(eventArgs.NpcId)
    elseif eventType == EScriptEvent.FightWin then
        self:OnFightWin()
    elseif eventType == EScriptEvent.FightLose then
        self:OnFightLose()
    end
end

---@param npc number
function XFightResultJudge:OnNpcDie(npc)
    --local npcKind = FuncSet.GetNpcKind(npc)
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
