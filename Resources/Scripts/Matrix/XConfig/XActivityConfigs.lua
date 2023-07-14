local ParseToTimestamp = XTime.ParseToTimestamp
local TimestampToGameDateTimeString = XTime.TimestampToGameDateTimeString

local TABLE_ACTIVITY_PATH = "Client/Activity/Activity.tab"
local TABLE_ACTIVITY_GROUP_PATH = "Client/Activity/ActivityGroup.tab"
local TABLE_ACTIVITY_LINK_PATH = "Client/Activity/ActivityLink.tab"

local ActivityTemplates = {}
local ActivityGroupTemplates = {}
local ActivityLinkTemplates = {}

XActivityConfigs = XActivityConfigs or {}

--活动类型
XActivityConfigs.ActivityType = {
    Task = 1, --任务
    Shop = 2, --商店
    Skip = 3, --跳转
    SendInvitation = 4, --邀请他人
    AcceptInvitation = 5, -- 接受邀请
    JigsawPuzzle = 6, -- 拼图
    Link = 7, --活动外链类型
    ConsumeReward = 8, -- 累消奖励
    ScratchTicket = 9, -- 普通刮刮乐
    ScratchTicketGolden = 10, -- 黄金刮刮乐
}

-- 活动背景类型
XActivityConfigs.ActivityBgType = {
    Image = 1, -- 普通图片
    Spine = 2, -- Spine动画
}

-- 任务面板跳转类型
XActivityConfigs.TaskPanelSkipType = {
    CanZhangHeMing_Qu = 20031, -- 拼图游戏（曲版本预热）
    CanZhangHeMing_LuNa = 20036, -- 拼图游戏（露娜预热）
    ChrismasTree_Dress = 20048, -- 装点圣诞树小游戏
    Couplet_Game = 20064, -- 春节对联游戏
    CanZhangHeMing_SP = 20070, -- 拼图游戏(SP角色预热)
    InvertCard_Game = 20076, -- 翻牌小游戏
}

function XActivityConfigs.Init()
    ActivityTemplates = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableActivity, "Id")
    ActivityGroupTemplates = XTableManager.ReadByIntKey(TABLE_ACTIVITY_GROUP_PATH, XTable.XTableActivityGroup, "Id")
    ActivityLinkTemplates = XTableManager.ReadByIntKey(TABLE_ACTIVITY_LINK_PATH, XTable.XTableActivityLink, "Id")
end

function XActivityConfigs.GetActivityTemplates()
    return ActivityTemplates
end

function XActivityConfigs.GetActivityGroupTemplates()
    return ActivityGroupTemplates
end

function XActivityConfigs.GetActivityTemplate(activityId)
    return ActivityTemplates[activityId]
end


function XActivityConfigs.GetActivityTimeStr(activityId, beginTime, endTime)
    local activityCfg = XActivityConfigs.GetActivityTemplate(activityId)
    local format = "yyyy-MM-dd HH:mm"
    local beginTimeStr = ""
    local endTimeStr = ""
    if not string.IsNilOrEmpty(activityCfg.ShowBeginTime) then
        beginTimeStr = activityCfg.ShowBeginTime
    else
        if beginTime and beginTime ~= 0 then
            beginTimeStr = TimestampToGameDateTimeString(beginTime, format)
        else
            beginTimeStr = TimestampToGameDateTimeString(XFunctionManager.GetStartTimeByTimeId(activityCfg.TimeId), format)
        end
    end

    if not string.IsNilOrEmpty(activityCfg.ShowEndTime) then
        endTimeStr = activityCfg.ShowEndTime
    else
        if endTime and endTime ~= 0 then
            endTimeStr = TimestampToGameDateTimeString(endTime, format)
        else
            endTimeStr = TimestampToGameDateTimeString(XFunctionManager.GetEndTimeByTimeId(activityCfg.TimeId), format)
        end
    end

    if not string.IsNilOrEmpty(beginTimeStr) and not string.IsNilOrEmpty(endTimeStr) then
        return beginTimeStr .. "~" .. endTimeStr
    else
        if not string.IsNilOrEmpty(beginTimeStr) then
            return beginTimeStr
        elseif not string.IsNilOrEmpty(endTimeStr) then
            return endTimeStr
        else
            return ""
        end
    end
end

function XActivityConfigs.GetActivityLinkCfg(id)
    return ActivityLinkTemplates[id]
end

function XActivityConfigs.GetActivityLinkTemplate()
    return ActivityLinkTemplates
end

