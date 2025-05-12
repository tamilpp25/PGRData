local base = require("Common/XQuestBase")
---@class XQuestScript3002
local XQuestScript3002 = XDlcScriptManager.RegQuestStepScript(3002, "XQuestScript3002", base)

---@param proxy StatusSyncFight.XFightScriptProxy
function XQuestScript3002:Ctor(proxy)
    self._id = 3002
    self._treasure1PlaceId = 100176-----宝箱
    self._winNpc = 100001------终点的NPC
end

function XQuestScript3002:Init()
    --任务初始化
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.EnterLevel)
end

function XQuestScript3002:Terminate()
    --任务结束
    --事件监听解除
    --容器清空
end

--===================[[ 任务步骤]]
--region ========================[[ 步骤1 ]]=============================>>
---@param self XQuestScript3002
XQuestScript3002.StepEnterFuncs[300201] = function(self)
    self._proxy:PushQuestStepProcess(self._id, 300201, 3002011, 1)
    XLog.Debug("任务3002 300201 进入")
end

---@param self XQuestScript3002
XQuestScript3002.StepHandleEventFuncs[300201] = function(self, eventType, eventArgs)
    
end

---@param self XQuestScript3002
XQuestScript3002.StepExitFuncs[300201] = function(self)

end
--endregion ========================[[ 步骤1 ]]=============================<<

--region ========================[[ 步骤2]]=============================>>
---@param self XQuestScript3002
XQuestScript3002.StepEnterFuncs[300202] = function(self)
    
end

---@param self XQuestScript3002
XQuestScript3002.StepHandleEventFuncs[300202] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart and self._proxy:GetCurrentLevelId() == 4009 then   -----和终点辅助机交互时完成该任务
        self._winNpcUUID = self._proxy:GetNpcUUID(self._winNpc)
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._winNpcUUID then
            self._proxy:PushQuestStepProcess(self._id, 300202, 3002021, 1)
        end
    end
end

---@param self XQuestScript3002
XQuestScript3002.StepExitFuncs[300202] = function(self)

end
--endregion ========================[[ 步骤2 ]]=============================<<

--region ========================[[ 步骤3 ]]=============================>>
---@param self XQuestScript3002
XQuestScript3002.StepEnterFuncs[300203] = function(self)
    
end

---@param self XQuestScript3002
XQuestScript3002.StepHandleEventFuncs[300203] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.EnterLevel then -------在进4001时 加载宝箱
        self._proxy:LoadSceneObject(self._treasure1PlaceId)
    elseif eventType == EWorldEvent.NpcInteractStart then   ----------交互宝箱
        local treasureObjUUID = self._proxy:GetSceneObjectUUID(self._treasure1PlaceId)---获取UUID
        self._proxy:SetActorInQuest(self._id, treasureObjUUID, true)
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == treasureObjUUID then ----判断交互对象ID
            self._proxy:PushQuestStepProcess(self._id, 300203, 3002031, 1)
        end
    end
end

---@param self XQuestScript3002
XQuestScript3002.StepExitFuncs[300203] = function(self)

end
--endregion ========================[[ 步骤3 ]]=============================<<

