XFubenRogueLikeManagerCreator = function()

    local XFubenRogueLikeManager = {}

    local RogueLikeRpc = {
        GetBlackShopData = "GetBlackShopDataRequest", --获取黑市商店数据
        BuyBlackShopItem = "BuyBlackShopItemRequest", --黑市商店购买
        FinishNode = "FinishNodeRequest", --完成节点
        OpenBox = "OpenBoxRequest", --打开宝箱
        Recover = "RecoverRequest", --休息点回复行动力
        IntensifyBuff = "IntensifyBuffRequest", --增强buff
        SelectNode = "SelectNodeRequest", --选择节点
        NodeBuy = "NodeBuyRequest", --节点商店购买
        SelectSpecialEvent = "SelectSpecialEventRequest", --选择特殊事件
        SupportCall = "SupportCallRequest", --支援请求
        SelectSpecialEventGroup = "SelectSpecialEventGroupRequest", --选择特殊事件组
        TeamSet = "RogueLikeTeamSetRequest", --设置队伍
        ResetHardNode = "ResetHardNodeRequest",--重置副本次数
        OpenTrialPoint = "OpenTrialPointRequest",--刷新试炼积分信息
    }
    local CheckUiName = {
        [1] = "UiRogueLikeMain",
        [2] = "UiRogueLikeHelpRole",
        [3] = "UiRogueLikeIllegalShop",
        [4] = "UiRogueLikeObtainBuff",
        [5] = "UiRogueLikeRoomCharacter",
        [6] = "UiRogueLikeShop",
        [7] = "UiRogueLikeStoryResult",
        [8] = "UiRogueLikeThemeTips",
        [9] = "UiRogueLikeTask",
        [10] = "UiRogueLikeFightTips",
    }

    -- 活动信息
    local ActivityId                        -- 活动id
    local CurSectionId = 0                  -- 当前章节
    local ActionPoint = 0
    local SectionInfo = {}                  -- 选择的节点信息//TierSectionInfo
    local AssistRobots = {}                 -- 助战机器人//int
    local BuffIds = {}                      -- 获得的buff//int
    local CharacterInfos = {}               -- 参战列表//RLCharacterInfo
    local NodeShopInfos = {}                -- 节点商店信息//RLNodeShopInfo
    -- local DayBuffIds = {}                   -- 每日buff//int
    local TeamEffectId = 0                  -- 队伍效果id
    local DayRefreshTime = 0                -- 每日刷新时间
    local WeekRefreshTime = 0               -- 每周刷新时间
    local SupportInfos = {}                 -- 支援终端
    local NewBuffIds = {}                   -- 最新获得的buff,用来显示
    local NewRobots = {}                    -- 最新获得的支援角色,显示用
    local ShowSelectNodeInfo = {}           -- 选择过的节点//[nodeId = nodeInfo]
    local IsFinal = false                   -- 是否为最后的层级
    local HistoryMaxTier = 0                -- 历史达到最高层数

    local Id2SectionMap = {}                -- SecionId对应SectionInfo
    local RogueLikeStageRobots = {}         -- 助战阵容{stageId = {IsAssis=,RobotId}}

    local RogueLikeTrialPoint = 0           --试炼模式积分
    local RogueLikeResetNum = 0             --重置试炼次数
    local NeedShowTrialTips = false         --是否需要显示试炼开启
    local TrialPointDatas = {}
    local NeedShowTrialPointView = false         --是否需要显示积分页面
    local RogueLikeTrialPointLast = -1
    local RogueLikeTrialPointShowByTween = 0

    function XFubenRogueLikeManager.InitStageInfo()
        local allNodes = XFubenRogueLikeConfig.GetAllNodes()
        for _, nodeDatas in pairs(allNodes) do
            if nodeDatas.Type == XFubenRogueLikeConfig.XRLNodeType.Fight then
                local stageId = nodeDatas.Param[1]
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.RogueLike
                end
                local stageDiffcultId = nodeDatas.Param[2]
                if stageDiffcultId and stageDiffcultId > 0 then
                    local stageDiffcultInfo = XDataCenter.FubenManager.GetStageInfo(stageDiffcultId)
                    if stageDiffcultInfo then
                        stageDiffcultInfo.Type = XDataCenter.FubenManager.StageType.RogueLike
                    end
                end
            end
        end
    end

    -- [胜利]
    function XFubenRogueLikeManager.ShowReward(winData)
        if not winData then return end
        XLuaUiManager.Open("UiSettleWin", winData)
    end

    function XFubenRogueLikeManager.AsyncRogueLikeInfo(notifyData)
        if not notifyData then return end
        ActivityId = notifyData.Id
        CurSectionId = notifyData.CurSectionId
        ActionPoint = notifyData.ActionPoint
        SectionInfo = notifyData.SectionInfo
        AssistRobots = notifyData.AssistRobots
        RogueLikeTrialPoint = notifyData.TrialPoint
        RogueLikeResetNum = notifyData.HardNodeResetCount
        
        if RogueLikeTrialPointLast > -1 and RogueLikeTrialPointLast < RogueLikeTrialPoint then
            RogueLikeTrialPointShowByTween = RogueLikeTrialPointLast
        end
        RogueLikeTrialPointLast = RogueLikeTrialPoint

        if not next(AssistRobots) then
            XFubenRogueLikeManager.ResetNewRobots()
        end
        BuffIds = notifyData.BuffIds
        if not next(BuffIds) then
            XFubenRogueLikeManager.ResetNewBuffs()
        end
        CharacterInfos = notifyData.CharacterInfos
        HistoryMaxTier = notifyData.MaxTier

        NodeShopInfos = {}
        for i = 1, #notifyData.ShopInfos do
            local shopInfo = notifyData.ShopInfos[i]
            NodeShopInfos[shopInfo.Id] = shopInfo
        end

        TeamEffectId = notifyData.TeamEffectId
        DayRefreshTime = math.floor(notifyData.DayRefreshTime)
        WeekRefreshTime = math.floor(notifyData.WeekRefreshTime)

        SupportInfos = {}
        for _, v in pairs(notifyData.SupportInfos or {}) do
            SupportInfos[v.Id] = v.Count
        end

        for k, v in pairs(SectionInfo) do
            Id2SectionMap[v.Id] = {}
            Id2SectionMap[v.Id].Index = k
            Id2SectionMap[v.Id].Id = v.Id
            Id2SectionMap[v.Id].Group = v.Group

            Id2SectionMap[v.Id].FinishNode = {}
            for _, node in pairs(v.FinishNode or {}) do
                Id2SectionMap[v.Id].FinishNode[node] = true
            end

            Id2SectionMap[v.Id].SelectNodeInfo = {}
            for _, nodeInfo in pairs(v.SelectNodeInfos or {}) do
                Id2SectionMap[v.Id].SelectNodeInfo[nodeInfo.SelectId] = nodeInfo
            end
        end

        -- 日重置、 周重置刷新界面
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_REFRESH_ALLNODES)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_ACTIONPOINT_CHARACTER_CHANGED)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_ASSISTROBOT_CHANGED)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_BUFFIDS_CHANGES)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_TEAMEFFECT_CHANGES)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_TASK_RESET)

        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_ILLEGAL_SHOP_RESET)
        -- 检查是否需要重置角色
        XFubenRogueLikeManager.CheckCharacterReset()
    end

    function XFubenRogueLikeManager.AsyncBuffData(notifyData)
        if not notifyData then return end
        BuffIds = notifyData.BuffIds
        if notifyData.NewId > 0 then
            NewBuffIds[notifyData.NewId] = true
        end
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_BUFFIDS_CHANGES)
    end

    function XFubenRogueLikeManager.ResetDataByInPurgatory()
        NeedShowTrialTips = true
        BuffIds = {}
        XFubenRogueLikeManager.ResetNewBuffs()
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_BUFFIDS_CHANGES)
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_SECTIONTYPE_CHANGE)
    end

    -- 章节选择同步
    function XFubenRogueLikeManager.AsyncSectionInfoChange(notifyData)
        if not notifyData then return end
        local lastSectionType = XFubenRogueLikeConfig.GetTierSectionTierTypeById(CurSectionId) or 0
        CurSectionId = notifyData.CurSectionId
        local curSectionType = XFubenRogueLikeConfig.GetTierSectionTierTypeById(CurSectionId)
        if lastSectionType == XFubenRogueLikeConfig.TierType.Normal and curSectionType == XFubenRogueLikeConfig.TierType.Purgatory then
            XFubenRogueLikeManager.ResetDataByInPurgatory()
        end

        for k, v in pairs(SectionInfo) do
            if v.Id == notifyData.SectionInfo.Id then
                SectionInfo[k] = notifyData.SectionInfo
            end
        end

        local sectionId = notifyData.SectionInfo.Id
        Id2SectionMap[sectionId].FinishNode = {}
        for _, node in pairs(notifyData.SectionInfo.FinishNode or {}) do
            Id2SectionMap[sectionId].FinishNode[node] = true
        end

        Id2SectionMap[sectionId].SelectNodeInfo = {}
        for _, nodeInfo in pairs(notifyData.SectionInfo.SelectNodeInfos or {}) do
            Id2SectionMap[sectionId].SelectNodeInfo[nodeInfo.SelectId] = nodeInfo
        end
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_REFRESH_ALLNODES)
        IsFinal = XFubenRogueLikeManager.GetRogueLikeLevel() == XFubenRogueLikeManager.GetMaxTier()

        local currTier = XFubenRogueLikeManager.GetRogueLikeLevel()
        if currTier > HistoryMaxTier then
            HistoryMaxTier = currTier
        end
    end

    function XFubenRogueLikeManager.AsyncNodeShopInfo(notifyData)
        if not notifyData then return end
        local shopId = notifyData.ShopInfo.Id
        NodeShopInfos[shopId] = notifyData.ShopInfo

    end

    -- 通知助战机器人改变
    function XFubenRogueLikeManager.AsyncAssistRobot(notifyData)
        if not notifyData then return end

        local new_assisRobots = {}
        for _, robotId in pairs(notifyData.AssistRobots) do
            new_assisRobots[robotId] = true
        end
        for _, robotId in pairs(AssistRobots) do
            new_assisRobots[robotId] = nil
        end
        local receiveNewRobot = false
        local robot_names = ""
        for robotId, _ in pairs(new_assisRobots) do
            receiveNewRobot = true
            NewRobots[robotId] = true
            local characterId = XRobotManager.GetCharacterId(robotId)
            local fullName = XCharacterConfigs.GetCharacterFullNameStr(characterId)
            if robot_names == "" then
                robot_names = fullName
            else
                robot_names = string.format("%s %s", robot_names, fullName)
            end
        end
        if receiveNewRobot and robot_names ~= "" then
            XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeGetAssistRobot", robot_names))
        end

        AssistRobots = notifyData.AssistRobots
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_ASSISTROBOT_CHANGED)
    end

    -- 刷新行动点和角色信息
    function XFubenRogueLikeManager.AsyncActionPointAndCharacterInfo(notifyData)
        if not notifyData then return end
        local newActionPoint = notifyData.ActionPoint
        local isAdd = newActionPoint > ActionPoint
        ActionPoint = notifyData.ActionPoint

        RogueLikeTrialPoint = notifyData.TrialPoint
        
        if RogueLikeTrialPointLast > -1 and RogueLikeTrialPointLast < RogueLikeTrialPoint then
            RogueLikeTrialPointShowByTween = RogueLikeTrialPointLast
        end
        RogueLikeTrialPointLast = RogueLikeTrialPoint

        local newCharacterInfos = notifyData.CharacterInfos
        for i = 1, #newCharacterInfos do
            if newCharacterInfos[i] and CharacterInfos[i] then
                if newCharacterInfos[i].HpLeft ~= CharacterInfos[i].HpLeft then
                    newCharacterInfos[i].EffectUp = true
                end
            end
        end
        CharacterInfos = notifyData.CharacterInfos

        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_ACTIONPOINT_CHARACTER_CHANGED, isAdd)
    end

    -- 刷新队伍效果
    function XFubenRogueLikeManager.AsyncTeamEffect(notifyData)
        if not notifyData then return end
        TeamEffectId = notifyData.TeamEffectId

        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_TEAMEFFECT_CHANGES)
    end
    
    --刷新获得积分数据
    function XFubenRogueLikeManager.AsyncTrialPoint(notifyData)
        TrialPointDatas = notifyData.pointInfo or {}
        table.sort(TrialPointDatas,function(a,b)
            return a.PointType < b.PointType
        end)
        NeedShowTrialPointView = true
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_TRIALPOINT_CHANGE)
    end
    
    --刷新获得积分数据(回调)
    function XFubenRogueLikeManager.AsyncTrialPointRequest(pointInfo)
        TrialPointDatas = pointInfo
        table.sort(TrialPointDatas,function(a,b)
            return a.PointType < b.PointType
        end)
    end

    -- 活动id
    function XFubenRogueLikeManager.GetRogueLikeActivityId()
        return ActivityId
    end

    -- 行动点
    function XFubenRogueLikeManager.GetRogueLikeActionPoint()
        return ActionPoint
    end

    -- 日常buff
    function XFubenRogueLikeManager.GetRogueLikeDayBuffs()
        return XFubenRogueLikeManager.GetDayBuffByTeamEffect(TeamEffectId, CharacterInfos)
    end

    -- 锁定的出站角色
    function XFubenRogueLikeManager.GetCharacterInfos()
        return CharacterInfos
    end

    -- 如果有出站人数为3则视为已经锁定
    function XFubenRogueLikeManager.IsRogueLikeCharacterLock()
        return XFubenRogueLikeManager.GetTeamMemberCount() == #CharacterInfos
    end

    -- 助战机器人
    function XFubenRogueLikeManager.GetAssistRobots(characterType)
        local robots = {}

        for _, v in pairs(AssistRobots or {}) do
            local characterId = XRobotManager.GetCharacterId(v)
            local charType = XCharacterConfigs.GetCharacterType(characterId)
            if not characterType or charType == characterType then
                table.insert(robots, { Id = v })
            end
        end

        return robots
    end

    -- 助战角色达到3人则视为可以切换助战
    function XFubenRogueLikeManager.CanSwitch2Assist()
        return #AssistRobots >= XFubenRogueLikeManager.GetTeamMemberCount()
    end

    -- 获得助战人数,默认3
    function XFubenRogueLikeManager.GetTeamMemberCount()
        local activityId = XFubenRogueLikeManager.GetRogueLikeActivityId()
        if not activityId then return XFubenRogueLikeConfig.TEAM_NUMBER end

        local activityTemplate = XFubenRogueLikeConfig.GetRougueLikeTemplateById(activityId)
        if not activityTemplate then return XFubenRogueLikeConfig.TEAM_NUMBER end

        return activityTemplate.TeamMemberCount or XFubenRogueLikeConfig.TEAM_NUMBER
    end

    -- 当前章节
    function XFubenRogueLikeManager.GetCurSectionInfo()
        return Id2SectionMap[CurSectionId]
    end

    -- 获取当前活动最大层数
    function XFubenRogueLikeManager.GetMaxTier()
        local maxTier = 0
        local maxTierNormal = 0
        local maxTierPurgatory = 0
        local curSectionType = XFubenRogueLikeConfig.GetTierSectionTierTypeById(CurSectionId)

        for _, v in pairs(SectionInfo) do
            local tierSectionTemplate = XFubenRogueLikeConfig.GetTierSectionTemplateById(v.Id)
            if tierSectionTemplate.MaxTier > maxTier then
                if XFubenRogueLikeConfig.GetTierSectionTierTypeById(v.Id) == XFubenRogueLikeConfig.TierType.Normal then
                    maxTierNormal = tierSectionTemplate.MaxTier
                else
                    maxTierPurgatory = tierSectionTemplate.MaxTier
                end
                --maxTier = tierSectionTemplate.MaxTier
            end
        end
        maxTierPurgatory = maxTierPurgatory - maxTierNormal
        if XFubenRogueLikeManager.IsSectionPurgatory() then
            return maxTierPurgatory
        else
            return maxTierNormal
        end
        return maxTier
    end

    function XFubenRogueLikeManager.GetRogueLikeLevel()
        if not SectionInfo then return 0 end

        local rogueLikeLevel = 0
        local curSectionType = XFubenRogueLikeConfig.GetTierSectionTierTypeById(CurSectionId)
        for i = 1, #SectionInfo do
            local section = SectionInfo[i]
            if section and section.Id then
                local sectionType = XFubenRogueLikeConfig.GetTierSectionTierTypeById(section.Id)
                for _, v in pairs(section.FinishNode) do
                    local finishNode = Id2SectionMap[section.Id].FinishNode or {}
                    if finishNode[v] and curSectionType == sectionType then
                        rogueLikeLevel = rogueLikeLevel + 1
                    end
                end
            end
        end
        return rogueLikeLevel
    end

    -- 获取我的buffs//排序规则：新获得的(20) > 正面的(10) > 负面的(5)
    function XFubenRogueLikeManager.GetMyBuffs()
        local myBuffs = {}
        for _, v in pairs(BuffIds) do
            local buffConfig = XFubenRogueLikeConfig.GetBuffConfigById(v)

            local weight = 5
            if XFubenRogueLikeConfig.BuffType.PositiveBuff == buffConfig.BuffType then
                weight = 10
            end
            weight = XFubenRogueLikeManager.IsBuffNew(v) and 20 or weight
            table.insert(myBuffs, {
                BuffId = v,
                IsSelect = false,
                BuffType = buffConfig.BuffType,
                Priority = buffConfig.Priority,
                SortWeight = weight,
            })
        end
        table.sort(myBuffs, function(a, b)
            return a.BuffId < b.BuffId
        end)
        return myBuffs
    end

    -- 获得节点商店数据
    function XFubenRogueLikeManager.GetNodeShopInfoById(shopId)
        return NodeShopInfos[shopId]
    end

    -- 队伍效果id
    function XFubenRogueLikeManager.GetTeamEffectId()
        return TeamEffectId
    end

    -- 是否为队伍效果id中配置的角色
    function XFubenRogueLikeManager.IsTeamEffectCharacter(cid)
        local teamEffectId = XFubenRogueLikeManager.GetTeamEffectId()
        if XFubenRogueLikeManager.IsSectionPurgatory() then return false end
        if teamEffectId <= 0 then return false end

        local teamEffectTemplate = XFubenRogueLikeConfig.GetTeamEffectTemplateById(teamEffectId)
        if not teamEffectTemplate then
            return false
        end
        for _, characterId in pairs(teamEffectTemplate.CharacterId) do
            if characterId == cid then
                return true
            end
        end
        return false
    end

    -- 日刷新时间
    function XFubenRogueLikeManager.GetDayRefreshTime()
        return DayRefreshTime
    end

    -- 周刷新时间
    function XFubenRogueLikeManager.GetWeekRefreshTime()
        return WeekRefreshTime
    end

    -- 获取支援终端的东西
    function XFubenRogueLikeManager.GetSupportInfos()
        return SupportInfos
    end

    -- 是否有新的buffId
    function XFubenRogueLikeManager.HasNewBuffs()
        local newBuffCount = 0
        for _, _ in pairs(NewBuffIds) do
            newBuffCount = newBuffCount + 1
        end
        return newBuffCount
    end

    -- 重置新效果
    function XFubenRogueLikeManager.ResetNewBuffs()
        NewBuffIds = {}
    end

    -- 是否为新获得的buff
    function XFubenRogueLikeManager.IsBuffNew(buffId)
        return NewBuffIds[buffId]
    end

    -- 是否有新获得的支援角色
    function XFubenRogueLikeManager.HasNewRobots()
        local newRobotCount = 0
        for _, _ in pairs(NewRobots) do
            newRobotCount = newRobotCount + 1
        end
        return newRobotCount > 0
    end

    function XFubenRogueLikeManager.ResetNewRobots()
        NewRobots = {}
    end

    function XFubenRogueLikeManager.UpdateNewRobots(robotId)
        NewRobots[robotId] = nil
    end

    function XFubenRogueLikeManager.IsRobotNew(robotId)
        return NewRobots[robotId]
    end

    -- 获取是否选择过节点
    function XFubenRogueLikeManager.GetShowSelectNodeById(nodeId)
        return ShowSelectNodeInfo[nodeId]
    end

    -- 获得主题buff
    function XFubenRogueLikeManager.GetDayBuffByTeamEffect(id, characterInfos)
        local day_buffs = {}
        local teamEffectTemplate = XFubenRogueLikeConfig.GetTeamEffectTemplateById(id)
        if not teamEffectTemplate then
            return day_buffs
        end

        local lock_character = {}
        for _, characterInfo in pairs(characterInfos or {}) do
            lock_character[characterInfo.Id] = true
        end

        local buff_count = 0

        for _, characterId in pairs(teamEffectTemplate.CharacterId) do
            if lock_character[characterId] then
                buff_count = buff_count + 1
            end
        end

        for i, buffId in pairs(teamEffectTemplate.BuffId) do
            table.insert(day_buffs, {
                BuffId = buffId,
                IsActive = i <= buff_count
            })
        end

        return day_buffs
    end

    -- 获得折扣:队伍buff/系统buff
    function XFubenRogueLikeManager.GetNodeShopDiscount()
        -- 默认100，没有打折
        local discount = 100
        local curSectionType = XFubenRogueLikeConfig.GetTierSectionTierTypeById(CurSectionId)
        if curSectionType == XFubenRogueLikeConfig.TierType.Purgatory then
            return discount
        end
        for _, buffId in pairs(BuffIds) do
            local buffTemplate = XFubenRogueLikeConfig.GetBuffTemplateById(buffId)
            if buffTemplate then
                if buffTemplate.Discount > 0 and buffTemplate.Discount < discount then
                    discount = buffTemplate.Discount
                end
            end
        end

        local day_Buff = XFubenRogueLikeManager.GetDayBuffByTeamEffect(TeamEffectId, CharacterInfos)
        for _, buffInfo in pairs(day_Buff) do
            local buffTemplate = XFubenRogueLikeConfig.GetBuffTemplateById(buffInfo.BuffId)
            if buffTemplate and buffInfo.IsActive then
                if buffTemplate.Discount > 0 and buffTemplate.Discount < discount then
                    discount = buffTemplate.Discount
                end
            end
        end

        return discount
    end

    -- 是否在显示等级的时间段
    function XFubenRogueLikeManager.IsInActivity()
        local activityId = XFubenRogueLikeManager.GetRogueLikeActivityId()
        if not activityId then return false end
        local activityTemplate = XFubenRogueLikeConfig.GetRougueLikeTemplateById(activityId)
        if not activityTemplate then return false end
        local now = XTime.GetServerNowTimestamp()
        local beginTime, endTime = XFunctionManager.GetTimeByTimeId(activityTemplate.ActivityTimeId)
        if not beginTime or not endTime then return false end
        return now >= beginTime and now <= endTime
    end

    -- 是否在挑战时间
    function XFubenRogueLikeManager.IsInFight()
        local activityId = XFubenRogueLikeManager.GetRogueLikeActivityId()
        if not activityId then return false end
        local activityTemplate = XFubenRogueLikeConfig.GetRougueLikeTemplateById(activityId)
        if not activityTemplate then return false end
        local now = XTime.GetServerNowTimestamp()
        local beginTime = XFunctionManager.GetStartTimeByTimeId(activityTemplate.ActivityTimeId)
        local endTime = XFunctionManager.GetEndTimeByTimeId(activityTemplate.FightTimeId)
        if not beginTime or not endTime then return false end
        return now >= beginTime and now <= endTime
    end

    -- 获取入口数据
    function XFubenRogueLikeManager.GetRogueLikeSection()
        local sections = {}
        local activityId = XFubenRogueLikeManager.GetRogueLikeActivityId()
        if activityId and XFubenRogueLikeManager.IsInActivity() then
            local section = {
                Id = activityId,
                Type = XDataCenter.FubenManager.ChapterType.RogueLike,
                BannerBg = CS.XGame.ClientConfig:GetString("FubenRogueLikeBannerBg"),
            }

            table.insert(sections, section)
        end

        return sections
    end

    -- 选择特殊节点
    function XFubenRogueLikeManager.SelectSpecialEvent(nodeId, eventId, func)
        XNetwork.Call(RogueLikeRpc.SelectSpecialEvent, {
            NodeId = nodeId,
            EventId = eventId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if func then
                func()
            end
            -- response
            -- public XCode Code;
        end)
    end

    -- 神秘商店购买
    function XFubenRogueLikeManager.NodeBuy(nodeId, itemId, itemCount, func)
        XNetwork.Call(RogueLikeRpc.NodeBuy, {
            NodeId = nodeId,
            ItemId = itemId,
            Count = itemCount
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if func then
                func()
            end

            -- 奖励通知
            local shopItemTemplate = XFubenRogueLikeConfig.GetShopItemTemplateById(itemId)
            if not shopItemTemplate then return end

            if shopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Item then
                local list = {}
                table.insert(list, XRewardManager.CreateRewardGoodsByTemplate({ TemplateId = shopItemTemplate.Param[1], Count = shopItemTemplate.Param[2] or 1 }))
                XUiManager.OpenUiObtain(list)
            elseif shopItemTemplate.Type == XFubenRogueLikeConfig.XRLShopItemType.Buff then
                local buffIds = {}
                table.insert(buffIds, {
                    Id = shopItemTemplate.Param[1]
                })
                XLuaUiManager.Open("UiRogueLikeObtainBuff", buffIds)
            end

        end)
    end

    -- 选择节点
    function XFubenRogueLikeManager.SelectNode(nodeId, func)
        XNetwork.Call(RogueLikeRpc.SelectNode, {
            NodeId = nodeId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            -- 记下选择过的节点{Id，SelectId, Value, SubValue}
            if res.SelectInfo then
                ShowSelectNodeInfo[res.SelectInfo.SelectId] = res.SelectInfo
            end

            if func then
                func()
            end
            -- response
            -- public XCode Code;
        end)
    end

    -- 增强buff
    function XFubenRogueLikeManager.IntensifyBuff(nodeId, buffId, func)
        XNetwork.Call(RogueLikeRpc.IntensifyBuff, {
            NodeId = nodeId,
            BuffId = buffId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            local buffTemplate = XFubenRogueLikeConfig.GetBuffTemplateById(buffId)
            local update_buffs = {}
            for _, v in pairs(BuffIds or {}) do
                if v ~= buffId and v ~= buffTemplate.IntensifyId then
                    table.insert(update_buffs, v)
                end
            end
            if buffTemplate.IntensifyId > 0 then
                table.insert(update_buffs, buffTemplate.IntensifyId)
            end
            BuffIds = update_buffs
            XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_BUFFIDS_CHANGES)

            if func then
                func()
            end
            -- response
            -- public XCode Code;
        end)
    end

    -- 休息点回复行动力
    function XFubenRogueLikeManager.Recover(nodeId, func)
        XNetwork.Call(RogueLikeRpc.Recover, {
            NodeId = nodeId,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if func then
                func()
            end
            -- response
            -- public XCode Code;
        end)
    end

    -- 打开宝箱
    function XFubenRogueLikeManager.OpenBox(nodeId, eventNode, func)
        XNetwork.Call(RogueLikeRpc.OpenBox, {
            NodeId = nodeId,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 判断宝箱类型
            local nodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(eventNode.Id)
            for i = 1, #nodeTemplate.Param do
                local boxId = nodeTemplate.Param[i]
                local boxTemplate = XFubenRogueLikeConfig.GetBoxTemplateById(boxId)
                if boxTemplate.Type == XFubenRogueLikeConfig.XRLBoxType.Item then
                    if func then
                        func()
                    end
                    XUiManager.OpenUiObtain(res.RewardGoodsList or {})
                elseif boxTemplate.Type == XFubenRogueLikeConfig.XRLBoxType.Buff then
                    local buffIds = {}
                    for i2 = 1, #boxTemplate.Param do
                        table.insert(buffIds, {
                            Id = boxTemplate.Param[i2]
                        })
                    end
                    XLuaUiManager.Open("UiRogueLikeObtainBuff", buffIds)
                    if func then
                        func()
                    end
                end
                break
            end

            -- response
            -- public XCode Code;
            -- public List<XRewardGoods> RewardGoodsList;
        end)
    end

    -- 完成节点:离开
    function XFubenRogueLikeManager.FinishNode(nodeId, func)
        XNetwork.Call(RogueLikeRpc.FinishNode, {
            NodeId = nodeId,
        }, function(res)
            
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if func then
                func(res)
            end
            -- response
            -- public XCode Code;
        end)
    end

    -- 黑市商店购买
    function XFubenRogueLikeManager.BuyBlackShopItem()
    end

    -- 支援请求
    function XFubenRogueLikeManager.RequestSupportCall(id, count, func)
        XNetwork.Call(RogueLikeRpc.SupportCall, {
            Id = id,
            Count = count
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            SupportInfos[id] = (SupportInfos[id] or 0) + 1
            local supportTemplate = XFubenRogueLikeConfig.GetSupportStationTemplateById(id)
            local specialEventTemplate = XFubenRogueLikeConfig.GetSpecialEventTemplateById(supportTemplate.SpecialEvent)
            if XFubenRogueLikeConfig.XRLOtherEventType.AddRobot ~= specialEventTemplate.Type then
                XLuaUiManager.Open("UiRogueLikeStoryResult", supportTemplate.SpecialEvent, XFubenRogueLikeConfig.SpecialResultType.SingleEvent)
            end

            if func then
                func()
            end

        end)
    end

    -- 选择特殊事件组
    function XFubenRogueLikeManager.SelectSpecialEventGroup(nodeId, groupId, func)
        XNetwork.Call(RogueLikeRpc.SelectSpecialEventGroup,
        {
            NodeId = nodeId,
            GroupId = groupId
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if func then
                func()
            end

            if #res.ResultInfos > 0 then
                XLuaUiManager.Open("UiRogueLikeStoryResult", res.ResultInfos, XFubenRogueLikeConfig.SpecialResultType.MultipleEvent)
            end
        end)
    end

    -- 当天第一次进入时，保存今日队伍
    function XFubenRogueLikeManager.RogueLikeSetTeam(characterList, func)
        XNetwork.Call(RogueLikeRpc.TeamSet,
        {
            CharacterList = characterList
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            for i = 1, #characterList do
                CharacterInfos[i] = {}
                CharacterInfos[i].Id = characterList[i]
                CharacterInfos[i].HpLeft = 100
                CharacterInfos[i].TeamPos = i
                CharacterInfos[i].Captain = 0
                CharacterInfos[i].FirstFight = 0
            end

            XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_ACTIONPOINT_CHARACTER_CHANGED)

            if func then
                func()
            end
        end)
    end


    function XFubenRogueLikeManager.UpdateRogueLikeStageRobots(stageId, isAssis, robotId)
        RogueLikeStageRobots[stageId] = {}
        RogueLikeStageRobots[stageId].IsAssis = isAssis == 1
        local robots = (isAssis == 1) and robotId or {}
        RogueLikeStageRobots[stageId].RobotId = robots
    end

    function XFubenRogueLikeManager.GetRogueLikeStageRobots(stageId)
        return RogueLikeStageRobots[stageId]
    end


    function XFubenRogueLikeManager.GetActivityBeginTime()
        local activityTemplate = XFubenRogueLikeConfig.GetLastRogueLikeConfig()
        return XFunctionManager.GetStartTimeByTimeId(activityTemplate.ActivityTimeId)
    end

    function XFubenRogueLikeManager.GetFightEndTime()
        local activityTemplate = XFubenRogueLikeConfig.GetLastRogueLikeConfig()
        return XFunctionManager.GetEndTimeByTimeId(activityTemplate.FightTimeId)
    end

    function XFubenRogueLikeManager.GetActivityEndTime()
        local activityTemplate = XFubenRogueLikeConfig.GetLastRogueLikeConfig()
        return XFunctionManager.GetEndTimeByTimeId(activityTemplate.ActivityTimeId)
    end

    function XFubenRogueLikeManager.GetFunctionalOpenId()
        local activityConfig = XFubenRogueLikeConfig.GetRogueLikeConfigById(ActivityId)
        return activityConfig.FunctionalOpenId
    end

    function XFubenRogueLikeManager.ShowRogueLikeTipsOnce()
        local value = XFubenRogueLikeManager.GetRogueLikePrefs(XFubenRogueLikeConfig.KEY_SHOW_TIPS, 0)
        local hasShow = value == 1
        if not hasShow then
            XUiManager.ShowHelpTip("RogueLike")
            XFubenRogueLikeManager.SaveRogueLikePrefs(XFubenRogueLikeConfig.KEY_SHOW_TIPS, 1)
        end
    end

    -- 打开爬塔之前检查是否需要播剧情
    function XFubenRogueLikeManager.OpenRogueLikeCheckStory()
        local value = XFubenRogueLikeManager.GetRogueLikePrefs(XFubenRogueLikeConfig.KEY_PLAY_STORY, 0)
        local activityId = XFubenRogueLikeManager.GetRogueLikeActivityId()
        local hasPlay = value == 1
        if not hasPlay and activityId then
            local activityConfig = XFubenRogueLikeConfig.GetRogueLikeConfigById(activityId)
            -- -- 播放剧情
            if activityConfig and activityConfig.BeginStoryId then
                XDataCenter.MovieManager.PlayMovie(activityConfig.BeginStoryId, function()
                    XLuaUiManager.Open("UiRogueLikeMain")
                end)
            else
                XLuaUiManager.Open("UiRogueLikeMain")
            end
            XFubenRogueLikeManager.SaveRogueLikePrefs(XFubenRogueLikeConfig.KEY_PLAY_STORY, 1)
        else
            XLuaUiManager.Open("UiRogueLikeMain")
        end
    end

    -- 保存本地数据
    function XFubenRogueLikeManager.SaveRogueLikePrefs(key, value)
        local activityId = XFubenRogueLikeManager.GetRogueLikeActivityId()
        if XPlayer.Id and activityId then
            key = string.format("%s_%s_%s", key, tostring(XPlayer.Id), tostring(activityId))
            CS.UnityEngine.PlayerPrefs.SetInt(key, value)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    function XFubenRogueLikeManager.GetRogueLikePrefs(key, defaultValue)
        local activityId = XFubenRogueLikeManager.GetRogueLikeActivityId()
        if XPlayer.Id and activityId then
            key = string.format("%s_%s_%s", key, tostring(XPlayer.Id), tostring(activityId))
            if CS.UnityEngine.PlayerPrefs.HasKey(key) then
                local rogueLikePref = CS.UnityEngine.PlayerPrefs.GetInt(key)
                return (rogueLikePref == nil or rogueLikePref == 0) and defaultValue or rogueLikePref
            end
        end
        return defaultValue
    end

    -- 检查活动结束
    function XFubenRogueLikeManager.CheckRogueLikeActivityEndOnUi(uiName)
        if not XFubenRogueLikeManager.IsInActivity() and XLuaUiManager.IsUiShow(uiName) then
            XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
            XLuaUiManager.RunMain()
        end
    end

    -- 检查天重置-修改为活动过期提示
    function XFubenRogueLikeManager.CheckRogueLikeDayResetOnUi(uiName)
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        if XLuaUiManager.IsUiShow(uiName) then
            local notChars = #CharacterInfos <= 0
            local notInActivity = not XFubenRogueLikeManager.IsInActivity()
            if notChars or notInActivity then
                if notChars then
                    XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeDayReset"))
                elseif notInActivity then
                    XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
                end
                XScheduleManager.ScheduleOnce(function()
                    XLuaUiManager.RunMain()
                end, 1000)
            end
        end
    end

    function XFubenRogueLikeManager.CheckCharacterReset()
        -- 战斗模式
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end

        if XFubenRogueLikeManager.IsTargetUiShow() and not XFubenRogueLikeManager.IsSectionPurgatory() then
            local notChars = #CharacterInfos <= 0
            local notInActivity = not XFubenRogueLikeManager.IsInActivity()
            if notChars or notInActivity then
                if notInActivity then
                    XUiManager.TipMsg(CS.XTextManager.GetText("RougeLikeNotInActivityTime"))
                elseif notChars then
                    XUiManager.TipMsg(CS.XTextManager.GetText("RogueLikeDayReset"))
                end
                XScheduleManager.ScheduleOnce(function()
                    XLuaUiManager.RunMain()
                end, 1000)
            end
        end

    end

    function XFubenRogueLikeManager.IsTargetUiShow()
        for _, uiName in pairs(CheckUiName) do
            if XLuaUiManager.IsUiShow(uiName) then
                return true
            end
        end
        return false
    end

    function XFubenRogueLikeManager.IsFinalTier()
        return IsFinal
    end

    -- 获取历史最高层级
    function XFubenRogueLikeManager.GetHistoryMaxTier()
        return HistoryMaxTier
    end

    function XFubenRogueLikeManager.ResetIsFinalTier()
        IsFinal = false
    end

    -- 最多获得机器人数量
    function XFubenRogueLikeManager.GetMaxRobotCount()
        local activityId = XFubenRogueLikeManager.GetRogueLikeActivityId()
        if not activityId then return 3 end
        local activityTemplate = XFubenRogueLikeConfig.GetRougueLikeTemplateById(activityId)
        if not activityTemplate then return 3 end
        return activityTemplate.RobotMax or 3
    end

    -- 机器人是否已经到达最大值
    function XFubenRogueLikeManager.IsAssistRobotFull()
        local ownCount = #AssistRobots
        local needCount = XFubenRogueLikeManager.GetMaxRobotCount()
        return ownCount >= needCount
    end

   
    --试炼模式尽量放在这里
    --试炼模式重置数据
    function XFubenRogueLikeManager.ResetHardNode(resetType, func)
        XNetwork.Call(RogueLikeRpc.ResetHardNode, {
            Type = resetType,
        }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            XDataCenter.FubenRogueLikeManager.AsyncRogueLikeInfo(res.Data)
            XEventManager.DispatchEvent(XEventId.EVENT_ROGUELIKE_SECTION_REFRESH)
            if func then
                func()
            end
        end)
    end
    
    function XFubenRogueLikeManager.OpenTrialPoint(func)
        XNetwork.Call(RogueLikeRpc.OpenTrialPoint, {
            CurSectionId = CurSectionId
        }, function(res)

            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
           
            XDataCenter.FubenRogueLikeManager.AsyncTrialPointRequest(res.PointInfo)
            if func then
                func()
            end
        end)
    end

    function XFubenRogueLikeManager.GetRogueLikeTrialPoint()
        return RogueLikeTrialPoint
    end
    
    function XFubenRogueLikeManager.SetRogueLikeTrialPointShowByTween(value)
        RogueLikeTrialPointShowByTween = value
    end

    function XFubenRogueLikeManager.GetRogueLikeTrialPointShowByTween()
        return RogueLikeTrialPointShowByTween
    end

    function XFubenRogueLikeManager.IsSectionPurgatory()
        local CurSectionTierType = XFubenRogueLikeConfig.GetTierSectionTierTypeById(CurSectionId)
        return CurSectionTierType == XFubenRogueLikeConfig.TierType.Purgatory
    end

    function XFubenRogueLikeManager.GetNeedShowTrialTips()
        return NeedShowTrialTips
    end
    
    --是否需要显示试炼开启页面
    function XFubenRogueLikeManager.SetNeedShowTrialTips(value)
        NeedShowTrialTips = value
    end

    function XFubenRogueLikeManager.GetRogueLikeResetNum()
        return RogueLikeResetNum
    end
    
    --获取最终得分的数据
    function XFubenRogueLikeManager.GetRogueLikeTrialPointDatas()
        return TrialPointDatas
    end
    
    --是否需要显示最终得分页面
    function XFubenRogueLikeManager.SetNeedShowTrialPointView(value)
        NeedShowTrialPointView = value
    end

    function XFubenRogueLikeManager.GetNeedShowTrialPointView()
        return NeedShowTrialPointView
    end

    function XFubenRogueLikeManager.Init()
    end
    
    XFubenRogueLikeManager.Init()
    return XFubenRogueLikeManager
end

-- 通知玩法数据
XRpc.NotifyRogueLikeData = function(notifyData)
    XDataCenter.FubenRogueLikeManager.AsyncRogueLikeInfo(notifyData)
end

-- 通知buff
XRpc.NotifyBuffData = function(notifyData)
    XDataCenter.FubenRogueLikeManager.AsyncBuffData(notifyData)
end

-- 更新章节数据
XRpc.NotifySectionInfoChange = function(notifyData)
    XDataCenter.FubenRogueLikeManager.AsyncSectionInfoChange(notifyData)
end


XRpc.NotifyNodeShopInfo = function(notifyData)
    XDataCenter.FubenRogueLikeManager.AsyncNodeShopInfo(notifyData)
end

-- 通知助战机器人改变
XRpc.NotifyAssistRobot = function(notifyData)
    XDataCenter.FubenRogueLikeManager.AsyncAssistRobot(notifyData)
end

-- 刷新行动点和角色信息
XRpc.NotifyActionPointAndCharacterInfo = function(notifyData)
    XDataCenter.FubenRogueLikeManager.AsyncActionPointAndCharacterInfo(notifyData)
end

-- 刷新队伍效果
XRpc.NotifyTeamEffect = function(notifyData)
    XDataCenter.FubenRogueLikeManager.AsyncTeamEffect(notifyData)
end

--通关显示试炼积分
XRpc.NotifyTrialPoint = function(notifyData)
    XDataCenter.FubenRogueLikeManager.AsyncTrialPoint(notifyData)
end