local base = require("Common/XQuestBase")
---@class XQuestScript3003
local XQuestScript3003 = XDlcScriptManager.RegQuestStepScript(3003, "XQuestScript3003", base)

---@param proxy StatusSyncFight.XFightScriptProxy
function XQuestScript3003:Ctor(proxy)
    self._id = 3003
    self._treasure1PlaceId = 100177-----宝箱
    self._winNpc = 200001------终点的NPC
end

function XQuestScript3003:Init()
    --任务初始化
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.EnterLevel)
end

function XQuestScript3003:Terminate()
    --任务结束
    --事件监听解除
    --容器清空
end

--===================[[ 任务步骤]]
--region ========================[[ 步骤1 ]]=============================>>
---@param self XQuestScript3003
XQuestScript3003.StepEnterFuncs[300301] = function(self)
    self._proxy:PushQuestStepProcess(self._id, 300301, 3003011, 1)
    XLog.Debug("任务3003 300301 进入")
end

---@param self XQuestScript3003
XQuestScript3003.StepHandleEventFuncs[300301] = function(self, eventType, eventArgs)
    
end

---@param self XQuestScript3003
XQuestScript3003.StepExitFuncs[300301] = function(self)

end
--endregion ========================[[ 步骤1 ]]=============================<<

--region ========================[[ 步骤2 ]]=============================>>
---@param self XQuestScript3003
XQuestScript3003.StepEnterFuncs[300302] = function(self)

end

---@param self XQuestScript3003
XQuestScript3003.StepHandleEventFuncs[300302] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart and self._proxy:GetCurrentLevelId() == 4010 then   -----和终点辅助机交互时完成该任务
        self._winNpcUUID = self._proxy:GetNpcUUID(self._winNpc)
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._winNpcUUID then
            self._proxy:PushQuestStepProcess(self._id, 300302, 3003021, 1)
        end
    end
end

---@param self XQuestScript3003
XQuestScript3003.StepExitFuncs[300302] = function(self)

end
--endregion ========================[[ 步骤2 ]]=============================<<

--region ========================[[ 步骤3 ]]=============================>>
---@param self XQuestScript3003
XQuestScript3003.StepEnterFuncs[300303] = function(self)
    
end

---@param self XQuestScript3003
XQuestScript3003.StepHandleEventFuncs[300303] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.EnterLevel then -------在进4001时 加载宝箱
        self._proxy:LoadSceneObject(self._treasure1PlaceId)
    elseif eventType == EWorldEvent.NpcInteractStart then   ----------交互宝箱
        local treasureObjUUID = self._proxy:GetSceneObjectUUID(self._treasure1PlaceId)---获取UUID
        self._proxy:SetActorInQuest(self._id, treasureObjUUID, true)
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == treasureObjUUID then ----判断交互对象ID
            self._proxy:PushQuestStepProcess(self._id, 300303, 3003031, 1)
        end
    end
end

---@param self XQuestScript3003
XQuestScript3003.StepExitFuncs[300303] = function(self)

end

--endregion ========================[[ 步骤3 ]]=============================<<

