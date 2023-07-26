--- 电梯
local XSObjElevator = XDlcScriptManager.RegSceneObjScript(0001, "XSObjElevator")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs


---@param proxy StatusSyncFight.XScriptLuaProxy
function XSObjElevator:Ctor(proxy)
    self._proxy = proxy

    self._platformTriggerId = 1
    self._carriedNpcDict = {}
    self._carriedNpcCount = 0

    self._gearPadEnterTriggerId = 2
    self._gearPadExitTriggerId = 3
    self._gearPadHasReleased = true
    self._gearPadTriggerNpc = 0
    self._gearPadDelayRelease = false
end

function XSObjElevator:Init()
    self._sceneObj = self._proxy:GetSceneObject()
    self._sceneObjPlaceId = self._proxy:GetSceneObjectPlaceId()
    self._proxy:RegisterSceneObjectTriggerEvent(self._sceneObjPlaceId, self._platformTriggerId)
end

function XSObjElevator:InitGearPad()
    local transform = self._sceneObj:GetActorTransform()
    self._gearPad = transform:Find("GearPad")
    if self._gearPad ~= nil and self._gearPad:Exist() then
        self._proxy:RegisterSceneObjectTriggerEvent(self._sceneObjPlaceId, self._gearPadEnterTriggerId)
        self._proxy:RegisterSceneObjectTriggerEvent(self._sceneObjPlaceId, self._gearPadExitTriggerId)
        self._proxy:RegisterSceneObjectMoveEvent(self._sceneObjPlaceId, 2)
        XLog.Debug("register gear pad trigger event")
    else
        XLog.Debug("register gear pad trigger event failed " .. tostring(transform) .. " " .. tostring(self._gearPad))
    end
end

function XSObjElevator:InitSwitchTriggers()
    --[[
       _switchIndexes = new Dictionary<UGearSwitch, int>();
       for (int i = 0; i < Switches.Count; i++)
       {
           var gearSwitch = Switches[i];
           if (gearSwitch == null)
               continue;
           _switchIndexes[gearSwitch] = i;
           gearSwitch.OnTrigger += () => StartMove(_switchIndexes[gearSwitch]);
       }
    ]]
end

---@param dt number @ delta time
function XSObjElevator:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XSObjElevator:HandleEvent(eventType, eventArgs)

    if eventType == EScriptEvent.SceneObjectTrigger then
        XLog.Debug("XSObjElevator SceneObjectTriggerEvent:"
        .. " TouchType " .. tostring(eventArgs.TouchType)
        .. " SourceActorId " .. tostring(eventArgs.SourceActorId)
        .. " SceneObjectId " .. tostring(eventArgs.SceneObjectId)
        .. " TriggerId " .. tostring(eventArgs.TriggerId)
        .. " TriggerState " .. tostring(eventArgs.TriggerState)
        .. " Log自电梯"
        )

        if eventArgs.SceneObjectId == self._sceneObjPlaceId and eventArgs.TriggerId == self._platformTriggerId then
            if eventArgs.TriggerState == ESceneObjectTriggerState.Enter then
                self._carriedNpcDict[eventArgs.SourceActorId] = true
                self._carriedNpcCount = self._carriedNpcCount + 1
            elseif eventArgs.TriggerState == ESceneObjectTriggerState.Exit then
                self._carriedNpcDict[eventArgs.SourceActorId] = nil
                self._carriedNpcCount = self._carriedNpcCount - 1
            end
        elseif eventArgs.SceneObjectId == self._sceneObjPlaceId and eventArgs.TriggerId == self._gearPadEnterTriggerId then
            if eventArgs.TriggerState == ESceneObjectTriggerState.Enter then
                if self._carriedNpcDict[eventArgs.SourceActorId] and self._gearPadHasReleased then
                    self._gearPadTriggerNpc = eventArgs.SourceActorId
                    self:_GearPadPress()
                    self._sceneObj.MoveComponent:MoveToNode()
                end
            end
        elseif eventArgs.SceneObjectId == self._sceneObjPlaceId and eventArgs.TriggerId == self._gearPadExitTriggerId then
            if eventArgs.TriggerState == ESceneObjectTriggerState.Exit then
                if self._gearPadTriggerNpc > 0 then
                    self._gearPadTriggerNpc = 0
                    if self._gearPadDelayRelease then -- 踏板延迟释放（到站后角色仍然踩在上面，未及时释放
                        self:_GearPadReleaseInternal()
                        self._gearPadDelayRelease = false
                    end
                end
            end
        end
    elseif eventType == EScriptEvent.SceneObjectMoveStop then
        -- 踏板释放 踏板作为电梯prefab的一部分 正式版通过播动画来代替
        if eventArgs.SceneObjectId == self._sceneObjPlaceId and eventArgs.MoveState == 2 and not self._gearPadHasReleased then
            self:_GearPadRelease()
        end
    end

end

function XSObjElevator:OnResLoadComplete()
    self:InitGearPad()
end

function XSObjElevator:_GearPadPress()
    local position = self._gearPad.position
    position.y = position.y - self._gearPad.lossyScale.y
    self._gearPad.position = position
    self._gearPadHasReleased = false
    XLog.Debug("Press gear pad")
end

function XSObjElevator:_GearPadRelease()
    if self._gearPadTriggerNpc > 0 then
        self._gearPadDelayRelease = true
        XLog.Debug("Delay release gear pad")
        return
    end

    self:_GearPadReleaseInternal()
end

function XSObjElevator:_GearPadReleaseInternal()
    local position = self._gearPad.position
    position.y = position.y + self._gearPad.lossyScale.y
    self._gearPad.position = position
    self._gearPadHasReleased = true
    XLog.Debug("Release gear pad")
end

function XSObjElevator:Terminate()

end

return XSObjElevator