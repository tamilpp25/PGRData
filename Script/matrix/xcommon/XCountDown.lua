XCountDown = XCountDown or {}

XCountDown.GTimerName = {
    UrgentEvent = "UrgentEvent",
    FubenInfestorExplore = "FubenInfestorExplore",
    FubenInfestorExploreDaily = "FubenInfestorExploreDaily",
    Stronghold = "Stronghold", --超级据点活动倒计时
    KillZone = "KillZone", --杀戮无双活动倒计时
    LivWarmSoundsActivity = "LivWarmSoundsActivity", --丽芙预热音频解密倒计时
    LivWarmExActivity = "LivWarmExActivity", --丽芙预热宣发活动
    AreaWar = "AreaWar", --全服决战
    Doomsday = "Doomsday", --末日生存
}

-- 倒计时存储容器
-- bindCnt : 当前倒计时的总数
-- record : 倒计时
--   record[name] : 通过倒计时命名来记录
--   record[name].remainTime : 剩余时间
--   record[name].lastTime : 最后一次绑定时间
--   record[name].bindCnt : 单个命名绑定的倒计时的个数
--   record[name].nodeList : 记录当前名字存下的节点
-- timeHandle : 处理事件
local TimerRecord = { bindCnt = 0, record = {}, timeHandle = nil }

local function UpdateTimerRecord()
    local now = XTime.GetServerNowTimestamp()
    for _, v in pairs(TimerRecord.record) do
        if v.bindCnt > 0 and v.remainTime > 0 then
            v.remainTime = v.remainTime - (now - v.lastTime)
            v.lastTime = now
            if v.remainTime < 0 then
                v.remainTime = 0
            end
        end
    end
end

function XCountDown.CreateTimer(name, remainTime, now)
    if not TimerRecord.record[name] then
        TimerRecord.record[name] = {
            bindCnt = 0,
        }
    end
    now = now or XTime.GetServerNowTimestamp()
    TimerRecord.record[name].remainTime = remainTime
    TimerRecord.record[name].lastTime = now
end

function XCountDown.RemoveTimer(name)
    local record = TimerRecord.record[name]
    if record then
        TimerRecord.bindCnt = TimerRecord.bindCnt - record.bindCnt
        XBindTool.UnBindObj(record)
        TimerRecord.record[name] = nil
        if TimerRecord.bindCnt == 0 and TimerRecord.timeHandle then
            XScheduleManager.UnSchedule(TimerRecord.timeHandle)
            TimerRecord.timeHandle = nil
        end
    end
end

function XCountDown.GetRemainTime(name)
    local record = TimerRecord.record[name]
    if record then
        local now = XTime.GetServerNowTimestamp()
        if record.bindCnt > 0 and record.remainTime > 0 then
            record.remainTime = record.remainTime - (now - record.lastTime)
            record.lastTime = now
            if record.remainTime < 0 then
                record.remainTime = 0
            end
        end
        return record.remainTime
    else
        return 0
    end
end

function XCountDown.BindTimer(node, name, cb)
    local record = TimerRecord.record[name]
    if record then
        if not record.nodeList then
            record.nodeList = {}
        end
        table.insert(record.nodeList, node)

        if not TimerRecord.timeHandle then
            TimerRecord.timeHandle = XScheduleManager.ScheduleForever(function()
                UpdateTimerRecord()
            end, XScheduleManager.SECOND, 0)
            UpdateTimerRecord()
        end

        TimerRecord.bindCnt = TimerRecord.bindCnt + 1
        record.bindCnt = record.bindCnt + 1
        XBindTool.BindNode(node, record, "remainTime", cb, function()
            TimerRecord.bindCnt = TimerRecord.bindCnt - 1
            record.bindCnt = record.bindCnt - 1
            if TimerRecord.bindCnt == 0 then
                XScheduleManager.UnSchedule(TimerRecord.timeHandle)
                TimerRecord.timeHandle = nil
            end
        end)
    end
end

function XCountDown.UnBindTimer(curNode, name)
    XBindTool.UnBindNode(curNode)

    local record = TimerRecord.record[name]
    if not record or not record.nodeList then
        return
    end

    for i = 1, #record.nodeList do
        if record.nodeList[i] == curNode then
            TimerRecord.bindCnt = TimerRecord.bindCnt - 1
            record.bindCnt = record.bindCnt - 1
            if TimerRecord.bindCnt == 0 then
                XScheduleManager.UnSchedule(TimerRecord.timeHandle)
                TimerRecord.timeHandle = nil
            end
            table.remove(record.nodeList, i)
        end
    end
end