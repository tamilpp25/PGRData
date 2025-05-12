local XCharKalieP1 = XDlcScriptManager.RegCharScript(1007, "XCharKalieP1") --一阶卡列（爆裂）
local XAnchorVisualization = require("Level/Common/XAnchorVisualization")
local Hunt01BossFight = require("Level/Common/XLevelScriptHunt01")

local _skillIdMap = {
    Interaction = 100719,
}

---@param proxy StatusSyncFight.XFightScriptProxy
function XCharKalieP1:Ctor(proxy)
    self._proxy = proxy
end

function XCharKalieP1:Init()
    self._npc = self._proxy:GetSelfNpcId() ---@type number

    self._anchorVisual = XAnchorVisualization.New(self._proxy, self._npc)
    self._bossFight = Hunt01BossFight.New(self._proxy,self._npc)
end

---@param dt number @ delta time
function XCharKalieP1:Update(dt)
    self._anchorVisual:Update(dt)
    self._bossFight:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharKalieP1:HandleEvent(eventType, eventArgs)
    --XLog.Debug(string.format("------XCharKalieP1 Npc:%d HandleEvent etype:%d", self._npc, eventType))
    self._bossFight:HandleEvent(eventType, eventArgs)
end

function XCharKalieP1:Terminate()
    self._proxy = nil
end

return XCharKalieP1