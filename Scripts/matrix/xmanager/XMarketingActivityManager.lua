XMarketingActivityManagerCreator = function()
    local tableInsert = table.insert
    local tableSort = table.sort
    local XMarketingActivityManager = {}
    local ActivityList = {}
    local CharacterList = {}
    local WindowsInlayActivityList = {}
    local WindowsInlayTokenList = {}

    local PicCompositionCfg = {}
    local OtherCompositionDataList = {}
    local RankCompositionDataList = {}
    local MyCompositionDataList = {}
    local PicCompositionUpLoadDayCount = 0
    local PicCompositionUpLoadMaxCount = 0
    local PicCompositionActivityId = 0
    local Json = require("XCommon/Json")
    local PicCompositionMemoMax = CS.XGame.ClientConfig:GetInt("PicCompositionMemoMax")
    local PicCompositionGetMaxCount = CS.XGame.ClientConfig:GetInt("PicCompositionGetMaxCount")
    local PicCompositionBeforStartIndex = 0
    local PicCompositionAfterStartIndex = 0
    local CurCompositionIndex = 0
    local PicCompositionAllCount = 0
    local PicCompositionGetedScheduleIds = {}
    local PicCompositionLikeList = {}
    local PicCompositionRankRewardInfo = {}
    local PicCompositionRankResultList = {}

    local GetMyCompositionRequest = nil
    local GetOtherCompositionRequest = nil
    local GetRankDataRequest = nil
    local GetTrueWordRequest = nil

    local LastSyncRankTimes = 0
    local LastSyncTokenTimes = 0
    local LastSyncPraiseTimes = 0
    local LastSyncMyCompositionTimes = 0
    local LastSyncUploadTimes = 0
    local LastSyncOtherCompositionTimes = {}

    local VoteTokenExpireTime = 0

    local SIGNSALT = "YzcmCZNvbXocrsz9dm8e"
    local SALTINDEX = 50
    
    local RANKSYNC_SECOND = 10
    local PRAISESYNC_SECOND = 2
    local UPLOADSYNC_SECOND = 6
    local MYDATASYNC_SECOND = 30
    local OTHERDATASYNC_SECOND = 30
    local TOKENSYNC_SECOND = 40
    local ERROR_CODE = {
        ActivityId = 10000,
        Rank = 10006,
        User = 10008,
    }

    local METHOD_NAME = {
        PraiseRequest = "PraiseRequest",
        UploadCommentRequest = "UploadCommentRequest",
        GetCommentScheduleRewardRequest = "GetCommentScheduleRewardRequest",
        MarketVoteTokenRequest = "MarketVoteTokenRequest"
    }

    local PicComposition_Url = {
        GetUser = "/activity/public/user/get?",
        GetFavorRank = "/activity/public/favor_rank/get?",
        GetTimeRank = "/activity/public/time_rank/get?",
        GetArticle = "/activity/public/article/get?",
        GetTrueWord = "/web/bad_words/replace?",
    }

    local TrueWordUrl = {
        BaseUrl = "http://47.112.80.27:10010",
    }

    function XMarketingActivityManager.Init()
        ActivityList = XMarketingActivityConfigs.GetMarketingActivityConfig()
        CharacterList = XMarketingActivityConfigs.GetCompositionCharacterConfigs()
        PicCompositionCfg = XMarketingActivityConfigs.GetPicCompositionConfigs()
        PicCompositionRankRewardInfo = XMarketingActivityConfigs.GetPicCompositionRankRewardInfoConfigs()
        WindowsInlayActivityList = XMarketingActivityConfigs.GetWindowsInlayActivityConfig()
    end
    ------------------------------看图作文相关---------------------------------->>>
    function XMarketingActivityManager.GetActivityList()
        local list = {}
        if not ActivityList then
            return list
        end
        for _, activity in pairs(ActivityList) do
            tableInsert(list, activity)
        end
        tableSort(list, function(a, b)
                return a.Priority > b.Priority
            end)
        return list
    end

    function XMarketingActivityManager.GetCharacterList()
        local list = {}
        if not CharacterList then
            return list
        end
        for _, character in pairs(CharacterList) do
            tableInsert(list, character)
        end
        tableSort(list, function(a, b)
                return a.Id < b.Id
            end)
        return list
    end

    function XMarketingActivityManager.GetPicCompositionInfo()
        return PicCompositionCfg
    end

    function XMarketingActivityManager.GetPicCompositionMemoMax()
        return PicCompositionMemoMax
    end

    function XMarketingActivityManager.GetPicCompositionGetMaxCount()
        return PicCompositionGetMaxCount
    end

    function XMarketingActivityManager.GetPicCompositionBeforStartIndex()
        return PicCompositionBeforStartIndex
    end

    function XMarketingActivityManager.GetPicCompositionAfterStartIndex()
        return PicCompositionAfterStartIndex
    end

    function XMarketingActivityManager.GetPicCompositionAllCount()
        return PicCompositionAllCount
    end

    function XMarketingActivityManager.GetUpLoadDayCount()
        return PicCompositionUpLoadDayCount
    end

    function XMarketingActivityManager.GetUpLoadMaxCount()
        return PicCompositionUpLoadMaxCount
    end

    function XMarketingActivityManager.GetGetedScheduleIds()
        return PicCompositionGetedScheduleIds
    end

    function XMarketingActivityManager.GetPicCompositionLikeList()
        return PicCompositionLikeList
    end

    function XMarketingActivityManager.GetPicCompositionRankResultList()
        return PicCompositionRankResultList
    end

    function XMarketingActivityManager.GetPicCompositionRankRewardInfoList()
        local list = {}
        if not PicCompositionRankRewardInfo then
            return list
        end
        for _, info in pairs(PicCompositionRankRewardInfo) do
            tableInsert(list, info)
        end
        return list
    end

    function XMarketingActivityManager.GetNowActivityId()
        return PicCompositionActivityId or 0
    end

    function XMarketingActivityManager.GetMyCompositionDataListByType(type)
        local list = {}
        local myCompositionDatalist = MyCompositionDataList[type]

        if not myCompositionDatalist then
            return list
        end
        for _, data in pairs(myCompositionDatalist) do
            tableInsert(list, data)
        end
        if type == XMarketingActivityConfigs.CompositionType.Examined then
            tableSort(list, function(a, b)
                    if a.Hot ~= b.Hot then
                        return a.Hot > b.Hot
                    else
                        return a.ReviewTime > b.ReviewTime
                    end
                end)
        end
        return list
    end

    function XMarketingActivityManager.GetMyCompositionDataList()
        local list = {}
        local dialogueData = XMarketingActivityManager.GetMyCompositionDataListByType(
            XMarketingActivityConfigs.CompositionType.Examined)

        for _, data in pairs(dialogueData) do
            tableInsert(list, data)
        end

        dialogueData = XMarketingActivityManager.GetMyCompositionDataListByType(
            XMarketingActivityConfigs.CompositionType.Examining)

        for _, data in pairs(dialogueData) do
            tableInsert(list, data)
        end

        dialogueData = XMarketingActivityManager.GetMyCompositionDataListByType(
            XMarketingActivityConfigs.CompositionType.UnExamine)

        for _, data in pairs(dialogueData) do
            tableInsert(list, data)
        end

        dialogueData = XMarketingActivityManager.GetMyCompositionDataListByType(
            XMarketingActivityConfigs.CompositionType.Memo)

        for _, data in pairs(dialogueData) do
            tableInsert(list, data)
        end
        return list
    end

    function XMarketingActivityManager.GetPicCompositionTaskDatas()
        if PicCompositionActivityId == 0 then
            return nil
        end
        local infoList = XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()
        local taskGroupId = infoList[PicCompositionActivityId].LimitTaskId
        if taskGroupId == 0 then return {} end
        return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
    end

    function XMarketingActivityManager.GetOtherCompositionDataList(sortType)
        local list = {}
        local otherCompositionDataList = OtherCompositionDataList[sortType][CurCompositionIndex]

        if not otherCompositionDataList then
            return list
        end

        for _, data in pairs(otherCompositionDataList) do
            tableInsert(list, data)
        end
        return list
    end

    function XMarketingActivityManager.GetRankCompositionDataList()
        local list = {}
        if not RankCompositionDataList then
            return list
        end
        for _, data in pairs(RankCompositionDataList) do
            tableInsert(list, data)
        end
        return list
    end

    function XMarketingActivityManager.GetUpLoadTime(IsInt)
        if PicCompositionActivityId == 0 then
            return 0, 0
        end

        local infoList = XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()
        local uploadBeginTimeStr = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].UploadBeginTimeStr)
        local uploadEndTimeStr = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].UploadEndTimeStr)

        if IsInt then
            return uploadBeginTimeStr, uploadEndTimeStr
        end

        return infoList[PicCompositionActivityId].UploadBeginTimeStr, infoList[PicCompositionActivityId].UploadEndTimeStr
    end

    function XMarketingActivityManager.GetPicCompositionTime(type)
        if PicCompositionActivityId == 0 then
            return nil
        end

        local infoList = XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()
        local beginTime = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].BeginTimeStr)
        local endTime = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].EndTimeStr)
        local uploadBeginTime = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].UploadBeginTimeStr)
        local uploadEndTime = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].UploadEndTimeStr)

        if type == XMarketingActivityConfigs.TimeDataType.BeginTime then
            return beginTime
        elseif type == XMarketingActivityConfigs.TimeDataType.EndTime then
            return endTime
        elseif type == XMarketingActivityConfigs.TimeDataType.UploadBeginTime then
            return uploadBeginTime
        elseif type == XMarketingActivityConfigs.TimeDataType.UploadEndTime then
            return uploadEndTime
        end

        return nil
    end

    function XMarketingActivityManager.SetNowActivityId(id)
        PicCompositionActivityId = id
    end

    function XMarketingActivityManager.SetGetedScheduleIds(ids)
        if not ids then
            return
        end

        for _, id in pairs(ids) do
            PicCompositionGetedScheduleIds[id] = id
        end
    end

    function XMarketingActivityManager.AddGetedScheduleIds(id)
        PicCompositionGetedScheduleIds[id] = id
    end

    function XMarketingActivityManager.AddPicCompositionLike(id)
        PicCompositionLikeList[id] = id
    end

    function XMarketingActivityManager.SetPicCompositionRankResultList(list)
        PicCompositionRankResultList = list
    end

    function XMarketingActivityManager.ResetPicCompositionRankResultList()
        PicCompositionRankResultList = {}
    end

    function XMarketingActivityManager.ResetPicCompositionStartIndex()
        PicCompositionBeforStartIndex = 0
        PicCompositionAfterStartIndex = 0
        CurCompositionIndex = 0
    end

    function XMarketingActivityManager.ClearOtherCompositionDataList(sortType)
        OtherCompositionDataList[sortType] = {}
    end

    function XMarketingActivityManager.CheckIsCanUpLoad()
        if PicCompositionActivityId == 0 then
            return XMarketingActivityConfigs.TimeType.Out
        end

        local infoList = XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()
        local nowTime = XTime.GetServerNowTimestamp()
        local beginTimeStr = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].BeginTimeStr)
        local endTimeStr = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].EndTimeStr)
        local uploadBeginTimeStr = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].UploadBeginTimeStr)
        local uploadEndTimeStr = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].UploadEndTimeStr)

        if nowTime > beginTimeStr and nowTime < uploadBeginTimeStr then
            return XMarketingActivityConfigs.TimeType.Before
        elseif nowTime > uploadBeginTimeStr and nowTime < uploadEndTimeStr then
            return XMarketingActivityConfigs.TimeType.In
        elseif nowTime > uploadEndTimeStr and nowTime < endTimeStr then
            return XMarketingActivityConfigs.TimeType.After
        end

        return XMarketingActivityConfigs.TimeType.Out
    end

    function XMarketingActivityManager.CheckIsIntime()
        if PicCompositionActivityId == 0 then
            return false
        end

        local infoList = XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()
        local nowTime = XTime.GetServerNowTimestamp()
        local beginTimeStr = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].BeginTimeStr)
        local endTimeStr = XTime.ParseToTimestamp(infoList[PicCompositionActivityId].EndTimeStr)

        if nowTime > beginTimeStr and nowTime < endTimeStr then
            return true
        end

        return false
    end

    function XMarketingActivityManager.CheckAnyTaskFinished()
        local taskDatas = XMarketingActivityManager.GetPicCompositionTaskDatas()
        if not taskDatas then
            return false
        end

        local achieved = XDataCenter.TaskManager.TaskState.Achieved
        for _, taskData in pairs(taskDatas or {}) do
            if taskData.State == achieved then
                return true
            end
        end

        return false
    end

    function XMarketingActivityManager.CheckHasActiveTaskReward()
        if PicCompositionActivityId == 0 then
            return false
        end
        local infoList = XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()
        local taskItem = infoList[PicCompositionActivityId].ScheduleItemId
        local curActivenes = XDataCenter.ItemManager.GetCount(taskItem)
        local ActivenesDatas = XMarketingActivityConfigs.GetPicCompositionScheduleRewardInfoConfigs()
        for _, activenesData in pairs(ActivenesDatas) do
            if activenesData.Schedule <= curActivenes and (not XMarketingActivityManager.IsGetedScheduleReward(activenesData.Id)) then
                return true
            end
        end
        return false
    end

    function XMarketingActivityManager.CheckItemEnough(count)
        local infoList = XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()
        return count >= infoList[PicCompositionActivityId].PraiseConsume
    end

    function XMarketingActivityManager.IsGetedScheduleReward(id)
        if PicCompositionGetedScheduleIds[id] then
            return true
        end
        return false
    end

    function XMarketingActivityManager.IsDoPicCompositionLike(id)
        if PicCompositionLikeList[id] then
            return true
        end
        return false
    end

    function XMarketingActivityManager.SetMemoDialogue()
        MyCompositionDataList[XMarketingActivityConfigs.CompositionType.Memo] = {}
        for id = 1, PicCompositionMemoMax do
            local dialogue = XSaveTool.GetData(string.format("%d%d%s", XPlayer.Id, id, "PicCompositionMemo"))
            if dialogue then
                local memo = {}
                memo.Type = XMarketingActivityConfigs.CompositionType.Memo
                memo.Dialogue = dialogue.Memo
                memo.MemoId = id
                tableInsert(MyCompositionDataList[memo.Type], memo)
            end
        end
    end

    function XMarketingActivityManager.AddMemoDialogue(id, dialogue)
        if dialogue then
            local memo = {}
            memo.Type = XMarketingActivityConfigs.CompositionType.Memo
            memo.Dialogue = dialogue
            memo.MemoId = id
            if not MyCompositionDataList[memo.Type] then
                MyCompositionDataList[memo.Type] = {}
            end
            tableInsert(MyCompositionDataList[memo.Type], memo)
        end
    end

    function XMarketingActivityManager.SaveMemoDialogue(memo, curMemoId, cb)
        if PicCompositionActivityId == 0 then
            XLog.Error("PicCompositionActivityId Is Error")
            return
        end
        if not curMemoId and #MyCompositionDataList[XMarketingActivityConfigs.CompositionType.Memo] >= PicCompositionMemoMax then
            local text = CS.XTextManager.GetText("PicCompositionMemoMax", #MyCompositionDataList[XMarketingActivityConfigs.CompositionType.Memo], PicCompositionMemoMax)
            XUiManager.TipMsg(text)
            return
        end
        local memoId = curMemoId and curMemoId or #MyCompositionDataList[XMarketingActivityConfigs.CompositionType.Memo] + 1

        local data = {}
        data.ActivityId = PicCompositionActivityId
        data.Memo = memo
        XSaveTool.SaveData(string.format("%d%d%s", XPlayer.Id, memoId, "PicCompositionMemo"), data)
        local text
        if not curMemoId then
            XDataCenter.MarketingActivityManager.AddMemoDialogue(memoId, memo)
            text = CS.XTextManager.GetText("PicCompositionSave", memoId, PicCompositionMemoMax)
        else
            XDataCenter.MarketingActivityManager.SetMemoDialogue()
            text = CS.XTextManager.GetText("PicCompositionEdit")
        end

        XUiManager.TipMsg(text)
        if cb then cb() end
    end

    function XMarketingActivityManager.DelectTimeOverMemoDialogue()
        if PicCompositionActivityId == 0 then
            return
        end
        for index = 1, PicCompositionMemoMax do
            local data = XSaveTool.GetData(string.format("%d%d%s", XPlayer.Id, index, "PicCompositionMemo"))
            if data and data.ActivityId ~= PicCompositionActivityId then
                XSaveTool.RemoveData(string.format("%d%d%s", XPlayer.Id, index, "PicCompositionMemo"))
            end
        end
    end

    function XMarketingActivityManager.DelectMemoDialogue(index)
        if PicCompositionActivityId == 0 then
            return
        end
        if not index then
            return
        end
        if XSaveTool.GetData(string.format("%d%d%s", XPlayer.Id, index, "PicCompositionMemo")) then
            XSaveTool.RemoveData(string.format("%d%d%s", XPlayer.Id, index, "PicCompositionMemo"))
        end
    end

    function XMarketingActivityManager.IsCanAutoOpenGuide() --判断是否可以自动打开图文教学
        local data = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "PicCompositionGuide"))
        if not data then
            XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "PicCompositionGuide"), true)
            return true
        end
        return false
    end

    function XMarketingActivityManager.GiveUploadComment(Composition, cb)
        local now = XTime.GetServerNowTimestamp()
        local syscTime = LastSyncUploadTimes

        if syscTime and now - syscTime < UPLOADSYNC_SECOND then
            local text = CS.XTextManager.GetText("PicCompositionfrequencyHint", UPLOADSYNC_SECOND)
            XUiManager.TipMsg(text)
            return
        end
        XNetwork.Call(METHOD_NAME.UploadCommentRequest, { CommentInfos = Composition }, function(res)
                if res.Code ~= XCode.Success then
                    if res.ErrorIndex and res.ErrorIndex > 0 then
                        local text = CS.XTextManager.GetText("PicCompositionErrorText", res.ErrorIndex)
                        XUiManager.TipMsg(text)
                    else
                        XUiManager.TipCode(res.Code)
                    end
                    LastSyncUploadTimes = XTime.GetServerNowTimestamp()
                    return
                end
                LastSyncUploadTimes = XTime.GetServerNowTimestamp()
                XUiManager.TipText("PicCompositionUpLoad")
                if cb then cb() end
            end)
    end


    function XMarketingActivityManager.GivePraise(id, cb)
        local now = XTime.GetServerNowTimestamp()
        local syscTime = LastSyncPraiseTimes

        if syscTime and now - syscTime < PRAISESYNC_SECOND then
            local text = CS.XTextManager.GetText("PicCompositionfrequencyHint", PRAISESYNC_SECOND)
            XUiManager.TipMsg(text)
            return
        end

        XNetwork.Call(METHOD_NAME.PraiseRequest, { CommentId = id }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XUiManager.TipText("PicCompositionPraise")
                XMarketingActivityManager.AddPicCompositionLike(id)
                LastSyncPraiseTimes = XTime.GetServerNowTimestamp()
                if cb then cb() end
            end)
    end

    function XMarketingActivityManager.GetCommentScheduleReward(id, cb)
        XNetwork.Call(METHOD_NAME.GetCommentScheduleRewardRequest, { Id = id }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XUiManager.OpenUiObtain(res.RewardGoodsList)
                XMarketingActivityManager.AddGetedScheduleIds(id)
                XEventManager.DispatchEvent(XEventId.EVENT_TASK_SYNC)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_TASK_SYNC)
                if cb then cb() end
            end)
    end

    function XMarketingActivityManager.InitMyCompositionDataList()
        local now = XTime.GetServerNowTimestamp()
        local syscTime = LastSyncMyCompositionTimes

        if syscTime and now - syscTime < MYDATASYNC_SECOND then
            XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_MYDATA, true)
            return
        end

        if GetMyCompositionRequest then
            return
        end

        MyCompositionDataList = {}
        local url = string.format("%s%s", CS.XRemoteConfig.PicComposition, PicComposition_Url.GetUser)
        local activityId = string.format("activityId=%d", PicCompositionActivityId)
        local userId = string.format("&userId=%d", XPlayer.Id)
        local sign = string.format("&sign=%s", CS.XTool.ToSHA1(string.format("%s%s%s", activityId, userId, SIGNSALT)))
        url = string.format("%s%s%s%s", url, activityId, userId, sign)
        GetMyCompositionRequest = CS.UnityEngine.Networking.UnityWebRequest.Get(url)
        GetMyCompositionRequest.timeout = CS.XGame.Config:GetInt("LoginTimeOutInterval")
        CS.XTool.WaitNativeCoroutine(GetMyCompositionRequest:SendWebRequest(), function()
                if GetMyCompositionRequest.isNetworkError then
                    XLog.Error("network error，url is " .. url .. ", message is " .. GetMyCompositionRequest.error)
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_MYDATA, false)
                    return
                end

                if GetMyCompositionRequest.isHttpError then
                    XLog.Error("http error，url is " .. url .. ", message is " .. GetMyCompositionRequest.error)
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_MYDATA, false)
                    return
                end

                local result = Json.decode(GetMyCompositionRequest.downloadHandler.text)
                if result.status ~= 0 then
                    if result.status == ERROR_CODE.ActivityId then
                        XLog.Error("ActivityId error，ActivityId is " .. PicCompositionActivityId)
                    end
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_MYDATA, false)
                    return
                end

                GetMyCompositionRequest:Dispose()
                GetMyCompositionRequest = nil

                PicCompositionUpLoadDayCount = result.data.remainTodayUploadTimes
                PicCompositionUpLoadMaxCount = result.data.remainActivityUploadTimes
                PicCompositionLikeList = {}
                for _, favor in pairs(result.data.favors) do
                    PicCompositionLikeList[favor] = favor
                end
                for _, article in pairs(result.data.articles) do
                    local composition = {}
                    composition.Id = article.articleId
                    composition.Type = article.state
                    composition.ReviewTime = article.reviewTimeStamp
                    composition.Dialogue = Json.decode(article.content)
                    composition.Hot = article.scores
                    if not MyCompositionDataList[composition.Type] then
                        MyCompositionDataList[composition.Type] = {}
                    end
                    tableInsert(MyCompositionDataList[composition.Type], composition)
                end
                LastSyncMyCompositionTimes = XTime.GetServerNowTimestamp()
                XMarketingActivityManager.SetMemoDialogue()
                XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_MYDATA, true)
            end)
    end

    function XMarketingActivityManager.InitOtherCompositionDataList(sortType, getType)
        local now = XTime.GetServerNowTimestamp()
        local syscTime = LastSyncOtherCompositionTimes[sortType]
        if not syscTime or now - syscTime > OTHERDATASYNC_SECOND then
            XMarketingActivityManager.ClearOtherCompositionDataList(sortType)
        end

        local url
        if sortType == XMarketingActivityConfigs.SortType.Hot then
            url = string.format("%s%s", CS.XRemoteConfig.PicComposition, PicComposition_Url.GetFavorRank)
        else
            url = string.format("%s%s", CS.XRemoteConfig.PicComposition, PicComposition_Url.GetTimeRank)
        end

        if getType == XMarketingActivityConfigs.GetType.Before then
            PicCompositionBeforStartIndex = (PicCompositionBeforStartIndex - PicCompositionGetMaxCount) > 0 and
            (PicCompositionBeforStartIndex - PicCompositionGetMaxCount) or 0
            PicCompositionAfterStartIndex = PicCompositionBeforStartIndex + PicCompositionGetMaxCount
        end

        CurCompositionIndex = getType == XMarketingActivityConfigs.GetType.Before and
        CurCompositionIndex - 1 or CurCompositionIndex + 1

        if not OtherCompositionDataList[sortType][CurCompositionIndex] then
            OtherCompositionDataList[sortType][CurCompositionIndex] = {}
        else
            if getType == XMarketingActivityConfigs.GetType.After then
                PicCompositionAfterStartIndex = PicCompositionAfterStartIndex + PicCompositionGetMaxCount
                PicCompositionBeforStartIndex = PicCompositionAfterStartIndex - PicCompositionGetMaxCount
            end
            XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_OTHERDATA, true, getType)
            return
        end


        local activityId = string.format("activityId=%d", PicCompositionActivityId)
        local index = getType == XMarketingActivityConfigs.GetType.Before and PicCompositionBeforStartIndex or PicCompositionAfterStartIndex
        local startStr = string.format("&start=%d", index)
        local lengthStr = string.format("&length=%d", PicCompositionGetMaxCount)
        local sign = string.format("&sign=%s", CS.XTool.ToSHA1(string.format("%s%s%s%s", activityId, startStr, lengthStr, SIGNSALT)))
        url = string.format("%s%s%s%s%s", url, activityId, startStr, lengthStr, sign)
        if GetOtherCompositionRequest then
            GetOtherCompositionRequest:Dispose()
        end
        GetOtherCompositionRequest = CS.UnityEngine.Networking.UnityWebRequest.Get(url)
        GetOtherCompositionRequest.timeout = CS.XGame.Config:GetInt("LoginTimeOutInterval")
        CS.XTool.WaitNativeCoroutine(GetOtherCompositionRequest:SendWebRequest(), function()
                if GetOtherCompositionRequest.isNetworkError then
                    XLog.Error("network error，url is " .. url .. ", message is " .. GetOtherCompositionRequest.error)
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_OTHERDATA, false, getType)
                    return
                end

                if GetOtherCompositionRequest.isHttpError then
                    XLog.Error("http error，url is " .. url .. ", message is " .. GetOtherCompositionRequest.error)
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_OTHERDATA, false, getType)
                    return
                end

                local ok, result = pcall(Json.decode, GetOtherCompositionRequest.downloadHandler.text)
                if not ok then
                    return
                end
                if result.status ~= 0 then
                    if result.status == ERROR_CODE.ActivityId then
                        XLog.Error("ActivityId error，ActivityId is " .. PicCompositionActivityId)
                    end
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_OTHERDATA, false, getType)
                    return
                end

                GetOtherCompositionRequest:Dispose()
                GetOtherCompositionRequest = nil

                PicCompositionAllCount = result.data.total
                if getType == XMarketingActivityConfigs.GetType.After then
                    PicCompositionAfterStartIndex = PicCompositionAfterStartIndex + PicCompositionGetMaxCount
                    PicCompositionBeforStartIndex = PicCompositionAfterStartIndex - PicCompositionGetMaxCount
                end
                for _, article in pairs(result.data.articles) do
                    local composition = {}
                    composition.Id = article.articleId
                    composition.Type = article.state
                    composition.UserName = article.userName
                    composition.ReviewTime = article.reviewTimeStamp
                    composition.Dialogue = Json.decode(article.content)
                    composition.UserId = tonumber(article.userId)
                    composition.Hot = article.scores
                    tableInsert(OtherCompositionDataList[sortType][CurCompositionIndex], composition)
                end
                local indexOffset = 2
                if OtherCompositionDataList[sortType][CurCompositionIndex + indexOffset] then
                    OtherCompositionDataList[sortType][CurCompositionIndex + indexOffset] = nil
                end
                if OtherCompositionDataList[sortType][CurCompositionIndex - indexOffset] then
                    OtherCompositionDataList[sortType][CurCompositionIndex - indexOffset] = nil
                end

                LastSyncOtherCompositionTimes[sortType] = XTime.GetServerNowTimestamp()
                XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_OTHERDATA, true, getType)

            end)
    end

    function XMarketingActivityManager.InitRankCompositionDataList()
        local now = XTime.GetServerNowTimestamp()
        local syscTime = LastSyncRankTimes

        if syscTime and now - syscTime < RANKSYNC_SECOND then
            XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_RANKDATA, true)
            return
        end

        if GetRankDataRequest then
            return
        end

        RankCompositionDataList = {}
        local infoList = XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()
        local rankNum = infoList[PicCompositionActivityId] and
        infoList[PicCompositionActivityId].RankNum or nil

        local url = string.format("%s%s", CS.XRemoteConfig.PicComposition, PicComposition_Url.GetFavorRank)
        local activityId = string.format("activityId=%d", PicCompositionActivityId)
        local startStr = string.format("&start=%d", 0)
        local lengthStr = string.format("&length=%d", rankNum)
        local sign = string.format("&sign=%s", CS.XTool.ToSHA1(string.format("%s%s%s%s", activityId, startStr, lengthStr, SIGNSALT)))
        url = string.format("%s%s%s%s%s", url, activityId, startStr, lengthStr, sign)
        GetRankDataRequest = CS.UnityEngine.Networking.UnityWebRequest.Get(url)
        GetRankDataRequest.timeout = CS.XGame.Config:GetInt("LoginTimeOutInterval")
        CS.XTool.WaitNativeCoroutine(GetRankDataRequest:SendWebRequest(), function()
                if GetRankDataRequest.isNetworkError then
                    XLog.Error("network error，url is " .. url .. ", message is " .. GetRankDataRequest.error)
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_RANKDATA, false)
                    return
                end

                if GetRankDataRequest.isHttpError then
                    XLog.Error("http error，url is " .. url .. ", message is " .. GetRankDataRequest.error)
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_RANKDATA, false)
                    return
                end

                local result = Json.decode(GetRankDataRequest.downloadHandler.text)
                if result.status ~= 0 then
                    if result.status == ERROR_CODE.ActivityId then
                        XLog.Error("ActivityId error，ActivityId is " .. PicCompositionActivityId)
                    end
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_RANKDATA, false)
                    return
                end

                GetRankDataRequest:Dispose()
                GetRankDataRequest = nil

                for _, article in pairs(result.data.articles) do
                    local composition = {}
                    composition.Id = article.articleId
                    composition.Type = article.state
                    composition.UserName = article.userName
                    composition.ReviewTime = article.reviewTimeStamp
                    composition.Dialogue = Json.decode(article.content)
                    composition.Hot = article.scores
                    composition.HeadPortraitId = tonumber(article.profileId)
                    composition.HeadFrameId = tonumber(article.headFrameId)
                    composition.UserId = tonumber(article.userId)
                    tableInsert(RankCompositionDataList, composition)
                end
                LastSyncRankTimes = XTime.GetServerNowTimestamp()
                XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_RANKDATA, true)
            end)
    end

    function XMarketingActivityManager.GetTrueWord(dialogueText, haveBadWordCb, notHaveBadWordCb, index)
        local url = string.format("%s%s", TrueWordUrl.BaseUrl, PicComposition_Url.GetTrueWord)
        --local enCodeText = CS.System.Net.WebUtility.UrlEncode(dialogueText)
        local content = string.format("content=%s", dialogueText)
        url = string.format("%s%s", url, content)

        if GetTrueWordRequest then
            GetTrueWordRequest:Dispose()
        end

        GetTrueWordRequest = CS.UnityEngine.Networking.UnityWebRequest.Get(url)
        GetTrueWordRequest.timeout = CS.XGame.Config:GetInt("LoginTimeOutInterval")
        CS.XTool.WaitNativeCoroutine(GetTrueWordRequest:SendWebRequest(), function()
                if GetTrueWordRequest.isNetworkError then
                    XLog.Error("network error，url is " .. url .. ", message is " .. GetTrueWordRequest.error)
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_WORD, false, nil, index)
                    return
                end

                if GetTrueWordRequest.isHttpError then
                    XLog.Error("http error，url is " .. url .. ", message is " .. GetTrueWordRequest.error)
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_WORD, false, nil, index)
                    return
                end

                local ok, result = pcall(Json.decode, GetTrueWordRequest.downloadHandler.text)
                if not ok then
                    return
                end
                if result.status ~= 0 then
                    if result.status == ERROR_CODE.ActivityId then
                        XLog.Error("ActivityId error，ActivityId is " .. PicCompositionActivityId)
                    end
                    XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_WORD, false, nil, index)
                    return
                end

                GetTrueWordRequest:Dispose()
                GetTrueWordRequest = nil

                local containBadWords = result.data.containBadWords
                local dataContent = result.data.content

                if containBadWords then
                    if haveBadWordCb then haveBadWordCb() end
                else
                    if notHaveBadWordCb then notHaveBadWordCb() end
                end

                XEventManager.DispatchEvent(XEventId.EVENT_PICCOMPOSITION_GET_WORD, true, dataContent, index)

            end)
    end
    ------------------------------看图作文相关----------------------------------<<<
    ------------------------------内嵌浏览器相关---------------------------------->>>

    function XMarketingActivityManager.GetWindowsInlayActivityList()
        local list = {}
        for _, activity in pairs(WindowsInlayActivityList) do
            tableInsert(list, activity)
        end
        tableSort(list, function(a, b)
                return a.Priority > b.Priority
            end)
        return list
    end

    function XMarketingActivityManager.GetWindowsInlayInTimeActivityList()
        local list = {}
        for _, activity in pairs(WindowsInlayActivityList) do
            local IsInTime = XMarketingActivityManager.CheckWindowsInlayActivityIsInTime(activity)
            if IsInTime then
                tableInsert(list, activity)
            end
        end
        tableSort(list, function(a, b)
                return a.Priority > b.Priority
            end)
        return list
    end

    function XMarketingActivityManager.GetWindowsInlayActivityById(id)
        return WindowsInlayActivityList[id]
    end

    function XMarketingActivityManager.GetWindowsInlayTokenByType(type)
        return WindowsInlayTokenList[type]
    end

    function XMarketingActivityManager.SetWindowsInlayToken(token,type)
        WindowsInlayTokenList[type] = token
    end

    function XMarketingActivityManager.CheckWindowsInlayActivityIsInTime(windowsInlayActivity)
        if not windowsInlayActivity then
            return false
        end
        local nowTime = XTime.GetServerNowTimestamp()
        local beginTimeStr = XTime.ParseToTimestamp(windowsInlayActivity.BeginTimeStr)
        local endTimeStr = XTime.ParseToTimestamp(windowsInlayActivity.EndTimeStr)

        return not beginTimeStr or (nowTime > beginTimeStr and nowTime < endTimeStr)
    end

    function XMarketingActivityManager.IsShowWindowsInlayRedPoint()
        local freshTime = XTime.GetSeverTodayFreshTime()
        local data = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "WindowsInlayRedPoint"))
        if data then
            if freshTime > data then
                return true
            else
                return false
            end
        else
            return true
        end
    end
    
    function XMarketingActivityManager.GetSignUrl(Url)
        local urlData = {}
        local keyList = {
            "roleId",
            "serverId",
            "time",
            "deviceNumber",
            }
        urlData["roleId"] = string.format("roleId=%d", XPlayer.Id)
        urlData["serverId"] = string.format("serverId=%s", CS.XHeroBdcAgent.ServerId)
        urlData["time"] = string.format("time=%d", XTime.GetServerNowTimestamp())
        urlData["deviceNumber"] = string.format("deviceNumber=%s", CS.UnityEngine.SystemInfo.deviceUniqueIdentifier)
        table.sort(keyList,function (a, b)
            return string.byte(a) < string.byte(b)
        end)
        local tmpUrl = string.format("%s&%s&%s&%s", urlData[keyList[1]], urlData[keyList[2]], urlData[keyList[3]], urlData[keyList[4]])
        local saltUrl = XMarketingActivityManager.AddSalt(tmpUrl)
        local sign = string.format("&sign=%s", CS.XTool.ToSHA1(saltUrl))
        local url = string.format("%s?%s%s", Url, tmpUrl, sign)
        return url
    end
    
    function XMarketingActivityManager.AddSalt(Url)
        local strLen = string.len(Url)
        local tagStr = Url
        if strLen <= SALTINDEX then
            tagStr = string.format("%s%s", tagStr, SIGNSALT)
        else
            local exStr = string.sub(tagStr, 1, SALTINDEX)
            local afStr = string.sub(tagStr, SALTINDEX + 1)
            tagStr = string.format("%s%s%s", exStr, SIGNSALT, afStr)
        end
        return tagStr
    end

    function XMarketingActivityManager.MarkWindowsInlayRedPoint()
        local freshTime = XTime.GetSeverTodayFreshTime()
        local data = XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "WindowsInlayRedPoint"))
        if data then
            if freshTime > data then
                XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "WindowsInlayRedPoint"), freshTime)
            end
        else
            XSaveTool.SaveData(string.format("%d%s", XPlayer.Id, "WindowsInlayRedPoint"), freshTime)
        end
    end

    function XMarketingActivityManager.RequestVoteToken(type, cb)
        local now = XTime.GetServerNowTimestamp()
        if now < VoteTokenExpireTime then --根据token的保质期来判断是否需要重新请求
            if cb then cb() end
            return
        end
        XNetwork.Call(METHOD_NAME.MarketVoteTokenRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                VoteTokenExpireTime = res.ExpireTime--Token的过期时间
                XMarketingActivityManager.SetWindowsInlayToken(res.Token,type)
                if cb then cb() end
            end)
    end
    ------------------------------内嵌浏览器相关----------------------------------<<<
    XMarketingActivityManager.Init()
    return XMarketingActivityManager
end



XRpc.NotifyCommentRankResult = function(data)
    XDataCenter.MarketingActivityManager.SetPicCompositionRankResultList(data)
end

XRpc.NotifyProductCommentData = function(data)
    XDataCenter.MarketingActivityManager.SetNowActivityId(data.Id)
    XDataCenter.MarketingActivityManager.SetGetedScheduleIds(data.ScheduleIds)
end