local XActivityInfo = XClass(nil,"XActivityInfo")

function XActivityInfo:Ctor(activityCfg)
    self.ActivityCfg = activityCfg
end

function XActivityInfo:GetId()
    return self.ActivityCfg.Id
end

function XActivityInfo:GetName()
    return self.ActivityCfg.Name
end

function XActivityInfo:GetSortId()
    return self.ActivityCfg.SortId
end

function XActivityInfo:GetIcon()
    return self.ActivityCfg.ActivityIcon
end

function XActivityInfo:GetBanner()
    return self.ActivityCfg.ActivityBanner
end

function XActivityInfo:GetDesc()
    return self.ActivityCfg.ActivityDesc
end

function XActivityInfo:GetShowItemList()
    return self.ActivityCfg.ShowItem or {}
end

function XActivityInfo:GetFunctionId()
    return self.ActivityCfg.FunctionId
end

function XActivityInfo:IsInCalendar()
    return self.ActivityCfg.IsInCalendar > 0
end

function XActivityInfo:GetSkipId()
    return self.ActivityCfg.SkipId
end

function XActivityInfo:IsInTime()
    return XFunctionManager.CheckInTimeByTimeId(self.ActivityCfg.TimeId)
end

function XActivityInfo:IsJudgeOpen()
    return XFunctionManager.DetectionFunction(self.ActivityCfg.FunctionId, true,true)
end

function XActivityInfo:GetStartTime()
    return XFunctionManager.GetStartTimeByTimeId(self.ActivityCfg.TimeId)
end

function XActivityInfo:GetEndTime()
    return XFunctionManager.GetEndTimeByTimeId(self.ActivityCfg.TimeId)
end


return XActivityInfo