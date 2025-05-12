local XLevelFlatLand = XDlcScriptManager.RegLevelLogicScript(0001, "XLevelFlatLand")

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelFlatLand:Ctor(proxy)
    self._proxy = proxy
end

function XLevelFlatLand:Init()
end

---@param dt number @ delta time
function XLevelFlatLand:Update(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevelFlatLand:HandleEvent(eventType, eventArgs)
    self.Super.HandleEvent(self, eventType, eventArgs)
end

function XLevelFlatLand:Terminate()
end

return XLevelFlatLand