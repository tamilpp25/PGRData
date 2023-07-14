local XCharBiancaP3 = XDlcScriptManager.RegCharScript(1014, "XCharBiancaP3") --三阶比安卡（真理
local XNpcInteraction = require("XDLCFight/Level/Common/XNpcInteraction")
local XAnchorVisualization = require("XDLCFight/Level/Common/XAnchorVisualization")
local Hunt01BossFight = require("XDLCFight/Level/Common/XLevelScriptHunt01")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs

local _skillIdMap = {
    Interaction = 101424,
}

---@param proxy StatusSyncFight.XScriptLuaProxy
function XCharBiancaP3:Ctor(proxy)
    self._proxy = proxy
end

function XCharBiancaP3:Init()
    self._npc = self._proxy:GetSelfNpcId() ---@type number

    self._interaction = XNpcInteraction.New(self._proxy, self._npc, _skillIdMap.Interaction) ---@type XNpcInteraction
    self._anchorVisual = XAnchorVisualization.New(self._npc)
    self._bossFight = Hunt01BossFight.New(self._proxy,self._npc)
end

---@param dt number @ delta time
function XCharBiancaP3:Update(dt)
    self._interaction:Update(dt)
    self._anchorVisual:Update(dt)
    self._bossFight:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharBiancaP3:HandleEvent(eventType, eventArgs)
    --XLog.Debug(string.format("------XCharLuciaP1 Npc:%d HandleEvent etype:%d", self._npc, eventType))
    self._interaction:HandleEvent(eventType, eventArgs)
    self._bossFight:HandleEvent(eventType, eventArgs)
end

function XCharBiancaP3:Terminate()

end

function XCharBiancaP3:OnResLoadComplete()

end


local _effectRefTable = {
}

function XCharBiancaP3.GetEffectRefTable()
    return _effectRefTable
end

return XCharBiancaP3