local XSpringFestivalBoxGift = require("XEntity/XSpringFestival/XSpringFestivalBoxGift")
local XSpringFestivalFriendRequestInfo = require("XEntity/XSpringFestival/XSpringFestivalFriendRequestInfo")
XSpringFestivalActivityManagerCreator = function()
    local tableInsert = table.insert
    local tableRemove = table.remove
    local tableSort = table.sort
    local pairs = pairs
    local XSpringFestivalActivityManager = {}

    local _CurrRecvRewardInfo = {}
    local _RecvFinalRewardTimes = 0
    local _CurrActivityId = 0
    local _GiftBoxData = {}
    local _FriendRequestList = {}
    local _RequestWordId = 0
    local _LastRequestTime = 0
    local _LastSendGuildRequestTime = 0
    local _SequenceSuccessCount = 0
    local _EggList = {}
    local _TodayScore = 0
    local _CurrentScore = 0
    local _HighestScore = 0
    local _TodayScoreRewardStatus = 0
    local _LastUseItemData = {
        Buff = 0,
        SafetyProtect = 0,
        Hammer = 1
    }
    local CollectWordsRequestWordCd = CS.XGame.Config:GetInt("CollectWordsRequestWordCd")
    local CollectWordsRequestWordGuildCd = CS.XGame.Config:GetInt("CollectWordsRequestWordGuildCd")
    local CollectWordsGiftBoxMaxCount = CS.XGame.Config:GetInt("CollectWordsGiftBoxMaxCount")
    local CollectWordsRecvRequestMaxCount = CS.XGame.Config:GetInt("CollectWordsRecvRequestMaxCount")
    local CollectWordsRequestWordFriendCd = CS.XGame.Config:GetInt("CollectWordsRequestWordFriendCd")

    -----------------------集字相关 begin----------------------------

    local GetAlreadyRecvTimes = function(type)
        for i = 1, #_CurrRecvRewardInfo do
            if type == _CurrRecvRewardInfo[i].Id then
                return _CurrRecvRewardInfo[i].AlreadyRecvTimes
            end
        end
        return 0
    end

    function XSpringFestivalActivityManager.GetCanGetNumberByType(type)
        local itemList = XSpringFestivalActivityConfigs.GetWordsItemListByType(type)
        local min
        for _, item in pairs(itemList) do
            local count = XDataCenter.ItemManager.GetCount(item.Id)
            if not min or count < min then
                min = count
            end
        end
        return XMath.Clamp(min, 0, XSpringFestivalActivityConfigs.GetCollectWordsRewardMaxCount(type) - GetAlreadyRecvTimes(type))
    end

    function XSpringFestivalActivityManager.CheckRewardIsMaxCount(type)
        for i = 1, #_CurrRecvRewardInfo do
            if type == _CurrRecvRewardInfo[i].Id then
                return _CurrRecvRewardInfo[i].AlreadyRecvTimes >= XSpringFestivalActivityConfigs.GetCollectWordsRewardMaxCount(type)
            end
        end
        return false
    end

    function XSpringFestivalActivityManager.CheckIsInGuildRequestCd()
        local now = XTime.GetServerNowTimestamp()
        local offset = now - _LastSendGuildRequestTime
        return offset < CollectWordsRequestWordGuildCd, CollectWordsRequestWordGuildCd - offset
    end
    
    function XSpringFestivalActivityManager.GetAlreadyRecvTimes(type)
        for _,v in pairs(_CurrRecvRewardInfo) do
            if v.Id == type then
                return v.AlreadyRecvTimes
            end
        end
    end
    
    function XSpringFestivalActivityManager.GetCollectWordDuringDay()
        local startTime = XSpringFestivalActivityManager.GetActivityStartTime()
        local now = XTime.GetServerNowTimestamp()
        local offset = now - startTime
        return math.ceil(offset / (3600 * 24))
    end

    function XSpringFestivalActivityManager.GetGiftBoxDataByIndex(index)
        return _GiftBoxData[index]
    end

    function XSpringFestivalActivityManager.GetGiftCount()
        return #_GiftBoxData
    end

    function XSpringFestivalActivityManager.GetRequestWordId()
        return _RequestWordId
    end

    function XSpringFestivalActivityManager.HasRequestWord()
        return _RequestWordId > 0
    end

    function XSpringFestivalActivityManager.GetNextRequestRefreshTime()
        local nextRecoverTime = XTime.GetSeverNextRefreshTime()
        local now = XTime.GetServerNowTimestamp()
        return nextRecoverTime - now
    end

    function XSpringFestivalActivityManager.GetNextRequestTime()
        local now = XTime.GetServerNowTimestamp()
        local during = now - _LastRequestTime
        local offset = CollectWordsRequestWordCd - during
        if offset < 0 then
            offset = 0
        end
        return offset
    end

    function XSpringFestivalActivityManager.CheckCanGetCollectWordsReward(type)
        if type == XSpringFestivalActivityConfigs.CollectWordsRewardType.Final then
            return XSpringFestivalActivityManager.GetCanRecvFinalRewardTimes() > 0
        end

        if XSpringFestivalActivityManager.CheckRewardIsMaxCount(type) then
            return false
        end

        local costItemList = XSpringFestivalActivityConfigs.GetCollectWordsRewardCostItemList(type)
        local costItemCount = XSpringFestivalActivityConfigs.GetCollectWordsRewardCostCountList(type)
        local need = 0
        for i = 1, #costItemList do
            local itemCount = XDataCenter.ItemManager.GetCount(costItemList[i])
            if itemCount < costItemCount[i] then
                need = need + costItemCount[i] - itemCount
            end
        end

        local universalWordId = XSpringFestivalActivityConfigs.GetWordsItemListByType(XSpringFestivalActivityConfigs.CollectCardType.Universal)
        local universalWordCount = 0
        for i = 1, #universalWordId do
            universalWordCount = universalWordCount + XDataCenter.ItemManager.GetCount(universalWordId[i].Id)
        end
        return need == 0 or universalWordCount >= need, need
    end

    function XSpringFestivalActivityManager.CheckCanGetRewardWithoutUniversal(type)
        local costItemList = XSpringFestivalActivityConfigs.GetCollectWordsRewardCostItemList(type)
        local costItemCount = XSpringFestivalActivityConfigs.GetCollectWordsRewardCostCountList(type)
        local need = 0
        for i = 1, #costItemList do
            local itemCount = XDataCenter.ItemManager.GetCount(costItemList[i])
            if itemCount < costItemCount[i] then
                need = need + costItemCount[i] - itemCount
            end
        end
        return need == 0
    end
    function XSpringFestivalActivityManager.GetCanRecvFinalRewardTimes()
        local min = _CurrRecvRewardInfo[1].AlreadyRecvTimes
        return XMath.Clamp(min - _RecvFinalRewardTimes, 0, min)
    end

    function XSpringFestivalActivityManager.GetRecvFinalRewardTimes()
        return _RecvFinalRewardTimes
    end

    function XSpringFestivalActivityManager.CheckHasUnReceiveGift()
        for _,giftInfo in pairs(_GiftBoxData) do
            if not giftInfo:IsReceive() then
                return true
            end
        end

        return false
    end
    
    
    -----------------------集字相关 end----------------------------
    -----------------------砸蛋相关 begin--------------------------
    local ResetEggList = function()
        for _, v in pairs(_EggList) do
            v.IsBroken = false
        end
    end

    local UpdateEggListByPlace = function(place, isBroken)
        for _, v in pairs(_EggList) do
            if v.Place == place then
                v.IsBroken = isBroken
            end
        end
    end

    local UpdateLastUseItemData = function(data)
        if not data then
            return
        end
        _LastUseItemData.Hammer = data.Hammer == 0 and 1 or data.Hammer
        _LastUseItemData.SafetyProtect = data.SafetyProtect
        _LastUseItemData.Buff = data.Buff
    end

    function XSpringFestivalActivityManager.GetSmashEggsSequenceSuccessCount()
        return _SequenceSuccessCount
    end

    function XSpringFestivalActivityManager.GetSmashEggsEggList()
        return _EggList
    end

    function XSpringFestivalActivityManager.GetSmashEggsTodayScore()
        return _TodayScore
    end

    function XSpringFestivalActivityManager.GetSmashEggsCurrentScore()
        return _CurrentScore
    end

    function XSpringFestivalActivityManager.GetSmashEggsHighestScore()
        return _HighestScore
    end

    function XSpringFestivalActivityManager.CheckRewardIsReceive(index)
        return 1 << index & _TodayScoreRewardStatus > 0
    end

    function XSpringFestivalActivityManager.GetTodayScoreRewardStatus()
        return _TodayScoreRewardStatus
    end

    function XSpringFestivalActivityManager.GetCurrHammer()
        return _LastUseItemData.Hammer
    end

    function XSpringFestivalActivityManager.GetCurrBuffItem()
        return _LastUseItemData.Buff
    end

    function XSpringFestivalActivityManager.GetCurrSafetyProtect()
        return _LastUseItemData.SafetyProtect
    end

    function XSpringFestivalActivityManager.CheckIsNeedTip()
        return _SequenceSuccessCount >= XSpringFestivalActivityConfigs.GetNeedTipCount()
    end

    function XSpringFestivalActivityManager.GetSequenceSuccessCount()
        return _SequenceSuccessCount
    end
    -----------------------砸蛋相关 end----------------------------
    -----------------------活动相关 begin--------------------------

    function XSpringFestivalActivityManager.IsOpen()
        local isOpen = XFunctionManager.CheckInTimeByTimeId(XSpringFestivalActivityConfigs.GetSpringFestivalActivityTimeId())
        if not isOpen then
            XUiManager.TipText("SpringFestivalNotOpen")
        end
        return isOpen
    end

    function XSpringFestivalActivityManager.IsActivityEnd()
        local endTime = XSpringFestivalActivityManager.GetActivityEndTime()
        local now = XTime.GetServerNowTimestamp()
        return now >= endTime
    end

    function XSpringFestivalActivityManager.IsActivityStart()
        local startTime = XSpringFestivalActivityManager.GetActivityStartTime()
        local now = XTime.GetServerNowTimestamp()
        return now >= startTime
    end

    function XSpringFestivalActivityManager.OpenActivityMain()
        if XSpringFestivalActivityManager.IsOpen() then
            XLuaUiManager.Open("UiFubenSpringFestivalChapter")
        else
        end
    end
    
    function XSpringFestivalActivityManager.OpenMainWithClose()
        if XSpringFestivalActivityManager.IsOpen() then
            XLuaUiManager.PopThenOpen("UiFubenSpringFestivalChapter")
        else
        end
    end

    function XSpringFestivalActivityManager.GetSmashEggsActivityDay()
        local smashActivityTimeId = XSpringFestivalActivityConfigs.GetSpringFestivalActivityTimeId()
        local now = XTime.GetServerNowTimestamp()
        local startTime = XFunctionManager.GetStartTimeByTimeId(smashActivityTimeId)
        return math.ceil((now-startTime) / (3600 * 24))
    end

    function XSpringFestivalActivityManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") or XLuaUiManager.IsUiLoad("UiSettleLose") or XLuaUiManager.IsUiLoad("UiSettleWin") then
            return
        end
        XUiManager.TipText("SpringFestivalOver")
        XLuaUiManager.RunMain()
    end

    function XSpringFestivalActivityManager.GetActivityStartTime()
        local timeId = XSpringFestivalActivityConfigs.GetSpringFestivalActivityTimeId()
        return XFunctionManager.GetStartTimeByTimeId(timeId)
    end

    function XSpringFestivalActivityManager.GetActivityEndTime()
        local timeId = XSpringFestivalActivityConfigs.GetSpringFestivalActivityTimeId()
        return XFunctionManager.GetEndTimeByTimeId(timeId)
    end

    function XSpringFestivalActivityManager.GetActivityChapter()
        local chapter = {}
        if XSpringFestivalActivityManager.IsOpen() then
            local tempChapter = {}
            tempChapter.Id = XSpringFestivalActivityConfigs.GetSpringFestivalActivityId()
            tempChapter.Type = XDataCenter.FubenManager.ChapterType.SpringFestivalActivity
            tempChapter.BannerBg = XSpringFestivalActivityConfigs.GetSpringFestivalActivityBg()
            tableInsert(chapter, tempChapter)
        end
        return chapter
    end
    -----------------------活动相关 end----------------------------
    -----------------------数据相关 begin----------------------------
    local function UpdateRequestWordList(requestList)
        _FriendRequestList = {}
        for _, requestInfo in pairs(requestList) do
            local temp = XSpringFestivalFriendRequestInfo.New(requestInfo)
            tableInsert(_FriendRequestList, temp)
        end
    end

    function XSpringFestivalActivityManager.GetFriendRequestList()
        return _FriendRequestList
    end

    function XSpringFestivalActivityManager.GetFriendRequestByType(type)
        local requestList = {}
        for _, info in pairs(_FriendRequestList) do
            if info:GetFromType() == type then
                tableInsert(requestList, info)
            end
        end
        return requestList
    end

    function XSpringFestivalActivityManager.GetFriendRequestInfoByIndex(index)
        return _FriendRequestList[index]
    end

    -----------------------数据相关 end------------------------------
    -----------------------推送相关 begin----------------------------
    local UpdateCurrActivityId = function(Id)
        _CurrActivityId = Id or _CurrActivityId
    end

    local UpdateGetRewardInfo = function(data)
        if not data then
            return
        end
        _CurrRecvRewardInfo = data
        table.sort(_CurrRecvRewardInfo, function(a, b)
                return a.AlreadyRecvTimes < b.AlreadyRecvTimes
        end)
            end

    local UpdateRecvFinalRewardTimes = function(times)
        if not times then
            return
        end
        _RecvFinalRewardTimes = times
    end

    local function UpdateGiftBoxData(data)
        if not data then
            return
        end
        _GiftBoxData = {}

        for _, v in pairs(data) do
            local temp = XSpringFestivalBoxGift.New(v)
            tableInsert(_GiftBoxData, temp)
        end
        tableSort(_GiftBoxData,function(a,b)
            if a:IsReceive() ~= b:IsReceive() then
                return not a:IsReceive()
            end
        end)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_SPRING_FESTIVAL_GIFT_BAG_REFRESH)
    end

    local function SetAllGiftReceived()
        for _, v in pairs(_GiftBoxData) do
            v:SetReceive(true)
        end
    end

    local function UpdateRequestWordData(data)
        if not data then
            return
        end
        _RequestWordId = data.WordId or _RequestWordId
        _LastRequestTime = data.LastRequestTime or _LastRequestTime
        _LastSendGuildRequestTime = data.LastSendGuildRequestTime or _LastSendGuildRequestTime
    end

    function XSpringFestivalActivityManager.NotifyCollectWordsActivityData(data)
        if not data then
            return
        end
        UpdateRecvFinalRewardTimes(data.JackpotRecvRewardTime)
        UpdateGetRewardInfo(data.RecvHalfRewardRecordData)
        UpdateCurrActivityId(data.ActivityId)
        UpdateGiftBoxData(data.GiftBoxData)
        UpdateRequestWordData(data.RequestWordData)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_SPRING_FESTIVAL_COLLECT_CARD_REFRESH)
    end

    function XSpringFestivalActivityManager.NotifyRecvHalfRewardRecordInfo(data)
        if not data then
            return
        end
        UpdateRecvFinalRewardTimes(data.JackpotRecvRewardTime)
        UpdateGetRewardInfo(data.RecvHalfRewardRecordData)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_SPRING_FESTIVAL_COLLECT_CARD_REFRESH)
    end

    function XSpringFestivalActivityManager.NotifyCollectWordsRequestInfoChange(data)
        if not data then return end
        UpdateRequestWordData(data.RequestWordData)
    end

    function XSpringFestivalActivityManager.NotifyRecvGiftFromOther(data)
        if not data and not data.GiftData then
            return
        end
        for i = 1,#data.GiftData do
            local giftData = XSpringFestivalBoxGift.New(data.GiftData[i])
            tableInsert(_GiftBoxData, giftData)
            if #_GiftBoxData > CollectWordsGiftBoxMaxCount then
                local min = XTime.GetServerNowTimestamp()
                local index = 0
                for i = 1, #_GiftBoxData do
                    if min > _GiftBoxData[i]:GetTime() then
                        min = _GiftBoxData[i]:GetTime()
                        index = i
                    end
                end
                tableRemove(_GiftBoxData,index)
            end
        end
        tableSort(_GiftBoxData,function(a,b)
            if a:IsReceive() ~= b:IsReceive() then
                return not a:IsReceive()
            end
        end)
        XEventManager.DispatchEvent(XEventId.EVENT_SPRING_FESTIVAL_GIFT_BAG_RED)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_SPRING_FESTIVAL_GIFT_BAG_REFRESH)
    end

    function XSpringFestivalActivityManager.NotifySmashEggsActivityData(data)
        if not data then
            return
        end
        _SequenceSuccessCount = data.SequenceSuccessCount or _SequenceSuccessCount
        _EggList = data.EggsData or _EggList
        _TodayScore = data.TodayScore or _TodayScore
        _CurrentScore = data.CurrentScore or _CurrentScore
        _HighestScore = data.HighestScore or _HighestScore
        _TodayScoreRewardStatus = data.TodayScoreRewardStatus or _TodayScoreRewardStatus
        UpdateLastUseItemData(data.LastUseItemData)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_SPRING_FESTIVAL_SMASH_EGGS_REFRESH)
    end

    function XSpringFestivalActivityManager.NotifySmashEggsActivityDailyReset(data)
        if not data then
            return
        end
        _TodayScoreRewardStatus = data.TodayScoreRewardStatus or _TodayScoreRewardStatus
        _TodayScore = data.TodayScore or _TodayScore
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_SPRING_FESTIVAL_SMASH_EGGS_REFRESH)
    end
    -----------------------推送相关 end----------------------------
    -----------------------请求相关 begin----------------------------
    --送字给好友或公会成员请求
    function XSpringFestivalActivityManager.CollectWordsGiveWordToOthersRequest(wordId, otherId,isRequest, callback)
        local count = XDataCenter.ItemManager.GetCount(wordId)
        if count == 0 then
            XUiManager.TipText("SpringFestivalItemCantSend")
            return
        end
        local request = { WordId = wordId, OtherId = otherId,IsRequest = isRequest }
        XNetwork.Call("CollectWordsGiveWordToOthersRequest", request, function(res)
            if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if callback then
                    callback(res.RewardGoodsList)
                end
        end)
    end
    --领取上下阕奖励请求
    function XSpringFestivalActivityManager.CollectWordsRecvRewardRequest(type, callback)
        local request = { Type = type }
        XNetwork.Call("CollectWordsRecvRewardRequest", request, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_SPRING_FESTIVAL_COLLECT_CARD_REFRESH)
                if callback then
                    callback(res.RewardGoodsList)
                end
        end)
    end
    -- 领取终极大奖奖励请求
    function XSpringFestivalActivityManager.CollectWordsRecvGrandPrizeRewardRequest(callback)
        XNetwork.Call("CollectWordsRecvGrandPrizeRewardRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if callback then
                callback(res.RewardGoodsList)
            end
        end)
    end

    --更新求字请求
    function XSpringFestivalActivityManager.CollectWordsRequestWordRequest(wordId, callback)
        local request = { WordId = wordId }
        XNetwork.Call("CollectWordsRequestWordRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            UpdateRequestWordData(res.RequestWordInfo)
            if XDataCenter.GuildManager.IsJoinGuild() then
                local chatData = {
                    ChannelType = ChatChannelType.Guild,
                    MsgType = ChatMsgType.SpringFestival,
                    Content = CS.XTextManager.GetText("SpringFestivalCollectCardGuildHelp", XDataCenter.ItemManager.GetItemName(XSpringFestivalActivityManager.GetRequestWordId())),
                    TargetIds = { XPlayer.Id }
                }
                XDataCenter.ChatManager.SendChat(chatData, function()
                    if callback then
                        callback()
                    end
                end)
            else
                if callback then
                    callback()
                end
            end

        end)
    end

    function XSpringFestivalActivityManager.CollectWordsRequestWordToFriendRequest(friendId, callback)
        local request = { FriendId = friendId }
        XNetwork.Call("CollectWordsRequestWordToFriendRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if callback then
                callback()
            end
        end)
    end

    --向公会求字请求
    function XSpringFestivalActivityManager.CollectWordsRequestWordToGuildRequest(callback)
        XNetwork.Call("CollectWordsRequestWordToGuildRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            local chatData = {
                ChannelType = ChatChannelType.Guild,
                MsgType = ChatMsgType.SpringFestival,
                Content = CS.XTextManager.GetText("SpringFestivalCollectCardGuildHelp", XDataCenter.ItemManager.GetItemName(XSpringFestivalActivityManager.GetRequestWordId())),
                TargetIds = { XPlayer.Id }
            }
            XDataCenter.ChatManager.SendChat(chatData, function()
                if callback then
                    callback()
                end
            end)
        end)
    end

    --一键领取礼物盒中的礼物请求
    function XSpringFestivalActivityManager.CollectWordsRecvWordGiftFromGiftBoxRequest(callback)
        XNetwork.Call("CollectWordsRecvWordGiftFromGiftBoxRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            SetAllGiftReceived()
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_SPRING_FESTIVAL_COLLECT_CARD_REFRESH)
            if callback then
                callback()
            end
        end)
    end

    function XSpringFestivalActivityManager.CollectWordsRefreshRequestWordListRequest(callback)
        XNetwork.Call("CollectWordsRefreshRequestWordListRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            UpdateRequestWordList(res.RequestList)
            if callback then
                callback()
            end
        end)
    end

    function XSpringFestivalActivityManager.SmashEggRequest(eggPlace, useItem, callback)
        local request = {
            EggPlace = eggPlace,
            UseItemData = useItem
        }
        XNetwork.Call("SmashEggRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_SPRING_FESTIVAL_SMASH_EGGS_REFRESH)
            if callback then
                callback(res.IsSuccess, res.DropItem, res.AddScore)
            end
        end)
    end

    function XSpringFestivalActivityManager.SmashEggsGetActivationDailyRewardRequest(index, callback)
        local request = {
            StageIndex = index
        }
        XNetwork.Call("SmashEggsGetActivationDailyRewardRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _TodayScoreRewardStatus = res.TodayScoreRewardStatus or _TodayScoreRewardStatus
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_SPRING_FESTIVAL_SMASH_EGGS_REFRESH)
            if callback then
                callback(res.RewardList)
            end
        end)
    end

    function XSpringFestivalActivityManager.SmashEggsConvertScoreRequest(callback)
        XNetwork.Call("SmashEggsConvertScoreRequest", nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            _CurrentScore = 0
            _SequenceSuccessCount = 0
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_SPRING_FESTIVAL_SMASH_EGGS_REFRESH)
            if callback then
                callback()
            end
        end)
    end

    function XSpringFestivalActivityManager.SmashEggsResetEggsRequest(list, callback)
        local request = {
            ResetList = list
        }
        XNetwork.Call("SmashEggsResetEggsRequest", request, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            ResetEggList()
            if callback then
                callback()
            end
        end)
    end

    -----------------------请求相关 end----------------------------
    return XSpringFestivalActivityManager
end

-----------------------协议相关 begin----------------------------
XRpc.NotifyCollectWordsActivityData = function(data)
    XDataCenter.SpringFestivalActivityManager.NotifyCollectWordsActivityData(data)
end

XRpc.NotifyCollectWordsRequestInfoChange = function(data)
    XDataCenter.SpringFestivalActivityManager.NotifyCollectWordsRequestInfoChange(data)
end

XRpc.NotifyRecvHalfRewardRecordInfo = function(data)
    XDataCenter.SpringFestivalActivityManager.NotifyRecvHalfRewardRecordInfo(data)
end

XRpc.NotifyRecvGiftFromOther = function(data)
    XDataCenter.SpringFestivalActivityManager.NotifyRecvGiftFromOther(data)
end

XRpc.NotifySmashEggsActivityData = function(data)
    XDataCenter.SpringFestivalActivityManager.NotifySmashEggsActivityData(data)
end

XRpc.NotifySmashEggsActivityDailyReset = function(data)
    XDataCenter.SpringFestivalActivityManager.NotifySmashEggsActivityDailyReset(data)
end
-----------------------协议相关 end----------------------------
