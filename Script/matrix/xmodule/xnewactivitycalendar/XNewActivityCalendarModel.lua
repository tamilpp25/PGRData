local XNewActivityCalendarData = require("XModule/XNewActivityCalendar/XEntity/XNewActivityCalendarData")
--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local TableKey = {
    NewActivityCalendarActivity = { Identifier = "ActivityId" },
    NewActivityCalendarPeriod = { Identifier = "PeriodId" },
    NewActivityCalendarWeekActivity = { Identifier = "MainId" },
    NewActivityCalendarWeekReward = {},
    NewActivityCalendarKind = { DirPath = XConfigUtil.DirectoryType.Client },
    NewActivityCalendarClientConfig = { CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.String, DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key" },
}

---@class XNewActivityCalendarModel : XModel
---@field ActivityData XNewActivityCalendarData
local XNewActivityCalendarModel = XClass(XModel, "XNewActivityCalendarModel")
function XNewActivityCalendarModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("NewActivityCalendar", TableKey, XConfigUtil.CacheType.Normal)
    self._MaxShowWeekCount = 2

    -- 周常活动MainId列表
    self.WeekActivityMainIds = {}
    -- 周常活动MainId和SubId对应的奖励Id列表 Key1: MainId Key2：SubId Value: Id
    self.WeekMainIdAndSubIdToRewardId = {}
    self.IsInitWeekConfig = false

    -- 活动Id(服务端下发)
    self.OpenActivityIds = {}
    -- 工会boss结束时间
    self.CurrentGuildBossEndTime = 0

    -- 添加周常开启时间表的字段检测
    self._ConfigUtil:AddCheckerByTableKey(TableKey.NewActivityCalendarClientConfig, self.CheckWeekShowTimeIsCorrect, self)
end

function XNewActivityCalendarModel:ClearPrivate()
    --这里执行内部数据清理
end

function XNewActivityCalendarModel:ResetAll()
    --这里执行重登数据清理
    self.OpenActivityIds = {}
    self.CurrentGuildBossEndTime = 0
    self.ActivityData = nil
end

--region 服务端信息

function XNewActivityCalendarModel:NotifyNewActivityCalendarData(data)
    if not data then
        return
    end
    if not self.ActivityData then
        self.ActivityData = XNewActivityCalendarData.New()
    end
    self.OpenActivityIds = data.OpenActivityIds or {}
    self.ActivityData:NotifyNewActivityCalendarData(data.NewActivityCalendarData)
    self.CurrentGuildBossEndTime = data.CurrentGuildBossEndTime or 0
    XEventManager.DispatchEvent(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE)
end

function XNewActivityCalendarModel:NotifyTimeLimitActivityInfos(data)
    if not data or not self.ActivityData then
        return
    end
    self.ActivityData:UpdateTimeLimitActivityInfos(data.TimeLimitActivityInfos)
    XEventManager.DispatchEvent(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE)
end

function XNewActivityCalendarModel:NotifyWeekActivityInfos(data)
    if not data or not self.ActivityData then
        return
    end
    self.ActivityData:UpdateWeekActivityInfos(data.WeekActivityInfos)
    self.CurrentGuildBossEndTime = data.CurrentGuildBossEndTime or 0
    XEventManager.DispatchEvent(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE)
end

--endregion

--region CalendarActivity 相关

---@return XTableNewActivityCalendarActivity
function XNewActivityCalendarModel:GetCalendarActivityConfig(activityId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NewActivityCalendarActivity, activityId)
end

function XNewActivityCalendarModel:GetCalenderMainTimeId(activityId)
    local config = self:GetCalendarActivityConfig(activityId)
    return config and config.MainTimeId or 0
end

function XNewActivityCalendarModel:GetCalendarMainTemplateId(activityId)
    local config = self:GetCalendarActivityConfig(activityId)
    return config and config.MainTemplateId or {}
end

function XNewActivityCalendarModel:GetCalendarMainTemplateCount(activityId)
    local config = self:GetCalendarActivityConfig(activityId)
    return config and config.MainTemplateCount or {}
end

function XNewActivityCalendarModel:GetCalendarExtraItem(activityId)
    local config = self:GetCalendarActivityConfig(activityId)
    return config and config.ExtraItem or {}
end

function XNewActivityCalendarModel:GetCalendarPeriodId(activityId)
    local config = self:GetCalendarActivityConfig(activityId)
    return config and config.PeriodId or {}
end

function XNewActivityCalendarModel:GetCalenderEndTime(activityId)
    local mainTimeId = self:GetCalenderMainTimeId(activityId)
    return XFunctionManager.GetEndTimeByTimeId(mainTimeId)
end

function XNewActivityCalendarModel:CheckCalenderMainTimeId(activityId)
    local mainTimeId = self:GetCalenderMainTimeId(activityId)
    return XFunctionManager.CheckInTimeByTimeId(mainTimeId)
end

-- 检查是否是重点活动
function XNewActivityCalendarModel:CheckIsMajorActivity(activityId)
    local config = self:GetCalendarActivityConfig(activityId)
    local isMajorActivity = config and config.IsMajorActivity or 0
    return isMajorActivity == 1
end

function XNewActivityCalendarModel:GetCalendarMainTemplateSkipId(activityId)
    local config = self:GetCalendarActivityConfig(activityId)
    return config and config.SkipId or 0
end

--endregion

--region CalendarPeriod 相关

---@return XTableNewActivityCalendarPeriod
function XNewActivityCalendarModel:GetCalendarPeriodConfig(periodId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NewActivityCalendarPeriod, periodId)
end

function XNewActivityCalendarModel:GetPeriodTimeId(periodId)
    local config = self:GetCalendarPeriodConfig(periodId)
    return config and config.TimeId or 0
end

function XNewActivityCalendarModel:GetPeriodMainTemplateId(periodId)
    local config = self:GetCalendarPeriodConfig(periodId)
    return config and config.MainTemplateId or {}
end

function XNewActivityCalendarModel:GetPeriodMainTemplateCount(periodId)
    local config = self:GetCalendarPeriodConfig(periodId)
    return config and config.MainTemplateCount or {}
end

function XNewActivityCalendarModel:CheckPeriodTimeId(periodId)
    local timeId = self:GetPeriodTimeId(periodId)
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XNewActivityCalendarModel:CheckPeriodEndTime(periodId)
    local timeId = self:GetPeriodTimeId(periodId)
    local now = XTime.GetServerNowTimestamp()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    if endTime > 0 and now >= endTime then
        return true
    end
    return false
end

--endregion

function XNewActivityCalendarModel:GetKindConfig(kindId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NewActivityCalendarKind, kindId)
end

--region 限时活动奖励数据处理

-- 获取限时活动Ids（功能开启 且 活动中 且 核心奖励未领取完）
function XNewActivityCalendarModel:GetTimeLimitActivityIds()
    local activityIds = {}
    local isHasOpenedFunctionalActivity = false -- 是否存在功能开启的限时活动
    for _, activityId in pairs(self.OpenActivityIds) do
        if self:CheckCalenderMainTimeId(activityId) then
            if self:CheckIsTimeLimitActivityFunctionalOpen(activityId) then
                local mainTemplateData = self:GetTemplateData(activityId)
                if not isHasOpenedFunctionalActivity then
                    isHasOpenedFunctionalActivity = true
                end
                if not self:CheckIsAllReceiveMainTemplate(mainTemplateData) then
                    table.insert(activityIds, activityId)
                end
            end
        end
    end

    return activityIds, isHasOpenedFunctionalActivity
end

-- 判断限时活动是否受功能开放限制
function XNewActivityCalendarModel:CheckIsTimeLimitActivityFunctionalOpen(activityId)
    local skipId = self:GetCalendarMainTemplateSkipId(activityId)
    if not XTool.IsNumberValid(skipId) then
        return false
    end

    return XFunctionManager.IsCanSkip(skipId)
end

-- 获取奖励数据(活动中)
-- return 1 核心奖励 2 额外奖励
function XNewActivityCalendarModel:GetTemplateData(activityId)
    local mainTemplateData = {}
    local extraItemData = {}
    -- 总核心奖励
    local totalMainTemplateData = self:GetTotalMainTemplateData(activityId)
    -- 额外奖励
    extraItemData = self:GetExtraItemData(activityId)
    -- 已结束的时间断奖励信息
    local endItemData = {}
    local periodIds = self:GetCalendarPeriodId(activityId)
    for _, periodId in ipairs(periodIds) do
        local tempTemplateData = self:GetMainTemplateData(activityId, periodId)
        if self:CheckPeriodTimeId(periodId) then
            mainTemplateData = appendArray(mainTemplateData, tempTemplateData)
        elseif self:CheckPeriodEndTime(periodId) then
            endItemData = appendArray(endItemData, tempTemplateData)
        end
    end
    -- 合并相同的数据
    mainTemplateData = self:MergeAndSortList(mainTemplateData)
    endItemData = self:MergeAndSortList(endItemData)

    local totalTemplateDict = {}
    for _, info in ipairs(totalMainTemplateData) do
        totalTemplateDict[info.TemplateId] = info
    end
    local endItemDict = {}
    for _, info in ipairs(endItemData) do
        endItemDict[info.TemplateId] = info
    end

    -- 数据有可能会保存在已结束的时间断内 需要使用总的数量减去结束的数量（如果结束的领取数量大于配置的数量，实际的数量需要加上结束的差值）
    for _, info in ipairs(mainTemplateData) do
        local totalTemplate = totalTemplateDict[info.TemplateId]
        local endTemplate = endItemDict[info.TemplateId]
        local endLerp = 0
        local curReceiveCount = totalTemplate.ReceiveCount
        if endTemplate then
            endLerp = endTemplate.ReceiveCount - endTemplate.Count
            curReceiveCount = totalTemplate.ReceiveCount - endTemplate.ReceiveCount
        end
        if endLerp > 0 then
            curReceiveCount = curReceiveCount + endLerp
        end
        info.ReceiveCount = curReceiveCount
    end

    return mainTemplateData, extraItemData
end

-- 获取总的核心奖励
function XNewActivityCalendarModel:GetTotalMainTemplateData(activityId)
    local itemData = {}
    local mainTemplateIds = self:GetCalendarMainTemplateId(activityId)
    local mainTemplateCounts = self:GetCalendarMainTemplateCount(activityId)
    for i, id in ipairs(mainTemplateIds) do
        local count = mainTemplateCounts[i]
        local receiveCount = self.ActivityData:GetTimeLimitTotalReceiveCount(activityId, id)
        table.insert(itemData, {
            TemplateId = id,
            Count = count,
            ReceiveCount = receiveCount,
        })
    end
    table.sort(itemData, function(a, b)
        return a.TemplateId > b.TemplateId
    end)
    return itemData
end

function XNewActivityCalendarModel:GetMainTemplateData(activityId, periodId)
    local itemData = {}
    local mainTemplateIds = self:GetPeriodMainTemplateId(periodId)
    local mainTemplateCounts = self:GetPeriodMainTemplateCount(periodId)
    for i, id in ipairs(mainTemplateIds) do
        local count = mainTemplateCounts[i]
        local receiveCount = self.ActivityData:GetTimeLimitReceiveCount(activityId, periodId, id)
        table.insert(itemData, {
            TemplateId = id,
            Count = count,
            ReceiveCount = receiveCount,
        })
    end
    return itemData
end

-- 获取额外奖励
function XNewActivityCalendarModel:GetExtraItemData(activityId)
    local itemData = {}
    local extraItem = self:GetCalendarExtraItem(activityId)
    for _, id in ipairs(extraItem) do
        table.insert(itemData, {
            TemplateId = id,
            Count = 0,
            ReceiveCount = 0,
        })
    end
    return itemData
end

-- 合并数据
function XNewActivityCalendarModel:MergeAndSortList(data)
    if XTool.IsTableEmpty(data) then
        return {}
    end
    local mergeList = {}
    local mergeDict = {}
    for _, info in ipairs(data) do
        local oldData = mergeDict[info.TemplateId]
        if oldData then
            mergeDict[info.TemplateId].Count = mergeDict[info.TemplateId].Count + info.Count
            mergeDict[info.TemplateId].ReceiveCount = mergeDict[info.TemplateId].ReceiveCount + info.ReceiveCount
        else
            mergeDict[info.TemplateId] = {
                TemplateId = info.TemplateId,
                Count = info.Count,
                ReceiveCount = info.ReceiveCount,
            }
        end
    end
    for _, info in pairs(mergeDict) do
        table.insert(mergeList, info)
    end
    table.sort(mergeList, function(a, b)
        return a.TemplateId > b.TemplateId
    end)
    return mergeList
end

-- 检查核心奖励是否全部已领取
function XNewActivityCalendarModel:CheckIsAllReceiveMainTemplate(data)
    if XTool.IsTableEmpty(data) then
        return true
    end
    for _, info in pairs(data) do
        local count = info.Count - info.ReceiveCount
        if count > 0 then
            return false
        end
    end
    return true
end

--endregion

--region WeekActivity 相关

function XNewActivityCalendarModel:InitWeekConfig()
    if self.IsInitWeekConfig then
        return
    end

    local weekConfigs = self:GetCalendarWeekActivityConfigs()
    for _, config in pairs(weekConfigs) do
        table.insert(self.WeekActivityMainIds, config.MainId)
    end

    local rewardConfig = self:GetCalendarWeekRewardConfigs()
    for _, config in pairs(rewardConfig) do
        local mainId = config.MainId
        local subId = config.SubId
        if not self.WeekMainIdAndSubIdToRewardId[mainId] then
            self.WeekMainIdAndSubIdToRewardId[mainId] = {}
        end
        self.WeekMainIdAndSubIdToRewardId[mainId][subId] = config.Id
    end

    table.sort(self.WeekActivityMainIds, function(a, b)
        local sortIdA = self:GetCalendarWeekSortId(a)
        local sortIdB = self:GetCalendarWeekSortId(b)
        if sortIdA ~= sortIdB then
            return sortIdA < sortIdB
        end
        return a < b
    end)

    self.IsInitWeekConfig = true
end

function XNewActivityCalendarModel:GetWeekActivityMainIds()
    self:InitWeekConfig()
    return self.WeekActivityMainIds or {}
end

function XNewActivityCalendarModel:GetWeekMainIdAndSubIdToRewardId(mainId, subId)
    self:InitWeekConfig()
    if not self.WeekMainIdAndSubIdToRewardId[mainId] then
        XLog.Error("NewActivityCalendarWeekReward表找不到数据 mainId:", mainId)
        return
    end
    return self.WeekMainIdAndSubIdToRewardId[mainId][subId]
end

---@return XTableNewActivityCalendarWeekActivity[]
function XNewActivityCalendarModel:GetCalendarWeekActivityConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.NewActivityCalendarWeekActivity)
end

---@return XTableNewActivityCalendarWeekActivity
function XNewActivityCalendarModel:GetCalendarWeekActivityConfig(mainId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NewActivityCalendarWeekActivity, mainId)
end

function XNewActivityCalendarModel:GetCalendarWeekSortId(mainId)
    local config = self:GetCalendarWeekActivityConfig(mainId)
    return config and config.SortId or 0
end

--endregion

--region WeekReward 相关

---@return XTableNewActivityCalendarWeekReward[]
function XNewActivityCalendarModel:GetCalendarWeekRewardConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.NewActivityCalendarWeekReward)
end

---@return XTableNewActivityCalendarWeekReward
function XNewActivityCalendarModel:GetCalendarWeekRewardConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NewActivityCalendarWeekReward, id)
end

function XNewActivityCalendarModel:GetWeekMainTemplateId(id)
    local config = self:GetCalendarWeekRewardConfig(id)
    return config and config.MainTemplateId or {}
end

function XNewActivityCalendarModel:GetWeekMainTemplateCount(id)
    local config = self:GetCalendarWeekRewardConfig(id)
    return config and config.MainTemplateCount or {}
end

--endregion

--region 周常活动奖励数据处理

-- 检查是否显示周常入口
function XNewActivityCalendarModel:CheckIsShowWeekEntrance()
    -- 检查时间
    local showTime = self:GetClientConfig("CalendarWeekShowTime", 1)
    if not string.IsNilOrEmpty(showTime) then
        local now = XTime.GetServerNowTimestamp()
        local showTimestamp = XTime.ParseToTimestamp(showTime)
        -- 显示时间未到
        if XTool.IsNumberValid(showTimestamp) and now <= showTimestamp then
            return false
        end
    end

    return true
end

-- 获取周常奖励数据
function XNewActivityCalendarModel:GetWeekTemplateData(mainId)
    local subId = self.ActivityData:GetWeekSubIdByMainId(mainId)
    local rewardId = self:GetWeekMainIdAndSubIdToRewardId(mainId, subId)
    if not rewardId then
        XLog.Error("NewActivityCalendarWeekReward表找不到数据 mainId:" .. mainId .. " subId:" .. subId)
        return {}
    end
    local itemData = {}
    local mainTemplateIds = self:GetWeekMainTemplateId(rewardId)
    local mainTemplateCounts = self:GetWeekMainTemplateCount(rewardId)
    for i, id in ipairs(mainTemplateIds) do
        local count = mainTemplateCounts[i]
        local receiveCount = self.ActivityData:GetWeekReceiveCount(mainId, id)
        table.insert(itemData, {
            TemplateId = id,
            Count = count,
            ReceiveCount = receiveCount,
        })
    end
    return itemData
end

-- 获取需要显示的常驻活动的MainIds
function XNewActivityCalendarModel:GetWeekEditShowMainIds()
    local localEditInfos = self:GetWeekEditActivityInfos()
    local mainIds = {}
    if XTool.IsTableEmpty(localEditInfos) then
        mainIds = self:GetWeekActivityMainIds()
    else
        for _, editInfo in pairs(localEditInfos) do
            if editInfo.IsShow then
                mainIds[editInfo.Index] = editInfo.MainId
            end
        end
    end
    return mainIds
end

-- 检查mainId是否满足条件 1.服务端有下发 2.常驻活动显示
function XNewActivityCalendarModel:CheckMainIdWhetherMet(mainId)
    if not self:CheckMainIdHasServerData(mainId) then
        return false
    end

    if not self:CheckWeekIsShow(mainId) then
        return false
    end

    return true
end

function XNewActivityCalendarModel:CheckMainIdHasServerData(mainId)
    if not self.ActivityData then
        return false
    end

    if not self.ActivityData:CheckIsHaveMainId(mainId) then
        return false
    end

    return true
end

-- 检查周常活动有开放的（无论是否设置显示）
function XNewActivityCalendarModel:CheckHasOpenWeekActivity()
    local mainIds = self:GetWeekActivityMainIds()
    for _, mainId in pairs(mainIds) do
        if self:CheckWeekIsShow(mainId) then
            return true
        end
    end

    return false
end

--endregion

--region ClientConfig 相关

function XNewActivityCalendarModel:GetClientConfig(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NewActivityCalendarClientConfig, key)
    if not config then
        return ""
    end
    return config.Values and config.Values[index] or ""
end

function XNewActivityCalendarModel:GetMaxShowWeekCount()
    return self._MaxShowWeekCount
end

--endregion

--region 本地信息

-- 常驻活动编辑信息
function XNewActivityCalendarModel:GetWeekEditActivityInfosKey()
    return string.format("WeekEditActivityInfos_%s", XPlayer.Id)
end

-- [MainId] = {MainId,Index,IsShow}
function XNewActivityCalendarModel:GetWeekEditActivityInfos()
    local key = self:GetWeekEditActivityInfosKey()
    return XSaveTool.GetData(key) or {}
end

function XNewActivityCalendarModel:SaveWeekEditActivityInfos(data)
    if not data then
        return
    end
    local key = self:GetWeekEditActivityInfosKey()
    XSaveTool.SaveData(key, data)
end

--endregion

--region 常驻活动相关

-- 获取常驻活动的管理类
function XNewActivityCalendarModel:GetManagerByMainId(mainId)
    if mainId == XEnumConst.NewActivityCalendar.WeekMainId.BossSingle then
        -- 幻痛囚笼 FubenBossSingleData.LevelType == 0 时通知周历刷新
        return XDataCenter.FubenManagerEx.GetManager(XFubenConfigs.ChapterType.BossSingle)
    end
    if mainId == XEnumConst.NewActivityCalendar.WeekMainId.ArenaChallenge then
        -- 纷争战区 有监听系统消息
        return XDataCenter.FubenManagerEx.GetManager(XFubenConfigs.ChapterType.ARENA)
    end
    if mainId == XEnumConst.NewActivityCalendar.WeekMainId.StrongHold then
        -- 诺曼复兴战 有监听系统消息
        return XDataCenter.FubenManagerEx.GetManager(XFubenConfigs.ChapterType.Stronghold)
    end
    if mainId == XEnumConst.NewActivityCalendar.WeekMainId.Transfinite then
        -- 历战映射
        return XDataCenter.FubenManagerEx.GetManager(XFubenConfigs.ChapterType.Transfinite)
    end
    if mainId == XEnumConst.NewActivityCalendar.WeekMainId.GuildBoss then
        -- 拟真围剿 特殊处理
        return self:GetCalendarShowGuildBossData()
    end
    return nil
end

-- 检查周常是否显示
function XNewActivityCalendarModel:CheckWeekIsShow(mainId)
    local manager = self:GetManagerByMainId(mainId)
    if manager and manager.ExCheckShowInCalendar then
        return manager:ExCheckShowInCalendar()
    end
    return false
end

-- 获取周常活动倒计时描述
function XNewActivityCalendarModel:GetWeekRemainingTimeDesc(mainId)
    local manager = self:GetManagerByMainId(mainId)
    if manager and manager.ExGetCalendarRemainingTime then
        return manager:ExGetCalendarRemainingTime()
    end
    return ""
end

-- 获取周常活动结束时间
function XNewActivityCalendarModel:GetWeekEndTime(mainId)
    local manager = self:GetManagerByMainId(mainId)
    if manager and manager.ExGetCalendarEndTime then
        return manager:ExGetCalendarEndTime()
    end
    return 0
end

-- 检查周常是否显示提示信息
function XNewActivityCalendarModel:CheckWeekIsShowTips(mainId)
    local manager = self:GetManagerByMainId(mainId)
    if manager and manager.ExCheckWeekIsShowTips then
        return manager:ExCheckWeekIsShowTips()
    end
    return false
end

-- 获取周历需要的拟真围剿接口
function XNewActivityCalendarModel:GetCalendarShowGuildBossData()
    return {
        -- 获取倒计时
        ExGetCalendarRemainingTime = function()
            local endTime = self.CurrentGuildBossEndTime
            if not XTool.IsNumberValid(endTime) then
                return ""
            end
            local remainTime = endTime - XTime.GetServerNowTimestamp()
            if remainTime < 0 then
                remainTime = 0
            end
            local timeText = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.NEW_CALENDAR)
            return XUiHelper.GetText("UiNewActivityCalendarEndCountDown", timeText)
        end,
        -- 获取解锁时间
        ExGetCalendarEndTime = function()
            return self.CurrentGuildBossEndTime or 0
        end,
        -- 是否在周历里显示
        ExCheckShowInCalendar = function()
            if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Guild, nil, true) then
                return false
            end

            if not XDataCenter.GuildManager.IsJoinGuild() then
                return false
            end

            local endTime = self.CurrentGuildBossEndTime
            if XTool.IsNumberValid(endTime) and (endTime - XTime.GetServerNowTimestamp()) > 0 then
                return true
            end
            return false
        end,
    }
end

--endregion

--region 配置表检查

function XNewActivityCalendarModel:CheckWeekShowTimeIsCorrect(configs)
    local config = configs["CalendarWeekShowTime"]
    if not config then
        XLog.Error("NewActivityCalendarClientConfig里缺少CalendarWeekShowTime字段")
        return
    end
    local showTime = config.Values and config.Values[1] or ""
    if string.IsNilOrEmpty(showTime) then
        XLog.Error("NewActivityCalendarClientConfig里的CalendarWeekShowTime配置为空")
        return
    end
    local showTimestamp = XTime.ParseToTimestamp(showTime)
    local weekActivityCfg = self:GetCalendarWeekActivityConfigs()
    local maxTimestamp = 0
    for _, cfg in pairs(weekActivityCfg) do
        local refreshTime = cfg.RefreshTime
        local refreshTimestamp = XTime.ParseToTimestamp(refreshTime)
        if refreshTimestamp > maxTimestamp then
            maxTimestamp = refreshTimestamp
        end
    end
    if maxTimestamp > showTimestamp then
        XLog.Error("NewActivityCalendarClientConfig里的CalendarWeekShowTime配置错误，应该取NewActivityCalendarWeekActivity里的RefreshTime最大值")
    end
end

--endregion

return XNewActivityCalendarModel
