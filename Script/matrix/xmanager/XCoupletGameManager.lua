local tableInsert = table.insert
local tableSort = table.sort

XCoupletGameManagerCreator = function()
    local XCoupletGameManager = {}
    local ActivityInfo = nil
    local CurrentCoupletId = 0
    local CurrentCoupletIndex = 0
    local CoupletsDataByServer = {} -- 服务器下发的数据

    local ACTIVITY_COUPLET_PROTO = {
        CoupletOpenWordRequest = "CoupletOpenWordRequest", -- 翻字
        CoupletCompleteSentenceRequest = "CoupletCompleteSentenceRequest", -- 校验对联
    }

    function XCoupletGameManager.Init()
        
    end

    function XCoupletGameManager.HandleCoupletData(data)
        local activityId = data.ActivityId
        ActivityInfo = XCoupletGameConfigs.GetCoupletBaseActivityById(activityId)
        CoupletsDataByServer = {}
        for _, coupletData in ipairs(data.WordList or {}) do
            CoupletsDataByServer[coupletData.CoupletId] = coupletData
        end
        if not XTool.IsTableEmpty(CoupletsDataByServer) then
            CurrentCoupletId = CoupletsDataByServer[#CoupletsDataByServer].CoupletId
            CurrentCoupletIndex = XCoupletGameManager.GetCoupletIndexById(CurrentCoupletId)
        end
    end

    function XCoupletGameManager.CheckHasServerData()
        return CoupletsDataByServer and next(CoupletsDataByServer)
    end

    function XCoupletGameManager.GetCoupletWord(index, cb)
        -- 自校验
        local consumeItemId = ActivityInfo.ConsumeItemId
        local needCount = XCoupletGameConfigs.GetCoupletTemplateById(CurrentCoupletId).ItemConsumeCount
        if not XDataCenter.ItemManager.CheckItemCountById(consumeItemId, needCount) then
            XUiManager.TipMsg(CS.XTextManager.GetText("CoupletGameItemNotEnough"))
            return
        end

        XNetwork.Call(ACTIVITY_COUPLET_PROTO.CoupletOpenWordRequest, {WordIndex = index}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            CoupletsDataByServer[CurrentCoupletId].Words[index] = res.WordId
            
            if cb then cb() end
        end)
    end

    function XCoupletGameManager.ChangeWord(takeIndex, putIndex)
        if not CurrentCoupletId or not CoupletsDataByServer[CurrentCoupletId] then
            return
        end

        if XCoupletGameManager.GetCoupletGameStatus() == XCoupletGameConfigs.CouPletStatus.Complete then
            return
        end

        if not CoupletsDataByServer[CurrentCoupletId].Words[takeIndex] or not CoupletsDataByServer[CurrentCoupletId].Words[takeIndex] then
            return
        end

        local takeWordId = CoupletsDataByServer[CurrentCoupletId].Words[takeIndex]
        CoupletsDataByServer[CurrentCoupletId].Words[takeIndex] = CoupletsDataByServer[CurrentCoupletId].Words[putIndex]
        CoupletsDataByServer[CurrentCoupletId].Words[putIndex] = takeWordId
        -- XLog.Debug(CoupletsDataByServer[CurrentCoupletId].Words)
        -- 抛出事件 刷新UI
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_COUPLET_GAME_CHANGE_WORD)
    end

    function XCoupletGameManager.CompleteCoupletSentence()
        if not XCoupletGameManager.CheckCoupletIsCheckComplete(CurrentCoupletId) then -- 没有全部翻开
            return
        end

        XNetwork.Call(ACTIVITY_COUPLET_PROTO.CoupletCompleteSentenceRequest, { Words = CoupletsDataByServer[CurrentCoupletId].Words }, function (res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_COUPLET_GAME_SENTENCE_ERROR)
                return
            end
            -- 成功出对 更新当前对联数据状态
            CoupletsDataByServer[CurrentCoupletId].Status = XCoupletGameConfigs.CouPletStatus.Complete
            -- 开放下一个数据
            XCoupletGameManager.InitializeNextCoupletData()
            -- 抛出事件 刷新UI
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_COUPLET_GAME_COMPLETE)
            XEventManager.DispatchEvent(XEventId.EVENT_COUPLET_GAME_COMPLETE)
        end)
    end

    function XCoupletGameManager.GetCoupletGameStatus(coupletId)
        if not CurrentCoupletId or not CoupletsDataByServer[coupletId] then
            return XCoupletGameConfigs.CouPletStatus.Incomplete
        end

        return CoupletsDataByServer[coupletId].Status
    end

    function XCoupletGameManager.GetCoupletIndexById(coupletId)
        if not coupletId or coupletId == 0 then
            return
        end

        local coupletTemplates = XCoupletGameManager.GetCoupletTemplates()
        for index, template in ipairs(coupletTemplates) do
            if template.Id == coupletId then
                return index
            end
        end

        return nil
    end

    function XCoupletGameManager.CheckCoupletIsOpen(index)
        local coupletTemplates = XCoupletGameManager.GetCoupletTemplates()
        if index == 1 then
            return true
        else
            if CoupletsDataByServer[coupletTemplates[index].Id] then
                return true
            else
                local lastData = CoupletsDataByServer[coupletTemplates[index-1].Id]
                if not lastData then -- 上一关没数据这关一定未解锁
                    return false
                end
                if lastData.Status == XCoupletGameConfigs.CouPletStatus.Complete then
                    return true
                end
            end
        end

        return false
    end

    function XCoupletGameManager.InitializeNextCoupletData()
        local coupletTemplates = XCoupletGameManager.GetCoupletTemplates()
        if CurrentCoupletIndex >= #coupletTemplates then -- 已经是最后一个
            return
        end

        CurrentCoupletIndex = CurrentCoupletIndex + 1
        local coupletTemplate = coupletTemplates[CurrentCoupletIndex]
        CurrentCoupletId = coupletTemplate.Id
        local words = {}
        for i = 1, #coupletTemplate.DownWordId, 1 do
            tableInsert(words, 0)
        end
        CoupletsDataByServer[coupletTemplate.Id] = {
            CoupletId = coupletTemplate.Id,
            Words = words,
            Status = XCoupletGameConfigs.CouPletStatus.Incomplete,
        }

        local coupletName = XCoupletGameConfigs.GetCoupletTemplateById(CurrentCoupletId).TitleName
        XUiManager.TipMsg(CS.XTextManager.GetText("CoupletGameCoupletUnlock", coupletName))
    end

    function XCoupletGameManager.GetHelpId()
        if not ActivityInfo then
            return
        end

        return ActivityInfo.HelpId
    end

    function XCoupletGameManager.GetConsumeItemId()
        if not ActivityInfo then
            return
        end

        return ActivityInfo.ConsumeItemId
    end

    function XCoupletGameManager.GetActivityTimeId()
        if not ActivityInfo then
            return
        end

        return ActivityInfo.TimeId
    end

    function XCoupletGameManager.GetCoupletTemplates()
        if not ActivityInfo then
            return
        end

        if not ActivityInfo.Id then
            return
        end

        return XCoupletGameConfigs.GetCoupletTemplatesByActId(ActivityInfo.Id)
    end

    function XCoupletGameManager.GetActivityTitle()
        if not ActivityInfo then
            return
        end

        return ActivityInfo.Title, ActivityInfo.TitleEn
    end

    function XCoupletGameManager.GetEffectOpenDelay()
        if not ActivityInfo then
            return
        end

        return ActivityInfo.EffectDelay
    end

    function XCoupletGameManager.GetHitFaceStoryId()
        if not ActivityInfo then
            return
        end

        return ActivityInfo.StoryId
    end

    function XCoupletGameManager.GetCoupletTemplateByIndex(index)
        local coupletTemplates = XCoupletGameManager.GetCoupletTemplates()
        if not coupletTemplates then
            return
        end

        return coupletTemplates[index]
    end

    function XCoupletGameManager.GetLastCoupletName(index)
        if not index then
            return
        end

        local lastIndex = index-1
        if lastIndex < 1 then
            return
        else
            local coupletTemplate = XCoupletGameManager.GetCoupletTemplateByIndex(lastIndex)
            return coupletTemplate.TitleName
        end
    end

    function XCoupletGameManager.FindDefaultSelectTabIndex()
        return #CoupletsDataByServer
    end

    function XCoupletGameManager.CheckCoupletIsCheckComplete(coupletId) -- 检查对联是否将文字全部翻开了
        if not CoupletsDataByServer[coupletId] then
            return false
        end

        if CoupletsDataByServer[coupletId].Status == XCoupletGameConfigs.CouPletStatus.Complete then
            return false
        end

        for _, wordId in pairs(CoupletsDataByServer[coupletId].Words) do
            if wordId == 0 then
                return false
            end
        end

        return true
    end

    function XCoupletGameManager.GetDownWordsDataById(coupletId)
        if not CoupletsDataByServer[coupletId] then
            return
        end

        return CoupletsDataByServer[coupletId].Words
    end

    function XCoupletGameManager.GetRewardTaskDatas()
        local taskDataList = XDataCenter.TaskManager.GetCoupletTaskList()

        tableSort(taskDataList, function (a, b)
            if a.State == b.State then
                return a.Id < b.Id
            else
                if a.State == XDataCenter.TaskManager.TaskState.Achieved then
                    return true
                elseif a.State == XDataCenter.TaskManager.TaskState.Active and b.State == XDataCenter.TaskManager.TaskState.Finish then
                    return true
                else
                    return false
                end
            end
        end)

        return taskDataList
    end

    function XCoupletGameManager.FinishTask(taskId)
        XDataCenter.TaskManager.FinishTask(taskId, function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_COUPLET_GAME_FINISH_TASK)
            XEventManager.DispatchEvent(XEventId.EVENT_COUPLET_GAME_FINISH_TASK)
        end)
    end

    function XCoupletGameManager.GetRewardProcess()
        local taskDataList = XDataCenter.TaskManager.GetCoupletTaskList()
        local takeNum = 0
        local Count = #taskDataList
        for _, taskData in pairs(taskDataList) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Finish then
                takeNum = takeNum + 1
            end
        end
        return takeNum, Count
    end

    function XCoupletGameManager.CheckRewardTaskRedPoint()
        return XDataCenter.TaskManager.GetIsRewardForEx(XDataCenter.TaskManager.TaskType.Couplet)
    end

    function XCoupletGameManager.CheckPlayVideoRedPoint(coupletId)
        if not CoupletsDataByServer[coupletId] then
            return false
        end

        if CoupletsDataByServer[coupletId].Status == XCoupletGameConfigs.CouPletStatus.Incomplete then
            return false
        end

        local isPlayedVideo = XSaveTool.GetData(string.format("%s%s%s", XCoupletGameConfigs.PLAY_VIDEO_STATE_KEY, XPlayer.Id, coupletId))
        if not isPlayedVideo or isPlayedVideo == XCoupletGameConfigs.PlayVideoState.UnPlay then
            return true
        else
            return false
        end
    end

    function XCoupletGameManager.CheckHasNoPlayVideo()
        for _, data in pairs(CoupletsDataByServer) do
            if XCoupletGameManager.CheckPlayVideoRedPoint(data.CoupletId) then
                return true
            end
        end

        return false
    end

    function XCoupletGameManager.CheckCanExchangeWord()
        if not CoupletsDataByServer[CurrentCoupletId] then
            return false
        end

        if CoupletsDataByServer[CurrentCoupletId].Status == XCoupletGameConfigs.CouPletStatus.Complete then
            return false
        end

        if XCoupletGameManager.CheckCoupletIsCheckComplete(CurrentCoupletId) then
            return false
        end

        local consumeItemId = ActivityInfo.ConsumeItemId
        local needCount = XCoupletGameConfigs.GetCoupletTemplateById(CurrentCoupletId).ItemConsumeCount
        return XDataCenter.ItemManager.CheckItemCountById(consumeItemId, needCount)
    end

    function XCoupletGameManager.CheckWordIsCorrect(coupletId, index, id)
        local downWordIdArr = XCoupletGameConfigs.GetCoupletDownIdArr(coupletId, index)
        if not downWordIdArr then
            return false
        end

        for _, downWordId in pairs(downWordIdArr) do
            if downWordId == id then
                return true
            end
        end

        return false
    end

    XCoupletGameManager.Init()
    return XCoupletGameManager
end

XRpc.NotifyCoupletData = function (data)
    XDataCenter.CoupletGameManager.HandleCoupletData(data)
end