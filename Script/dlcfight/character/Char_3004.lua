local Base = require("Character/BigWorld/XBigWorldPlayerCharBase")

---首席指挥官角色脚本
---@class XCharCommanderChief : XBigWorldPlayerCharBase
local XCharCommanderChief = XDlcScriptManager.RegCharScript(3004, "XCharCommanderChief", Base)

---@param proxy StatusSyncFight.XFightScriptProxy
function XCharCommanderChief:Ctor(proxy)
    self.Super.Ctor(self, proxy)
end

function XCharCommanderChief:Init()
    self.Super.Init(self)
end

---@param dt number @ delta time
function XCharCommanderChief:Update(dt)
    self.Super.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharCommanderChief:HandleEvent(eventType, eventArgs)
    --XLog.Debug(string.format("------XCharCommanderChief Npc:%d HandleEvent etype:%d", self._npc, eventType))
    self.Super.HandleEvent(self, eventType, eventArgs)
end

function XCharCommanderChief:Terminate()
    self.Super.Terminate(self)
end

return XCharCommanderChief