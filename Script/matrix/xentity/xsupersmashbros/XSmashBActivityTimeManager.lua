--===========================
--超限乱斗活动时间管理器
--模块负责：吕天元
--===========================
local XSmashBActivityTimeManager = {}
local Config
--===============
--设置活动配置
--===============
function XSmashBActivityTimeManager.SetConfig(config)
    Config = config
end
--===============
--检查当前活动是否在开放时间内
--===============
function XSmashBActivityTimeManager.CheckActivityIsInTime()
    local now = XTime.GetServerNowTimestamp()
    return (now >= XSmashBActivityTimeManager.GetActivityStartTime(Config))
    and (now < XSmashBActivityTimeManager.GetActivityEndTime(Config))
end
--===============
--获取当前活动开始时间戳(根据TimeId)
--===============
function XSmashBActivityTimeManager.GetActivityStartTime()
    return XFunctionManager.GetStartTimeByTimeId(Config.OpenTimeId)
end
--===============
--获取当前活动结束时间戳(根据TimeId)
--===============
function XSmashBActivityTimeManager.GetActivityEndTime()
    return XFunctionManager.GetEndTimeByTimeId(Config.OpenTimeId)
end
--===============
--获取当前活动剩余时间(秒)
--===============
function XSmashBActivityTimeManager.GetActivityLeftTime()
    local now = XTime.GetServerNowTimestamp()
    local endTime = XSmashBActivityTimeManager.GetActivityEndTime()
    local leftTime = endTime - now
    return leftTime
end
--================
--检查是否能进入玩法
--@return1 :是否在活动时间内(true为在活动时间内)
--@return2 :是否未开始活动(true为未开始活动)
--================
function XSmashBActivityTimeManager.CheckCanGoTo()
    local isActivityEnd, notStart = XSmashBActivityTimeManager.CheckIsEnd()
    return not isActivityEnd, notStart
end
--================
--检查玩法是否关闭(用于判断玩法入口，进入活动条件等)
--@return1 :玩法是否关闭
--@return2 :是否活动未开启
--================
function XSmashBActivityTimeManager.CheckIsEnd()
    local timeNow = XTime.GetServerNowTimestamp()
    local startTime = XSmashBActivityTimeManager.GetActivityStartTime()
    local endTime = XSmashBActivityTimeManager.GetActivityEndTime()
    local isEnd = timeNow >= endTime
    local isStart = timeNow >= startTime
    local inActivity = (not isEnd) and (isStart)
    return not inActivity, timeNow < startTime
end
return XSmashBActivityTimeManager