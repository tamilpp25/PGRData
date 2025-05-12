---角色交互模块

---@class XNpcInteraction
local XNpcInteraction = XClass(nil, "XNpcInteraction")

--local _interactionSkillNoteKey = 100091

---@param proxy StatusSyncFight.XFightScriptProxy
---@param npc number
function XNpcInteraction:Ctor(proxy, npc, interactionSkillId)
    self._proxy = proxy
    self._type = 0
    self._targetId = 0
    self._countTime = 0
    self._interactTime = 0
    self._interacting = false
    self._callback = nil ---@type function

    self._npc = npc ---@type number
    self._interactionSkillId = interactionSkillId
    if self._interactionSkillId <= 0 then
        XLog.Error("XNpcInteraction.Ctor error, invalid interaction skill id: " .. tostring(self._interactionSkillId))
        return
    end

    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.NpcExitSkill)

    self._initialized = true
end

function XNpcInteraction:Update(deltaTime)
    if not self._initialized then
        return
    end

    if not self._interacting then
        return
    end

    self._countTime = self._countTime + deltaTime
    local progress = self._countTime / self._interactTime
    --self._proxy:SetInteractionProgress(progress) --更新交互进度到UI
    if self._countTime >= self._interactTime then
        self._countTime = 0
        self:CompleteInteraction()
    end
end

---@param eventType number
---@param eventArgs table
function XNpcInteraction:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart and eventArgs.LauncherId == self._npc then --Npc开始交互
        XLog.Debug(string.format("XNpcInteraction.HandleEvent, launcher:%d try start interact", self._npc))
        local interactArgs = eventArgs
        self:StartInteraction(interactArgs.TargetId, interactArgs.Time, interactArgs.Type)
    elseif eventType == EWorldEvent.NpcExitSkill and eventArgs.LauncherId == self._npc then
        self:OnSkillExit(eventArgs)
    end
end

---@param eventArgs StatusSyncFight.XNpcSkillEventArgs
function XNpcInteraction:OnSkillExit(eventArgs)
    if not self._initialized then
        return
    end

    if not self._interacting then
        return
    end

    --交互中退出交互技能，交互被中断
    if eventArgs.LauncherId == self._npc and eventArgs.SkillId == self._interactionSkillId then
        self:StopInteraction()
        XLog.Debug("XNpcInteraction.OnSkillExit skill was aborted, stop interaction.")
    end
end

---@param targetId number
---@param time number @second
---@param type number
---@param callback function
---@return boolean
function XNpcInteraction:StartInteraction(targetId, time, type, callback)
    if not self._initialized then
        return false
    end

    if self._interacting then
        return false
    end

    self._targetId = targetId
    self._interactTime = time
    self._type = type
    self._callback = callback

    if self._proxy:CastSkill(self._npc, self._interactionSkillId) then
        self._interacting = true
    else
        XLog.Debug(string.format("XNpcInteraction.StartInteraction, launcher:%d cast interact skill failed!", self._npc))
        self:Reset()
        return false
    end

    if type == EInteractType.Rescue then
        self._proxy:SetNpcRescuedState(self._npc, targetId, true)
    end

    XLog.Debug(string.format("XNpcInteraction.StartInteraction launcher:%d target:%d", self._npc, targetId))
    return true
end

function XNpcInteraction:StopInteraction()
    --self._proxy:SetInteractionProgress(0) --交互进度清零
    if self._type == EInteractType.Rescue then
        self._proxy:SetNpcRescuedState(self._npc, self._targetId, false) --关闭被救者的被救援UI
    end

    self:Reset()
end

function XNpcInteraction:CompleteInteraction()
    self._interacting = false --提前修改交互中状态，避免下面的结束打断技能被OnSkillExit误认为交互技能中断
    self._proxy:AbortSkill(self._npc, true) --打断交互技能（交互技能统一配置了非常长的CastTime，以保证交互过程中不会被移动打断，故此处需要强制打断。
    --self._proxy:SetInteractionProgress(0) --交互进度清零
    --self._proxy:NpcInteractComplete(self._npc) --发送消息给关卡逻辑

    if self._type == EInteractType.Rescue then
        self._proxy:SetNpcRescuedState(self._npc, self._targetId, false) --关闭被救者的被救援UI
    end

    if self._callback then
        self._callback()
    end

    self:Reset()

    XLog.Debug(string.format("XNpcInteraction.CompleteInteraction, launcher:%d target:%d", self._npc, self._targetId))
end

function XNpcInteraction:Reset()
    self._targetId = 0
    self._type = 0
    self._countTime = 0
    self._interactTime = 0
    self._interacting = false
    self._callback = nil
end

return XNpcInteraction