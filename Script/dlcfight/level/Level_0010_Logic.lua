--- original prototype level
local XLevel0010 = XDlcScriptManager.RegLevelLogicScript(0010, "XLevel0010")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevel0010:Ctor(proxy)
    self._proxy = proxy
end

function XLevel0010:Init()
    --self._proxy:RegisterSceneObjectTriggerEvent(1, 1)
    --self._proxy:RegisterSceneObjectTriggerEvent(1, 2)
    --self._proxy:RegisterSceneObjectTriggerEvent(1, 3)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectTrigger)

    self._vCamSceneObjPlaceId = 6

end

---@param dt number @ delta time
function XLevel0010:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XLevel0010:HandleEvent(eventType, eventArgs)
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

function XLevel0010:Terminate()

end

return XLevel0010