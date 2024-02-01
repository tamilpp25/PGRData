local XCharLuciaQ4 = XDlcScriptManager.RegCharScript(4001, "XCharLuciaQ4") --Q版四阶露西亚（鸦羽
--local XNpcInteraction = require("XDLCFight/Level/Common/XNpcInteraction")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs

local _skillIdMap = {
    Interaction = 100219,
}

---@param proxy StatusSyncFight.XFightScriptProxy
function XCharLuciaQ4:Ctor(proxy)
    self._proxy = proxy
end

function XCharLuciaQ4:Init()
    self._npc = self._proxy:GetSelfNpcId() ---@type number

    --self._interaction = XNpcInteraction.New(self._proxy, self._npc, _skillIdMap.Interaction) ---@type XNpcInteraction
end

---@param dt number @ delta time
function XCharLuciaQ4:Update(dt)
    --self._interaction:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharLuciaQ4:HandleEvent(eventType, eventArgs)
    --XLog.Debug(string.format("------XCharLuciaQ4 Npc:%d HandleEvent eventType:%d", self._npc, eventType))
    --self._interaction:HandleEvent(eventType, eventArgs)
end

function XCharLuciaQ4:Terminate()
    self._proxy = nil
end

return XCharLuciaQ4