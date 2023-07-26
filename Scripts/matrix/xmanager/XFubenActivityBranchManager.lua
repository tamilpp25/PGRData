XFubenActivityBranchManagerCreator = function()
    local pairs = pairs
    local tableInsert = table.insert
    local ParseToTimestamp = XTime.ParseToTimestamp

    local CurActivityId = XFubenActivityBranchConfigs.GetDefaultActivityId()

    local SectionId = 0
    local ScheduleDic = {} --章节Id-通关进度Dic
    local SelectDifficult = false --记录上次是否选中挑战难度

    local XFubenActivityBranchManager = {}

    XFubenActivityBranchManager.BranchType = {
        Normal = 1,
        Difficult = 2
    }

    function XFubenActivityBranchManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA, XFubenActivityBranchManager.HandlerFightResult)
    end

    function XFubenActivityBranchManager.HandlerFightResult()
        XFubenActivityBranchManager.RefreshStagePassed()
    end

    function XFubenActivityBranchManager.GetActivitySections()
        local sections = {}

        if XFubenActivityBranchManager.IsOpen() then
            local section = {
                Type = XDataCenter.FubenManager.ChapterType.ActivtityBranch,
                Id = SectionId
            }
            tableInsert(sections, section)
        end

        return sections
    end

    function XFubenActivityBranchManager.InitStageInfo()
        local sectionCfgs = XFubenActivityBranchConfigs.GetSectionCfgs()

        for _, sectionCfg in pairs(sectionCfgs) do
            local normalChapterCfg = XFubenActivityBranchConfigs.GetChapterCfg(sectionCfg.NormalId)
            for _, stageId in pairs(normalChapterCfg.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                stageInfo.Type = XDataCenter.FubenManager.StageType.ActivtityBranch
            end

            local difficultChapterCfg = XFubenActivityBranchConfigs.GetChapterCfg(sectionCfg.DifficultyId)
            for _, stageId in pairs(difficultChapterCfg.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                stageInfo.Type = XDataCenter.FubenManager.StageType.ActivtityBranch
            end
        end
    end

    --刷新通关记录
    function XFubenActivityBranchManager.RefreshStagePassed()
        for chapterId, schedule in pairs(ScheduleDic) do
            local chapterCfg = XFubenActivityBranchConfigs.GetChapterCfg(chapterId)
            for index, stageId in pairs(chapterCfg.StageId) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if index <= schedule then
                    stageInfo.Passed = true
                else
                    stageInfo.Passed = false
                end

                if index <= schedule + 1 then
                    stageInfo.Unlock = true
                    stageInfo.IsOpen = true
                else
                    stageInfo.IsOpen = false
                end
            end
        end
    end

    function XFubenActivityBranchManager.SelectDifficult(selectDifficult)
        SelectDifficult = selectDifficult
    end

    function XFubenActivityBranchManager.IsSelectDifficult()
        return SelectDifficult
    end

    function XFubenActivityBranchManager.GetCurSectionId()
        return SectionId
    end

    function XFubenActivityBranchManager.GetCurChapterId(sectionId)
        local sectionCfg = XFubenActivityBranchConfigs.GetSectionCfg(sectionId)
        return XFubenActivityBranchManager.IsSelectDifficult() and sectionCfg.DifficultyId or sectionCfg.NormalId
    end

    function XFubenActivityBranchManager.GetChapterFinishCount(chapterId)
        return ScheduleDic[chapterId]
    end

    function XFubenActivityBranchManager.GetChapterMoveStageIndex(chapterId)
        if not chapterId then return end
        local chapterCfg = XFubenActivityBranchConfigs.GetChapterCfg(chapterId)
        return chapterCfg and chapterCfg.MoveStageIndex
    end

    function XFubenActivityBranchManager.GetChapterDatumLinePrecent(chapterId)
        if not chapterId then return end
        local chapterCfg = XFubenActivityBranchConfigs.GetChapterCfg(chapterId)
        return chapterCfg and chapterCfg.DatumLinePrecent
    end

    function XFubenActivityBranchManager.GetActivityBeginTime()
        return XFubenActivityBranchConfigs.GetActivityBeginTime(CurActivityId)
    end

    function XFubenActivityBranchManager.GetActivityChallengeBeginTime()
        return XFubenActivityBranchConfigs.GetChallengeBeginTime(CurActivityId)
    end

    function XFubenActivityBranchManager.GetFightEndTime()
        return XFubenActivityBranchConfigs.GetFightEndTime(CurActivityId)
    end

    function XFubenActivityBranchManager.GetActivityEndTime()
        return XFubenActivityBranchConfigs.GetActivityEndTime(CurActivityId)
    end

    function XFubenActivityBranchManager.IsStatusEqualFightEnd()
        local now = XTime.GetServerNowTimestamp()
        local fightEndTime = XFubenActivityBranchManager.GetFightEndTime()
        local endTime = XFubenActivityBranchManager.GetActivityEndTime()
        return fightEndTime <= now and now < endTime
    end

    function XFubenActivityBranchManager.IsStatusEqualChallengeBegin()
        local now = XTime.GetServerNowTimestamp()
        local challengeBeginTime = XFubenActivityBranchManager.GetActivityChallengeBeginTime()
        local endTime = XFubenActivityBranchManager.GetActivityEndTime()
        return challengeBeginTime <= now and now < endTime
    end

    function XFubenActivityBranchManager.IsOpen()
        local nowTime = XTime.GetServerNowTimestamp()
        local beginTime = XFubenActivityBranchManager.GetActivityBeginTime()
        local endTime = XFubenActivityBranchManager.GetActivityEndTime()
        return beginTime <= nowTime and nowTime < endTime and SectionId ~= 0
    end

    function XFubenActivityBranchManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        XUiManager.TipText("ActivityBranchOver")
        XLuaUiManager.RunMain()
    end

    function XFubenActivityBranchManager.NotifyBranchData(data)
        CurActivityId = data.ActivityId
        SectionId = data.SectionId

        for _, branchChallengeInfo in pairs(data.ChallengeInfos) do
            ScheduleDic[branchChallengeInfo.Id] = branchChallengeInfo.Schedule
        end

        XFubenActivityBranchManager.RefreshStagePassed()
    end

    function XFubenActivityBranchManager.CheckActivityCondition(sectionId)
        local sectionCfg = XFubenActivityBranchConfigs.GetSectionCfg(sectionId)
        local chapterCfg = XFubenActivityBranchConfigs.GetChapterCfg(sectionCfg.DifficultyId)
        local conditionId = chapterCfg.OpenCondition
        if conditionId ~= 0 then
            return XConditionManager.CheckCondition(conditionId)
        end
        return true
    end

    XFubenActivityBranchManager.Init()
    return XFubenActivityBranchManager
end

XRpc.NotifyBranchData = function(data)
    XDataCenter.FubenActivityBranchManager.NotifyBranchData(data)
end