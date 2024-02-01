local XCharacterScriptXXX = XDlcScriptManager.RegCharScript(0000, "XCharacterScriptXXX")

---@param proxy StatusSyncFight.XFightScriptProxy
function XCharacterScriptXXX:Ctor(proxy)
    self._proxy = proxy
end

function XCharacterScriptXXX:Init()

end

---@param dt number @ delta time
function XCharacterScriptXXX:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XCharacterScriptXXX:HandleEvent(eventType, eventArgs)

end

function XCharacterScriptXXX:Terminate()

end

return XCharacterScriptXXX