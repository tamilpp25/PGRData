---万用关卡测试关
local XLevelPrototype = XDlcScriptManager.RegLevelLogicScript(8000, "XLevelPrototype1")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs
local Tool = require("Level/Common/XLevelTools")

local _cameraResRefTable = {
    "MHWCam1",
    "MHWCam0",
    "TPSmode",
}

function XLevelPrototype.GetCameraResRefTable()
    return _cameraResRefTable
end

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelPrototype:Ctor(proxy)
    self._proxy = proxy

    --- 传送点配置
    self._playerInTeleport = false
    self._teleports = {
        [100] = true,
        [101] = true,
        [102] = true,
    } -- 用index来储存传送点id信息，就能用id来查询，免得写contain方法
    self._inputBtnList = {}

    --- 死区测试trigger
    self._deathZonePlaceId = 1022
    self._resetToCheckPointZonePlaceId = 1023

    --- 开关
    self.switches = {
        {
            --- 出生点附近的开关，测试虚拟相机的开关
            placeId = 20,
            agent = nil,
            object = self,
            func = self.SwitchVCam,
            param = nil,
            triggerTimes = -1,
        },
        {
            --- 出生点附近的开关，测试虚拟相机瞄准场景物体
            placeId = 28,
            agent = nil,
            object = self,
            func = self.SwitchVCamAimSceneObject,
            param = nil,
            triggerTimes = -1,
        },
    }

    --- 手动开关的虚拟相机的参数
    self.VCamActive = false
    self.VCamAimSceneObjectActive = false
end

function XLevelPrototype:Init()
    self._proxy:RegisterSceneObjectTriggerEvent(1, 1)
    self._vCamSceneObjPlaceId = 6

    XLog.Debug("------------Level 11 start set npc ids for SceneObj 25")
    self._localPlayerNpcId = FuncSet.GetLocalPlayerNpcId()

    -- 注册虚拟相机属性
    local testVCamAgent = XDlcScriptManager.GetSceneObjectScript(25) ---@type XSObjVCamAgent
    testVCamAgent:SetCallBackBeforeActivated(function()
        testVCamAgent:SetActorIds(0, -1, -1)
        testVCamAgent:SetCallBackBeforeActivated(nil)
    end)

    self._proxy:RegisterNpcEvent(EScriptEvent.NpcCastSkill, self._localPlayerNpcId)
    self._proxy:RegisterNpcEvent(EScriptEvent.NpcExitSkill, self._localPlayerNpcId)

    for key, _ in pairs(self._teleports) do
        self._proxy:RegisterSceneObjectTriggerEvent(key, 1) --注册传送门事件
    end

    self._proxy:RegisterSceneObjectTriggerEvent(self._deathZonePlaceId, 1) -- 注册死区试验场的死区
    self._proxy:RegisterSceneObjectTriggerEvent(self._resetToCheckPointZonePlaceId, 1) -- 注册死区试验场的死区

    self._switches = Tool.InitSwitch(self.switches) --配置开关
end

---@param dt number @ delta time
function XLevelPrototype:Update(dt)
    self:TeleportCheck()
end

---@param eventType number
---@param eventArgs userdata
function XLevelPrototype:HandleEvent(eventType, eventArgs)
    XLevelPrototype.Super.HandleEvent(self, eventType, eventArgs)
    if eventType == EScriptEvent.SceneObjectTrigger then
        --XLog.Debug("XLevelPrototype SceneObjectTriggerEvent:"
        --    .. " TouchType " .. tostring(eventArgs.TouchType)
        --    .. " SourceActorId " .. tostring(eventArgs.SourceActorId)
        --    .. " SceneObjectId " .. tostring(eventArgs.SceneObjectId)
        --    .. " TriggerId " .. tostring(eventArgs.TriggerId)
        --    .. " TriggerState " .. tostring(eventArgs.TriggerState)
        --    .. " Log自关卡"
        --)

        if eventArgs.SceneObjectId == self._vCamSceneObjPlaceId then
            if eventArgs.TriggerState == ESceneObjectTriggerState.Enter then
                FuncSet.ActivateVCam(eventArgs.SourceActorId, "MHWCam0", 0, 0, 0,
                        0, 7, -7, 0, 0, 0,
                        0, eventArgs.SourceActorId, 100, false);
            elseif eventArgs.TriggerState == ESceneObjectTriggerState.Exit then
                FuncSet.DeactivateVCam(eventArgs.SourceActorId, "MHWCam0", false);
            end
        elseif self._teleports[eventArgs.SceneObjectId] then
            -- 触发传送门
            if eventArgs.TriggerState == ESceneObjectTriggerState.Enter then
                self._playerInTeleport = true
            else
                self._playerInTeleport = false
            end

        end
        -- 死区重生
        if eventArgs.SceneObjectId == self._deathZonePlaceId and FuncSet.IsPlayerNpc(eventArgs.SourceActorId) then
            FuncSet.ResetNpcToSafePoint(eventArgs.SourceActorId)
        end
        -- 重生到检查点
        if eventArgs.SceneObjectId == self._resetToCheckPointZonePlaceId and FuncSet.IsPlayerNpc(eventArgs.SourceActorId) then
            FuncSet.ResetNpcToCheckPoint(eventArgs.SourceActorId)
            XLog.Debug(11111111111111111)
        end

    elseif eventType == EScriptEvent.NpcCastSkill then
        XLog.Debug(string.format("Level listen npc:%d cast skill:%d to target:%d", eventArgs.LauncherId, eventArgs.SkillId, eventArgs.TargetId))
    elseif eventType == EScriptEvent.NpcExitSkill then
        XLog.Debug(string.format("Level listen npc:%d exit skill:%d to target:%d", eventArgs.LauncherId, eventArgs.SkillId, eventArgs.TargetId))
    end
end

function XLevelPrototype:TeleportCheck()
    if self._playerInTeleport then
        if FuncSet.IsKeyDown(ENpcOperationKey.Ball1) then
            table.insert(self._inputBtnList, 1)
            XLog.Debug("Input Password 1")
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball2) then
            table.insert(self._inputBtnList, 2)
            XLog.Debug("Input Password 2")
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball3) then
            table.insert(self._inputBtnList, 3)
            XLog.Debug("Input Password 3")
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball4) then
            table.insert(self._inputBtnList, 4)
            XLog.Debug("Input Password 4")
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball5) then
            table.insert(self._inputBtnList, 5)
            XLog.Debug("Input Password 5")
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball6) then
            table.insert(self._inputBtnList, 6)
            XLog.Debug("Input Password 6")
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball7) then
            table.insert(self._inputBtnList, 7)
            XLog.Debug("Input Password 7")
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball8) then
            table.insert(self._inputBtnList, 8)
            XLog.Debug("Input Password 8")
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball9) then
            table.insert(self._inputBtnList, 9)
            XLog.Debug("Input Password 9")
        elseif FuncSet.IsKeyDown(ENpcOperationKey.Ball10) then
            table.insert(self._inputBtnList, 0)
            XLog.Debug("Input Password 0")
        end

        if FuncSet.IsKeyDown(ENpcOperationKey.Attack) then
            self:PasswordCheck()
        end
    end
end

---检查输入的密码,传送到对应的传送点
function XLevelPrototype:PasswordCheck()
    local result = tonumber(table.concat(self._inputBtnList))
    XLog.Debug(result)
    self._inputBtnList = {}
    if self._teleports[result] then
        local resultPosition = FuncSet.GetSceneObjectPosition(result)
        FuncSet.SetNpcPosition(self._localPlayerNpcId, resultPosition)
    end
end

function XLevelPrototype:SwitchVCam()
    if self.VCamActive then
        FuncSet.DeactivateVCam(self._localPlayerNpcId,"TPSmode",true)
    else
        FuncSet.ActivateVCam(self._localPlayerNpcId,"TPSmode",1,1,0,0,0,0,0,0,0,self._localPlayerNpcId,self._localPlayerNpcId,100,true)
    end
    self.VCamActive = not self.VCamActive
end

function XLevelPrototype:SwitchVCamAimSceneObject()
    local uuid = FuncSet.GetSceneObjectUUID(19)
    if self.VCamAimSceneObjectActive then
        FuncSet.DeactivateVCam(self._localPlayerNpcId,"TPSmode",true)
    else
        FuncSet.ActivateVCam(self._localPlayerNpcId,"TPSmode",1,1,0,0,0,0,0,0,0,self._localPlayerNpcId,uuid,100,true)
    end
    self.VCamAimSceneObjectActive = not self.VCamAimSceneObjectActive
end

function XLevelPrototype:Terminate()

end

return XLevelPrototype