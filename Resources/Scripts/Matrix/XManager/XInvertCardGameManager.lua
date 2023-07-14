local tableInsert = table.insert
local tableSort = table.sort
local XInvertCardStageEntity = require("XEntity/XInvertCardGame/XInvertCardStage")
XInvertCardGameManagerCreator = function()
    local XInvertCardGameManager = {}
    local ActId = 0
    local CurStageId = 0
    local StageEntityList = {}

    local INVERT_CARD_PROTO = {
        InvertCardRequest = "InvertCardRequest", -- 翻牌请求
        InvertCardsRewardRequest = "InvertCardsRewardRequest", -- 领取关卡奖励请求
    }

    function XInvertCardGameManager.HandleInvertGameData(data)
        ActId = data.ActivityId
        CurStageId = data.CurActivityStageId
        local stageInfoList = data.ActivityStageInfoList
        -- 遍历数据
        if stageInfoList and next(stageInfoList) then
            for _, stageData in ipairs(stageInfoList) do
                if stageData.ActivityStageId then
                    local tmp = XInvertCardGameConfig.GetInvertCardStageTemplateById(stageData.ActivityStageId)
                    local stageEntity = XInvertCardStageEntity.New(tmp, stageData)
                    tableInsert(StageEntityList, stageEntity)
                end
            end
        end
    end

    function XInvertCardGameManager.Init()
        
    end

    function XInvertCardGameManager.GetStageEntityById(stageId)
        for _, stageData in ipairs(StageEntityList) do
            local id = stageData:GetId()
            if id == stageId then
                return stageData
            end
        end

        return nil
    end

    function XInvertCardGameManager.InvertCardRequest(stageId, cardIdx)
        if not ActId or ActId == 0 then
            XLog.Error("Invert Card Game ActivityId Can't Be nil or 0")
            return
        end
        
        local cardState = XInvertCardGameManager.CheckCardState(stageId, cardIdx)
        if cardState == XInvertCardGameConfig.InvertCardGameCardState.Back then
            local stageData = XInvertCardGameManager.GetStageEntityById(stageId)
            if not XInvertCardGameManager.CheckHasEnoughItem(stageData) then
                XUiManager.TipText("InvertCardGameHaveNotEnoughItem")
                return
            end
            XNetwork.Call(INVERT_CARD_PROTO.InvertCardRequest, {ActivityId = ActId, ActivityStageId = stageId, CardIdx = cardIdx}, function (res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if stageData then
                    XInvertCardGameManager.InvertCard(stageData, stageId, cardIdx)
                    XInvertCardGameManager.ClearCardData(stageData, stageId, res.FinCardsIdxList)
                    XInvertCardGameManager.PunishCard(stageData, stageId, res.PunishCardsIdxList)
                    stageData:SetProgress(res.Progress)
                    stageData:AddTotalCounts()
                    stageData:SetStatus(res.ActivityStageStatus)
                    if res.ActivityStageStatus == XInvertCardGameConfig.InvertCardGameStageStatusType.Finish then
                        XInvertCardGameManager.CheckNextStageOpen()
                    end
                    
                    XEventManager.DispatchEvent(XEventId.EVENT_INVERT_CARD_GAME_CARD_CHANGED)
                    CsXGameEventManager.Instance:Notify(XEventId.EVENT_INVERT_CARD_GAME_CARD_CHANGED, stageData, cardIdx, res.PunishCardsIdxList, res.FinCardsIdxList)
                end
            end)
        end
    end
    
    function XInvertCardGameManager.InvertCard(stageData, stageId, cardIdx)
        if not stageData then
            stageData = XInvertCardGameManager.GetStageEntityById(stageId)
        end
        if stageData then
            stageData:SetCardInvert(cardIdx)
        end
    end

    function XInvertCardGameManager.ClearCardData(stageData, stageId, finishCardIdxs)
        if not stageData then
            stageData = XInvertCardGameManager.GetStageEntityById(stageId)
        end
        if stageData then
            for _, finishIdx in ipairs(finishCardIdxs) do
                stageData:SetCardFinish(finishIdx)
            end
        end
    end

    function XInvertCardGameManager.PunishCard(stageData, stageId, punishCardIdxs)
        if not stageData then
            stageData = XInvertCardGameManager.GetStageEntityById(stageId)
        end
        if stageData then
            for _, punishIdx in ipairs(punishCardIdxs) do
                stageData:SetCardPunish(punishIdx)
            end
        end
    end

    function XInvertCardGameManager.InvertCardsRewardRequest(stageId)
        if not ActId or ActId == 0 then
            XLog.Error("Invert Card Game ActivityId Can't Be nil or 0")
            return
        end

        XNetwork.Call(INVERT_CARD_PROTO.InvertCardsRewardRequest, {ActivityId = ActId, ActivityStageId = stageId}, function (res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local stageData = XInvertCardGameManager.GetStageEntityById(stageId)
            if stageData then
                stageData:SetRewardListIdx(res.RewardListIdx)
                if res.RewardGoodsList and next(res.RewardGoodsList) then
                    XUiManager.OpenUiObtain(res.RewardGoodsList, CS.XTextManager.GetText("Award"))
                end
            end

            XEventManager.DispatchEvent(XEventId.EVENT_INVERT_CARD_GAME_GET_REWARD)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_INVERT_CARD_GAME_GET_REWARD, stageData)
        end)
    end

    function XInvertCardGameManager.CheckNextStageOpen()
        local curOpenStageId = 0
        for index, stageData in ipairs(StageEntityList) do
            if stageData:GetStatus() == XInvertCardGameConfig.InvertCardGameStageStatusType.Lock then
                if StageEntityList[index-1] and StageEntityList[index-1]:GetStatus() == XInvertCardGameConfig.InvertCardGameStageStatusType.Finish then
                    stageData:SetStatus(XInvertCardGameConfig.InvertCardGameStageStatusType.Process)
                    CurStageId = stageData:GetId()
                end
            end
        end
    end

    function XInvertCardGameManager.GetHelpId()
        if ActId and ActId ~= 0 then
            return XInvertCardGameConfig.GetHelpId(ActId)
        end
    end

    function XInvertCardGameManager.GetConsumeItemId()
        if ActId and ActId ~= 0 then
            return XInvertCardGameConfig.GetConsumeItemId(ActId)
        end
    end

    function XInvertCardGameManager.CheckHasServerData()
        if StageEntityList and next(StageEntityList) then
            return true
        end

        return false
    end

    function XInvertCardGameManager.GetStorySkipId()
        if ActId and ActId ~= 0 then
            return XInvertCardGameConfig.GetStorySkipId(ActId)
        end
    end

    function XInvertCardGameManager.GetActivityTimeId()
        if ActId and ActId ~= 0 then
            return XInvertCardGameConfig.GetActivityTimeId(ActId)
        end
    end

    function XInvertCardGameManager.GetStageEntityList()
        return StageEntityList
    end

    function XInvertCardGameManager.CheckStageIsOpen(index)
        if StageEntityList and StageEntityList[index] then
            return StageEntityList[index]:GetStatus() ~= XInvertCardGameConfig.InvertCardGameStageStatusType.Lock
        end
    end

    function XInvertCardGameManager.FindDefaultSelectTabIndex()
        if CurStageId then
            for index, stageEntity in ipairs(StageEntityList) do
                if stageEntity:GetId() == CurStageId then
                    return index
                end
            end
        end

        return 1
    end

    function XInvertCardGameManager.GetCurStageEntity()
        if CurStageId then
            for index, stageEntity in ipairs(StageEntityList) do
                if stageEntity:GetId() == CurStageId then
                    return stageEntity
                end
            end
        end
    end

    -- 根据关卡Id，奖励Id检查奖励状态
    function XInvertCardGameManager.CheckRewardState(stageId, rewardIdx)
        if not stageId or not rewardIdx or stageId == 0 or rewardIdx == 0 then
            return XInvertCardGameConfig.InvertCardGameRewardTookState.NotFinish
        end
        local stageEntity = XInvertCardGameManager.GetStageEntityById(stageId)
        if stageEntity:GetRewardListIdx()[rewardIdx] == true then
            return XInvertCardGameConfig.InvertCardGameRewardTookState.Took
        else
            local finishProgress = stageEntity:GetProgress()
            local targetProgress = stageEntity:GetFinishProgress()[rewardIdx]
            if finishProgress and targetProgress then
                if finishProgress < targetProgress then
                    return XInvertCardGameConfig.InvertCardGameRewardTookState.NotFinish
                else
                    return XInvertCardGameConfig.InvertCardGameRewardTookState.NotTook
                end
            else
                return XInvertCardGameConfig.InvertCardGameRewardTookState.NotFinish
            end
        end
    end
    
    -- 根据关卡Id，卡牌Id检查卡牌状态
    function XInvertCardGameManager.CheckCardState(stageId, cardIdx)
        if not stageId or not cardIdx or stageId == 0 or cardIdx == 0 then
            return XInvertCardGameConfig.InvertCardGameCardState.Finish
        end
        local stageEntity = XInvertCardGameManager.GetStageEntityById(stageId)
        if stageEntity:GetStatus() == XInvertCardGameConfig.InvertCardGameStageStatusType.Finish then
            return XInvertCardGameConfig.InvertCardGameCardState.Front
        end
        local cardList = stageEntity:GetRandomCardList()
        if cardList[cardIdx] then
            if cardList[cardIdx].IsFinish then
                return XInvertCardGameConfig.InvertCardGameCardState.Finish
            else
                local invertList = stageEntity:GetInvertList()
                for _, invertCardIdx in ipairs(invertList) do
                    if cardIdx == invertCardIdx then
                        return XInvertCardGameConfig.InvertCardGameCardState.Front
                    end
                end

                return XInvertCardGameConfig.InvertCardGameCardState.Back
            end
        else
            return XInvertCardGameConfig.InvertCardGameCardState.Finish
        end
    end

    function XInvertCardGameManager.GetStartStage(stageEntity)
        if not stageEntity then
            return XInvertCardGameConfig.InvertCardGameStartStage.Started
        end
        local stageId = stageEntity:GetId()
        local startStateData = XSaveTool.GetData(string.format( "%s%s%s%s", XInvertCardGameConfig.INVERT_CARD_GAME_START_STATE_KEY, XPlayer.Id, XDataCenter.InvertCardGameManager.ActId, stageId))
        if not startStateData or startStateData == XInvertCardGameConfig.InvertCardGameStartStage.NotStart then
            return XInvertCardGameConfig.InvertCardGameStartStage.NotStart
        else
            return XInvertCardGameConfig.InvertCardGameStartStage.Started
        end
    end

    function XInvertCardGameManager.SetStartStage(stageEntity)
        if not stageEntity then
            return
        end
        local stageId = stageEntity:GetId()
        XSaveTool.SaveData(string.format( "%s%s%s%s", XInvertCardGameConfig.INVERT_CARD_GAME_START_STATE_KEY, XPlayer.Id, XDataCenter.InvertCardGameManager.ActId, stageId), XInvertCardGameConfig.InvertCardGameStartStage.Started)
    end

    function XInvertCardGameManager.CheckTogRedPoint(index)
        if StageEntityList[index] then
            if StageEntityList[index]:GetStatus() == XInvertCardGameConfig.InvertCardGameStageStatusType.Process then
                if StageEntityList[index]:GetTotalCounts() >= StageEntityList[index]:GetMaxCostNum() then -- 超过最大翻牌次数不消耗代币
                    return true
                end
                if XInvertCardGameManager.CheckHasEnoughItem(StageEntityList[index]) then
                    return true
                end
            end

            local rewardList = StageEntityList[index]:GetRewards()
            local stageId = StageEntityList[index]:GetId()
            for index, _ in ipairs(rewardList) do
                if XInvertCardGameManager.CheckRewardState(stageId, index) == XInvertCardGameConfig.InvertCardGameRewardTookState.NotTook then
                    return true
                end
            end
        end

        return false
    end

    function XInvertCardGameManager.CheckHasEnoughItem(stageEntity)
        local consumeItemId = XInvertCardGameManager.GetConsumeItemId()
        if not consumeItemId then
            return false
        end

        local consumeCount = stageEntity:GetCostCoinNum()
        if not consumeCount then
            return false
        end

        if stageEntity:GetTotalCounts() >= stageEntity:GetMaxCostNum() then -- 超过最大翻牌次数不消耗代币
            return true
        end

        return XDataCenter.ItemManager.CheckItemCountById(consumeItemId, consumeCount)
    end

    function XInvertCardGameManager.CheckAllGameRedPoint()
        if StageEntityList and next(StageEntityList) then
            for index, _ in ipairs(StageEntityList) do
                if XInvertCardGameManager.CheckTogRedPoint(index) then
                    return true
                end
            end
        end

        return false
    end

    function XInvertCardGameManager.CheckActivityStageFinished(activityId, stageId)
        if not ActId or ActId == 0 or ActId ~= activityId then
            return false
        end

        local stageEntity = XInvertCardGameManager.GetStageEntityById(stageId)
        if not stageEntity then
            return false
        end

        return stageEntity:GetStatus() == XInvertCardGameConfig.InvertCardGameStageStatusType.Finish
    end

    XInvertCardGameManager.Init()
    return XInvertCardGameManager
end

XRpc.NotifyInvertCardGameData = function (data)
    XDataCenter.InvertCardGameManager.HandleInvertGameData(data)
end