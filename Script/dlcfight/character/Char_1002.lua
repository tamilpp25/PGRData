local XCharLuciaP1 = XDlcScriptManager.RegCharScript(1002, "XCharLuciaP1") --一阶露西亚（红莲
local XAnchorVisualization = require("Level/Common/XAnchorVisualization")
local Hunt01BossFight = require("Level/Common/XLevelScriptHunt01")

---@param proxy StatusSyncFight.XFightScriptProxy
function XCharLuciaP1:Ctor(proxy)
    self._proxy = proxy

    self._skillIds = {
        Interaction = 100219,

        Red = 1002,
        Yellow = 1002,
        Blue = 1002,
    }
end

function XCharLuciaP1:Init()
    self._npc = self._proxy:GetSelfNpcId() ---@type number

    self._anchorVisual = XAnchorVisualization.New(self._proxy, self._npc)
    self._bossFight = Hunt01BossFight.New(self._proxy,self._npc)
end

---@param dt number @ delta time
function XCharLuciaP1:Update(dt)
    self._anchorVisual:Update(dt)
    self._bossFight:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharLuciaP1:HandleEvent(eventType, eventArgs)
    --XLog.Debug(string.format("------XCharLuciaP1 Npc:%d HandleEvent etype:%d", self._npc, eventType))
    self._bossFight:HandleEvent(eventType, eventArgs)
end

function XCharLuciaP1:Terminate()
    self._proxy = nil
end

return XCharLuciaP1