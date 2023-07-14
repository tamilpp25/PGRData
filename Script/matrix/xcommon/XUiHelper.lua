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
local CSVector2 = CS.UnityEngine.Vector2
local CSVector3 = CS.UnityEngine.Vector3
local CSQuaternion = CS.UnityEngine.Quaternion

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
    RPG_MAKER_GAME = 22, --谜题玩法，只显示天（向上取整）
    PASSPORT = 23, --战斗通行证（大于1天时，按天显示时间，当剩余时间小于1天时，按小时显示时间，剩余时间少于1小时，固定显示1小时）
    RPG_MAKER_GAME_MAIN = 24, --谜题玩法主界面，时间格式同活动（ACTIVITY）一致，调整了时间文字大小
    AREA_WAR_AREA_UNLOCK = 25, --全服决战区域开放倒计时：大于24H显示【xx天后开启】，小于24H显示【xx时后开启】，没有更小单位
    NEW_REGRESSION_ENTRANCE = 26, --新回归活动入口（只显示一个向上取整的时间单位，最大单位：周，最小单位：小时）
    NEW_REGRESSION = 27, --新回归活动（只显示一个向上取整的时间单位，最大单位：天，最小单位：小时）
    DOOMSDAY = 28, --模拟经营活动时间显示规则:（1）活动时间剩余>=24 小时	剩余时间精确到【天】，取整显示 （2）活动时间剩余>24 小时精确到【小时】，取整显示剩余时间小于 1 小时，仍然显示剩余 1 小时
    DOOMSDAY_STAGE = 29, --模拟经营关卡时间显示规则:精确到【天】，小于 1 天的，仍然显示 1 天
    ESCAPE_ACTIVITY = 30, --大逃杀玩法活动倒计时（大于一天显示天数，小于一天大于一小时显示小时，小于一小时大于一分钟显示分钟，小于一分钟大于一秒钟显示一分钟，返回时间和时间单位两个参数）
    ESCAPE_REMAIN_TIME = 31, --大逃杀玩法剩余通关时间（显示xx分:xx秒）
    ACTIVITY_NEW_YEAR_FUBEN = 32, -- 琥虎符福(只显示"x天"，最少1天，"天"字是黑色)
    DOUBLE_TOWER = 33,-- 动作塔防（只显示到分，最少一分钟，忽略秒）
    HOUR_MINUTE_SECOND = 34, -- 格式化时间（1:20:20/10:20）
    DAY_HOUR = 35, --大于一天显示【X天X小时】,小于一小时显示【X小时X分X秒】
    PIVOT_COMBAT = 36, --独域特攻 大于一小时则按 xx天xx小时 小于一小时  则 xx分xx秒
    Multi_Dim = 37, --多维挑战 显示xx:xx:xx,当前大于1天时小时加24
    SHOP_REFRESH = 38, -- 商店自动刷新倒计时
    MINUTE_SECOND = 39, --只显示分和秒，他转换成分。
    PLANET_RUNNING = 40, -- 行星环游记 大于一小时则按 xx天xx小时 小于一小时  则 xx分xx秒
}

XUiHelper.DelayType = {
    Second = 1,
    Minute = 2,
    Hour = 3,
    Day = 4
}

--- 时间单位
---@field Second number 秒
---@field Minute number 分
---@field Hour number 时
---@field Day number 天
---@field Week number 周
---@field Mouth number 月
XUiHelper.TimeUnit = {
    Second  = 1,
    Minute  = 2,
    Hour    = 3,
    Day     = 4,
    Week    = 5,
    Mouth   = 6
}

XUiHelper.ClientConfigType = {
    String = 1,
    Float = 2,
    Int = 3,
    Bool = 4
}

XUiHelper.TagBgPath = {
    Red = CS.XGame.ClientConfig:GetString("UiBagItemRed"),
    Yellow = CS.XGame.ClientConfig:GetString("UiBagItemYellow"),
    Blue = CS.XGame.ClientConfig:GetString("UiBagItemBlue"),
    Green = CS.XGame.ClientConfig:GetString("UiBagItemGreen")
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
            if rootUi then
                item = ctor(rootUi, go)
            else
                item = ctor(go)
            end
            
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
    local width, height =
        template.gameObject:GetComponent("RectTransform").rect.width,
        template.gameObject:GetComponent("RectTransform").rect.height

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

---@param rootUi XLuaUi
function XUiHelper.SetQualityIcon(rootUi, imgQuality, quality)
    local spriteName = XArrangeConfigs.GeQualityPath(quality)
    if rootUi then
        rootUi:SetUiSprite(imgQuality, spriteName)
    else
        imgQuality:SetSprite(spriteName)
    end
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

    if timeFormatType == XUiHelper.TimeFormatType.ACTIVITY_NEW_YEAR_FUBEN then
        local totalDays = mathFloor(second / D)
        local formatStr = "%d\n<color=#595554FF><size=25>%s</size></color>"
        if totalDays >= 1 then
            return stringFormat(formatStr, totalDays, STR_DAY)
        end
        if hours >= 1 then
            return stringFormat(formatStr, hours, STR_HOUR)
        end
        if minutes >= 1 then
            return stringFormat(formatStr, minutes, STR_MINUTE)
        end
        return stringFormat(formatStr, seconds, STR_SECOND)
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
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s", sumDas, STR_DAY)
        end

        if hours >= 1 then
            return stringFormat("%d%s", hours, STR_HOUR)
        end
        return stringFormat("%d%s", 1, STR_HOUR)
    end

    if timeFormatType == XUiHelper.TimeFormatType.NEW_REGRESSION_ENTRANCE then
        local week = mathCeil(second / W)
        if second >= W then
            return stringFormat("%d%s", week, STR_WEEK)
        end

        local day = mathCeil(second / D)
        if second >= D then
            return stringFormat("%d%s", day, STR_DAY)
        end

        local hour = mathMax(1, mathCeil(second / H))
        return stringFormat("%d%s", hour, STR_HOUR)
    end

    if timeFormatType == XUiHelper.TimeFormatType.NEW_REGRESSION then
        local day = mathCeil(second / D)
        if second >= D then
            return stringFormat("%d%s", day, STR_DAY)
        end

        local hour = mathMax(1, mathCeil(second / H))
        return stringFormat("%d%s", hour, STR_HOUR)
    end

    if timeFormatType == XUiHelper.TimeFormatType.RPG_MAKER_GAME_MAIN then
        local totalDays = mathFloor(second / D)
        if totalDays >= 1 then
            return stringFormat("%d<size=32>%s</size>", totalDays, STR_DAY)
        end
        if hours >= 1 then
            return stringFormat("%d<size=32>%s</size>", hours, STR_HOUR)
        end
        if minutes >= 1 then
            return stringFormat("%d<size=32>%s</size>", minutes, STR_MINUTE)
        end
        return stringFormat("%d<size=32>%s</size>", seconds, STR_SECOND)
    end

    if timeFormatType == XUiHelper.TimeFormatType.AREA_WAR_AREA_UNLOCK then
        local sumDas = mathCeil(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s", sumDas, STR_DAY)
        end
        if hours >= 1 then
            return stringFormat("%d%s", hours, STR_HOUR)
        end
        return stringFormat("%d%s", 1, STR_HOUR)
    end

    if timeFormatType == XUiHelper.TimeFormatType.DOOMSDAY then
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return sumDas, STR_DAY
        end
        if hours >= 1 then
            return hours, STR_HOUR
        end
        return 1, STR_HOUR
    end

    if timeFormatType == XUiHelper.TimeFormatType.DOOMSDAY_STAGE then
        local sumDas = mathFloor(second / D)
        return sumDas > 1 and sumDas or 1
    end

    if timeFormatType == XUiHelper.TimeFormatType.ESCAPE_ACTIVITY then
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return sumDas, STR_DAY
        end

        if hours >= 1 then
            return hours, STR_HOUR
        end

        if minutes < 1 and seconds > 0 then
            minutes = 1
        end

        return minutes, STR_MINUTE
    end

    if timeFormatType == XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME then
        return string.format("%02d:%02d", minutes, seconds)
    end

    if timeFormatType == XUiHelper.TimeFormatType.DOUBLE_TOWER then
        if month >= 1 then
            return stringFormat("%d%s", month, STR_MONTH)
        end
        if weeks >= 1 then
            return stringFormat("%d%s", weeks, STR_WEEK)
        end
        if days >= 1 then
            return stringFormat("%d%s", days, STR_DAY)
        end
        minutes = math.max(minutes, 1)
        return stringFormat("%02d:%02d", hours, minutes)
    end

    if timeFormatType == XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND then
        local ret = ""
        local hour = math.floor(second / H)
        second = second - hour * H
        local minute = math.floor(second / S)
        second = second - minute * S
        local second = math.floor(second % S)
        local secondStr
        if second < 10 then
            secondStr = "0".. second
        else
            secondStr = second
        end
        if hour >= 1 then
            local minuteStr
            if minute < 10 then
                minuteStr = "0" .. minute
            else
                minuteStr = minute
            end
            ret = string.format("%s:%s:%s", hour, minuteStr, secondStr)
        else
            if minute >= 1 then
                ret = string.format("%s:%s", minute, secondStr)
            else
                ret = string.format("00:%s", secondStr)
            end
        end
        return ret
    end
    
    if timeFormatType == XUiHelper.TimeFormatType.DAY_HOUR then
        local sumDas = mathFloor(second / D)
        if sumDas >= 1 then
            return stringFormat("%d%s%d%s", sumDas, STR_DAY, hours, STR_HOUR)
        end
        return stringFormat("%02d:%02d:%02d", hours, minutes, seconds)
    end

    if timeFormatType == XUiHelper.TimeFormatType.PIVOT_COMBAT then
        local totalDays = mathFloor(second / D)
        if totalDays >= 1 then
            return stringFormat("%d%s%d%s", totalDays, STR_DAY, hours, STR_HOUR)
        else
            if hours >= 1 then
                return stringFormat("%d%s", hours, STR_HOUR)
            elseif minutes >= 1 then
                return stringFormat("%d%s%d%s", minutes, STR_MINUTE, seconds, STR_SECOND)
            else
                return stringFormat("%d%s", seconds, STR_SECOND)
            end
        end
    end

    if timeFormatType == XUiHelper.TimeFormatType.Multi_Dim then
        if days >= 1 then
            hours = hours + 24
        end
        return stringFormat("%02d:%02d:%02d", hours, minutes, seconds)
    end

    if timeFormatType == XUiHelper.TimeFormatType.SHOP_REFRESH then
        if month >= 1 then
            return stringFormat("%d%s", month, STR_MONTH)
        end
        if days >= 1 or weeks >= 1 then
            local dayOfWeek = 7
            return stringFormat("%d%s", days + weeks * dayOfWeek, STR_DAY)
        end
        return stringFormat("%02d:%02d:%02d", hours, minutes, seconds)
    end

    if timeFormatType == XUiHelper.TimeFormatType.MINUTE_SECOND then
        local ret = ""
        local minute = math.floor(second / S)
        second = second - minute * S
        local second = math.floor(second % S)
        local secondStr
        if second < 10 then
            secondStr = "0".. second
        else
            secondStr = second
        end
        local minuteStr
        if minute == 0 then
            minuteStr = "00"
        elseif minute >= 10 then
            minuteStr = minute
        else
            minuteStr = "0" .. minute
        end
        ret = string.format("%s:%s", minuteStr, secondStr)
        return ret
    end

    if timeFormatType == XUiHelper.TimeFormatType.PLANET_RUNNING then
        local totalDays = mathFloor(second / D)
        if totalDays >= 1 then
            return stringFormat("%d%s%d%s", totalDays, STR_DAY, hours, STR_HOUR)
        elseif hours >= 1 then
            return stringFormat("%d%s", hours, STR_HOUR)
        elseif minutes >= 1 then
            return stringFormat("%d%s", minutes, STR_MINUTE)
        else
            return stringFormat("%d%s", seconds, STR_SECOND)
        end
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

function XUiHelper.GetTimeOfDelay(time, delayTime, delayType) --获取延时后的时间戳
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


--- 获取时间以及单位
---@param second number 秒数
---@param minUnit number 最小单位
---@param maxUnit number 最大单位
---@return table
--------------------------
function XUiHelper.GetTimeAndUnit(second, minUnit, maxUnit)
    maxUnit = maxUnit or XUiHelper.TimeUnit.Mouth
    minUnit = minUnit or XUiHelper.TimeUnit.Second

    local month = mathFloor(second / M)
    local weeks = mathFloor(second / W)
    local days = mathFloor(second / D)
    local hours = mathFloor(second / H)
    local minutes = mathFloor(second / S)
    local seconds = second
    
    local minUnitStr
    
    local function func(unit, number, str)
        if unit == minUnit then
            minUnitStr = str
        end
        if minUnit <= unit and maxUnit >= unit and number >= 1 then
            return true, number, str
        end
        return false, nil, nil
    end
    local passed, num, unitStr
    passed, num, unitStr = func(XUiHelper.TimeUnit.Mouth, month, STR_MONTH)
    if passed then
        return num, unitStr
    end

    passed, num, unitStr = func(XUiHelper.TimeUnit.Week, weeks, STR_WEEK)
    if passed then
        return num, unitStr
    end

    passed, num, unitStr = func(XUiHelper.TimeUnit.Day, days, STR_DAY)
    if passed then
        return num, unitStr
    end

    passed, num, unitStr = func(XUiHelper.TimeUnit.Hour, hours, STR_HOUR)
    if passed then
        return num, unitStr
    end

    passed, num, unitStr = func(XUiHelper.TimeUnit.Minute, minutes, STR_MINUTE)
    if passed then
        return num, unitStr
    end

    passed, num, unitStr = func(XUiHelper.TimeUnit.Second, seconds, STR_SECOND)
    if passed then
        return num, unitStr
    end
    return 1, minUnitStr
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

---@desc 将originColor的RGB转为color的RGB
---@param originColor UnityEngine.Color 初始Color
---@param color UnityEngine.Color 转换成的Color
---@return UnityEngine.Color
function XUiHelper.ConvertColorRGB(originColor, color)
    if not color or not originColor then
        return CS.UnityEngine.Color.white
    end
    originColor.r = color.r
    originColor.g = color.g
    originColor.b = color.b
    
    return originColor
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
    timer =
        XScheduleManager.ScheduleForever(
        function()
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
        end,
        interval
    )
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

-- 播放该节点下的所有粒子特效
function XUiHelper.PlayAllChildParticleSystem(transform)
    local allPs = transform:GetComponentsInChildren(typeof(CS.UnityEngine.ParticleSystem), true)
    for i = 0, allPs.Length - 1, 1 do
        local ps = allPs[i]
        ps:Play()
    end
end

--==============================--
--desc: 默认不会插入到全局播放列表。
--@duration: 动画时长(s)
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
    Increase = 3 --由慢到快
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
    local timer =
        XUiHelper.Tween(
        duration,
        function(t)
            if not rectTf:Exist() then
                return true
            end
            rectTf.anchoredPosition3D = Vec3Lerp(startPos, tarPos, t)
        end,
        cb,
        function(t)
            return XUiHelper.Evaluate(easeType, t)
        end
    )
    return timer
end

function XUiHelper.DoMove(rectTf, tarPos, duration, easeType, cb)
    local startPos = rectTf.localPosition
    easeType = easeType or XUiHelper.EaseType.Linear
    local timer =
        XUiHelper.Tween(
        duration,
        function(t)
            if not rectTf:Exist() then
                return true
            end
            rectTf.localPosition = Vec3Lerp(startPos, tarPos, t)
        end,
        cb,
        function(t)
            return XUiHelper.Evaluate(easeType, t)
        end
    )
    return timer
end

function XUiHelper.DoWorldMove(rectTf, tarPos, duration, easeType, cb)
    local startPos = rectTf.position
    easeType = easeType or XUiHelper.EaseType.Linear
    local timer =
        XUiHelper.Tween(
        duration,
        function(t)
            if not rectTf:Exist() then
                return true
            end
            rectTf.position = Vec3Lerp(startPos, tarPos, t)
        end,
        cb,
        function(t)
            return XUiHelper.Evaluate(easeType, t)
        end
    )
    return timer
end

function XUiHelper.DoScale(rectTf, startScale, tarScale, duration, easeType, cb)
    easeType = easeType or XUiHelper.EaseType.Linear
    local timer =
        XUiHelper.Tween(
        duration,
        function(t)
            if not rectTf:Exist() then
                return true
            end
            rectTf.localScale = Vec3Lerp(startScale, tarScale, t)
        end,
        cb,
        function(t)
            return XUiHelper.Evaluate(easeType, t)
        end
    )
    return timer
end

function XUiHelper.DoAlpha(canvasGroup, startAlpha, tarAlpha, duration, easeType, cb)
    easeType = easeType or XUiHelper.EaseType.Linear
    local timer =
        XUiHelper.Tween(
        duration,
        function(t)
            if not canvasGroup:Exist() then
                return true
            end
            canvasGroup.alpha = MathLerp(startAlpha, tarAlpha, t)
        end,
        cb,
        function(t)
            return XUiHelper.Evaluate(easeType, t)
        end
    )
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

    local data = {Id = id, Type = type}
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
        -- 如果包含信号数据
        if type(component) == "table" and component.SignalData then
            component.SignalData:EmitSignal("OnPressed", ...)
        end
    end

    if type(component) == "table" and component.__Source then
        CsXUiHelper.RegisterClickEvent(component.__Source, func, clear)
    else
        CsXUiHelper.RegisterClickEvent(component, func, clear)
    end
end

function XUiHelper.RegisterHelpButton(btn, helpKey, cb)
    XUiHelper.RegisterClickEvent(
        nil,
        btn,
        function()
            XUiManager.ShowHelpTip(helpKey, cb)
        end
    )
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
    if not str or not replaceStr then
        return str
    end
    if not stringFind(str, replaceStr) then
        return str
    end

    local playerName = XPlayer.Name
    if not playerName then
        return str
    end

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
            local bigNum = num / 10000
            if math.floor(bigNum) < bigNum then
                return string.format("%.2fw", bigNum)
            else
                return string.format("%dw", bigNum)
            end
        else
            return tostring(num)
        end
    end
end

--富文本字符串转普通文本
--@param: <color=#25BF6D>山穷水绝处回眸一遍你</color>
--@return: 山穷水绝处回眸一遍你
function XUiHelper.RichTextToTextString(str)
    if not str then
        return ""
    end
    return stringGsub(str, "%b<>", "")
end

--字符串换行符可用化
function XUiHelper.ConvertLineBreakSymbol(str)
    if not str then
        return ""
    end
    return stringGsub(str, "\\n", "\n")
end

--策划需求 空格字符转换行
function XUiHelper.ConvertSpaceToLineBreak(str)
    if not str then
        return ""
    end
    return stringGsub(str, "%s+", "\n")
end

--读取Text配置并保留换行符
---@return string, number
function XUiHelper.ReadTextWithNewLine(text, ...)
    return stringGsub(CSTextManagerGetText(text, ...), "\\n", "\n")
end

---@return string
function XUiHelper.ReadTextWithNewLineWithNotNumber(text, ...)
    local result, _ = XUiHelper.ReadTextWithNewLine(text, ...)
    return result
end

-- 获取屏幕点击位置到指定transform的位置
function XUiHelper.GetScreenClickPosition(transform, camera)
    local screenPoint
    local platform = CS.UnityEngine.Application.platform
    local Input = CS.UnityEngine.Input
    if platform == CS.UnityEngine.RuntimePlatform.WindowsEditor 
            or platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer 
    then
        screenPoint = CS.UnityEngine.Vector2(CS.UnityEngine.Input.mousePosition.x, CS.UnityEngine.Input.mousePosition.y)
    else
        -- 避免某些模拟器无法点击问题
        screenPoint = Input.touchCount >= 1 and Input.GetTouch(0).position or CS.UnityEngine.Vector2(Input.mousePosition.x, Input.mousePosition.y)
    end
    local hasValue, v2 =
        CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, screenPoint, camera)
    if hasValue then
        return CS.UnityEngine.Vector3(v2.x, v2.y, 0)
    else
        return CS.UnityEngine.Vector3.zero
    end
end

function XUiHelper.GetText(key, ...)
    return CS.XTextManager.GetText(key, ...)
end

---C#的string解析方法
function XUiHelper.FormatText(str, ...)
    return CS.XStringEx.Format(str, ...)
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

--clickFunc：重写点击方法
---@return XUiPanelActivityAsset
function XUiHelper.NewPanelActivityAsset(itemIds, panelGo, maxCountDic, clickFunc, canBuyItemIds)
    if panelGo == nil then
        XLog.Error("XUiHelper.NewPanelActivityAsset(itemIds, panelGo)  panelGo为nil")
        return
    end
    local assetActivityPanel = XUiPanelActivityAsset.New(panelGo)
    if clickFunc then
        assetActivityPanel.OnBtnClick = clickFunc
    end
    -- 不一一注册的话就无法同时监听到两种黑卡id
    for k, id in pairs(itemIds) do
        XDataCenter.ItemManager.AddCountUpdateListener(id, function()
            assetActivityPanel:Refresh(itemIds, canBuyItemIds, maxCountDic)
        end, assetActivityPanel)
    end
    assetActivityPanel:Refresh(itemIds, canBuyItemIds, maxCountDic)
    return assetActivityPanel
end
--===================
--通用返回，主菜单按钮控件
--rootUi : 界面Ui
--panel : TopControl面板
--onBack : 点返回键的处理(可缺省，缺省时默认操作为Close)
--onMainUi : 点主菜单的处理(可缺省， 缺省时默认操作为RunMain)
--===================
function XUiHelper.NewPanelTopControl(rootUi, panel, onBack, onMainUi)
    local TopControl = require("XUi/XUiCommon/XUiTopControl")
    return TopControl.New(rootUi, panel, onBack, onMainUi)
end

function XUiHelper.InitUiClass(obj, ui)
    obj.GameObject = ui.gameObject or ui.GameObject
    obj.Transform = ui.transform or ui.Transform
    XTool.InitUiObject(obj)
end

function XUiHelper.Instantiate(go, parent)
    return CS.UnityEngine.Object.Instantiate(go, parent)
end

function XUiHelper.Destroy(go)
    if XTool.UObjIsNil(go) then
        return
    end
    CS.UnityEngine.Object.Destroy(go)
end

function XUiHelper.GetFillAmountValue(value, maxValue)
    return maxValue == 0 and 0 or value / maxValue
end

--获取排行榜特殊排行（1,2,3）图标
local RankIcon = {
    CS.XGame.ClientConfig:GetString("BabelTowerRankIcon1"),
    CS.XGame.ClientConfig:GetString("BabelTowerRankIcon2"),
    CS.XGame.ClientConfig:GetString("BabelTowerRankIcon3")
}
function XUiHelper.GetRankIcon(rank)
    return RankIcon[rank]
end

--获取排名(百分比)
function XUiHelper.GetRankingPercentage(ranking, totalCount)
    --表示还未参与活动
    if ranking <= 0 then
        return CS.XTextManager.GetText("None")
    end
    return string.format("%s%%", math.floor((ranking / totalCount) * 100))
end

function XUiHelper.RefreshCustomizedList(container, gridGo, count, handleFunc)
    gridGo.gameObject:SetActiveEx(false)
    -- 先隐藏所有
    local childCount = container.childCount
    for i = 0, childCount - 1 do
        container:GetChild(i).gameObject:SetActiveEx(false)
    end
    -- 创建或显示相对应的数量对象
    local childrens = {}
    for i = 1, count do
        local child
        if i > childCount then
            child = XUiHelper.Instantiate(gridGo, container)
        else
            child = container:GetChild(i - 1)
        end
        table.insert(childrens, child)
    end
    -- 操作放回这里，避免根节点处理后拷贝冲突
    for i, child in ipairs(childrens) do
        child.gameObject:SetActiveEx(true)
        if handleFunc then
            handleFunc(i, child)
        end
    end
end

function XUiHelper.MarkLayoutForRebuild(transform)
    XScheduleManager.ScheduleOnce(
        function()
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(transform)
        end,
        0.1
    )
end

--根据传入两点坐标计算 连线在UI中的长度、位置与旋转，设置给RectTransform对应的sizeDelta、anchoredPosition、localRotation
---@param positionA UnityEngine.Vector3
---@param positionB UnityEngine.Vector3
function XUiHelper.CalculateLineWithTwoPosition(positionA, positionB, rotationAxis)
    local vecOffset = positionB - positionA
    local width = vecOffset.magnitude
    local position = (positionA + positionB) / 2
    local angle = CSQuaternion.Euler(CSVector2.Angle(CSVector2(1, 0), vecOffset) * rotationAxis)
    return position, width, angle
end

--==============================
 ---@desc 全角空格转为半角空格
 ---@content 转换内容 
 ---@return string
--==============================
function XUiHelper.ReplaceUnicodeSpace(content)
    return string.gsub(content, " ", "\u{00A0}")
end 

--==============================
 ---@desc text表中读到的\n会被Unity识别为\\n
 ---@content 转换内容 
 ---@return string
--==============================
function XUiHelper.ReplaceTextNewLine(content)
    return string.gsub(content, "\\n", "\n")
end

--==============================
---@desc 换行空格转换为全角空格(中文文章中使用)
---@content 实现首行缩进
---@return string
--==============================
function XUiHelper.ReplaceTextIndent(content)
    if not content then
        return ""
    end
    return stringGsub(content, " ", "\u{3000}")
end

function XUiHelper.GetStringUTF8Length(str)
    local len = #str
    local left = len
    local cnt = 0
    local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc}
    while left ~= 0 do
        local tmp=string.byte(str,-left)
        local i=#arr
        while arr[i] do
            if tmp>=arr[i] then
                left=left-i
                break
            end
            i=i-1
        end
        cnt=cnt+1
    end
    return cnt
end

function XUiHelper.DeleteOverlengthString(str, length, addSymbol)
    local len = XUiHelper.GetStringUTF8Length(str)
    if len > length then
        local addStr = not string.IsNilOrEmpty(addSymbol) and addSymbol or ""
        str = string.sub(str, 1, length * 3) .. addStr
    end
    return str
end

--- 移除字符串中最后一个指定符号(可以兼容中文符号)
---@param content string
---@param symbol string
function XUiHelper.RemoveLastSymbol(content, symbol)
    local last_symbol = content:sub(-#symbol)
    if last_symbol == symbol then
        content = content:sub(1, -#symbol - 1)
    end
    return content
end

--==============================
 ---@desc 记录一级界面按钮埋点
 ---@btnIndex 按钮下标 
--==============================
function XUiHelper.RecordBuriedSpotTypeLevelOne(btnIndex)
    local dict = {}
    dict["ui_first_button"] = btnIndex
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200004", "UiOpen")
end 

-- fixme临时的时钟设置现在2.1版本处理，后续在下版本优化再删除该方法
-- 记录目前开启了时钟的Ui UiMain/UiSceneTip/UiPhotograph/UiFavorabilityNew
local TimeStopTrans = nil --播放特殊动作时出现的带动画的transform
local TempClockFun = function (trans)
    if trans then
        TimeStopTrans = trans
    end
end
function XUiHelper.SetClockTimeTempFun(Ui)
    local panel3D = {}
    XTool.InitUiObjectByUi(panel3D, Ui.UiSceneInfo.Transform) -- 将场景的内容和镜头的内容加到1个table里
    if not panel3D.Uimc_05ClockAni3 then -- 检测是不是时钟场景
        return
    end

    panel3D.Uimc_05ClockAni.gameObject:SetActiveEx(false)
    panel3D.Uimc_05ClockAni2.gameObject:SetActiveEx(false)
    panel3D.Uimc_05ClockAni3.gameObject:SetActiveEx(true)

    local targetClock = panel3D.Uimc_05ClockAni3
    local transH = targetClock:Find("Dummy00/Bone001")
    local transM = targetClock:Find("Dummy00/Bone005")
    local transS = targetClock:Find("Dummy00/Bone003")

    XEventManager.AddEventListener(XEventId.EVENT_ACTION_HIDE_UI, TempClockFun)
    local TempV3 = Vector3(0, 0, 0) --提出临时变量，减少内存消耗

    local doSync = function ()
        local timeStamp = XTime.GetLocalNowTimestamp()
        local h = tonumber(XTime.TimestampToGameDateTimeString(timeStamp, "HH"))
        local m = tonumber(XTime.TimestampToGameDateTimeString(timeStamp, "mm"))
        local s = tonumber(XTime.TimestampToGameDateTimeString(timeStamp, "ss"))
        -- 换算为12小时制
        h = h > 12 and h - 12 or h
    
        -- 各指针角度
        local angleS = (s / 60) * 360
        local angleM = (m / 60) * 360 + angleS / 60
        local angleH = (h / 12) * 360 + angleM / 12
    
        if not XTool.UObjIsNil(TimeStopTrans) then
            local t = TimeStopTrans:GetComponent(typeof(CS.XCustomVFXTimeController))
            if t and t.TimeScale <= 0 then
                return
            end
        end
      
        -- H
        TempV3.x = transH.localEulerAngles.x
        TempV3.y = transH.localEulerAngles.y
        TempV3.z = -angleH
        transH.localEulerAngles = TempV3
        -- M
        TempV3.x = transM.localEulerAngles.x
        TempV3.y = transM.localEulerAngles.y
        TempV3.z = -angleM
        transM.localEulerAngles = TempV3
        -- S
        TempV3.x = transS.localEulerAngles.x
        TempV3.y = transS.localEulerAngles.y
        TempV3.z = -angleS
        transS.localEulerAngles = TempV3
    end

    doSync()
    local timer = XScheduleManager.ScheduleForever(function()
        doSync()
    end, XScheduleManager.SECOND, 0)

    return timer
end

-- 配套时钟停止函数(如果开启了，必须在Ui的disable调用)
function XUiHelper.StopClockTimeTempFun(Ui, timer)
    XScheduleManager.UnSchedule(timer)
    XEventManager.RemoveEventListener(XEventId.EVENT_ACTION_HIDE_UI, TempClockFun)
    TimeStopTrans = nil
end

-- 设置场景类型
function XUiHelper.SetSceneType(sceneType)
    if not sceneType then
        return
    end
    if sceneType == CS.XSceneType.Dormitory then
        XEventManager.DispatchEvent(XEventId.EVENT_SCENE_SET_NONE_STATE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_SCENE_SET_NONE_STATE)
    end
    CS.XGlobalIllumination.SetSceneType(sceneType)
end

-- xxxx年x月x日 年月日
function XUiHelper.GetTimeYearMonthDay(time)
    time = time or XTime.GetServerNowTimestamp()
    local format = string.format("yyyy%sM%sd%s", XUiHelper.GetText("Year"), XUiHelper.GetText("Monthly"), XUiHelper.GetText("Diary"))
    local timeStr = XTime.TimestampToLocalDateTimeString(time, format)
    return timeStr
end

-- x月x日 xx:xx 月日时分
function XUiHelper.GetTimeMonthDayHourMinutes(time)
    time = time or XTime.GetServerNowTimestamp()
    local dt = CS.XDateUtil.GetLocalDateTime(time)
    local timeStr=string.format("%d%s%d%s %02d:%02d",dt.Month, XUiHelper.GetText("Monthly"),dt.Day,XUiHelper.GetText("Diary"),dt.Hour,dt.Minute)
    return timeStr
end

---设置图片
---@param imgObj UnityEngine.UI.RawImage|UnityEngine.UI.Image
function XUiHelper.GetUiSetIcon(imgObj, iconUrl)
    if not string.IsNilOrEmpty(iconUrl) then
        if imgObj.sprite then
            imgObj:SetSprite(iconUrl)
        else
            imgObj:SetRawImage(iconUrl)
        end
    end
end

-- 传入3d的localposition，相机，和目标渲染到的ui。返回vector2
---@param canvasRect UnityEngine.RectTransform|UnityEngine.Transform
---@param fromObjPos UnityEngine.Vector3
---@param cameraWorld UnityEngine.Camera
function XUiHelper.ObjPosToUguiPos(canvasRect, fromObjPos, cameraWorld)
    local screenPoint = cameraWorld:WorldToScreenPoint(fromObjPos)
    local screenPoint_v2 = Vector2(screenPoint.x, screenPoint.y)
    local hasValue, localPoint = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(canvasRect, screenPoint_v2, CS.XUiManager.Instance.UiCamera)
    return localPoint
end

-- 根据两个单位向量判断夹角
function XUiHelper.GetAngleByVector3(normalizeV3A, normalizeV3B)
    local dotRes = Vector3.Dot(normalizeV3A, normalizeV3B)
    local angle = math.acos(dotRes) -- 弧度
    angle = math.deg(angle) -- 角度
    return angle
end

-- 打开提示 [PC] 当前平台虹卡数量不够, 且其他移动端平台虹卡数量同样不够时 弹出提示
function XUiHelper.OpenPurchaseBuyHongKaCountTips()
    if XDataCenter.UiPcManager.IsPc() then
        XUiManager.TipText("PcPurchaseBuyHongKaCountTips")
    else
        XUiManager.TipText("PurchaseBuyHongKaCountTips")
    end
end

-- [PC] 当前平台虹卡数量不够, 判断其他平台的虹卡数量是否能够购买, 如果海外拥有PC端虹卡, 应当做其他处理
function XUiHelper.CanBuyInOtherPlatformHongKa(consumeCount)
    if not XDataCenter.UiPcManager.IsPc() then
        return false
    end
    local otherCount = XPlayer.GetPcOtherPlatformMoneyCardCount()
    if not otherCount or not consumeCount then
        return false
    end
    if otherCount < consumeCount then
        return false
    end
    return true   
end

-- [PC] 切换到另一个平台的虹卡, 进行接下来的购买流程 (函数名不同是因为功能进行过修改, 之前是直接切换+购买, 后改为仅切换)
function XUiHelper.BuyInOtherPlatformHongka(closeCallback)
    local otherCount = XPlayer.GetPcOtherPlatformMoneyCardCount()
    local selectedId = XPlayer.GetPcSelectMoneyCardId()
    local platform 
    if selectedId == 8 then
        platform = "IOS"
    elseif  selectedId == 10 then
        platform = "安卓"
    end
    local content = XUiHelper.GetText("PcPurchaseWithSwitchHongka", platform, otherCount);
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"),  content, XUiManager.DialogType.Normal, closeCallback, 
    function() 
        XPlayer.ChangePcSelectMoneyCardId()
    end, nil, nil)
    return true
end

function XUiHelper.GetCountNotEnoughTips(consumeId)
    local tips = "";
    if XDataCenter.UiPcManager.IsPc() and consumeId == XDataCenter.ItemManager.ItemId.HongKa then
        tips = XUiHelper.GetText("PcPurchaseBuyHongKaCountTips");
    else
        local name = XDataCenter.ItemManager.GetItemName(consumeId) or ""
        tips = XUiHelper.GetText("PurchaseBuyKaCountTips", name)
    end
    return tips
end