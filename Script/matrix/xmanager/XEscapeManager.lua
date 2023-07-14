local XEscapeData = require("XEntity/XEscape/XEscapeData")
local XTeam = require("XEntity/XTeam/XTeam")

XEscapeManagerCreator = function()
    local EscapeData = XEscapeData.New()
    local CurActivityId
    local EscapeDataCopy
    local IsOpenChapterSettle

    local XEscapeManager = {}
    local Team

    function XEscapeManager.UpdateActivityId()
        local configs = XEscapeConfigs.GetEscapeActivity()
        for id, v in pairs(configs) do
            if XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
                CurActivityId = id
                return
            end
            if XTool.IsNumberValid(v.TimeId) then
                CurActivityId = id
            end
        end
    end

    function XEscapeManager.OnOpenMain()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Escape) then
            return
        end
        if not XEscapeManager.IsOpen() then
            XUiManager.TipText("CommonActivityNotStart")
            return
        end

        local openMainCb = function()
            XLuaUiManager.Open("UiEscapeMain")
        end
        if EscapeData:IsCurChapterClear() then
            XEscapeManager.RequestEscapeSettleChapter(openMainCb, openMainCb)
            return
        end
        openMainCb()
    end

    function XEscapeManager.GetEscapeData()
        return EscapeData
    end

    function XEscapeManager.GetTeam()
        if not Team then
            Team = XDataCenter.TeamManager.GetXTeamByTypeId(CS.XGame.Config:GetInt("TypeIdEscape"))
            local isRobot
            for teamPos, entityId in ipairs(Team:GetEntityIds()) do
                --清除队伍中不存在的角色
                isRobot = XRobotManager.CheckIsRobotId(entityId)
                if (isRobot and not XEscapeConfigs.IsStageTypeRobot(entityId)) or 
                    (not isRobot and not XDataCenter.CharacterManager.IsOwnCharacter(entityId)) then
                    Team:UpdateEntityTeamPos(0, teamPos, true)
                end
            end
        end
        return Team
    end

    function XEscapeManager.GetTaskDataList(taskGroupId)
        local taskIdList = XEscapeConfigs.GetTaskIdList(taskGroupId)
        local taskList = {}
        local tastData
        for _, taskId in pairs(taskIdList) do
            tastData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if tastData then
                table.insert(taskList, tastData)
            end
        end

        local achieved = XDataCenter.TaskManager.TaskState.Achieved
        local finish = XDataCenter.TaskManager.TaskState.Finish
        table.sort(taskList, function(a, b)
            if a.State ~= b.State then
                if a.State == achieved then
                    return true
                end
                if b.State == achieved then
                    return false
                end
                if a.State == finish then
                    return false
                end
                if b.State == finish then
                    return true
                end
            end

            local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(a.Id)
            local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(b.Id)
            return templatesTaskA.Priority > templatesTaskB.Priority
        end)

        return taskList
    end

    function XEscapeManager.IsOpen()
        if not CurActivityId then return false end
        local timeId = XEscapeConfigs.GetActivityTimeId(CurActivityId)
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    function XEscapeManager.GetActivityStartTime()
        if not CurActivityId then return 0 end
        local timeId = XEscapeConfigs.GetActivityTimeId(CurActivityId)
        return XFunctionManager.GetStartTimeByTimeId(timeId)
    end

    function XEscapeManager.GetActivityEndTime()
        if not CurActivityId then return 0 end
        local timeId = XEscapeConfigs.GetActivityTimeId(CurActivityId)
        return XFunctionManager.GetEndTimeByTimeId(timeId)
    end

    function XEscapeManager.HandleActivityEndTime()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
    end

    function XEscapeManager.GetActivityChapters()
        local chapters = {}
        if XEscapeManager.IsOpen() then
            local temp = {}
            temp.Id = CurActivityId
            temp.Name = XEscapeConfigs.GetActivityName(CurActivityId)
            temp.BannerBg = XEscapeConfigs.GetActivityBackground(CurActivityId)
            temp.Type = XDataCenter.FubenManager.ChapterType.Escape
            table.insert(chapters, temp)
        end
        return chapters
    end

    function XEscapeManager.GetLayerChallengeState(chapterId, layerId)
        local layerIds = XEscapeConfigs.GetChapterLayerIds(chapterId)
        local preLayerId
        local preLayerIndex
        for i, layerIdConfig in ipairs(layerIds) do
            if layerIdConfig == layerId then
                preLayerIndex = i - 1
                preLayerId = layerIds[preLayerIndex]
                break
            end
        end

        --当前层已通关
        local layerClearStageCount = EscapeData:GetLayerClearStageCount(layerId, true)
        local layerClearStageCountConfig = XEscapeConfigs.GetLayerClearStageCount(layerId)
        if layerClearStageCount >= layerClearStageCountConfig then
            return XEscapeConfigs.LayerState.Pass, ""
        end

        --不存在上一层的Id，当前层可挑战
        if not preLayerId then
            return XEscapeConfigs.LayerState.Now, ""
        end

        local stageIdList = XEscapeConfigs.GetLayerStageIds(preLayerId)
        local clearStageCount = XEscapeConfigs.GetLayerClearStageCount(preLayerId)
        for _, stageId in ipairs(stageIdList) do
            if EscapeData:IsCurChapterStageClear(stageId) then
                clearStageCount = clearStageCount - 1
            end
        end

        local preStageClear = clearStageCount <= 0
        local challengeConditionDesc = not preStageClear and XUiHelper.GetText("EscapeNotClearLayerDesc", preLayerIndex) or ""
        return preStageClear and XEscapeConfigs.LayerState.Now or XEscapeConfigs.LayerState.Lock, challengeConditionDesc
    end

    --获得达到开启条件的最高区域Id
    function XEscapeManager.GetChapterOpenId()
        local chapterGroupIdList = XEscapeConfigs.GetEscapeChapterGroupIdList()
        for i = #chapterGroupIdList, 1, -1 do
            local groupId = chapterGroupIdList[i]
            local chapterIdList = XEscapeConfigs.GetEscapeChapterIdListByGroupId(groupId)
            local normalChapterId = chapterIdList[1] --普通难度的章节Id
            local timeId = XEscapeConfigs.GetChapterTimeId(normalChapterId)
            local conditionId = XEscapeConfigs.GetChapterOpenCondition(normalChapterId)
            local isOpen = XFunctionManager.CheckInTimeByTimeId(timeId)
            if not isOpen then
                goto continue
            end

            isOpen = not XTool.IsNumberValid(conditionId) or XConditionManager.CheckCondition(conditionId)
            if isOpen then
                return normalChapterId
            end
            :: continue ::
        end
        return 0
    end

    function XEscapeManager.IsChapterClear(chapterId)
        return EscapeData:IsChapterClear(chapterId)
    end

    function XEscapeManager.IsChapterOpen(chapterId, isShowTips)
        local timeId = XEscapeConfigs.GetChapterTimeId(chapterId)
        if not XFunctionManager.CheckInTimeByTimeId(timeId) then
            if isShowTips then
                XUiManager.TipErrorWithKey("EscapeTimeNotReached")
            end
            return false
        end

        local conditionId = XEscapeConfigs.GetChapterOpenCondition(chapterId)
        if XTool.IsNumberValid(conditionId) then
            local isOpen, desc = XConditionManager.CheckCondition(conditionId)
            if not isOpen then
                if isShowTips then
                    XUiManager.TipError(desc)
                end
                return false
            end
        end
        return true
    end

    ---------------------缓存数据 begin---------------------
    local CurSelectChapterId
    function XEscapeManager.SetCurSelectChapterId(chapterId)
        CurSelectChapterId = chapterId
    end

    function XEscapeManager.GetCurSelectChapterId()
        return CurSelectChapterId or EscapeData:GetChapterId()
    end

    function XEscapeManager.CatchEscapeData()
        EscapeDataCopy = XTool.Clone(EscapeData)
    end

    function XEscapeManager.GetEscapeDataCopy()
        return EscapeDataCopy
    end

    function XEscapeManager.CheckOpenChapterSettle()
        if EscapeData:IsCurChapterClear() then
            if not XEscapeManager.GetIsOpenChapterSettle() then
                XEscapeManager.CatchEscapeData()
            end
            XEscapeManager.SetOpenChapterSettle(true)
        end
    end

    function XEscapeManager.SetOpenChapterSettle(isOpenChapterSettle)
        IsOpenChapterSettle = isOpenChapterSettle
    end

    function XEscapeManager.GetIsOpenChapterSettle()
        return IsOpenChapterSettle
    end
    ---------------------缓存数据 end-----------------------

    ---------------------副本相关 begin-------------------------
    function XEscapeManager.InitStageInfo()
        local stageIdList = XEscapeConfigs.GetEscapeStageIdList()
        local stageInfo
        for _, stageId in ipairs(stageIdList) do
            stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.Escape
            end
        end
    end

    function XEscapeManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local team = XEscapeManager.GetTeam()
        local cardIds = {0, 0, 0}
        local robotIds = {0, 0, 0}
        local role
        for pos, entityId in ipairs(team:GetEntityIds()) do
            if entityId > 0 then
                if XEntityHelper.GetIsRobot(entityId) then
                    robotIds[pos] = entityId
                else
                    cardIds[pos] = entityId
                end
            end
        end
        return {
            StageId = stage.StageId,
            IsHasAssist = isAssist,
            ChallengeCount = challengeCount,
            CaptainPos = team:GetCaptainPos(),
            FirstFightPos = team:GetFirstFightPos(),
            CardIds = cardIds,
            RobotIds = robotIds,
        }
    end
    
    function XEscapeManager.ShowReward(winData)
        XLuaUiManager.Open("UiEscapeSettle", XEscapeConfigs.ShowSettlePanel.SelfWinInfo, nil, winData)
    end
    ---------------------副本相关 end-------------------------

    ------------------红点相关 begin-----------------------
    --检查是否有任务奖励可领取
    function XEscapeManager.CheckTaskCanReward()
        local configs = XEscapeConfigs.GetEscapeTask()
        for id in pairs(configs) do
            if XEscapeManager.CheckTaskCanRewardByEscapeTaskId(id) then
                return true
            end
        end
        return false
    end

    function XEscapeManager.CheckTaskCanRewardByEscapeTaskId(escapeTaskId)
        local taskIdList = XEscapeConfigs.GetTaskIdList(escapeTaskId)
        for _, taskId in ipairs(taskIdList) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                return true
            end
        end
        return false
    end
    ------------------红点相关 end------------------------

    ---------------------protocol begin------------------
    --推送数据
    function XEscapeManager.NotifyEscapeData(data)
        EscapeData:UpdateData(data)
        XDataCenter.EscapeManager.CheckOpenChapterSettle()
        XDataCenter.EscapeManager.UpdateActivityId()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ESCAPE_DATA_NOTIFY)
        XEventManager.DispatchEvent(XEventId.EVENT_ESCAPE_DATA_NOTIFY)
    end

    function XEscapeManager.NotifyEscapeStageResult(data)
        EscapeData:UpdateStageResult(data)
    end

    --重置关卡
    function XEscapeManager.RequestEscapeResetStage(stageId)
        local requestBody = {
            StageId = stageId
        }
        XNetwork.CallWithAutoHandleErrorCode("EscapeResetStageRequest", requestBody)
    end

    --结算章节/放弃当前进度
    function XEscapeManager.RequestEscapeSettleChapter(successCallback, failCallback)
        XEscapeManager.CatchEscapeData()
        XNetwork.Call("EscapeSettleChapterRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                if failCallback then
                    failCallback()
                end
                XUiManager.TipCode(res.Code)
                return
            end
            if successCallback then
                successCallback()
            end
        end)
    end
    ---------------------protocol end---------------------

    XEscapeManager.UpdateActivityId()
    return XEscapeManager
end

XRpc.NotifyEscapeData = function(data)
    XDataCenter.EscapeManager.NotifyEscapeData(data)
end

XRpc.NotifyEscapeStageResult = function(data)
    XDataCenter.EscapeManager.NotifyEscapeStageResult(data)
end