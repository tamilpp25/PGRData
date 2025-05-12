local XLevelScript4001 = XDlcScriptManager.RegLevelLogicScript(4001, "XLevel4001") --注册脚本类到管理器（逻辑脚本注册
local float3 = CS.Mathematics.float3

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevelScript4001:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy               --脚本代理对象，通过它来调用战斗程序开放的函数接口。
    self._streetMall2F_ElevatorCallerPlaceId = 100066
    self._streetMall3F_ElevatorCallerPlaceId = 100067
    self._streetMall1F_ElevatorCallerPlaceId = 100068
    self._streetMall4F_ElevatorCallerPlaceId = 100123
    self._streetMall2F_ElevatorPortSpotId = 100002
    self._streetMall3F_ElevatorPortSpotId = 100001
    self._streetMall1F_ElevatorPortSpotId = 100014
    self._streetMall4F_ElevatorPortSpotId = 100015
    self._streetCE_ElevatorPortSpotId = 100010
    self._tempLevelSwitcherPlaceId = 100011
    self._CoffeeNpcUUID = 100093
    self._WeComeBackID = 100010
    self._assistMachineId = 6030               --辅助机npc单位表Id
    self._deathZoneId = 100009                 --死区的triggerID
    self._reviveRotation = { 0, 0, 0 }         --复活时的旋转
    self._transportNPCPlazaId = 100020

    self._cafeObj = 100076
end

function XLevelScript4001:Init() --初始化逻辑
    self._streetMall2F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall2F_ElevatorCallerPlaceId)
    self._streetMall3F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall3F_ElevatorCallerPlaceId)
    self._streetMall1F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall1F_ElevatorCallerPlaceId)
    self._streetMall4F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall4F_ElevatorCallerPlaceId)
    self._streetMall3F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall3F_ElevatorPortSpotId)
    self._streetMall2F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall2F_ElevatorPortSpotId)
    self._streetMall1F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall1F_ElevatorPortSpotId)
    self._streetMall4F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall4F_ElevatorPortSpotId)
    self._tempLevelSwitcherUUID = self._proxy:GetSceneObjectUUID(self._tempLevelSwitcherPlaceId)
    self._tempLevelSwitcherBackUUID = self._proxy:GetSceneObjectUUID(self._WeComeBackID)
    self._questNpcUUID = self._proxy:GetNpcUUID(self._CoffeeNpcUUID)
    self._PlazaLevelSwitchUUID = self._proxy:GetNpcUUID(self._transportNPCPlazaId)         --传送去商业街玩法

    self._cafeObjSwitchUUID = self._proxy:GetSceneObjectUUID(self._cafeObj)                        --切换去咖啡厅玩法
    local playerNpcUUID = self._proxy:GetLocalPlayerNpcId()                        --获取玩家npc
    self._kuroroUUID = self._proxy:GetAssistNpcUUID()
    self._revivePoint = self._proxy:GetSpot(100003)                                --复活点坐标
    -- local kuroroScript = self._proxy:GetActorScriptObject(EScriptType.Npc, self._kuroroUUID, 6004) ---@type XCharKuroro  --npc脚本6004
    -- local commanderScript = self._proxy:GetActorScriptObject(EScriptType.Npc, playerNpcUUID, 3005) ---@type XCharCommanderChief --npc脚本3005
    -- commanderScript:SetKuroroScript(kuroroScript)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.DramaFinish)
    local interactableGearPlaceId = 100005                                                                         --交互物体PlaceID
    local gearUUID = self._proxy:GetSceneObjectUUID(interactableGearPlaceId)                                       --交互物体ID
    local success = self._proxy:SetActorInteractionReactCallback(gearUUID, function(launcherUUID, optionId, phase) --
        if phase == EInteractPhase.Complete then
            self._proxy:DoSceneObjectAction(interactableGearPlaceId, 2205)
            XLog.Error("临时交互机关，自定义交互响应完成")
        end
    end)
    --XLog.Error("设置临时机关交互响应回调：" .. tostring(success))
end

---@param dt number @ delta time
function XLevelScript4001:Update(dt) --每帧更新逻辑
    self:OnUpdatePhase(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript4001:HandleEvent(eventType, eventArgs) --事件响应逻辑
    self:HandlePhaseEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) then --是玩家发起的交互
            if eventArgs.TargetId == self._streetMall2F_ElevatorCallerUUID then
                --传送到露天广场
                XScriptTool.DoTeleportNpcPosWithBlackScreen(self._proxy, eventArgs.LauncherId, self._streetMall3F_ElevatorPortPos, 0.5, 0.5)
            elseif eventArgs.TargetId == self._streetMall3F_ElevatorCallerUUID then
                --传送到时序广场
                XScriptTool.DoTeleportNpcPosWithBlackScreen(self._proxy, eventArgs.LauncherId, self._streetMall2F_ElevatorPortPos, 0.5, 0.5)
            elseif eventArgs.TargetId == self._streetMall1F_ElevatorCallerUUID then
                --从商业街传送回时序广场
                XScriptTool.DoTeleportNpcPosWithBlackScreen(self._proxy, eventArgs.LauncherId, self._streetMall1F_ElevatorPortPos, 0.5, 0.5)
            elseif eventArgs.TargetId == self._streetMall4F_ElevatorCallerUUID then
                --从时序广场传送到商业街
                XScriptTool.DoTeleportNpcPosWithBlackScreen(self._proxy, eventArgs.LauncherId, self._streetMall4F_ElevatorPortPos, 0.5, 0.5)
            elseif eventArgs.TargetId == self._tempLevelSwitcherUUID then
                local pos = { x = 555.8912, y = 169.6177, z = 1175.655 }
                self._proxy:SwitchLevel(4002, pos)
            elseif eventArgs.TargetId == self._tempLevelSwitcherBackUUID then
                local pos = { x = 11.925, y = 1.646, z = 13.30518 }
                self._proxy:SwitchLevel(4003, pos)
            elseif eventArgs.TargetId == self._PlazaLevelSwitchUUID and not self._proxy:IsActorInQuest(self._PlazaLevelSwitchUUID) then
                -- local pos = { x = 597, y = 189, z = 1139 }
                -- self._proxy:SwitchLevel(4005, pos)
                self._proxy:OpenGameplayMainEntrance(2, { 597, 189, 1139 })
            elseif eventArgs.TargetId == self._cafeObjSwitchUUID then
                self._proxy:OpenGameplayMainEntrance(1, { 555.03, 169.44, 1174.21 })
            end
        end
    elseif eventType == EWorldEvent.ActorTrigger then
        --XLog.Error("有npc触发器触发")
        if (eventArgs.HostSceneObjectPlaceId == self._deathZoneId and eventArgs.TriggerState == ETriggerState.Enter) then
            self._proxy:SetNpcPosAndRot(eventArgs.EnteredActorUUID, self._revivePoint,
                self._reviveRotation, true)
        end
    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "CE0.2_Play01" then                               --跳跳乐对话跳转
            local dramaOptions = self._proxy:GetDramaDialogSelectedOptionIndex(1, 1)
            if dramaOptions == 1 then --选择了对话选项1
                self._proxy:SwitchInstanceLevel(4008, { x = 490.45, y = 148.55, z = 1334.78 })
            elseif dramaOptions == 2 then --选择了对话选项2
                self._proxy:SwitchInstanceLevel(4009, { x = 409.41, y = 108.19, z = 993.03 })
            elseif dramaOptions == 3 then --选择了对话选项3
                self._proxy:SwitchInstanceLevel(4010, { x = 172, y = 87, z = 1087 })
            end
        end
    end
end

function XLevelScript4001:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

function XLevelScript4001:InitPhase() --初始化关卡各个阶段的相关变量
    self._currentPhase = 0
    self._lastPhase = 0
end

function XLevelScript4001:SetPhase(phase) --跳转关卡阶段
    if phase == self._currentPhase then
        return
    end

    self:OnExitPhase(self._currentPhase)
    self:OnEnterPhase(phase)
    self:OnPhaseChanged(self._currentPhase, self.phase)

    self._lastPhase = self._currentPhase
    self._currentPhase = phase
end

function XLevelScript4001:OnEnterPhase(phase) --进入一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
end

---@param dt number @ delta time
function XLevelScript4001:OnUpdatePhase(dt) --当前关卡阶段需要一直执行的逻辑在这里实现（一般在这里跳转关卡阶段
end

function XLevelScript4001:OnExitPhase(phase) --退出一个关卡阶段时需要做的事情在这里实现（最好不要在这里跳转关卡阶段
end

function XLevelScript4001:OnPhaseChanged(lastPhase, nextPhase)
    --关卡阶段改变时需要执行的逻辑，一般用于通知外部
end

function XLevelScript4001:HandlePhaseEvent(eventType, eventArgs) --处理阶段相关的事件响应，一般在这里跳转关卡阶段
end

return XLevelScript4001
