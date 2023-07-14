---@class XGoldenMinerHideTaskInfo
local XGoldenMinerHideTaskInfo = XClass(nil, "XGoldenMinerHideTaskInfo")

local Default = {
    _HideTaskId = 0,
    _FinishProgress = 0,
    _CatchValue = 0,
}

function XGoldenMinerHideTaskInfo:Ctor(hideTaskId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
    self._HideTaskId = hideTaskId
end

function XGoldenMinerHideTaskInfo:AddCurProgress()
    self._FinishProgress = self:GetCurProgress() + 1
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_HIDE_TASK, self)
end

--region Setter
function XGoldenMinerHideTaskInfo:SetCurProgress(progress)
    self._FinishProgress = progress
end

function XGoldenMinerHideTaskInfo:SetCatchValue(catchValue)
    self._CatchValue = catchValue
end
--endregion

--region Getter
function XGoldenMinerHideTaskInfo:GetId()
    return self._HideTaskId
end

function XGoldenMinerHideTaskInfo:GetCurProgress()
    return self._FinishProgress
end

function XGoldenMinerHideTaskInfo:GetCatchValue()
    return self._CatchValue
end

function XGoldenMinerHideTaskInfo:GetProgressLimit()
    return XGoldenMinerConfigs.GetHideTaskFinishProgress(self._HideTaskId)
end

function XGoldenMinerHideTaskInfo:GetType()
    return XGoldenMinerConfigs.GetHideTaskType(self._HideTaskId)
end

function XGoldenMinerHideTaskInfo:GetParams()
    return XGoldenMinerConfigs.GetHideTaskParams(self._HideTaskId)
end

function XGoldenMinerHideTaskInfo:GetTxtShowProgress()
    return self:GetCurProgress() .. "/" .. self:GetProgressLimit()
end

function XGoldenMinerHideTaskInfo:Get4Request()
    local data = {
        Id = self._HideTaskId
    }
    return data
end
--endregion

--region Checker
function XGoldenMinerHideTaskInfo:IsFinish()
    return self._FinishProgress >= self:GetProgressLimit()
end
--endregion

return XGoldenMinerHideTaskInfo