---@class XNewActivityCalendarAgency : XAgency
---@field private _Model XNewActivityCalendarModel
local XNewActivityCalendarAgency = XClass(XAgency, "XNewActivityCalendarAgency")
function XNewActivityCalendarAgency:OnInit()
    --初始化一些变量
end

function XNewActivityCalendarAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyNewActivityCalendarData = handler(self, self.NotifyNewActivityCalendarData)
    XRpc.NotifyTimeLimitActivityInfos = handler(self, self.NotifyTimeLimitActivityInfos)
    XRpc.NotifyWeekActivityInfos = handler(self, self.NotifyWeekActivityInfos)
end

function XNewActivityCalendarAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XNewActivityCalendarAgency:NotifyNewActivityCalendarData(data)
    self._Model:NotifyNewActivityCalendarData(data)
end

function XNewActivityCalendarAgency:NotifyTimeLimitActivityInfos(data)
    self._Model:NotifyTimeLimitActivityInfos(data)
end

function XNewActivityCalendarAgency:NotifyWeekActivityInfos(data)
    self._Model:NotifyWeekActivityInfos(data)
end

function XNewActivityCalendarAgency:GetIsOpen(noTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.NewActivityCalendar, false, noTips) or XUiManager.IsHideFunc then
        return false
    end
    if not self._Model.ActivityData then
        if not noTips then
            XUiManager.TipText("CommonActivityNotStart")
        end
        return false
    end
    return true
end

-- 检查是否有新活动开启(限时活动)
function XNewActivityCalendarAgency:CheckIsNewActivityOpen()
    if not self._Model.ActivityData then
        return false
    end
    local activityIds = self._Model.OpenActivityIds
    local localActivityIds = self:GetLocalActivityIds()
    for _, id in pairs(activityIds) do
        if not table.contains(localActivityIds, id) then
            return true
        end
    end
    return false
end

-- 检查周常是否是新的轮次(周常活动)
function XNewActivityCalendarAgency:CheckIsNewWeekOpen()
    if not self._Model.ActivityData then
        return false
    end
    -- 未显示入口不检查新的轮次
    if not self._Model:CheckIsShowWeekEntrance() then
        return false
    end
    local mainIds = self._Model:GetWeekEditShowMainIds()
    for _, mainId in ipairs(mainIds) do
        if self._Model:CheckMainIdWhetherMet(mainId) and not self:CheckLocalWeekEndTime(mainId) then
            return true
        end
    end
    return false
end

-- 检查在活动中是否有未领取的奖励(限时活动)
function XNewActivityCalendarAgency:CheckInActivityNotReceiveReward()
    if not self._Model.ActivityData then
        return false
    end
    local activityIds = self._Model.OpenActivityIds
    for _, activityId in pairs(activityIds) do
        local mainTemplateData = self._Model:GetTemplateData(activityId)
        if not self._Model:CheckIsAllReceiveMainTemplate(mainTemplateData) then
            return true
        end
    end
    return false
end

-- 检查在周常中是否有未领取的奖励(周常活动)
function XNewActivityCalendarAgency:CheckWeekMainIdNotReceiveReward()
    if not self._Model.ActivityData then
        return false
    end
    -- 未显示入口不检查奖励
    if not self._Model:CheckIsShowWeekEntrance() then
        return false
    end
    local mainIds = self._Model:GetWeekEditShowMainIds()
    for _, mainId in ipairs(mainIds) do
        if self._Model:CheckMainIdWhetherMet(mainId) then
            -- 不在进行中的特殊处理
            local isShowTips = self._Model:CheckWeekIsShowTips(mainId)
            local mainTemplateData = self._Model:GetWeekTemplateData(mainId)
            if not isShowTips and not self._Model:CheckIsAllReceiveMainTemplate(mainTemplateData) then
                return true
            end
        end
    end
    return false
end

-- 检查是否需要播放特效
--1、刷光特效：
--（1）大前提！只有满足这个前提，才会出现改特效：新周历内的活动还有未领取完的核心奖励
--（2）每日登录，关闭主界面所有弹窗后播放一次即可
--（3）有限时活动/常驻活动开启后，返回主界面，播放一次即可
function XNewActivityCalendarAgency:CheckIsNeedPlayEffect()
    if self:CheckIsPlayEffect() then
        return false
    end
    local isRadPoint = self:CheckActivityCalendarRadPoint()
    if isRadPoint then
        self:SaveIsPlayEffect(true)
        return true
    end
    return false
end

-- 检查是否需要显示红点
--2、摇铃动效：
--（1）大前提！只有满足这个前提，才会出现改特效：新周历内的活动还有未领取完的核心奖励
--（2）出现时机：每日登录和有新限时活动/周常活动开启
--（3）消失时机：玩家点进新周历结束
function XNewActivityCalendarAgency:CheckActivityCalendarRadPoint()
    if not self:CheckInActivityNotReceiveReward() and not self:CheckWeekMainIdNotReceiveReward() then
        return false
    end
    if not self:CheckIsDailyFirstLogin() then
        return true
    end
    if self:CheckIsNewActivityOpen() or self:CheckIsNewWeekOpen() then
        return true
    end
    return false
end

--1、有新活动开启时    提示文本【新活动开启了】
--2、有未领完核心奖励活动开启  提示文本【丰厚奖励活动】
--3、领完核心奖励且宿舍可接取委托数量 > 0 提示文本【还有日程活动未处理】
--4、领完核心奖励且宿舍可接取委托数量 = 0 提示文本【日常列表已经清空】
function XNewActivityCalendarAgency:GetMainBtnShowTextDesc()
    if self:CheckIsNewActivityOpen() or self:CheckIsNewWeekOpen() then
        return self._Model:GetClientConfig("CalendarBtnTips", 1)
    end
    if self:CheckInActivityNotReceiveReward() or self:CheckWeekMainIdNotReceiveReward() then
        return self._Model:GetClientConfig("CalendarBtnTips", 2)
    end
    if XDataCenter.DormQuestManager.GetCanAcceptQuestCount() > 0 then
        return self._Model:GetClientConfig("CalendarBtnTips", 3)
    end
    return self._Model:GetClientConfig("CalendarBtnTips", 4)
end

--region 本地信息相关

function XNewActivityCalendarAgency:GetDailyFirstLoginKey()
    local time = XTime.GetSeverTodayFreshTime()
    return string.format("NewActivityCalendarDailyFirstLogin_%s_%s", XPlayer.Id, time)
end

function XNewActivityCalendarAgency:CheckIsDailyFirstLogin()
    local key = self:GetDailyFirstLoginKey()
    local data = XSaveTool.GetData(key) or 0
    return data == 1
end

function XNewActivityCalendarAgency:SaveIsDailyFirstLogin()
    local key = self:GetDailyFirstLoginKey()
    local data = XSaveTool.GetData(key) or 0
    if data == 1 then
        return
    end
    XSaveTool.SaveData(key, 1)
end

function XNewActivityCalendarAgency:GetLocalActivityIdsKey()
    return string.format("NewActivityCalendarLocalActivityIds_%s", XPlayer.Id)
end

function XNewActivityCalendarAgency:GetLocalActivityIds()
    local key = self:GetLocalActivityIdsKey()
    return XSaveTool.GetData(key) or {}
end

function XNewActivityCalendarAgency:SaveLocalActivityIds()
    local key = self:GetLocalActivityIdsKey()
    local activityIds = self._Model.OpenActivityIds
    XSaveTool.SaveData(key, activityIds)
end

function XNewActivityCalendarAgency:GetPlayEffectKey()
    return string.format("NewActivityCalendarPlayEffect_%s", XPlayer.Id)
end

function XNewActivityCalendarAgency:CheckIsPlayEffect()
    local key = self:GetPlayEffectKey()
    local data = XSaveTool.GetData(key) or 0
    return data == 1
end

function XNewActivityCalendarAgency:SaveIsPlayEffect(value)
    local key = self:GetPlayEffectKey()
    XSaveTool.SaveData(key, value and 1 or 0)
end

function XNewActivityCalendarAgency:GetLocalWeekEndTimeKey(mainId)
    local endTime = self._Model:GetWeekEndTime(mainId)
    return string.format("NewActivityCalendarLocalWeekEndTime_%s_%s_%s", XPlayer.Id, mainId, endTime)
end

function XNewActivityCalendarAgency:CheckLocalWeekEndTime(mainId)
    local key = self:GetLocalWeekEndTimeKey(mainId)
    local data = XSaveTool.GetData(key) or 0
    return data == 1
end

function XNewActivityCalendarAgency:SaveLocalWeekEndTime()
    local mainIds = self._Model:GetWeekEditShowMainIds()
    for _, mainId in ipairs(mainIds) do
        if self._Model:CheckMainIdWhetherMet(mainId) and not self:CheckLocalWeekEndTime(mainId) then
            local key = self:GetLocalWeekEndTimeKey(mainId)
            XSaveTool.SaveData(key, 1)
        end
    end
end

--endregion

return XNewActivityCalendarAgency