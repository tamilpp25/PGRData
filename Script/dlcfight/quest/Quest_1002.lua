local base = require("Common/XQuestBase")
---@class XQuestScript1002 : XQuestBase
local XQuestScript1002 = XDlcScriptManager.RegQuestStepScript(1002, "XQuestScript1002", base)

---@param proxy StatusSyncFight.XFightScriptProxy
function XQuestScript1002:Ctor(proxy)
    self._id = 1002
    self._dramaRot = { x = 0, y = 0, z = 0 }
    self._playerNpcUUID = 0
    self._item1PlaceId = 100001
    self._item1UUID = 0
    self._questNpc1PlaceId = 100016
    self._questNpc2PlaceId = 100011
    self._sceneObject_4003_3_PlaceId = 100010
    self._questNpc4PlaceId = 100002
    self._actor4003_1 = 3
    self._actor4003_2 = 4
    self._actor4003_3 = 2
    self._tempLevelSwitcherBackUUID = 0 --初始化为0，大于0时才是有效的UUID
    self._tempLevelSwitcherBack1UUID = 0 --初始化为0，大于0时才是有效的UUID
    self._questLevelId = 4001
    self._questLevel2Id = 4003
    self._emptyVector3 = { x = 0, y = 0, z = 0 }
end
function XQuestScript1002:Init()
    self._proxy:RegisterEvent(EWorldEvent.DramaFinish)
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.ShortMessageReadComplete)
    self._proxy:RegisterEvent(EWorldEvent.EnterLevel)
    self._proxy:RegisterEvent(EWorldEvent.LeaveLevel)
    self._playerNpcUUID = self._proxy:GetLocalPlayerNpcId()
    XLog.Debug("quest 1002 init, player npc uuid:" .. tostring(self._playerNpcUUID))
    self._questNpc4UUID = self._proxy:GetNpcUUID(self._questNpc4PlaceId)
    self._sceneObject_4003_3_UUID = self._proxy:GetSceneObjectUUID(self._actor4003_3)
end
function XQuestScript1002:Terminate()
end

--===================[[ 任务步骤]]-===================

--========================[[ 步骤1]]=============================>>
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10021] = function(self)
    self._proxy:PushQuestStepProcess(self._id, 10021, 100211, 1)--推进任务1002中的步骤1中的进度1
end

---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10021] = function(self, eventType, eventArgs)
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10021] = function(self)
end
--==============================================================<<

--========================[[ 步骤2]]=============================<< 
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10022] = function(self)
    self._proxy:RegisterEvent(EWorldEvent.QuestPopupClosed)
end
---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10022] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.QuestPopupClosed then
        if eventArgs.QuestId == self._id and eventArgs.PopupType == EQuestPopupType.Undertake then
            self._proxy:PlayDrama(self._id, nil, "CE_Dialog06", self._emptyVector3, self._dramaRot)
        end
    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "CE_Dialog06" then--播放完小露邀约指挥官短信对话
            self._proxy:SendChatMessage(1002)
            XLog.Debug("任务1002，发送短信1002")
        end
    elseif eventType == EWorldEvent.ShortMessageReadComplete then
        if eventArgs.MessageId == 1002 then --播放完小露邀约指挥官短信对话
            XLog.Debug("任务1002，短信1002阅读完毕")
            self._proxy:PushQuestStepProcess(self._id, 10022, 100221, 1)--推进任务1002中的步骤1中的进度1
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10022] = function(self)
    self._proxy:UnregisterEvent(EWorldEvent.QuestPopupClosed)
end
--==============================================================<<

--========================[[ 步骤3]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10023] = function(self)
    self._step1Item2NavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevelId, self._id, 1, self._sceneObject_4003_3_PlaceId, { x = 0,y = 1.3,z = 0 }, false, false)
    self._proxy:PlayDrama(self._id, nil,"CE_Dialog01", self._emptyVector3, self._dramaRot)
end

---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10023] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.EnterLevel then
        XLog.Error("quest step 10023 handle event EnterLevel")
        --有关卡切换
        if eventArgs.LevelId == 4003 then --切换到宿舍关卡
            self._proxy:PushQuestStepProcess(self._id, 10023, 100231, 1)--推进任务1002中的步骤2中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step1Item2NavPointId)
            XLog.Error("quest push 4003 100231")
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10023] = function(self)
end

--==============================================================>>
--========================[[ 步骤4]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10024] = function(self)  
    self._proxy:LoadSceneObject(self._item1PlaceId)--加载兔子物件
    self._proxy:SetActorInQuest(self._id, self._item1UUID, true)
    self._step2Item2NavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevel2Id, self._id, 1, self._item1PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    self._proxy:PlayDrama(self._id, nil,"CE_Dialog02", self._emptyVector3, self._dramaRot)
end

---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10024] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        --[[
            放在这里获取uuid，因为正常来说，第一次做该任务时，
            不可能在enter里load该物件后立刻就能拿到uuid，因为load创建行为是在客户端进行，有物理网络延迟。
        ]]
        self._item1UUID = self._proxy:GetSceneObjectUUID(self._item1PlaceId)--获取兔子物件UUID
        XLog.Debug("任务1002, 10024, 兔子点心UUID：" .. tostring(self._item1UUID))
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._item1UUID and eventArgs.Type == 1 then
            self._proxy:PushQuestStepProcess(self._id, 10024, 100241, 1)--推进任务1002中的步骤3中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step2Item2NavPointId)
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10024] = function(self)
    self._proxy:DestroySceneObject(self._item1UUID)
    self._proxy:PlayDrama(self._id, nil,"CE_Dialog03", self._emptyVector3, self._dramaRot)
end

--==============================================================>>
--========================[[ 步骤5]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10025] = function(self)
    self._proxy:SetActorInQuest(self._id, self._tempLevelSwitcherBackUUID, true)
    if self._proxy:GetCurrentLevelId() == 4003 then 
        self._tempLevelSwitcherBackUUID = self._proxy:GetSceneObjectUUID(self._actor4003_1) 
        self._step3ItemNavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevel2Id, self._id, 1, self._actor4003_1, self._emptyVector3, false, false)       
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10025] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._tempLevelSwitcherBackUUID and eventArgs.Type == 1 then
            self._proxy:RemoveQuestNavPoint(self._id, self._step3ItemNavPointId)
            self._proxy:PushQuestStepProcess(self._id, 10025, 100251, 1)--推进任务1002中的步骤3中的进度1
        end
    elseif eventType == EWorldEvent.EnterLevel then
        if eventArgs.IsPlayer and eventArgs.LevelId == 4003 and self._tempLevelSwitcherBackUUID <= 0 then 
            if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10025, 100251) then
                self._tempLevelSwitcherBackUUID = self._proxy:GetSceneObjectUUID(self._actor4003_1)
            end
        end
    elseif eventType == EWorldEvent.LeaveLevel then
        if eventArgs.IsPlayer and eventArgs.LevelId == 4003 and self._tempLevelSwitcherBackUUID <= 0 then 
            if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10025, 100251) then
                self._tempLevelSwitcherBackUUID = 0
            end
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10025] = function(self)
end
--==============================================================>>
--========================[[ 步骤6]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10026] = function(self)
    self._proxy:SetActorInQuest(self._id, self._tempLevelSwitcherBack1UUID, true)
    if self._proxy:GetCurrentLevelId() == 4003 then 
        self._tempLevelSwitcherBack1UUID = self._proxy:GetSceneObjectUUID(self._actor4003_2) 
        self._step4ItemNavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevel2Id, self._id, 1, self._actor4003_2, self._emptyVector3, false, false)           
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10026] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._tempLevelSwitcherBack1UUID and eventArgs.Type == 1 then
            self._proxy:PushQuestStepProcess(self._id, 10026, 100261, 1)--推进任务1002中的步骤3中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step4ItemNavPointId)
        end
    elseif eventType == EWorldEvent.EnterLevel then
        if eventArgs.IsPlayer and eventArgs.LevelId == 4003 and self._tempLevelSwitcherBackUUID <= 0 then 
            if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10026, 100261) then
                self._tempLevelSwitcherBack1UUID = self._proxy:GetSceneObjectUUID(self._actor4003_2)
            end
        end
    elseif eventType == EWorldEvent.LeaveLevel then
        if eventArgs.IsPlayer and eventArgs.LevelId == 4003 and self._tempLevelSwitcherBackUUID <= 0 then 
            if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10026, 100261) then
                self._tempLevelSwitcherBack1UUID = 0
            end
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10026] = function(self)
end
--==============================================================>>
--========================[[ 步骤7]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10027] = function(self)  
    self._proxy:SetActorInQuest(self._id, self._sceneObject_4003_3_UUID, true)
    self._step5ItemNavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevel2Id, self._id, 1, self._actor4003_3, { x = 0, y = 1.3, z = 0 }, false, false)        
end

---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10027] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.LeaveLevel then
        XLog.Debug("quest step 10027 handle event LeaveLevel")
        --有关卡切换
        if eventArgs.LevelId == 4003 then --退出宿舍关卡
            self._proxy:PushQuestStepProcess(self._id, 10027, 100271, 1)--推进任务1002中的步骤4中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step5ItemNavPointId)
            XLog.Debug("quest push 4003 100271")
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10027] = function(self) 
end

--==============================================================>>
--========================[[ 步骤8]]=============================<<

---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10028] = function(self)
    self._questNpc1UUID = self._proxy:GetNpcUUID(self._questNpc1PlaceId)
    XLog.Debug("任务1002，10028，获取咖啡npc：".. tostring(self._questNpc1UUID) .. " 关卡：".. self._proxy:GetCurrentLevelId())
    self._proxy:SetActorInQuest(self._id, self._questNpc1UUID, true)
    self._step6ItemNavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc1PlaceId, { x = 0, y = 2.2, z = 0 }, false, false)        
end
---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10028] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        XLog.Debug("任务1002，10028，Npc交互事件，target：" .. tostring(eventArgs.TargetId) .. "，cafeWaiter：" .. tostring(self._questNpc1UUID))
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc1UUID and eventArgs.Type == 1 then
            self._proxy:PlayDrama(self._id, { self._questNpc1UUID }, "CE_Dialog04", self._emptyVector3, self._dramaRot)--和咖啡厅引导员对话剧情
        end
    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "CE_Dialog04" then
            self._proxy:PushQuestStepProcess(self._id, 10028, 100281, 1)--推进任务1002中的步骤5中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step6ItemNavPointId)
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10028] = function(self)
end
--==============================================================>>
--========================[[ 步骤9]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10029] = function(self)
    self._questNpc2UUID = self._proxy:GetNpcUUID(self._questNpc2PlaceId)
    self._proxy:SetActorInQuest(self._id, self._questNpc2UUID, true)
    self._step7ItemNavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc2PlaceId, { x = 0, y = 1.5, z = 0 }, false, false)       
end
---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10029] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        if XScriptTool.CheckNpcInteractStart(self._proxy, eventArgs, self._questNpc2UUID) then
            self._proxy:PlayDrama(self._id, nil, "StoryDrama05", self._emptyVector3, self._dramaRot)--和小露聊天对话剧情
        end
    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "StoryDrama05" then
            self._proxy:PushQuestStepProcess(self._id, 10029, 100291, 1)--推进任务1002中的步骤5中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step7ItemNavPointId)
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10029] = function(self)
end
