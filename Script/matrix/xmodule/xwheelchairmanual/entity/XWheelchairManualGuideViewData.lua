---@class XWheelchairManualGuideViewData
local XWheelchairManualGuideViewData = XClass(nil, 'XWheelchairManualGuideViewData')

function XWheelchairManualGuideViewData:InitData(data)
    self.Data = data
end

function XWheelchairManualGuideViewData:InitConfig(config)
    self._Config = config
end

function XWheelchairManualGuideViewData:SetIsTimelimitActivity(isTimelimit)
    self._IsTimelimitActivity = isTimelimit
end

function XWheelchairManualGuideViewData:IsTimelimitActivity()
    return self._IsTimelimitActivity
end

function XWheelchairManualGuideViewData:HasServerData()
    return not XTool.IsTableEmpty(self.Data)
end

--region Configs
function XWheelchairManualGuideViewData:GetId()
    return self._Config.Id
end

function XWheelchairManualGuideViewData:GetSort()
    return self._Config.Sort
end

function XWheelchairManualGuideViewData:GetSkipId()
    return self._Config.SkipId
end

function XWheelchairManualGuideViewData:GetActivityIcon()
    return self._Config.ActivityIcon
end

function XWheelchairManualGuideViewData:GetName()
    return self._Config.Name
end

function XWheelchairManualGuideViewData:GetKindId()
    return self._Config.KindId
end
--endregion

--region TimelimitActivity
function XWheelchairManualGuideViewData:GetTimelimitActivityIsOpen()
    if self:GetIsInTotalTime() then
        local conditionId = self:GetConditionId()
        if not XTool.IsNumberValid(conditionId) or XConditionManager.CheckCondition(conditionId) then
            return true
        end
    end
    
    return false
end

function XWheelchairManualGuideViewData:GetIsInTotalTime()
    return XFunctionManager.CheckInTimeByTimeId(self._Config.TimeId, true)
end

function XWheelchairManualGuideViewData:GetTotalTimeId()
    return self._Config.TimeId
end

-- 获取期数列表，仅限时活动类型配置有
function XWheelchairManualGuideViewData:GetPeriodIds()
    return self._Config.PeriodIds
end

function XWheelchairManualGuideViewData:GetConditionId()
    return self._Config.ConditionId
end

function XWheelchairManualGuideViewData:GetIsHideTime()
    return self._Config.IsHideTime or false
end

-- 获取指定期数获取的道具数量
function XWheelchairManualGuideViewData:GetReceiveTemplateCount(periodId, templateId)
    if self:IsTimelimitActivity() then
        if XTool.IsTableEmpty(self.Data) or XTool.IsTableEmpty(self.Data.PeriodInfos) then
            return 0
        end

        for i1, periodInfo in pairs(self.Data.PeriodInfos) do
            if periodInfo.PeriodId == periodId then
                if not XTool.IsTableEmpty(periodInfo.GotRewards) then
                    for i2, rewardInfo in pairs(periodInfo.GotRewards) do
                        if rewardInfo.TemplateId == templateId then
                            return rewardInfo.Count
                        end
                    end
                end
            end
        end
        XLog.Error('找不到目标期数的数据', self._Config.Id)
        return 0
    else
        XLog.Error('尝试读取非限时活动的轮次数据', self._Config.Id)
    end
end

function XWheelchairManualGuideViewData:GetReceiveTemplateCounts(periodId)
    if self:IsTimelimitActivity() then
        if XTool.IsTableEmpty(self.Data) or XTool.IsTableEmpty(self.Data.PeriodInfos) then
            return
        end
        local countMap = {}
        for i1, periodInfo in pairs(self.Data.PeriodInfos) do
            if periodInfo.PeriodId == periodId then
                if not XTool.IsTableEmpty(periodInfo.GotRewards) then
                    for i2, rewardInfo in pairs(periodInfo.GotRewards) do
                        countMap[rewardInfo.TemplateId] = rewardInfo.Count
                    end
                end
            end
        end
        return countMap
    else
        XLog.Error('尝试读取非限时活动的轮次数据', self._Config.Id)
    end
end

--endregion

--region WeekActivity
function XWheelchairManualGuideViewData:GetMainId()
    return self._Config.Id
end

function XWheelchairManualGuideViewData:GetSubId()
    return self.Data and self.Data.SubId or 0
end

function XWheelchairManualGuideViewData:GetWeekActivityReceiveTemplateCounts()
    if not XTool.IsTableEmpty(self.Data.GotRewards) then
        local countMap = {}
        for i, rewardInfo in pairs(self.Data.GotRewards) do
            countMap[rewardInfo.TemplateId] = rewardInfo.Count
        end
        return countMap
    end
end
--endregion

return XWheelchairManualGuideViewData