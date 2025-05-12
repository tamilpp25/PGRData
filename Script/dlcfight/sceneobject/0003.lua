local XSObjPlatform = XDlcScriptManager.RegSceneObjScript(0003, "XSObjPlatform")

-- 设定一系列路径点，平台将围绕路径点循环移动

---@param proxy StatusSyncFight.XFightScriptProxy
function XSObjPlatform:Ctor(proxy)
    self._proxy = proxy

    self._platformTriggerId = 1
    self._carriedNpcDict = {}
    self._carriedNpcCount = 0

    XLog.Debug("--------------------------------1------------------------------------")
end

function XSObjPlatform:Init()
    self._sceneObj = self._proxy:GetSceneObject()
    self._sceneObjPlaceId = self._proxy:GetSceneObjectPlaceId()

    --self._proxy:RegisterSceneObjectTriggerEvent(self._sceneObjPlaceId, self._platformTriggerId)
    --self._proxy:RegisterSceneObjectMoveEvent(self._sceneObjPlaceId, 2)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectTrigger)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectMoveStop)

    --原OnResLoadComplete执行内容
end

---@param dt number @ delta time
function XSObjPlatform:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XSObjPlatform:HandleEvent(eventType, eventArgs)

    if eventType == EWorldEvent.ActorTrigger then
        --print("XSObjElevator SceneObjectTriggerEvent:"
        --.. " TouchType " .. tostring(eventArgs.TouchType)
        --.. " EnteredActorUUID " .. tostring(eventArgs.EnteredActorUUID)
        --.. " HostSceneObjectPlaceId " .. tostring(eventArgs.HostSceneObjectPlaceId)
        --.. " TriggerId " .. tostring(eventArgs.TriggerId)
        --.. " TriggerState " .. tostring(eventArgs.TriggerState)
        --.. " Log自平台" .. tostring(self._sceneObjPlaceId)
        --)
    -- 当平台停止移动，自动执行下一段移动
    elseif eventType == EWorldEvent.SceneObjectMoveStop then
        if eventArgs.SceneObjectId == self._sceneObjPlaceId and eventArgs.MoveState == 2 then
            
        end
    end

end

function XSObjPlatform:Terminate()

end

return XSObjPlatform