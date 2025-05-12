local XLevelTestScene = XDlcScriptManager.RegLevelLogicScript(8002, "XLevelTestScene")
--local XFightResultJudge = require("Level/Common/XFightResultJudge")
local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelTestScene:Ctor(proxy)
    self._proxy = proxy
    self._playerNpcContainer = XPlayerNpcContainer.New()
    self._playerNpcList = nil ---@type table<number>
end

function XLevelTestScene:Init()
    self._playerNpcContainer:Init()
    self._playerNpcList = self._playerNpcContainer:GetPlayerNpcList()

    --self._fightResultJudge = XFightResultJudge.New(self._proxy, self._proxy:GetLocalPlayerNpcId())
end

---@param dt number @ delta time
function XLevelTestScene:Update(dt)

    --self._fightResultJudge:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevelTestScene:HandleEvent(eventType, eventArgs)
    self.Super.HandleEvent(self, eventType, eventArgs)

    self._playerNpcContainer:HandleEvent(eventType, eventArgs)
    --self._fightResultJudge:HandleEvent(eventArgs)
end

function XLevelTestScene:Terminate()
end

---@param npc number
function XLevelTestScene:IsNpcDead(npc)
    return self._proxy:CheckNpcAction(npc, ENpcAction.Dying) or self._proxy:CheckNpcAction(npc, ENpcAction.Death) -- dying or death
end

return XLevelTestScene