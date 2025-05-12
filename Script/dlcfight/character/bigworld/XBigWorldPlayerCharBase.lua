---大世界玩家角色基类
---@class XBigWorldPlayerCharBase
---@field protected _kuroroScript XCharKuroro
local XBigWorldPlayerCharBase = XClass(nil, "XPlayerCharBase")

---@param proxy StatusSyncFight.XFightScriptProxy
function XBigWorldPlayerCharBase:Ctor(proxy)
    self._proxy = proxy
    self._kuroroScript = nil
end

function XBigWorldPlayerCharBase:Init()
    self._uuid = self._proxy:GetSelfNpcId() ---@type number

    self._proxy:RegisterEvent(EWorldEvent.NpcInteractComplete)
end

---@param dt number @ delta time
function XBigWorldPlayerCharBase:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XBigWorldPlayerCharBase:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractComplete then
        if eventArgs.LauncherId == self._uuid
            and self._proxy:ShouldActorReactToPlayerInteract(eventArgs.TargetId) == false
            and self._kuroroScript
        then
            self._kuroroScript:GoToInteractWith(eventArgs.TargetId, eventArgs.OptionId)
        end
    end
end

function XBigWorldPlayerCharBase:Terminate()
    self._proxy = nil
end

---@param script XCharKuroro
function XBigWorldPlayerCharBase:SetKuroroScript(script)
    self._kuroroScript = script
end

return XBigWorldPlayerCharBase