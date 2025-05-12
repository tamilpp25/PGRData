local XSObjXXX = XDlcScriptManager.RegSceneObjScript(0001, "XSObjXXX")

---@param proxy StatusSyncFight.XFightScriptProxy
function XSObjXXX:Ctor(proxy)
    self._proxy = proxy
end

function XSObjXXX:Init()

end

---@param dt number @ delta time
function XSObjXXX:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XSObjXXX:HandleEvent(eventType, eventArgs)

end

function XSObjXXX:Terminate()

end

return XSObjXXX