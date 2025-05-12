---@class XReCallActivityControl : XControl
---@field private _Model XReCallActivityModel
local XReCallActivityControl = XClass(XControl, "XReCallActivityControl")

local METHOD_NAME = {
    InviteCode = "HoldRegressionUseInviteCodeRequest",
    TaskReward = "HoldRegressionTaskRewardRequest",
    ShareReward = "HoldRegressionShareRewardRequest"
}
function XReCallActivityControl:OnInit()
    --初始化内部变量
end

function XReCallActivityControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XReCallActivityControl:RemoveAgencyEvent()

end

function XReCallActivityControl:AutoCloseHandler(isClose)
    if isClose then
        XUiManager.TipText("CommonActivityEnd")
        XLuaUiManager.RunMain()
    end
end

function XReCallActivityControl:InviteCodeRequest(code)
    XNetwork.Call(METHOD_NAME.InviteCode, { InviteCode = code }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if #res.RewardGoodsList > 0 then
            XUiManager.OpenUiObtain(res.RewardGoodsList, nil)
        end
    end)
end

function XReCallActivityControl:TaskRewardRequest(taskId)
    XNetwork.Call(METHOD_NAME.TaskReward, { TaskId = taskId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if #res.RewardGoodsList > 0 then
            XUiManager.OpenUiObtain(res.RewardGoodsList, nil)
        end
        if res.HoldRegressionInviteInfo then
            self._Model:UpdateTaskData(res.HoldRegressionInviteInfo.TaskInfos)
            self._Model:SetInviteCount(res.HoldRegressionInviteInfo.InviteCount)
            XEventManager.DispatchEvent(XEventId.EVENT_RECALL_TASK_UPDATE)
        end
    end)
end

function XReCallActivityControl:ShareRewardRequest()
    XNetwork.Call(METHOD_NAME.ShareReward, { }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetIsGetShareReward(true)
        if #res.RewardGoodsList > 0 then
            XUiManager.OpenUiObtain(res.RewardGoodsList, nil)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_RECALL_OPEN_STATUS_UPDATE)
    end)
end

function XReCallActivityControl:GetActivityId()
    local data = self._Model:GetRecallData()
    if data then
        return data.ActivityId
    end
    return nil

end

function XReCallActivityControl:GetInviteId()
    local data = self._Model:GetRecallData()
    if data then
        return data.InviteId
    end
    return nil
end

function XReCallActivityControl:GetEndTime()
    local timeId = self._Model:GetCurReCallTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XReCallActivityControl:GetIsRegression()
    local data = self._Model:GetRecallData()
    if data then
        return data.IsRegression
    end
    return nil
end

function XReCallActivityControl:GetIsGetShareReward()
    return self._Model:GetIsGetShareReward()
end

function XReCallActivityControl:GetTaskList()
    local taskData = self._Model:GetTaskData()
    local taskList = {}
    for _,v in ipairs(taskData) do
        local timeIndex = self:GetTimeIndex(v.timeId)
        if timeIndex ~= 4 then
            v.priorityL = timeIndex
            table.insert(taskList,v)
        end
        --可领取任务置顶
        if v.Finish then
            v.priorityL = 1
        end
        --已完成的置底
        if v.isComplete then
            v.priorityL = 4
        end
    end
    table.sort(taskList, function(a, b)
        if a.priorityL ~= b.priorityL then
            return a.priorityL < b.priorityL
        end
        return a.priority < b.priority
    end)
    return taskList
end

---@desc 检查过期 到期任务还是要显示出来不过置底，index最大
function XReCallActivityControl:GetTimeIndex(timeId)
    local curTime = XTime.GetServerNowTimestamp()

    local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
    if curTime < startTime then
        return 4
    end

    if curTime > endTime then
        return 3
    end

    return 2
end

function XReCallActivityControl:GetActivityConfigById(id)
    return self._Model:GetActivityConfigById(id)
end

function XReCallActivityControl:GetRegressionChannelConfigById(id)
    return self._Model:GetRegressionChannelConfigById(id)
end

function XReCallActivityControl:GetRegressionPlatformConfigById(id)
    return self._Model:GetRegressionPlatformConfigById(id)
end

function XReCallActivityControl:GetInviteCount()
    return self._Model:GetInviteCount()
end

function XReCallActivityControl:GetIgnoreChannelIds()
    return self._Model:GetIgnoreChannelIds()
end

function XReCallActivityControl:GetCurInviteInTime()
    return self._Model:GetCurInviteInTime()
end

function XReCallActivityControl:PlayIdToHexUpper()
    return string.upper(string.format("%X", XPlayer.Id))
end

function XReCallActivityControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

return XReCallActivityControl