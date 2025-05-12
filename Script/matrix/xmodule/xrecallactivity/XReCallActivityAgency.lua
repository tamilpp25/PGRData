---@class XReCallActivityAgency : XAgency
---@field private _Model XReCallActivityModel
local XReCallActivityAgency = XClass(XAgency, "XReCallActivityAgency")

function XReCallActivityAgency:OnInit()
    --初始化一些变量
end

function XReCallActivityAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyHoldRegressionData = Handler(self, self.OnNotifyHoldRegressionData)
    XRpc.NotifyHoldRegressionTaskInfo = Handler(self, self.OnNotifyHoldRegressionTaskInfo)
    XRpc.NotifyHoldRegressionIgnoreChannel = Handler(self, self.OnNotifyHoldRegressionIgnoreChannel)
end

function XReCallActivityAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XReCallActivityAgency:OnNotifyHoldRegressionData(data)
    if data.HoldRegressionData then
        self._Model:SetRecallData(data.HoldRegressionData)
        self._Model:UpdateTaskData(data.HoldRegressionData.InviteInfo.TaskInfos)
        self._Model:SetInviteCount(data.HoldRegressionData.InviteInfo.InviteCount)
        self._Model:SetIsGetShareReward(data.HoldRegressionData.IsGetShareReward)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_RECALL_OPEN_STATUS_UPDATE)
end

function XReCallActivityAgency:OnNotifyHoldRegressionTaskInfo(data)
    self._Model:UpdateTaskData(data.HoldRegressionInviteInfo.TaskInfos)
    self._Model:SetInviteCount(data.HoldRegressionInviteInfo.InviteCount)
    XEventManager.DispatchEvent(XEventId.EVENT_RECALL_TASK_UPDATE)
end

function XReCallActivityAgency:OnNotifyHoldRegressionIgnoreChannel(data)
    self._Model:SetIgnoreChannelIds(data.IgnoreChannelIds)
end

function XReCallActivityAgency:GetReCallTimeId()
    return self._Model:GetCurReCallTimeId()
end

function XReCallActivityAgency:GetReCallIsOpen()
    local timeId = self:GetReCallTimeId()
    if XFunctionManager.CheckInTimeByTimeId(timeId) then
        return true
    end
    return false
end

function XReCallActivityAgency:CheckIsFirstOpen()
    if self:GetReCallIsOpen() then
        return not XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "ReCallAlreadyIn"))
    else
        return false
    end
end

function XReCallActivityAgency:CheckHasReward()
    local taskData = self._Model:GetTaskData()
    for _, task in pairs(taskData) do
        if task and task.Finish and not task.isComplete then
            return true
        end
    end

    return false
end

function XReCallActivityAgency:CheckCanInvite()
    local reCallData = self._Model:GetRecallData()
    if XTool.IsTableEmpty(reCallData) then
        return false
    end
    if not self._Model:GetCurInviteInTime() then
        return false
    end
    if reCallData.IsRegression and reCallData.InviteId and reCallData.InviteId == 0 then
        return true
    end
    return false
end

return XReCallActivityAgency