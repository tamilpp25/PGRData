---@return TwoSideTowerManager
XTwoSideTowerManagerCreator = function()
    local XTwoSideTowerChapter = require("XEntity/XTwoSideTower/XTwoSideTowerChapter")
    ---@class TwoSideTowerManager
    local TwoSideTowerManager = {}
    local ActivityId = 1
    local ActivityCfg = XTwoSideTowerConfigs.GetActivityCfg(1)
    local ShowSettle = false
    local ChapterDic = {}
    local PassStageList = {}
    if ActivityCfg then
        for _, chapterId in pairs(ActivityCfg.ChapterIds) do
            if not ChapterDic[chapterId] then
                ChapterDic[chapterId] = XTwoSideTowerChapter.New(chapterId)
            end
        end
    end
    ---@return XTwoSideTowerChapter
    function TwoSideTowerManager.GetChapter(chapterId)
        return ChapterDic[chapterId]
    end

    function TwoSideTowerManager.GetChapterDic()
        return ChapterDic
    end

    function TwoSideTowerManager.GetEndTime()
        if not ActivityCfg then
            return
        end
        return XFunctionManager.GetEndTimeByTimeId(ActivityCfg.TimeId)
    end

    function TwoSideTowerManager.GetStartTime()
        if not ActivityCfg then
            return
        end
        return XFunctionManager.GetStartTimeByTimeId(ActivityCfg.TimeId)
    end

    function TwoSideTowerManager.InitStageInfo()
        local stageCfgs = XTwoSideTowerConfigs.GetStageCfgs()
        for _, stage in pairs(stageCfgs) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stage.Id)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.TwoSideTower
            end
        end
    end

    function TwoSideTowerManager.FinishFight(settle)
        local result = settle.TwoSideTowerSettleResult or {}
        ShowSettle = result.FirstCleared
        if settle.IsWin then
            XDataCenter.FubenManager.ChallengeWin(settle)
        else
            XDataCenter.FubenManager.ChallengeLose(settle)
        end
    end

    function TwoSideTowerManager.CheckTaskFinish()
        local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(XDataCenter.TwoSideTowerManager.GetLimitTaskId())
        for _, task in pairs(taskList) do
            if XDataCenter.TaskManager.CheckTaskAchieved(task.Id) then
                return true
            end
        end
        return false
    end

    function TwoSideTowerManager.CheckChapterOpenRed()
        local hasNewOpen = false
        for _, chapter in pairs(ChapterDic) do
            local desc, isOpen = chapter:GetProcess()
            local saveKey = TwoSideTowerManager.GetChapterOpenRedKey(chapter:GetId())
            if isOpen and (not XSaveTool.GetData(saveKey)) then
                hasNewOpen = true
            end
        end
        return hasNewOpen
    end

    function TwoSideTowerManager.GetChapterOpenRedKey(chapterId)
        return string.format("TwoSideTowerNewChapterFlag_%s_%s_%s", XPlayer.Id, ActivityId, chapterId)
    end

    function TwoSideTowerManager.CheckOpenUiChapterSettle(chapterId)
        if ShowSettle then
            local chapter = TwoSideTowerManager.GetChapter(chapterId)
            XLuaUiManager.Open("UiTwoSideTowerSettle", chapter)
        end
        ShowSettle = false
    end

    function TwoSideTowerManager.IsOpen()
        if not ActivityCfg then
            return false
        end
        return XFunctionManager.CheckInTimeByTimeId(ActivityCfg.TimeId)
    end

    function TwoSideTowerManager.GetActivitySaveKey()
        return string.format("TwoSideTowerManager_GetActivitySaveKey_XPlayer.Id:%s_ActivityId:%s_", XPlayer.Id, ActivityId)
    end

    -- 检测打开章节特性总览界面
    function TwoSideTowerManager.CheckOpenUiChapterOverview(chapterId)
        local key = TwoSideTowerManager.GetChapterOverviewSaveKey(chapterId)
        if XSaveTool.GetData(key) then
            return
        end

        XLuaUiManager.Open("UiTwoSideTowerOverview", chapterId)
        XSaveTool.SaveData(key, true)
    end

    -- 章节特性总览key
    function TwoSideTowerManager.GetChapterOverviewSaveKey(chapterId)
        return XDataCenter.Maverick2Manager.GetActivitySaveKey() .. "TwoSideTowerManager_GetChapterOverviewSaveKey_chapterId:" .. tostring(chapterId)
    end

    -- 设置关卡是否不再提示
    function TwoSideTowerManager.SetDiglogHintCookie(isSelect)
        local key = TwoSideTowerManager.GetDiglogHintCookieKey()
        XSaveTool.SaveData(key, isSelect)
    end

    -- 获取关卡是否不再提示
    function TwoSideTowerManager.GetDiglogHintCookie()
        local key = TwoSideTowerManager.GetDiglogHintCookieKey()
        local isSelect = XSaveTool.GetData(key) == true
        return isSelect
    end

    -- 关卡提示key
    function TwoSideTowerManager.GetDiglogHintCookieKey()
        return XDataCenter.Maverick2Manager.GetActivitySaveKey() .. "GetDiglogHintCookieKey"
    end

    function TwoSideTowerManager.OnOpenMain()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.TwoSideTower) then
            return
        end
        if not TwoSideTowerManager.IsOpen() then
            XUiManager.TipText("CommonActivityNotStart")
            return
        end
        XLuaUiManager.Open("UiTwoSideTowerMain")
    end

    function TwoSideTowerManager.OpenUiBattleRoleRoom(stageId)
        -- 移除组队数据里，上一期失效的机器人id
        local team = XDataCenter.TeamManager.GetXTeamByTypeId(CS.XGame.Config:GetInt("TypeIdTwoSideTower"))
        local robotIds = XDataCenter.TwoSideTowerManager.GetActivityRobotIds()
        local isClear = false
        for pos, entityId in pairs(team:GetEntityIds()) do
            if entityId and entityId ~= 0 and XEntityHelper.GetIsRobot(entityId) then
                local isInclude = false
                for _, robotId in ipairs(robotIds) do
                    if entityId == robotId then
                        isInclude = true
                    end
                end
                isClear = isClear or not isInclude
            end
        end
        if isClear then
            team:Clear()
        end
        
        local XUiTwoSideTowerBattleRoleRoom = require("XUi/XUiTwoSideTower/XUiTwoSideTowerBattleRoleRoom")
        XLuaUiManager.Open("UiBattleRoleRoom", stageId, team, XUiTwoSideTowerBattleRoleRoom)
    end

    function TwoSideTowerManager.CheckStageIsPassed(stageId)
        for _, id in pairs(PassStageList) do
            if id == stageId then
                return true
            end
        end
        return false
    end

    function TwoSideTowerManager.GetLimitTaskId()
        if not ActivityCfg then
            return
        end

        return ActivityCfg.LimitTaskId
    end

    function TwoSideTowerManager.GetActivityName()
        if not ActivityCfg then
            return
        end
        return ActivityCfg.Name
    end

    function TwoSideTowerManager.GetActivityRobotIds()
        if not ActivityCfg then
            return
        end
        return ActivityCfg.RobotIds
    end

    function TwoSideTowerManager.GetProgress()
        local totalCount = 0
        local passCount = 0
        for _, chapter in pairs(ChapterDic) do
            totalCount = totalCount + 1
            if chapter:IsCleared() then
                passCount = passCount + 1
            end
        end
        return passCount, totalCount
    end

    function TwoSideTowerManager.GetActivityChapter()
        local chapters = {}
        if TwoSideTowerManager.IsOpen() then
            local temp = {}
            temp.Id = ActivityCfg.Id
            temp.Name = ActivityCfg.Name
            temp.Background = ActivityCfg.BannerBg
            temp.Type = XDataCenter.FubenManager.ChapterType.TwoSideTower
            table.insert(chapters, temp)
        end
        return chapters
    end

    function TwoSideTowerManager.UpdateChapterData(chapterData)
        if not ChapterDic[chapterData.ChapterId] then
            ChapterDic[chapterData.ChapterId] = XTwoSideTowerChapter.New(chapterData.ChapterId)
        end
        ChapterDic[chapterData.ChapterId]:UpdateData(chapterData)
    end

    function TwoSideTowerManager.HandleActivityData(data)
        ActivityId = data.ActivityId
        ActivityCfg = XTwoSideTowerConfigs.GetActivityCfg(ActivityId)
        PassStageList = data.PassedStages or {}
        for _, chapterId in pairs(ActivityCfg.ChapterIds) do
            if not ChapterDic[chapterId] then
                ChapterDic[chapterId] = XTwoSideTowerChapter.New(chapterId)
            end
        end
        for _, chapterData in pairs(data.ChapterDataList) do
            TwoSideTowerManager.UpdateChapterData(chapterData)
        end
    end

    function TwoSideTowerManager.ShieldFeatureRequest(featureId, stageId, isShield, cb)
        local req = {
            StageId = stageId,
            FeatureId = featureId,
            IsShield = isShield
        }

        XNetwork.Call("TwoSideTowerShieldOrUnShieldFeatureIdRequest", req, function(rsp)
            if rsp.Code ~= XCode.Success then
                XUiManager.TipCode(rsp.Code)
                return
            end
            if cb then
                cb(rsp.PointData)
            end
        end)
    end

    function TwoSideTowerManager.ResetChapterRequest(chapterId, cb)
        local req = {
            ChapterId = chapterId
        }
        XNetwork.Call("TwoSideTowerResetChapterRequest", req, function(rsp)
            if rsp.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if rsp.ChapterData then
                ChapterDic[chapterId] = XTwoSideTowerChapter.New(chapterId)
                ChapterDic[chapterId]:UpdateData(rsp.ChapterData)
                if cb then
                    cb()
                end
            end
        end)

    end

    function TwoSideTowerManager.SweepPositiveStageRequest(stageId, cb)
        local req = {
            StageId = stageId
        }
        XNetwork.Call("TwoSideTowerSweepPositiveStageRequest", req, function(rsp)
            if rsp.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            TwoSideTowerManager.UpdateChapterData(rsp.ChapterData)
            if cb then
                cb()
            end
        end)
    end

    return TwoSideTowerManager
end

XRpc.NotifyTwoSideTowerActivityData = function(data)
    XDataCenter.TwoSideTowerManager.HandleActivityData(data)
end

XRpc.XTwoSideTowerChapterData = function(data)
    XDataCenter.TwoSideTowerManager.UpdateChapterData(data)
end
