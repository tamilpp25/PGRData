---万用关卡测试关
local XLevelPrototype = XDlcScriptManager.RegLevelLogicScript(8000, "XLevelPrototype1")

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelPrototype:Ctor(proxy)
    self._proxy = proxy

    --- 手动开关的虚拟相机的参数
    self._vCamSceneObjPlaceId = 6
    self.VCamActive = false
    self.VCamAimSceneObjectActive = false
end

function XLevelPrototype:Init()
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkill)
    self._proxy:RegisterEvent(EWorldEvent.NpcExitSkill)

    XLog.Debug("------------Level 11 start set npc ids for SceneObj 25")
    self._localPlayerNpcId = self._proxy:GetLocalPlayerNpcId()

    -- 注册虚拟相机属性
    local testVCamAgent = self._proxy:GetActorScriptObject(EScriptType.SceneObject, 25, 0006) ---@type XSObjVCamAgent
    testVCamAgent:SetCallBackBeforeActivated(function()
        testVCamAgent:SetActorIds(0, -1, -1)
        testVCamAgent:SetCallBackBeforeActivated(nil)
    end)
end

---@param dt number @ delta time
function XLevelPrototype:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XLevelPrototype:HandleEvent(eventType, eventArgs)
    XLevelPrototype.Super.HandleEvent(self, eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger then
        --XLog.Debug("XLevelPrototype SceneObjectTriggerEvent:"
        --    .. " TouchType " .. tostring(eventArgs.TouchType)
        --    .. " EnteredActorUUID " .. tostring(eventArgs.EnteredActorUUID)
        --    .. " HostSceneObjectPlaceId " .. tostring(eventArgs.HostSceneObjectPlaceId)
        --    .. " TriggerId " .. tostring(eventArgs.TriggerId)
        --    .. " TriggerState " .. tostring(eventArgs.TriggerState)
        --    .. " Log自关卡"
        --)

        if eventArgs.HostSceneObjectPlaceId == self._vCamSceneObjPlaceId then
            if eventArgs.TriggerState == ETriggerState.Enter then
                self._proxy:ActivateVCam(eventArgs.EnteredActorUUID, "MHWCam0", 0, 0, 0,
                        0, 7, -7, 0, 0, 0,
                        0, eventArgs.EnteredActorUUID, 100, false);
            elseif eventArgs.TriggerState == ETriggerState.Exit then
                self._proxy:DeactivateVCam(eventArgs.EnteredActorUUID, "MHWCam0", false);
            end
        end

    end
end

function XLevelPrototype:SwitchVCam()
    if self.VCamActive then
        self._proxy:DeactivateVCam(self._localPlayerNpcId,"TPSmode",true)
    else
        self._proxy:ActivateVCam(self._localPlayerNpcId,"TPSmode",1,1,0,0,0,0,0,0,0,self._localPlayerNpcId,self._localPlayerNpcId,100,true)
    end
    self.VCamActive = not self.VCamActive
end

function XLevelPrototype:SwitchVCamAimSceneObject()
    local uuid = self._proxy:GetSceneObjectUUID(19)
    if self.VCamAimSceneObjectActive then
        self._proxy:DeactivateVCam(self._localPlayerNpcId,"TPSmode",true)
    else
        self._proxy:ActivateVCam(self._localPlayerNpcId,"TPSmode",1,1,0,0,0,0,0,0,0,self._localPlayerNpcId,uuid,100,true)
    end
    self.VCamAimSceneObjectActive = not self.VCamAimSceneObjectActive
end

function XLevelPrototype:Terminate()

end

return XLevelPrototype