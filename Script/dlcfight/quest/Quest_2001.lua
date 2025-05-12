local base = require("Common/XQuestBase")
---@class XQuestScript2001
local XQuestScript2001 = XDlcScriptManager.RegQuestStepScript(2001, "XQuestScript2001", base)

---@param proxy StatusSyncFight.XFightScriptProxy
function XQuestScript2001:Ctor(proxy)
    self._id = 2001
    self._dramaRot = { x = 0, y = 0, z = 0 }
    self._playerNpcUUID = 0
    self._questLevelId = 4001
    self._questNpc1PlaceId = 100084
    self._questNpc2PlaceId = 100020
    self._questNpc3PlaceId = 100145
    self._questNpc4PlaceId = 100144
    self._questNpc5PlaceId = 100079
    self._questNpc6PlaceId = 100148
    self._questNpc7PlaceId = 100146
    self._questNpc8PlaceId = 100147
    self._questNpc9PlaceId = 100080
    self._questNpc10PlaceId = 100081
    self._questNpc11PlaceId = 100082
    self._questNpc12PlaceId = 100149
    self._questNpc13PlaceId = 100150
    self._questNpc14PlaceId = 100151
    self._questNpc15PlaceId = 100083
    self._questNpc16PlaceId = 100042
    self._questNpc17PlaceId = 100176
    self._questNpc18PlaceId = 100177
    self._questNpc19PlaceId = 100085
    self._questNpc20PlaceId = 100128
    self._questNpc21PlaceId = 100178
    self._questNpc22PlaceId = 100086
    self._questNpc23PlaceId = 100179
    self._questNpc24PlaceId = 100180
    self._questNpc25PlaceId = 100087
    self._questNpc26PlaceId = 100088
    self._questNpc27PlaceId = 100089
    self._questNpc28PlaceId = 100181
    self._questNpc29PlaceId = 100065

    self._emptyVector3 = { x = 0, y = 0, z = 0 }
    self._tempLevelSwitcherBackUUID = 0 --初始化为0，大于0时才是有效的UUID
    self._tempLevelSwitcherBack1UUID = 0 --初始化为0，大于0时才是有效的UUID
    self._streetGuideNpcLockKey = 40010020
    self._triggerSceneObjectUUID = 0
end

function XQuestScript2001:Init()
    --任务初始化
    self._proxy:RegisterEvent(EWorldEvent.DramaCaptionEnd)
    self._proxy:RegisterEvent(EWorldEvent.DramaFinish)
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractComplete)
    self._proxy:RegisterEvent(EWorldEvent.ShortMessageReadComplete)
    self._proxy:RegisterEvent(EWorldEvent.EnterLevel)

    self._playerNpcUUID = self._proxy:GetLocalPlayerNpcId()

end

function XQuestScript2001:Terminate()
    --任务结束
    --事件监听解除
    --容器清空
end

--===================[[ 任务步骤]]
--region ========================[[ 步骤1 ]]=============================>>
---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200101] = function(self)
    self._proxy:PushQuestStepProcess(self._id, 200101, 2001011, 1)
    XLog.Debug("任务2001 200101 进入")
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200101] = function(self, eventType, eventArgs)


end
---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200101] = function(self)
end


--region ========================[[ 步骤2]]=============================>>
---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200102] = function(self)
    self._proxy:RegisterEvent(EWorldEvent.QuestPopupClosed)
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200102] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.QuestPopupClosed then
        if eventArgs.QuestId == self._id and eventArgs.PopupType == EQuestPopupType.Undertake then
            self._proxy:PlayDrama(self._id, nil, "Caption200101", self._emptyVector3, self._dramaRot)
            self._proxy:SendChatMessage(200101)
            ----发送短信
            XLog.Debug("任务2001，200102，短信：" .. tostring(eventArgs))

        end

    elseif eventType == EWorldEvent.ShortMessageReadComplete then
        if eventArgs.MessageId == (200101) then
            XLog.Debug("任务2001，200102，短信，ID：" .. tostring(eventArgs.MessageId))
            self._proxy:PushQuestStepProcess(self._id, 200102, 2001021, 1)
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200102] = function(self)
    self._proxy:UnregisterEvent(EWorldEvent.QuestPopupClosed)
end

--region ========================[[ 步骤3 ]]=============================>>
---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200103] = function(self)
    self._proxy:PlayDrama(self._id, nil, "Caption200102", self._emptyVector3, self._dramaRot)
    --------播放剧情
    self._proxy:LoadSceneObject(self._questNpc1PlaceId)
    --------注册新闻调查物件
    self._step3Item1NavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevelId, self._id, 1, self._questNpc1PlaceId, self._emptyVector3, false, false)
end
---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200103] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        ----------调查物件
        self._item1UUID = self._proxy:GetSceneObjectUUID(self._questNpc1PlaceId)------获取新闻调查物件id
        XLog.Debug("任务2001，200103，Npc交互事件，target：" .. tostring(eventArgs.TargetId) .. "，item：" .. tostring(self._item1UUID))

        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._item1UUID then
            self._proxy:RemoveQuestNavPoint(self._id, self._step3Item1NavPointId)
            self._proxy:PushQuestStepProcess(self._id, 200103, 2001031, 1)
            --------推进任务步骤
            self._proxy:DestroySceneObject(self._item1UUID)
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200103] = function(self)


end

--endregion ========================[[ 步骤3 ]]=============================<<

--region ========================[[ 步骤4 ]]=============================>>
---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200104] = function(self)
    self._proxy:SendChatMessage(200102)------发送短信
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200104] = function(self, eventType, eventArgs)

    if eventType == EWorldEvent.ShortMessageReadComplete then
        if eventArgs.MessageId == (200102) then
            self._proxy:PlayDrama(self._id, nil, "Caption200103", self._emptyVector3, self._dramaRot)--------播放剧情（暂）
        end
    elseif eventType == EWorldEvent.DramaFinish then

        if eventArgs.DramaName == "Caption200103" then
            self._proxy:PushQuestStepProcess(self._id, 200104, 2001041, 1)

        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200104] = function(self)
end

--endregion ========================[[ 步骤4 ]]=============================<<

--region ========================[[ 步骤5 ]]=============================>>
---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200105] = function(self)
    self._proxy:LoadLevelNpc(self._questNpc3PlaceId)
    ------加载窃听员工1
    self._proxy:LoadLevelNpc(self._questNpc4PlaceId)
    ------加载窃听员工2
    self._questNpc2UUID = self._proxy:GetNpcUUID(self._questNpc2PlaceId)
    self._proxy:SetActorInQuest(self._id, self._questNpc2UUID, true)

    self._step5questNPC2NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc2PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200105] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        ----------和赛利卡对话

        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc2UUID then
            self._proxy:SetActorInQuest(self._id, self._questNpc2UUID, true)
            self._proxy:SetLevelMemoryInt(self._streetGuideNpcLockKey, 1)
            XLog.Debug("商店街 赛利卡 set lock：" .. tostring(self._proxy:GetLevelMemoryInt(self._streetGuideNpcLockKey)))
            self._proxy:RemoveQuestNavPoint(self._id, self._step5questNPC2NavPointId)
            self._proxy:PlayDrama(self._id, nil, "Drama200101", self._emptyVector3, self._dramaRot)--------播放剧情
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama200101" then
            self._proxy:PushQuestStepProcess(self._id, 200105, 2001051, 1)--------推进任务步骤


        end

    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200105] = function(self)
end

--endregion ========================[[ 步骤5 ]]=============================<<

--region ========================[[ 步骤6 ]]=============================>>
---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200106] = function(self)
    ----------该任务步骤暂时用来测试触发器好不好使，测完记得改回去----等程序看触发器---12.23备注 不改回去了
    self._proxy:LoadSceneObject(self._questNpc15PlaceId)
    ------加载带有触发器组件的空物体，并赋予它triggerUUID
    self._step6questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevelId, self._id, 1, self._questNpc15PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    ---------导航设置到这个空物体上
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200106] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger then
        ----------监听事件：Trigger是否被触发
        XLog.Debug("触发器事件：", eventArgs)
        self._triggerSceneObjectUUID = self._proxy:GetSceneObjectUUID(self._questNpc15PlaceId)
        if eventArgs.HostSceneObjectPlaceId == self._questNpc15PlaceId and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then
            ----判断角色是否触发空物体上的Trigger
            XLog.Debug("任务2001，200106，触发器事件，trigger：" .. tostring(eventArgs.HostSceneObjectPlaceId) .. "，Player：" .. tostring(self._EnteredActorUUID))
            self._proxy:DestroySceneObject(self._triggerSceneObjectUUID)
            -----销毁这个空物件
            self._proxy:RemoveQuestNavPoint(self._id, self._step6questNPC1NavPointId)
            -----移除导航点
            self._proxy:PlayDrama(self._id, nil, "Drama200102", self._emptyVector3, self._dramaRot)--------播放剧情
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama200102" then

            self._proxy:PushQuestStepProcess(self._id, 200106, 2001061, 1)--------推进任务步骤
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200106] = function(self)
end

--endregion ========================[[ 步骤6 ]]=============================<<

--region ========================[[ 步骤7 ]]=============================>>
---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200107] = function(self)
    self._proxy:LoadSceneObject(self._questNpc5PlaceId)
    ------加载遗失文件
    self._step7questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevelId, self._id, 1, self._questNpc5PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200107] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        ----------交互遗失的文件
        self._item3UUID = self._proxy:GetSceneObjectUUID(self._questNpc5PlaceId)
        self._proxy:SetActorInQuest(self._id, self._item3UUID, true)
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._item3UUID then
            self._proxy:RemoveQuestNavPoint(self._id, self._step7questNPC1NavPointId)
            self._proxy:DestroySceneObject(self._item3UUID)
            self._proxy:PlayDrama(self._id, nil, "Caption200104", self._emptyVector3, self._dramaRot)-------播放独白
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Caption200104" then
            self._proxy:PushQuestStepProcess(self._id, 200107, 2001071, 1)
        end
    end

end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200107] = function(self)
    self._proxy:DestroySceneObject(self._questNpc5UUID)-------摧毁场景物件
end

--endregion ========================[[ 步骤7 ]]=============================<<

--region ========================[[ 步骤8 ]]=============================>>
---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200108] = function(self)

    self._step8questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc2PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200108] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        ----------和赛利卡对话
        self._questNpc2UUID = self._proxy:GetNpcUUID(self._questNpc2PlaceId)
        self._proxy:SetActorInQuest(self._id, self._questNpc2UUID, true)
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc2UUID then
            self._proxy:RemoveQuestNavPoint(self._id, self._step8questNPC1NavPointId)
            self._proxy:PlayDrama(self._id, nil, "Drama200104", self._emptyVector3, self._dramaRot)--------播放剧情

            self._questNpc3UUID = self._proxy:GetNpcUUID(self._questNpc3PlaceId)-----获得两个窃听NPC的ID
            self._questNpc4UUID = self._proxy:GetNpcUUID(self._questNpc4PlaceId)
            self._proxy:DestroyNpc(self._questNpc3UUID)
            -------销毁两个窃听Npc
            self._proxy:DestroyNpc(self._questNpc4UUID)
        end
    elseif eventType == EWorldEvent.DramaFinish then

        if eventArgs.DramaName == "Drama200104" then
            self._proxy:PushQuestStepProcess(self._id, 200108, 2001081, 1)
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200108] = function(self)
end

--endregion ========================[[ 步骤8 ]]=============================<<

--region ========================[[ 步骤9 ]]=============================>>
---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200109] = function(self)

    self._step1questNPC6NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc2PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    self._proxy:SetActorInQuest(self._id, self._questNpc2UUID, true)
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200109] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        ----------和赛利卡对话
        self._questNpc2UUID = self._proxy:GetNpcUUID(self._questNpc2PlaceId)

        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc2UUID then
            self._proxy:RemoveQuestNavPoint(self._id, self._step1questNPC6NavPointId)
            self._proxy:PlayDrama(self._id, nil, "Drama200105", self._emptyVector3, self._dramaRot)--------播放剧情

        end
    elseif eventType == EWorldEvent.DramaFinish then

        if eventArgs.DramaName == "Drama200105" then
            self._proxy:LoadLevelNpc(self._questNpc6PlaceId)
            -----加载卡列
            self._proxy:PushQuestStepProcess(self._id, 200109, 2001091, 1)
        end
    end

end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200109] = function(self)
end

--endregion ========================[[ 步骤9 ]]=============================<<

--region ========================[[ 步骤10 ]]=============================>>
---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200110] = function(self)
    self._step1questNPC7NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc6PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)

end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200110] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        ----------和卡列对话
        self._questNpc6UUID = self._proxy:GetNpcUUID(self._questNpc6PlaceId)

        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc6UUID then
            self._proxy:RemoveQuestNavPoint(self._id, self._step1questNPC7NavPointId)
            self._proxy:PlayDrama(self._id, nil, "Drama200106", self._emptyVector3, self._dramaRot)--------播放剧情

        end
    elseif eventType == EWorldEvent.DramaFinish then

        if eventArgs.DramaName == "Drama200106" then
            self._proxy:PushQuestStepProcess(self._id, 200110, 2001101, 1)
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200110] = function(self)

end
--endregion ========================[[ 步骤10 ]]=============================<<

--region ========================[[ 步骤11 ]]=============================>>

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200111] = function(self)
    self._proxy:LoadSceneObject(self._questNpc9PlaceId)
    -----逛街触发器1
    self._step11questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevelId, self._id, 1, self._questNpc9PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    ---------导航设置到这个触发器上
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200111] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger then
        ----------监听事件：Trigger是否被触发
        XLog.Debug("触发器事件：", eventArgs)
        self._triggerSceneObjectUUID = self._proxy:GetSceneObjectUUID(self._questNpc9PlaceId)
        if eventArgs.HostSceneObjectPlaceId == self._questNpc9PlaceId and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then
            ----判断角色是否触发空物体上的Trigger
            XLog.Debug("任务2001，200111，触发器事件，trigger：" .. tostring(eventArgs.HostSceneObjectPlaceId) .. "，Player：" .. tostring(self._EnteredActorUUID))
            self._proxy:DestroySceneObject(self._triggerSceneObjectUUID)
            -----销毁这个空物件
            self._proxy:RemoveQuestNavPoint(self._id, self._step11questNPC1NavPointId)
            -----移除导航点
            self._proxy:PlayDrama(self._id, nil, "Caption200105", self._emptyVector3, self._dramaRot)--------播放剧情----卡列妮娜视察商业街
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Caption200105" then
            self._proxy:LoadLevelNpc(self._questNpc7PlaceId)
            -----加载食品店老板
            self._proxy:LoadLevelNpc(self._questNpc8PlaceId)
            -----加载花店老板
            self._proxy:PushQuestStepProcess(self._id, 200111, 2001111, 1)--------推进任务步骤
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200111] = function(self)

end

--endregion ========================[[ 步骤11 ]]=============================<<

--region ========================[[ 步骤12 ]]=============================>>

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200112] = function(self)
    self._step12questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc7PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)

end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200112] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        ----------监听事件：NPC交互
        XLog.Debug("交互事件：", eventArgs)
        self._questNpc7UUID = self._proxy:GetNpcUUID(self._questNpc7PlaceId)
        self._proxy:SetActorInQuest(self._id, self._questNpc7UUID, true)
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc7UUID then
            ----判断主角是否和NPC交互
            self._proxy:RemoveQuestNavPoint(self._id, self._step12questNPC1NavPointId)
            -----移除导航点
            self._proxy:PlayDrama(self._id, nil, "Caption200111", self._emptyVector3, self._dramaRot)--------播放剧情-----和食品店对话
        end
    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Caption200111" then
            self._proxy:PushQuestStepProcess(self._id, 200112, 2001121, 1)--------推进任务步骤
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200112] = function(self)

end
--endregion ========================[[ 步骤12 ]]=============================<<

--region ========================[[ 步骤13 ]]=============================>>

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200113] = function(self)
    self._step13questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc8PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    self._questNpc8UUID = self._proxy:GetNpcUUID(self._questNpc8PlaceId)


end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200113] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        ----------监听事件：NPC交互
        XLog.Debug("交互事件：", eventArgs)
        self._questNpc8UUID = self._proxy:GetNpcUUID(self._questNpc8PlaceId)
        self._proxy:SetActorInQuest(self._id, self._questNpc8UUID, true)
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc8UUID then
            ----判断主角是否和NPC交互
            self._proxy:RemoveQuestNavPoint(self._id, self._step13questNPC1NavPointId)
            -----移除导航点
            self._proxy:PlayDrama(self._id, nil, "Caption200106", self._emptyVector3, self._dramaRot)--------播放剧情-----和花店对话
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Caption200106" then

            self._proxy:PushQuestStepProcess(self._id, 200113, 2001131, 1)--------推进任务步骤
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200113] = function(self)

end
--endregion ========================[[ 步骤13 ]]=============================<<

--region ========================[[ 步骤14 ]]=============================>>

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200114] = function(self)
    self._proxy:PlayDrama(self._id, nil, "Caption200107", self._emptyVector3, self._dramaRot)
    self._proxy:SendChatMessage(200103)---------------向蕾奥妮发送短信
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200114] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.ShortMessageReadComplete then
        if eventArgs.MessageId == (200103) then
            self._proxy:PlayDrama(self._id, nil, "Drama200107", self._emptyVector3, self._dramaRot)

        end
    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama200107" then
            self._proxy:PushQuestStepProcess(self._id, 200114, 2001141, 1)
            self._proxy:LoadLevelNpc(self._questNpc12PlaceId)
            self._proxy:LoadLevelNpc(self._questNpc13PlaceId)
            self._proxy:LoadLevelNpc(self._questNpc14PlaceId)-----------预先加载三个辅助机
        end

    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200114] = function(self)

end

--endregion ========================[[ 步骤14 ]]=============================<<

--region ========================[[ 步骤15]=============================>>

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200115] = function(self)

    self._proxy:SetActorInQuest(2001, self._questNpc2UUID, false)
    -------解除赛利卡的占用
    self._step15questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc2PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    -----------导航到塞利卡上
    self._proxy:RegisterEvent(EWorldEvent.ConditionCheckTrigger)

end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200115] = function(self, eventType, eventArgs)

    if eventType == EWorldEvent.ConditionCheckTrigger then
        ----------监听事件：条件达成
        XLog.Debug("条件监听事件：", eventArgs)
        if eventArgs.ConditionType == 20201001 and self._proxy:CheckSystemCondition(50000001) then
            ------判断条件
            XLog.Debug("条件类型：" .. tostring(eventArgs.ConditionType) .. "条件id" .. tostring(eventArgs.ConditionType))

        end


    elseif eventType == EWorldEvent.EnterLevel and self._proxy:CheckSystemCondition(50000001) then
        -----判断玩家加载入40001 以及完成了玩法条件
        if eventArgs.IsPlayer and eventArgs.LevelId == 4001 then
            self._proxy:PlayDrama(self._id, nil, "Drama200108", self._emptyVector3, self._dramaRot)
            --------播放剧情----赛利卡让你继续联系商户入驻
            self._proxy:RemoveQuestNavPoint(self._id, self._step15questNPC1NavPointId)-----移除导航点--容错
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama200108" then
            self._proxy:SetActorInQuest(2001, self._questNpc2UUID, true)-------恢复对赛利卡的占用

            self._proxy:PushQuestStepProcess(self._id, 200115, 2001151, 1)--------推进任务步骤

        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200115] = function(self)
    self._questNpc6UUID = self._proxy:GetNpcUUID(self._questNpc6PlaceId)------卡列6（id）
    self._questNpc12UUID = self._proxy:GetNpcUUID(self._questNpc12PlaceId)
    self._questNpc13UUID = self._proxy:GetNpcUUID(self._questNpc13PlaceId)
    self._questNpc14UUID = self._proxy:GetNpcUUID(self._questNpc14PlaceId)
    self._questNpc7UUID = self._proxy:GetNpcUUID(self._questNpc7PlaceId)
    self._questNpc8UUID = self._proxy:GetNpcUUID(self._questNpc8PlaceId)
    self._proxy:DestroyNpc(self._questNpc12UUID)
    ------摧毁库洛洛*3
    self._proxy:DestroyNpc(self._questNpc13UUID)
    self._proxy:DestroyNpc(self._questNpc14UUID)
    self._proxy:DestroyNpc(self._questNpc7UUID)
    -----摧毁花店老板和食品店老板
    self._proxy:DestroyNpc(self._questNpc8UUID)
    self._proxy:LoadLevelNpc(self._questNpc16PlaceId)
    -------加载甜品店老板
    ---self._proxy:LoadLevelNpc(self._questNpc18PlaceId)-------加载游客---注释掉了暂时不加载
    self._proxy:LoadLevelNpc(self._questNpc20PlaceId)-------加载桌游店老板
end

--endregion ========================[[ 步骤15 ]]=============================<<

--region ========================[[ 步骤16]=============================>>

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200116] = function(self)
    self._proxy:PlayDrama(self._id, nil, "Caption200108", self._emptyVector3, self._dramaRot)
    self._step16questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc16PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    -----------导航到甜品店老板身上

end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200116] = function(self, eventType, eventArgs)

    if eventType == EWorldEvent.NpcInteractStart then
        self._questNpc16UUID = self._proxy:GetNpcUUID(self._questNpc16PlaceId)------甜品店老板（id）
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc16UUID then
            self._proxy:PlayDrama(self._id, nil, "Drama200109", self._emptyVector3, self._dramaRot)--------播放剧情
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama200109" then
            self._proxy:DestroyNpc(self._questNpc6UUID)
            --------摧毁卡列6
            self._proxy:LoadLevelNpc(self._questNpc17PlaceId)
            -------加载卡列17
            self._proxy:RemoveQuestNavPoint(self._id, self._step16questNPC1NavPointId)
            -----移除导航点
            self._proxy:PushQuestStepProcess(self._id, 200116, 2001161, 1)--------推进任务步骤

        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[2001116] = function(self)

end
--endregion ========================[[ 步骤16 ]]=============================<<

--region ========================[[ 步骤17]=============================>>

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200117] = function(self)
    self._proxy:PlayDrama(self._id, nil, "Caption200109", self._emptyVector3, self._dramaRot)
    self._step17questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc17PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    -----------导航到卡列身上

end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200117] = function(self, eventType, eventArgs)

    if eventType == EWorldEvent.NpcInteractStart then
        self._questNpc17UUID = self._proxy:GetNpcUUID(self._questNpc17PlaceId)------卡列（id）
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc17UUID then
            self._proxy:RemoveQuestNavPoint(self._id, self._step17questNPC1NavPointId)
            -----移除导航点
            self._proxy:PlayDrama(self._id, nil, "Drama200110", self._emptyVector3, self._dramaRot)--------播放剧情
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama200110" then
            self._proxy:PushQuestStepProcess(self._id, 200117, 2001171, 1)--------推进任务步骤
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200117] = function(self)

end
--endregion ========================[[ 步骤17 ]]=============================<<

--region ========================[[ 步骤18]=============================>>

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200118] = function(self)
    self._step18questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc20PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    -----------导航到桌游店老板身上
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200118] = function(self, eventType, eventArgs)

    if eventType == EWorldEvent.NpcInteractStart then
        self._questNpc20UUID = self._proxy:GetNpcUUID(self._questNpc20PlaceId)------桌游店老板（id）
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc20UUID then
            self._proxy:RemoveQuestNavPoint(self._id, self._step18questNPC1NavPointId)
            -----移除导航点
            self._proxy:PlayDrama(self._id, nil, "Drama200111", self._emptyVector3, self._dramaRot)
            --------播放剧情.得到桌游店老板的建议
            self._proxy:DestroyNpc(self._questNpc17UUID)------摧毁卡列17
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama200111" then
            self._proxy:PushQuestStepProcess(self._id, 200118, 2001181, 1)--------推进任务步骤
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200118] = function(self)


end
--endregion ========================[[ 步骤18]]=============================<<

--region ========================[[ 步骤19]=============================>>

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200119] = function(self)
    self._proxy:PlayDrama(self._id, nil, "Drama200112", self._emptyVector3, self._dramaRot)
    self._proxy:SendChatMessage(200104)-------发送短信 记得先去配置一个临时短信 不然会报错

end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200119] = function(self, eventType, eventArgs)

    if eventType == EWorldEvent.ShortMessageReadComplete then
        if eventArgs.MessageId == (200104) then
            self._proxy:PlayDrama(self._id, nil, "Drama200113", self._emptyVector3, self._dramaRot)--------播放剧情.招募桌游店老板
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama200113" then
            self._proxy:PushQuestStepProcess(self._id, 200119, 2001191, 1)
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200119] = function(self)


end

--endregion ========================[[ 步骤19]]=============================<<

--region ========================[[ 步骤20]=============================>>

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200120] = function(self)

    self._proxy:SetActorInQuest(2001, self._questNpc2UUID, false)
    -------解除赛利卡的占用
    self._step20questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc2PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    -----------导航到塞利卡上

end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200120] = function(self, eventType, eventArgs)

    if eventType == EWorldEvent.ConditionCheckTrigger then
        ----------监听事件：条件达成
        XLog.Debug("条件监听事件：", eventArgs)
        if eventArgs.ConditionType == 20201001 and self._proxy:CheckSystemCondition(50000002) then
            ------判断条件（等玩法给新的）
            XLog.Debug("条件类型：" .. tostring(eventArgs.ConditionType) .. "条件id" .. tostring(eventArgs.ConditionType))
            self._proxy:RemoveQuestNavPoint(self._id, self._step20questNPC1NavPointId)-----移除导航点
        end

    elseif eventType == EWorldEvent.EnterLevel and self._proxy:CheckSystemCondition(50000002) then
        -----判断玩家加载入40001 以及完成了玩法条件
        if eventArgs.IsPlayer and eventArgs.LevelId == 4001 then
            self._proxy:PlayDrama(self._id, nil, "Drama200115", self._emptyVector3, self._dramaRot)
            --------播放剧情----赛利卡让你继续联系商户入驻
            self._proxy:RemoveQuestNavPoint(self._id, self._step20questNPC1NavPointId)-----移除导航点---容错
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama200115" then
            self._questNpc16UUID = self._proxy:GetNpcUUID(self._questNpc16PlaceId)
            self._questNpc18UUID = self._proxy:GetNpcUUID(self._questNpc20PlaceId)
            self._proxy:DestroyNpc(self._questNpc16UUID)
            ----摧毁甜品店老板
            self._proxy:DestroyNpc(self._questNpc20UUID)
            ----摧毁桌游店老板
            self._proxy:SetActorInQuest(2001, self._questNpc2UUID, true)
            -------恢复对赛利卡的占用
            self._proxy:SendChatMessage(200105)------提前发送短信
        end
    elseif eventType == EWorldEvent.ShortMessageReadComplete then
        if eventArgs.MessageId == (200105) then
            self._proxy:PushQuestStepProcess(self._id, 200120, 2001201, 1)--------推进任务步骤
        end

    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200120] = function(self)

end
--endregion ========================[[ 步骤20]]=============================<<

--region ========================[ 步骤21]=============================>>《最后的书》

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200121] = function(self)
    self._proxy:LoadLevelNpc(self._questNpc28PlaceId)
    -------先加载卡列粉丝------临时挪到这里，玩法修好了搬回去
    self._proxy:LoadSceneObject(self._questNpc27PlaceId)
    -------先加载触发器
    self._proxy:LoadSceneObject(self._questNpc22PlaceId)
    -------先加载《最后的书》
    self._proxy:LoadLevelNpc(self._questNpc23PlaceId)
    -------加载库洛洛
    self._proxy:LoadSceneObject(self._questNpc29PlaceId)-----加载《机器人》

    self._step21questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevelId, self._id, 1, self._questNpc22PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    -----------导航到《最后的书》身上
end
---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200121] = function(self, eventType, eventArgs)

    if eventType == EWorldEvent.NpcInteractStart then
        ----------监听事件交互物件完毕
        XLog.Debug("交互物：", eventArgs)
        self._questNpc22UUID = self._proxy:GetSceneObjectUUID(self._questNpc22PlaceId)------《最后的书》（id）
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc22UUID then
            ----判断角色交互是否正确

            self._proxy:DestroySceneObject(self._questNpc22UUID)
            -----销毁这本书
            self._proxy:RemoveQuestNavPoint(self._id, self._step21questNPC1NavPointId)
            -----移除导航点
            self._proxy:PushQuestStepProcess(self._id, 200121, 2001211, 1)--------推进任务步骤
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200121] = function(self)


end
--endregion ========================[[ 步骤21]]=============================<<

--region ========================[ 步骤22]=============================>>在库洛洛身上获取第二本书

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200122] = function(self)
    self._step22questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevelId, self._id, 1, self._questNpc29PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    -----------导航到第二个触发器身上
end
---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200122] = function(self, eventType, eventArgs)

    if eventType == EWorldEvent.NpcInteractStart then
        ----------监听事件交互物件完毕
        XLog.Debug("交互物：", eventArgs)
        self._questNpc29UUID = self._proxy:GetSceneObjectUUID(self._questNpc29PlaceId)------库洛洛（id）
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc29UUID then
            ----判断角色交互是否正确

            self._proxy:DestroySceneObject(self._questNpc29UUID)
            -----销毁这本书
            self._proxy:RemoveQuestNavPoint(self._id, self._step22questNPC1NavPointId)
            -----移除导航点
            self._proxy:PushQuestStepProcess(self._id, 200122, 2001221, 1)--------推进任务步骤
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200122] = function(self)


end
--endregion ========================[[ 步骤22]]=============================<<

--region ========================[ 步骤23]=============================>>目标是卡列粉丝

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200123] = function(self)
    self._proxy:PlayDrama(self._id, nil, "Drama200116", self._emptyVector3, self._dramaRot)
    self._step21questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevelId, self._id, 1, self._questNpc27PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    -----------导航到第三个触发器身上
end
---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200123] = function(self, eventType, eventArgs)

    if eventType == EWorldEvent.ActorTrigger then
        ----------监听事件：Trigger是否被触发
        XLog.Debug("触发器事件：", eventArgs)
        self._triggerSceneObjectUUID = self._proxy:GetSceneObjectUUID(self._questNpc27PlaceId)
        if eventArgs.HostSceneObjectPlaceId == self._questNpc27PlaceId and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then
            ----判断角色是否触发空物体上的Trigger
            XLog.Debug("任务2001，200137，触发器事件，trigger：" .. tostring(eventArgs.HostSceneObjectPlaceId) .. "，Player：" .. tostring(self._EnteredActorUUID))
            self._proxy:DestroySceneObject(self._triggerSceneObjectUUID)
            -----销毁这个空物件
            self._proxy:RemoveQuestNavPoint(self._id, self._step21questNPC1NavPointId)
            -----移除导航点
            self._proxy:PlayDrama(self._id, nil, "Drama200118", self._emptyVector3, self._dramaRot)--------播放剧情卡列后援团！
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama200118" then
            self._proxy:PushQuestStepProcess(self._id, 200123, 2001231, 1)--------推进任务步骤
        end
    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200123] = function(self)


end


--endregion ========================[[ 步骤23]]=============================<<

--region ========================[ 步骤24]=============================>>和书店主人短信对话

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200124] = function(self)
    self._proxy:SendChatMessage(200106)------记得写一条临时的短信

end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200124] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.ShortMessageReadComplete then
        if eventArgs.MessageId == (200106) then
            self._proxy:PushQuestStepProcess(self._id, 200124, 2001241, 1)
            --------推进任务步骤
            self._proxy:LoadLevelNpc(self._questNpc6PlaceId)------加载卡列

        end
    end

end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200124] = function(self)


end
--endregion ========================[[ 步骤24]]=============================<<

--region ========================[ 步骤25]=============================>>和卡列总结事态

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200125] = function(self)
    self._step23questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc6PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    -----------导航到卡列身上
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200125] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        self._questNpc6UUID = self._proxy:GetNpcUUID(self._questNpc6PlaceId)------卡列6（id）
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc6UUID then
            self._proxy:RemoveQuestNavPoint(self._id, self._step23questNPC1NavPointId)
            -----移除导航点
            self._proxy:PlayDrama(self._id, nil, "Drama200119", self._emptyVector3, self._dramaRot)--------播放剧情
        end

    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama200119" then
            self._proxy:PushQuestStepProcess(self._id, 200125, 2001251, 1)--------推进任务步骤

        end
    end

end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200125] = function(self)


end
--endregion ========================[[ 步骤25]]=============================<<

--region ========================[[ 步骤26]=============================>>

---@param self XQuestScript2001
XQuestScript2001.StepEnterFuncs[200126] = function(self)
    self._proxy:SetActorInQuest(2001, self._questNpc2UUID, false)
    -------解除赛利卡的占用
    self._step26questNPC1NavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc2PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    -----------导航到塞利卡上
end

---@param self XQuestScript2001
XQuestScript2001.StepHandleEventFuncs[200126] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.ConditionCheckTrigger then
        ----------监听事件：条件达成
        XLog.Debug("条件监听事件：", eventArgs)
        if eventArgs.ConditionType == 20201001 and self._proxy:CheckSystemCondition(50000003) then
            ------判断条件（等玩法给新的）
            XLog.Debug("条件类型：" .. tostring(eventArgs.ConditionType) .. "条件id" .. tostring(eventArgs.ConditionType))
            self._proxy:PushQuestStepProcess(self._id, 200126, 2001261, 1)--------推进任务步骤
        end
    elseif eventType == EWorldEvent.EnterLevel and self._proxy:CheckSystemCondition(50000003) then
        -----判断玩家加载入40001 以及完成了玩法条件
        if eventArgs.IsPlayer and eventArgs.LevelId == 4001 then
            self._proxy:PushQuestStepProcess(self._id, 200126, 2001261, 1)
            --------推进任务步骤--容错
            self._proxy:RemoveQuestNavPoint(self._id, self._step26questNPC1NavPointId)-----移除导航点
        end

    end
end

---@param self XQuestScript2001
XQuestScript2001.StepExitFuncs[200126] = function(self)

end
--endregion ========================[[ 步骤26]]=============================<<