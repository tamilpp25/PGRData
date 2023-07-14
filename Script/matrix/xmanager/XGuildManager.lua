XGuildManagerCreator = function()
    local XGuildManager = {}
    local Json = require("XCommon/Json")

    local GuildRpc = {
        GuildCreate = "GuildCreateRequest",                             --创建公会请求
        GuildApply = "GuildApplyRequest",                               --申请加入公会
        GuildAckApply = "GuildAckApplyRequest",                         --审批加入公会
        GuildRecruit = "GuildRecruitRequest",                           --公会招募请求
        GuildListRecommend = "GuildListRecommendRequest",               --获取公会推荐列表请求
        GuildListDetail = "GuildListDetailRequest",                     --获取公会详情
        GuildChangeIcon = "GuildChangeIconRequest",                     --更改公会头像
        GuildChangeName = "GuildChangeNameRequest",                            --更改公会名称
        GuildChangeDeclaration = "GuildChangeDeclarationRequest",       --更换宣言
        GuildChangeNotice = "GuildChangeNoticeRequest",                 --更换内部通讯
        GuildChangeRankName = "GuildChangeRankNameRequest",             --修改自定义职位
        GuildReleaseWish = "GuildReleaseWishRequest",                   --发布心愿
        GuildListWish = "GuildListWishRequest",                         --获取已发布心愿列表
        GuildWishContribute = "GuildWishContributeRequest",             --心愿捐献
        GuildChangeRank = "GuildChangeRankRequest",                     --更换职位
        GuildQuit = "GuildQuitRequest",                                 --退出公会
        GuildKickMember = "GuildKickMemberRequest",                     --公会踢人
        GuildListNews = "GuildListNewsRequest",                         --获取公会动态
        GuildGiveLike = "GuildGiveLikeRequest",                         --点赞
        GuildImpeach = "GuildImpeachRequest",                           --弹劾
        GuildChangeScript = "GuildChangeScriptRequest",                 --迎新语，检测屏蔽词
        --GuildListScript = "GuildListScriptRequest",                     --获取当前自定义话术 暂时弃用
        GuildRecruitRecommend = "GuildRecruitRecommendRequest",         --获取招募推荐请求
        GuildListRecruit = "GuildListRecruitRequest",                   --玩家查询发给自己的招募请求
        GuildAckRecruit = "GuildAckRecruitRequest",                     --回应招募请求
        GuildTourist = "GuildTouristRequest",                           --游客模式加入公会
        GuildQuitTourist = "GuildQuitTouristRequest",                   --退出游客模式
        GuildListApply = "GuildListApplyRequest",                       --获取公会申请者列表
        GuildLevelUp = "GuildLevelUpRequest",                           --公会升级
        GuildPayMaintain = "GuildPayMaintainRequest",                   --公会缴纳维护费用
        GuildGetGift = "GuildGetGiftRequest",                           --公会获取活跃度礼包
        GuildListChat = "GuildListChatRequest",                         --服务器聊天缓存请求
        GuildChangeApplyOption = "GuildChangeApplyOptionRequest",       --修改申请选项
        GuildGetContributeReward = "GuildGetContributeRewardRequest",   --领取上周贡献奖励
        GuildMemberDetail = "GuildMemberDetailRequest",                 --获取公会成员信息
        GuildListRank = "GuildListRankRequest",                         --公会排行榜
        GuildFind = "GuildFindRequest",                                 --公会搜索
        GuildListTalent = "GuildListTalentRequest",                     --公会天赋列表
        GuildUpgradeTalent = "GuildUpgradeTalentRequest",               --公会天赋升级
    }
    local DataType = {
        Int = 1,
        String = 2,
    }
    XGuildManager.GuildFunctional = {
        Info = 1,
        Member = 2,
        Challenge = 3,
        Welfare = 4,
    }

    local GuildData = nil

    local GuildMemberCount = 0
    local GuildJoinCdEnd = 0
    local CanImpeach = false
    local HasImpeach = false
    local GuildLastRank = {}
    local GuildCurRank = {}
    local EnterGuildRightAway = false
    local TalentLevelCount = 0

    local LastReqServeChatTime = 0
    local TalentPoint = 0
    local TalentLevels = {} -- id = level
    --发布心愿，请求多少次。
    local WishCount = 0
    --发布心愿，捐赠了多少次。
    local WishContributeCount = 0
    -- 是否可以领取贡献奖励
    local HasContributeReward = 0
    -- 公会推荐招募页数
    local RecommendPageNo = 0
    -- 公会推荐招募数据
    local RecommendPageData = {}
    -- 发送过招募的玩家
    local RecommendedPlayers = {}
    --推荐公会数据
    local GuildRecommendDatas = {}
    --搜索公会数据
    local GuildFindDatas = {}
    --自定义话术数据
    local GuildScriptListDatas = {}
    local GuildScriptSelectedDatas = {}
    --自定义话术
    local GuildScriptAutoChat = nil
    local GuildWelcomeWordKey = "GuildWelcomeWordKey"
    local GuildWelcomeSelectKey = "GuildWelcomeSelectKey"
    local GuildWelcomeAutoChatKey = "GuildWelcomeAutoChatKey"
    -- 自定义职位名
    local GuildCustomName = {}
    --已发布心愿列表数据
    local GuildWishListDatas = {}
    --公会申请者数据
    local GuildApplyListDatas = {}
    local HasApplyMember = false
    --玩家收到的招募数据
    local GuildRecruitDatas = {}
    --未加入公会时公会信息
    local GuildVistorInfoDatas = {}
    -- 排行榜
    local GuildRankListDatas = {}
    -- 公会动态相关
    local GuildLogList = {}
    local GuildLogMaxPage = {}
    local GuildNewsCountPerPage = 0
    -- 未加入公会前的邀请
    local HasGuildRecruit = false
    -- 公会免费改名机会（被强制改名后获得）
    local FreeChangeGuildNameCount = 0

    function XGuildManager.AsyncGuildData(notifyData)
        if not notifyData then return end
        HasContributeReward = notifyData.HasContributeReward
        FreeChangeGuildNameCount = notifyData.FreeChangeGuildNameCount or 0
        GuildData.GuildId = notifyData.GuildId
        GuildData.GuildName = notifyData.GuildName
        GuildData.GuildLevel = notifyData.GuildLevel
        GuildData.GuildIconId = notifyData.IconId
        GuildData.GuildRankLevel = notifyData.GuildRankLevel
        GuildData.BossEndTime = notifyData.BossEndTime --工会boss结束时间，用于工会主页面显示倒计时
        HasGuildRecruit = notifyData.HasRecruit
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_RECRUIT_LIST_CHANGED)
        if XGuildManager.IsJoinGuild() then
            XGuildManager.GetGuildDetails(0)
            if EnterGuildRightAway == notifyData.GuildId then
                EnterGuildRightAway = nil
                XGuildManager.CloseAllAndEnterGuild()
            end
            -- 获取服务端公会频道缓存
            XGuildManager.GuildListChat(function()
                end)

            -- 申请列表
            if XGuildManager.IsGuildAdminister() then
                XGuildManager.GetGuildListApply(function()
                        local applyList = XGuildManager.GetGuildApplyList()
                        if next(applyList) then
                            HasApplyMember = true
                            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_APPLY_LIST_CHANGED)
                        end
                    end)
            end
            -- 获取成员
            local guildId = XGuildManager.GetGuildId()
            XGuildManager.GetGuildMembers(guildId)
        else
            -- 未加入公会，清除自定义职位信息
            GuildData:UpdateAllRankNames()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_NOTICE)
    end

    function XGuildManager.AsyncGuildRankName(notifyData)
        if not notifyData then return end
        GuildData:UpdateAllRankNames(notifyData.AllRankName)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_ALLRANKNAME_UPDATE)
    end

    -- 紧急维护状态更新
    function XGuildManager.AsyncGuildMaintain(notifyData)
        if not notifyData then return end

        GuildData.MaintainState = notifyData.MaintainState
        GuildData.EmergenceTime = notifyData.EmergenceTime

        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_MAINTAIN_STATE_CHANGED)
    end

    -- 公会弹劾状态
    function XGuildManager.AsyncGuildImpeach(notifyData)
        if not notifyData then return end
        -- notifyData.State 0正常、1可弹劾
        CanImpeach = notifyData.State == 1
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_LEADER_DISSMISS)
    end

    -- 公会建设度更新
    function XGuildManager.AsyncGuildEvent(notifyData)
        if not notifyData then return end
        local eventType = notifyData.Type
        local eventValue = notifyData.Value
        local eventValue2 = notifyData.Value2
        local eventStr = notifyData.Str1

        if XGuildConfig.GuildEventType.Build == eventType then
            GuildData.Build = eventValue
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_BUILD_CHANGED)
        elseif XGuildConfig.GuildEventType.Contribute == eventType then
            GuildData.GuildContributeLeft = eventValue
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_CONTRIBUTE_CHANGED)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_CONTRIBUTE_CHANGED)
        elseif XGuildConfig.GuildEventType.GiftContribute == eventType then
            GuildData.GiftContribute = eventValue
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED)
        elseif XGuildConfig.GuildEventType.Level == eventType then
            GuildData.GuildLevel = eventValue
            local levelTemplate = XGuildConfig.GetGuildLevelDataBylevel(GuildData.GuildLevel)
            GuildData.GuildMemberMaxCount = levelTemplate.Capacity
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_LEVEL_CHANGED)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_LEVEL_CHANGED)
        elseif XGuildConfig.GuildEventType.ApplyChanged == eventType then
            HasApplyMember = true
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_APPLY_LIST_CHANGED)

        elseif XGuildConfig.GuildEventType.KickOut == eventType then

            XDataCenter.ChatManager.DeleteGuildChat(GuildData.GuildId)
            XDataCenter.GuildBossManager.ClearLog()
            XDataCenter.GuildBossManager.ClearReward()

            GuildData.GuildId = 0
            GuildData.GiftGuildLevel = 0

            if XPlayer.Id == eventValue then return end
            if XLuaUiManager.IsUiLoad("UiGuildMain") or XLuaUiManager.IsUiLoad("UiGuildDormMain") then
                XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
                if CS.XFight.Instance ~= nil then
                    return
                end
                if XHomeSceneManager.GetCurrentScene() ~= nil then
                    XHomeSceneManager.LeaveScene()
                end
                XLuaUiManager.RunMain()
            end
            -- if XLuaUiManager.IsUiLoad("UiGuildMain") then
            --     XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
            --     if XLuaUiManager.IsUiShow("UiGuildMain") then
            --         XLuaUiManager.Close("UiGuildMain")
            --     end
            -- end
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED)
        elseif XGuildConfig.GuildEventType.ContributeReward == eventType then
            HasContributeReward = eventValue

            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_MEMBER_CONTRIBUTE_CONDITION)

        elseif XGuildConfig.GuildEventType.WeeklyReset == eventType then
            -- 清空周贡献
            -- local allMember = XGuildManager.GetMemberList()
            -- for _, member in pairs(allMember or {}) do
            --     member.ContributeWeek = 0
            -- end

            if XGuildManager.IsJoinGuild() then
                XGuildManager.GuildListChat(function()
                        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_WEEKLY_RESET)
                    end)
            end

        elseif XGuildConfig.GuildEventType.RankLevelChanged == eventType then
            -- 重新请求最新消息，重现请求角色
            local oldRankLevel = GuildData.GuildRankLevel
            local needReq = oldRankLevel == XGuildConfig.GuildRankLevel.Leader or eventValue == XGuildConfig.GuildRankLevel.Leader
            GuildData.GuildRankLevel = eventValue

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_RANKLEVEL_CHANGED)
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_RANKLEVEL_CHANGED)
            if XLuaUiManager.IsUiLoad("UiGuildMain") then
                XUiManager.TipMsg(CS.XTextManager.GetText("GuildRankLevelChangeNotify", XGuildManager.GetRankNameByLevel(GuildData.GuildRankLevel)))
                if XGuildManager.IsGuildAdminister() then
                    XGuildManager.GetGuildListApply(function()
                            local applyList = XGuildManager.GetGuildApplyList()
                            if next(applyList) then
                                HasApplyMember = true
                                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_APPLY_LIST_CHANGED)
                            end
                        end)
                else
                    HasApplyMember = false
                    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_APPLY_LIST_CHANGED)
                end

                if needReq then--更新
                    XGuildManager.GetGuildDetails(0, function()
                            CsXGameEventManager.Instance:Notify(XEventId.EVNET_GUILD_LEADER_NAME_CHANGED)
                        end)
                end
            end

            -- 假如会长->会员，其他->会长,更新成员
            if XLuaUiManager.IsUiLoad("UiGuildRongyu") and needReq then
                local guildId = XGuildManager.GetGuildId()
                XGuildManager.GetGuildMembers(guildId, function()
                        XEventManager.DispatchEvent(XEventId.EVNET_GUILD_LEADER_CHANGED)
                        if XLuaUiManager.IsUiShow("UiPlayerInfo") then
                            XLuaUiManager.Close("UiPlayerInfo")
                        end
                    end)
            end

            if XLuaUiManager.IsUiShow("UiPlayerInfo") then
                XLuaUiManager.Close("UiPlayerInfo")
            end
        elseif XGuildConfig.GuildEventType.Talent == eventType then
            TalentLevels[eventValue] = eventValue2
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_TALENT_ASYNC)
        elseif XGuildConfig.GuildEventType.TalentPoint == eventType then
            TalentPoint = eventValue
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_TALENT_ASYNC)
        elseif XGuildConfig.GuildEventType.MemberChanged == eventType then
            GuildData.GuildMemberCount = eventValue
            if XGuildManager.GetGuildScriptAutoChat() then
                -- local username = eventStr
                XGuildManager.SendGuildScript()
            end
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_MEMBERCOUNT_CHANGED)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_MEMBERCOUNT_CHANGED)
        elseif XGuildConfig.GuildEventType.Recruit == eventType then
            HasGuildRecruit = true
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_RECRUIT_LIST_CHANGED)
        elseif XGuildConfig.GuildEventType.GuildBossHpBox == eventType then
            XDataCenter.GuildBossManager.SetBossHpReward(true)
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDBOSS_HPBOX_CHANGED)
            XDataCenter.GuildBossManager.UpdateGuildBossHp(eventValue, eventValue2)
        elseif XGuildConfig.GuildEventType.GuildBossScoreBox == eventType then
            XDataCenter.GuildBossManager.SetScoreReward(true)
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDBOSS_SCOREBOX_CHANGED)
        elseif XGuildConfig.GuildEventType.GuildBossWeeklyTask == eventType then
            XDataCenter.GuildBossManager.SetGuildBossWeeklyTaskTime(eventValue)
        elseif XGuildConfig.GuildEventType.FreeChangeName == eventType then
            FreeChangeGuildNameCount = FreeChangeGuildNameCount + 1
        end
    end

    function XGuildManager.Init()
        if not GuildData then
            GuildData = XGuildData.New()
        end
        GuildNewsCountPerPage = CS.XGame.Config:GetInt("GuildNewsCountPerPage")
    end

    function XGuildManager.IsInitGuildData()
        return GuildData:IsInit()
    end

    --所在公会的职务
    function XGuildManager.GetCurRankLevel()
        return GuildData.GuildRankLevel
    end

    --所在公会的职务是否是管理层
    function XGuildManager.IsGuildAdminister()
        return GuildData:IsGuildAdministor()
    end

    -- 是否为会长
    function XGuildManager.IsGuildLeader()
        return GuildData:IsLeader()
    end

    --是否已经加入公会
    function XGuildManager.IsJoinGuild()
        return GuildData:IsJoinGuild()
    end

    --当前公会职位人数
    function XGuildManager.GetMyGuildPosCount()
        -- GetGuildPositionCurAmount
        local data = GuildData:GetGuildMembers()
        local level = XGuildManager.GetGuildLevel()
        local amount = {}
        for _, v in pairs(XGuildConfig.GuildRankLevel) do
            amount[v] = amount[v] or 0
        end
        for _, v in pairs(data) do
            amount[v.RankLevel] = amount[v.RankLevel] + 1
        end
        return amount
    end

    --当前公会职位容量
    function XGuildManager.GetGuildPosCapacity(level, rank)
        local rankLevel = XGuildConfig.GuildRankLevel
        local guildLevelData = XGuildConfig.GetGuildLevelDataBylevel(level)
        if not guildLevelData then
            return
        end
        if rank == rankLevel.Leader then
            return 1
        elseif rank == rankLevel.CoLeader then
            return guildLevelData.PositionNum[1]
        elseif rank == rankLevel.Elder then
            return guildLevelData.PositionNum[2]
        elseif rank == rankLevel.Member then
            return guildLevelData.Capacity
        elseif rank == rankLevel.Tourist then
            return guildLevelData.PositionNum[3]
        end
    end

    -- 如果该玩家是在离线时被审批进入了公会，则重新上线前，Data.GuildDetail都不会更新信息，因此采用本地信息判断
    function XGuildManager.CheckMemberOperatePermission(targetId)
        local memberList = XDataCenter.GuildManager.GetMemberList()
        local isAdministor = XDataCenter.GuildManager.IsGuildAdminister()
        local myRankLevel = XDataCenter.GuildManager.GetCurRankLevel()
        if memberList[targetId] then
            local targetRankLevel = memberList[targetId].RankLevel
            return targetRankLevel ~= nil and targetRankLevel > 0 and isAdministor and myRankLevel < targetRankLevel
        end
        return false
    end

    --当前心愿请求数
    function XGuildManager.GetCurWishReqCount()
        return WishCount
    end

    --累计当前心愿请求数
    function XGuildManager.AddCurWishReqCount()
        WishCount = WishCount + 1
    end

    --获取所有公会
    function XGuildManager.GetCurGuildsInfo()
        return {}
    end

    --获取今天已经捐赠次数
    function XGuildManager.GetCurDonationCount()
        return WishContributeCount
    end

    --累加今天已经捐赠次数
    function XGuildManager.AddCurDonationCount()
        WishContributeCount = WishContributeCount + 1
    end

    --获取总可捐赠次数
    function XGuildManager.GetTotalDonationCount(level)
        return XGuildConfig.GetGuildWishContributeMaxCountByLevel(level)
    end

    --判断此公会人数是否已经满
    function XGuildManager.IsFullGuild(guildId)
        local data = XGuildManager.GetVistorGuildDetailsById(guildId)
        if not data then
            return true
        end

        return data.GuildMemberMaxCount == data.GuildMemberCount
    end

    --判断此公会游客数量是否已经满
    function XGuildManager.IsFullGuildVistor(guildId)
        local data = XGuildManager.GetVistorGuildDetailsById(guildId)
        if not data then
            return true
        end

        return data.GuildTouristMaxCount == data.GuildTouristCount
    end

    --判断自己是不是游客
    function XGuildManager.IsGuildTourist()
        return XGuildManager.GetCurRankLevel() == XGuildConfig.GuildRankLevel.Tourist
    end

    --已经发布的心愿
    function XGuildManager.GetGuildWishList()
        return GuildWishListDatas
    end
    --处理公会推荐列表数据
    -- int Id;
    -- string Name;
    -- int IconId;
    -- int Level;
    -- int MemberCount;
    -- int MemberMaxCount;
    -- int ContributeIn7Days;
    function XGuildManager.HandleGuildRecommendDatas(pageNo, datas)
        if datas ~= nil and next(datas) ~= nil then
            GuildRecommendDatas[pageNo] = {}
            for _, v in pairs(datas) do
                if v and v.Id then
                    table.insert(GuildRecommendDatas[pageNo], v)
                end
            end
            XGuildManager.RecordGuildRecommend(-1)
        else
            XGuildManager.RecordGuildRecommend(pageNo)
        end
    end

    function XGuildManager.HandleGuildFindDatas(guildname, datas)
        if datas ~= nil and next(datas) ~= nil then
            GuildFindDatas[guildname] = {}
            for _, v in pairs(datas) do
                if v and v.Id then
                    table.insert(GuildFindDatas[guildname], v)
                end
            end
        end
    end

    function XGuildManager.GetGuildFindDatas(guildname)
        return GuildFindDatas[guildname] or {}
    end

    function XGuildManager.RecordGuildRecommend(pageNo)
        XGuildManager.EmptyPageNo = pageNo
    end

    function XGuildManager.GetCurGuildRecommend()
        return XGuildManager.EmptyPageNo
    end

    function XGuildManager.GetGuildRecommendDatas(pageNo)

        local nextPageNo = pageNo + 1
        if GuildRecommendDatas[pageNo] and not GuildRecommendDatas[nextPageNo] then
            XDataCenter.GuildManager.GuildListRecommendRequest(nextPageNo, function()
                end)
        end

        return GuildRecommendDatas[pageNo] or {}
    end

    function XGuildManager.ResetGuildRecommendDatas()
        GuildRecommendDatas = {}
    end

    function XGuildManager.IsNeedRequestRecommendData()
        if not next(GuildRecommendDatas) then
            return true
        end
        if XTime.GetServerNowTimestamp() - XGuildManager.PreRequestRecommendTime > XGuildConfig.GuildRequestRecommandTime then
            return true
        end

        return false
    end

    function XGuildManager.ResetPreRequestRecommendTime()
        XGuildManager.PreRequestRecommendTime = 0
    end

    function XGuildManager.IsNeedRequestRank()
        if not next(GuildRankListDatas) then
            return true
        end

        if XTime.GetServerNowTimestamp() - XGuildManager.PreRequestGuildListRankTime > XGuildConfig.GuildRequestRankTime then
            return true
        end

        return false
    end

    -- 随机发送迎新语
    function XGuildManager.SendGuildScript()
        math.randomseed(os.time())
        local chatData = {}
        chatData.ChannelType = ChatChannelType.Guild
        chatData.MsgType = ChatMsgType.Normal
        chatData.TargetIds = {}
        chatData.TargetIds[1] = XGuildManager.GetGuildId()
        local welcome = XGuildManager.GetGuildScriptSelectedDatas()
        if #welcome == 0 then return end
        local content = welcome[math.random(#welcome)]
        chatData.Content = content
        XDataCenter.ChatManager.SendChat(chatData)
    end

    --处理已发布心愿列表数据
    -- string Name;
    -- int HeadPortraitId;
    -- int RankLevel;
    -- int ItemId;
    -- int GotCount;
    -- int MaxCount;
    -- int Seq;
    function XGuildManager.HandleListWishDatas(wishesData, wishCount, wishContributeCount)
        GuildWishListDatas = {}
        if wishesData ~= nil and next(wishesData) ~= nil then
            for _, v in pairs(wishesData) do
                if v and v.Id then
                    if XPlayer.Id ~= v.Id then
                        table.insert(GuildWishListDatas, v)
                    end
                end
            end
        end
        WishCount = wishCount
        WishContributeCount = wishContributeCount
    end

    function XGuildManager.HandleListRankDatas(type, tabledata, myRankNum)
        GuildRankListDatas[type] = {}
        local rankFromList = nil
        if not (tabledata and next(tabledata)) then return end
        for index, v in ipairs(tabledata) do
            if v and v.GuildId then
                if GuildData.GuildId == v.GuildId then
                    rankFromList = index
                end
                v.RankNum = index
                v.Type = type
                table.insert(GuildRankListDatas[type], v)
            end
        end
        -- 如果榜单中有则优先用榜单的排名
        if rankFromList then
            GuildData.GuildRank[type] = rankFromList
            -- 如果服务端没有，则本地只能显示百分比
        elseif myRankNum > 0 and myRankNum < 1 then
            GuildData.GuildRank[type] = (math.floor(myRankNum * 10000) / 10000)
        else
            GuildData.GuildRank[type] = 0
        end
    end

    function XGuildManager.GetMyGuildRank(type)
        return GuildData.GuildRank[type] or 0
    end

    function XGuildManager.GetMyGuildLastRank(type)
        if not GuildLastRank[type] then
            GuildLastRank[type] = XGuildManager.GetGuildPrefs(XGuildConfig.KEY_LAST_RANK..type, nil, DataType.String)
        end
        if not GuildLastRank[type] then
            return 0
        end
        local strTable = string.Split(GuildLastRank[type], '_')
        local lastDate, lastRank = strTable[1], strTable[2]
        return tonumber(lastRank) or 0
    end

    function XGuildManager.SaveMyGuildCurRank(type)
        local date = os.date("%Y%m%d")
        local oldCurRank = XGuildManager.GetGuildPrefs(XGuildConfig.KEY_CUR_RANK..type, nil, DataType.String)
        local strTable = string.Split(oldCurRank, '_')
        local lastDate = strTable[1] or date
        -- 已经是旧数据了，需要赋给GuildLastRank
        if next(strTable) and tonumber(lastDate) < tonumber(date) then
            GuildLastRank[type] = oldCurRank
            XGuildManager.SaveGuildPrefs(XGuildConfig.KEY_LAST_RANK..type,  GuildLastRank[type], DataType.String)
        end
        GuildCurRank[type] = string.format( "%s_%.4f", date, XGuildManager.GetMyGuildRank(type))
        XGuildManager.SaveGuildPrefs(XGuildConfig.KEY_CUR_RANK..type, GuildCurRank[type], DataType.String)
    end

    function XGuildManager.GetListRankDatas(order)
        return GuildRankListDatas[order]
    end

    function XGuildManager.EnterGuild(onEnterGuildCb)
        if not XDataCenter.GuildManager.IsJoinGuild() then
            if XGuildManager.IsNeedRequestRecommendData() then
                XDataCenter.GuildManager.GuildListRecommendRequest(1, function()
                        XLuaUiManager.Open("UiGuildRecommendation")
                    end)
            else
                XLuaUiManager.Open("UiGuildRecommendation")
            end
            return
        end

        if XGuildManager.IsGuildTourist() then
            XDataCenter.GuildManager.GetVistorGuildDetailsReq(GuildData.GuildId, function()
                    XLuaUiManager.Open("UiGuildVistor")
                end)
        else
            XDataCenter.GuildManager.GetGuildDetails(0, function()
                    XLuaUiManager.Open("UiGuildMain")
                    if onEnterGuildCb then
                        onEnterGuildCb()
                    end
                end)
        end
    end

    -- 用于在未进公会界面前获取公会数据，如已有数据则不再获取
    function XGuildManager.RequestGuildData()
        if not XDataCenter.GuildManager.IsJoinGuild() then return end
        if not XGuildManager.IsInitGuildData() then
            XDataCenter.GuildManager.GetGuildDetails(0)
        end
    end

    function XGuildManager.CloseAllAndEnterGuild()
        XDataCenter.GuildManager.GetGuildDetails(0, function()
                local topUiName = XLuaUiManager.GetTopUiName()
                XDataCenter.GuildDormManager.EnterGuildDorm(nil, nil, function()
                        XLuaUiManager.Remove(topUiName)
                        XLuaUiManager.Remove("UiGuildRecommendation")
                    end)
            end)
    end


    function XGuildManager.EnterGuildTalent()
        if XGuildManager.CheckAllTalentLevelMax() then
            XDataCenter.GuildManager.GetGuildDetails(0, function()
                    XLuaUiManager.Open("UiGuildGloryLevel")
                end)
        else
            XGuildManager.GuildTalentListReq(function()
                    XLuaUiManager.Open("UiGuildSkill")
                end)
        end
    end

    function XGuildManager.HandleGuildListRecruitDatas(datas)
        GuildRecruitDatas = {}
        if datas ~= nil and next(datas) ~= nil then
            for _, v in pairs(datas) do
                if v.PlayerId and v.PlayerId ~= XPlayer.Id then
                    table.insert(GuildRecruitDatas, v)
                end
            end
        end
    end

    function XGuildManager.GetGuildListRecruitDatas()
        return GuildRecruitDatas
    end

    function XGuildManager.IsNeedRequestRecruitData()
        if not next(GuildRecruitDatas) then
            return true
        end

        if XTime.GetServerNowTimestamp() - XGuildManager.PreRequestRecruitTime > XGuildConfig.GuildRequestRecruitTime then
            return true
        end

        return false
    end

    --游客模式退出后，清掉。
    function XGuildManager.QuitVistorClean()
        XGuildManager.ClearVistorGuildMembers(GuildData.GuildId)
        GuildData.GuildId = 0
    end

    -- RPC
    --获取招募推荐请求
    function XGuildManager.GuildRecruitRecommendRequest(pageNo, cb)
        XNetwork.Call(GuildRpc.GuildRecruitRecommend, { PageNo = pageNo }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                for _, recruitInfo in pairs(res.RecommendData or {}) do
                    if not RecommendedPlayers[recruitInfo.PlayerId] then
                        RecommendPageData[recruitInfo.PlayerId] = recruitInfo
                    end
                end

                if cb then
                    cb()
                end
            end)
    end

    -- 随机出count个推荐招募,不在ownList中
    function XGuildManager.GetRandomRecommendPlayers()

        local randomRecommend = {}
        local playerIdList = {}
        local availableCount = 0
        local availableRecommend = {}
        for id, recruitInfo in pairs(RecommendPageData) do
            if not RecommendedPlayers[id] then
                table.insert(playerIdList, id)
                availableCount = availableCount + 1
                availableRecommend[id] = recruitInfo
            end
        end

        if availableCount <= XGuildConfig.RecommendCount then
            return availableRecommend
        end
        -- 需要随机：随机次数尽量少
        math.randomseed(os.time())
        local randomCount = XGuildConfig.RecommendCount
        local leftCount = availableCount - XGuildConfig.RecommendCount
        local leftPlayers = {}
        if leftCount <= XGuildConfig.RecommendCount then
            while (leftCount > 0) do
                local index = math.random(1, availableCount)
                local playerId = playerIdList[index]
                if not leftPlayers[playerId] then
                    leftPlayers[playerId] = true
                    leftCount = leftCount - 1
                end
            end
            for id, recruitInfo in pairs(availableRecommend) do
                if not leftPlayers[id] then
                    randomRecommend[id] = recruitInfo
                end
            end
            return randomRecommend
        else
            while (randomCount > 0) do
                local randomLength = availableCount - (XGuildConfig.RecommendCount - randomCount)
                local index = math.random(1, randomLength)
                local playerId = playerIdList[index]
                if not randomRecommend[playerId] then
                    randomRecommend[playerId] = availableRecommend[playerId]
                    randomCount = randomCount - 1
                    -- 随机到的、跟最后一个调换位置
                    local temp = playerIdList[randomLength]
                    playerIdList[index] = temp
                    playerIdList[randomLength] = playerId
                end
            end
            return randomRecommend
        end
    end

    --玩家查询发给自己的招募请求
    function XGuildManager.GuildListRecruitRequest(cb)
        if XGuildManager.IsNeedRequestRecruitData() then
            XNetwork.Call(GuildRpc.GuildListRecruit, {}, function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        return
                    end
                    XGuildManager.PreRequestRecruitTime = XTime.GetServerNowTimestamp()
                    XGuildManager.HandleGuildListRecruitDatas(res.Data)
                    if cb then
                        cb()
                    end
                end)
        else
            if cb then
                cb()
            end
        end
    end

    --回应招募请求
    function XGuildManager.GuildAckRecruitRequest(guildId, isAgree, playerId, cb)
        if not guildId or guildId <= 0 or isAgree == nil then
            XLog.Error("XGuildManager.GuildAckRecruitRequest参数错误: 参数guildId是 " .. tostring(guildId) .. " 参数isAgree是" .. tostring(isAgree))
            return
        end

        XNetwork.Call(GuildRpc.GuildAckRecruit, { GuildId = guildId, IsAgree = isAgree }, function(res)
                local removeIndex = -1
                for k, v in pairs(GuildRecruitDatas or {}) do
                    if v.PlayerId == playerId and v.GuildId == guildId then
                        removeIndex = k
                        break
                    end
                end

                if removeIndex ~= -1 then
                    table.remove(GuildRecruitDatas, removeIndex)
                end

                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if cb then
                        cb()
                    end
                    return
                end

                if isAgree then
                    XGuildManager.CloseAllAndEnterGuild()
                end

                if cb then
                    cb()
                end
            end)
    end

    --游客模式加入公会
    function XGuildManager.GuildTouristRequest(guildId, cb)
        if not guildId or guildId <= 0 then
            XLog.Error("XGuildManager.GuildTouristRequest参数错误: 参数guildId是空或者guildId小于等于0, 参数guildId：" .. tostring(guildId))
            return
        end

        XNetwork.Call(GuildRpc.GuildTourist, { GuildId = guildId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                GuildData.GuildId = guildId
                if cb then
                    cb()
                end
            end)
    end

    --退出游客模式
    function XGuildManager.GuildQuitTouristRequest(cb)
        XNetwork.Call(GuildRpc.GuildQuitTourist, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
            end)
    end

    --发布心愿
    function XGuildManager.PublishWishRequest(itemId, cb)
        if not itemId then
            XLog.Error("XGuildManager.PublishWishRequest参数错误: 参数itemId是空")
            return
        end

        XNetwork.Call(GuildRpc.GuildReleaseWish, { ItemId = itemId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                XGuildManager.AddCurWishReqCount()
                if cb then
                    cb()
                end
            end)
    end

    --捐赠
    function XGuildManager.DonateRequest(playerId, seq, itemId, cb)
        XNetwork.Call(GuildRpc.GuildWishContribute, { PlayerId = playerId, Seq = seq, ItemId = itemId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                XGuildManager.AddCurDonationCount()
                if cb then
                    cb()
                end
            end)
    end

    --创建公会
    function XGuildManager.BuildGuildRequest(guildName, guildDeclaration, iconId, cb)
        XNetwork.Call(GuildRpc.GuildCreate, {
                GuildName = guildName,
                GuildDeclaration = guildDeclaration,
                IconId = iconId
            }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    local needDispatch, name, declaration = false
                    if res.GuildName ~= nil and res.GuildName ~= "" then
                        name = res.GuildName
                        needDispatch = true
                    end

                    if res.GuildDeclaration ~= nil and res.GuildDeclaration ~= "" then
                        declaration = res.GuildDeclaration
                        needDispatch = true
                    end

                    if needDispatch then
                        name = name or guildName
                        declaration = declaration or guildDeclaration
                        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_FILTER_FINISH, name, declaration)
                    end
                    return
                end

                if cb then
                    cb()
                end
            end)
    end

    --v1.28 创建工会功能前置条件判断
    function XGuildManager.CheckBuildGuild()
        local conditionIds = XGuildConfig.GetCreateConditionals()
        for _, id in ipairs(conditionIds) do
            if not XConditionManager.CheckCondition(id) then
                return id
            end
        end
        return nil
    end

    -- 获取公会详情GuildId = 0表示本公会
    function XGuildManager.GetGuildDetails(guild, cb)
        XNetwork.Call(GuildRpc.GuildListDetail, { GuildId = guild }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                GuildData:UpdateGuildData(res)

                if cb then
                    cb()
                end
            end)
    end

    function XGuildManager.GetVistorGuildDetailsReq(guildId, cb)
        XNetwork.Call(GuildRpc.GuildListDetail, { GuildId = guildId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if not GuildVistorInfoDatas[res.GuildId] then
                    GuildVistorInfoDatas[res.GuildId] = XGuildVistorData.New()
                end

                GuildVistorInfoDatas[res.GuildId]:UpdateGuildData(res)
                if cb then
                    cb()
                end
            end)
    end

    function XGuildManager.GetVistorGuildDetailsById(guildId)
        return GuildVistorInfoDatas[guildId]
    end

    function XGuildManager.GetVistorMemberList(guildId)
        return GuildVistorInfoDatas[guildId]:GetMemberList()
    end

    function XGuildManager.IsHaveVistorGuildDetailsById(guildId)
        if not GuildVistorInfoDatas[guildId] then
            return false
        end

        return GuildVistorInfoDatas[guildId]:IsHaveVistorGuildDetailsById()
    end

    -- 自定义职位
    function XGuildManager.ChangeRankName(allRankNames, cb)
        XNetwork.Call(GuildRpc.GuildChangeRankName, { AllRankName = allRankNames }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                GuildData:UpdateAllRankNames(allRankNames)

                if cb then
                    cb()
                end
            end)
    end

    -- 变更职位
    function XGuildManager.GuildChangeRank(playerId, rankId, cb)
        XNetwork.Call(GuildRpc.GuildChangeRank,
            {
                PlayerId = playerId,
                NewRank = rankId
            }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local members = GuildData:GetGuildMembers()
                if members and members[playerId] then
                    members[playerId].RankLevel = rankId
                    -- 通知刷新
                    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_UPDATE_MEMBER_INFO)
                end

                if cb then
                    cb()
                end
            end)
    end

    -- 退出公会
    function XGuildManager.QuitGuild(cb)
        local lastGuildId = GuildData.GuildId
        local tempLevel = XGuildManager.GetGuildLevel()
        XGuildManager.SaveGuildLevel(-1)
        if XDataCenter.GuildWarManager.CheckActivityIsInTime() and XDataCenter.GuildWarManager.CheckRoundIsInTime() then
            local memberList = XGuildManager.GetMemberList()
            local onlyOneMember = true
            local memberCount = 0
            for _, _ in pairs(memberList or {}) do
                memberCount = memberCount + 1
                if memberCount > 1 then
                    onlyOneMember = false
                    break
                end
            end
            if onlyOneMember then
                XUiManager.TipText("GuildWarCantGiveUpGuild")
                return
            end
        end
        XNetwork.Call(GuildRpc.GuildQuit, {}, function(res)
                if res.Code ~= XCode.Success then
                    XGuildManager.SaveGuildLevel(tempLevel)
                    XUiManager.TipCode(res.Code)
                    return
                end
                XDataCenter.ChatManager.DeleteGuildChat(lastGuildId)
                XDataCenter.GuildBossManager.ClearLog()
                XDataCenter.GuildBossManager.ClearReward()
                XGuildManager.ClearLog()
                GuildData.GuildId = 0

                if cb then
                    cb()
                end
            end)
    end

    --修改公会头像
    function XGuildManager.GuildChangeIconRequest(iconid, cb)
        XNetwork.Call(GuildRpc.GuildChangeIcon, { IconId = iconid }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                GuildData.GuildIconId = iconid
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DATA_CHANGED)
                if cb then
                    cb()
                end
            end)
    end

    -- 修改公会名称
    function XGuildManager.GuildChangeName(name, func)
        XNetwork.Call(GuildRpc.GuildChangeName, { Name = name }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if res.Name ~= nil and res.Name ~= "" then
                        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_FILTER_FINISH, res.Name)
                    end
                    return
                end
                GuildData.GuildName = name
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DATA_CHANGED)
                if func then
                    func()
                end
            end)
    end

    -- 修改宣言
    function XGuildManager.GuildChangeDeclaration(delaration, func)
        XNetwork.Call(GuildRpc.GuildChangeDeclaration, { Delaration = delaration }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if res.Delaration ~= nil and res.Delaration ~= "" then
                        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_FILTER_FINISH, res.Delaration)
                    end
                    return
                end
                GuildData.GuildDeclaration = delaration
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DATA_CHANGED)
                if func then
                    func()
                end
            end)
    end

    -- 修改内部通讯
    function XGuildManager.GuildChangeNotice(notice, func)
        XNetwork.Call(GuildRpc.GuildChangeNotice, { Notice = notice }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if res.Notice ~= nil and res.Notice ~= "" then
                        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_FILTER_FINISH, res.Notice)
                    end
                    return
                end
                GuildData.GuildInterCom = notice
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DATA_CHANGED)
                if func then
                    func()
                end
            end)
    end


    -- 获取公会成员信息
    function XGuildManager.GetGuildMembers(guildId, func)
        XNetwork.Call(GuildRpc.GuildMemberDetail, { GuildId = guildId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                CanImpeach = res.CanImpeach
                HasImpeach = res.HasImpeach

                local MemberCount = 0
                for _, _ in pairs(res.MembersData or {}) do
                    MemberCount = MemberCount + 1
                end
                GuildData:UpdateGuildMembers(res.MembersData, MemberCount)

                -- 人数变化，相同界面使用这个事件
                if MemberCount > GuildMemberCount then
                    GuildMemberCount = MemberCount
                    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_UPDATE_MEMBER_INFO)
                end
                -- 检查会长罢免
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_LEADER_DISSMISS)
                -- 检查成员在线人数
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_MEMBERCOUNT_CHANGED)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_MEMBERCOUNT_CHANGED)
                if func then
                    func()
                end
            end)

    end

    -- 获取公会成员信息(游客)
    function XGuildManager.GetVistorGuildMembers(guildId, func)
        XNetwork.Call(GuildRpc.GuildMemberDetail, { GuildId = guildId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if not GuildVistorInfoDatas[guildId] then
                    GuildVistorInfoDatas[guildId] = XGuildVistorData.New()
                end

                GuildVistorInfoDatas[guildId]:UpdateGuildMembers(res.MembersData)
                if func then
                    func()
                end
            end)

    end
    -- 申请加入公会的列表
    function XGuildManager.GetGuildListApply(cb)
        XNetwork.Call(GuildRpc.GuildListApply, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                GuildApplyListDatas = {}
                for _, v in pairs(res.Data or {}) do
                    GuildApplyListDatas[v.PlayerId] = v
                end

                if cb then
                    cb()
                end
            end)
    end

    -- 点赞
    function XGuildManager.GuildGiveLike(playerId, itemId, itemCount, cb)
        XNetwork.Call(GuildRpc.GuildGiveLike,
            {
                OtherId = playerId,
                ItemId = itemId,
                ItemCount = itemCount
            }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then
                    cb()
                end
            end)
    end

    -- 弹劾会长
    function XGuildManager.GuildImpeachLeader(cb)
        XNetwork.Call(GuildRpc.GuildImpeach, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
            end)
    end

    -- 公会升级
    function XGuildManager.GuildLevelUp(cb)
        XNetwork.Call(GuildRpc.GuildLevelUp, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                if cb then
                    cb()
                end
            end)
    end

    -- 缴纳维护费用
    function XGuildManager.GuildPayMaintain(cb)
        XNetwork.Call(GuildRpc.GuildPayMaintain, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                GuildData.MaintainState = XGuildConfig.GuildMaintainState.Normal

                if cb then
                    cb()
                end
            end)
    end

    function XGuildManager.GetGuildLogListByType(type)
        if not GuildLogList[type] then
            GuildLogList[type] = {}
        end
        return GuildLogList[type]
    end

    function XGuildManager.GetGuildLogMaxPage(type)
        return GuildLogMaxPage[type] or 0
    end

    function XGuildManager.ClearLog()
        GuildLogList = {}
        GuildLogMaxPage = {}
    end

    -- 获取公会动态
    function XGuildManager.GetGuildListNews(newsType, pageNo, cb)
        XNetwork.Call(GuildRpc.GuildListNews,
            {
                NewsType = newsType,
                PageNo = pageNo
            }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                -- 记录公会动态信息
                local logList = XGuildManager.GetGuildLogListByType(newsType)
                if pageNo <= 0 then
                    pageNo = res.MaxPageNo
                    GuildLogMaxPage[newsType] = res.MaxPageNo
                end
                for k, v in ipairs(res.News or {}) do
                    -- 首先请求最后一页（pageNo为0），获得最大页数后循环-1获取列表
                    local index = (pageNo - 1) * GuildNewsCountPerPage + k
                    logList[index] = v
                end

                if cb then
                    cb()
                end
            end)
    end

    -- 公会活跃度礼包
    function XGuildManager.GuildGetGift(giftLevel, cb)
        XNetwork.Call(GuildRpc.GuildGetGift, { GiftLevel = giftLevel}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                GuildData.GiftLevelGot[giftLevel] = true
                local giftGuildLevel = GuildData.GiftGuildLevel
                local giftData = XGuildConfig.GetGuildGiftByGuildLevelAndGiftLevel(giftGuildLevel, giftLevel)
                if giftData and giftData.GiftReward then
                    local rewardList = XRewardManager.GetRewardList(giftData.GiftReward)
                    if rewardList then
                        XUiManager.OpenUiObtain(rewardList)
                    end
                end
                if cb then
                    cb()
                end
                -- 触发更新
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED)
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED)
            end)
    end

    -- 修改申请设置
    function XGuildManager.GuildChangeApplyOption(option, minLevel, func)
        XNetwork.Call(GuildRpc.GuildChangeApplyOption,
            { Option = option, MinLevel = minLevel }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                GuildData.Option = option
                GuildData.MinLevel = minLevel

                if func then
                    func()
                end

            end)
    end

    -- 领取上周贡献奖励
    function XGuildManager.GuildGetContributeReward(func)
        XNetwork.Call(GuildRpc.GuildGetContributeReward,
            {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                HasContributeReward = 0
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_MEMBER_CONTRIBUTE_CONDITION)

                local list = {}
                table.insert(list, XRewardManager.CreateRewardGoodsByTemplate({ TemplateId = XGuildConfig.GuildCoin, Count = res.AddGuildCoin }))
                XUiManager.OpenUiObtain(list)

                if func then
                    func()
                end
            end)
    end

    -- 获取服务器聊天缓存
    function XGuildManager.GuildListChat(cb)
        -- 限制频繁操作
        local curTime = XTime.GetServerNowTimestamp()
        if curTime - LastReqServeChatTime < 5 then
            return
        end
        LastReqServeChatTime = curTime

        XNetwork.Call(GuildRpc.GuildListChat, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                local chatCache = {}
                for i = 1, #res.ChatList do
                    local chatJson = Json.decode(res.ChatList[i])
                    local chatData = XChatData.New(chatJson)
                    -- local chatData = XChatData.New()
                    -- chatData.SenderId = chatJson.SenderId
                    -- chatData.TargetId = chatJson.TargetId
                    -- chatData.CreateTime = chatJson.CreateTime
                    -- chatData.Content = chatJson.Content
                    -- chatData.MsgType = chatJson.MsgType
                    -- chatData.MessageId = chatJson.MessageId
                    -- chatData.Icon = chatJson.Icon
                    -- chatData.CustomContent = chatJson.CustomContent
                    -- chatData.NickName = chatJson.NickName
                    table.insert(chatCache, 1, chatData)
                end
                -- 初始化客户端信息
                XDataCenter.ChatManager.InitLocalCacheGuildChatContent()

                -- 服务端，客户端消息合并
                XDataCenter.ChatManager.MergeClientAndServerGuildChat(chatCache)

                if cb then
                    cb()
                end
            end)
    end

    -- 会长向玩家发出招募
    function XGuildManager.GuildRecruit(playerId, cb, notRecord)
        XNetwork.Call(GuildRpc.GuildRecruit, { PlayId = playerId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if not notRecord then
                        RecommendedPlayers[playerId] = true
                    end
                    -- 招募发出成功
                    if cb then
                        cb()
                    end
                    return
                end
                XUiManager.TipMsg(CS.XTextManager.GetText("GuildHasSendRecruit"))
                if not notRecord then
                    RecommendedPlayers[playerId] = true
                end
                -- 招募发出成功
                if cb then
                    cb()
                end
            end)
    end

    --申请加入公会
    function XGuildManager.ApplyToJoinGuildRequest(guildId, cb)
        XNetwork.Call(GuildRpc.GuildApply, { GuildId = guildId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then
                    cb()
                end
                if res.IsPass == true then
                    EnterGuildRightAway = guildId
                    if guildId == XGuildManager.GetGuildId() then
                        XGuildManager.CloseAllAndEnterGuild()
                    end
                end
            end)
    end

    -- 拒绝成员加入公会
    function XGuildManager.RefuseGuildRequest(playId, cb)
        XNetwork.Call(GuildRpc.GuildAckApply, { PlayId = playId, IsAgree = false }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)

                    GuildApplyListDatas[playId] = nil
                    if cb then
                        cb()
                    end
                    return
                end

                GuildApplyListDatas[playId] = nil

                if cb then
                    cb()
                end
            end)
    end

    --同意成员加入公会
    function XGuildManager.AcceptGuildRequest(playId, playerName, cb)
        XNetwork.Call(GuildRpc.GuildAckApply, { PlayId = playId, IsAgree = true }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    GuildApplyListDatas[playId] = nil

                    if cb then
                        cb()
                    end
                    return
                end

                XUiManager.TipMsg(CS.XTextManager.GetText("GuildAcceptSucceed", playerName))
                GuildApplyListDatas[playId] = nil
                if cb then
                    cb()
                end
            end)
    end

    -- 公会踢人
    function XGuildManager.GuildKickMember(playerId, cb)
        if XDataCenter.GuildWarManager.CheckActivityIsInTime() and XDataCenter.GuildWarManager.CheckRoundIsInTime() then
            XUiManager.TipText("GuildWarCantKickMember")
            return
        end
        XNetwork.Call(GuildRpc.GuildKickMember, { OtherId = playerId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                GuildData:RemoveMember(playerId)
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_UPDATE_MEMBER_INFO)
                if cb then
                    cb()
                end
            end)
    end

    --获取公会推荐列表请求
    function XGuildManager.GuildListRecommendRequest(pageNo, cb)
        XNetwork.Call(GuildRpc.GuildListRecommend, { PageNo = pageNo }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XGuildManager.PreRequestRecommendTime = XTime.GetServerNowTimestamp()
                XGuildManager.HandleGuildRecommendDatas(pageNo, res.Datas)
                GuildJoinCdEnd = res.JoinCdEnd
                if cb then
                    cb()
                end
            end)
    end

    function XGuildManager.GetGuildJoinCdEnd()
        return GuildJoinCdEnd
    end

    -- 公会搜索
    function XGuildManager.GuildFind(guildname, cb)
        XNetwork.Call(GuildRpc.GuildFind, { GuildName = guildname }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                XGuildManager.HandleGuildFindDatas(guildname, res.GuildList)

                if cb then
                    cb()
                end
            end)
    end

    --迎新语，检测屏蔽词
    function XGuildManager.GuildChangeScriptRequest(scripts, selects, autoChat, cb)
        XNetwork.Call(GuildRpc.GuildChangeScript, { Scripts = scripts }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                for i= 1, #scripts do
                    if res.Scripts and res.Scripts[i] ~= nil and res.Scripts[i] ~= "" then
                        scripts[i] = res.Scripts[i]
                    end
                end
                local scriptsData = {}
                local exist = false
                for index, data in pairs(scripts) do
                    scriptsData[index] = {}
                    scriptsData[index].WelcomeWord = data
                    scriptsData[index].Select = selects[index]
                    exist = exist or selects[index]
                end
                autoChat = autoChat and exist
                XDataCenter.GuildManager.SetGuildScriptDatas(scriptsData, autoChat)
                XUiManager.TipText("GuildWelcomeWordSuccessTips")
                if cb then
                    cb()
                end
            end)
    end

    --获取当前自定义话术 暂时弃用
    -- function XGuildManager.GuildListScriptRequest(cb)
    --     XNetwork.Call(GuildRpc.GuildListScript, {}, function(res)
    --         if res.Code ~= XCode.Success then
    --             XUiManager.TipCode(res.Code)
    --             return
    --         end

    --         XGuildManager.HandleGuildScriptDatas(res.Scripts, res.AutoChat)
    --         if cb then
    --             cb()
    --         end
    --     end)
    -- end

    --获取已发布心愿列表
    function XGuildManager.GuildListWishRequest(cb)
        XNetwork.Call(GuildRpc.GuildListWish, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                XGuildManager.HandleListWishDatas(res.WishesData, res.WishCount, res.WishContributeCount)
                if cb then
                    cb()
                end
            end)
    end

    -- 公会天赋
    function XGuildManager.GuildTalentListReq(func)
        XNetwork.Call(GuildRpc.GuildListTalent, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end

                TalentPoint = res.Point
                TalentLevels = {}
                local talentSumLevel = 0
                for id, level in pairs(res.Talents or {}) do
                    TalentLevels[id] = level
                    talentSumLevel = talentSumLevel + level
                end
                GuildData.TalentSumLevel = talentSumLevel
                if func then
                    func()
                end
            end)
    end

    -- 公会天赋升级
    function XGuildManager.GuildUpgradeTalent(talentId, func)
        XNetwork.Call(GuildRpc.GuildUpgradeTalent, { Id = talentId }, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                GuildData.TalentSumLevel = GuildData.TalentSumLevel + 1
                TalentPoint = res.Point
                -- if not TalentLevels[talentId] then
                --     TalentLevels[talentId] = 0
                -- end
                -- local oldLevel = TalentLevels[talentId]
                -- TalentLevels[talentId] = oldLevel + 1

                if func then
                    func()
                end
            end)
    end

    function XGuildManager.GetTalentPoint()
        return TalentPoint
    end

    function XGuildManager.GetTalentLevel(id)
        return TalentLevels[id] or 0
    end

    -- 是否解锁
    function XGuildManager.IsTalentUnlock(id)
        local talentTemplate = XGuildConfig.GetGuildTalentById(id)
        if not talentTemplate then return false end
        local curGuildLevel = XGuildManager.GetGuildLevel()
        return curGuildLevel >= talentTemplate.GuildLevel
    end

    function XGuildManager.IsTalentMaxLevel(id)
        local curLevel = XGuildManager.GetTalentLevel(id)
        local talentTemplate = XGuildConfig.GetGuildTalentById(id)
        if not talentTemplate then return false end
        return talentTemplate.CostPoint[curLevel + 1] == nil
    end

    function XGuildManager.CheckAllTalentLevelMax()
        if XGuildManager.IsGuildLevelMax(XGuildManager.GetGuildLevel()) then --or
            -- XGuildManager.GetTalentPointFromBuild() > 0 then
            if TalentLevelCount == 0 then
                local sum = 0
                local points = XGuildConfig.GetSortedTalentPoints()
                for _, v in pairs(points) do
                    local talentTemplate = XGuildConfig.GetGuildTalentById(v.Id)
                    sum = sum + #talentTemplate.CostPoint
                end
                TalentLevelCount = sum
            end
            return GuildData.TalentSumLevel == TalentLevelCount
        end
        return false
    end

    -- 能否升级:是否解锁、父节点、消耗,最高级
    function XGuildManager.CanTalentUpgrade(id)
        if not XGuildManager.IsTalentUnlock(id) then return false end
        local curLevel = XGuildManager.GetTalentLevel(id)
        local talentTemplate = XGuildConfig.GetGuildTalentById(id)
        if not talentTemplate then return false end

        if not XGuildManager.CheckParentTalent(id) then
            return false
        end

        local cost = talentTemplate.CostPoint[curLevel + 1] or 0
        return TalentPoint >= cost
    end

    -- 前置条件检查
    function XGuildManager.CheckParentTalent(id)
        local talentTemplate = XGuildConfig.GetGuildTalentById(id)
        if not talentTemplate then return false end

        local preUnlock = false
        local preAllZero = true
        local curLevel = XGuildManager.GetTalentLevel(id)
        for i = 1, #talentTemplate.Parent do
            local preId = talentTemplate.Parent[i]
            local preLevel = XGuildManager.GetTalentLevel(preId)
            if preId > 0 then
                preAllZero = false
                if preLevel > curLevel then
                    preUnlock = true
                    break
                end
            end
        end

        if not preAllZero then
            return preUnlock
        end
        return true
    end

    -- 父节点是否都为0
    function XGuildManager.IsTalentParentAllZero(id)
        local talentTemplate = XGuildConfig.GetGuildTalentById(id)
        if not talentTemplate then return false end

        local allZero = true
        for i = 1, #talentTemplate.Parent do
            if talentTemplate.Parent[i] > 0 then
                allZero = false
                break
            end
        end
        return allZero
    end

    -- 公会日常任务
    function XGuildManager.GetSortedGuildDailyTasks()
        local tasks = XDataCenter.TaskManager.GetGuildDailyFullTaskList()
        -- 是否需要排序
        for _, v in pairs(tasks or {}) do
            v.SortWeight = 2
            if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                v.SortWeight = 1
            elseif v.State == XDataCenter.TaskManager.TaskState.Finish or v.State == XDataCenter.TaskManager.TaskState.Invalid then
                v.SortWeight = 3
            end
        end

        table.sort(tasks, function(taskA, taskB)
                if taskA.SortWeight == taskB.SortWeight then
                    return taskA.Id < taskB.Id
                end
                return taskA.SortWeight < taskB.SortWeight
            end)
        return tasks
    end

    -- 是否有购买的权限
    function XGuildManager.CheckShopBuyAccess(shopId)
        if shopId == XGuildConfig.GuildPurchaseShop then
            return XGuildManager.IsGuildAdminister()
        end
        return true
    end

    -- 是否可以领取贡献奖励
    function XGuildManager.CanCollectContributeReward()
        if XGuildManager.IsGuildTourist() then return false end

        return HasContributeReward == 1
    end

    -- 获取公会排名
    function XGuildManager.GuildListRankRequest(order, cb)
        XNetwork.Call(GuildRpc.GuildListRank, { Order = order}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XGuildManager.HandleListRankDatas(order, res.RankList, res.MyRankNum)
                if cb then
                    cb()
                end
            end)
    end
    -- 是否紧急维护状态
    function XGuildManager.IsUrgentMaintainState()
        return GuildData.MaintainState == XGuildConfig.GuildMaintainState.Urgent
    end

    -- 紧急状态开始时间
    function XGuildManager.GetEmergenceTime()
        return GuildData.EmergenceTime
    end

    -- 获取建设度
    function XGuildManager.GetBuild()
        return GuildData.Build
    end

    -- 获取申请设置
    function XGuildManager.GetApplyOption()
        return GuildData.Option
    end

    -- 获取最低等级
    function XGuildManager.GetMinLevelOption()
        return GuildData.MinLevel
    end

    -- 获取最高等级获得的天赋点
    function XGuildManager.GetTalentPointFromBuild()
        return GuildData.TalentPointFromBuild or 0
    end

    -- 获取当前荣耀等级
    function XGuildManager.GetGloryLevel()
        local level = math.modf( GuildData.TalentPointFromBuild / XGuildConfig.GloryPointsPerLevel)
        return level > XGuildConfig.GuildGloryMaxLevel and XGuildConfig.GuildGloryMaxLevel or level
    end

    -- 礼包是否可以领取
    function XGuildManager.CanCollectGift(giftLevel)
        if XGuildManager.IsGuildTourist() then return false end
        if not XGuildManager.IsJoinGuild() then return false end

        local lastGuildId = XGuildManager.GetGiftGuildGot()
        local curGuildId = XGuildManager.GetGuildId()
        if lastGuildId > 0 and lastGuildId ~= curGuildId then
            return false
        end

        local giftGuildLevel = XGuildManager.GetGiftGuildLevel()
        local giftLevelGots = XGuildManager.GetGiftLevelGot()
        if giftLevelGots[giftLevel] then return false end

        local giftData = XGuildConfig.GetGuildGiftByGuildLevelAndGiftLevel(giftGuildLevel, giftLevel)
        if not giftData then return false end

        local giftContribute = XGuildManager.GetGiftContribute()
        if giftContribute < giftData.GiftContribute then
            return false
        end

        return true
    end

    -- 公会礼包贡献进度
    function XGuildManager.GetGiftContribute()
        return GuildData.GiftContribute
    end

    -- 礼包刷新时的公会等级
    function XGuildManager.GetGiftGuildLevel()
        return GuildData.GiftGuildLevel
    end

    -- 礼包当前等级
    function XGuildManager.GetGiftLevel()
        return GuildData.GiftLevel
    end

    -- 玩家已领取的礼包等级
    function XGuildManager.GetGiftLevelGot()
        return GuildData.GiftLevelGot
    end

    -- 玩家在哪个公会领过礼包
    function XGuildManager.GetGiftGuildGot()
        return GuildData.GiftGuildGot
    end

    -- 当前剩余的贡献值
    function XGuildManager.GetGuildContributeLeft()
        return GuildData.GuildContributeLeft
    end

    -- 公会id
    function XGuildManager.GetGuildId()
        return GuildData.GuildId
    end

    -- 公会名字
    function XGuildManager.GetGuildName()
        return GuildData.GuildName
    end

    -- 公会等级
    function XGuildManager.GetGuildLevel()
        return GuildData.GuildLevel
    end

    function XGuildManager.GetGuildContributeIn7Days()
        return GuildData.GuildContributeIn7Days
    end

    -- 判断公会等级是否提升
    function XGuildManager.CheckGuildLevelUp()
        if not XGuildManager.IsJoinGuild() then return false end
        if XLuaUiManager.IsUiShow("UiGuildLevelUp") then return false end
        local curLevel = XGuildManager.GetGuildLevel()
        local lastLevel = XGuildManager.GetLastLevel()
        -- -1 表示换了公会或未保存过
        if lastLevel == -1 then
            XGuildManager.SaveGuildLevel()
            return false
        end
        if lastLevel < curLevel then
            GuildData.GuildLastLevel = lastLevel
            XLuaUiManager.Open("UiGuildLevelUp",lastLevel, curLevel, function()
                    XGuildManager.SaveGuildLevel(curLevel)
                end)
            return true
        end
        return false
    end

    --最后一次保存的等级
    function XGuildManager.GetLastLevel()
        return GuildData.GuildLastLevel or XGuildManager.GetGuildPrefs(XGuildConfig.KEY_LAST_LEVEL, -1)
    end

    -- 保存当前等级
    function XGuildManager.SaveGuildLevel(level)
        local curLevel = level or XGuildManager.GetGuildLevel()
        XGuildManager.SaveGuildPrefs(XGuildConfig.KEY_LAST_LEVEL,  curLevel)
        GuildData.GuildLastLevel = curLevel
    end

    -- 公会等级是否达到最大（是否满级）
    function XGuildManager.IsGuildLevelMax(level)
        local isMax = false
        local levelData = XGuildConfig.GetGuildLevelDataBylevel(level)
        if not levelData then return isMax end

        local nextLevel = level + 1
        local nextLevelData = XGuildConfig.GetGuildLevelDataBylevel(nextLevel)
        if not nextLevelData then
            isMax = true
        end

        return isMax
    end

    function XGuildManager.GetGuildExpAmount()
        local GuildBuildIntervalWhenMaxLevel = CS.XGame.Config:GetInt("GuildBuildIntervalWhenMaxLevel")
        local guildLevel = XGuildManager.GetGuildLevel()
        local fillAmount = 0
        if XGuildManager.IsGuildLevelMax(guildLevel) then
            -- 达到最高等级
            fillAmount = XGuildManager.GetBuild() * 1.0 / GuildBuildIntervalWhenMaxLevel
        else
            local data = XGuildConfig.GetGuildLevelDataBylevel(guildLevel)
            local max = data and data.Build
            -- 未到达最高等级
            fillAmount = XGuildManager.GetBuild() * 1.0 / (max and max > 0 and max or 1)
        end
        return fillAmount
    end
    -- 保存本地数据
    function XGuildManager.SaveGuildPrefs(key, value, type)
        local guildId = XGuildManager.GetGuildId()
        if XPlayer.Id and guildId then
            key = string.format("%s_%s_%s", key, tostring(XPlayer.Id), tostring(guildId))
            if type == DataType.String then
                CS.UnityEngine.PlayerPrefs.SetString(key, value)
            else
                CS.UnityEngine.PlayerPrefs.SetInt(key, value)
            end
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    -- 获取本地数据
    function XGuildManager.GetGuildPrefs(key, defaultValue, type)
        local guildId = XGuildManager.GetGuildId()
        if XPlayer.Id and guildId then
            key = string.format("%s_%s_%s", key, tostring(XPlayer.Id), tostring(guildId))
            if CS.UnityEngine.PlayerPrefs.HasKey(key) then
                local guildPref = nil
                if type == DataType.String then
                    guildPref = CS.UnityEngine.PlayerPrefs.GetString(key)
                else
                    guildPref = CS.UnityEngine.PlayerPrefs.GetInt(key)
                end
                return (guildPref == nil or guildPref == 0) and defaultValue or guildPref
            end
        end
        return defaultValue
    end

    -- 公会宣言
    function XGuildManager.GetGuildDeclaration()
        return GuildData.GuildDeclaration
    end

    -- 公会内部通讯
    function XGuildManager.GetGuildInterCom()
        return GuildData.GuildInterCom
    end

    -- 公会图标
    function XGuildManager.GetGuildIconId()
        local headPortrait = XGuildConfig.GetGuildHeadPortraitById(GuildData.GuildIconId)
        if not headPortrait then return nil end
        return headPortrait.Icon
    end

    function XGuildManager.GetGuildHeadPortrait()
        return GuildData.GuildIconId
    end

    -- 会长名字
    function XGuildManager.GetGuildLeaderName()
        return GuildData.GuildLeaderName
    end

    -- 会员数量
    function XGuildManager.GetMemberCount()
        return GuildData.GuildMemberCount
    end

    -- 会员在线数量
    function XGuildManager.GetOnlineMemberCount()
        local onlineCount = 0
        local allMembers = GuildData:GetGuildMembers()
        for _, member in pairs(allMembers or {}) do
            if member.OnlineFlag == 1 then
                onlineCount = onlineCount + 1
            end
        end
        return onlineCount
    end

    -- 会员最大数量
    function XGuildManager.GetMemberMaxCount()
        return GuildData.GuildMemberMaxCount
    end

    -- 是否可以弹劾会长
    function XGuildManager.CanImpeachLeader()
        return CanImpeach
    end

    -- 是否弹劾过会长
    function XGuildManager.HasImpeachLeader()
        return HasImpeach
    end

    -- 设置弹劾过会长
    function XGuildManager.SetImpeachLeader()
        HasImpeach = true
    end

    -- 获取成员
    function XGuildManager.GetMemberList()
        return GuildData:GetGuildMembers()
    end

    -- 获取成员(游客)
    function XGuildManager.GetVistorMemberList(guildid)
        return GuildVistorInfoDatas[guildid]:GetGuildMembers()
    end

    -- 清掉获取成员
    function XGuildManager.ClearVistorGuildMembers(guildid)
        if GuildVistorInfoDatas[guildid] then
            GuildVistorInfoDatas[guildid]:ClearGuildMembers()
        end
    end

    -- 推荐页数
    function XGuildManager.GetRecommendPageNo()
        RecommendPageNo = RecommendPageNo % 10 + 1
        return RecommendPageNo
    end

    -- 自定义职位{Id = Name}
    function XGuildManager.GetAllRankNames()
        return GuildData.DecodeRankNames
    end

    function XGuildManager.GetRankNameByLevel(level)
        return GuildData:GetRankNameByLevel(level)
    end

    -- 查看申请者列表
    function XGuildManager.GetGuildApplyList()
        return GuildApplyListDatas
    end

    -- 重置申请信息
    function XGuildManager.ResetApplyMemberList()
        HasApplyMember = false
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_APPLY_LIST_CHANGED)
    end

    -- 是否有申请信息
    function XGuildManager.GetHasApplyMemberList()
        if XGuildManager.IsGuildTourist() or not XGuildManager.IsGuildAdminister() then return false end
        return HasApplyMember
    end

    -- 获取保存公会聊天缓存的key
    function XGuildManager.GetGuildChannelKey(guildId)
        return string.format("GuildKey_%s_%s", tostring(XPlayer.Id), tostring(guildId))
    end

    -- 查看是否有招募
    function XGuildManager.HasGuildRecruitList()
        return HasGuildRecruit
    end

    -- 重置招募列表
    function XGuildManager.ResetGuildRecruit()
        if HasGuildRecruit then
            HasGuildRecruit = false
            XEventManager.DispatchEvent(XEventId.EVENT_GUILD_RECRUIT_LIST_CHANGED)
        end
    end

    -- 查询免费改名机会
    function XGuildManager.GetFreeChangeGuildName()
        return FreeChangeGuildNameCount > 0
    end

    -- 使用免费改名机会
    function XGuildManager.SetFreeChangeGuildNameCount()
        if FreeChangeGuildNameCount > 0 then
            FreeChangeGuildNameCount = FreeChangeGuildNameCount - 1
        end
    end

    -- 获取工会boss结束时间
    function XGuildManager.GuildBossEndTime()
        return GuildData.BossEndTime
    end

    -- 更新工会boss结束时间
    function XGuildManager.SetGuildBossEndTime(val)
        if val then
            GuildData.BossEndTime = val
        else
            XLog.Warning("SetGuildBossEndTime(val) Failed")
        end
    end

    --获取当前迎新语
    function XGuildManager.GetGuildScriptDatas()
        if not next(GuildScriptListDatas) then
            GuildScriptListDatas = {}
            for i = 1, XGuildConfig.GuildDefaultWelcomeWord do
                local key = string.format("%s_%d_%d", GuildWelcomeWordKey, XPlayer.Id, i)
                if not CS.UnityEngine.PlayerPrefs.HasKey(key) then
                    break
                end
                GuildScriptListDatas[i] = {}
                GuildScriptListDatas[i].WelcomeWord = CS.UnityEngine.PlayerPrefs.GetString(key ,nil)
                key = string.format("%s_%d_%d", GuildWelcomeSelectKey, XPlayer.Id, i)
                GuildScriptListDatas[i].Select = (CS.UnityEngine.PlayerPrefs.GetInt(key, 0) == 1)
            end
            if not next(GuildScriptListDatas) then
                GuildScriptListDatas = XGuildConfig.GetDefaultWelcomeWords()
            end
        end
        return GuildScriptListDatas
    end

    function XGuildManager.HandleGuildScriptSelectedDatas(scriptsData)
        GuildScriptSelectedDatas = {}
        for _, v in pairs(scriptsData) do
            if v.Select then
                table.insert(GuildScriptSelectedDatas, v.WelcomeWord)
            end
        end
    end

    function XGuildManager.GetGuildScriptSelectedDatas()
        if GuildScriptSelectedDatas == nil or next(GuildScriptSelectedDatas) == nil then
            local scriptsData = XGuildManager.GetGuildScriptDatas()
            XGuildManager.HandleGuildScriptSelectedDatas(scriptsData)
        end
        return GuildScriptSelectedDatas
    end

    --处理迎新语数据（可以优化，用XSaveTool.SaveData方法）
    function XGuildManager.SetGuildScriptDatas(scriptsData, autoChat)
        GuildScriptListDatas = {}
        if scriptsData and next(scriptsData) then
            for k, v in pairs(scriptsData) do
                if v then
                    table.insert(GuildScriptListDatas, v)
                    local key = string.format("%s_%d_%d", GuildWelcomeWordKey, XPlayer.Id, k)
                    CS.UnityEngine.PlayerPrefs.SetString(key, v.WelcomeWord)
                    key = string.format("%s_%d_%d", GuildWelcomeSelectKey, XPlayer.Id, k)
                    CS.UnityEngine.PlayerPrefs.SetInt(key, v.Select and 1 or 0)
                end
            end
            XGuildManager.HandleGuildScriptSelectedDatas(scriptsData)
        end
        GuildScriptAutoChat = autoChat
        local key = string.format("%s_%d", GuildWelcomeAutoChatKey, XPlayer.Id)
        CS.UnityEngine.PlayerPrefs.SetInt(key, GuildScriptAutoChat and 1 or 0)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    function XGuildManager.GetGuildScriptAutoChat()
        if GuildScriptAutoChat == nil then
            local key = string.format("%s_%d", GuildWelcomeAutoChatKey, XPlayer.Id)
            -- 是否自动喊话，默认开启
            GuildScriptAutoChat = (CS.UnityEngine.PlayerPrefs.GetInt(key, 1) == 1)
        end
        return GuildScriptAutoChat
    end

    function XGuildManager.InitGuildCustomNameTable()
        GuildCustomName = {}
        for _, v in pairs(XGuildConfig.GuildRankLevel) do
            GuildCustomName[v] = {}
        end
        local templates = XTool.Clone(XGuildConfig.GetCustomNameTemplate())
        local list = {}
        for index, template in pairs(templates) do
            if template.Enable then
                template.Id = index
                table.insert(list, template)
            end
        end
        table.sort(list, function(itemA, itemB)
                return itemA.Id < itemB.Id
            end)
        for k, v in pairs(list) do
            table.insert(GuildCustomName[v.RankLevel], v.Name)
        end
    end

    function XGuildManager.GetGuildCustomName()
        if not next(GuildCustomName) then
            XGuildManager.InitGuildCustomNameTable()
        end
        return GuildCustomName
    end

    function XGuildManager.GetMemberDataByPlayerId(playerId)
        if GuildData == nil then
            return nil
        end
        local member = GuildData:GetGuildMembers()[playerId]
        return member
    end

    XGuildManager.Init()
    return XGuildManager
end

-- 上线时推送公会数据
XRpc.NotifyGuildData = function(notifyData)
    XDataCenter.GuildManager.AsyncGuildData(notifyData)
end

-- 推送公会事件
XRpc.NotifyGuildEvent = function(notifyData)
    XDataCenter.GuildManager.AsyncGuildEvent(notifyData)
end

XRpc.NotifyRankName = function(notifyData)
    XDataCenter.GuildManager.AsyncGuildRankName(notifyData)
end

XRpc.NotifyGuildMaintain = function(notifyData)
    XDataCenter.GuildManager.AsyncGuildMaintain(notifyData)
end

XRpc.NotifyGuildImpeach = function(notifyData)
    XDataCenter.GuildManager.AsyncGuildImpeach(notifyData)
end