---@class XNewActivityCalendarControl : XControl
---@field private _Model XNewActivityCalendarModel
local XNewActivityCalendarControl = XClass(XControl, "XNewActivityCalendarControl")
function XNewActivityCalendarControl:OnInit()
    --初始化内部变量
end

function XNewActivityCalendarControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XNewActivityCalendarControl:RemoveAgencyEvent()

end

function XNewActivityCalendarControl:OnRelease()

end

--region 宿舍委托

-- 可接取委托数量=0且可领取（回归）=0且派遣中=0，隐藏宿舍委托条
function XNewActivityCalendarControl:CheckIsShowDormQuest()
    -- 检查宿舍委托等级是否有效 无效默认显示
    local isValid = XDataCenter.DormQuestManager.CheckTerminalLevelIsValid()
    if not isValid then
        return true
    end
    -- 可派遣的委托数量
    local acceptQuestCount = XDataCenter.DormQuestManager.GetCanAcceptQuestCount()
    -- 可领取（回归）, 派遣中
    local dispatchedCount, dispatchingCount = XDataCenter.DormQuestManager.GetQuestAcceptStateCount()
    return acceptQuestCount > 0 or dispatchedCount > 0 or dispatchingCount > 0
end

-- 获取委托描述
--1、委托空闲坑位数量>0，显示——可接取委托数量：空闲坑位数量*个
--2、委托空闲坑位数量=0，可领取奖励委托坑位数量>0，显示——可领取奖励的队伍数量：N
--3、委托空闲坑位数量=0，可领取奖励委托坑位数量=0，显示：正在进行的委托：N个
function XNewActivityCalendarControl:GetDormQuestDesc()
    -- 检查宿舍委托等级是否有效 无效默认显示
    local isValid = XDataCenter.DormQuestManager.CheckTerminalLevelIsValid()
    if not isValid then
        return self._Model:GetClientConfig("CalendarDormQuestDesc", 4)
    end
    -- 空闲栏位数量
    local freeTeamPosCount = XDataCenter.DormQuestManager.GetFreeTeamPosCount()
    -- 可派遣的委托数量
    local acceptQuestCount = XDataCenter.DormQuestManager.GetCanAcceptQuestCount()
    if freeTeamPosCount > 0 and acceptQuestCount > 0 then
        if acceptQuestCount >= freeTeamPosCount then
            return XUiHelper.FormatText(self._Model:GetClientConfig("CalendarDormQuestDesc", 1), freeTeamPosCount)
        else
            return XUiHelper.FormatText(self._Model:GetClientConfig("CalendarDormQuestDesc", 1), acceptQuestCount)
        end
    end
    -- 可领取（回归）, 派遣中
    local dispatchedCount, dispatchingCount = XDataCenter.DormQuestManager.GetQuestAcceptStateCount()
    if dispatchedCount > 0 then
        return XUiHelper.FormatText(self._Model:GetClientConfig("CalendarDormQuestDesc", 2), dispatchedCount)
    else
        return XUiHelper.FormatText(self._Model:GetClientConfig("CalendarDormQuestDesc", 3), dispatchingCount)
    end
end

--endregion

--region 限时活动相关

function XNewActivityCalendarControl:GetCalendarActivityConfig(activityId)
    return self._Model:GetCalendarActivityConfig(activityId)
end

function XNewActivityCalendarControl:GetCalendarSkipId(activityId)
    local config = self:GetCalendarActivityConfig(activityId)
    return config and config.SkipId or 0
end

-- 获取限时活动信息
function XNewActivityCalendarControl:GetTimeLimitActivityIds()
    local activityIds = self._Model:GetTimeLimitActivityIds()
    table.sort(activityIds, function(a, b)
        -- 重点活动
        local isMajorA = self._Model:CheckIsMajorActivity(a)
        local isMajorB = self._Model:CheckIsMajorActivity(b)
        if isMajorA ~= isMajorB then
            return isMajorA
        end
        -- 结束时间（倒计时）
        local endTimeA = self._Model:GetCalenderEndTime(a)
        local endTimeB = self._Model:GetCalenderEndTime(b)
        if endTimeA ~= endTimeB then
            return endTimeA < endTimeB
        end
        return a < b
    end)
    return activityIds
end

-- 获取限时活动奖励信息（活动中）
function XNewActivityCalendarControl:GetTimeLimitRewardItemData(activityId)
    local mainTemplateData, extraItemData = self._Model:GetTemplateData(activityId)
    -- 按照道具品质从高到低排列，若品质相同，按照ID从大到小排列
    table.sort(mainTemplateData, function(a, b)
        local goodsShowParamsA = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(a.TemplateId)
        local goodsShowParamsB = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(b.TemplateId)
        if goodsShowParamsA.Quality ~= goodsShowParamsB.Quality then
            return goodsShowParamsA.Quality > goodsShowParamsB.Quality
        end
        return a.TemplateId > b.TemplateId
    end)
    if not self._Model:CheckIsAllReceiveMainTemplate(mainTemplateData) or XTool.IsTableEmpty(extraItemData) then
        return mainTemplateData
    end
    return extraItemData
end

function XNewActivityCalendarControl:GetCalenderRemainingTime(activityId)
    local now = XTime.GetServerNowTimestamp()
    local remainingTime = self._Model:GetCalenderEndTime(activityId) - now
    if remainingTime < 0 then
        remainingTime = 0
    end
    local timeText = XUiHelper.GetTime(remainingTime, XUiHelper.TimeFormatType.NEW_CALENDAR)
    return XUiHelper.GetText("UiNewActivityCalendarEndCountDown", timeText)
end

--endregion

--region 常驻活动相关

function XNewActivityCalendarControl:GetCalendarWeekActivityConfig(mainId)
    return self._Model:GetCalendarWeekActivityConfig(mainId)
end

function XNewActivityCalendarControl:GetCalendarWeekName(mainId)
    local config = self:GetCalendarWeekActivityConfig(mainId)
    return config and config.Name or ""
end

function XNewActivityCalendarControl:GetCalendarWeekSkipId(mainId)
    local config = self:GetCalendarWeekActivityConfig(mainId)
    return config and config.SkipId or 0
end

function XNewActivityCalendarControl:GetCalendarWeekRefreshTime(mainId)
    local config = self:GetCalendarWeekActivityConfig(mainId)
    return config and config.RefreshTime or ""
end

-- 获取周常活动信息
-- maxNum 最多显示几个
function XNewActivityCalendarControl:GetWeekMainIds(maxNum)
    local data = {}
    local curNum = 0
    local mainIds = self._Model:GetWeekEditShowMainIds()
    for _, mainId in ipairs(mainIds) do
        if self._Model:CheckMainIdWhetherMet(mainId) then
            -- 不在进行中的特殊处理
            local isShowTips = self:CheckWeekIsShowTips(mainId)
            local mainTemplateData = self._Model:GetWeekTemplateData(mainId)
            if isShowTips or not self._Model:CheckIsAllReceiveMainTemplate(mainTemplateData) then
                curNum = curNum + 1
                table.insert(data, mainId)
            end
        end
        if XTool.IsNumberValid(maxNum) and curNum >= maxNum then
            break
        end
    end
    return data
end

-- 获取周常奖励信息（活动中）
function XNewActivityCalendarControl:GetWeekRewardItemData(mainId)
    local mainTemplateData = self._Model:GetWeekTemplateData(mainId)
    return mainTemplateData
end

-- 获取倒计时描述
function XNewActivityCalendarControl:GetWeekRemainingTimeDesc(mainId)
    return self._Model:GetWeekRemainingTimeDesc(mainId)
end

-- 检查周常是否显示领取的数量
function XNewActivityCalendarControl:CheckWeekIsShowReceiveCount(mainId)
    local refreshTime = self:GetCalendarWeekRefreshTime(mainId)
    if not string.IsNilOrEmpty(refreshTime) then
        local now = XTime.GetServerNowTimestamp()
        local refreshTimestamp = XTime.ParseToTimestamp(refreshTime)
        -- 刷新时间未到
        if XTool.IsNumberValid(refreshTimestamp) and now <= refreshTimestamp then
            return false
        end
    end
    return true
end

-- 检查是否显示周常入口
function XNewActivityCalendarControl:CheckIsShowWeekEntrance()
    return self._Model:CheckIsShowWeekEntrance()
end

-- 检查周常是否显示提示信息
function XNewActivityCalendarControl:CheckWeekIsShowTips(mainId)
    return self._Model:CheckWeekIsShowTips(mainId)
end

--endregion

--region 周常编辑相关

-- 获取编辑信息
function XNewActivityCalendarControl:GetWeekEditInfos()
    local localEditInfos = self._Model:GetWeekEditActivityInfos()
    local count = table.nums(localEditInfos)
    local mainIds = self._Model:GetWeekActivityMainIds()
    local infos = {}
    for _, mainId in pairs(mainIds) do
        local editInfo = localEditInfos[mainId]
        if not editInfo then
            count = count + 1
            infos[mainId] = {
                MainId = mainId,
                Index = count,
                IsShow = true
            }
        else
            infos[mainId] = XTool.Clone(editInfo)
        end
    end
    return infos
end

--endregion

function XNewActivityCalendarControl:GetKindConfig(kindId)
    return self._Model:GetKindConfig(kindId)
end

function XNewActivityCalendarControl:GetClientConfig(key, index)
    if not index then
        index = 1
    end
    return self._Model:GetClientConfig(key, index)
end

function XNewActivityCalendarControl:SaveWeekEditActivityInfos(data)
    self._Model:SaveWeekEditActivityInfos(data)
end

return XNewActivityCalendarControl
