local base = require("Common/XQuestBase")
---@class XQuestScript1001 : XQuestBase
local XQuestScript1001 = XDlcScriptManager.RegQuestStepScript(1001, "XQuestScript1001", base)

---@param proxy StatusSyncFight.XFightScriptProxy
function XQuestScript1001:Ctor(proxy)
    self._id = 1001
    self._questNpcTemplateId = 101037
    self._commonSceneObjectBaseId = 1 --通用空物件BaseId

    self._questNpcPlaceId = 100002
    
    self._playerNpcUUID = 0
    self._questNpcUUID = 0
    self._item1UUID = 0
    self._item2UUID = 0
    self._triggerSceneObjectUUID = 0
    
    self._step2triggerPos = { x = 542.1, y = 143.7, z = 1367.6}
    self._step3Item1PlaceId = 400001
    self._step3Item2PlaceId = 400002

    self._triggerRot = { x = 0, y = 0, z = 0}
    self._questNpcRot = { x = 0, y = 180, z = 0}
    self._dramaRot = { x = 0, y = 0, z = 0}

    self._foundItemCount = 0

    self._step4ElevatorGearUUID = 0
    self._step5ElevatorGearUUID = 0

    self._questLevelId = 4001
end

function XQuestScript1001:Init()
    if self._proxy:GetCurrentLevelId() ~= self._questLevelId then
        XLog.Error(string.format("Dlc Quest 1001 requires Level %d !", self._questLevelId))
        return
    end

    self._proxy:RegisterEvent(EWorldEvent.DramaFinish)
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.QuestItemsDeliveryConfirm)
    self._proxy:RegisterEvent(EWorldEvent.EnterLevel)
    self._playerNpcUUID = self._proxy:GetLocalPlayerNpcId()
    self._questNpcUUID = self._proxy:GetNpcUUID(self._questNpcPlaceId)

    self._streetMall3F_ElevatorPortPos = self._proxy:GetSpot(100001)
    self._streetMall2F_ElevatorPortPos = self._proxy:GetSpot(100002)
end

function XQuestScript1001:Terminate()
end

--===================[[ 任务步骤]]
--========================[[ 步骤1]]=============================>>
---@param self XQuestScript1001
XQuestScript1001.StepEnterFuncs[10011] = function(self)
    self._proxy:SetNpcSelectDialogOptionShowList(self._questNpcUUID, 1, {1})
    self._proxy:SetNpcQuestTipIconActive(self._questNpcUUID, self._id, true)
    self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpcPlaceId, 0, false, true)
    --self._proxy:AddQuestNavPoint()
end

---@param self XQuestScript1001
XQuestScript1001.StepHandleEventFuncs[10011] = function(self, eventType, eventArgs)
    --if eventType == EWorldEvent.NpcInteractStart then
    --    if eventArgs.LauncherId == self._playerNpcUUID and eventArgs.TargetId == self._questNpcUUID and eventArgs.Type == 1 then
    --        local pos = (self._proxy:GetNpcPosition(self._playerNpcUUID) + self._proxy:GetNpcPosition(self._questNpcUUID)) / 2
    --        local rot = self._proxy:GetNpcRotation(self._playerNpcUUID)
    --        self._proxy:PlayDrama(self._id, { self._questNpcUUID }, "StoryLine001", pos, rot) --接任务剧情，NPC有东西丢了
    --    end
    if eventType == EWorldEvent.DramaFinish then
        --有剧情播放完成
        local dialogOption = self._proxy:GetDramaDialogSelectedOptionIndex(1, 4)
        if eventArgs.DramaName == "StoryLine001" and dialogOption == 1 then --选择了对话选项1
            self._proxy:PushQuestStepProcess(self._id, 10011, 100111, 1)--推进任务1001中的步骤1中的进度1
            self._proxy:SetNpcQuestTipIconActive(self._questNpcUUID, self._id, false)
        end
    end
end

---@param self XQuestScript1001
XQuestScript1001.StepExitFuncs[10011] = function(self)
    self._proxy:SetActorInQuest(self._id , self._questNpcUUID, true)
    self._proxy:SetNpcSelectDialogOptionShowList(self._questNpcUUID, 1, nil)
end
--==============================================================<<
--========================[[ 步骤2]]=============================<<
---@param self XQuestScript1001
XQuestScript1001.StepEnterFuncs[10012] = function(self)
    self._triggerSceneObjectUUID = self._proxy:CreateSceneObject(self._commonSceneObjectBaseId, self._step2triggerPos, self._triggerRot)
    self._proxy:CreateActorTrigger(self._triggerSceneObjectUUID, ETriggerTouchType.NpcCollider,
        EShapeType.Box, "Q1001-S2", nil, nil,
        {x = 2.4, y = 2, z = 2.4}, 0, 0, 0)
    self._step2NavPointId = self._proxy:AddQuestNavPointForActor(self._questLevelId, self._id, 1, self._triggerSceneObjectUUID)
    self._proxy:RegisterEvent(EWorldEvent.QuestPopupClosed)
end

---@param self XQuestScript1001
XQuestScript1001.StepHandleEventFuncs[10012] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger then
        if eventArgs.TriggerHolderUUID == self._triggerSceneObjectUUID and eventArgs.EnteredActorUUID == self._playerNpcUUID then
            --local pos = self._proxy:GetNpcPosition(self._playerNpcUUID)
            --self._proxy:PlayDrama(self._id, nil, "XunZhaoDiuShi_1", pos, self._dramaRot) --到达寻找地点剧情
            self._proxy:DestroySceneObject(self._triggerSceneObjectUUID)
            self._proxy:RemoveQuestNavPoint(self._id, self._step2NavPointId)
            self._proxy:PushQuestStepProcess(self._id,10012,100121,1)--推进任务1001中的步骤2中的进度2
        end
    elseif eventType == EWorldEvent.QuestPopupClosed then
        if eventArgs.QuestId == self._id and eventArgs.PopupType == EQuestPopupType.Undertake then
            local pos = self._proxy:GetNpcPosition(self._playerNpcUUID)
            --指挥官内心独白（这里就是广场了，在附近找找吧
            self._proxy:PlayDrama(self._id, nil,"StoryLine002", pos, self._dramaRot)
        end
    end
end

---@param self XQuestScript1001
XQuestScript1001.StepExitFuncs[10012] = function(self)
    self._proxy:UnregisterEvent(EWorldEvent.QuestPopupClosed)
end

--==============================================================>>
--========================[[ 步骤3]]=============================<<
---@param self XQuestScript1001
XQuestScript1001.StepEnterFuncs[10013] = function(self)
    if self._proxy:GetCurrentLevelId() == 4001 then
        --之所以检查process是否完成，是因为玩家有可能只完成了部分process然后下线了，之后重新上线就不能再让玩家重复做已经完成的process
        if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10013, 100131) then
            self._proxy:LoadSceneObject(self._step3Item1PlaceId)
            self._item1UUID = self._proxy:GetSceneObjectUUID(self._step3Item1PlaceId)--物件1
            self._proxy:SetActorInQuest(self._id, self._item1UUID, true)
            self._step3Item1NavPointId = self._proxy:AddQuestNavPointForActor(self._questLevelId, self._id, 1, self._item1UUID)
        end

        if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10013, 100132) then
            self._proxy:LoadSceneObject(self._step3Item2PlaceId)
            self._item2UUID = self._proxy:GetSceneObjectUUID(self._step3Item2PlaceId)--物件2
            self._proxy:SetActorInQuest(self._id, self._item2UUID, true)
            self._step3Item2NavPointId = self._proxy:AddQuestNavPointForActor(self._questLevelId, self._id, 1, self._item2UUID)
        end
    end

    --初次进入该任务步骤时，先看是否在关卡4002中，是的话，就直接创建我们的动态actor，在添加导航点时把它填进去，
    --否则就只给一个为0的UUID，先添加一个暂时没有导航对象的导航点，等到后续进入关卡再给它设置导航对象
    local targetUUID = 0
    if self._proxy:GetCurrentLevelId() == 4002 then
        self._level4002TempNpc = self._proxy:GenerateLevelNpc(101001, ENpcCampType.Camp3, {x = 10, y = 1.2, z = 10}, {0})
        targetUUID = self._level4002TempNpc
    end
    self._level4002TempNpcNavPointId = self._proxy:AddQuestNavPointForActor(4002, self._id, 1, targetUUID)

    self._proxy:AddQuestNavPointForLevelNpc(4002, self._id, 1, 1)
    self._proxy:AddQuestNavPointForLevelSceneObject(4002, self._id, 1, 1)
end

---@param self XQuestScript1001
XQuestScript1001.StepHandleEventFuncs[10013] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        local foundItemCountChanged = false
        if eventArgs.LauncherId == self._playerNpcUUID and eventArgs.TargetId == self._item1UUID and eventArgs.Type == 1 then
            self._foundItemCount = self._foundItemCount + 1
            foundItemCountChanged = true

            self._proxy:DestroySceneObject(self._item1UUID)
            self._proxy:RemoveQuestNavPoint(self._id, self._step3Item1NavPointId)
            self._proxy:PushQuestStepProcess(self._id, 10013, 100131, 1)
            self._proxy:PushQuestStepProcess(self._id, 10013, 100133, 1)

            --local pos = self._proxy:GetSceneObjectPosition(self._item1UUID)
            --local rot = self._proxy:GetSceneObjectRotation(self._item1UUID)
            --rot.y = rot.y * -1
            --self._proxy:PlayDrama(self._id, nil, "StoryTest02", pos, rot)--找到物品1的剧情
        end
        if eventArgs.LauncherId == self._playerNpcUUID and eventArgs.TargetId == self._item2UUID and eventArgs.Type == 1 then
            self._foundItemCount = self._foundItemCount + 1
            foundItemCountChanged = true

            self._proxy:DestroySceneObject(self._item2UUID)
            self._proxy:RemoveQuestNavPoint(self._id, self._step3Item2NavPointId)
            self._proxy:PushQuestStepProcess(self._id, 10013, 100132, 1)
            self._proxy:PushQuestStepProcess(self._id, 10013, 100133, 1)

            --local pos = self._proxy:GetSceneObjectPosition(self._item2UUID)
            --local rot = self._proxy:GetSceneObjectRotation(self._item2UUID)
            --rot.y = rot.y * -1
            --self._proxy:PlayDrama(self._id, nil, "StoryTest03", pos, rot)--找到物品2的剧情
        end

        if foundItemCountChanged and self._foundItemCount == 2 then
            local pos = self._proxy:GetNpcPosition(self._playerNpcUUID)
            self._proxy:PlayDrama(self._id, nil, "StoryLine005", pos, self._dramaRot)--获得2个目标物品的剧情
        end
    elseif eventType == EWorldEvent.EnterLevel then
        if eventArgs.IsPlayer and eventArgs.LevelId == 4001 then
            --重新进入关卡4001时，重新按需加载并获取道具物件
            if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10013, 100131) then
                self._proxy:LoadSceneObject(self._step3Item1PlaceId)
                self._item1UUID = self._proxy:GetSceneObjectUUID(self._step3Item1PlaceId)--物件1
                self._proxy:SetActorInQuest(self._id, self._item1UUID, true)
                if not self._step3Item1NavPointId then
                    self._step3Item1NavPointId = self._proxy:AddQuestNavPointForActor(self._questLevelId, self._id, 1, self._item1UUID)
                else
                    self._proxy:SetNavPointTargetActor(self._step3Item1NavPointId, self._item1UUID)
                end
            end

            if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10013, 100132) then
                self._proxy:LoadSceneObject(self._step3Item2PlaceId)
                self._item2UUID = self._proxy:GetSceneObjectUUID(self._step3Item2PlaceId)--物件1
                self._proxy:SetActorInQuest(self._id, self._item2UUID, true)
                if not self._step3Item2NavPointId then
                    self._step3Item2NavPointId = self._proxy:AddQuestNavPointForActor(self._questLevelId, self._id, 1, self._item2UUID)
                else
                    self._proxy:SetNavPointTargetActor(self._step3Item2NavPointId, self._item2UUID)
                end
            end

        elseif eventArgs.IsPlayer and eventArgs.LevelId == 4002 then
            --进入关卡4002时，重新创建我们的动态actor，重新将它设置给先前创建的导航点
            local playerUUID = self._proxy:GetLocalPlayerNpcId()
            local playerPos = self._proxy:GetNpcPosition(playerUUID)
            playerPos.z = playerPos.z + 2
            self._level4002TempNpc = self._proxy:GenerateLevelNpc(101001, ENpcCampType.Camp3, playerPos, {0})
            self._proxy:SetNavPointTargetActor(self._level4002TempNpcNavPointId, self._level4002TempNpc)
        end
    end
end

---@param self XQuestScript1001
XQuestScript1001.StepExitFuncs[10013] = function(self)
end

--==============================================================>>
--========================[[ 步骤4]]=============================<<
---@param self XQuestScript1001
XQuestScript1001.StepEnterFuncs[10014] = function(self)
    self._step4SceneObject3F = self._proxy:CreateSceneObject(self._commonSceneObjectBaseId, self._streetMall3F_ElevatorPortPos, nil)
    self._proxy:CreateActorTrigger(self._step4SceneObject3F, ETriggerTouchType.NpcCollider,
        EShapeType.Sphere, "Q1001-S4-3F", nil, nil,
        nil, 0.75, 0, 0)
    self._step4NavPointId = self._proxy:AddQuestNavPointForActor(self._questLevelId, self._id, 1, self._step4SceneObject3F)
end

---@param self XQuestScript1001
XQuestScript1001.StepHandleEventFuncs[10014] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger then
        if eventArgs.TriggerHolderUUID == self._step4SceneObject3F and eventArgs.EnteredActorUUID == self._playerNpcUUID then
            self._proxy:RemoveQuestNavPoint(self._id, self._step4NavPointId)
            self._proxy:PushQuestStepProcess(self._id, 10014, 100141, 1)
        end
    end
end

---@param self XQuestScript1001
XQuestScript1001.StepExitFuncs[10014] = function(self)
end

--==============================================================>>
--========================[[ 步骤5]]=============================<<
---@param self XQuestScript1001
XQuestScript1001.StepEnterFuncs[10015] = function(self)
    self._step5SceneObject2F = self._proxy:CreateSceneObject(self._commonSceneObjectBaseId, self._streetMall2F_ElevatorPortPos, nil)
    self._proxy:CreateActorTrigger(self._step5SceneObject2F, ETriggerTouchType.NpcCollider,
        EShapeType.Sphere, "Q1001-S5-2F", nil, nil,
        nil, 0.75, 0, 0)
    self._step5NavPointId = self._proxy:AddQuestNavPointForActor(self._questLevelId, self._id, 1, self._step5SceneObject2F)
end

---@param self XQuestScript1001
XQuestScript1001.StepHandleEventFuncs[10015] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger then
        if eventArgs.TriggerHolderUUID == self._step5SceneObject2F and eventArgs.EnteredActorUUID == self._playerNpcUUID then
            self._proxy:RemoveQuestNavPoint(self._id, self._step5NavPointId)
            self._proxy:PushQuestStepProcess(self._id, 10015, 100151, 1)
        end
    end
end

---@param self XQuestScript1001
XQuestScript1001.StepExitFuncs[10015] = function(self)
end

--==============================================================>>
--========================[[ 步骤6 ]]=============================<<
---@param self XQuestScript1001
XQuestScript1001.StepEnterFuncs[10016] = function(self)
    self._proxy:SetActorInQuest(self._id , self._questNpcUUID, true)
    self._step6NavPointId = self._proxy:AddQuestNavPointForActor(self._questLevelId, self._id, 1, self._questNpcUUID)
end

---@param self XQuestScript1001
XQuestScript1001.StepHandleEventFuncs[10016] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        if eventArgs.LauncherId == self._playerNpcUUID and eventArgs.TargetId == self._questNpcUUID and eventArgs.Type == 1 then
            self._proxy:OpenQuestItemDeliveryUI(100161)
        end
    elseif eventType == EWorldEvent.QuestItemsDeliveryConfirm then
        if eventArgs.ObjectiveId == 100161 then
            local pos = (self._proxy:GetNpcPosition(self._playerNpcUUID) + self._proxy:GetNpcPosition(self._questNpcUUID)) / 2
            local rot = self._proxy:GetNpcRotation(self._playerNpcUUID)
            self._proxy:PlayDrama(self._id, nil, "StoryLine010", pos, rot)--交付物品给NPC，结束任务的剧情
            self._proxy:RemoveQuestNavPoint(self._id, self._step6NavPointId)
        end
    elseif eventType == EWorldEvent.DramaFinish then
        --有剧情播放完成
        if eventArgs.DramaName == "StoryLine010" then
            self._proxy:PushQuestStepProcess(self._id,10016,100161,1)--推进任务1001中的步骤4中的进度6
        end
    end
end

---@param self XQuestScript1001
XQuestScript1001.StepExitFuncs[10016] = function(self)
end

--==============================================================>>