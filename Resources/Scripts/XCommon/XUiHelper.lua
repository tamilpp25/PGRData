local math = math
local string = string
local tonumber = tonumber
local mathFloor = math.floor
local mathCeil = math.ceil
local mathMin = math.min
local mathMax = math.max
local stringFormat = string.format
local stringSub = string.sub
local stringFind = string.find
local stringGsub = string.gsub
local tableSort = table.sort
local tableInsert = table.insert
local Vec3Lerp = CS.UnityEngine.Vector3.Lerp
local MathLerp = CS.UnityEngine.Mathf.Lerp
local CSTextManagerGetText = CS.XTextManager.GetText

local STR_MONTH = CSTextManagerGetText("Mouth")
local STR_WEEK = CSTextManagerGetText("Week")
local STR_DAY = CSTextManagerGetText("Day")
local STR_HOUR = CSTextManagerGetText("Hour")
local STR_MINUTE = CSTextManagerGetText("Minute")
local STR_SECOND = CSTextManagerGetText("Second")


local S = 60
local H = 3600
local D = 3600 * 24
local W = 3600 * 24 * 7
local M = 3600 * 24 * 30

XUiHelper = XUiHelper or {}
XUiHelper.TimeFormatType = {
    DEFAULT = 1, -- 默认时间格式（大于一天显示天数，小于一天显示xx小时xx分）
    SHOP = 1, -- 商城时间格式
    TOWER = 2, -- 爬塔时间格式
    TOWER_RANK = 3, -- 爬塔排行消耗时间格式
    CHALLENGE = 4, -- 挑战的时间
    HOSTEL = 5, -- 宿舍倒计时
    DRAW = 6, -- 抽卡倒计时
    MAIN = 7, -- 主界面系统时间
    PURCHASELB = 8, -- 礼包时间
    ONLINE_BOSS = 9, -- 联机boss
    ACTIVITY = 10, -- 活动
    MAINBATTERY = 11, -- 主界面血清剩余时间
    HEADPORTRAIT = 12, -- 头像时间
    DAILY_TASK = 13, --每日任务（显示X时X分，不足一分钟时显示一分钟）
    GUILDCD = 14, -- 公会冷却倒计时
    CHATEMOJITIMER = 15, -- 倒计时（大于一天显示天数，小于一天大于一小时显示小时，小于一小时大于一分钟显示分钟，小于一分钟大于一秒钟显示秒钟）
    ACTIVITY_LINEBREAK = 16, --日期会换行(例：10\n天)
    NieRShow = 17, --尼尔玩法显示剩余时间（汉字替换为英文字符）
    STRONGHOLD = 18, --超级据点时间格式
    TO_A_MINUTE = 19, --时间精确到分，不足一分钟时显示<1分钟，倒计时结束输出0分钟
    MOE_WAR = 20, --倒计时（大于一天显示天数，小于一天大于一小时显示小时，小于一小时大于一分钟显示分钟，小于一分钟大于一秒钟显示一分钟）
    KillZone = 21, --杀戮无双（当剩余时间大于1天时，按天显示时间，当剩余时间小于1天时，按小时显示时间，剩余时间少于1小时，也显示1小时）
    RPG_MAKER_GAME = 22, --21年端午活动，只显示天（向上取整）
    PASSPORT = 23, --战斗通行证（时间≥1天时，显示【X天XX：XX】；小于1天时间时，显示【XX：XX】；小于一分钟大于一秒钟显示一分钟）
}

XUiHelper.DelayType = {
    Second = 1,
    Minute = 2,
    Hour = 3,
    Day = 4,
}

XUiHelper.ClientConfigType = {
    String = 1,
    Float = 2,
    Int = 3,
    Bool = 4,
}

XUiHelper.TagBgPath = {
    Red = CS.XGame.ClientConfig:GetString("UiBagItemRed"),
    Yellow = CS.XGame.ClientConfig:GetString("UiBagItemYellow"),
    Blue = CS.XGame.ClientConfig:GetString("UiBagItemBlue"),
    Green = CS.XGame.ClientConfig:GetString("UiBagItemGreen"),
}

function XUiHelper.CreateTemplates(rootUi, pool, datas, ctor, template, parent, onCreate)
    for i = 1, #datas do
        local data = datas[i]
        local item

        if i <= #pool then
            item = pool[i]
        else
            local go = CS.UnityEngine.Object.Instantiate(template)
            go.transform:SetParent(parent, false)
            item = ctor(rootUi, go)
            pool[i] = item
        end

        if onCreate then
            onCreate(item, data)
        end
    end

    for i = #datas + 1, #pool do
        local item = pool[i]
        item.GameObject:SetActive(false)
    end
end

function XUiHelper.CreateScrollItem(datas, template, parent, cb, scrollstyle)
    scrollstyle = scrollstyle or XGlobalVar.ScrollViewScrollDir.ScrollDown
    local width, height = template.gameObject:GetComponent("RectTransform").rect.width, template.gameObject:GetComponent("RectTransform").rect.height

    if scrollstyle == XGlobalVar.ScrollViewScrollDir.ScrollDown then
        parent:GetComponent("RectTransform").sizeDelta = CS.UnityEngine.Vector2(0, #datas * height)
    elseif scrollstyle == XGlobalVar.ScrollViewScrollDir.ScrollRight then
        parent:GetComponent("RectTransform").sizeDelta = CS.UnityEngine.Vector2(#datas * width, 0)
    end

    for i = 1, #datas do
        local obj = CS.UnityEngine.Object.Instantiate(template)
        obj.gameObject:SetActive(true)
        if scrollstyle == XGlobalVar.ScrollViewScrollDir.ScrollDown then
            obj.transform.localPosition = CS.UnityEngine.Vector3(width / 2, -height / 2 - height * (i - 1), 0)
        elseif scrollstyle == XGlobalVar.ScrollViewScrollDir.ScrollRight then
            obj.transform.localPosition = CS.UnityEngine.Vector3(width * (i - 1), 0, 0)
        end
        obj.transform.localScale = CS.UnityEngine.Vector3(1, 1, 1)
        obj.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, 0)
        obj.transform:SetParent(parent, false)
        cb(obj, datas[i])
    end

end

function XUiHelper.TryGetComponent(transform, path, type)
    local temp = transform:Find(path)
    if temp then
        if type then
            return temp:GetComponent(type)
        else
            return temp
        end
    else
        return nil
    end
end

function XUiHelper.SetQualityIcon(rootUi, imgQuality, quality)
    local spriteName = XArrangeConfigs.GeQualityPath(quality)
    rootUi:SetUiSprite(imgQuality, spriteName)
end

function XUiHelper.GetPanelRoot(ui)
    while ui.Parent do
        ui = ui.Parent
    end
    return ui
end

------------时间相关begin------------
--==============================--
--desc: 固定的时间格式
--@second: 总秒数
--@return: 固定的时间格式
-- 时间大于1个月     则返回 X个月
-- 时间大于1周       则返回 X周
-- 时间大于1天       则返回 X天
-- 其余             则返回 XX:XX:XX
--==============================--
function XUiHelper.GetTime(second, timeFormatType)
    timeFormatType = timeFormatType and timeFormatType or XUiHelper.TimeFormatType.DEFAULT

    local month, weeks, days, hours, minutes, seconds = XUiHelper.GetTimeNumber(second)

    if timeFormatType == XUiHelper.TimeFormatType.DEFAULT then
        if month >= 1 then
            return stringFormat("%d%s", month, STR_MONTH)
        end
        if weeks >= 1 then
            return stringFormat("%d%s", weeks, STR_WEEK)
        end
        if days >= 1 then
            return stringFormat("%d%s", days, STR_DAY)
        end
        return stringFormat("%02d:%02d:%02d", hours, minutes, seconds)
    end

    if timeFormatType == XUiHelper.TimeFormatType.MAINBATTERY then
        if month >= 1 then
            return stringFormat("%d%s", month, STR_MONTH)
        end
        if weeks >= 1 then
            return stringFormat("%d%s", weeks, STR_WEEK)
        end
        if days >= 1 then
            return stringFormat("%d%s", days, STR_DAY)
        end
        if hours >= 1 then
            return stringFormat("%d%s", hours, STR_HOUR)
        end
        local notZeroMin = minutes > 0 and minutes or 1
        return stringFormat("%d%s", notZeroMin, STR_MINUTE)
    end

    if timeFormatType == XUiHelper.TimeFormatType.ACTIVITY then
        local totalDays = mathFloor(second / D)
        if totalDays >= 1 then
            return stringFormat("%d%s", totalDays, STR_DAY)
        end
        if hours >= 1 then
            return stringFormat("%d%s", hours, STR_HOUR)
        end
        if minutes >= 1 then
            return stringFormat("%d%s", minutes, STR_MINUTE)
        end
        return stringFormat("%d%s", seconds, STR_SECOND)
    end

    if timeFormatType == XUiHelper.TimeFormatType.ACTIVITY_LINEBREAK then
        local totalDays = mathFloor(second / D)
        if totalDays >= 1 then
            return stringFormat("%d\n%s", totalDays, STR_DAY)
        end
        if hours >= 1 then
            return stringFormat("%d\n%s", hours, STR_HOUR)
        end
        if minutes >= 1 then
            return stringFormat("%d\n%s", minutes, STR_MINUTE)
        end
        return stringFormat("%d\n%s", seconds, STR_SECOND)
    end

    if timeFormatType == XUiHelper.TimeFormatType.TOWER then
        return stringFormat("%d%s%02d%s%02d%s", days, STR_DAY, hours, STR_HOUR, minutes, STR_MINUTE)
    end

    if timeFormatType == XUiHelper.TimeFormatType.TOWER_RANK then
        return stringFormat("%02d%s%02d%s", minutes, STR_MINUTE, seconds, STR_SECOND)
    end

    if timeFormatType == XUiHelper.TimeFormatType.DAILY_TASK then
        if minutes < 1 and seconds > 0 then
            minutes = 1
        end

        return stringFormat("%02d%s%02d%s", hours, STR_HOUR, minutes, STR_MINUTE)
    end

    if timeFormatType == XUiHelper.TimeFormatType.CHALLENGE or timeFormatType == XUiHelper.TimeFormatType.HOSTEL then
        if month >= 1 then
            return stringFormat("%d%s", month, STR_MONTH)
        end
        if weeks >= 1 then
            return stringFormat("%d%s", weeks, STR_WEEK)
        end
        if days >= 1 then
            return stringFormat("%d%s%d%s", days, STR_DAY, hours, STR_HOUR)
        end
        return stringFormat("%02d:%02d:%02d", hours, minutes, seconds)
    end

    if timeFormatType == XUiHelper.TimeFormatType.DRAW then
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s", sumDas, STR_DAY)
        end
        if hours >= 1 then
            return stringFormat("%d%s", hours, STR_HOUR)
        end
        if minutes >= 1 then
            return stringFormat("%d%s", minutes, STR_MINUTE)
        end
        return stringFormat("%02d:%02d:%02d", hours, minutes, seconds)
    end

    if timeFormatType == XUiHelper.TimeFormatType.GUILDCD then
        return stringFormat("%01d:%02d:%02d", hours, minutes, seconds)
    end

    if timeFormatType == XUiHelper.TimeFormatType.MAIN then
        return stringFormat("%02d:%02d", hours, minutes)
    end

    if timeFormatType == XUiHelper.TimeFormatType.PURCHASELB then
        if month >= 1 or weeks >= 1 then
            local sumDas = mathFloor(second / D)
            return stringFormat("%d%s", sumDas, STR_DAY)
        end
        if days >= 1 then
            return stringFormat("%d%s%d%s", days, STR_DAY, hours, STR_HOUR)
        end
        return stringFormat("%02d:%02d:%02d", hours, minutes, seconds)
    end

    if timeFormatType == XUiHelper.TimeFormatType.ONLINE_BOSS then
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s", sumDas, STR_DAY)
        end
        if hours >= 1 then
            return stringFormat("%d%s", hours, STR_HOUR)
        end
        return stringFormat("%02d:%02d", minutes, seconds)
    end

    if timeFormatType == XUiHelper.TimeFormatType.HEADPORTRAIT then
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s", sumDas, STR_DAY)
        end

        if hours >= 1 then
            return stringFormat("%d%s", hours, STR_HOUR)
        end

        if minutes < 1 and seconds > 0 then
            minutes = 1
        end

        return stringFormat("%d%s", minutes, STR_MINUTE)
    end

    if timeFormatType == XUiHelper.TimeFormatType.CHATEMOJITIMER then
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s", sumDas, STR_DAY)
        end

        if hours >= 1 then
            return stringFormat("%d%s", hours, STR_HOUR)
        end

        if minutes < 1 and seconds > 0 then
            return stringFormat("%d%s", seconds, STR_SECOND)
        end

        return stringFormat("%d%s", minutes, STR_MINUTE)
    end

    if timeFormatType == XUiHelper.TimeFormatType.NieRShow then
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s", sumDas, "DAY")
        end

        if hours >= 1 then
            return stringFormat("%d%s", hours, "Hour")
        end

        if minutes < 1 and seconds > 0 then
            return stringFormat("%d%s", seconds, "Second")
        end

        return stringFormat("%d%s", minutes, "Minute")
    end

    if timeFormatType == XUiHelper.TimeFormatType.STRONGHOLD then
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s%d%s", sumDas, STR_DAY, hours, STR_HOUR)
        end
        return stringFormat("%02d:%02d:%02d", hours, minutes, seconds)
    end

    if timeFormatType == XUiHelper.TimeFormatType.TO_A_MINUTE then
        if days >= 1 then
            return stringFormat("%d%s%d%s%d%s", days, STR_DAY, hours, STR_HOUR, minutes, STR_MINUTE)
        end

        if hours >= 1 then
            return stringFormat("%d%s%d%s", hours, STR_HOUR, minutes, STR_MINUTE)
        end

        if minutes < 1 and seconds > 0 then
            return stringFormat("<1%s", STR_MINUTE)
        end

        return stringFormat("%d%s", minutes, STR_MINUTE)
    end

    if timeFormatType == XUiHelper.TimeFormatType.MOE_WAR then
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s", sumDas, STR_DAY)
        end

        if hours >= 1 then
            return stringFormat("%d%s", hours, STR_HOUR)
        end

        if minutes < 1 and seconds > 0 then
            minutes = 1
        end

        return stringFormat("%d%s", minutes, STR_MINUTE)
    end

    if timeFormatType == XUiHelper.TimeFormatType.KillZone then
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s", sumDas, STR_DAY)
        end

        if hours >= 1 then
            return stringFormat("%d%s", hours, STR_HOUR)
        end

        return stringFormat("%d%s", minutes, STR_MINUTE)
    end

    if timeFormatType == XUiHelper.TimeFormatType.RPG_MAKER_GAME then
        local sumDas = mathCeil(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s", sumDas, STR_DAY)
        end
        return stringFormat("%d%s", 0, STR_DAY)
    end

    if timeFormatType == XUiHelper.TimeFormatType.PASSPORT then
        if days >= 1 then
            return stringFormat("%d%s%02d:%02d", days, STR_DAY, hours, minutes)
        end

        if minutes < 1 and seconds > 0 then
            minutes = 1
        end
        return stringFormat("%02d:%02d", hours, minutes)
    end
end

function XUiHelper.GetTimeNumber(second)
    local month = mathFloor(second / M)
    local weeks = mathFloor((second % M) / W)
    local days = mathFloor((second % W) / D)
    local hours = mathFloor((second % D) / H)
    local minutes = mathFloor((second % H) / S)
    local seconds = mathFloor(second % S)

    return month, weeks, days, hours, minutes, seconds
end

function XUiHelper.GetTimeOfDelay(time, delayTime, delayType)--获取延时后的时间戳
    if delayType == XUiHelper.DelayType.Second then
        return time + delayTime
    elseif delayType == XUiHelper.DelayType.Minute then
        return time + delayTime * S
    elseif delayType == XUiHelper.DelayType.Hour then
        return time + delayTime * H
    elseif delayType == XUiHelper.DelayType.Day then
        return time + delayTime * D
    end
    return time + delayTime
end

--背包限时道具时间样式
function XUiHelper.GetBagTimeLimitTimeStrAndBg(second)
    local timeStr, bgPath

    local weeks = mathFloor(second / W)
    local days = mathFloor((second % W) / D)
    local hours = mathFloor((second % D) / H)
    local minutes = mathFloor((second % H) / S)
    if weeks >= 1 then
        timeStr = stringFormat("%d%s", weeks, STR_WEEK)
        bgPath = XUiHelper.TagBgPath.Green
    elseif days >= 1 then
        timeStr = stringFormat("%d%s", days, STR_DAY)
        bgPath = XUiHelper.TagBgPath.Yellow
    elseif hours >= 1 then
        timeStr = stringFormat("%d%s", hours, STR_HOUR)
        bgPath = XUiHelper.TagBgPath.Red
    else
        local notZeroMin = minutes > 0 and minutes or 1
        timeStr = stringFormat("%d%s", notZeroMin, STR_MINUTE)
        bgPath = XUiHelper.TagBgPath.Red
    end

    return timeStr, bgPath
end

--  length为可选参数，为要显示的长度，例如3601,1为1小时，3601,2为1小时1秒,
function XUiHelper.GetTimeDesc(second, length)
    local minute = 60
    local hour = 3600
    local day = 3600 * 24

    if second <= 0 then
        return CSTextManagerGetText("IsExpire")
    end

    if not length then
        length = 1
    end

    local desc = ""
    while length > 0 do
        if second == 0 then
            return desc
        end

        if second < minute then
            local s = mathFloor(second)
            desc = desc .. s .. CSTextManagerGetText("Second")
            second = 0
        else
            if second < hour then
                local m = mathFloor(second / minute)
                desc = desc .. m .. CSTextManagerGetText("Minute")
                second = second - m * minute
            else
                if second < day then
                    local h = mathFloor(second / hour)
                    desc = desc .. h .. CSTextManagerGetText("Hour")
                    second = second - h * hour
                else
                    local d = mathFloor(second / day)
                    desc = desc .. d .. CSTextManagerGetText("Day")
                    second = second - d * day
                end
            end
        end

        length = length - 1
        if length > 0 then
            desc = desc .. " "
        end
    end

    return desc
end

--返回X时间开启，或X时间结束，或已结束
function XUiHelper.GetInTimeDesc(startTime, endTime)
    local nowTime = XTime.GetServerNowTimestamp()
    local timeStr

    if startTime and nowTime < startTime then
        timeStr = XUiHelper.GetTime(startTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
        return CSTextManagerGetText("StartInTime", timeStr)
    end

    if endTime and nowTime < endTime then
        timeStr = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
        return CSTextManagerGetText("EndInTime", timeStr)
    end

    return CSTextManagerGetText("TimeUp")
end

--==============================--
--desc: 获取最后登录时间描述
--@time: 登录时间
--@return 最后登录时间对应描述
--==============================--
function XUiHelper.CalcLatelyLoginTime(time, nowTime)
    nowTime = nowTime or XTime.GetServerNowTimestamp()
    local minute = mathFloor((nowTime - time) / 60)
    local hourCount = mathFloor(minute / 60)
    local dayCount = mathFloor(hourCount / 24)
    local monthCount = mathFloor(dayCount / 30)

    if monthCount >= 1 then
        return monthCount .. CSTextManagerGetText("ToolMonthBefore")
    elseif dayCount >= 1 then
        return dayCount .. CSTextManagerGetText("ToolDayBrfore")
    elseif hourCount >= 1 then
        return hourCount .. CSTextManagerGetText("ToolHourBefore")
    else
        return minute .. CSTextManagerGetText("ToolMinuteBefore")
    end
end

--==============================--
--desc: 获取最后登录时间描述
--@time: 登录时间
--@defaultDay: 默认显示的天数
--@return 最后登录时间对应描述
--==============================--
function XUiHelper.CalcLatelyLoginTimeWithDefault(time, defaultDay)
    local minute = mathFloor((XTime.GetServerNowTimestamp() - time) / 60)
    local hourCount = mathFloor(minute / 60)
    local dayCount = mathFloor(hourCount / 24)

    if dayCount >= 1 then
        if defaultDay and defaultDay < dayCount then
            return defaultDay .. CSTextManagerGetText("ToolDayBrfore")
        else
            return dayCount .. CSTextManagerGetText("ToolDayBrfore")
        end
    elseif hourCount >= 1 then
        return hourCount .. CSTextManagerGetText("ToolHourBefore")
    else
        return minute .. CSTextManagerGetText("ToolMinuteBefore")
    end
end

function XUiHelper.GetRemindTime(time, now)
    now = now or XTime.GetServerNowTimestamp()
    local remindTime = time - now
    if remindTime > 86400 then
        local day = mathFloor(remindTime / 86400) + 1
        return day .. CSTextManagerGetText("Day")
    else
        local h = mathFloor(remindTime / 3600)
        local m = mathFloor((remindTime - h * 3600) / 60)
        local s = mathFloor(remindTime % 60)
        return stringFormat("%02d:%02d:%02d", h, m, s)
    end
end
------------时间相关end------------
--==============================--
--desc: Hex Color 转成 color
--@hexColor: 如:B7C4FFFF或B7C4FF
--@return: color(r, g, b, a)或color(r, g, b)
--==============================--
function XUiHelper.Hexcolor2Color(hexColor)
    local str
    str = stringSub(hexColor, 1, 2)
    local r = tonumber(str, 16) / 255
    str = stringSub(hexColor, 3, 4)
    local g = tonumber(str, 16) / 255
    str = stringSub(hexColor, 5, 6)
    local b = tonumber(str, 16) / 255
    str = stringSub(hexColor, 7, 8)
    local a = string.IsNilOrEmpty(str) and 1 or tonumber(str, 16) / 255
    return CS.UnityEngine.Color(r, g, b, a)
end

--------------------------------------
-- 将RGB Color(100, 100, 255) 转换成16进制颜色代码 #6464ff
--------------------------------------
function XUiHelper.Color2Hex(color)
    return string.format("#%.2x%.2x%.2x", color.r, color.g, color.b)
end

------------动画相关begin------------
--==============================--
--desc: 打字机动画
--@txtobj: 文本对象
--@str: 打印的字符串
--@interval: 时间间隔
--@finishcallback: 结束回调
--@return 定时器对象
--==============================--
function XUiHelper.ShowCharByTypeAnimation(txtobj, str, interval, callback, finishcallback)
    local chartab = string.CharsConvertToCharTab(str)
    local index = 1
    local timer
    txtobj.text = ""
    timer = XScheduleManager.ScheduleForever(function()
        if index > #chartab then
            XScheduleManager.UnSchedule(timer)
            if finishcallback then
                finishcallback()
            end
        else
            local char = chartab[index]
            if callback then
                callback(char)
            else
                txtobj.text = txtobj.text .. char
            end
            index = index + 1
        end
    end, interval)
    return timer
end

-- 如果是子Ui，得先定义Parent才能获取到UiAnimation组件。
--弃用
function XUiHelper.PlayAnimation(ui, name, onStart, onEnd)
    if onStart then
        onStart()
    end

    if ui.GetType and ui:GetType():ToString() == "UnityEngine.GameObject" then
        ui:PlayLegacyAnimation(name, onEnd)
    else
        ui.GameObject:PlayLegacyAnimation(name, onEnd)
    end
end

function XUiHelper.StopAnimation()
end

function XUiHelper.PlayCallback(onStart, onFinish)
    return CS.XUiAnimationManager.PlayCallback(onStart, onFinish)
end

--==============================--
--desc: 默认不会插入到全局播放列表。
--@duration: 动画时长
--@onRefresh: 刷新动作，返回值不为空或true时中断tween
--@onFinish:   结束回调
--@easeMethod: 自定义曲线函数
--@return 定时器
--==============================--
function XUiHelper.Tween(duration, onRefresh, onFinish, easeMethod)
    local startTicks = CS.XTimerManager.Ticks
    local refresh = function(timer)
        local t = (CS.XTimerManager.Ticks - startTicks) / duration / CS.System.TimeSpan.TicksPerSecond
        t = mathMin(1, t)
        t = mathMax(0, t)
        if easeMethod then
            t = easeMethod(t)
        end

        if onRefresh then
            local stop = onRefresh(t) or t == 1
            if stop then
                XScheduleManager.UnSchedule(timer)
                if onFinish then
                    onFinish()
                end
                return
            end
        end

    end
    return XScheduleManager.ScheduleForever(refresh, 0)
end

XUiHelper.EaseType = {
    Linear = 1,
    Sin = 2,
    Increase = 3, --由慢到快
}

function XUiHelper.Evaluate(easeType, t)
    if easeType == XUiHelper.EaseType.Linear then
        return t
    elseif easeType == XUiHelper.EaseType.Sin then
        return math.sin(t * math.pi / 2)
    elseif easeType == XUiHelper.EaseType.Increase then
        t = t * t
        t = mathMin(1, t)
        t = mathMax(0, t)
        return t
    end
end

function XUiHelper.DoUiMove(rectTf, tarPos, duration, easeType, cb)
    local startPos = rectTf.anchoredPosition3D
    easeType = easeType or XUiHelper.EaseType.Linear
    local timer = XUiHelper.Tween(duration, function(t)
        if not rectTf:Exist() then
            return true
        end
        rectTf.anchoredPosition3D = Vec3Lerp(startPos, tarPos, t)
    end, cb, function(t)
        return XUiHelper.Evaluate(easeType, t)
    end)
    return timer
end

function XUiHelper.DoMove(rectTf, tarPos, duration, easeType, cb)
    local startPos = rectTf.localPosition
    easeType = easeType or XUiHelper.EaseType.Linear
    local timer = XUiHelper.Tween(duration, function(t)
        if not rectTf:Exist() then
            return true
        end
        rectTf.localPosition = Vec3Lerp(startPos, tarPos, t)
    end, cb, function(t)
        return XUiHelper.Evaluate(easeType, t)
    end)
    return timer
end

function XUiHelper.DoWorldMove(rectTf, tarPos, duration, easeType, cb)
    local startPos = rectTf.position
    easeType = easeType or XUiHelper.EaseType.Linear
    local timer = XUiHelper.Tween(duration, function(t)
        if not rectTf:Exist() then
            return true
        end
        rectTf.position = Vec3Lerp(startPos, tarPos, t)
    end, cb, function(t)
        return XUiHelper.Evaluate(easeType, t)
    end)
    return timer
end

function XUiHelper.DoScale(rectTf, startScale, tarScale, duration, easeType, cb)
    easeType = easeType or XUiHelper.EaseType.Linear
    local timer = XUiHelper.Tween(duration, function(t)
        if not rectTf:Exist() then
            return true
        end
        rectTf.localScale = Vec3Lerp(startScale, tarScale, t)
    end, cb, function(t)
        return XUiHelper.Evaluate(easeType, t)
    end)
    return timer
end

function XUiHelper.DoAlpha(canvasGroup, startAlpha, tarAlpha, duration, easeType, cb)
    easeType = easeType or XUiHelper.EaseType.Linear
    local timer = XUiHelper.Tween(duration, function(t)
        if not canvasGroup:Exist() then
            return true
        end
        canvasGroup.alpha = MathLerp(startAlpha, tarAlpha, t)
    end, cb, function(t)
        return XUiHelper.Evaluate(easeType, t)
    end)
    return timer
end
------------动画相关end------------
--==============================--
--desc: 计算文本所占宽
--@textObj: 文本对象
--@return 所占宽度
--==============================--
function XUiHelper.CalcTextWidth(textObj)
    local tg = textObj.cachedTextGeneratorForLayout
    local set = textObj:GetGenerationSettings(CS.UnityEngine.Vector2.zero)
    local text = textObj.text
    return mathCeil(tg:GetPreferredWidth(text, set) / textObj.pixelsPerUnit)
end

------------首次获得弹窗Begin------------
local FirstGetIdWaitToShowList = {}
local DELAY_POPUP_UI = false

local PopSortFunc = function(a, b)
    --角色 > 装备
    if a.Type ~= b.Type then
        return a.Type == XArrangeConfigs.Types.Weapon
    end

    if a.Type == XArrangeConfigs.Types.Character then
        local aCharacter = XDataCenter.CharacterManager.GetCharacter(a.Id)
        local bCharacter = XDataCenter.CharacterManager.GetCharacter(b.Id)
        if aCharacter and bCharacter then
            --品质
            if aCharacter.Quality ~= bCharacter.Quality then
                return aCharacter.Quality > bCharacter.Quality
            end

            --优先级
            local priorityA = XCharacterConfigs.GetCharacterPriority(a.Id)
            local priorityB = XCharacterConfigs.GetCharacterPriority(b.Id)
            if priorityA ~= priorityB then
                return priorityA < priorityB
            end
        end
    end

    if a.Type == XArrangeConfigs.Types.Weapon then
        --品质
        local aQuality = XDataCenter.EquipManager.GetEquipQuality(a.Id)
        local bQuality = XDataCenter.EquipManager.GetEquipQuality(b.Id)
        if aQuality ~= bQuality then
            return aQuality > bQuality
        end

        --优先级
        local priorityA = XDataCenter.EquipManager.GetEquipPriority(a.Id)
        local priorityB = XDataCenter.EquipManager.GetEquipPriority(b.Id)
        if priorityA ~= priorityB then
            return priorityA < priorityB
        end
    end
end

function XUiHelper.PushInFirstGetIdList(id, type)
    local beginPopUi = not next(FirstGetIdWaitToShowList)

    local data = { Id = id, Type = type }
    tableInsert(FirstGetIdWaitToShowList, data)
    tableSort(FirstGetIdWaitToShowList, PopSortFunc)

    if beginPopUi and not DELAY_POPUP_UI and not XLuaUiManager.IsUiShow("UiFirstGetPopUp") then
        XLuaUiManager.Open("UiFirstGetPopUp", FirstGetIdWaitToShowList)
    end
end

function XUiHelper.SetDelayPopupFirstGet(isDelay)
    DELAY_POPUP_UI = isDelay
end

function XUiHelper.PopupFirstGet()
    if next(FirstGetIdWaitToShowList) then
        XLuaUiManager.Open("UiFirstGetPopUp", FirstGetIdWaitToShowList)
    end
end

------------首次获得弹窗End------------
function XUiHelper.RegisterClickEvent(table, component, handle, clear)

    clear = clear and true or true

    local func = function(...)
        if handle then
            handle(table, ...)
        end
    end

    CsXUiHelper.RegisterClickEvent(component, func, clear)

end

function XUiHelper.RegisterSliderChangeEvent(table, component, handle, clear)

    clear = clear and true or true

    local func = function(...)
        if handle then
            handle(table, ...)
        end
    end

    CsXUiHelper.RegisterSliderChangeEvent(component, func, clear)

end

function XUiHelper.GetToggleVal(val)
    if val == XUiToggleState.Off then
        return false
    elseif val == XUiToggleState.On then
        return true
    end
end

function XUiHelper.ReplaceWithPlayerName(str, replaceStr)
    if not str or not replaceStr then return str end
    if not stringFind(str, replaceStr) then return str end

    local playerName = XPlayer.Name
    if not playerName then return str end

    local tmpPlayerName = stringGsub(playerName, "%%", "$")
    str = stringGsub(str, replaceStr, tmpPlayerName)
    str = stringGsub(str, "%$", "%%")

    return str
end

--把大数字按照一定的规范转换成字符串
--规范：小于6位不转换，大于等于6位转换为w并保留小数点后2位
--比如 600000 返回 60w
function XUiHelper.GetLargeIntNumText(num)
    local t = type(num)
    if t == "number" then
        if num >= 100000 then
            local bigNum = num / 1000
            if math.floor(bigNum) < bigNum then
                return CS.XTextManager.GetText("ShowLargeIntNumText", string.format("%.2f", bigNum))-- 日服W转换为万(日本人能看懂万字)
            else
                return CS.XTextManager.GetText("ShowLargeIntNumText", string.format("%d", bigNum))
            end
        else
            return tostring(num)
        end
    end
end

--富文本字符串转普通文本
---@param: <color=#25BF6D>山穷水绝处回眸一遍你</color>
---@return: 山穷水绝处回眸一遍你
function XUiHelper.RichTextToTextString(str)
    if not str then return "" end
    return stringGsub(str, "%b<>", "")
end

--字符串换行符可用化
function XUiHelper.ConvertLineBreakSymbol(str)
    if not str then return "" end
    return stringGsub(str, "\\n", "\n")
end

--读取Text配置并保留换行符
function XUiHelper.ReadTextWithNewLine(text, ...)
    return stringGsub(CSTextManagerGetText(text, ...), "\\n", "\n")
end

-- 获取屏幕点击位置到指定transform的位置
function XUiHelper.GetScreenClickPosition(transform, camera)
    local screenPoint
    local platform = CS.UnityEngine.Application.platform
    if platform == CS.UnityEngine.RuntimePlatform.WindowsEditor
    or platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
        screenPoint = CS.UnityEngine.Vector2(CS.UnityEngine.Input.mousePosition.x, CS.UnityEngine.Input.mousePosition.y)
    else
        screenPoint = CS.UnityEngine.Input.GetTouch(0).position
    end
    local hasValue, v2 = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, screenPoint, camera)
    if hasValue then
        return CS.UnityEngine.Vector3(v2.x, v2.y, 0)
    else
        return CS.UnityEngine.Vector3.zero
    end
end

function XUiHelper.GetText(key, ...)
    return CS.XTextManager.GetText(key, ...)
end

function XUiHelper.GetClientConfig(key, configType)
    if configType == XUiHelper.ClientConfigType.String then
        return CS.XGame.ClientConfig:GetString(key)
    elseif configType == XUiHelper.ClientConfigType.Int then
        return CS.XGame.ClientConfig:GetInt(key)
    elseif configType == XUiHelper.ClientConfigType.Float then
        return CS.XGame.ClientConfig:GetFloat(key)
    elseif configType == XUiHelper.ClientConfigType.Bool then
        return CS.XGame.ClientConfig:GetBool(key)
    else
        return nil
    end
end

--背包道具时间（日服）
function XUiHelper.GetBagTimeStrAndBg(second)
    local timeStr
    local days = mathFloor(second / D)
    local hours = mathFloor(second / H)
    local minutes = mathFloor((second - hours * H) / S)

    if days >= 1 then
        timeStr = stringFormat("%d%s", days, STR_DAY)
    else
        local notZeroMin = minutes > 0 and minutes or 1
        timeStr = stringFormat("%d:%d", hours, notZeroMin)
    end
    return timeStr
end

function XUiHelper.TextHasBubble(textComponent, textContent)
    if not textComponent then
        XLog.Error("The Function \"TextHasBubble\" Param Must Not Be Nil")
        return
    end
    if not textContent then
        XLog.Warning("The Function \"TextHasBubble\" Param (textContent) is Nil, Maybe Cause Problem")
    end
    textComponent:SetTextEllipsis(textContent) -- 扩展方法，显示不全用省略号表示
    local textPointHandler = textComponent.gameObject:GetComponent(typeof(CS.XTextPointHandler))
    if XTool.UObjIsNil(textPointHandler) then
        textPointHandler = textComponent.gameObject:AddComponent(typeof(CS.XTextPointHandler))
    end
    textPointHandler:AddTouchBeganListener(function()
        if XLuaUiManager.IsUiShow("UiBubbleTip") then return end
        local touchData = nil
        if CS.UnityEngine.Input.touchCount > 1 then
            XLog.Debug("BubbleTip:TouchCount is "..CS.UnityEngine.Input.TouchCount)
            touchData = CS.UnityEngine.Input.GetTouch(0)
        elseif CS.UnityEngine.Input:GetMouseButtonDown(0) then
            touchData = {position = CS.UnityEngine.Vector2(CS.UnityEngine.Input.mousePosition.x, CS.UnityEngine.Input.mousePosition.y)}
        end
        if not touchData then return end
        XLuaUiManager.Open("UiBubbleTip", touchData, textContent or textComponent.text)
    end)
    textPointHandler:AddTouchEndListener(function()
        if XLuaUiManager.IsUiShow("UiBubbleTip") then
            XLuaUiManager.Close("UiBubbleTip")
        end
    end)
    textPointHandler:AddTouchCancelListener(function()
        if XLuaUiManager.IsUiShow("UiBubbleTip") then
            XLuaUiManager.Close("UiBubbleTip")
        end
    end)
end

function XUiHelper.TextHasBubble(textComponent, textContent)
    if not textComponent then
        XLog.Error("The Function \"TextHasBubble\" Param Must Not Be Nil")
        return
    end
    if not textContent then
        XLog.Warning("The Function \"TextHasBubble\" Param (textContent) is Nil, Maybe Cause Problem")
    end
    textComponent:SetTextEllipsis(textContent) -- 扩展方法，显示不全用省略号表示
    local textPointHandler = textComponent.gameObject:GetComponent(typeof(CS.XTextPointHandler))
    if XTool.UObjIsNil(textPointHandler) then
        textPointHandler = textComponent.gameObject:AddComponent(typeof(CS.XTextPointHandler))
    end
    textPointHandler:AddTouchBeganListener(function()
        if XLuaUiManager.IsUiShow("UiBubbleTip") then return end
        local touchData = nil
        if CS.UnityEngine.Input.touchCount > 1 then
            touchData = CS.UnityEngine.Input.GetTouch(0)
        elseif CS.UnityEngine.Input:GetMouseButtonDown(0) then
            touchData = {position = CS.UnityEngine.Vector2(CS.UnityEngine.Input.mousePosition.x, CS.UnityEngine.Input.mousePosition.y)}
        end
        if not touchData then return end
        XLuaUiManager.Open("UiBubbleTip", touchData, textContent or textComponent.text)
    end)
    textPointHandler:AddTouchEndListener(function()
        if XLuaUiManager.IsUiShow("UiBubbleTip") then
            XLuaUiManager.Close("UiBubbleTip")
        end
    end)
    textPointHandler:AddTouchCancelListener(function()
        if XLuaUiManager.IsUiShow("UiBubbleTip") then
            XLuaUiManager.Close("UiBubbleTip")
        end
    end)
end

function XUiHelper.GetText(key, ...)
    return CS.XTextManager.GetText(key, ...)
end

--==============================
 ---@desc text表中读到的\n会被Unity识别为\\n
 ---@content 转换内容 
 ---@return string
--==============================
function XUiHelper.ReplaceTextNewLine(content)
    return string.gsub(content, "\\n", "\n")
end
