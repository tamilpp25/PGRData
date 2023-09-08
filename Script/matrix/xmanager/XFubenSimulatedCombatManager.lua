local tableInsert = table.insert
local ipairs = ipairs
local pairs = pairs

XFubenSimulatedCombatManagerCreator = function()
    local MAX_CHAR_COUNT = 3
    local MAX_STAGE_STAR_COUNT = 3
    local XFubenSimulatedCombatManager = {}
    local ActivityInfo = nil
    local DefaultActivityInfo = nil
    local StageInterInfo = nil
    local ChallengeMapKey = "SIMULATED_COMBAT_CHALLENGE_MAP_"
    local ShopMapKey = "SIMULATED_COMBAT_SHOP_MAP_"

    local MemberList = {}
    local AdditionList = {}
    local LocalCurrency = {}
    local CurrencyNoToId = {}
    local CurrencyIdToNo = {}
    local ChallengeMap = {}
    local CurrentTeam = {}
    local CharIdToMemberId = {}
    local ConsumeLimitList = {}
    local LastShopMap = {}

    local DailyStageStarRewardCount = 0 --每日关卡星级奖励领取次数
    local StageStarRecordDic = {}
    local StarRewardDic = {} --已经领取的星级奖励
    local PointRewardDic = {} --已经领取的积分奖励
    local ResMemberSelectCount = 0  -- 已选择成员数
    local IsRegisterEditBattleProxy = false

    function XFubenSimulatedCombatManager.Init()
        DailyStageStarRewardCount = 0
        local activityTemplates = XFubenSimulatedCombatConfig.GetActTemplates()
        local nowTime = XTime.GetServerNowTimestamp()
        for _, template in pairs(activityTemplates) do
            DefaultActivityInfo = XFubenSimulatedCombatConfig.GetActivityTemplateById(template.Id)
            local TimeId = template.TimeId
            local startTime, endTime = XFunctionManager.GetTimeByTimeId(TimeId)
            if nowTime > startTime and nowTime < endTime then
                if not ActivityInfo then
                    ActivityInfo = XFubenSimulatedCombatConfig.GetActivityTemplateById(template.Id)
                end
                break
            end
        end

        if ActivityInfo then
            for i, v in ipairs(ActivityInfo.ConsumeIds) do
                XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. v, XFubenSimulatedCombatManager.OnCurrencyChange)
                CurrencyNoToId[i] = v
                CurrencyIdToNo[v] = i
                if ActivityInfo.ConsumeCountLimit[i] > 0 then
                    ConsumeLimitList[v] = true
                end
            end
            XFubenSimulatedCombatManager.OnCurrencyChange()
        end
        
        XFubenSimulatedCombatManager.ResetChange()
        XFubenSimulatedCombatManager.RegisterEditBattleProxy()
    end

    local FUBEN_SIMUCOMBAT_PROTO = {
        SimulatedCombatGetStageRewardRequest = "SimulatedCombatGetStageRewardRequest",
        SimulatedCombatPreFightRequest = "SimulatedCombatPreFightRequest",
        SimulatedCombatPointRewardRequest = "SimulatedCombatPointRewardRequest",
        SimulatedCombatGetStarRewardRequest = "SimulatedCombatGetStarRewardRequest",
    }

    function XFubenSimulatedCombatManager.GetCurrentActTemplate()
        return ActivityInfo
    end

    function XFubenSimulatedCombatManager.GetCurrencyIdByNo(no)
        return CurrencyNoToId[no]
    end

    function XFubenSimulatedCombatManager.CheckChange()
        return false
    end
    
    function XFubenSimulatedCombatManager.OnActivityEnd()
        XLuaUiManager.RunMain()
        XUiManager.TipText("ActivityMainLineEnd", XUiManager.UiTipType.Wrong, true)
    end
    
    function XFubenSimulatedCombatManager.ResetChange()
        if not ActivityInfo then return end
        
        XFubenSimulatedCombatManager.SaveShopMap()
        StageInterInfo = nil
        MemberList = {}
        AdditionList = {}
        ChallengeMap = {}
        CharIdToMemberId = {}
        ResMemberSelectCount = 0
        XFubenSimulatedCombatManager.OnCurrencyChange()
    end

    function XFubenSimulatedCombatManager.GetCurrencyByItem(item)
        if ConsumeLimitList[item.Id] then
            return string.format("%d/%d", LocalCurrency[item.Id], item:GetCount())
        else
            return LocalCurrency[item.Id]
        end
    end

    function XFubenSimulatedCombatManager.GetCurrencyByNo(no)
        if not ActivityInfo then return end
        return LocalCurrency[ActivityInfo.ConsumeIds[no]]
    end

    function XFubenSimulatedCombatManager.GetCurrencyIcon(no)
        if not no or not ActivityInfo then return end
        local index = tonumber(no)
        return XDataCenter.ItemManager.GetItemIcon(ActivityInfo.ConsumeIds[index])
    end

    function XFubenSimulatedCombatManager.OnCurrencyChange()
        if not ActivityInfo then return end
        -- 计算本地货币数量
        for _, consumeId in ipairs(ActivityInfo.ConsumeIds) do
            LocalCurrency[consumeId] = XDataCenter.ItemManager.GetCount(consumeId)
        end

        if StageInterInfo then
            local priceCount = XFubenSimulatedCombatManager.CalcBuyCount()
            for consumeId, price in pairs(priceCount) do
                LocalCurrency[consumeId] = LocalCurrency[consumeId] - price
            end
        end
        
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE, false)
    end

    function XFubenSimulatedCombatManager.GetResCfg(data)
        if data.Type == XFubenSimulatedCombatConfig.ResType.Member then
            return XFubenSimulatedCombatConfig.GetMemberById(data.Id)
        elseif data.Type == XFubenSimulatedCombatConfig.ResType.Addition then
            return XFubenSimulatedCombatConfig.GetAdditionById(data.Id)
        end
    end

    function XFubenSimulatedCombatManager.CalcPriceCount(calcSelectType)
        if not StageInterInfo then return end
        local price = {}
        -- calcSelectType 计算特定类别选中商品的价格
        for _, consumeId in ipairs(ActivityInfo.ConsumeIds) do
            price[consumeId] = 0
        end

        if XFubenSimulatedCombatManager.CheckCurrencyFree() then
            return price
        end
        
        local list = XFubenSimulatedCombatManager.GetCurrentResList(calcSelectType)
        for _, item in ipairs(list) do
            if item.IsSelect then
                for i, v in ipairs(XFubenSimulatedCombatManager.GetResCfg(item).ConsumeCounts) do
                    local consume = CurrencyNoToId[i]
                    price[consume] = price[consume] + v
                end
            end
        end
        
        return price
    end

    function XFubenSimulatedCombatManager.CalcBuyCount()
        if not ActivityInfo then return end
        -- 计算已购买商品的价格
        local price = {}
        for _, consumeId in ipairs(ActivityInfo.ConsumeIds) do
            price[consumeId] = 0
        end
        
        if XFubenSimulatedCombatManager.CheckCurrencyFree() then
            return price
        end

        local list = XTool.MergeArray(MemberList, AdditionList)
        for _, item in ipairs(list) do
            local unitPrice = XFubenSimulatedCombatManager.GetResCfg(item).ConsumeCounts
            if item.BuyMethod then
                local consume = CurrencyNoToId[item.BuyMethod]
                price[consume] = price[consume] + unitPrice[item.BuyMethod]
            end
        end

        return price
    end
    function XFubenSimulatedCombatManager.CheckCurrencyFree()
        if not ActivityInfo or not StageInterInfo then return end
        if XDataCenter.FubenManager.CheckStageIsPass(StageInterInfo.StageId) and
                StageInterInfo.Type == XFubenSimulatedCombatConfig.StageType.Normal then
            return true
        else
            return false
        end
    end
    
    function XFubenSimulatedCombatManager.GetCurStageMember(memberId)
        local memberCfgList = {}
        -- 后续考虑根据是否已选择、已购买排序
        for _,v in ipairs(MemberList) do
            local data = XFubenSimulatedCombatConfig.GetMemberById(v.Id)
            if memberId ~= v.Id then
                tableInsert(memberCfgList, data)
            else
                tableInsert(memberCfgList, 1, data)
            end
        end
        return memberCfgList
    end

    function XFubenSimulatedCombatManager.GetCurStageMemberDataByCharId(charId)
        -- XLog.Warning("GetCurStageMemberDataByCharId", charId, CharIdToMemberId[charId], CharIdToMemberId)
        local memberId = CharIdToMemberId[charId] or 0
        return XFubenSimulatedCombatConfig.GetMemberById(memberId)
    end
    
    function XFubenSimulatedCombatManager.SelectStageInter(Id)
        StageInterInfo = XFubenSimulatedCombatConfig.GetStageInterData(Id)
        if not StageInterInfo then return end
        
        LastShopMap = XFubenSimulatedCombatManager.GetShopMapCache()
        MemberList = {}
        ResMemberSelectCount = 0
        for _,v in ipairs(StageInterInfo.MemberIds) do
            local type = XFubenSimulatedCombatConfig.ResType.Member
            local data = {Id = v, Type = type}
            local subMap = LastShopMap[type]
            if subMap then
                data.BuyMethod = subMap[v]
            end
            if data.BuyMethod then
                ResMemberSelectCount = ResMemberSelectCount + 1
            end
            tableInsert(MemberList, data)
        end
        AdditionList = {}
        for _,v in ipairs(StageInterInfo.Additions) do
            local type = XFubenSimulatedCombatConfig.ResType.Addition
            local data = {Id = v, Type = type}
            local subMap = LastShopMap[type]
            if subMap then
                data.BuyMethod = subMap[v]
            end
            tableInsert(AdditionList, data)
        end
        XFubenSimulatedCombatManager.OnCurrencyChange()
    end

    function XFubenSimulatedCombatManager.GetCurrentResList(type)
        if type == XFubenSimulatedCombatConfig.ResType.Member then
            return MemberList
        elseif type == XFubenSimulatedCombatConfig.ResType.Addition then
            return AdditionList
        end
        return {}
    end

    function XFubenSimulatedCombatManager.SelectGridRes(data)
        if data.Type == XFubenSimulatedCombatConfig.ResType.Member then
            if not data.BuyMethod then
                if not data.IsSelect then
                    if ResMemberSelectCount >= MAX_CHAR_COUNT then
                        return false, CsXTextManagerGetText("SimulatedCombatOverMaxChar")
                    end
                    ResMemberSelectCount = ResMemberSelectCount + 1
                else
                    ResMemberSelectCount = ResMemberSelectCount - 1
                end
            end
        end
        
        data.IsSelect = not data.IsSelect
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE, false)
        return true
    end
    
    function XFubenSimulatedCombatManager.GetMemberCount()
        local count = 0
        for _, item in ipairs(MemberList) do
            if item.BuyMethod then
                count = count + 1
            end
        end
        return count, MAX_CHAR_COUNT
    end
    
    function XFubenSimulatedCombatManager.CancelBuyGridRes(data)
        data.BuyMethod = false
        if data.Type == XFubenSimulatedCombatConfig.ResType.Member then
            ResMemberSelectCount = ResMemberSelectCount - 1
        end
        XFubenSimulatedCombatManager.OnCurrencyChange()
    end

    function XFubenSimulatedCombatManager.CheckBuyRes(type)
        local selectCount, buyCount = 0, 0
        local list = XFubenSimulatedCombatManager.GetCurrentResList(type)
        for _, item in ipairs(list) do
            if item.IsSelect then
                selectCount = selectCount + 1
            elseif item.BuyMethod then
                buyCount = buyCount + 1
            end
        end
        if type == XFubenSimulatedCombatConfig.ResType.Member and buyCount >= MAX_CHAR_COUNT then
            return false, CsXTextManagerGetText("SimulatedCombatOverMaxCharUnableBuy")
        elseif selectCount > 0 then
            return true
        else
            return false, CsXTextManagerGetText("SimulatedCombatBuyNothing")
        end
    end
    
    function XFubenSimulatedCombatManager.BuySelectedGridRes(type, payMethod)
        local result, desc = XFubenSimulatedCombatManager.CheckBuyRes(type)
        if not result then 
            return result, desc 
        end
        
        local bill = XFubenSimulatedCombatManager.CalcPriceCount(type)
        local consume = CurrencyNoToId[payMethod]
        if LocalCurrency[consume] < bill[consume] then
            return false, CsXTextManagerGetText("SimulatedCombatBuyFail")
        end
        
        local list = XFubenSimulatedCombatManager.GetCurrentResList(type)
        for _, item in ipairs(list) do
            if item.IsSelect then
                item.BuyMethod = payMethod
                item.IsSelect = false
            end
        end
        XFubenSimulatedCombatManager.OnCurrencyChange()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE, true)
        return true
    end

    function XFubenSimulatedCombatManager.CheckEnterRoom()
        if not StageInterInfo then return end
        
        local memberCount = 0
        for _,v in ipairs(MemberList) do
            if v.BuyMethod then
                memberCount = memberCount + 1
            end
        end
        
        if StageInterInfo.Type == XFubenSimulatedCombatConfig.StageType.Normal then
            return memberCount == MAX_CHAR_COUNT
        elseif StageInterInfo.Type == XFubenSimulatedCombatConfig.StageType.Challenge then
            return memberCount > 0 and memberCount <= MAX_CHAR_COUNT
        end
    end

    --获取奖励
    function XFubenSimulatedCombatManager.GetStarRewardList()
        local ownStars = XFubenSimulatedCombatManager.GetStarProgress()
        local canGet = false
        local startIndex = 1
        local leastGap = XMath.IntMax()
        local starReward = {}
        for i in ipairs(XFubenSimulatedCombatConfig.GetStarReward()) do
            local cfg = XFubenSimulatedCombatConfig.GetStarRewardById(i)
            if cfg then
                local data = {}
                data.Id = cfg.Id
                data.RequireStar = cfg.RequireStar
                data.RewardId = cfg.RewardId
                data.IsFinish = ownStars >= cfg.RequireStar
                data.IsReward = XFubenSimulatedCombatManager.CheckStarRewardGet(cfg.Id)
                starReward[i] = data
                if canGet then goto CONTINUE end
                if data.IsFinish and not data.IsReward then
                    startIndex = i
                    canGet = true
                elseif not data.IsFinish then
                    local gap = cfg.RequireStar - ownStars
                    if leastGap > gap then
                        leastGap = gap
                        startIndex = i
                    end
                end
            end
            ::CONTINUE::
        end

        return starReward, canGet, startIndex
    end

    function XFubenSimulatedCombatManager.GetStardRewardNeedStarNum(rewardIndex)
        if not rewardCfg[rewardIndex] then
            return nil
        end

        return rewardCfg[rewardIndex].RequireStar
    end

    --判断是否已经领奖
    function XFubenSimulatedCombatManager.CheckStarRewardGet(rewardId)
        if not rewardId then
            return
        end

        return StarRewardDic and StarRewardDic[rewardId]
    end

    --返回每日领奖次数及上限
    function XFubenSimulatedCombatManager.GetDailyRewardRemainCount()
        if not ActivityInfo then return 0 end
        return ActivityInfo.MaxDailyStageStarRewardCount - DailyStageStarRewardCount
    end
    
    --读取获得奖励的状态
    function XFubenSimulatedCombatManager.CheckPointRewardGet(rewardId)
        if not rewardId then
            return
        end

        return PointRewardDic and PointRewardDic[rewardId]
    end

    -- 检测是否开启模式
    function XFubenSimulatedCombatManager.CheckModeOpen(type)
        if XFubenSimulatedCombatManager.GetIsActivityEnd() then
            XUiManager.TipText("RougeLikeNotInActivityTime")
            return false, CS.XTextManager.GetText("RougeLikeNotInActivityTime")
        end

        if type == XFubenSimulatedCombatConfig.StageType.Challenge then
            local isOpen, desc = XConditionManager.CheckCondition(ActivityInfo.HardConditionId)
            return isOpen, desc
        end

        return true
    end

    function XFubenSimulatedCombatManager.GetPointReward(id, funCb)
        XNetwork.Call(FUBEN_SIMUCOMBAT_PROTO.SimulatedCombatPointRewardRequest, { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            PointRewardDic[id] = true
            if funCb then
                funCb(res.Goods)
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SIMUCOMBAT_REWARD)
        end)
    end

    function XFubenSimulatedCombatManager.GetStarReward(treasureId, cb)
        XNetwork.Call(FUBEN_SIMUCOMBAT_PROTO.SimulatedCombatGetStarRewardRequest, {Id = treasureId},function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 设置已领取
            StarRewardDic[treasureId] = true
            if cb then
                cb(res.Goods)
            end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE)
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE)
        end)
    end

    -- [初始化数据]
    function XFubenSimulatedCombatManager.InitStageInfo()
        for _, stageType in pairs(XFubenSimulatedCombatConfig.StageType or {}) do
            local stages = XFubenSimulatedCombatConfig.GetStageInterDataByType(stageType)
            for _, v in ipairs(stages) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(v.StageId)
                if stageInfo then
                    stageInfo.Type = XDataCenter.FubenManager.StageType.SimulatedCombat
                end
            end
        end

        -- 通关后需要会执行InitStage 所以需要刷新
        XFubenSimulatedCombatManager.RefreshStagePassed()
    end

    function XFubenSimulatedCombatManager.RefreshStagePassed()
        local mapStages = XFubenSimulatedCombatConfig.GetStageInterDataByType(XFubenSimulatedCombatConfig.StageType.Normal)
        local stages = XFubenSimulatedCombatConfig.GetStageInterDataByType(XFubenSimulatedCombatConfig.StageType.Challenge)
        for i, v in ipairs(stages) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(v.StageId)
            local mapStageInfo = XDataCenter.FubenManager.GetStageInfo(mapStages[i].StageId)
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(v.StageId)
            if stageInfo then
                stageInfo.Unlock = mapStageInfo.Passed
                stageInfo.IsOpen = mapStageInfo.Passed
                
                for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                    if preStageId > 0 then
                        if not XDataCenter.FubenManager.CheckStageIsPass(preStageId) then
                            stageInfo.Unlock = false
                            break
                        end
                    end
                end
            end
        end
    end

    function XFubenSimulatedCombatManager.GetCharacterAndRobotId(memberId)
        local data = XFubenSimulatedCombatConfig.GetMemberById(memberId)
        return XRobotManager.GetCharacterId(data.RobotId), data.RobotId
    end
    
    function XFubenSimulatedCombatManager.SendPreFightRequest(cb)
        if not StageInterInfo then return end
        local members = {}
        local additions = {}
        
        CurrentTeam = XTool.Clone(XFubenSimulatedCombatConfig.TeamTemplate)
        CurrentTeam.TeamId = XDataCenter.TeamManager.GetTeamId(CS.XGame.Config:GetInt("TypeIdSimulatedCombat"))
        
        for _, item in ipairs(MemberList) do
            if item.BuyMethod then
                tableInsert(members, {Id = item.Id, ConsumeType = item.BuyMethod})
                local charId = XFubenSimulatedCombatManager.GetCharacterAndRobotId(item.Id)
                --XLog.Warning("name", XMVCA.XCharacter:GetCharacterFullNameStr(charId))
                tableInsert(CurrentTeam.TeamData, charId)
                CharIdToMemberId[charId] = item.Id
            end
        end
        
        for _, item in ipairs(AdditionList) do
            if item.BuyMethod then
                tableInsert(additions, {Id = item.Id, ConsumeType = item.BuyMethod})
            end
        end
        
        for i = #CurrentTeam.TeamData + 1, MAX_CHAR_COUNT do
            CurrentTeam.TeamData[i] = 0
        end
        
        local challengeIds = {}
        for i, v in ipairs(ChallengeMap) do
            if v then
                tableInsert(challengeIds, StageInterInfo.ChallengeIds[i])
            end
        end
        
        XNetwork.Call(FUBEN_SIMUCOMBAT_PROTO.SimulatedCombatPreFightRequest, 
                { StageId = StageInterInfo.StageId, Members = members, Additions = additions, ChallengeIds = challengeIds}, 
                function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        return
                    end
                    if cb then
                        cb()
                    end
        end)
    end
    
    function XFubenSimulatedCombatManager.GetTeam()
        if not StageInterInfo then return end
        local curMapStr = XSaveTool.Stringify(XFubenSimulatedCombatManager.GetShopMap())
        local preMapStr = XSaveTool.Stringify(LastShopMap)
        
        if curMapStr == preMapStr then
            local team = XDataCenter.TeamManager.LoadTeamLocal(StageInterInfo.StageId)
            if team then
                --CurrentTeam = team
                --XLog.Warning("curMapStr == preMapStr", XFubenSimulatedCombatManager.GetShopMap(), LastShopMap)
                return team
            end
        end
        
        --XLog.Warning("curMapStr ！= preMapStr", XFubenSimulatedCombatManager.GetShopMap(), LastShopMap)
        return XTool.Clone(CurrentTeam)
    end

    function XFubenSimulatedCombatManager.GetRoomMemberList()
        local memberList = {}
        for _, v in ipairs(CurrentTeam.TeamData) do
            if v and v ~= 0 then
                tableInsert(memberList, v)
            end
        end
        return memberList
    end

    function XFubenSimulatedCombatManager.FinishFight(settleData)
        XLuaUiManager.Remove("UiSimulatedCombatResAllo")
        if settleData.IsWin then
            local beginData = XDataCenter.FubenManager.GetFightBeginData()

            local winData = {
                SettleData = settleData,
                StageId = settleData.StageId,
                RewardGoodsList = settleData.RewardGoodsList,
                UrgentId = settleData.UrgentEnventId,
                NpcInfo = settleData.NpcHpInfo,
                CharExp = beginData.CharExp,
                RoleExp = beginData.RoleExp,
                RoleLevel = beginData.RoleLevel,
                RoleCoins = beginData.RoleCoins,
                PlayerList = beginData.PlayerList,
            }
            if StageInterInfo.Type == XFubenSimulatedCombatConfig.StageType.Challenge then
                local count = 0
                for _, v in ipairs(ChallengeMap) do
                    if v then
                        count = count + 1
                    end
                end
                local rewardId = StageInterInfo.StarRewardIds[count]
                if rewardId and rewardId ~= 0 then
                    winData.RewardGoodsList = XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
                end
                winData.StarsMap = ChallengeMap
            end
            
            XFubenSimulatedCombatManager.ShowReward(winData)
        else
            XUiManager.TipText("SimulatedCombatFailTips", XUiManager.UiTipType.Tip, true)
            XDataCenter.FubenManager.ChallengeLose(settleData)
        end
    end

    -- [胜利]
    function XFubenSimulatedCombatManager.ShowReward(winData)
        if not winData or not StageInterInfo then return end

        XFubenSimulatedCombatManager.RefreshStagePassed()
        XLuaUiManager.Open("UiSimulatedCombatSettleWin", winData, StageInterInfo)
    end

    function XFubenSimulatedCombatManager.GetStageReward(cb)
        XNetwork.Call(FUBEN_SIMUCOMBAT_PROTO.SimulatedCombatGetStageRewardRequest, {},function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            DailyStageStarRewardCount = DailyStageStarRewardCount + 1
            if cb then
                cb()
            end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE, false)
        end)
    end
    
    function XFubenSimulatedCombatManager.GetStageStar(stageId)
        return StageStarRecordDic[stageId]
    end

    function XFubenSimulatedCombatManager.CheckStageIsSimulatedCombat(stageId)
        local info = XDataCenter.FubenManager.GetStageInfo(stageId)
        return info and info.Type == XDataCenter.FubenManager.StageType.SimulatedCombat
    end

    -- 获取所有关卡进度
    function XFubenSimulatedCombatManager.GetStageSchedule(stageType)
        local templates = {}
        if stageType == XFubenSimulatedCombatConfig.StageType.Challenge then
            templates = XFubenSimulatedCombatConfig.GetStageInterDataByType(stageType)
        else
            templates = XFubenSimulatedCombatConfig.GetStageInterDataByType(XFubenSimulatedCombatConfig.StageType.Normal)
        end 

        local passCount = 0
        local allCount = #templates

        for _, v in ipairs(templates) do
            if XDataCenter.FubenManager.CheckStageIsPass(v.StageId) then
                passCount = passCount + 1
            end
        end

        return passCount, allCount
    end

    -- 主题活动页面是否可挑战接口
    function XFubenSimulatedCombatManager.IsChallengeable()
        if not ActivityInfo then return false end
        
        local passCount, allCount = XFubenSimulatedCombatManager.GetStageSchedule(XFubenSimulatedCombatConfig.StageType.Normal)
        if passCount < allCount then 
            return true
        end

        passCount, allCount = XFubenSimulatedCombatManager.GetStageSchedule(XFubenSimulatedCombatConfig.StageType.Challenge)
        if passCount < allCount then
            return true
        end
        
        return false
    end

    -- 获取篇章星数
    function XFubenSimulatedCombatManager.GetStarProgress()
        local templates = XFubenSimulatedCombatConfig.GetStageInterDataByType(XFubenSimulatedCombatConfig.StageType.Challenge)
        local totalStars = #templates * MAX_STAGE_STAR_COUNT
        local ownStars = 0
        for _,v in ipairs(templates) do
            local starCount = StageStarRecordDic[v.StageId] or 0
            ownStars = ownStars + starCount
        end
        return ownStars, totalStars
    end
    
    function XFubenSimulatedCombatManager.GetAvailableActs()
        local act = XFubenSimulatedCombatManager.GetCurrentActTemplate()
        local activityList = {}
        if act and 
                not XFubenSimulatedCombatManager.GetIsActivityEnd() and
                not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenSimulatedCombat) then
                tableInsert(activityList, {
                    Id = act.Id,
                    Type = XDataCenter.FubenManager.ChapterType.SimulatedCombat,
                    Name = act.Name,
                    Icon = act.BannerBg,
                })
        end
        return activityList
    end

    --判断活动是否开启
    function XFubenSimulatedCombatManager.GetIsActivityEnd()
        if not ActivityInfo then return true end
        local timeNow = XTime.GetServerNowTimestamp()
        local isEnd = timeNow >= XFubenSimulatedCombatManager.GetEndTime()
        local isStart = timeNow >= XFubenSimulatedCombatManager.GetStartTime()
        local inActivity = (not isEnd) and (isStart)
        return not inActivity, timeNow < XFubenSimulatedCombatManager.GetStartTime()
    end

    --获取本轮开始时间
    function XFubenSimulatedCombatManager.GetStartTime()
        if DefaultActivityInfo then
            return XFunctionManager.GetStartTimeByTimeId(DefaultActivityInfo.TimeId) or 0
        end
        return 0
    end

    --获取本轮结束时间
    function XFubenSimulatedCombatManager.GetEndTime()
        if DefaultActivityInfo then
            return XFunctionManager.GetEndTimeByTimeId(DefaultActivityInfo.TimeId) or 0
        end
        return 0
    end

    function XFubenSimulatedCombatManager.GetPlainStarMap(stageId)
        local starsCount = StageStarRecordDic[stageId] or 0
        local starMap = {starsCount >= 1, starsCount >= 2, starsCount >= 3}
        return starMap, starsCount
    end
    
    local function GetShopMapKey()
        return string.format("%s%s_%d_%s", ShopMapKey, tostring(XPlayer.Id), ActivityInfo.Id, StageInterInfo.StageId)
    end
    
    function XFubenSimulatedCombatManager.GetShopMapCache()
        if not StageInterInfo then return {} end
        return XSaveTool.GetData(GetShopMapKey()) or {}
    end

    function XFubenSimulatedCombatManager.GetShopMap()
        if not StageInterInfo then return end
        local shopMap = {}
        local list = XTool.MergeArray(MemberList, AdditionList)
        for _, item in ipairs(list) do
            if not shopMap[item.Type] then
                shopMap[item.Type] = {}
            end
            shopMap[item.Type][item.Id] = item.BuyMethod
        end
        return shopMap
    end
    
    function XFubenSimulatedCombatManager.SaveShopMap()
        if not StageInterInfo then return end
        --XLog.Warning("SaveShopMap", XFubenSimulatedCombatManager.GetShopMap())
        XSaveTool.SaveData(GetShopMapKey(), XFubenSimulatedCombatManager.GetShopMap())
    end

    function XFubenSimulatedCombatManager.UpdateShopMapCache()
        if not StageInterInfo then return end
        LastShopMap = XFubenSimulatedCombatManager.GetShopMapCache()
    end
    
    local function GetClgMapKey(stageId)
        return string.format("%s%s_%d_%s", ChallengeMapKey, tostring(XPlayer.Id), ActivityInfo.Id, stageId)
    end
    
    function XFubenSimulatedCombatManager.GetClgMap(stageId)
        local clgMap = XSaveTool.GetData(GetClgMapKey(stageId)) or {false, false, false}
        local count = 0
        for _, v in ipairs(clgMap) do
            if v then
                count = count + 1
            end
        end
        return clgMap, count
    end

    function XFubenSimulatedCombatManager.SaveClgMap(stageId, clgMap)
        ChallengeMap = clgMap or {false, false, false}
        XSaveTool.SaveData(GetClgMapKey(stageId), clgMap)
    end

    -- 注册出战界面代理
    function XFubenSimulatedCombatManager.RegisterEditBattleProxy()
        if IsRegisterEditBattleProxy then return end
        IsRegisterEditBattleProxy = true
        XUiNewRoomSingleProxy.RegisterProxy(XDataCenter.FubenManager.StageType.SimulatedCombat,
                require("XUi/XUiFubenSimulatedCombat/XUiSimulatedCombatNewRoomSingle"))
    end
    
    --活动登录下发
    function XFubenSimulatedCombatManager.NotifyData(data)
        if data.ActivityId == 0  then
            if CS.XFight.Instance ~= nil then
                XLuaUiManager.Remove("UiSimulatedCombatMain")
                XLuaUiManager.Remove("UiSimulatedCombatResAllo")
            else
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_ON_RESET, XDataCenter.FubenManager.StageType.SimulatedCombat)
            end
            ActivityInfo = nil
            return
        end
        
        if not ActivityInfo or ActivityInfo.Id ~= data.ActivityId then
            ActivityInfo = XFubenSimulatedCombatConfig.GetActivityTemplateById(data.ActivityId)
            XFubenSimulatedCombatManager.Init()
        end
        
        DailyStageStarRewardCount = data.DailyStageStarRewardCount
        for _, starRewardId in ipairs(data.StarRewards) do
            StarRewardDic[starRewardId] = true
        end
        for _, pointRewardId in ipairs(data.PointRewards) do
            PointRewardDic[pointRewardId] = true
        end
        for _, stageData in ipairs(data.StageDataList) do
            StageStarRecordDic[stageData.StageId] = stageData.FinishStar
        end
    end

    -- 下发奖励领取次数
    function XFubenSimulatedCombatManager.NotifyDailyReset(data)
        DailyStageStarRewardCount = data.DailyStageStarRewardCount
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SIMUCOMBAT_UPDATE, false)
    end

    -- 下发关卡数据（通关星数）
    function XFubenSimulatedCombatManager.NotifyStageData(stageData)
        StageStarRecordDic[stageData.StageId] = stageData.FinishStar
    end

    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, function()
        XFubenSimulatedCombatManager.Init()
    end)
    return XFubenSimulatedCombatManager
end

XRpc.NotifySimulatedCombatData = function(data)
    XDataCenter.FubenSimulatedCombatManager.NotifyData(data.Data)
end

XRpc.NotifySimulatedCombatDailyReset = function(data)
    XDataCenter.FubenSimulatedCombatManager.NotifyDailyReset(data)
end

XRpc.NotifySimulatedCombatStageData = function(data)
    XDataCenter.FubenSimulatedCombatManager.NotifyStageData(data.SimulatedCombatStageData)
end
