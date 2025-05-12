XPokerGuessingMangerCreator = function()
    local XPokerGuessingManager = {}

    local XPokerGuessing = require("XEntity/XPokerGuessing/XPokerGuessing")

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
    local _PokerGuessing
    local _HintTipKey = "HintTipKey"
    local _UnLockStoryKey = "UnLockStoryKey_"

    --region   ------------------HintTip start-------------------
    local ClearHintTip = function()
        local key = XPokerGuessingManager.GetCookiesKey(_HintTipKey)
        XSaveTool.RemoveData(key)
    end
    
    local HintTipStatus = function()
        local key =  XPokerGuessingManager.GetCookiesKey(_HintTipKey)
        local updateTime = XSaveTool.GetData(key)
        if not updateTime then
            return false
        end
        
        return XTime.GetServerNowTimestamp() < updateTime
    end
    
    local MarkHintTip = function(select)
        local key = XPokerGuessingManager.GetCookiesKey(_HintTipKey)
        if select then
            if HintTipStatus() then
                return
            end
            local updateTime = XTime.GetSeverTomorrowFreshTime()
            XSaveTool.SaveData(key, updateTime)
        else
            ClearHintTip()
        end
    end

    --endregion------------------HintTip finish------------------

    local UpdateGuessingInfo = function(guessInfo)
        if not guessInfo then return end
        if XTool.IsNumberValid(_DisplayCardId) then
            _LastCardId = _DisplayCardId
        elseif not XTool.IsTableEmpty(guessInfo.RecordCardIds) then
            local count = #guessInfo.RecordCardIds
            _LastCardId = guessInfo.RecordCardIds[count]
        end
        _CurrentScore = guessInfo.CurrentWinCounts
        _DisplayCardId = guessInfo.DisplayCardId
        _CurrGameStatus = guessInfo.ActivityStatus
        _IsEnterCost = guessInfo.IsEnterCost
        _PokerGuessing:SetProperty("_TipsCount", guessInfo.TipsCount)
        _PokerGuessing:SetProperty("_TipsProgress", guessInfo.TipsProgress)
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
    
    function XPokerGuessingManager.GetPokerGuessingData()
        return _PokerGuessing
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
    
    function XPokerGuessingManager.UseTipsRequest(cb)
        XNetwork.Call("UseTipsRequest", {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _PokerGuessing:SetProperty("_DescKey", XPokerGuessingConfig.Type2DescKey[res.Result])
            
            if cb then cb() end
        end)
    end
    
    local function RequestUnlockCharacterStory(characterId, cb)
        local config
        for _, cfg in ipairs(XPokerGuessingConfig.PokerStoryConfig:GetConfigs()) do
            if cfg.CharacterId == characterId then
                config = cfg
                break
            end
        end
        if not config then return end
        local itemCount = XDataCenter.ItemManager.GetCount(config.UnlockItemId)
        if itemCount < config.Cost then
            XUiManager.TipText("PokerGuessingUnlockItemDeficiency")
            return
        end
        XNetwork.Call("UnlockCharacterStoryRequest", { CharacterId = characterId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local storyInfo = res.StoryInfo
            _PokerGuessing:SetProperty("_UnLockCharacters", storyInfo.UnlockCharacters)

            if cb then cb() end
        end)
    end
    
    function XPokerGuessingManager.UnlockCharacterStoryRequest(characterId, cb)
        local status = HintTipStatus()
        if status then
            RequestUnlockCharacterStory(characterId, cb)
            return
        end
        local hintInfo = {
            SetHintCb = MarkHintTip,
            Status = status,
        }
        local content = XUiHelper.GetText("PokerGuessingSendContent", XPokerGuessingConfig.GetUnlockCostCount(characterId))
        XUiManager.DialogHintTip(XUiHelper.GetText("PokerGuessingSendTitle"), XUiHelper.ReplaceTextNewLine(content), nil, ClearHintTip, 
                function()
                    RequestUnlockCharacterStory(characterId, cb)
                end,
                hintInfo
        )
        
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
    
    function XPokerGuessingManager.GetActivityStoryId()
        return XPokerGuessingConfig.GetActivityStoryId(_CurrActivityId)
    end
    
    function XPokerGuessingManager.GetMaxProgress()
        return XPokerGuessingConfig.GetMaxProgress(_CurrActivityId)
    end

    function XPokerGuessingManager.GetMaxTipCount()
        return XPokerGuessingConfig.GetMaxTipCount(_CurrActivityId)
    end

    ---------配置相关 end---------


    ---------活动相关 begin-------

    function XPokerGuessingManager.OnOpenMain()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.PokerGuessing) then
            return
        end
        if not XPokerGuessingManager.IsOpen() then
            XUiManager.TipText("FestivalActivityNotInActivityTime")
            return
        end
        if not _PokerGuessing then
            return
        end
        XSaveTool.SaveData(XPokerGuessingManager.GetPlayerPrefsKey(), true)
        if _PokerGuessing:IsFirstOpen() then
            CsXUiManager.Instance:SetRevertAndReleaseLock(true)
            XDataCenter.MovieManager.PlayMovie(XDataCenter.PokerGuessingManager.GetActivityStoryId(), function()
                _PokerGuessing:MarkFirstOpen()
                XLuaUiManager.Open("UiFubenPokerGuessing")
                CsXUiManager.Instance:SetRevertAndReleaseLock(false)
            end
            )
        else
            XLuaUiManager.Open("UiFubenPokerGuessing")
        end
    end

    function XPokerGuessingManager.OnActivityEnd()
        XLuaUiManager.RunMain()
        XUiManager.TipText("CommonActivityEnd")
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
    
    function XPokerGuessingManager.GetCookiesKey(key)
        return string.format("XPokerGuessingManager_GetCookiesKey_%s_%s_%s", XPlayer.Id, _CurrActivityId, key)
    end

    function XPokerGuessingManager.CheckBannerRedPoint()
        local task = XPokerGuessingManager.CheckTaskRedPoint()
        local story = XPokerGuessingManager.CheckStoryRedPoint()
        if task or story then
            return true
        end
        return false
    end
    
    function XPokerGuessingManager.CheckTaskRedPoint()
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
    
    function XPokerGuessingManager.CheckStoryRedPoint()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.PokerGuessing) then
            return false
        end
        if not XPokerGuessingManager.IsOpen() then
            return false
        end
        local count = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.PokerGuessingItemId)
        local freshKey = XPokerGuessingManager.GetCookiesKey(XTime.GetSeverNextRefreshTime())
        --今日已检测
        if XSaveTool.GetData(freshKey) then
            return false
        end
        local key = XPokerGuessingManager.GetCookiesKey(_UnLockStoryKey .. count)
        if XSaveTool.GetData(key) then
            return false
        end
        local unlockList = _PokerGuessing and _PokerGuessing:GetProperty("_UnLockCharacters") or {}
        local unlockDict = {}
        for _, characterId in ipairs(unlockList) do
            unlockDict[characterId] = true
        end
        local configs = XPokerGuessingConfig.PokerStoryConfig:GetConfigs()
        for _, cfg in ipairs(configs) do
            if not unlockDict[cfg.CharacterId] and count >= cfg.Cost then
                return true
            end
        end
        return false
    end
    
    function XPokerGuessingManager.MarkUnlockStory()
        local state = XPokerGuessingManager.CheckStoryRedPoint()
        if not state then
            return
        end
        local count = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.PokerGuessingItemId)
        local key = XPokerGuessingManager.GetCookiesKey(_UnLockStoryKey .. count)
        XSaveTool.SaveData(key, true)
    end
    
    function XPokerGuessingManager.MarkUnlockItemChange()
        local state = XPokerGuessingManager.CheckStoryRedPoint()
        if not state then
            return
        end
        local freshKey = XPokerGuessingManager.GetCookiesKey(XTime.GetSeverNextRefreshTime())
        XSaveTool.SaveData(freshKey, true)
    end
    ---------活动相关 end --------

    ---------推送相关 begin --------

    function XPokerGuessingManager.NotifyPokerGuessingData(data)
        if not data then return end
        if data.ActivityId ~= 0 then
            _CurrActivityId = data.ActivityId
            _PokerGuessing = _PokerGuessing or XPokerGuessing.New(_CurrActivityId)
            local storyInfo = data.StoryInfo
            _PokerGuessing:SetProperty("_UnLockCharacters", storyInfo.UnlockCharacters)
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

