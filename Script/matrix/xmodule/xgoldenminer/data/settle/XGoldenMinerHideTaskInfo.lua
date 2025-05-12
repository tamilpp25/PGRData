---@class XGoldenMinerHideTaskInfo
local XGoldenMinerHideTaskInfo = XClass(nil, "XGoldenMinerHideTaskInfo")

function XGoldenMinerHideTaskInfo:Ctor(hideTaskId)
    ---@type XTableGoldenMinerHideTask
    self._Cfg = XMVCA.XGoldenMiner:GetCfgHideTask(hideTaskId)
    self._FinishProgress = 0
    self._CatchValue = 0
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
    return self._Cfg and self._Cfg.Id
end

function XGoldenMinerHideTaskInfo:GetCfgName()
    return self._Cfg and self._Cfg.Name
end

function XGoldenMinerHideTaskInfo:GetCfgType()
    return self._Cfg and self._Cfg.TaskType
end

function XGoldenMinerHideTaskInfo:GetCfgParams()
    return self._Cfg and self._Cfg.Params
end

function XGoldenMinerHideTaskInfo:GetCfgDesc()
    return self._Cfg and self._Cfg.Desc
end

function XGoldenMinerHideTaskInfo:GetCfgProgressLimit()
    return self._Cfg and self._Cfg.FinishProgress
end

function XGoldenMinerHideTaskInfo:GetCurProgress()
    return self._FinishProgress
end

function XGoldenMinerHideTaskInfo:GetCatchValue()
    return self._CatchValue
end

function XGoldenMinerHideTaskInfo:GetTxtShowProgress()
    return self:GetCurProgress() .. "/" .. self:GetCfgProgressLimit()
end
--endregion

--region Checker
function XGoldenMinerHideTaskInfo:IsFinish()
    return self._FinishProgress >= self:GetCfgProgressLimit()
end
--endregion

return XGoldenMinerHideTaskInfo