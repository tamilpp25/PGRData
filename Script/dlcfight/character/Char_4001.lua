local XCharLuciaQ4 = XDlcScriptManager.RegCharScript(4001, "XCharLuciaQ4") --Q版四阶露西亚（鸦羽

local _skillIdMap = {
    Interaction = 100219,
}

---@param proxy StatusSyncFight.XFightScriptProxy
function XCharLuciaQ4:Ctor(proxy)
    self._proxy = proxy
end

function XCharLuciaQ4:Init()
    self._npc = self._proxy:GetSelfNpcId() ---@type number
end

---@param dt number @ delta time
function XCharLuciaQ4:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharLuciaQ4:HandleEvent(eventType, eventArgs)
    --XLog.Debug(string.format("------XCharLuciaQ4 Npc:%d HandleEvent eventType:%d", self._npc, eventType))
end

function XCharLuciaQ4:Terminate()
    self._proxy = nil
end

return XCharLuciaQ4