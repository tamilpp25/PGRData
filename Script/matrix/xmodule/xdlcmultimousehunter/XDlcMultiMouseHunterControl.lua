local XDlcMutiplayerActivityControl = require(
    "XModule/XDlcMultiplayer/XDlcMultiplayerActivity/XDlcMutiplayerActivityControl")
local XDlcMultiplayerFriend = require("XModule/XDlcMultiMouseHunter/XEntity/XDlcMultiplayerFriend")
local XDlcMultiplayerTitle = require("XModule/XDlcMultiMouseHunter/XEntity/XDlcMultiplayerTitle")

---@class XDlcMultiMouseHunterControl : XDlcMutiplayerActivityControl
---@field private _Model XDlcMultiMouseHunterModel
local XDlcMultiMouseHunterControl = XClass(XDlcMutiplayerActivityControl, "XDlcMultiMouseHunterControl")

function XDlcMultiMouseHunterControl:OnStart()
    -- 初始化内部变量
    self._TitleCache = {}
    self._FriendCache = nil
    self._FriendMap = {}
    self._TitleList = nil
    self._FriendInfoSyncTime = 20
    self._LastFriendInfoSyncTime = 0

    self._IsRegisterEvent = false
    self._ChatEventData = nil
    self._MatchEventData = nil

    self._ButtonState = nil
end

function XDlcMultiMouseHunterControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XDlcMultiMouseHunterControl:RemoveAgencyEvent()

end

function XDlcMultiMouseHunterControl:OnDestroy()
    self._TitleCache = {}
    self._FriendCache = nil
    self._FriendMap = {}
    self._TitleList = nil
    self._LastFriendInfoSyncTime = 0

    self._ChatEventData = nil
    self._MatchEventData = nil

    self._ButtonState = nil

    self:RemoveEventCacheListeners()
end

function XDlcMultiMouseHunterControl:OpenFriendInviteUi()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialFriend) then
        return
    end

    local nowTime = XTime.GetServerNowTimestamp()

    if not self._FriendCache or self._LastFriendInfoSyncTime + self._FriendInfoSyncTime <= nowTime then
        local friendList = XDataCenter.SocialManager.GetFriendList()
        local playerIds = {}

        for _, friend in pairs(friendList) do
            table.insert(playerIds, friend.FriendId)
        end

        if XTool.IsTableEmpty(playerIds) then
            self._FriendCache = {}
            self._FriendMap = {}
            XLuaUiManager.Open("UiDlcMultiPlayerInvite", self._FriendCache)
        else
            XDataCenter.SocialManager.GetPlayerInfoListByServer(playerIds, function(friendInfoList)
                self._FriendCache = {}
                self._LastFriendInfoSyncTime = XTime.GetServerNowTimestamp()

                self:_SortFriendList(friendInfoList)
                for i, friendInfo in pairs(friendInfoList) do
                    local cache = self._FriendMap[friendInfo.Id]

                    if cache then
                        cache:SetData(friendInfo)
                    else
                        cache = XDlcMultiplayerFriend.New(friendInfo)
                    end

                    self._FriendCache[i] = cache
                    self._FriendMap[friendInfo.Id] = cache
                end
                XLuaUiManager.Open("UiDlcMultiPlayerInvite", self._FriendCache)
            end)
        end
    else
        XLuaUiManager.Open("UiDlcMultiPlayerInvite", self._FriendCache)
    end
end

function XDlcMultiMouseHunterControl:OpenTitleUi()
    XLuaUiManager.Open("UiDlcMultiPlayerTitle")
end

function XDlcMultiMouseHunterControl:OpenMatchingPopupUi(startTime)
    if XTool.IsNumberValid(startTime) and not XLuaUiManager.IsUiShow("UiDlcMultiPlayerMatchingPopup") then
        XLuaUiManager.Open("UiDlcMultiPlayerMatchingPopup", startTime)
    end
end

function XDlcMultiMouseHunterControl:OpenUiDlcMultiPlayerSkill(matchingTime)
    self:OpenMatchingPopupUi(matchingTime)
    XLuaUiManager.Open("UiDlcMultiPlayerSkill")
end

function XDlcMultiMouseHunterControl:OpenUiDlcMultiPlayerGift(matchingTime)
    self:OpenMatchingPopupUi(matchingTime)
    XLuaUiManager.Open("UiDlcMultiPlayerGift")
end

function XDlcMultiMouseHunterControl:OpenUiDlcMultiPlayerCompetition(matchingTime)
    self:OpenMatchingPopupUi(matchingTime)
    XLuaUiManager.Open("UiDlcMultiPlayerCompetition")
end

function XDlcMultiMouseHunterControl:OpenShopUi(matchingTime)
    local shopId = self:GetShopId()

    if XTool.IsNumberValid(shopId) then
        XShopManager.GetShopInfo(shopId, function()
            self:OpenMatchingPopupUi(matchingTime)
            XLuaUiManager.Open("UiDlcMultiPlayerShop", shopId)
            self._Model:SetIsShowShopRedPoint(false)
        end)
    end
end

function XDlcMultiMouseHunterControl:AutoCloseHandler(isClose)
    if isClose then
        XLuaUiManager.RunMain(true)
        XUiManager.TipText("CommonActivityEnd")
    end
end

function XDlcMultiMouseHunterControl:GetActivityId()
    return self._Model:GetActivityId()
end

function XDlcMultiMouseHunterControl:GetCurrentWorldIdAndLevelId()
    ---@type XDlcMultiMouseHunterAgency
    local agency = self:GetAgency()

    return agency:GetCurrentWorldIdAndLevelId()
end

function XDlcMultiMouseHunterControl:GetCurrencyCount()
    return self._Model:GetCurrencyCount()
end

function XDlcMultiMouseHunterControl:GetCurrentActivityName()
    local activityId = self:GetActivityId()

    return self._Model:GetDlcMultiplayerActivityNameById(activityId)
end

function XDlcMultiMouseHunterControl:GetActivityEndTime()
    local activityId = self:GetActivityId()
    local timeId = self._Model:GetDlcMultiplayerActivityTimeIdById(activityId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)

    return endTime
end

function XDlcMultiMouseHunterControl:GetActivityEndTimeStr()
    local endTime = self:GetActivityEndTime()
    local nowTime = XTime.GetServerNowTimestamp()

    return XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XDlcMultiMouseHunterControl:GetCurrentWorldMapIcon()
    local worldId, levelId = self:GetCurrentWorldIdAndLevelId()

    return self._Model:GetDlcMultiplayerWorldIconById(tostring(worldId) .. tostring(levelId))
end

function XDlcMultiMouseHunterControl:GetCurrentWorldName()
    local worldId = self:GetCurrentWorldIdAndLevelId()

    return XMVCA.XDlcWorld:GetWorldNameById(worldId)
end

function XDlcMultiMouseHunterControl:GetCurrentWorldScene()
    local worldId, levelId = self:GetCurrentWorldIdAndLevelId()

    return self:GetWorldSceneByWorldIdAndLevelId(worldId, levelId)
end

function XDlcMultiMouseHunterControl:GetWorldSceneByWorldIdAndLevelId(worldId, levelId)
    return self._Model:GetDlcMultiplayerWorldSceneUrlById(tostring(worldId) .. tostring(levelId))
end

function XDlcMultiMouseHunterControl:GetCurrentWorldSceneModel()
    local worldId, levelId = self:GetCurrentWorldIdAndLevelId()

    return self:GetWorldSceneModelByWorldIdAndLevelId(worldId, levelId)
end

function XDlcMultiMouseHunterControl:GetWorldSceneModelByWorldIdAndLevelId(worldId, levelId)
    return self._Model:GetDlcMultiplayerWorldSceneModelUrlById(tostring(worldId) .. tostring(levelId))
end

function XDlcMultiMouseHunterControl:GetCurrentWorldLoadingBackground()
    local worldId, levelId = self:GetCurrentWorldIdAndLevelId()

    return self._Model:GetDlcMultiplayerWorldLoadingBackgroundById(tostring(worldId) .. tostring(levelId))
end

function XDlcMultiMouseHunterControl:GetCurrentWorldArtName()
    local worldId, levelId = self:GetCurrentWorldIdAndLevelId()

    return self._Model:GetDlcMultiplayerWorldArtNameById(tostring(worldId) .. tostring(levelId))
end

function XDlcMultiMouseHunterControl:GetCurrentMaskLoadingType()
    local worldId, levelId = self:GetCurrentWorldIdAndLevelId()

    return self._Model:GetDlcMultiplayerWorldMaskLoadingTypeById(tostring(worldId) .. tostring(levelId))
end

function XDlcMultiMouseHunterControl:GetCoinItemIds()
    local itemIds = self:_GetClientConfigValuesByKey("CoinItemIds")
    local result = {}

    for i, itemId in pairs(itemIds) do
        result[i] = tonumber(itemId)
    end

    return result
end

function XDlcMultiMouseHunterControl:GetCoinItemId(index)
    return self:GetCoinItemIds()[index or 1]
end

function XDlcMultiMouseHunterControl:CheckCoinInTime(index)
    local itemId = self:GetCoinItemId(index)

    if not XTool.IsNumberValid(itemId) then
        return false
    end

    return XDataCenter.ItemManager.GetItem(itemId) ~= nil
end

function XDlcMultiMouseHunterControl:CheckAllCoinsInTime()
    local itemIds = self:GetCoinItemIds()

    if not XTool.IsTableEmpty(itemIds) then
        for _, itemId in pairs(itemIds) do
            if XDataCenter.ItemManager.GetItem(itemId) == nil then
                return false
            end
        end

        return true
    end

    return false
end

function XDlcMultiMouseHunterControl:GetCoinIcon()
    local itemId = self:GetCoinItemId()

    return XDataCenter.ItemManager.GetItemIcon(itemId)
end

function XDlcMultiMouseHunterControl:GetCurrencyLimit()
    return self._Model:GetCurrencyLimit()
end

function XDlcMultiMouseHunterControl:GetCurrencyLimitStr()
    local dailyUpper = self:GetCurrencyLimit()
    local dailyCount = self:GetCurrencyCount()

    dailyCount = math.min(dailyCount, tonumber(dailyUpper))

    return dailyCount .. "/" .. dailyUpper
end

function XDlcMultiMouseHunterControl:GetShowRewardIds()
    local rewardIds = self:_GetClientConfigValuesByKey("ShowRewards")
    local result = {}

    for i, rewardId in pairs(rewardIds) do
        result[i] = tonumber(rewardId)
    end

    return result
end

function XDlcMultiMouseHunterControl:GetShowRewardTime()
    local showTime = self:_GetClientConfigValueByKeyAndIndex("ShowRewardTime", 1)

    return tonumber(showTime)
end

function XDlcMultiMouseHunterControl:GetInvitedTime()
    return XMVCA.XDlcRoom:GetInviteShowTime()
end

function XDlcMultiMouseHunterControl:GetUnlockedLevel()
    local unlockedLevel = self:_GetClientConfigValueByKeyAndIndex("InvitedUnlockedLevel", 1)

    return tonumber(unlockedLevel)
end

function XDlcMultiMouseHunterControl:GetSettleWinTitle()
    local winTitle = self:_GetClientConfigValueByKeyAndIndex("SettleTitle", 1)

    return winTitle
end

function XDlcMultiMouseHunterControl:GetSettleLoseTitle()
    local loseTitle = self:_GetClientConfigValueByKeyAndIndex("SettleTitle", 2)

    return loseTitle
end

function XDlcMultiMouseHunterControl:GetSettleDataCatTitle()
    local winTitle = self:_GetClientConfigValueByKeyAndIndex("SettleDataTitle", 1)

    return winTitle
end

function XDlcMultiMouseHunterControl:GetSettleDataMouseTitle()
    local loseTitle = self:_GetClientConfigValueByKeyAndIndex("SettleDataTitle", 2)

    return loseTitle
end

function XDlcMultiMouseHunterControl:GetInviteLockedTipStr(level)
    return XUiHelper.GetText("DlcMultiplayerInvitedLockedTips", level)
end

function XDlcMultiMouseHunterControl:GetInvitedPlayerInTeamStr()
    return XUiHelper.GetText("DlcMultiplayerInvitedInRoomTips")
end

function XDlcMultiMouseHunterControl:GetShopIds()
    local activityId = self:GetActivityId()
    return self._Model:GetDlcMultiplayerActivityShopIdListById(activityId)
end

function XDlcMultiMouseHunterControl:GetShopId(index)
    return self:GetShopIds()[index or 1]
end

function XDlcMultiMouseHunterControl:GetShopName(index)
    local shopId = self:GetShopId()

    return XShopManager.GetShopName(shopId)
end

function XDlcMultiMouseHunterControl:GetHelpId()
    local activityId = self:GetActivityId()

    return self._Model:GetDlcMultiplayerActivityHelpIdById(activityId)
end

function XDlcMultiMouseHunterControl:GetShopItemNotBuyColor()
    return self:_GetClientConfigValueByKeyAndIndex("ShopTextNotBuyColor", 1)
end

function XDlcMultiMouseHunterControl:GetShopItemCanBuyColor()
    return self:_GetClientConfigValueByKeyAndIndex("ShopTextCanBuyColor", 1)
end

function XDlcMultiMouseHunterControl:GetShopItemTextColor()
    return {
        CanBuyColor = self:GetShopItemCanBuyColor(),
        CanNotBuyColor = self:GetShopItemNotBuyColor(),
    }
end

---@return XDlcMultiplayerTitle[]
function XDlcMultiMouseHunterControl:GetTitleList()
    if not self._TitleList or self._Model:GetIsRefreshTitlInfo() then
        local activityId = self:GetActivityId()
        local titleGroupId = self._Model:GetDlcMultiplayerActivityTitleGroupIdById(activityId)
        local titleIdList = self._Model:GetDlcMultiplayerTitleGroupTitleIdsById(titleGroupId)
        local titleInfoList = self._Model:GetUnlockTitleInfos()
        local currentWearTitle = self._Model:GetCurrentWearTitleId()
        local titleProgress = self._Model:GetTitleProgress()

        self._TitleList = {}
        self._Model:RefreshedTitleInfo()
        if not XTool.IsTableEmpty(titleIdList) then
            for i, titleId in pairs(titleIdList) do
                local title = self._TitleCache[titleId]
                local config = self._Model:GetDlcMultiplayerTitleConfigById(titleId)

                if not title then
                    title = XDlcMultiplayerTitle.New(config)
                    self._TitleCache[titleId] = title
                else
                    title:SetData(config)
                end

                title:SetProgress(titleProgress[titleId] or 0)
                self._TitleList[i] = title
            end
        end
        if not XTool.IsTableEmpty(titleInfoList) then
            for i, titleInfo in pairs(titleInfoList) do
                local title = self._TitleCache[titleInfo.TitleId]

                if title then
                    title:SetInfo(titleInfo, titleInfo.TitleId == currentWearTitle)
                end
            end
        end
        table.sort(self._TitleList, function(titleA, titleB)
            if titleA:GetIsUnlock() == titleB:GetIsUnlock() then
                return titleA:GetUnlockTime() < titleB:GetUnlockTime()
            end

            return titleA:GetIsUnlock()
        end)
    end

    return self._TitleList
end

function XDlcMultiMouseHunterControl:GetTitleUnlockNumber()
    local count = 0
    local titleInfoList = self._Model:GetUnlockTitleInfos()

    if not XTool.IsTableEmpty(titleInfoList) then
        return #titleInfoList
    end

    return count
end

function XDlcMultiMouseHunterControl:GetTitleTotalNumber()
    local activityId = self:GetActivityId()
    local titleGroupId = self._Model:GetDlcMultiplayerActivityTitleGroupIdById(activityId)
    local titleIdList = self._Model:GetDlcMultiplayerTitleGroupTitleIdsById(titleGroupId)

    return #titleIdList
end

function XDlcMultiMouseHunterControl:GetLoadingTips()
    local tips = self:_GetClientConfigValuesByKey("LoadingTips")

    return XTool.RandomArray(tips, os.time())
end

function XDlcMultiMouseHunterControl:GetLoadingTipsScrollingTime()
    return tonumber(self:_GetClientConfigValueByKeyAndIndex("LoadingTipsScrollingTime", 1))
end

function XDlcMultiMouseHunterControl:GetCatCampName()
    return self:_GetClientConfigValueByKeyAndIndex("CampName", 1)
end

function XDlcMultiMouseHunterControl:GetMouseCampName()
    return self:_GetClientConfigValueByKeyAndIndex("CampName", 2)
end

function XDlcMultiMouseHunterControl:GetCharacterIdList()
    local activityId = self:GetActivityId()
    local characterPoolId = self._Model:GetDlcMultiplayerActivityCharacterPoolIdById(activityId)
    local characterIds = self._Model:GetDlcMultiplayerCharacterPoolCharacterIdsById(characterPoolId)

    return characterIds or {}
end

function XDlcMultiMouseHunterControl:GetSelectCharacterIndex(characterId)
    local characterIds = self:GetCharacterIdList()

    for i, id in pairs(characterIds) do
        if id == characterId then
            return i
        end
    end

    return 1
end

function XDlcMultiMouseHunterControl:GetCharacterCuteHeadIconByCharacterId(characterId)
    return self._Model:GetDlcMultiplayerCharacterSquareHeadImageById(characterId)
end

function XDlcMultiMouseHunterControl:GetCharacterNameByCharacterId(characterId)
    return self._Model:GetDlcMultiplayerCharacterNameById(characterId)
end

function XDlcMultiMouseHunterControl:GetCharacterTradeNameByCharacterId(characterId)
    return self._Model:GetDlcMultiplayerCharacterTradeNameById(characterId)
end

function XDlcMultiMouseHunterControl:GetCharacterMvpActionByCharacterId(characterId)
    return self._Model:GetDlcMultiplayerCharacterMvpActionById(characterId)
end

function XDlcMultiMouseHunterControl:GetCharacterVictoryActionByCharacterId(characterId)
    return self._Model:GetDlcMultiplayerCharacterVictoryActionById(characterId)
end

function XDlcMultiMouseHunterControl:GetCharacterFailActionByCharacterId(characterId)
    return self._Model:GetDlcMultiplayerCharacterFailActionById(characterId)
end

function XDlcMultiMouseHunterControl:UpdateCharacterModelByCharacterId(displayProxy, characterId, callback)
    if displayProxy and XTool.IsNumberValid(characterId) then
        local modelId = self._Model:GetDlcMultiplayerCharacterModelIdById(characterId)

        displayProxy:UpdateRoleModel(modelId, nil, nil, function(model)
            -- Q版模型禁止动画移动
            displayProxy:CloseRootMotion(model)
            if callback then
                callback(model)
            end
        end, nil, true)
    end
end

function XDlcMultiMouseHunterControl:GetCurrentWearTitleIndex()
    local titleList = self:GetTitleList()

    for i, title in pairs(titleList) do
        if title:GetIsWear() then
            return i
        end
    end

    return 0
end

function XDlcMultiMouseHunterControl:GetTitleIcon(titleId)
    ---@type XDlcMultiMouseHunterAgency
    local agency = self:GetAgency()

    return agency:GetTitleIcon(titleId)
end

function XDlcMultiMouseHunterControl:RegisterEventCacheListeners()
    if not self._IsRegisterEvent then
        XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.OnReceiveChatMessageCache, self)
        XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MULTI_CANCEL_MATCH, self.OnRefreshCancelMatching, self)
        XEventManager.AddEventListener(XEventId.EVENT_DLC_ROOM_MULTI_START_MATCH, self.OnRefreshMatching, self)
        self._IsRegisterEvent = true
    end
end

function XDlcMultiMouseHunterControl:RemoveEventCacheListeners()
    if self._IsRegisterEvent then
        XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.OnReceiveChatMessageCache, self)
        XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MULTI_CANCEL_MATCH, self.OnRefreshCancelMatching, self)
        XEventManager.RemoveEventListener(XEventId.EVENT_DLC_ROOM_MULTI_START_MATCH, self.OnRefreshMatching, self)
        self._IsRegisterEvent = false
    end
end

function XDlcMultiMouseHunterControl:RecordButtonState(state, matchTime)
    if state then
        self._ButtonState = {
            State = state,
            MatchTime = matchTime,
        }
    end
end

-- region 事件

function XDlcMultiMouseHunterControl:CheckRefreshButtonState()
    return self._ButtonState ~= nil
end

function XDlcMultiMouseHunterControl:GetButtonState()
    return self._ButtonState
end

function XDlcMultiMouseHunterControl:ClearButtonState()
    self._ButtonState = nil
end

function XDlcMultiMouseHunterControl:CheckRefreshMatchEvent()
    return self._MatchEventData ~= nil
end

function XDlcMultiMouseHunterControl:GetMatchEventData()
    return self._MatchEventData
end

function XDlcMultiMouseHunterControl:ClearMatchEvent()
    self._MatchEventData = nil
end

function XDlcMultiMouseHunterControl:CheckRefreshChatEvent()
    return self._ChatEventData ~= nil
end

function XDlcMultiMouseHunterControl:GetChatEventData()
    return self._ChatEventData
end

function XDlcMultiMouseHunterControl:ClearChatEvent()
    self._ChatEventData = nil
end

function XDlcMultiMouseHunterControl:OnReceiveChatMessageCache(chatData)
    if self._ChatEventData then
        self._ChatEventData.LastData = chatData
        if self._ChatEventData.Datas[chatData.SenderId] then
            self._ChatEventData.Datas[chatData.SenderId].ChatData = chatData
            self._ChatEventData.Datas[chatData.SenderId].Time = XTime.GetServerNowTimestamp()
        else
            self._ChatEventData.Datas[chatData.SenderId] = {
                ChatData = chatData,
                Time = XTime.GetServerNowTimestamp(),
            }
        end
    else
        self._ChatEventData = {
            Datas = {
                [chatData.SenderId] = {
                    ChatData = chatData,
                    Time = XTime.GetServerNowTimestamp(),
                },
            },
            LastData = chatData,
        }
    end
end

function XDlcMultiMouseHunterControl:OnRefreshMatching(startTime)
    self:OpenMatchingPopupUi(startTime)
    if self._MatchEventData then
        self._MatchEventData.IsMatching = true
        self._MatchEventData.Time = startTime
    else
        self._MatchEventData = {
            IsMatching = true,
            Time = startTime,
        }
    end
end

function XDlcMultiMouseHunterControl:OnRefreshCancelMatching(changeTime)
    if self._MatchEventData then
        self._MatchEventData.IsMatching = false
        self._MatchEventData.Time = changeTime
    else
        self._MatchEventData = {
            IsMatching = false,
            Time = changeTime,
        }
    end
end

function XDlcMultiMouseHunterControl:CheckPlayerInRoom(playerId)
    if XMVCA.XDlcRoom:IsInRoom() and XTool.IsNumberValid(playerId) then
        local team = XMVCA.XDlcRoom:GetTeam()

        return team:IsPlayerInTeam(playerId)
    end

    return false
end

-- endregion

function XDlcMultiMouseHunterControl:PlayOffFrameAnimation(gridList, animationName, nodeName, interval, beginWait)
    if XTool.IsTableEmpty(gridList) then
        return
    end

    local animationList = {}
    local count = 0
    local index = 0

    for index, grid in pairs(gridList) do
        local animation = grid.Transform:FindTransform(animationName)

        if animation then
            count = count + 1
            table.insert(animationList, {
                Animation = animation,
                Grid = grid,
                Index = index,
            })
        end
    end

    table.sort(animationList, function(animationA, animationB)
        return animationA.Index < animationB.Index
    end)
    XLuaUiManager.SetMask(true, self:_GetPlayAnimationMaskKey())
    RunAsyn(function()
        if XTool.IsNumberValid(beginWait) then
            asynWaitSecond(beginWait)
        end

        for _, animation in pairs(animationList) do
            animation.Animation:PlayTimelineAnimation(function()
                self:SetGridTransparent(animation.Grid, true, nodeName)
                index = index + 1
                if index == count then
                    XLuaUiManager.SetMask(false, self:_GetPlayAnimationMaskKey())
                end
            end)

            if XTool.IsNumberValid(interval) then
                asynWaitSecond(interval)
            end
        end
    end)
end

function XDlcMultiMouseHunterControl:SetGridTransparent(grid, value, canvasGroupName)
    if not grid then
        return
    end

    if XTool.UObjIsNil(grid.CanvasGroup) then
        self:_InitGridCanvasGroup(grid, canvasGroupName)
    end
    if not XTool.UObjIsNil(grid.CanvasGroup) then
        grid.CanvasGroup.alpha = value and 1 or 0
    end
end

function XDlcMultiMouseHunterControl:_InitGridCanvasGroup(grid, canvasGroupName)
    if XTool.UObjIsNil(grid.CanvasGroup) then
        local imgBg = nil
        if string.IsNilOrEmpty(canvasGroupName) then
            imgBg = grid.Transform
        else
            imgBg = grid.Transform:FindTransform(canvasGroupName)
        end

        if imgBg then
            grid.CanvasGroup = imgBg.gameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
        end
    end
end

function XDlcMultiMouseHunterControl:_GetClientConfigValueByKeyAndIndex(key, index)
    local results = self:_GetClientConfigValuesByKey(key)

    if not results[index] then
        return ""
    end

    return results[index]
end

function XDlcMultiMouseHunterControl:_GetClientConfigValuesByKey(key)
    return self._Model:GetDlcMultiplayerConfigValuesByKey(key) or {}
end

function XDlcMultiMouseHunterControl:_SortFriendList(friendDatas)
    if friendDatas == nil or #friendDatas <= 1 then
        return friendDatas
    end

    table.sort(friendDatas, Handler(self, self._SortFriendListHandler))

    return friendDatas
end

function XDlcMultiMouseHunterControl:_SortFriendListHandler(friendA, friendB)
    if friendA.IsOnline == friendB.IsOnline then
        if friendA.IsOnline then
            -- 双方都在线
            if friendA.FriendExp == friendB.FriendExp then
                return friendA.Level > friendB.Level
            end

            return friendA.FriendExp > friendB.FriendExp
        else
            -- 双方都不在线
            if friendA.LastLoginTime == friendB.LastLoginTime then
                if friendA.FriendExp == friendB.FriendExp then
                    return friendA.Level > friendB.Level
                end

                return friendA.FriendExp > friendB.FriendExp
            end

            return friendA.LastLoginTime > friendB.LastLoginTime
        end
    end

    return friendA.IsOnline
end

function XDlcMultiMouseHunterControl:_GetPlayAnimationMaskKey()
    return "DlcMultiMouseHunterPlayAnimationMask"
end

function XDlcMultiMouseHunterControl:GetDlcMultiplayerConfigConfigByKey(key)
    return self._Model:GetDlcMultiplayerConfigConfigByKey(key)
end

-- region 投票
function XDlcMultiMouseHunterControl:GetDiscussion()
    return self._Model:GetDiscussion()
end

function XDlcMultiMouseHunterControl:IsOpenVoteCompetitionUi()
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return false
    end

    local discussion = self:GetDiscussion()
    if discussion == nil or (not discussion:HasDiscussionData() and not discussion:HasPlayerData()) then
        return false
    end

    local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionCamp
    local StatusEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionStatus
    return (discussion:GetStatus() == StatusEnum.Vote and discussion:GetPlayerCamp() == CampEnum.None) or discussion:CanGetReward()
end

function XDlcMultiMouseHunterControl:SaveDiscussionRedPoint()
    self._Model:SaveDiscussionRedPoint()
end
--endregion

--region bp
function XDlcMultiMouseHunterControl:RequestDlcMultiplayerGetBpReward()
    XMVCA.XDlcMultiMouseHunter:RequestDlcMultiplayerGetBpReward(function(rewardList)
        if not rewardList then
            return
        end
        XUiManager.OpenUiObtain(rewardList)
    end)
end

function XDlcMultiMouseHunterControl:GetBpTaskList(taskType, isSort)
    return self._Model:GetBpTaskList(taskType, isSort)
end

function XDlcMultiMouseHunterControl:CheckReceiveBpReawrd(lv)
    return self._Model:CheckReceiveBpReawrd(lv)
end

function XDlcMultiMouseHunterControl:GetBpRewardIds()
    return self._Model:GetBpRewardIds()
end

function XDlcMultiMouseHunterControl:GetBpLevel()
    return self._Model:GetBpLevel()
end

function XDlcMultiMouseHunterControl:RequestFinishAllBpTask(taskType)
    local allTaskIds = nil
    local bpTasks = self:GetBpTaskList(taskType, false)

    for _, v in pairs(bpTasks) do
        if XDataCenter.TaskManager.CheckTaskAchieved(v.Id) then
            allTaskIds = allTaskIds or {}
            table.insert(allTaskIds, v.Id)
        end
    end
    
    if not allTaskIds then
        return
    end

    XDataCenter.TaskManager.FinishMultiTaskRequest(allTaskIds, function(rewardGoodsList)
        local horizontalNormalizedPosition = 0
        XUiManager.OpenUiObtain(rewardGoodsList, nil, nil, nil, horizontalNormalizedPosition)
    end)
end

function XDlcMultiMouseHunterControl:GetDlcMultiplayerBPConfigs()
    return self._Model:GetDlcMultiplayerBPConfigs()
end

function XDlcMultiMouseHunterControl:GetDlcMultiplayerBPConfigById(id)
    return self._Model:GetDlcMultiplayerBPConfigById(id)
end

function XDlcMultiMouseHunterControl:CheckBpRedPoint()
    return self._Model:CheckBpRedPoint()
end

function XDlcMultiMouseHunterControl:CheckBpTaskRedPoint(taskType)
    return self._Model:CheckBpTaskRedPoint(taskType)
end

function XDlcMultiMouseHunterControl:CheckBpRewardRedPoint()
    return self._Model:CheckBpRewardRedPoint()
end
--endregion

--region 技能
function XDlcMultiMouseHunterControl:RequestDlcMultiplayerSelectSkill(catSkillId, mouseSkillId, callback)
    local hasData, skillData = self:TryGetSkillData()
    if hasData and skillData.SelectCatSkillId == catSkillId and skillData.SelectMouseSkillId == mouseSkillId then
        if callback then
            callback()
        end
        return
    end

    XMVCA.XDlcMultiMouseHunter:RequestDlcMultiplayerSelectSkill(catSkillId, mouseSkillId, callback)
end

function XDlcMultiMouseHunterControl:TryGetSkillData()
    return self._Model:TryGetSkillData()
end

function XDlcMultiMouseHunterControl:CheckSkillUnlock(skillId)
    local hasData, skillData = self:TryGetSkillData()
    return hasData and skillData.UnlockSkills[skillId] == true or false
end

function XDlcMultiMouseHunterControl:GetDlcMultiplayerSkillConfigById(id)
    return self._Model:GetDlcMultiplayerSkillConfigById(id)
end

function XDlcMultiMouseHunterControl:GetDlcMultiplayerSkillGroupConfigById(id)
    return self._Model:GetDlcMultiplayerSkillGroupConfigById(id)
end

function XDlcMultiMouseHunterControl:GetDlcMultiplayerActivityConfig()
    return self._Model:GetDlcMultiplayerActivityConfig()
end

function XDlcMultiMouseHunterControl:CheckNewSkillRedPoint(skillId)
    return self._Model:CheckHasNewSkill(skillId)
end

function XDlcMultiMouseHunterControl:CheckNewSkillCampRedPoint(camp)
    local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMouseHunterCamp
    local activityConfig = self:GetDlcMultiplayerActivityConfig()
    if not activityConfig then 
        return false
    end

    local skillGroupConfig = nil
    if camp == CampEnum.Cat then
        skillGroupConfig = self:GetDlcMultiplayerSkillGroupConfigById(activityConfig.CatSkillGroup)
    elseif camp == CampEnum.Mouse then
        skillGroupConfig = self:GetDlcMultiplayerSkillGroupConfigById(activityConfig.MouseSkillGroup)
    end

    if skillGroupConfig then
        for _, skillId in ipairs(skillGroupConfig.SkillIdList) do
            if self:CheckNewSkillRedPoint(skillId) then
                return true
            end
        end
    end

    return false
end

function XDlcMultiMouseHunterControl:RemoveNewSkill(skillId)
    return self._Model:RemoveNewSkill(skillId)
end
--endregion

function XDlcMultiMouseHunterControl:DlcInitFight()
    XMVCA.XDlcMultiMouseHunter:DlcInitFight()
end

return XDlcMultiMouseHunterControl
