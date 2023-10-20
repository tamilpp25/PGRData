XFubenUnionKillManagerCreator = function()

    local XFubenUnionKillManager = {}

    local UnionKillRpc = {
        GetBoxReward = "GetBoxRewardRequest", -- 领取宝箱
        GetUnionKillRankData = "GetUnionKillRankDataRequest", -- 获取歼敌排行榜
        GetUnionPraiseRankData = "GetUnionPraiseRankDataRequest", -- 获取点赞排行榜
        PraisePlayer = "UnionKillPraiseRequest", -- 点赞请求
        LeaveFightRoom = "UnionKillLeaveFightRoomRequest", -- 离开战斗房间
    }

    --------------------------------------------------------排行数据
    local UnionRankData = XClass(nil, "UnionRankData")

    function UnionRankData:Ctor(rankDatas)
        self.LastModify = 0
        if not rankDatas then return end
        self:UpdateUnionRankData(rankDatas)
    end

    function UnionRankData:UpdateUnionRankData(rankDatas)
        self.Score = rankDatas.Score or 0
        self.Rank = rankDatas.Rank or 0
        self.TotalRank = rankDatas.TotalRank or 0
        self.HistoryRank = rankDatas.HistoryRank or 0
        self.PlayerList = rankDatas.UnionKillRowRankInfos or rankDatas.UnionPraiseRowRankInfos or {}
        self:SetModifyTime()
    end

    function UnionRankData:SetModifyTime()
        self.LastModify = XTime.GetServerNowTimestamp()
    end
    --------------------------------------------------------提示数据
    local UnionTipMessage = XClass(nil, "UnionTipMessage")

    function UnionTipMessage:Ctor(msg, chatData)
        self.IsChatMsg = false
        if msg then
            self.TipsType = msg.TipsType
            self.PlayerId = msg.PlayerId
            self.CharacterId = msg.CharacterId
            self.ShareCharacterInfos = msg.ShareCharacterInfos
        end
        if chatData then
            self.PlayerId = chatData.SenderId
            self.ChatData = chatData
            self.IsChatMsg = true
        end
    end

    function UnionTipMessage:IsChatTip()
        return self.IsChatMsg
    end

    local UnionKillData = {}
    local UnionKillFightRoomData = nil
    local PraiseRankDatas = UnionRankData.New()
    local KillRankDatas = {}
    local SectionKillBossCount = {}
    local TipQueue = {}
    local CacheTeam = {}
    local Max_Team_Count = 3
    -- 判断结算用
    local EventStageIds = {}
    local BossStageIds = {}
    local TrialStageIds = {}

    function XFubenUnionKillManager.InitStageInfo()
        -- 初始化全部
        if UnionKillData and UnionKillData.Id and UnionKillData.Id > 0 then
            EventStageIds = {}
            BossStageIds = {}
            TrialStageIds = {}
            local unionKillTemplate = XFubenUnionKillConfigs.GetUnionActivityById(UnionKillData.Id)
            if unionKillTemplate then
                for i = 1, #unionKillTemplate.SectionId do
                    local sectionId = unionKillTemplate.SectionId[i]
                    local sectionTemplate = XFubenUnionKillConfigs.GetUnionSectionById(sectionId)
                    if sectionTemplate then
                        XFubenUnionKillManager.SetStageInfoType(sectionTemplate.BossStage)
                        BossStageIds[sectionTemplate.BossStage] = true

                        XFubenUnionKillManager.SetStageInfoType(sectionTemplate.TrialStage)
                        TrialStageIds[sectionTemplate.TrialStage] = true

                        for _, stageId in pairs(sectionTemplate.EventStageId) do
                            XFubenUnionKillManager.SetStageInfoType(stageId)
                            EventStageIds[stageId] = true
                        end
                    end
                end
            end
        end
    end

    function XFubenUnionKillManager.SetStageInfoType(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo then
            stageInfo.Type = XDataCenter.FubenManager.StageType.UnionKill
        end
    end

    function XFubenUnionKillManager.ShowReward(winData)
        if not winData then return end
        -- 有共享角色、先弹出点赞界面
        local unionKillResult = winData.SettleData.UnionKillResult
        if unionKillResult then
            local shareResults = unionKillResult.ShareResultInfos
            if shareResults and #shareResults > 0 then
                XLuaUiManager.Open("UiUnionKillGrade", winData)
                return
            end
        end

        local stageId = winData.SettleData.StageId
        -- 没有贡献角色、走通用
        -- 事件关卡
        if XFubenUnionKillManager.IsEventStage(stageId) then
            XLuaUiManager.Open("UiSettleWin", winData)
            return
        end
        -- boss、试炼关卡
        if XFubenUnionKillManager.IsBossStage(stageId) or XFubenUnionKillManager.IsTrialStage(stageId) then
            if winData.SettleData.UnionKillResult then
                XLuaUiManager.Open("UiArenaFightResult", winData)
                return
            end
        end

        -- by default
        XLuaUiManager.Open("UiSettleWin", winData)
    end

    -- 离开战斗房间
    function XFubenUnionKillManager.LeaveFightRoom(func)
        XNetwork.Call(UnionKillRpc.LeaveFightRoom, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if func then
                func()
            end
        end)
    end

    -- 点赞请求
    function XFubenUnionKillManager.PraisePlayerCharacters(playerId, characterId, func)
        XNetwork.Call(UnionKillRpc.PraisePlayer, {
            PlayerId = playerId, CharacterId = characterId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if func then
                func()
            end
        end)
    end

    -- 获取点赞排行榜
    function XFubenUnionKillManager.GetPraiseRankData(func)
        XNetwork.Call(UnionKillRpc.GetUnionPraiseRankData, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            PraiseRankDatas:UpdateUnionRankData(res)

            if func then
                func()
            end
        end)
    end

    -- 获取歼敌排行榜
    function XFubenUnionKillManager.GetUnionKillRankData(levelId, func)
        XNetwork.Call(UnionKillRpc.GetUnionKillRankData, { LevelId = levelId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if not KillRankDatas[levelId] then
                KillRankDatas[levelId] = UnionRankData.New(res)
            else
                KillRankDatas[levelId]:UpdateUnionRankData(res)
            end

            if func then
                func()
            end
        end)
    end

    -- 领取宝箱
    function XFubenUnionKillManager.GetUnionBoxReward(id, func)
        XNetwork.Call(UnionKillRpc.GetBoxReward, { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XUiManager.OpenUiObtain(res.RewardGoodsList or {})
            if func then
                func()
            end
        end)
    end

    -- 活动登录信息通知
    function XFubenUnionKillManager.SyncUnionKillLoginData(notifyData)
        if not notifyData then return end
        UnionKillData.Id = notifyData.Id
        UnionKillData.CurSectionId = notifyData.CurSectionId
        UnionKillData.WeatherId = notifyData.WeatherId
        UnionKillData.SectionInfos = {}
        for _, sectionInfo in pairs(notifyData.SectionInfos) do
            UnionKillData.SectionInfos[sectionInfo.Id] = sectionInfo
        end

        local activityTemplate = XFubenUnionKillConfigs.GetUnionActivityById(UnionKillData.Id)
        if activityTemplate and UnionKillData.CurSectionId == 0 then
            local length = #activityTemplate.SectionId
            UnionKillData.CurSectionId = activityTemplate.SectionId[length]
        end

        XFubenUnionKillManager.InitStageInfo()
    end

    -- 活动信息变化:切章节界面
    function XFubenUnionKillManager.SyncUnionKillActivityData(notifyData)
        if not notifyData then return end
        UnionKillData.Id = notifyData.Id
        UnionKillData.CurSectionId = notifyData.CurSectionId
        UnionKillData.WeatherId = notifyData.WeatherId

        local activityTemplate = XFubenUnionKillConfigs.GetUnionActivityById(UnionKillData.Id)
        if activityTemplate and UnionKillData.CurSectionId == 0 then
            local length = #activityTemplate.SectionId
            UnionKillData.CurSectionId = activityTemplate.SectionId[length]
        end

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILL_ACTIVITYINFO)
    end

    -- 通知战斗房间数据:进入关卡界面
    function XFubenUnionKillManager.SyncUnionKillFightRoomData(notifyData)
        if not notifyData then return end
        UnionKillFightRoomData = {}
        UnionKillFightRoomData.EndTime = notifyData.EndTime
        UnionKillFightRoomData.BossHpLeft = notifyData.BossHpLeft
        UnionKillFightRoomData.UnionKillPlayerInfos = {}
        for index, playerInfo in pairs(notifyData.UnionKillPlayerInfos or {}) do
            playerInfo.Position = index
            UnionKillFightRoomData.UnionKillPlayerInfos[playerInfo.Id] = playerInfo
        end

        UnionKillFightRoomData.UnionKillStageInfos = {}
        for _, stageInfo in pairs(notifyData.UnionKillStageInfos or {}) do
            UnionKillFightRoomData.UnionKillStageInfos[stageInfo.Id] = stageInfo
        end
        UnionKillFightRoomData.ChallengeStage = {}

        XDataCenter.FubenUnionKillRoomManager.SetPlayersFightState()

        -- 新关卡，重置队伍
        CacheTeam = {}
        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILL_ROOMDATANOTIFY)
    end

    -- 通知boss血量
    function XFubenUnionKillManager.SyncUnionKillBossHp(notifyData)
        if not notifyData then return end
        if not UnionKillFightRoomData then return end

        if notifyData.BossHpLeft <= 0 then
            UnionKillFightRoomData.FirstKillBoss = true
        end

        UnionKillFightRoomData.BossHpLeft = notifyData.BossHpLeft

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILL_BOSSHPCHANGE)
    end

    -- 通知玩家状态
    function XFubenUnionKillManager.SyncUnionKillPlayerInfo(notifyData)
        if not notifyData then return end
        if not UnionKillFightRoomData then return end

        local changePlayerInfo = notifyData.PlayerInfo
        local oldPlayerInfo = UnionKillFightRoomData.UnionKillPlayerInfos[changePlayerInfo.Id]
        local position = oldPlayerInfo.Position
        changePlayerInfo.Position = position
        UnionKillFightRoomData.UnionKillPlayerInfos[changePlayerInfo.Id] = changePlayerInfo

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILL_PLAYERINFOCHANGE)
    end

    -- 通知关卡信息
    function XFubenUnionKillManager.SyncUnionKillStageInfo(notifyData)
        if not notifyData then return end
        if not UnionKillFightRoomData then return end

        local changeStageInfo = notifyData.StageInfo
        UnionKillFightRoomData.UnionKillStageInfos[changeStageInfo.Id] = changeStageInfo

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILL_STAGEINFOCHANGE)
    end

    -- 通知击杀boss
    function XFubenUnionKillManager.SyncUnionKillBossCount(notifyData)
        if not notifyData then return end
        SectionKillBossCount[notifyData.Section] = notifyData.KillCount

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILL_BOSSCOUNTCHANGE)
    end

    -- tips通知
    function XFubenUnionKillManager.SyncUnionKillTipsMessage(notifyData)
        if not notifyData then return end

        if not TipQueue["All"] then
            TipQueue["All"] = {}
        end

        if notifyData.TipsType == XFubenUnionKillConfigs.TipsMessageType.Praise then
            table.insert(TipQueue["All"], UnionTipMessage.New(notifyData, nil))
        elseif notifyData.TipsType == XFubenUnionKillConfigs.TipsMessageType.FightBrrow then
            local playerId = notifyData.PlayerId

            if notifyData.ShareCharacterInfos then
                for i = 1, #notifyData.ShareCharacterInfos do
                    local shareInfo = notifyData.ShareCharacterInfos[i]
                    local args = {}
                    args.TipsType = XFubenUnionKillConfigs.TipsMessageType.FightBrrow
                    args.PlayerId = notifyData.PlayerId
                    args.CharacterId = notifyData.CharacterId--这种类型用不到
                    args.ShareCharacterInfos = {}
                    args.ShareCharacterInfos.CharacterId = shareInfo.CharacterId
                    args.ShareCharacterInfos.PlayerId = shareInfo.PlayerId

                    XFubenUnionKillManager.Add2TipQueue(false, playerId, args)
                end
            end

            local stageId = notifyData.StageId
            XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILL_FIGHTSTATUS, playerId, stageId)

        elseif notifyData.TipsType == XFubenUnionKillConfigs.TipsMessageType.ResultBorrow then
            table.insert(TipQueue["All"], UnionTipMessage.New(notifyData, nil))
        elseif notifyData.TipsType == XFubenUnionKillConfigs.TipsMessageType.LeaveStage then
            local playerId = notifyData.PlayerId
            XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILL_FIGHTSTATUS, playerId)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILL_TIPSMESSAGE)
    end


    -- 是否是事件关卡
    function XFubenUnionKillManager.IsEventStage(stageId)
        return EventStageIds[stageId]
    end

    -- 是否是boss关卡
    function XFubenUnionKillManager.IsBossStage(stageId)
        return BossStageIds[stageId]
    end

    -- 是否是试炼关
    function XFubenUnionKillManager.IsTrialStage(stageId)
        return TrialStageIds[stageId]
    end

    -- 判断我是否通关某关卡
    function XFubenUnionKillManager.IsMeFinish(stageInfo)
        if not stageInfo then return false end
        for _, playerId in pairs(stageInfo.PlayerIds or {}) do
            if playerId == XPlayer.Id then
                return true
            end
        end
        return false
    end

    -- 判读其他玩家是否通关某关卡
    function XFubenUnionKillManager.IsOthersFinish(stageInfo)
        if not stageInfo then return false end
        for _, playerId in pairs(stageInfo.PlayerIds or {}) do
            if playerId ~= XPlayer.Id then
                return true
            end
        end
        return false
    end


    -- 通知玩家离开房间
    function XFubenUnionKillManager.SyncUnionKillLeaveRoom(notifyData)
        if not notifyData then return end

        -- 离开队伍
        if UnionKillFightRoomData then
            UnionKillFightRoomData.LeaveReson = notifyData.Reason
        end

        XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILL_LEAVEROOM, notifyData.Reason)
    end

    -- 提示玩家离开的理由
    function XFubenUnionKillManager.TipsPlayerleaveReson(leaveReason)
        if XFubenUnionKillConfigs.LeaveReason.LeaveTeam == leaveReason then
            XUiManager.TipMsg(CS.XTextManager.GetText("UnionLeaveMiddle"))
        elseif XFubenUnionKillConfigs.LeaveReason.LeaveFight == leaveReason then
            XUiManager.TipMsg(CS.XTextManager.GetText("UnionLeaveMiddle"))
        elseif XFubenUnionKillConfigs.LeaveReason.TimeOver == leaveReason then
            XUiManager.TipMsg(CS.XTextManager.GetText("UnionLeaveTimeOver"))
        elseif XFubenUnionKillConfigs.LeaveReason.KickOut == leaveReason then
            XUiManager.TipMsg(CS.XTextManager.GetText("UnionLeaveKickOut"))
        elseif XFubenUnionKillConfigs.LeaveReason.Offline == leaveReason then
            XUiManager.TipMsg(CS.XTextManager.GetText("UnionLeaveOffline"))
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("UnionLeaveMiddle"))
        end

    end

    -- 同步章节信息
    function XFubenUnionKillManager.SyncUnionKillSectionData(notifyData)
        if not notifyData then return end

        local id = notifyData.SectionInfo.Id
        UnionKillData.SectionInfos[id] = notifyData.SectionInfo

    end

    -- 获取阵容缓存
    function XFubenUnionKillManager.GetCacheTeam()
        return CacheTeam
    end

    -- 更新阵容缓存,这里保存的东西结算的时候可用,玩家数据被清空也可以用
    function XFubenUnionKillManager.UpdateCacheTeam(curTeam)
        if not curTeam then return end
        for i = 1, Max_Team_Count do
            local curItem = curTeam[i]
            if curItem then
                if not CacheTeam[i] then
                    CacheTeam[i] = {}
                end
                CacheTeam[i].CharacterId = curItem.CharacterId
                CacheTeam[i].IsShare = curItem.IsShare
                CacheTeam[i].PlayerId = curItem.PlayerId
                CacheTeam[i].IsTeamLeader = curItem.IsTeamLeader
            else
                CacheTeam[i] = nil
            end
        end
    end

    function XFubenUnionKillManager.GetAllTip()
        return TipQueue
    end

    -- 获取特殊tipmessage
    function XFubenUnionKillManager.GetTipQueueAll()
        if not TipQueue["All"] then return nil end
        if #TipQueue["All"] >= 1 then
            local tip_msg = table.remove(TipQueue["All"], 1)
            return tip_msg
        end
        return nil
    end

    -- 根据玩家id获取提示
    function XFubenUnionKillManager.GetTipQueueById(playerId)
        if not TipQueue[playerId] then return nil end
        if #TipQueue[playerId] >= 1 then
            local tip_msg = table.remove(TipQueue[playerId], 1)
            return tip_msg
        end
        return nil
    end

    -- 更新tipmessage
    function XFubenUnionKillManager.Add2TipQueue(isMsgChat, playerId, tipData)
        if not TipQueue[playerId] then
            TipQueue[playerId] = {}
        end
        if isMsgChat then
            table.insert(TipQueue[playerId], UnionTipMessage.New(nil, tipData))
        else
            table.insert(TipQueue[playerId], UnionTipMessage.New(tipData, nil))
        end
    end

    -- 获取房间数据:为空则没有房间
    function XFubenUnionKillManager.GetCurRoomData()
        return UnionKillFightRoomData
    end

    -- 当前房间内打过的关卡
    function XFubenUnionKillManager.UpdateChallengeStageById(stageId)
        if UnionKillFightRoomData and UnionKillFightRoomData.ChallengeStage then
            UnionKillFightRoomData.ChallengeStage[stageId] = true
        end
    end

    -- 获取boss击杀数
    function XFubenUnionKillManager.GetBossKillCount(id)
        return SectionKillBossCount[id] or 0
    end

    -- 试炼关是否可以使用共享角色
    function XFubenUnionKillManager.GetTrialUseShare()
        local unionKillInfo = XFubenUnionKillManager.GetUnionKillInfo()
        if unionKillInfo == nil then return true end

        if unionKillInfo.Id == nil or unionKillInfo.Id == 0 then return true end

        local curSectionId = unionKillInfo.CurSectionId
        local curSectionTemplate = XFubenUnionKillConfigs.GetUnionSectionById(curSectionId)
        if not curSectionTemplate then return true end

        return curSectionTemplate.TrialUseShare == 1
    end

    -- 是否为试炼关
    function XFubenUnionKillManager.CurIsTrialBoss()
        local roomFightData = XFubenUnionKillManager.GetCurRoomData()
        if not roomFightData then return false end
        return roomFightData.BossHpLeft <= 0
    end

    -- 获取章节信息
    function XFubenUnionKillManager.GetSectionInfoById(id)

        if not id then return nil end
        return UnionKillData.SectionInfos[id]
    end

    -- 获取合众歼敌信息
    function XFubenUnionKillManager.GetUnionKillInfo()
        return UnionKillData
    end

    -- 获取点赞排名数据
    function XFubenUnionKillManager.GetPraiseRankInfos()
        return PraiseRankDatas
    end

    -- 获取歼敌排名数据
    function XFubenUnionKillManager.GetKillRankInfosByLevel(level)
        return KillRankDatas[level]
    end

    -- 获取活动入口
    function XFubenUnionKillManager.GetUnionKillActivity()
        local sections = {}
        local activityId = UnionKillData and UnionKillData.Id

        if activityId and activityId > 0 and XFubenUnionKillConfigs.UnionKillInActivity(activityId) then
            local activityConfig = XFubenUnionKillConfigs.GetUnionActivityConfigById(activityId)
            local section = {
                Id = activityId,
                Type = XDataCenter.FubenManager.ChapterType.UnionKill,
                BannerBg = activityConfig.Icon
            }

            table.insert(sections, section)
        end

        return sections
    end

    local function GetActivityId()
        local activityId = XFubenUnionKillConfigs.GetUnionDefaultActivityId()

        local unionInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()
        if unionInfo and unionInfo.Id and unionInfo.Id > 0 then
            activityId = unionInfo.Id
        end

        return activityId
    end

    -- 获取活动入口时间
    function XFubenUnionKillManager.GetUnionActivityTimes()
        local activityId = GetActivityId()
        return XFubenUnionKillConfigs.GetUnionActivityTimes(activityId)
    end

    -- 保存本地数据
    function XFubenUnionKillManager.SaveUnionKillStringPrefs(key, value)
        if XPlayer.Id then
            key = string.format("%s_%s", key, tostring(XPlayer.Id))
            CS.UnityEngine.PlayerPrefs.SetString(key, value)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    function XFubenUnionKillManager.GetUnionKillStringPrefs(key, defaultValue)
        if XPlayer.Id then
            key = string.format("%s_%s", key, tostring(XPlayer.Id))
            if CS.UnityEngine.PlayerPrefs.HasKey(key) then
                local unionPref = CS.UnityEngine.PlayerPrefs.GetString(key)
                return (unionPref == nil or unionPref == "") and defaultValue or unionPref
            end
        end
        return defaultValue
    end

    function XFubenUnionKillManager.Init()
    end

    XFubenUnionKillManager.Init()
    return XFubenUnionKillManager
end

-- 同步登陆数据
XRpc.NotifyUnionKillLoginData = function(notifyData)
    --XDataCenter.FubenUnionKillManager.SyncUnionKillLoginData(notifyData)
end

-- 同步活动数据
XRpc.NotifyUnionKillActivityData = function(notifyData)
    --XDataCenter.FubenUnionKillManager.SyncUnionKillActivityData(notifyData)
end

-- 同步房间内数据
XRpc.NotifyUnionKillFightRoomData = function(notifyData)
    --XDataCenter.FubenUnionKillManager.SyncUnionKillFightRoomData(notifyData)
end

-- 同步boss血量
XRpc.NotifyUnionKillBossHp = function(notifyData)
    --XDataCenter.FubenUnionKillManager.SyncUnionKillBossHp(notifyData)
end

-- 通知玩家状态
XRpc.NotifyUnionKillPlayerInfo = function(notifyData)
    --XDataCenter.FubenUnionKillManager.SyncUnionKillPlayerInfo(notifyData)
end

-- 通知关卡信息
XRpc.NotifyUnionKillStageInfo = function(notifyData)
    --XDataCenter.FubenUnionKillManager.SyncUnionKillStageInfo(notifyData)
end

-- 通知击杀boss
XRpc.NotifyUnionKillBossCount = function(notifyData)
    --XDataCenter.FubenUnionKillManager.SyncUnionKillBossCount(notifyData)
end

-- tips通知
XRpc.NotifyUnionKillTipsMessage = function(notifyData)
    --XDataCenter.FubenUnionKillManager.SyncUnionKillTipsMessage(notifyData)
end

-- 通知玩家离开战斗房间
XRpc.NotifyUnionKillLeaveRoom = function(notifyData)
    --XDataCenter.FubenUnionKillManager.SyncUnionKillLeaveRoom(notifyData)
end

-- 通知章节信息
XRpc.NotifyUnionKillSectionData = function(notifyData)
    --XDataCenter.FubenUnionKillManager.SyncUnionKillSectionData(notifyData)
end