local XLevelScriptXXX = XDlcScriptManager.RegLevelScript(0000, "XLevelXXX")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs

local _cameraResRefTable = {
    fightStart =  "fightStart",
}

function XLevelScriptXXX.GetCameraResRefTable()
    return _cameraResRefTable
end

---@param proxy StatusSyncFight.XScriptLuaProxy
function XLevelScriptXXX:Ctor(proxy)
    self._proxy = proxy
end

function XLevelScriptXXX:Init()

end

---@param dt number @ delta time
function XLevelScriptXXX:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XLevelScriptXXX:HandleEvent(eventType, eventArgs)
    self.Super.HandleEvent(self, eventType, eventArgs)

end

function XLevelScriptXXX:Terminate()

end

return XLevelScriptXXX