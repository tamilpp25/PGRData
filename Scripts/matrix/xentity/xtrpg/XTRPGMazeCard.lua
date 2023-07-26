local type = type
local tonumber = tonumber
local CardType = XTRPGConfigs.CardType

local XTRPGMazeCard = XClass(nil, "XTRPGMazeCard")

local Default = {
    __Id = 0,
    __ReplaceId = 0,
    __Type = CardType.Default,
    __IsDisposeableSingle = false, --是否一次性使用
    __IsDisposeable = false, --是否一次性使用(服务端记录，永久一次性触发)
    __IsFinished = false, --是否触发过
}

function XTRPGMazeCard:Ctor(cardId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.__Id = cardId
    self.__Type = XTRPGConfigs.GetMazeCardType(cardId)
    self.__IsDisposeableSingle = XTRPGConfigs.IsMazeCardSingleDisposeable(cardId)
    self.__IsDisposeable = XTRPGConfigs.IsMazeCardDisposeable(cardId)
end

function XTRPGMazeCard:Reset()
    if self:IsDisposeableForever() then
        return
    end

    self.__ReplaceId = 0
    self.__IsFinished = false
end

function XTRPGMazeCard:GetId()
    return self.__Id
end

function XTRPGMazeCard:GetEffectId()
    if self.__ReplaceId ~= 0 then
        return self.__ReplaceId
    end

    return self.__Id
end

function XTRPGMazeCard:CheckType(cardType)
    if self.__ReplaceId ~= 0 then
        local replaceCardType = XTRPGConfigs.GetMazeCardType(self.__ReplaceId)
        return replaceCardType == cardType
    end

    return self.__Type == cardType
end

function XTRPGMazeCard:OnSelect(cardIndex, doNotSyn)

    if self:CheckType(CardType.Block) then
        return
    end

    if not doNotSyn then
        self:ReplaceCard(nil)--手动点击选择要用卡牌原始类型处理
        XDataCenter.TRPGManager.TRPGMazeSelectCardRequest(cardIndex)
    end

    --已完成过的卡牌直接通行 
    if self:IsFinished() then
        return
    end

    if self:CheckType(CardType.Fight) then

        local cardId = self:GetEffectId()
        local params = XTRPGConfigs.GetMazeCardParam(cardId)
        local challengeLevel = tonumber(params[1])
        local stageId = tonumber(params[2])
        local qucikRewardId = tonumber(params[3])
        XLuaUiManager.Open("UiTRPGFightTips", cardId, cardIndex, stageId, challengeLevel, qucikRewardId)

    elseif self:CheckType(CardType.FightWin) then

        local cardId = self:GetEffectId()
        local params = XTRPGConfigs.GetMazeCardParam(cardId)
        local stageId = tonumber(params[1])
        XLuaUiManager.Open("UiTRPGFightTips", cardId, cardIndex, stageId)

    elseif self:CheckType(CardType.Examine) then

        local cardId = self:GetEffectId()
        local params = XTRPGConfigs.GetMazeCardParam(cardId)
        local examineId = tonumber(params[1])
        XDataCenter.TRPGManager.EnterExamine(examineId)

    end
end

function XTRPGMazeCard:OnResult(cardIndex, resultData)
    if not resultData then return end

    if not resultData.Success then

        if self:CheckType(CardType.Random) then--随机牌需要转换为真实类型后尝试进行新一轮操作

            --优先处理随机牌类型替换逻辑
            local replaceCardId = resultData.ReplaceId
            self:ReplaceCard(replaceCardId)

            local doNotSyn = true
            self:OnSelect(cardIndex, doNotSyn)

        end

        return

    end

    coroutine.wrap(function()
        local co = coroutine.running()
        local callBack = function() coroutine.resume(co) end

        --奖励相关
        local rewardList = resultData.RewardList
        if not XTool.IsTableEmpty(rewardList) then
            XDataCenter.TRPGManager.OnGetReward(rewardList, callBack)
            coroutine.yield()
        end

        --已完成过的卡牌直接通行 
        if self:IsFinished() then
            XDataCenter.TRPGManager.ReqMazeMoveNext(cardIndex)
            return
        end

        --优先处理随机牌类型替换逻辑
        if self:CheckType(CardType.Random) then
            local replaceCardId = resultData.ReplaceId
            self:ReplaceCard(replaceCardId)
        end

        --迷宫位置更新
        if self:CheckType(CardType.Block)
        or self:CheckType(CardType.Random) then --随机牌替换为其他类型处理
            return
        elseif self:CheckType(CardType.Pass)
        or self:CheckType(CardType.Fight)
        or self:CheckType(CardType.Examine)
        or self:CheckType(CardType.Reward)
        then

            XDataCenter.TRPGManager.ReqMazeMoveNext(cardIndex)

        elseif self:CheckType(CardType.FightWin) then

            local movieId = XTRPGConfigs.GetMazeCardMovieId(self.__Id)
            XDataCenter.TRPGManager.ReqMazeMoveNext(cardIndex, movieId)

        elseif self:CheckType(CardType.Story) then

            local params = XTRPGConfigs.GetMazeCardParam(self.__Id)
            local movieId = params[1]
            local cb = function()
                XDataCenter.TRPGManager.ReqMazeMoveNext(cardIndex)
                XDataCenter.TRPGManager.CheckOpenNewMazeTips()
            end
            XDataCenter.MovieManager.PlayMovie(movieId, cb)

        elseif self:CheckType(CardType.Skip) then

            local params = XTRPGConfigs.GetMazeCardParam(self.__Id)
            local skipLayerId = tonumber(params[1])
            local skipNodeId = tonumber(params[2])
            local skipCardIndex = tonumber(params[3])
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_TRPG_MAZE_MOVE_TO, skipLayerId, skipNodeId, skipCardIndex)

        elseif self:CheckType(CardType.Over) then

            XDataCenter.TRPGManager.QuitMaze()

        end

        --还原随机牌类型
        self:RevertCard()

        --标记已完成
        self:SetFinished()
    end)()

end

function XTRPGMazeCard:IsDisposeable()
    return self.__IsDisposeableSingle or self.__IsDisposeable
end

function XTRPGMazeCard:IsDisposeableForever()
    return self.__IsDisposeable
end

function XTRPGMazeCard:IsFinished()
    return self.__IsFinished
end

function XTRPGMazeCard:GetFinishedId()
    if not self:IsFinished() then
        return
    end
    return XTRPGConfigs.GetMazeCardConvertCardId(self.__Id)
end

function XTRPGMazeCard:SetFinished()
    if not self:IsDisposeable() then
        return
    end
    self.__IsFinished = true
end

function XTRPGMazeCard:ReplaceCard(replaceCardId)
    self.__ReplaceId = replaceCardId or 0
end

function XTRPGMazeCard:RevertCard()
    --一次性卡牌触发完随机之后不再复原
    if self:IsDisposeable() then
        return
    end
    self.__ReplaceId = 0
end

return XTRPGMazeCard