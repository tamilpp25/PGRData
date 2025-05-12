--- original prototype level
local XLevel0010 = XDlcScriptManager.RegLevelLogicScript(0010, "XLevel0010")

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevel0010:Ctor(proxy)
    self._proxy = proxy
end

function XLevel0010:Init()
end

---@param dt number @ delta time
function XLevel0010:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XLevel0010:HandleEvent(eventType, eventArgs)
end

function XLevel0010:Terminate()

end

return XLevel0010