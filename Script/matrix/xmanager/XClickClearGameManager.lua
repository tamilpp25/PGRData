local XClickClearGameRewardData = require("XEntity/XClickClearGame/XClickClearGameRewardData")

XClickClearGameManagerCreator = function()
    local tableInsert = table.insert

    local XClickClearGameManager = {}

    XClickClearGameManager.GeneralPanelStates = {
        Default = 1,
        Clearance = 2,
        Failure = 3,
    }
    
    XClickClearGameManager.GameState = {
        Default = 1, -- 默认
        InitComplete = 2, -- 初始化完成
        Playing = 3, -- 游戏中
        Pause = 4, -- 暂停
        Account = 5 -- 结算
    }

    XClickClearGameManager.GameDifficultys = {
        Simple = 1,
        Complex = 2,
        Difficult = 3,
        Hell = 4,
    }

    local GameInfo = {
        CurGameState = XClickClearGameManager.GameState.Default, -- 游戏当前状态
        HeadNormalType = 0,               -- 普通头像类型
        HeadNormalTargetCount = 0,        -- 普通头像目标数量
        HeadNormalCurCount = 0,           -- 普通头像当前找到数量
        HeadNormalDesc = "",              -- 普通头像条件文字
        HeadSpecialType = 0,              -- 特殊头像类型
        HeadSpecialTargetCount = 0,       -- 特殊头像目标数量
        HeadSpecialCurCount = 0,          -- 特殊头像当前找到数量
        HeadSpecialDesc = "",             -- 特殊头像条件文字
        LimitTime = 0,                    -- 本关时间限制
        RemainTime = 0,                   -- 游戏剩余时间
        WrongCostTime = 0,                -- 点错扣除的时间
        HeadInfoPageList = {},            -- 头像页信息列表
        HeadInfoPageCount = 0,            -- 头像页页数
        CurrentHeadPageIndex = 0,         -- 当前头像页序号
        CurrentHeadRealPageIndex = 1,     -- 当前头像页真实列表序号(数组下标)
        UseTime = 0,                      -- 结算用时
        IsNewRecord = false               -- 是否是新记录
    }

    local PassTimeRecords = {} -- 保存的通关时间记录
    local ActivityData = {}
    local ActivityId = 0
    local StartTime = 0
    local TakedRewardIds = {}
    local RewardDataList = {} -- 奖励数据列表
    local IsTakeDifficultyBtnRedPointTable = {} -- 难度按钮红点是否被点击表

    local CurrentGameDifficulty = XClickClearGameManager.GameDifficultys.Simple -- 当前难度

    local CLICKCLEARGAME_PROTO = {
        ClickClearGameStageRecordRequest = "ClickClearGameStageRecordRequest",
        ClickClearGameStageGetRewardRequest = "ClickClearGameStageGetRewardRequest",
    }

    function XClickClearGameManager.Init()
        XClickClearGameManager.InitRewardDataList()
    end

    function XClickClearGameManager.HandlerClickClearData(data)
        local ActivityDatas = data.Activities
        ActivityData = ActivityDatas[1]
        if not ActivityData then
            return
        end
        
        ActivityId = ActivityData.Id
        StartTime = ActivityData.StartTime
        PassTimeRecords = ActivityData.BestRecords
        TakedRewardIds = ActivityData.RewardIds
        for _,v in pairs(RewardDataList) do
            local gameStageId = v:GetGameStageId()
            if TakedRewardIds[gameStageId] then
                v:SetIsTaked(true)
            else
                v:SetIsTaked(false)
            end

            if PassTimeRecords[gameStageId] and PassTimeRecords[gameStageId] > 0 then
                v:SetCanTake(true)
            else
                v:SetCanTake(false)
            end
        end
    end

    function XClickClearGameManager.GetRemainDaysStr()
        local gameTemplates = XClickClearGameConfigs.GetGameTemplates()
        if not gameTemplates or #gameTemplates <= 0 then
            return false
        end

        local gameTemplate = gameTemplates[1]
        local nowTimeStamp = XTime.GetServerNowTimestamp()
        local startTimeStamp = XTime.ParseToTimestamp(gameTemplate.StartTimeStr)
        local endTimeStamp = XTime.ParseToTimestamp(gameTemplate.EndTimeStr)
        if nowTimeStamp < startTimeStamp or nowTimeStamp > endTimeStamp then
            return false
        end

        local differenceTimeStamp = endTimeStamp - nowTimeStamp
        local remainDaysStr = XUiHelper.GetTime(differenceTimeStamp, XUiHelper.TimeFormatType.ACTIVITY)
        return true, remainDaysStr
    end

    function XClickClearGameManager.CheckTabBtnByIndex(index)
        local gameStageTemplate = XClickClearGameConfigs.GetGameStageTemplateById(index)
        if not gameStageTemplate.UnlockCondition or gameStageTemplate.UnlockCondition == 0 then
            return true
        end

        return XConditionManager.CheckCondition(gameStageTemplate.UnlockCondition)
    end

    function XClickClearGameManager.CheckTabBtnByLastDifficult(index)
        if index == 1 then
            return true
        end

        local lastIndex = index - 1
        if PassTimeRecords[lastIndex] and PassTimeRecords[lastIndex] > 0 then
            return true
        end

        return false
    end

    function XClickClearGameManager.GetCondetionDeseByIndex(index)
        local gameStageTemplate = XClickClearGameConfigs.GetGameStageTemplateById(index)
        if not gameStageTemplate.UnlockCondition or gameStageTemplate.UnlockCondition == 0 then
            return ""
        end

        return XConditionManager.GetConditionDescById(gameStageTemplate.UnlockCondition)
    end

    function XClickClearGameManager.CheckPass(difficulty)
        if PassTimeRecords[difficulty] and PassTimeRecords[difficulty] ~= 0 then
            return true, PassTimeRecords[difficulty]/1000
        end

        return false
    end

    function XClickClearGameManager.GetStageTagNameAndNameEnById(id)
        local gameStageTemplate = XClickClearGameConfigs.GetGameStageTemplateById(id)
        if not gameStageTemplate then
            return nil
        end

        return gameStageTemplate.Name, gameStageTemplate.NameEn
    end

    function XClickClearGameManager.GetGameInfo() -- 获取游戏信息
        return GameInfo
    end

    function XClickClearGameManager.GetHelpId()
        local gameTemplates = XClickClearGameConfigs.GetGameTemplates()
        if not gameTemplates or #gameTemplates <= 0 then
            return 0
        end

        local gameTemplate = gameTemplates[1]
        return gameTemplate.HelpId
    end

    function XClickClearGameManager.GetCurGameDifficulty()
        return CurrentGameDifficulty
    end

    function XClickClearGameManager.SetCurGameDifficulty(difficulty)
        CurrentGameDifficulty = difficulty
    end

    function XClickClearGameManager.ResetGame()
        XClickClearGameManager.ResetData()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CLICKCLEARGAME_GAME_RESET)
    end

    function XClickClearGameManager.ResetData()
        GameInfo = {
            CurGameState = XClickClearGameManager.GameState.Default,
            HeadNormalType = 0,
            HeadNormalTargetCount = 0,
            HeadNormalCurCount = 0,
            HeadNormalDesc = "",
            HeadSpecialType = 0,
            HeadSpecialTargetCount = 0,
            HeadSpecialCurCount = 0,
            HeadSpecialDesc = "",
            LimitTime = 0,
            RemainTime = 0,
            WrongCostTime = 0,
            HeadInfoPageList = {},
            HeadInfoPageCount = 0,
            CurrentHeadPageIndex = 0,
            CurrentHeadRealPageIndex = 1,
            IsNewRecord = false,
        }
    end

    function XClickClearGameManager.StartGame()
        if not XClickClearGameManager.GetRemainDaysStr() then -- 活动结束 不可再开始游戏
            XUiManager.TipError(CS.XTextManager.GetText("ClickClearGameOver"))
            return
        end

        if not XClickClearGameManager.InitGame() then
            return
        end

        GameInfo.CurGameState = XClickClearGameManager.GameState.InitComplete
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CLICKCLEARGAME_INIT_COMPLETE)
    end

    function XClickClearGameManager.InitGame()
        if not CurrentGameDifficulty then
            return false
        end

        local gameStage = XClickClearGameConfigs.GetGameStageTemplateById(CurrentGameDifficulty)
        GameInfo.IsNewRecord = false
        GameInfo.HeadNormalType = gameStage.HeadNormalType
        GameInfo.HeadNormalTargetCount = gameStage.HeadNormalCount
        GameInfo.HeadNormalDesc = gameStage.NormalTypeDesc
        GameInfo.HeadNormalCurCount = 0
        GameInfo.HeadSpecialType = gameStage.HeadSpecialType
        GameInfo.HeadSpecialTargetCount = gameStage.HeadSpecialCount
        GameInfo.HeadSpecialDesc = gameStage.SpecialTypeDesc
        GameInfo.HeadSpecialCurCount = 0
        GameInfo.LimitTime = gameStage.TimeLimit
        GameInfo.RemainTime = gameStage.TimeLimit
        GameInfo.WrongCostTime = gameStage.WrongCostTime
        GameInfo.HeadInfoPageList = {}

        local pageListIdStr = gameStage.PageList
        for _,v in pairs(pageListIdStr) do
            local pageIdList = string.ToIntArray(v)
            local randomPageIndex = math.random(1, #pageIdList)
            local pageId = pageIdList[randomPageIndex]
            local headInfoList = {}

            local pageTemplate = XClickClearGameConfigs.GetPageTemplateById(pageId)
            local rowNumberList = pageTemplate.RowNumber
            for _,v in pairs(rowNumberList) do
                local rowNumberIdList = string.ToIntArray(v)
                local randomRowIndex = math.random(1, #rowNumberIdList)
                local rowId = rowNumberIdList[randomRowIndex]

                local rowTemplate = XClickClearGameConfigs.GetRowTemplateById(rowId)
                local headIdList = rowTemplate.HeadId
                for _,v in pairs(headIdList) do
                    local headTypeList = XClickClearGameConfigs.GetHeadTypeListByType(v)
                    local headIndex = math.random(1, #headTypeList)
                    local headTemplate = XClickClearGameConfigs.GetHeadTemplateById(headTypeList[headIndex])
                    local headInfo = {}
                    headInfo.Type = headTemplate.Type
                    headInfo.Url = headTemplate.Url
                    headInfo.IsBeCatched = false

                    tableInsert(headInfoList, headInfo)
                end
            end

            tableInsert(GameInfo.HeadInfoPageList, headInfoList)
        end
        
        GameInfo.HeadInfoPageCount = #GameInfo.HeadInfoPageList

        return true
    end

    function XClickClearGameManager.CalcRealIndex(index)
        if index > 0 then
            return math.fmod(index, GameInfo.HeadInfoPageCount) + 1
        elseif index == 0 then
            return 1
        elseif index < 0 then
            local abs = math.abs(index)
            local fmodVal = math.fmod(abs, GameInfo.HeadInfoPageCount)
            if fmodVal == 0 then
                return 1
            else
                return GameInfo.HeadInfoPageCount - fmodVal + 1
            end
        end
    end

    function XClickClearGameManager.GetNextPageIndex()
        GameInfo.CurrentHeadPageIndex = GameInfo.CurrentHeadPageIndex + 1
        GameInfo.CurrentHeadRealPageIndex = XClickClearGameManager.CalcRealIndex(GameInfo.CurrentHeadPageIndex)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CLICKCLEARGAME_GAME_PAGE_CHANGED)
        return GameInfo.CurrentHeadPageIndex
    end

    function XClickClearGameManager.GetLastPageIndex()
        GameInfo.CurrentHeadPageIndex = GameInfo.CurrentHeadPageIndex - 1
        GameInfo.CurrentHeadRealPageIndex = XClickClearGameManager.CalcRealIndex(GameInfo.CurrentHeadPageIndex)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CLICKCLEARGAME_GAME_PAGE_CHANGED)
        return GameInfo.CurrentHeadPageIndex
    end

    function XClickClearGameManager.OnTouchedHead(index, grid)
        if GameInfo.CurGameState ~= XClickClearGameManager.GameState.Playing then
            return
        end

        local headInfo = GameInfo.HeadInfoPageList[GameInfo.CurrentHeadRealPageIndex][index]
        if headInfo.IsBeCatched then
            return
        end

        if headInfo.Type ~= GameInfo.HeadNormalType and headInfo.Type ~= GameInfo.HeadSpecialType then
            GameInfo.RemainTime = GameInfo.RemainTime - GameInfo.WrongCostTime
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CLICKCLEARGAME_GAME_PAUSE, true)
            return
        end

        if headInfo.Type == GameInfo.HeadNormalType then
            GameInfo.HeadNormalCurCount = GameInfo.HeadNormalCurCount + 1
        elseif headInfo.Type == GameInfo.HeadSpecialType then
            GameInfo.HeadSpecialCurCount = GameInfo.HeadSpecialCurCount + 1
        end

        headInfo.IsBeCatched = true
        grid.DisableAnimation.gameObject:PlayTimelineAnimation(function(state)
            grid.HeadIcon.gameObject:SetActiveEx(false)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CLICKCLEARGAME_HEAD_COUNT_CHANGED)
            XClickClearGameManager.CheckWin()
        end, nil)
        
    end

    function XClickClearGameManager.SetGameStatePlaying()
        GameInfo.CurGameState = XClickClearGameManager.GameState.Playing
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CLICKCLEARGAME_GAME_PLAYING)
    end

    function XClickClearGameManager.SetGameStatePause()
        GameInfo.CurGameState = XClickClearGameManager.GameState.Pause
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CLICKCLEARGAME_GAME_PAUSE)
    end

    function XClickClearGameManager.SetGameStateAccount(isWin)
        GameInfo.CurGameState = XClickClearGameManager.GameState.Account
        if isWin then
            GameInfo.UseTime = GameInfo.LimitTime - GameInfo.RemainTime
            if not PassTimeRecords[CurrentGameDifficulty] or GameInfo.UseTime < PassTimeRecords[CurrentGameDifficulty]/1000 then
                PassTimeRecords[CurrentGameDifficulty] = GameInfo.UseTime * 1000
                local gameStageId = CurrentGameDifficulty
                local bestRecord = math.ceil(PassTimeRecords[CurrentGameDifficulty])
                XNetwork.Call( CLICKCLEARGAME_PROTO.ClickClearGameStageRecordRequest, { GameStageId = gameStageId, BestRecord = bestRecord }, function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        return
                    end
                end)
                GameInfo.IsNewRecord = true
            end
            RewardDataList[CurrentGameDifficulty]:SetCanTake(true)
            XEventManager.DispatchEvent(XEventId.EVENT_CLICKCLEARGAME_FINISHED_GAME)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CLICKCLEARGAME_GAME_PAUSE)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_CLICKCLEARGAME_GAME_ACCOUNT, isWin)
    end

    function XClickClearGameManager.SetRemainTime(remainTime)
        if remainTime < 0 then
            remainTime = 0
        end
        
        GameInfo.RemainTime = remainTime
    end
    
    function XClickClearGameManager.CheckHeadIsCatch(pageIndex, headIndex)
        return GameInfo.HeadInfoPageList[pageIndex][headIndex].IsBeCatched
    end

    function XClickClearGameManager.CheckWin()
        if GameInfo.HeadNormalCurCount >= GameInfo.HeadNormalTargetCount and GameInfo.HeadSpecialCurCount >= GameInfo.HeadSpecialTargetCount then
            XClickClearGameManager.SetGameStateAccount(true)
        end
    end

    function XClickClearGameManager.GetRewardList()
        return RewardDataList
    end

    function XClickClearGameManager.GetSortRewardList()
        local isTakedRewardList = {}
        local notTakedRewardList = {}
        for _,v in pairs(RewardDataList) do
            if v:CheckIsTaked() then
                tableInsert(isTakedRewardList, v)
            else
                tableInsert(notTakedRewardList, v)
            end
        end

        for _,v in pairs(isTakedRewardList) do
            tableInsert(notTakedRewardList, v)
        end

        return notTakedRewardList
    end

    function XClickClearGameManager.GetRewardData(gameStageId)
        return RewardDataList[gameStageId]
    end

    function XClickClearGameManager.InitRewardDataList()
        RewardDataList = {}
        local gameStageTemplates = XClickClearGameConfigs.GetGameStageTemplates()
        for gameStageId,template in pairs(gameStageTemplates) do
            local rewardId = template.RewardId
            local rewardConditionDesc = template.RewardConditionDesc
            local rewardData = XClickClearGameRewardData.New(gameStageId, rewardId, rewardConditionDesc)
            if rewardData then
                tableInsert(RewardDataList, rewardData)
            end
        end
    end

    function XClickClearGameManager.GetRewardRequest(gameStageId, cb)
        XNetwork.Call(CLICKCLEARGAME_PROTO.ClickClearGameStageGetRewardRequest, { GameStageId = gameStageId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            RewardDataList[gameStageId]:SetIsTaked(true)
            XEventManager.DispatchEvent(XEventId.EVENT_CLICKCLEARGAME_TAKED_REWARD)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_CLICKCLEARGAME_TAKED_REWARD)
            if cb then
                cb(res.RewardGoodsList)
            end
        end)
    end

    function XClickClearGameManager.GetRewardCount()
        return #RewardDataList
    end

    function XClickClearGameManager.GetRewardTakedCount()
        local count = 0
        for _,v in pairs(RewardDataList) do
            if v:CheckIsTaked() then
                count = count + 1
            end
        end
        return count
    end

    function XClickClearGameManager.GetRewardCanTakeCount()
        local count = 0
        for _,v in pairs(RewardDataList) do
            if v:CheckCanTake() then
                count = count + 1
            end
        end
        return count
    end

    function XClickClearGameManager.CheckDifficultyRedPoint(difficulty)
        local isUnLock = XClickClearGameManager.CheckTabBtnByLastDifficult(difficulty)
        local passTime = PassTimeRecords[difficulty]
        if isUnLock and not IsTakeDifficultyBtnRedPointTable[difficulty] then
            if not passTime or passTime == 0 then
                return true
            end
        end
        return false
    end

    function XClickClearGameManager.CheckRewardRedPoint()
        for _,v in pairs(RewardDataList) do
            if v:CheckCanTake() and not v:CheckIsTaked() then
                return  true
            end
        end
        
        return false
    end

    function XClickClearGameManager.SetTakeDifficultyBtnRedPoint(index, bool)
        IsTakeDifficultyBtnRedPointTable[index] = bool
    end

    function XClickClearGameManager.GetTakeDifficultyBtnRedPoint(index)
        return IsTakeDifficultyBtnRedPointTable[index]
    end

    XClickClearGameManager:Init()
    
    return XClickClearGameManager
end

XRpc.NotifyClickClearData = function (data)
    XDataCenter.XClickClearGameManager.HandlerClickClearData(data)
end