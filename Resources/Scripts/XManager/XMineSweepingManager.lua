local XMineSweepingGame = require("XEntity/XMineSweeping/XMineSweepingGame")
local tableInsert = table.insert
local tableSort = table.sort

XMineSweepingManagerCreator = function()
    local XMineSweepingManager = {}

    local METHOD_NAME = {
        MineSweepingStartStageRequest = "MineSweepingStartStageRequest",--开始关卡请求
        MineSweepingOpenRequest = "MineSweepingOpenRequest",--扫雷翻开方格请求
        MineSweepingFlagRequest = "MineSweepingFlagRequest",--扫雷标记方格请求
    }

    local MineSweepingGameData = {}

    function XMineSweepingManager.Init()
        XMineSweepingManager.InitGameData()
    end
    
    function XMineSweepingManager.InitGameData()
        MineSweepingGameData = XMineSweepingGame.New()
    end
    
    function XMineSweepingManager.UpdateGameData(data)
        MineSweepingGameData:UpdateData(data)
    end

    function XMineSweepingManager.UpdateStageInfoByChapterId(chapterId, stageInfo)
        local chapterEntity = MineSweepingGameData:GetChapterEntityById(chapterId)
        local activityStageList = XTool.Clone(chapterEntity:GetActivityStageList())
        for index,info in pairs(activityStageList) do
            if info.ActivityStageId == stageInfo.ActivityStageId then
                activityStageList[index] = stageInfo
            end
        end
        chapterEntity:UpdateData({ActivityStageList = activityStageList})
    end
    
    function XMineSweepingManager.UpdateChallengeCountByChapterId(chapterId, challengeCounts)
        local chapterEntity = MineSweepingGameData:GetChapterEntityById(chapterId)
        chapterEntity:UpdateData({ChallengeCounts = challengeCounts})
    end
    
    function XMineSweepingManager.UpdateCurGridListByChapterId(chapterId, curGridList)
        local chapterEntity = MineSweepingGameData:GetChapterEntityById(chapterId)
        chapterEntity:UpdateData({CurGridList = curGridList})
    end
    
    function XMineSweepingManager.GetPreStageByStageId(id)
        local preStageDic = MineSweepingGameData:GetPreStageDic()
        return preStageDic[id]
    end

    function XMineSweepingManager.GetChapterByChapterId(chapterId)
        local chapterEntity = MineSweepingGameData:GetChapterEntityById(chapterId)
        return chapterEntity
    end
    
    function XMineSweepingManager.GetChapterMineIcon(chapterId)
        local chapterEntity = MineSweepingGameData:GetChapterEntityById(chapterId)
        chapterEntity:GetMineIcon()
    end
    
    function XMineSweepingManager.ResetMineGridByChapterId(chapterId)
        local chapterEntity = MineSweepingGameData:GetChapterEntityById(chapterId)
        chapterEntity:ResetGrid()
    end
    
    function XMineSweepingManager.GetMineSweepingData()
        return MineSweepingGameData
    end
    
    function XMineSweepingManager.GetMineSweepingActivityId()
        return MineSweepingGameData:GetActivityId()
    end
    
    function XMineSweepingManager.GetMineSweepingCoinItemId()
        return MineSweepingGameData:GetCoinItemId()
    end
    
    function XMineSweepingManager.GetMineSweepingCoinItemCount()
        local id = MineSweepingGameData:GetCoinItemId()
        return XDataCenter.ItemManager.GetCount(id)
    end
    
    function XMineSweepingManager.GetChapterEntityDic()
        return MineSweepingGameData:GetChapterEntityDic()
    end
    
    function XMineSweepingManager.GetChapterIds()
        return MineSweepingGameData:GetChapterIds()
    end
    
    function XMineSweepingManager.GetChapterEntityByIndex(index)
        local id = MineSweepingGameData:GetChapterIdByIndex(index)
        return XMineSweepingManager.GetChapterEntityById(id)
    end
    
    function XMineSweepingManager.GetChapterEntityById(chapterId)
        return MineSweepingGameData:GetChapterEntityById(chapterId)
    end
    
    function XMineSweepingManager.GetNewChapterIndex()
        return MineSweepingGameData:GetNewChapterIndex()
    end
    
    function XMineSweepingManager.GetMineSweepingTimeLeft()
        local activityId = MineSweepingGameData:GetActivityId()
        if activityId ~= 0 then
            local timeId = MineSweepingGameData:GetTimeId()
            local endTime = XFunctionManager.GetEndTimeByTimeId(timeId) or 0
            local timeLeft = endTime - XTime.GetServerNowTimestamp()
            return timeLeft
        else
            return 0
        end
    end
    
    function XMineSweepingManager.CheckIsInTime()
        local activityId = MineSweepingGameData:GetActivityId()
        if activityId ~= 0 then
            local timeId = MineSweepingGameData:GetTimeId()
            local startTime = XFunctionManager.GetStartTimeByTimeId(timeId) or 0
            local endTime = XFunctionManager.GetEndTimeByTimeId(timeId) or 0
            local nowTime = XTime.GetServerNowTimestamp()
            return endTime == 0 or (nowTime > startTime and nowTime < endTime)
        else
            return false
        end
    end
    
    function XMineSweepingManager.CheckIsOpen()
        local functionId = XFunctionManager.FunctionName.MineSweeping
        local isCanOpen = XFunctionManager.JudgeCanOpen(functionId)
        if isCanOpen then
            local isInTime = XMineSweepingManager.CheckIsInTime()
            if not isInTime then
                return false, CS.XTextManager.GetText("MineSweepingNotOpenHint")
            else
                return true
            end
        else
            return false, XFunctionManager.GetFunctionOpenCondition(functionId)
        end
    end
    
    function XMineSweepingManager.OpenMineSweeping()
        local IsOpen,desc = XMineSweepingManager.CheckIsOpen()
        if IsOpen then
            XLuaUiManager.Open("UiMineSweepingMain")
        else
            XUiManager.TipMsg(desc)
        end
    end
    
    function XMineSweepingManager.CheckHaveRed()
        local IsHaveRed = false
        local idList = MineSweepingGameData:GetChapterIds()
        for _,id in pairs(idList) do
            if XMineSweepingManager.CheckHaveRedByChapterId(id) then
                IsHaveRed = true
                break 
            end
        end
        return IsHaveRed
    end
    
    function XMineSweepingManager.CheckShowHelp()
        local IsShow = false
        local activityId = XMineSweepingManager.GetMineSweepingActivityId()
        local hitFaceData = XSaveTool.GetData(string.format( "%sMineSweepingHelp%s", XPlayer.Id, activityId))
        if not hitFaceData then
            IsShow = true
            XSaveTool.SaveData(string.format("%sMineSweepingHelp%s", XPlayer.Id, activityId), true)
        end
        return IsShow
    end
    
    function XMineSweepingManager.CheckStoryRed(chapterId)
        local IsShow = false
        local activityId = XMineSweepingManager.GetMineSweepingActivityId()
        local data = XSaveTool.GetData(string.format("%sMineSweepingStoryRed%s_%s", XPlayer.Id, activityId, chapterId))
        if not data then
            IsShow = true
        end
        return IsShow
    end
    
    function XMineSweepingManager.MarkStoryRed(chapterId)
        local activityId = XMineSweepingManager.GetMineSweepingActivityId()
        local data = XSaveTool.GetData(string.format("%sMineSweepingStoryRed%s_%s", XPlayer.Id, activityId, chapterId))
        if not data then
            XSaveTool.SaveData(string.format("%sMineSweepingStoryRed%s_%s", XPlayer.Id, activityId, chapterId), true)
        end
    end
    
    function XMineSweepingManager.CheckHaveRedByChapterId(chapterId)
        local chapterEntity = MineSweepingGameData:GetChapterEntityById(chapterId)
        if not chapterEntity then
           return false 
        end
        
        local curStageEntity = chapterEntity:GetCurStageEntity()
        if not curStageEntity then
            return false
        end
        
        if chapterEntity:IsSweeping() then
           return true 
        end
        
        if chapterEntity:IsFailed() then
            return true
        end
        
        if chapterEntity:IsFinish() and XMineSweepingManager.CheckStoryRed(chapterId) and chapterEntity:GetCompleteStoryId() then
            return true
        end
        
        local coinId = XDataCenter.MineSweepingManager.GetMineSweepingCoinItemId()
        local coinCount = XDataCenter.ItemManager.GetCount(coinId)
        local costCoinNum = curStageEntity:GetCostCoinNum()
        
        if not chapterEntity:IsLock() and chapterEntity:IsPrepare() and coinCount >= costCoinNum then
            return true
        end
    end
    
    function XMineSweepingManager.MineSweepingStartStageRequest(chapterId, stageId, cb)
        XNetwork.Call(METHOD_NAME.MineSweepingStartStageRequest,
            {ActivityChapterId = chapterId, ActivityStageId = stageId},
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XMineSweepingManager.ResetMineGridByChapterId(chapterId)
                XMineSweepingManager.UpdateStageInfoByChapterId(chapterId, res.ActivityStageInfo)
                XMineSweepingManager.UpdateChallengeCountByChapterId(chapterId, res.ChallengeCounts)
                
                if cb then cb() end
                XEventManager.DispatchEvent(XEventId.EVENT_MINESWEEPING_STAGESTART)
            end)
    end
    
    function XMineSweepingManager.MineSweepingOpenRequest(chapterId, stageId, xIndex, yIndex, cb)
        XNetwork.Call(METHOD_NAME.MineSweepingOpenRequest, 
            {ActivityChapterId = chapterId, ActivityStageId = stageId, XIndex = xIndex, YIndex = yIndex}, 
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XMineSweepingManager.UpdateStageInfoByChapterId(chapterId, res.ActivityStageInfo)
                XMineSweepingManager.UpdateCurGridListByChapterId(chapterId, res.RefreshGridList)

                if cb then cb(res.RewardGoodsList) end
                XEventManager.DispatchEvent(XEventId.EVENT_MINESWEEPING_GRIDOPEN)
            end)
    end
    
    function XMineSweepingManager.MineSweepingFlagRequest(chapterId, stageId, xIndex, yIndex, isFlag, cb)--暂时不用
        XNetwork.Call(METHOD_NAME.MineSweepingFlagRequest, 
            {ActivityChapterId = chapterId, ActivityStageId = stageId, XIndex = xIndex, YIndex = yIndex, IsFlag = isFlag},
            function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then cb() end
            end)
    end
    
    XMineSweepingManager.Init()
    return XMineSweepingManager
end

XRpc.NotifyMineSweepingData = function(res) --登陆时,章节最后一关通关时
    XDataCenter.MineSweepingManager.UpdateGameData(res)
end