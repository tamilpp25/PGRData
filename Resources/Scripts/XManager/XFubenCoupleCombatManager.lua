local tableInsert = table.insert
local ipairs = ipairs
local pairs = pairs
local KEY_STAGE = "NewStage"

XFubenCoupleCombatManagerCreator = function()
    local XFubenCoupleCombatManager = {}
    local ActivityInfo = nil
    local ActivityDay = 0
    local DefaultActivityInfo = nil

    local StageRecordDic = {}
    local RobotRecordDic = {}
    local StageChapterDic = {}
    local NewStageReadDic = {}
    local IsRegisterEditBattleProxy = false

    -------- local function begin ----------
    local function Init()
        if ActivityInfo then
            DefaultActivityInfo = ActivityInfo
        else
            local activityTemplates = XFubenCoupleCombatConfig.GetActTemplates()
            for _, template in pairs(activityTemplates) do
                DefaultActivityInfo = XFubenCoupleCombatConfig.GetActivityTemplateById(template.Id)
                if XFunctionManager.CheckInTimeByTimeId(DefaultActivityInfo.TimeId) then
                    ActivityInfo = DefaultActivityInfo
                end
            end
        end
        XFubenCoupleCombatManager.RegisterEditBattleProxy()
    end

    local function GetKey(key)
        return string.format("%s_FubenCoupleCombat_%d_%s", tostring(XPlayer.Id), ActivityInfo.Id, key)
    end

    -------- local function end ----------
    local FUBEN_COUPLE_COMBAT_PROTO = {
        ResetStageMemberRequest = "CoupleCombatResetStageMemberRequest",
    }

    function XFubenCoupleCombatManager.GetCurrentActTemplate()
        return ActivityInfo
    end

    function XFubenCoupleCombatManager.GetChapterTemplate(type)
        if not ActivityInfo then return {} end
        local id = ActivityInfo.ChapterIds[type]
        return XFubenCoupleCombatConfig.GetChapterTemplate(id) or {}
    end

    function XFubenCoupleCombatManager.OnActivityEnd()
        XLuaUiManager.RunMain()
        if XFubenCoupleCombatManager.GetIsActivityEnd() then
            XUiManager.TipText("ActivityMainLineEnd", XUiManager.UiTipType.Wrong)
        else
            XUiManager.TipText("ArenaOnlineTimeOut", XUiManager.UiTipType.Wrong, true)
        end
    end

    -- 检测是否开启模式
    function XFubenCoupleCombatManager.CheckModeOpen(type)
        if not type then return end
        if XFubenCoupleCombatManager.GetIsActivityEnd() then
            XUiManager.TipText("RougeLikeNotInActivityTime")
            return false, CS.XTextManager.GetText("RougeLikeNotInActivityTime")
        end

        local chapter = XFubenCoupleCombatManager.GetChapterTemplate(type)
        if not chapter then return true end
        if not XFubenCoupleCombatManager.CheckStageOpen(chapter.StageIds[1]) then
            return XFubenCoupleCombatManager.CheckStageOpen(chapter.StageIds[1], true)
        end

        if type == XFubenCoupleCombatConfig.StageType.Hard then
            chapter = XFubenCoupleCombatManager.GetChapterTemplate(XFubenCoupleCombatConfig.StageType.Normal)
            local stageId = chapter.StageIds[#chapter.StageIds]
            if not StageRecordDic[stageId] then
                return false, CS.XTextManager.GetText("CoupleCombatHardModeNotOpen")
            end
        end

        return true
    end

    -- 检测关卡是否处于开放状态
    function XFubenCoupleCombatManager.CheckStageOpen(stageId, isGetTime)
        local stageInterInfo = XFubenCoupleCombatConfig.GetStageInfo(stageId)
        if not stageInterInfo then return end
        if ActivityDay >= stageInterInfo.OpenDay then
            return true
        elseif isGetTime then
            local nowTime = XTime.GetServerNowTimestamp()
            local refreshTime = XTime.GetSeverNextRefreshTime()
            local remainTime = XUiHelper.GetTime((stageInterInfo.OpenDay - ActivityDay - 1) * 60 * 60 * 24 + refreshTime - nowTime, XUiHelper.TimeFormatType.MOE_WAR)
            return false, CS.XTextManager.GetText("ScheOpenCountdown", remainTime)
        else
            return false
        end
    end

    -- 红点逻辑：有新关卡时重置
    function XFubenCoupleCombatManager.CheckNewStage(type)
        if not XFubenCoupleCombatManager.CheckModeOpen(type) then return false end

        local chapter = XFubenCoupleCombatManager.GetChapterTemplate(type)
        for _, v in ipairs(chapter.StageIds) do
            if XFubenCoupleCombatManager.CheckStageOpen(v) and not NewStageReadDic[v] then
                return true
            end
        end

        return false
    end

    function XFubenCoupleCombatManager.SetReadNewStageMark(type)
        if not XFubenCoupleCombatManager.CheckModeOpen(type) then return end
        local needSave = false
        local chapter = XFubenCoupleCombatManager.GetChapterTemplate(type)
        for _, v in ipairs(chapter.StageIds) do
            if XFubenCoupleCombatManager.CheckStageOpen(v) and not NewStageReadDic[v] then
                NewStageReadDic[v] = true
                needSave = true
            end
        end

        if needSave then
            XSaveTool.SaveData(GetKey(KEY_STAGE), NewStageReadDic)
        end
    end

    -- 获取所有关卡进度
    function XFubenCoupleCombatManager.GetStageSchedule(stageType)
        local passCount = 0
        local allCount = 0
        for _, type in pairs(XFubenCoupleCombatConfig.StageType) do
            if stageType and type ~= stageType then
                goto CONTINUE
            end
            local chapter = XFubenCoupleCombatManager.GetChapterTemplate(type)
            if XFubenCoupleCombatManager.CheckStageOpen(chapter.StageIds[1]) then
                allCount = allCount + #chapter.StageIds
                for _, stageId in ipairs(chapter.StageIds) do
                    if StageRecordDic[stageId] and next(StageRecordDic[stageId]) then
                        passCount = passCount + 1
                    end
                end
            end
            ::CONTINUE::
        end

        return passCount, allCount
    end

    function XFubenCoupleCombatManager.GetFeatureMatch(stageId, teamData)
        local matchDic = {}
        local featureList = {}
        local stageInterInfo = XFubenCoupleCombatConfig.GetStageInfo(stageId)
        if not stageInterInfo then return matchDic end
        featureList[0] = stageInterInfo.Feature
        for _, v in ipairs(stageInterInfo.Feature) do
            matchDic[v] = 0
        end
        for i, id in ipairs(teamData) do
            local memberInfo = XFubenCoupleCombatConfig.GetRobotInfo(id)
            if memberInfo then
                featureList[i] = memberInfo.Feature
                for _, v in ipairs(memberInfo.Feature) do
                    if matchDic[v] then
                        matchDic[v] = matchDic[v] + 1
                    end
                end
            end
        end
        return matchDic, featureList
    end

    -- 检测机器人是否已使用状态
    function XFubenCoupleCombatManager.CheckRobotUsed(stageId, robotId)
        if not StageChapterDic[stageId] then return end
        local chapterId = StageChapterDic[stageId].Id
        if not RobotRecordDic[chapterId] then
            return
        end
        return RobotRecordDic[chapterId][robotId]
    end

    function XFubenCoupleCombatManager.GetStageUsedRobot(stageId)
        return StageRecordDic[stageId] or {}
    end

    function XFubenCoupleCombatManager.GetRobotByStage(stageId)
        return StageChapterDic[stageId] and StageChapterDic[stageId].RobotIds
    end

    -- [初始化数据]
    function XFubenCoupleCombatManager.InitStageInfo()
        for _, chapter in pairs(XFubenCoupleCombatConfig.GetChapterTemplates()) do
            for _, stageId in ipairs(chapter.StageIds) do
                StageChapterDic[stageId] = chapter
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.CoupleCombat
                end
            end
        end

        -- 通关后会执行InitStage 所以需要刷新
        XFubenCoupleCombatManager.RefreshStagePassed()
    end

    function XFubenCoupleCombatManager.RefreshStagePassed()
        for _, chapter in pairs(XFubenCoupleCombatConfig.GetChapterTemplates()) do
            for _, stageId in ipairs(chapter.StageIds) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                if stageInfo then
                stageInfo.Passed = StageRecordDic[stageId] or false
                    --stageInfo.StarsMap = XFubenCoupleCombatManager.GetStarMap(stageId)
                    stageInfo.Unlock = XFubenCoupleCombatManager.CheckStageOpen(stageId)
                    stageInfo.IsOpen = true

                    if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                        stageInfo.Unlock = false
                    end

                    for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                        if preStageId > 0 then
                            if not StageRecordDic[preStageId] then
                                stageInfo.Unlock = false
                                stageInfo.IsOpen = false
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    function XFubenCoupleCombatManager.PreFight(stage, teamId)
        local preFight = {}
        --preFight.CardIds = {}
        preFight.RobotIds = {}
        preFight.StageId = stage.StageId
        local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
        for i, v in pairs(teamData) do
            local isRobot = XRobotManager.CheckIsRobotId(v)
            preFight.RobotIds[i] = isRobot and v or 0
        end

        preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
        preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)

        return preFight
    end

    function XFubenCoupleCombatManager.GetAvailableActs()
        local act = ActivityInfo or DefaultActivityInfo
        local activityList = {}
        if act and
                not XFubenCoupleCombatManager.GetIsActivityEnd() and
                not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenCoupleCombat) then
                tableInsert(activityList, {
                    Id = act.Id,
                    Type = XDataCenter.FubenManager.ChapterType.CoupleCombat,
                    Name = act.Name,
                    Icon = act.BannerBg,
                })
        end
        return activityList
    end

    --判断活动是否开启
    function XFubenCoupleCombatManager.GetIsActivityEnd()
        local timeNow = XTime.GetServerNowTimestamp()
        local isEnd = timeNow >= XFubenCoupleCombatManager.GetEndTime()
        local isStart = timeNow >= XFubenCoupleCombatManager.GetStartTime()
        local inActivity = (not isEnd) and (isStart)
        return not inActivity, timeNow < XFubenCoupleCombatManager.GetStartTime()
    end

    --获取活动开始时间
    function XFubenCoupleCombatManager.GetStartTime()
        if DefaultActivityInfo then
            return XFunctionManager.GetStartTimeByTimeId(DefaultActivityInfo.TimeId) or 0
        end
        return 0
    end

    --获取活动结束时间
    function XFubenCoupleCombatManager.GetEndTime()
        if DefaultActivityInfo then
            return XFunctionManager.GetEndTimeByTimeId(DefaultActivityInfo.TimeId) or 0
        end
        return 0
    end

    -- 主题活动页面是否可挑战接口
    function XFubenCoupleCombatManager.IsChallengeable()
        if not ActivityInfo then return false end
        for _, type in pairs(XFubenCoupleCombatConfig.StageType) do
            if XFubenCoupleCombatManager.CheckNewStage(type) then
                return true
            end
        end

        return false
    end

    -- 注册出战界面代理
    function XFubenCoupleCombatManager.RegisterEditBattleProxy()
        if IsRegisterEditBattleProxy then return end
        IsRegisterEditBattleProxy = true
        XUiNewRoomSingleProxy.RegisterProxy(XDataCenter.FubenManager.StageType.CoupleCombat,
                require("XUi/XUiFubenCoupleCombat/Proxy/XUiCoupleCombatNewRoomSingle"))
        XUiRoomCharacterProxy.RegisterProxy(XDataCenter.FubenManager.StageType.CoupleCombat,
                require("XUi/XUiFubenCoupleCombat/Proxy/XUiCoupleCombatRoomCharacter"))
    end

    function XFubenCoupleCombatManager.ResetStage(stageId, cb)
        if not StageRecordDic[stageId] then return end
        XNetwork.Call(FUBEN_COUPLE_COMBAT_PROTO.ResetStageMemberRequest, { StageId = stageId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            for _, robotId in pairs(StageRecordDic[stageId]) do
                local chapterId = StageChapterDic[stageId].Id
                RobotRecordDic[chapterId][robotId] = nil
            end

            StageRecordDic[stageId] = {}
            if cb then cb() end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE)
        end)
    end

    --登录/活动开始/跨周时下发
    function XFubenCoupleCombatManager.NotifyData(data)
        ActivityInfo = XFubenCoupleCombatConfig.GetActivityTemplateById(data.Data.ActivityId)
        if not ActivityInfo then
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_ON_RESET, XDataCenter.FubenManager.StageType.CoupleCombat)
            return
        end
        ActivityDay = data.ActivityDay
        Init()
        StageRecordDic = {}
        RobotRecordDic = {}
        for _, v in ipairs(data.Data.Stages) do
            StageRecordDic[v.StageId] = v.RobotIds
            local chapterId = StageChapterDic[v.StageId].Id
            if not RobotRecordDic[chapterId] then
                RobotRecordDic[chapterId] = {}
            end
            for _, robotId in pairs(v.RobotIds) do
                RobotRecordDic[chapterId][robotId] = true
            end
        end

        XFubenCoupleCombatManager.RefreshStagePassed()

        NewStageReadDic = XSaveTool.GetData(GetKey(KEY_STAGE)) or {}
    end

    -- 下发关卡数据（通关星数）
    function XFubenCoupleCombatManager.NotifyStageData(stageInfo)
        StageRecordDic[stageInfo.StageId] = stageInfo.RobotIds

        local chapterId = StageChapterDic[stageInfo.StageId].Id
        if not RobotRecordDic[chapterId] then
            RobotRecordDic[chapterId] = {}
        end
        for _, robotId in pairs(stageInfo.RobotIds) do
            RobotRecordDic[chapterId][robotId] = true
        end

        XFubenCoupleCombatManager.RefreshStagePassed()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE)
    end

    -- 下发活动天数
    function XFubenCoupleCombatManager.NotifyDailyData(data)
        ActivityDay = data.ActivityDay
        XFubenCoupleCombatManager.RefreshStagePassed()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE)
    end

    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, function()
        Init()
    end)
    return XFubenCoupleCombatManager
end

XRpc.NotifyCoupleCombatData = function(data)
    XDataCenter.FubenCoupleCombatManager.NotifyData(data)
end

XRpc.NotifyCoupleCombatStageData = function(data)
    XDataCenter.FubenCoupleCombatManager.NotifyStageData(data.StageData)
end

XRpc.NotifyCoupleCombatDailyData = function(data)
    XDataCenter.FubenCoupleCombatManager.NotifyDailyData(data)
end
