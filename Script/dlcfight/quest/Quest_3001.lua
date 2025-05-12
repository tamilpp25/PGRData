local base = require("Common/XQuestBase")
---@class XQuestScript3001
local XQuestScript3001 = XDlcScriptManager.RegQuestStepScript(3001, "XQuestScript3001", base)

---@param proxy StatusSyncFight.XFightScriptProxy
function XQuestScript3001:Ctor(proxy)
    self._id = 3001
    self._treasure1PlaceId = 100120-----宝箱
    self._questNpc2PlaceId = 1------终点的NPC
end

function XQuestScript3001:Init()
    --任务初始化
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.EnterLevel)
end

function XQuestScript3001:Terminate()
    --任务结束
    --事件监听解除
    --容器清空
end

--===================[[ 任务步骤]]
--region ========================[[ 步骤1 ]]=============================>>
---@param self XQuestScript3001
XQuestScript3001.StepEnterFuncs[300101] = function(self)
    self._proxy:PushQuestStepProcess(self._id, 300101, 3001011, 1)
    XLog.Debug("任务3001 300101 进入")
end

---@param self XQuestScript3001
XQuestScript3001.StepHandleEventFuncs[300101] = function(self, eventType, eventArgs)
    
end
---@param self XQuestScript3001
XQuestScript3001.StepExitFuncs[300101] = function(self)

end
--endregion ========================[[ 步骤1 ]]=============================<<

--region ========================[[ 步骤2]]=============================>>
---@param self XQuestScript3001
XQuestScript3001.StepEnterFuncs[300102] = function(self)

end

---@param self XQuestScript3001
XQuestScript3001.StepHandleEventFuncs[300102] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart and self._proxy:GetCurrentLevelId() == 4008 then   -----和终点辅助机交互时完成该任务
        self._questNpc2UUID = self._proxy:GetNpcUUID(self._questNpc2PlaceId)
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc2UUID then
            self._proxy:PushQuestStepProcess(self._id, 300102, 3001021, 1)
        end
    end
end

---@param self XQuestScript3001
XQuestScript3001.StepExitFuncs[300102] = function(self)

end
--endregion ========================[[ 步骤2 ]]=============================<<

--region ========================[[ 步骤3 ]]=============================>>
---@param self XQuestScript3001
XQuestScript3001.StepEnterFuncs[300103] = function(self)
    
end
---@param self XQuestScript3001
XQuestScript3001.StepHandleEventFuncs[300103] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.EnterLevel then -------在进4001时 加载宝箱
        self._proxy:LoadSceneObject(self._treasure1PlaceId)
    elseif eventType == EWorldEvent.NpcInteractStart then   ----------交互宝箱
        local treasureObjUUID = self._proxy:GetSceneObjectUUID(self._treasure1PlaceId)---获取UUID
        self._proxy:SetActorInQuest(self._id, treasureObjUUID, true)
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == treasureObjUUID then ----判断交互对象ID
            self._proxy:PushQuestStepProcess(self._id, 300103, 3001031, 1)
        end
    end
end

---@param self XQuestScript3001
XQuestScript3001.StepExitFuncs[300103] = function(self)
    
end
--endregion ========================[[ 步骤3 ]]=============================<<

