local XDlcMultiplayerActivityAgency = require("XModule/XDlcMultiplayer/XDlcMultiplayerActivity/XDlcMultiplayerActivityAgency")
local XDlcMultiMouseHunterRoom = require("XModule/XDlcMultiMouseHunter/XEntity/XDlcMultiMouseHunterRoom")
local XDlcMultiMouseHunterWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcMultiMouseHunterWorldFight")
local XDlcMultiMouseHunterPlayerData = require("XModule/XDlcMultiMouseHunter/XData/XDlcMultiMouseHunterPlayerData")

---@class XDlcMultiMouseHunterAgency : XDlcMultiplayerActivityAgency
---@field private _Model XDlcMultiMouseHunterModel
local XDlcMultiMouseHunterAgency = XClass(XDlcMultiplayerActivityAgency, "XDlcMultiMouseHunterAgency")

local Protocols = {
    DlcMultiplayerWearTitleRequest = "DlcMultiplayerWearTitleRequest",
    DlcMultiplayerDiscussionVoteRequest = "DlcMultiplayerDiscussionVoteRequest",
    DlcMultiplayerGetDiscussionVoteRewardRequest = "DlcMultiplayerGetDiscussionVoteRewardRequest",
    DlcMultiplayerGetBpRewardRequest = "DlcMultiplayerGetBpRewardRequest",
    DlcMultiplayerSelectSkillRequest = "DlcMultiplayerSelectSkillRequest"
}

function XDlcMultiMouseHunterAgency:OnInit()
    -- 初始化一些变量
    self:InitEnum()
    self:DlcMultiplayerRegisterAllPrivateConfig()
    self:DlcRegisterActivity()
end

function XDlcMultiMouseHunterAgency:InitEnum()
    self.DlcMultiplayerDiscussionCamp = {
        None = 0, --未选择
        Camp1 = 1, --选择阵营1
        Camp2 = 2 --选择阵营2
    }
    self.DlcMultiplayerDiscussionStatus = {
        None = 0, --话题未开始
        Vote = 1, --话题投票阶段
        Show = 2, --话题展示阶段
    }
    self.DlcMouseHunterTaskType = {
        Daily = 0, --每日任务
        Challenge = 1 --挑战任务
    }
    self.DlcMouseHunterCamp = {
        Cat = 1,  --猫技能
        Mouse = 2, --鼠技能
    }
end

function XDlcMultiMouseHunterAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
    XRpc.NotifyDlcMultiplayerData = Handler(self, self.OnNotifyDlcMultiplayerData)
    XRpc.DlcPlayerChangeTitleNotify = Handler(self, self.OnDlcPlayerChangeTitleNotify)
    XRpc.NotifyDlcMultiplayerUpdateCurrencyLimit = Handler(self, self.OnNotifyDlcMultiplayerUpdateCurrencyLimit)
    XRpc.NotifyDlcMultiplayerDiscussionStatusUpdate = Handler(self, self.OnNotifyDlcMultiplayerDiscussionStatusUpdate)
    XRpc.NotifyDlcMultiplayerSkillUpdate = handler(self, self.OnNotifyDlcMultiplayerSkillUpdate)
    XRpc.NotifyDlcMultiplayerDiscussionUpdate = handler(self, self.OnNotifyDlcMultiplayerDiscussionUpdate)
    XRpc.NotifyDlcMultiplayerBpLevelUpdate = handler(self, self.OnNotifyDlcMultiplayerBpLevelUpdate)
end

function XDlcMultiMouseHunterAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

function XDlcMultiMouseHunterAgency:OpenMainUi()
    local worldId, levelId = self:GetCurrentWorldIdAndLevelId()

    if worldId and levelId then
        XMVCA.XDlcRoom:CreateRoom(worldId, levelId, 1, true)
    end
end

-- region Notify

function XDlcMultiMouseHunterAgency:OnNotifyDlcMultiplayerData(data)
    local oldChapterId = self._Model:GetCurrentChapterId()

    self._Model:SetActivityId(data.ActivityId)
    self:_SetChapterInfo(data.ChapterInfo)
    self._Model:SetCurrentWearTitleId(data.Title)
    self._Model:SetCurrencyCount(data.CurrencyCount)
    self._Model:SetCurrencyLimit(data.CurrencyLimit)
    self._Model:SetUnlockTitleInfos(data.UnlockTitleList)
    self._Model:SetTitleProgress(data.TitleProgress)
    self._Model:SetDiscussionInfo(data.Discussion)
    self._Model:SetBpLevel(data.BpLevel)
    self._Model:SetBpRewardIds(data.BpRewardIds)
    self._Model:SetSelectSkillData(data.SelectCatSkillId, data.SelectMouseSkillId)
    self._Model:SetFinishStageCount(data.FinishStageCount)

    if oldChapterId ~= self._Model:GetCurrentChapterId() then
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_UPDATE)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_BP_REWARDS)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_SKILL_DATA)
end

function XDlcMultiMouseHunterAgency:OnDlcPlayerChangeTitleNotify(response)
    if XMVCA.XDlcRoom:IsInRoom() then
        local roomData = XMVCA.XDlcRoom:GetRoomData()

        if roomData and not roomData:IsClear() then
            local playerData = roomData:GetPlayerDataById(response.PlayerId)

            if playerData and not playerData:IsEmpty() then
                playerData:SetCustomData({
                    ["_TitleId"] = response.TitleId,
                })

                XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_PLAYER_CHANGE_TITLE, response.PlayerId,
                    response.Title)
            end
        end
    end
end

function XDlcMultiMouseHunterAgency:OnNotifyDlcMultiplayerUpdateCurrencyLimit(data)
    self._Model:SetActivityId(data.ActivityId)
    self._Model:SetCurrencyLimit(data.CurrencyLimit)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_CURRENCY_UPDATE, data.CurrencyLimit)
end

function XDlcMultiMouseHunterAgency:OnNotifyDlcMultiplayerDiscussionStatusUpdate(data)
    self._Model:SetDiscussionData(data)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA)
end

function XDlcMultiMouseHunterAgency:OnNotifyDlcMultiplayerSkillUpdate(data)
    self._Model:SetSkillData(data)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_SKILL_DATA)
end

function XDlcMultiMouseHunterAgency:OnNotifyDlcMultiplayerDiscussionUpdate(data)
    self._Model:SetDiscussionInfo(data)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA)
end

function XDlcMultiMouseHunterAgency:OnNotifyDlcMultiplayerBpLevelUpdate(data)
    self._Model:SetBpLevel(data.BpLevel)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_BP_REWARDS)
end

-- endregion

-- region Request

function XDlcMultiMouseHunterAgency:RequestWearTitle(titleId, callback)
    XNetwork.Call(Protocols.DlcMultiplayerWearTitleRequest, {
        TitleId = titleId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetCurrentWearTitleId(titleId)
        if callback then
            callback()
        end
    end)
end

function XDlcMultiMouseHunterAgency:RequestPlayerDiscussionVote(camp)
    XNetwork.Call(Protocols.DlcMultiplayerDiscussionVoteRequest, {
        Camp = camp,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:SetDiscussionInfo(res.DiscussionInfo)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA)
    end)
end

function XDlcMultiMouseHunterAgency:RequestGetDiscussionVoteReward(callback)
    XNetwork.Call(Protocols.DlcMultiplayerGetDiscussionVoteRewardRequest, {
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:SetDiscussionInfo(res.DiscussionInfo)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA)
        if callback then
            callback()
        end
    end)
end

function XDlcMultiMouseHunterAgency:RequestDlcMultiplayerGetBpReward(callback)
    XNetwork.Call(Protocols.DlcMultiplayerGetBpRewardRequest, {
        Lv = 0
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:SetBpRewardIds(res.BpRewardSet)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_BP_REWARDS)
        if callback then
            callback(res.RewardList)
        end
    end)
end

function XDlcMultiMouseHunterAgency:RequestDlcMultiplayerSelectSkill(catSkillId, mouseSkillId, callback)
    XNetwork.Call(Protocols.DlcMultiplayerSelectSkillRequest, {
        CatSkillId = catSkillId,
        MouseSkillId = mouseSkillId
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:SetSelectSkillData(catSkillId, mouseSkillId)
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_SKILL_DATA)
        if callback then
            callback()
        end
    end)
end
-- endregion

-- region Dlc

function XDlcMultiMouseHunterAgency:DlcGetRoomProxy()
    return XDlcMultiMouseHunterRoom.New()
end

function XDlcMultiMouseHunterAgency:DlcGetFightEvent()
    return XDlcMultiMouseHunterWorldFight.New()
end

function XDlcMultiMouseHunterAgency:DlcGetPlayerCustomData()
    return XDlcMultiMouseHunterPlayerData.New()
end

function XDlcMultiMouseHunterAgency:DlcGetWorldType()
    return XEnumConst.DlcWorld.WorldType.MouseHunter
end

function XDlcMultiMouseHunterAgency:DlcCheckActivityInTime()
    if not self:ExCheckInTime() then
        return false
    end

    local activityId = self._Model:GetActivityId()

    if XTool.IsNumberValid(activityId) then
        local timeId = self._Model:GetDlcMultiplayerActivityTimeIdById(activityId)
        return XFunctionManager.CheckInTimeByTimeId(timeId, false)
    end

    return false
end

function XDlcMultiMouseHunterAgency:DlcReconnect()
    local title = XUiHelper.GetText("TipTitle")
    local message = XUiHelper.GetText("OnlineInstanceReconnect")

    XUiManager.DialogTip(title, message, XUiManager.DialogType.Normal, function()
        XMVCA.XDlcRoom:CancelReconnectToWorld()
    end, function()
        self:DlcInitFight() 
        XMVCA.XDlcRoom:ReconnectToWorld()
    end)
end

function XDlcMultiMouseHunterAgency:DlcGetAttribIdByNpcId(npcId)
    local attribId = self:_GetAttribIdByNpcId(npcId)

    if XTool.IsNumberValid(attribId) then
        return attribId
    end

    return self.Super.DlcGetAttribIdByNpcId(self, npcId)
end

-- endregion

-- region 副本入口相关

function XDlcMultiMouseHunterAgency:ExGetConfig()
    if not XTool.IsTableEmpty(self.ExConfig) then
        return self.ExConfig
    end
    self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)

    return self.ExConfig
end

function XDlcMultiMouseHunterAgency:ExGetProgressTip()
    return ""
end

function XDlcMultiMouseHunterAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.DlcMultiMouseHunter
end

-- endregion

function XDlcMultiMouseHunterAgency:GetTitleIcon(titleId)
    return self._Model:GetDlcMultiplayerTitleIconById(titleId)
end

function XDlcMultiMouseHunterAgency:GetTitleBackground(titleId)
    return self._Model:GetDlcMultiplayerTitleBackgroundById(titleId)
end

function XDlcMultiMouseHunterAgency:GetTitleContent(titleId)
    return self._Model:GetDlcMultiplayerTitleTitleContentById(titleId)
end

function XDlcMultiMouseHunterAgency:GetIsFirstUnlockTitle(titleId)
    local unlockMap = self._Model:GetLocalUnlockTitleIdMap()

    return not unlockMap[titleId]
end

function XDlcMultiMouseHunterAgency:SetIsFirstUnlockTitle(titleId)
    self._Model:SetLocalUnlockTitleId(titleId)
end

function XDlcMultiMouseHunterAgency:GetCurrentWorldIdAndLevelId(index)
    local chapterInfoList = self._Model:GetChapterInfoList()

    index = index or 1
    if not XTool.IsTableEmpty(chapterInfoList) then
        local chapterInfo = chapterInfoList[index]

        if chapterInfo then
            return chapterInfo.WorldId, chapterInfo.LevelId
        end
    else
        local chapterId = self._Model:GetCurrentChapterId()

        if XTool.IsNumberValid(chapterId) then
            local worldIds = self._Model:GetDlcMultiplayerChapterWorldIdsById(chapterId)
            local levelIds = self._Model:GetDlcMultiplayerChapterLevelIdsById(chapterId)

            return worldIds[index], levelIds[index]
        end
    end

    return 0, 0
end

---@param result XDlcMultiMouseHunterResult
function XDlcMultiMouseHunterAgency:OpenSettmentUi(result)
    local worldId = result:GetWorldId()
    local levelId = result:GetLevelId()
    local uiName = self._Model:GetDlcMultiplayerWorldSettlementUiNameById(tostring(worldId) .. tostring(levelId))

    XLuaUiManager.Open(uiName, result)
end

function XDlcMultiMouseHunterAgency:CheckTitleRedPoint()
    local unlockMap = self._Model:GetLocalUnlockTitleIdMap()
    local titleInfoList = self._Model:GetUnlockTitleInfos()

    if not XTool.IsTableEmpty(titleInfoList) then
        for _, titleInfo in pairs(titleInfoList) do
            if not unlockMap[titleInfo.TitleId] then
                return true
            end
        end
    end

    return false
end

function XDlcMultiMouseHunterAgency:CheckShopRedPoint()
    if not self:DlcCheckActivityInTime() then
        return false
    end

    if not self._Model:GetIsShowShopRedPoint() then
        return false
    end

    local activityId = self._Model:GetActivityId()

    if not XTool.IsNumberValid(activityId) then
        return false
    end

    local shopIds = self._Model:GetDlcMultiplayerActivityShopIdListById(activityId) or {}
    local itemIds = self._Model:GetDlcMultiplayerConfigValuesByKey("CoinItemIds") or {}
    local itemMap = {}

    for _, id in ipairs(itemIds) do
        id = tonumber(id)
        itemMap[id] = XDataCenter.ItemManager.GetCount(id)
    end
    for _, shopId in pairs(shopIds) do
        local goodsList = XShopManager.GetShopGoodsList(shopId, true, true)

        if not XTool.IsTableEmpty(goodsList) then
            for _, goods in ipairs(goodsList) do
                -- 售罄
                if not (goods.BuyTimesLimit == goods.TotalBuyTimes and goods.BuyTimesLimit > 0) then
                    -- 货币不足
                    for _, consume in ipairs(goods.ConsumeList) do
                        local count = itemMap[consume.Id] or 0
                        
                        if count >= consume.Count then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    return false
end

function XDlcMultiMouseHunterAgency:CheckShopRedPointWithSyncShopInfo()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, false, true) then
        return false
    end
    if not self:DlcCheckActivityInTime() then
        return false
    end

    if self._Model:CheckNeedSyncShopInfo() then
        local activityId = self._Model:GetActivityId()

        if not XTool.IsNumberValid(activityId) then
            return false
        end

        local shopIds = self._Model:GetDlcMultiplayerActivityShopIdListById(activityId)

        if XTool.IsTableEmpty(shopIds) then
            return false
        end

        local shopCount = #shopIds
        local requestCount = 0

        self._Model:RefreshSyncShopInfo()
        for _, shopId in pairs(shopIds) do
            XShopManager.GetShopInfo(shopId, function()
                requestCount = requestCount + 1
                if requestCount == shopCount then
                    self._Model:RefreshSyncShopInfo()
                    CS.XGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_CHAPTER_REFRESH_RED)
                end
            end, true)
        end
    else
        return self:CheckShopRedPoint()
    end
end

function XDlcMultiMouseHunterAgency:_GetAttribIdByNpcId(npcId)
    local activityId = self._Model:GetActivityId()
    local characterPoolId = self._Model:GetDlcMultiplayerActivityCharacterPoolIdById(activityId)
    local characterIds = self._Model:GetDlcMultiplayerCharacterPoolCharacterIdsById(characterPoolId)

    if not XTool.IsTableEmpty(characterIds) then
        for _, characterId in pairs(characterIds) do
            local config = self._Model:GetDlcMultiplayerCharacterConfigById(characterId)

            if config.NpcId == npcId then
                return config.AttribId
            end
        end
    end

    return 0
end

function XDlcMultiMouseHunterAgency:_SetChapterInfo(chapterInfo)
    if chapterInfo then
        local worldIds = chapterInfo.WorldIds
        local levelIds = chapterInfo.LevelIds
        local chapterInfoList = {}

        self._Model:SetCurrentChapterId(chapterInfo.ChapterId)
        for i, worldId in pairs(worldIds) do
            chapterInfoList[i] = {
                WorldId = worldId,
                LevelId = levelIds[i],
            }
        end
        self._Model:SetChapterInfoList(chapterInfoList)
    end
end

function XDlcMultiMouseHunterAgency:GetDlcMultiplayerDiscussionConfigById(id)
    return self._Model:GetDlcMultiplayerDiscussionConfigById(id)
end

function XDlcMultiMouseHunterAgency:CheckDiscussionRedPoint()
    if not self._Model:GetActivityId() then
        return false
    end

    return self._Model:CheckDiscussionRedPoint()
end

function XDlcMultiMouseHunterAgency:CheckBpRedPoint()
    if not self._Model:GetActivityId() then
        return false
    end

    return self._Model:CheckBpRedPoint()
end

function XDlcMultiMouseHunterAgency:GetFinishStageCount()
    return self._Model:GetFinishStageCount()
end

return XDlcMultiMouseHunterAgency
