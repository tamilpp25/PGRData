local XExFubenBaseManager = require("XEntity/XFuben/XExFubenBaseManager")
local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")

XFubenDailyManagerCreator = function()
    local XFubenDailyManager = XExFubenBaseManager.New(XFubenConfigs.ChapterType.Daily)

    local METHOD_NAME = {
        ReceiveDailyReward = "ReceiveDailyRewardRequest",
    }

    local ConditionType = {
        LeverCondition = 1,
        EventCondition = 2,
    }

    local WEEK = 7
    local RefreshTime = 0

    local DailySectionData = {}
    local DailyRecord = {}

    function XFubenDailyManager.Init()
    end

    function XFubenDailyManager.OpenFightLoading(stageId)
        XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_LOADINGFINISHED)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

        if stageCfg and stageCfg.LoadingType then
            XLuaUiManager.Open("UiLoading", stageCfg.LoadingType)
        else
            XLuaUiManager.Open("UiLoading", LoadingType.Fight)
        end
    end

    function XFubenDailyManager.CloseFightLoading(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo.DailyType == XDataCenter.FubenManager.ChapterType.EMEX then
            -- XLuaUiManager.Remove("UiOnLineLoading")
            XLuaUiManager.Remove("UiLoading")
        else
            XLuaUiManager.Remove("UiLoading")
        end
    end

    -- function XFubenDailyManager.ShowReward(winData)
    --     local stageInfo = XDataCenter.FubenManager.GetStageInfo(winData.StageId)
    --     if stageInfo.DailyType == XDataCenter.FubenManager.ChapterType.EMEX then
    --         XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SHOW_REWARD, winData)
    --     else
    --         XLuaUiManager.Open("UiSettleWin", winData)
    --     end
    -- end
    -- 需要显示多重挑战则需要加ShowReward
    function XFubenDailyManager.ShowReward(winData)
        if not winData then return end
        XLuaUiManager.Open("UiRepeatChallengeSettleWin", winData)
    end

    function XFubenDailyManager.InitFubenDailyData()
        -- if fubenDailyData.DailySectionData then
        --     for k, v in pairs(fubenDailyData.DailySectionData) do
        --         DailySectionData[k] = v
        --     end
        -- end
    end

    function XFubenDailyManager.GetDailySectionData(sectionId)
        return DailySectionData[sectionId]
    end


    function XFubenDailyManager.SyncDailyReward(sectionId)
        DailySectionData[sectionId].ReceiveReward = true
    end

    function XFubenDailyManager.IsDayLock(Id)

        for k, v in pairs(XDailyDungeonConfigs.GetDailyDungeonDayOfWeek(Id)) do
            if v > 0 and k == XFubenDailyManager.GetNowDayOfWeekByRefreshTime() then
                return false
            end
        end
        return true
    end

    function XFubenDailyManager.GetConditionData(Id)
        local functionNameId = {}
        local data = {}
        local dungeonRule = XDailyDungeonConfigs.GetDailyDungeonRulesById(Id)
        if dungeonRule.Type == XDataCenter.FubenManager.ChapterType.GZTX then--日常構造體特訓
            functionNameId = XFunctionManager.FunctionName.FubenDailyGZTX
        elseif dungeonRule.Type == XDataCenter.FubenManager.ChapterType.XYZB then--日常稀有裝備
            functionNameId = XFunctionManager.FunctionName.FubenDailyXYZB
        elseif dungeonRule.Type == XDataCenter.FubenManager.ChapterType.TPCL then--日常突破材料
            functionNameId = XFunctionManager.FunctionName.FubenDailyTPCL
        elseif dungeonRule.Type == XDataCenter.FubenManager.ChapterType.ZBJY then--日常裝備經驗
            functionNameId = XFunctionManager.FunctionName.FubenDailyZBJY
        elseif dungeonRule.Type == XDataCenter.FubenManager.ChapterType.LMDZ then--日常螺母大戰
            functionNameId = XFunctionManager.FunctionName.FubenDailyLMDZ
        elseif dungeonRule.Type == XDataCenter.FubenManager.ChapterType.JNQH then--日常技能强化
            functionNameId = XFunctionManager.FunctionName.FubenDailyJNQH
        elseif dungeonRule.Type == XDataCenter.FubenManager.ChapterType.FZJQH then--日常辅助机强化
            functionNameId = XFunctionManager.FunctionName.FubenDailyFZJQH
        elseif dungeonRule.Type == XDataCenter.FubenManager.ChapterType.Assign then--边界公约
            functionNameId = XFunctionManager.FunctionName.FubenAssign
        elseif dungeonRule.Type == XDataCenter.FubenManager.ChapterType.RepeatChallenge then--复刷关
            functionNameId = XFunctionManager.FunctionName.RepeatChallenge    
        else
            for key, val in pairs(XDataCenter.FubenManager.ChapterType) do
                if dungeonRule.Type == val then
                    functionNameId = XFunctionManager.FunctionName[key] or 0
                end
            end
        end
        data.IsLock = not XFunctionManager.JudgeCanOpen(functionNameId)
        data.functionNameId = functionNameId
        return data
    end
    function XFubenDailyManager.GetOpenDayString(rule)
        --開放日顯示
        local tmpNum = { "One", "Two", "Three", "Four", "Five", "Six", "Diary" }
        local dayStr = ""
        local dayCount = 0
        local IsAllDay = false
        for i = 1, WEEK do
            if rule.OpenDayOfWeek[i] ~= 0 then
                dayStr = dayStr .. CS.XTextManager.GetText(tmpNum[i])
                dayCount = dayCount + 1
            end
        end

        if dayCount == WEEK then
            dayStr = CS.XTextManager.GetText("FubenDailyAllDayOpen")
            IsAllDay = true
        end

        return dayStr, IsAllDay
    end

    function XFubenDailyManager.GetMainLineFubenOrderId(stageId)
        local chapterCfg = XFubenMainLineConfigs.GetChapterCfg()
        for _, v1 in pairs(chapterCfg) do
            for _, v2 in pairs(v1.StageId) do
                if stageId == v2 then
                    return v1.OrderId .. "-" .. XDataCenter.FubenManager.GetStageCfg(v2).OrderId
                end
            end
        end
        return ""
    end

    function XFubenDailyManager.GetEventOpen(Id)
        local eventOpenData = {}
        local eventText = ""
        local dungeonRule = XDailyDungeonConfigs.GetDailyDungeonRulesById(Id)
        local specialCondition = XDailyDungeonConfigs.GetDailySpecialConditionList()
        local eventOpen = false
        local nowTime = XTime.GetServerNowTimestamp()
        local stratTime
        local endTime
        for _, v in pairs(dungeonRule.SpecialConditionId) do
            if v ~= 0 then
                if specialCondition[v].Type == ConditionType.LeverCondition then

                    local tmpCon = XConditionManager.CheckPlayerCondition(specialCondition[v].IntParam[1])
                    eventOpen = eventOpen or tmpCon
                    if tmpCon and eventText == "" then eventText = specialCondition[v].Text end

                elseif specialCondition[v].Type == ConditionType.EventCondition then
                    stratTime = XTime.ParseToTimestamp(specialCondition[v].StringParam[1])
                    endTime = XTime.ParseToTimestamp(specialCondition[v].StringParam[2])
                    if stratTime and endTime then
                        local tmpCon = nowTime > stratTime and nowTime < endTime
                        eventOpen = eventOpen or tmpCon
                        if tmpCon and eventText == "" then eventText = specialCondition[v].Text end
                    end
                end
            else
                eventOpen = eventOpen or false
            end
        end
        eventOpenData.IsOpen = eventOpen
        eventOpenData.Text = eventText
        return eventOpenData
    end

    function XFubenDailyManager.GetDropDataList(Id, dayOfWeek)--根据日期获得掉落的物品组
        local RandomDrop = {}
        local FixedDrop = {}
        local DropGroupDatas = {}
        for _, v in pairs(XDailyDungeonConfigs.GetDailyDropGroupList()) do
            if v.DungeonId == Id then
                table.insert(DropGroupDatas, v)
            end
        end

        for _, v in pairs(DropGroupDatas) do
            if v.OpenDayOfWeek == dayOfWeek then
                RandomDrop = XRewardManager.GetRewardList(v.RandomRewardId)

                FixedDrop = XRewardManager.GetRewardList(v.FixedRewardId)

            end
        end
        return RandomDrop, FixedDrop
    end

    function XFubenDailyManager.GetNowDayOfWeekByRefreshTime()
        local nowTime = XTime.GetServerNowTimestamp()
        local toDay = XTime.GetWeekDay(nowTime, true)
        local tmpTime
        RefreshTime = RefreshTime or 0

        if RefreshTime - XTime.GetTodayTime(0, 0, 0) >= CS.XDateUtil.ONE_DAY_SECOND then
            tmpTime = RefreshTime - CS.XDateUtil.ONE_DAY_SECOND
        else
            tmpTime = RefreshTime
        end

        if nowTime < tmpTime then
            toDay = toDay - 1
        end

        if toDay <= 0 then
            toDay = toDay + 7
        end
        return toDay
    end

    --function XFubenDailyManager.InitStageInfo()
    --    local DungeonDataList = XDailyDungeonConfigs.GetDailyDungeonDataList()
    --    for _, chapter in pairs(DungeonDataList) do
    --        for _, stageId in pairs(chapter.StageId) do
    --            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    --            if stageInfo then
    --                stageInfo.Type = XDataCenter.FubenManager.StageType.Daily
    --                stageInfo.mode = XDataCenter.FubenManager.ModeType.SINGLE
    --                stageInfo.stageDataName = chapter.Name
    --            end
    --        end
    --    end
    --end
    
    function XFubenDailyManager.GetChapterName(stageId)
        local DungeonDataList = XDailyDungeonConfigs.GetDailyDungeonDataList()
        for _, chapter in pairs(DungeonDataList) do
            for _, stageIdOnConfig in pairs(chapter.StageId) do
                if stageIdOnConfig == stageId then
                    return chapter.Name
                end
            end
        end
    end


    -- 领取挑战奖励
    function XFubenDailyManager.ReceiveDailyReward(cb, dailySectionId)
        local req = { DailySectionId = dailySectionId }
        XNetwork.Call(METHOD_NAME.ReceiveDailyReward, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XFubenDailyManager.SyncDailyReward(dailySectionId)
            if cb then
                cb(res.RewardGoodsList)
            end
        end)
    end

    function XFubenDailyManager.GetRemainCount()

    end

    function XFubenDailyManager.NotifyFubenDailyData(req)
        XTool.LoopMap(req.FubenDailyData.DailySectionData, function(k, v)
            DailySectionData[k] = v
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_DAILY_REFRESH)
        end)
    end

    function XFubenDailyManager.NotifyDailyFubenRefreshTime(req)
        RefreshTime = req.RefreshTime
    end

    function XFubenDailyManager.NotifyDailyFubenLoginData(req)
        RefreshTime = req.RefreshTime
        for _, v in pairs(req.Records) do
            DailyRecord[v.ChapterId] = v.StageId
        end
    end

    function XFubenDailyManager.GetLastStageId(dailyDungeonId)
        return DailyRecord[dailyDungeonId]
    end

    function XFubenDailyManager.SetFubenDailyRecord(stageId)
        local dailyDungeonId = XDailyDungeonConfigs.GetDailyDungeonIdByStageId(stageId)
        if dailyDungeonId and DailyRecord then
            DailyRecord[dailyDungeonId] = stageId
        end
    end
    ------------------副本入口扩展(带ChapterViewModel) start-------------------------
    function XFubenDailyManager:ExGetFunctionNameType()
        return XFunctionManager.FunctionName.FubenDaily
    end

    -- 检查是否展示红点
    function XFubenDailyManager:ExCheckIsShowRedPoint()
        for _, viewModel in ipairs(self:ExGetChapterViewModels()) do
            if viewModel:CheckHasRedPoint() then
                return true
            end
        end
   
        return false
    end
    
    function XFubenDailyManager:ExGetChapterViewModels()
        if self.__ChapterViewModelDic == nil then self.__ChapterViewModelDic = {} end
        if next(self.__ChapterViewModelDic) then return self.__ChapterViewModelDic end
        local chapterConfigs = XDailyDungeonConfigs.GetDailyDungeonRulesList()
        for _, config in pairs(chapterConfigs) do
            local id = config.Id
            local chapterMainId = XFubenShortStoryChapterConfigs.GetChapterMainIdByChapterId(id)
            table.insert(self.__ChapterViewModelDic, CreateAnonClassInstance({
                GetProgress = function(proxy)
                    return nil
                end,
                CheckHasRedPoint = function(proxy)
                    return false
                end,
                GetIsLocked = function(proxy)
                    return XFubenDailyManager.GetConditionData(id).IsLock
                end,
                GetLockTip = function(proxy)
                    local tmpCon = XFubenDailyManager.GetConditionData(config.Id)
                    return XFunctionManager.GetFunctionOpenCondition(tmpCon.functionNameId)
                end,
                GetOpenDayString = function(proxy)
                    return XFubenDailyManager.GetOpenDayString(config)
                end,
                IsDayLock = function(proxy)
                    return XFubenDailyManager.IsDayLock(id)
                end,
                CheckHasTimeLimitTag = function(proxy) -- 这个就是资源商店标签，用这个接口名顶替
                    local shopId = XDailyDungeonConfigs.GetFubenDailyShopId(id)
                    local tagName = ""
                    if shopId > 0 then
                        tagName = XShopManager.GetShopTypeDataById(XShopManager.ShopType.FubenDaily).Desc
                        return not proxy:GetIsLocked(), tagName
                    else
                        tagName = XDailyDungeonConfigs.GetFubenDailyTagName(id)
                        
                        return (not string.IsNilOrEmpty(tagName) and not proxy:GetIsLocked()), tagName
                    end
                    return (shopId > 0 and not proxy:GetIsLocked()), tagName
                end,
                OpenUi = function(proxy)
                    local dataCfg = XDailyDungeonConfigs.GetDailyDungeonData(config.Id)
                    if dataCfg and XTool.IsNumberValid(dataCfg.SkipId) then
                        XFunctionManager.SkipInterface(dataCfg.SkipId)
                    else
                        XLuaUiManager.Open("UiFubenDaily", config)
                    end
                end,
                CheckHasRedPoint = function(proxy)
                    ---@type XTableDailyDungeonData
                    local dataCfg = XDailyDungeonConfigs.GetDailyDungeonData(config.Id)
                    if dataCfg and not string.IsNilOrEmpty(dataCfg.RedPointConditions) then 
                        return XRedPointManager.CheckConditions({dataCfg.RedPointConditions})
                    end
                    return false
                end

            }, XChapterViewModel
            , {
                Id = id,
                ExtralName = config.Title,
                Name = config.Title,
                Desc = config.Describe,
                Icon = config.Icon,
                ExtralData = config,
            }))
            table.sort(self.__ChapterViewModelDic, function (a, b)
                return a:GetExtralData().Priority < b:GetExtralData().Priority
            end)
        end
        return self.__ChapterViewModelDic
    end
    ------------------副本入口扩展 end-------------------------

    XFubenDailyManager.Init()
    return XFubenDailyManager
end

XRpc.NotifyFubenDailyData = function(req)
    XDataCenter.FubenDailyManager.NotifyFubenDailyData(req)
end

XRpc.NotifyDailyFuBenRefreshTime = function(req)
    XDataCenter.FubenDailyManager.NotifyDailyFubenRefreshTime(req)
end

XRpc.NotifyDailyFubenLoginData = function(req)
    XDataCenter.FubenDailyManager.NotifyDailyFubenLoginData(req)
end