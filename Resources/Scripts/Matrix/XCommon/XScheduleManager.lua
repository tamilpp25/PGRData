XScheduleManager = XScheduleManager or {}

local CSXScheduleManager = CS.XScheduleManager
XScheduleManager.SECOND = CSXScheduleManager.SECOND

require("XCommon/XTool")
local XTool = XTool
local IsEditor = XMain.IsEditorDebug

-- /// <summary>
-- /// 启动定时器
-- /// </summary>
-- /// <param name="handler">处理函数</param>
-- /// <param name="interval">间隔毫秒（第一次执行在间隔时间后）</param>
-- /// <param name="loop">循环次数</param>
-- /// <param name="delay">延迟毫秒</param>
-- /// <returns>定时器id</returns>
function XScheduleManager.Schedule(func, interval, loop, delay)
    local name = IsEditor and XTool.GetStackTraceName() or nil
    return CSXScheduleManager.Schedule(func, interval, loop, delay or 0, name)
end

-- /// <summary>
-- /// 启动单次定时器
-- /// </summary>
-- /// <param name="handler">处理函数</param>
-- /// <param name="delay">延迟毫秒</param>
-- /// <returns>定时器id</returns>
function XScheduleManager.ScheduleOnce(func, delay)
    local name = IsEditor and XTool.GetStackTraceName() or nil
    return CSXScheduleManager.ScheduleOnce(func, delay, name)
end

-- /// <summary>
-- /// 启动指定时间单次定时器
-- /// </summary>
-- /// <param name="handler">处理函数</param>
-- /// <param name="timeStamp">需要启动的时间</param>
-- /// <returns>定时器id</returns>
function XScheduleManager.ScheduleAtTimestamp(func, timeStamp)
    local name = IsEditor and XTool.GetStackTraceName() or nil
    local nowTime = XTime.GetServerNowTimestamp()
    if timeStamp <= nowTime then
        return
    end
    return CSXScheduleManager.ScheduleOnce(func, (timeStamp - nowTime) * XScheduleManager.SECOND, name)
end

-- /// <summary>
-- /// 启动永久定时器
-- /// </summary>
-- /// <param name="handler">处理函数</param>
-- /// <param name="interval">间隔毫秒</param>
-- /// <param name="delay">延迟毫秒</param>
-- /// <returns>定时器id</returns>
function XScheduleManager.ScheduleForever(func, interval, delay)
    local name = IsEditor and XTool.GetStackTraceName() or nil
    return CSXScheduleManager.ScheduleForever(func, interval, delay or 0, name)
end

-- /// <summary>
-- /// 取消定时器
-- /// </summary>
-- /// <param name="id">定时器id</param>
function XScheduleManager.UnSchedule(id)
    return CSXScheduleManager.UnSchedule(id)
end

-- 释放所有定时器
function XScheduleManager.UnScheduleAll()
    return CSXScheduleManager.UnScheduleAll()
end