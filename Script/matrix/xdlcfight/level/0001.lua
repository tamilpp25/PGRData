local XLevelFlatLand = XDlcScriptManager.RegLevelScript(0001, "XLevelFlatLand")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs

local _cameraResRefTable = {
    --fightStart =  "fightStart",
}

function XLevelFlatLand.GetCameraResRefTable()
    return _cameraResRefTable
end

---@param proxy StatusSyncFight.XScriptLuaProxy
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