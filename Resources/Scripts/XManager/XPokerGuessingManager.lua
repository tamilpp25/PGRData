XPokerGuessingMangerCreator = function()
    local XPokerGuessingManager = {}


    local _CurrActivityId =  XPokerGuessingConfig.GetDefaultActivityId()

    ---------玩法相关 begin-------
    --数据结构 GuessInfo
    --比赛状态 PokerGuessingStatusType ActivityStatus
    --明牌的Id int DisplayCardId
    --当前积分 int CurrentWinCounts
    --记牌器列表 List<int> RecordCardIds

    local _LastCardId = 0
    local _LastGuessType = 0
    local _DisplayCardId = 0
    local _CurrentScore = 0
    local _RecordCardIdsDic = {}
    local _CurrGameStatus = 0
    local _OldScore = 0
    local _RequestLock = false
    local _IsEnterCost = true

    local UpdateGuessingInfo = function(guessInfo)
        if not guessInfo then return end
        _LastCardId = _DisplayCardId
        _CurrentScore = guessInfo.CurrentWinCounts
        _DisplayCardId = guessInfo.DisplayCardId
        _CurrGameStatus = guessInfo.ActivityStatus
        _IsEnterCost = guessInfo.IsEnterCost
        _RecordCardIdsDic = {}
        if guessInfo.RecordCardIds then
            for _,id in pairs(guessInfo.RecordCardIds) do
                _RecordCardIdsDic[id] = id
            end
        end
    end

    function XPokerGuessingManager.IsInRecordCardDic(id)
        return _RecordCardIdsDic[id] or false
    end

    function XPokerGuessingManager.GetDisplayCardId()
        return _DisplayCardId
    end

    function XPokerGuessingManager.GetCurrentScore()
        return _CurrentScore
    end

    function XPokerGuessingManager.GetCurrGameStatus()
        return _CurrGameStatus
    end

    function XPokerGuessingManager.GetOldScore()
        return _OldScore
    end

    function XPokerGuessingManager.GetIsEnterCost()
        return _IsEnterCost
    end

    function XPokerGuessingManager.GetResult()
        local lastNum = XPokerGuessingConfig.GetCardNumber(_LastCardId)
        local currNum = XPokerGuessingConfig.GetCardNumber(_DisplayCardId)
        if lastNum == currNum then return XPokerGuessingConfig.GameStatus.Drawn end
        local isWin = _LastGuessType == XPokerGuessingConfig.GuessType.Greater and (currNum > lastNum) or (currNum < lastNum)
        return isWin and XPokerGuessingConfig.GameStatus.Victory or XPokerGuessingConfig.GameStatus.Failed
    end
    function XPokerGuessingManager.IsContinueGuessRequest(isContinue)
        if _RequestLock then return end
        _RequestLock = true
        local req = {IsContinue = isContinue}
        XNetwork.Call("IsContinueGuessRequest",req,function(rsp)
            _RequestLock = false
            if rsp.Code ~= XCode.Success then
                XUiManager.TipCode(rsp.Code)
                return
            end
            UpdateGuessingInfo(rsp.GuessInfo)
            CS.XGameEventManager.Instance:Notify(XEventId.EVENT_POKER_GUESSING_UPDATE_STATE)
        end)
    end

    function XPokerGuessingManager.StartNewPokerGuessingRequest(cb)
        if _RequestLock then return end
        _RequestLock = true
        XNetwork.Call("StartNewPokerGuessingRequest",nil,function(rsp)
            _RequestLock = false
            if rsp.Code ~= XCode.Success then
                XUiManager.TipCode(rsp.Code)
                return
            end
            UpdateGuessingInfo(rsp.GuessInfo)
            CS.XGameEventManager.Instance:Notify(XEventId.EVENT_POKER_GUESSING_UPDATE_STATE)
            if cb then
                cb()
            end
        end)
    end

    function XPokerGuessingManager.GuessCompareRequest(guessType,cb)
        if _RequestLock then return end
        _RequestLock = true
        local req = {GuessType = guessType}
        _LastGuessType = guessType
        XNetwork.Call("GuessCompareRequest",req,function(rsp)
            _RequestLock = false
            if rsp.Code ~= XCode.Success then
                XUiManager.TipCode(rsp.Code)
                return
            end
            _OldScore = _CurrentScore
            UpdateGuessingInfo(rsp.GuessInfo)
            CS.XGameEventManager.Instance:Notify(XEventId.EVENT_POKER_GUESSING_UPDATE_STATE)
            if cb then
                cb()
            end
        end)
    end

    ---------玩法相关 end---------
    ---------配置相关 begin-------
    function XPokerGuessingManager.GetBackAssetPath()
        return XPokerGuessingConfig.GetBackAssetPath(_CurrActivityId)
    end

    function XPokerGuessingManager.GetCostItemName()
        return XPokerGuessingConfig.GetCostItemName(_CurrActivityId)
    end

    function XPokerGuessingManager.GetCostItemCount()
        return XPokerGuessingConfig.GetCostItemCount(_CurrActivityId)
    end

    function XPokerGuessingManager.GetCostItemIcon()
        return XPokerGuessingConfig.GetCostItemIcon(_CurrActivityId)
    end

    function XPokerGuessingManager.GetShopSkipId()
        return XPokerGuessingConfig.GetShopSkipId(_CurrActivityId)
    end

    function XPokerGuessingManager.GetPokerGroup()
        return XPokerGuessingConfig.GetPokerGroup(_CurrActivityId)
    end

    ---------配置相关 end---------


    ---------活动相关 begin-------

    function XPokerGuessingManager.OnOpenMain()
        XSaveTool.SaveData(XPokerGuessingManager.GetPlayerPrefsKey(), true)
        XLuaUiManager.Open("UiFubenPokerGuessing")
    end

    function XPokerGuessingManager.OnActivityEnd()

    end

    function XPokerGuessingManager.GetStartTime()
        return XFunctionManager.GetStartTimeByTimeId(XPokerGuessingConfig.GetActivityTimeId(_CurrActivityId))
    end

    function XPokerGuessingManager.GetEndTime()
        return XFunctionManager.GetEndTimeByTimeId(XPokerGuessingConfig.GetActivityTimeId(_CurrActivityId))
    end

    function XPokerGuessingManager.IsOpen()
        return XFunctionManager.CheckInTimeByTimeId(XPokerGuessingConfig.GetActivityTimeId(_CurrActivityId))
    end

    function XPokerGuessingManager.GetChapters()
        local chapters = {}
        if XPokerGuessingManager.IsOpen() then
            local tempChapter = {}
            tempChapter.Id = _CurrActivityId
            tempChapter.Name = XPokerGuessingConfig.GetActivityName(_CurrActivityId)
            tempChapter.Type = XDataCenter.FubenManager.ChapterType.PokerGuessing
            tempChapter.BannerBg = XPokerGuessingConfig.GetBannerBg(_CurrActivityId)
            table.insert(chapters, tempChapter)
        end
        return chapters
    end

    function XPokerGuessingManager.GetPlayerPrefsKey()
        local severNextRefreshTime = XTime.GetSeverNextRefreshTime()
        return string.format("%s_%s_%s", XPlayer.Id, "PokerGuessingBannerRed", severNextRefreshTime)
    end

    function XPokerGuessingManager.CheckBannerRedPoint()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.PokerGuessing) then
            return false
        end
        if not XPokerGuessingManager.IsOpen() then
            return false
        end
        local taskList = XDataCenter.TaskManager.GetPokerGuessingTaskList()
        for k,v in pairs(taskList) do
            if XDataCenter.TaskManager.CheckTaskAchieved(v.Id) then
                return true
            end
        end
        if XSaveTool.GetData(XPokerGuessingManager.GetPlayerPrefsKey()) then
            return false
        end
        local taskList = XDataCenter.TaskManager.GetPokerGuessingTaskList()
        for _,task in pairs(taskList) do
            if task.State == XDataCenter.TaskManager.TaskState.Active then
                return true
            end
        end
        return false
    end
    ---------活动相关 end --------

    ---------推送相关 begin --------

    function XPokerGuessingManager.NotifyPokerGuessingData(data)
        if not data then return end
        if data.ActivityId ~= 0 then
            _CurrActivityId = data.ActivityId
        elseif data.ActivityId == 0 then
            CS.XGameEventManager.Instance:Notify(XEventId.EVENT_POKER_GUESSING_ACTIVITY_END)
        end
        UpdateGuessingInfo(data.GuessInfo)
    end

    ---------推送相关 end ----------

    return XPokerGuessingManager
end

XRpc.NotifyPokerGuessingData = function(data)
    XDataCenter.PokerGuessingManager.NotifyPokerGuessingData(data)
end

