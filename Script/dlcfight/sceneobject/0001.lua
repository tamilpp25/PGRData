--- 电梯
local XSObjElevator = XDlcScriptManager.RegSceneObjScript(0001, "XSObjElevator")

---@param proxy StatusSyncFight.XFightScriptProxy
function XSObjElevator:Ctor(proxy)
    self._proxy = proxy

    self._platformTriggerId = 1
    self._carriedNpcDict = {}
    self._carriedNpcCount = 0

    self._buttonPressTriggerId = 2
    self._buttonReleaseTriggerId = 3
    self._buttonHasReleased = true
    self._buttonTriggerNpc = 0
    self._buttonDelayRelease = false

    self._buttonState = 1 --1-抬起，2-按下
end

function XSObjElevator:Init()
    self._sceneObjPlaceId = self._proxy:GetSceneObjectPlaceId()

    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectMoveStop)
    XLog.Debug("Register events for elevator")
end

---@param dt number @ delta time
function XSObjElevator:Update(dt)
    --临时按键控制逻辑（debug用
    if self._proxy:IsKeyDown(ENpcOperationKey.Ball12) then
        self:StartMove()
    end
end

---@param eventType number
---@param eventArgs userdata
function XSObjElevator:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger then
        --XLog.Debug("XSObjElevator SceneObjectTriggerEvent:"
        --.. " TouchType " .. tostring(eventArgs.TouchType)
        --.. " EnteredActorUUID " .. tostring(eventArgs.EnteredActorUUID)
        --.. " HostSceneObjectPlaceId " .. tostring(eventArgs.HostSceneObjectPlaceId)
        --.. " TriggerId " .. tostring(eventArgs.TriggerId)
        --.. " TriggerState " .. tostring(eventArgs.TriggerState)
        --.. " Log自电梯"
        --)

        if eventArgs.HostSceneObjectPlaceId == self._sceneObjPlaceId and eventArgs.TriggerId == self._platformTriggerId then
            if eventArgs.TriggerState == ETriggerState.Enter then
                self._carriedNpcDict[eventArgs.EnteredActorUUID] = true
                self._carriedNpcCount = self._carriedNpcCount + 1
            elseif eventArgs.TriggerState == ETriggerState.Exit then
                self._carriedNpcDict[eventArgs.EnteredActorUUID] = nil
                self._carriedNpcCount = self._carriedNpcCount - 1
            end
        elseif eventArgs.HostSceneObjectPlaceId == self._sceneObjPlaceId and eventArgs.TriggerId == self._buttonPressTriggerId then
            if eventArgs.TriggerState == ETriggerState.Enter then
                if self._carriedNpcDict[eventArgs.EnteredActorUUID] and self._buttonHasReleased then
                    self._buttonTriggerNpc = eventArgs.EnteredActorUUID
                    self:StartMove()
                end
            end
        elseif eventArgs.HostSceneObjectPlaceId == self._sceneObjPlaceId and eventArgs.TriggerId == self._buttonReleaseTriggerId then
            if eventArgs.TriggerState == ETriggerState.Exit then
                if self._buttonTriggerNpc > 0 then
                    self._buttonTriggerNpc = 0
                    if self._buttonDelayRelease then -- 踏板延迟弹起（平台移动到点停止后角色仍然踩在上面，未及时弹起
                        self:_ReleaseButtonInternal()
                        self._buttonDelayRelease = false
                    end
                end
            end
        end
    elseif eventType == EWorldEvent.SceneObjectMoveStop then
        -- 踏板弹起 踏板作为电梯prefab的一部分 正式版通过播动画来代替
        if eventArgs.SceneObjectId == self._sceneObjPlaceId and eventArgs.MoveState == 2 and not self._buttonHasReleased then
            self:_ReleaseButton()
        end
    end

end

function XSObjElevator:Terminate()
    self._proxy:UnregisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:UnregisterEvent(EWorldEvent.SceneObjectMoveStop)
end

function XSObjElevator:StartMove()
    self:_PressButton()
    self._proxy:MoveSceneObjectToNode(self._sceneObjPlaceId, 0)
end

function XSObjElevator:_PressButton()
    self._buttonHasReleased = false
    --self._proxy:DoSceneObjectAction(self._sceneObjPlaceId, 1) --call to play animation
    XLog.Debug("Elevator button was pressed.")
end

function XSObjElevator:_ReleaseButton()
    if self._buttonTriggerNpc > 0 then
        self._buttonDelayRelease = true
        XLog.Debug("Delay release elevator button")
        return
    end

    self:_ReleaseButtonInternal()
end

function XSObjElevator:_ReleaseButtonInternal()
    --self._proxy:DoSceneObjectAction(self._sceneObjPlaceId, 2) --call to play animation
    self._buttonHasReleased = true
    XLog.Debug("Release elevator button")
end

return XSObjElevator