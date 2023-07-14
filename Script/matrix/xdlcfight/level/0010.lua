local XLevelPrototype = XDlcScriptManager.RegLevelScript(0010, "XLevelPrototype")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs

local _cameraResRefTable = {
    "MHWCam0",
}

function XLevelPrototype.GetCameraResRefTable()
    return _cameraResRefTable
end

---@param proxy StatusSyncFight.XScriptLuaProxy
function XLevelPrototype:Ctor(proxy)
    self._proxy = proxy
end

function XLevelPrototype:Init()
    --self._proxy:RegisterSceneObjectTriggerEvent(1, 1)
    --self._proxy:RegisterSceneObjectTriggerEvent(1, 2)
    --self._proxy:RegisterSceneObjectTriggerEvent(1, 3)

    self._vCamSceneObjPlaceId = 6

end

---@param dt number @ delta time
function XLevelPrototype:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XLevelPrototype:HandleEvent(eventType, eventArgs)
    XLevelPrototype.Super.HandleEvent(self, eventType, eventArgs)
    if eventType == EScriptEvent.SceneObjectTrigger then
        XLog.Debug("XLevelPrototype SceneObjectTriggerEvent:"
            .. " TouchType " .. tostring(eventArgs.TouchType)
            .. " SourceActorId " .. tostring(eventArgs.SourceActorId)
            .. " SceneObjectId " .. tostring(eventArgs.SceneObjectId)
            .. " TriggerId " .. tostring(eventArgs.TriggerId)
            .. " TriggerState " .. tostring(eventArgs.TriggerState)
        )

        if eventArgs.SceneObjectId == self._vCamSceneObjPlaceId then
            if eventArgs.TriggerState == ESceneObjectTriggerState.Enter then
                FuncSet.ActivateVCam(eventArgs.SourceActorId, "MHWCam0", 0, 0, 0,
                        0, 7, -7, 0, 0, 0,
                        0, eventArgs.SourceActorId, 100, false);
            elseif eventArgs.TriggerState == ESceneObjectTriggerState.Exit then
                FuncSet.DeactivateVCam(eventArgs.SourceActorId, "MHWCam0", false);
            end
        end
    end
end

function XLevelPrototype:Terminate()

end

return XLevelPrototype