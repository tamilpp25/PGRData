XMultiDimManagerCreator = function()
    local XMultiDimManager = {}
    
    local RequestProto = {
        MultiDimUpgradeTalentRequest = "MultiDimUpgradeTalentRequest", -- 升级天赋
        MultiDimOpenRankRequest = "MultiDimOpenRankRequest", -- 打开排行榜
        MultiDimSelectCareerRequest = "MultiDimSelectCareerRequest", -- 预选职业
        MultiDimSelectCharacterRequest = "MultiDimSelectCharacterRequest", -- 预选角色
        MultiDimResetTalentRequest = "MultiDimResetTalentRequest", -- 重置天赋
        MultiDimSelectTeamMatesCareer = "MultiDimSelectTeammateCareerRequest", --选择房间内队友职业
        MultiDimChangeRecommendCareer = "ChangeRecommendClassRequest", --房间内更换队友职业
    }
    
    --region 活动相关
    local _ActivityId = XMultiDimConfig.GetDefaultActivityId() -- 当前开发活动ID
    local ThemeData = {} --share和client的合并theme数据

    local function UpdateActivityId(activityId)
        if not XTool.IsNumberValid(activityId) then
            _ActivityId = XMultiDimConfig.GetDefaultActivityId()
            return
        end

        _ActivityId = activityId
    end
    
    function XMultiDimManager.GetActivityChapters()
        local chapters = {}
        if not _ActivityId then
            return chapters
        end
        
        if XMultiDimManager.IsOpen() then
            local temp = {}
            temp.Id = _ActivityId
            temp.Name = XMultiDimManager.GetActivityName()
            temp.BannerBg = XMultiDimConfig.GetActivityBannerBg(_ActivityId)
            temp.Type = XDataCenter.FubenManager.ChapterType.MultiDim
            table.insert(chapters, temp)
        end
        return chapters
    end
    
    function XMultiDimManager.IsOpen()
        if not XTool.IsNumberValid(_ActivityId) then
            return false
        end
        local timeId = XMultiDimConfig.GetActivityTimeId(_ActivityId)
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    function XMultiDimManager.GetMultiSinglePassStageCount(themeId)
        local passCount = 0
        local stageList = XMultiDimConfig.GetMultiSingleStageListByThemeId(themeId)
        for key, stageId in pairs(stageList) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo.Passed then
                passCount = passCount + 1
            end
        end
        return passCount
    end
    
    function XMultiDimManager.GetStartTime()
        local timeId = XMultiDimConfig.GetActivityTimeId(_ActivityId)
        return XFunctionManager.GetStartTimeByTimeId(timeId) or 0
    end

    function XMultiDimManager.GetEndTime()
        local timeId = XMultiDimConfig.GetActivityTimeId(_ActivityId)
        return XFunctionManager.GetEndTimeByTimeId(timeId) or 0
    end
    
    function XMultiDimManager.GetActivityName()
        return XMultiDimConfig.GetActivityName(_ActivityId)
    end
    
    function XMultiDimManager.OnOpenMain()
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.MultiDim) then
            return
        end
        
        if not XMultiDimManager.IsOpen() then
            XUiManager.TipText("CommonActivityNotStart")
            return
        end
        
        XLuaUiManager.Open("UiMultiDimMain")
    end
    
    function XMultiDimManager.HandleActivityEndTime()
        XUiManager.TipText("MultiDimActivityEnd")
        XLuaUiManager.RunMain()
    end
    
    function XMultiDimManager.GetActivityItemId()
        return XMultiDimConfig.GetActivityItemId(_ActivityId)
    end

    function XMultiDimManager.GetActivityTaskGroupId()
        return XMultiDimConfig.GetActivityTaskGroupId(_ActivityId)
    end

    function XMultiDimManager.GetActivityTaskGroupName()
        return XMultiDimConfig.GetActivityTaskGroupName(_ActivityId)
    end
    
    function XMultiDimManager.CheckLimitTaskGroup()
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.MultiDim) then
            return false
        end
        
        local taskGroupIds = XMultiDimManager.GetActivityTaskGroupId()
        if XTool.IsTableEmpty(taskGroupIds) then
            return false
        end

        for _, taskGroupId in pairs(taskGroupIds) do
            if XDataCenter.TaskManager.CheckLimitTaskList(taskGroupId) then
                return true
            end
        end
        
        return false
    end
    
    function XMultiDimManager.GetActivityBannerThemeId()
        local themeIds = XMultiDimManager.GetThemeAllId()
        local maxThemeId = 1
        for _, themeId in pairs(themeIds) do
            local info = XMultiDimConfig.GetDifficultyInfoByThemeId(themeId)
            for _, config in pairs(info) do
                local isPass = XMultiDimManager.CheckTodayIsPass(config.Id)
                if isPass and themeId > maxThemeId then
                    maxThemeId = themeId
                end
            end
        end
        return maxThemeId
    end
    
    --endregion
    
    --region 副本相关
    
    -- 多人副本凌晨1点到9点关闭
    local _CloseStartHour = XMultiDimConfig.GetMultiDimConfigValue("MultiFubenCloseStartHour")
    local _CloseEndHour = XMultiDimConfig.GetMultiDimConfigValue("MultiFubenCloseEndHour")
    
    -- 设置关卡类型    
    function XMultiDimManager.InitStageInfo()
        -- 多维挑战多人
        local stageIds = XMultiDimConfig.GetMultiDimDifficultyStageId()
        for _, stageId in pairs(stageIds) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.MultiDimOnline
            end
        end
        local stageDatas = XMultiDimConfig.GetMultiSingleStageDatas()
        for stageId, value in pairs(stageDatas) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.MultiDimSingle
            end
        end
    end
    
    function XMultiDimManager.IsMultiDimStage(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        return stageInfo.Type == XDataCenter.FubenManager.StageType.MultiDimSingle or stageInfo.Type == XDataCenter.FubenManager.StageType.MultiDimOnline
    end

    function XMultiDimManager.OpenFightLoading(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if stageCfg.IsMultiplayer then
            XLuaUiManager.Open("UiOnLineLoading")
        else
            XDataCenter.FubenManager.OpenFightLoading(stageId)
        end
    end

    function XMultiDimManager.CloseFightLoading(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if stageCfg.IsMultiplayer then
            XLuaUiManager.Remove("UiOnLineLoading")
            XLuaUiManager.Remove("UiOnLineLoadingCute")
        else
            XDataCenter.FubenManager.CloseFightLoading(stageId)
        end
    end
    
    -- 胜利
    function XMultiDimManager.ShowReward(winData)
        if not winData then return end
        local stageId = winData.StageId
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo.Type == XDataCenter.FubenManager.StageType.MultiDimOnline then
            XLuaUiManager.PopThenOpen("UiMultiDimGrade",winData, function ()
                XLuaUiManager.PopThenOpen("UiMultiDimSettle", winData)
            end)
        else
            XLuaUiManager.Open("UiMultiDimSettle", winData, true)
        end
        stageInfo.Passed = true

        -- 多维单人刷新
        if stageInfo.Type == XDataCenter.FubenManager.StageType.MultiDimSingle then
            XEventManager.DispatchEvent(XEventId.EVENT_ON_MULTIDIM_SINGLE_CHANGED)
        end
    end

    function XMultiDimManager.GetCloseStartAndEndTimestamp()
        local closeStartTimestamp = XTime.GetTodayTime(tonumber(_CloseStartHour))
        local closeEndTimestamp = XTime.GetTodayTime(tonumber(_CloseEndHour))
        return closeStartTimestamp, closeEndTimestamp
    end
    
    -- 多人副本是否在开启 凌晨1点到9点是关闭时间
    function XMultiDimManager.CheckTeamIsOpen(isShowTip)
        local closeStartTimestamp, closeEndTimestamp = XMultiDimManager.GetCloseStartAndEndTimestamp()
        local now = XTime.GetServerNowTimestamp()
        if now > closeStartTimestamp and now < closeEndTimestamp then
            if isShowTip then
                local msg = CSXTextManagerGetText("MultiDimMainDetailNotTeamActivity", XMultiDimManager.GetTeamFubenOpenTimeText())
                XUiManager.TipMsg(msg)
            end
            return false
        end
        return true
    end
    -- 获取多人副本开启时间文本
    function XMultiDimManager.GetTeamFubenOpenTimeText()
        local closeStartTimestamp, closeEndTimestamp = XMultiDimManager.GetCloseStartAndEndTimestamp()
        -- 开启时间
        local startTimeStr = XTime.TimestampToGameDateTimeString(closeEndTimestamp, "H:mm")
        -- 结束时间
        local endTimeStr = XTime.TimestampToGameDateTimeString(closeStartTimestamp, "H:mm")
        return CSXTextManagerGetText("MultiDimTeamFubenOpenTimeText", startTimeStr, endTimeStr)
    end
    
    -- 组队进度
    function XMultiDimManager.GetMultiDimTeamProgress(themeId)
        local info = XMultiDimConfig.GetDifficultyInfoByThemeId(themeId)
        local passCount = 0
        local totalCount = #info

        for _, config in pairs(info) do
            local isPass = XMultiDimManager.CheckTodayIsPass(config.Id)
            if isPass then
                passCount = passCount + 1
            end
        end
        
        return passCount, totalCount
    end
    
    --endregion
    
    --region 主题相关
    
    local _DailyFirstPassThemeId = {} -- 主题每日首通 (每日首通打过保存在这里) key 是 主题id
    
    local function UpdateFirstPassThemeId(data)
        if XTool.IsTableEmpty(data) then
            return
        end
        for _, id in pairs(data) do
            _DailyFirstPassThemeId[id] = true
        end
    end
    -- _DailyFirstPassThemeId 包含当前themeId 表明首通已打过
    function XMultiDimManager.CheckDailyFirstPassThemeId(themeId)
        return _DailyFirstPassThemeId[themeId] or false
    end
    
    function XMultiDimManager.GetThemeAllId()
        return XMultiDimConfig.GetThemeAllId()
    end

    function XMultiDimManager.GetThemeNameById(id)
        return XMultiDimConfig.GetThemeNameById(id)
    end

    function XMultiDimManager.GetThemeDailyFirstPassRewardIdById(id)
        return XMultiDimConfig.GetThemeDailyFirstPassRewardIdById(id)
    end

    function XMultiDimManager.GetThemeModelId(id)
        return XMultiDimConfig.GetThemeModelId(id)
    end

    ---@description: 检查是否在主题开放时间内
    ---@params: 主题ID
    function XMultiDimManager.CheckThemeIsOpen(id)
        local timeId = XMultiDimConfig.GetThemeTimeIdById(id)
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    -- 开始时间文本
    function XMultiDimManager.GetThemeStartTimeText(id)
        local timeId = XMultiDimConfig.GetThemeTimeIdById(id)
        local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
        local startTimeStr = XTime.TimestampToGameDateTimeString(startTime, "MM/dd HH:mm")
        return CSXTextManagerGetText("MultiDimThemeOpenText", startTimeStr)
    end

    ---@description: 检查是否在每日首通
    ---@params: 主题ID
    function XMultiDimManager.CheckThemeIsFirstPassOpen(id)
        local timeId = XMultiDimConfig.GetThemeFirstPassTimeIdById(id)
        local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
        local isFight = XMultiDimManager.CheckDailyFirstPassThemeId(id)  -- 是否战斗过
        return isInTime and not isFight
    end


    function XMultiDimManager.GetMultiDimTheme(id)
        return XMultiDimConfig.GetMultiDimTheme(id)
    end

    function XMultiDimManager.GetMultiDimThemeDetail(id)
        return XMultiDimConfig.GetMultiDimThemeDetail(id)
    end

    --合并share和client的theme信息表 并获取
    function XMultiDimManager.GetMultiDimThemeData(id)
        if not next(ThemeData) then
            local themeDetialConfig = XMultiDimConfig.GetMultiDimThemeDetails()
            local themeConfig = XMultiDimConfig.GetMultiDimThemes()
            for themeId, value in pairs(themeDetialConfig) do
                if not ThemeData[themeId] then
                    ThemeData[themeId] = {}
                end

                for key, data in pairs(value) do
                    ThemeData[themeId][key] = data
                end

                for key, data in pairs(themeConfig[themeId]) do
                    ThemeData[themeId][key] = data
                end
            end
            
        end
        local config = ThemeData[id]
        if not config then
            return nil
        end
        return config
    end

    function XMultiDimManager.CheckThemeTeamFubenCondition(themeId)
        local conditionId = XMultiDimConfig.GetThemeMatchConditionIdById(themeId)
        if XTool.IsNumberValid(conditionId) then
            return XConditionManager.CheckCondition(conditionId)
        end
        return true, ""
    end

    --endregion
    
    --region 排行榜相关

    local XMultiDimFightRecord = require("XEntity/XMultiDim/XMultiDimFightRecord")
    
    local _FightRecordDic = {} -- 战斗记录
    local _MyRankInfo = {} -- 我的排行信息
    local _RankInfoDic = {} -- 排行信息
    local SYNC_RANK_LIST_SECOND = 60 -- 获取排行榜List请求保护时间
    local LastSyncRankListTime = {}   --排行榜List最后刷新时间

    local function GetFightRecord(themeId)
        if not XTool.IsNumberValid(themeId) then
            XLog.Error("XMultiDimManager GetFightRecord error: 获取战斗记录失败, themeId: ", themeId)
            return
        end
        
        local fightRecord = _FightRecordDic[themeId]
        if not fightRecord then
            fightRecord = XMultiDimFightRecord.New(themeId)
            _FightRecordDic[themeId] = fightRecord
        end
        return fightRecord
    end

    local function UpdateFightRecord(data)
        if not XTool.IsTableEmpty(data) then
            for _, info in pairs(data) do
                local themeId = info.ThemeId
                GetFightRecord(themeId):UpdatePoint(info.Point)
            end
        end
    end
    
    function XMultiDimManager.GetFightRecordPoint(themeId)
        ---@type XMultiDimFightRecord
        local fightRecord = GetFightRecord(themeId)
        return fightRecord:GetPoint()
    end

    local function UpdateRankDataTable(selectTable, rankType, themeId, data)
        if selectTable[rankType] == nil then
            selectTable[rankType] = {}
        end
        selectTable[rankType][themeId] = data
    end
    
    function XMultiDimManager.GetRankInfo(rankType, themeId)
        if not _RankInfoDic[rankType] then
            return {}
        end
        local rankInfo = _RankInfoDic[rankType][themeId]
        return rankInfo or {}
    end

    function XMultiDimManager.GetMyRankInfo(rankType, themeId)
        if not _MyRankInfo[rankType] then
            return nil
        end
        local rankInfo = _MyRankInfo[rankType][themeId]
        return rankInfo
    end
    
    -- 获取当前排名 默认值是"未挑战"
    function XMultiDimManager.GetCurrentRankMsg(rankType, themeId)
        local rankInfo = XMultiDimManager.GetMyRankInfo(rankType, themeId)
        -- 当前排名/玩家参与人数，显示百分比
        -- 若玩家位于1%以内，直接显示名次
        if rankInfo and rankInfo.Rank > 0 then
            local percentCount, percent = XMultiDimManager.GetSingleRankFringe(rankInfo.Rank, rankInfo.MemberCount, true)
            if rankInfo.Rank <= percentCount then
                return true, rankInfo.Rank
            else
                return true, string.format("%s%%", percent)
            end
        end
        return false, ""
    end

    -- 获取单人排行零界点（若玩家位于1%以内，直接显示名次 否则显示百分比）
    function XMultiDimManager.GetSingleRankFringe(rank, memberCount, isCalculatePercent)
        local count = XMultiDimConfig.GetMultiDimConfigValue("SingleRankFloor") --保底人数
        local maxCount = tonumber(count)
        if memberCount > maxCount then
            maxCount = memberCount
        end
        local singleRankPercent = XMultiDimConfig.GetMultiDimConfigValue("SingleRankPercent") -- 百分比（小数）
        local percentCount = maxCount * tonumber(singleRankPercent)
        local percent = 0
        if isCalculatePercent then
            percent = getRoundingValue((rank / maxCount) * 100, 1)
        end
        return percentCount, percent
    end
    
    -- 打开排行榜
    function XMultiDimManager.MultiDimOpenRankRequest(rankType, themeId, cb)
        -- 请求间隔保护
        local now = XTime.GetServerNowTimestamp()
        if LastSyncRankListTime[rankType] and 
                LastSyncRankListTime[rankType][themeId] and 
                LastSyncRankListTime[rankType][themeId] + SYNC_RANK_LIST_SECOND >= now then
            if cb then
                cb()
            end
            return
        end
        UpdateRankDataTable(LastSyncRankListTime, rankType, themeId, now)
        
        local req = { RankType = rankType, ThemeId = themeId }
        XNetwork.Call(RequestProto.MultiDimOpenRankRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            --[[
                //我的排行信息
                //多人排行榜，如果玩家在1000名以外，该值为空，显示榜外
                //单人排行榜，100名以内显示具体排名，以外显示百分比，用排名除以排行榜人数
                public XMultiDimRankInfo MyRankInfo;
            
                public List<XMultiDimRankInfo> RankList = new List<XMultiDimRankInfo>();
            ]]
            UpdateRankDataTable(_MyRankInfo, rankType, themeId, res.MyRankInfo)
            UpdateRankDataTable(_RankInfoDic, rankType, themeId, res.RankList)
            
            if cb then
                cb()
            end
        end)
    end
    --endregion
    
    --region 难度相关

    local _FirstPassDifficultyId = {} -- 首次通关难度 key 是 MultiDimDifficulty表的ID

    local function UpdateFirstPassDifficultyId(data)
        if XTool.IsTableEmpty(data) then
           return 
        end
        for _, id in pairs(data) do
            _FirstPassDifficultyId[id] = true
        end
    end
    
    function XMultiDimManager.CheckTodayIsPass(difficultyId)
        return _FirstPassDifficultyId[difficultyId] or false
    end
    
    function XMultiDimManager.GetDifficultyStageId(themeId, difficultyId)
        return XMultiDimConfig.GetDifficultyStageId(themeId, difficultyId)
    end

    function XMultiDimManager.GetDifficultyFirstPassReward(themeId, difficultyId)
        return XMultiDimConfig.GetDifficultyFirstPassReward(themeId, difficultyId)
    end
    
    function XMultiDimManager.GetDifficultyInfoByThemeId(themeId)
        return XMultiDimConfig.GetDifficultyInfoByThemeId(themeId)
    end

    function XMultiDimManager.GetDifficultyRecommendClass(themeId, difficultyId)
        return XMultiDimConfig.GetDifficultyRecommendClass(themeId, difficultyId)
    end

    function XMultiDimManager.GetDifficultyDetailInfo(themeId, difficultyId)
        return XMultiDimConfig.GetDifficultyDetailInfo(themeId, difficultyId)
    end

    function XMultiDimManager.GetDifficultyDetailName(themeId, difficultyId)
        return XMultiDimConfig.GetDifficultyDetailName(themeId, difficultyId)
    end
    -- 默认选择未通关的最低等级难度，如果全部通关默认选择最高等级难度
    function XMultiDimManager.GetCurrentThemeDefaultDifficultyId(themeId)
        local infos = XMultiDimConfig.GetDifficultyInfoByThemeId(themeId)
        local currentIndex = #infos
        for index, config in pairs(infos) do
            local isPass = XMultiDimManager.CheckTodayIsPass(config.Id)
            if not isPass and index < currentIndex then
                currentIndex = index
            end
        end
        return currentIndex
    end
    
    --endregion
    
    --region 职业相关
    local _PresetCareerId = {}  -- 预选职业 key MultiDimDifficulty表的ID value 职业id
    
    local function UpdatePrefabCareerId(prefabCareers)
        if not XTool.IsTableEmpty(prefabCareers) then
            for _, careerInfo in pairs(prefabCareers) do
                _PresetCareerId[careerInfo.DifficultyId] = careerInfo.CareerId
        end
    end
    end
    
    function XMultiDimManager.GetPresetCareerId(difficultyId)
        return _PresetCareerId[difficultyId] or 0  
    end
    
    function XMultiDimManager.GetMultiDimCareerIconTranspose(career)
        return XMultiDimConfig.GetMultiDimCareerIconTranspose(career)
    end

    function XMultiDimManager.GetMultiDimCareerName(career)
        return XMultiDimConfig.GetMultiDimCareerName(career)
    end

    function XMultiDimManager.GetMultiDimCareerInfo()
        return XMultiDimConfig.GetMultiDimCareerInfo()
    end
    
    -- 预选职业
    -- difficultyId 是MultiDimDifficulty表的ID
    function XMultiDimManager.MultiDimSelectCareerRequest(difficultyId, careerId, cb)
        local req = { DifficultyId = difficultyId, CareerId = careerId }

        XNetwork.Call(RequestProto.MultiDimSelectCareerRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            UpdatePrefabCareerId({ req })
            
            if cb then
                cb()
            end
        end)
    end
    
    --endregion
    
    --region 天赋相关
    
    local XMultiDimTalentInfo = require("XEntity/XMultiDim/XMultiDimTalentInfo")
    
    local _TalentInfoDic = {} 
    local _LastTalentResetTime = 0 -- 上次重置天赋时间
    local _TalentResetTime = XMultiDimConfig.GetMultiDimConfigValue("TalentResetCD") -- 获取重置天赋的冷却时间 （单位秒）
    local _TalentConditionId = XMultiDimConfig.GetMultiDimConfigValue("TalentConditionId") -- 天赋开启Condition

    local function GetTalentInfo(classId)
        if not XTool.IsNumberValid(classId) then
            XLog.Error("XMultiDimManager GetTalentInfo error: 获取天赋信息失败, classId: ", classId)
            return
        end
        
        local talentInfo = _TalentInfoDic[classId]
        if not talentInfo then
            talentInfo = XMultiDimTalentInfo.New(classId)
            _TalentInfoDic[classId] = talentInfo
        end
        return talentInfo
    end

    local function UpdateTalentInfo(data)
        if not XTool.IsTableEmpty(data) then
            for _, id in pairs(data) do
                local classId = XMultiDimConfig.GetMultiDimTalentClassId(id)
                GetTalentInfo(classId):UpdateData(id)
            end
        end
    end
    
    local function UpdateTalentResetTime(resetTime)
        if XTool.IsNumberValid(resetTime) then
            _LastTalentResetTime = resetTime
        end
    end

    function XMultiDimManager.GetTalentLevel(classId, typeId)
        ---@type XMultiDimTalentInfo
        local talentInfo = GetTalentInfo(classId)
        return talentInfo:GetTalentLevel(typeId)
    end
    -- 获取天赋点数
    function XMultiDimManager.GetTalentPoint(classId)
        ---@type XMultiDimTalentInfo
        local talentInfo = GetTalentInfo(classId)
        return talentInfo:GetCareerTalentPoint()
    end
    
    function XMultiDimManager.GetTalentName(classId, typeId)
        local level = XMultiDimManager.GetTalentLevel(classId, typeId)
        return XMultiDimConfig.GetMultiDimTalentName(classId, typeId, level)
    end

    function XMultiDimManager.GetTalentCostItemId(classId, typeId)
        local level = XMultiDimManager.GetTalentLevel(classId, typeId)
        return XMultiDimConfig.GetMultiDimTalentCostItemId(classId, typeId, level)
    end    
    
    function XMultiDimManager.GetTalentCostItemCount(classId, typeId)
        local level = XMultiDimManager.GetTalentLevel(classId, typeId)
        return XMultiDimConfig.GetMultiDimTalentCostItemCount(classId, typeId, level)
    end

    function XMultiDimManager.GetTalentIcon(classId, typeId)
        local level = XMultiDimManager.GetTalentLevel(classId, typeId)
        return XMultiDimConfig.GetMultiDimTalentIcon(classId, typeId, level)
    end    
    
    function XMultiDimManager.GetTalentDescription(classId, typeId, level)
        if not level then
            level = XMultiDimManager.GetTalentLevel(classId, typeId)
        end
        local desc = XMultiDimConfig.GetMultiDimTalentDescription(classId, typeId, level)
        return XUiHelper.ConvertLineBreakSymbol(desc)
    end    
    
    function XMultiDimManager.GetTalentIsHighLevel(classId, typeId)
        local level = XMultiDimManager.GetTalentLevel(classId, typeId)
        return XMultiDimConfig.GetMultiDimTalentIsHighLevel(classId, typeId, level)
    end
    
    function XMultiDimManager.GetTalentNextLevel(classId, typeId)
        local level = XMultiDimManager.GetTalentLevel(classId, typeId)
        return XMultiDimConfig.GetMultiDimTalentNextLevel(classId, typeId, level)
    end

    function XMultiDimManager.GetTalentId(classId, typeId)
        local level = XMultiDimManager.GetTalentLevel(classId, typeId)
        return XMultiDimConfig.GetMultiDimTalentId(classId, typeId, level)
    end
    -- 返回重置天赋冷却时间
    function XMultiDimManager.GetTalentResetCoolingTime()
        local now = XTime.GetServerNowTimestamp()
        return _LastTalentResetTime + tonumber(_TalentResetTime) - now
    end
    -- 判断当前是否在冷却时间
    function XMultiDimManager.CheckTalentResetCoolingTime()
        local now = XTime.GetServerNowTimestamp()
        if not XTool.IsNumberValid(_LastTalentResetTime) then
            return false
        end
        local isOpen = (now - _LastTalentResetTime) < tonumber(_TalentResetTime)
        return isOpen
    end
    
    function XMultiDimManager.CheckTalentIsOpen()
        local condition = tonumber(_TalentConditionId)
        if XTool.IsNumberValid(condition) then
            return XConditionManager.CheckCondition(condition)
        end
        return true, ""
    end
    
    -- 升级天赋
    function XMultiDimManager.MultiDimUpgradeTalentRequest(talentId, cb)
        local req = { TalentId = talentId }

        XNetwork.Call(RequestProto.MultiDimUpgradeTalentRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新天赋等级
            local data = { res.NextTalentId }
            if XTool.IsNumberValid(res.NextCoreTalentId) then -- 核心天赋没有升级会下发0
                table.insert(data, res.NextCoreTalentId)
            end
            UpdateTalentInfo(data)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_MULTI_DIM_TALENT_LEVEL_UPDATE)
            
            if cb then
                cb()
            end
        end)
    end
    -- 重置天赋
    function XMultiDimManager.MultiDimResetTalentRequest(classId, cb)
        local req = { ClassId = classId }

        XNetwork.Call(RequestProto.MultiDimResetTalentRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            -- 重置当前职业天赋
            if XTool.IsNumberValid(classId) then
                GetTalentInfo(classId):ResetTalent()
            else
                for _, talentInfo in pairs(_TalentInfoDic) do
                    talentInfo:ResetTalent()
                end
            end
            -- 刷新重置天赋的时间
            UpdateTalentResetTime(res.LastTalentResetTime)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_MULTI_DIM_TALENT_LEVEL_UPDATE)
            
            if cb then
                cb()
            end
        end)
    end
    --endregion
    
    --region 预选角色
    local XMultiDimPresetRoleData = require("XEntity/XMultiDim/XMultiDimPresetRoleData")
    
    local _PresetCharacterDic = {} -- 预选角色
    
    local function GetPresetCharacter(careerId)
        if not XTool.IsNumberValid(careerId) then
            XLog.Error("XMultiDimManager GetPresetCharacter error: 获取预选角色失败, careerId: ", careerId)
            return
        end
        
        local pressCharacter = _PresetCharacterDic[careerId]
        if not pressCharacter then
            pressCharacter = XMultiDimPresetRoleData.New(careerId)
            _PresetCharacterDic[careerId] = pressCharacter
        end
        return pressCharacter
    end

    local function UpdatePresetCharacterDic(data)
        if not XTool.IsTableEmpty(data) then
            for _, info in pairs(data) do
                local careerId = info.CareerId
                GetPresetCharacter(careerId):UpdateCharacterData(info.CharacterIds)
            end
        end
    end
    
    function XMultiDimManager.GetPresetCharacters(careerId)
        ---@type XMultiDimPresetRoleData
        local pressCharacter = GetPresetCharacter(careerId)
        return pressCharacter:GetEntityIds()
    end
    
    function XMultiDimManager.GetTeam(careerId)
        ---@type XMultiDimPresetRoleData
        local pressCharacter = GetPresetCharacter(careerId)
        return pressCharacter:GetTeam()
    end
    
    function XMultiDimManager.GetOwnCharacterListByFilterCareer(careerId, characterType)
        ---@type XMultiDimPresetRoleData
        local pressCharacter = GetPresetCharacter(careerId)
        return pressCharacter:GetOwnCharacterListByFilterCareer(characterType)
    end

    function XMultiDimManager.UpdateDefaultCharacterIds(careerId)
        ---@type XMultiDimPresetRoleData
        local pressCharacter = GetPresetCharacter(careerId)
        return pressCharacter:UpdateDefaultCharacterIds()
    end
    
    function XMultiDimManager.GetHighAbility(careerId)
        ---@type XMultiDimPresetRoleData
        local pressCharacter = GetPresetCharacter(careerId)
        return pressCharacter:GetHighAbility()
    end
    
    -- 预选角色
    function XMultiDimManager.MultiDimSelectCharacterRequest(careerId, characterIds, cb)
        local req = { CareerId = careerId, CharacterIds = characterIds }

        XNetwork.Call(RequestProto.MultiDimSelectCharacterRequest, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 更新保存的预选角色
            UpdatePresetCharacterDic({ req })
            
            if cb then
                cb()
            end
        end)
    end
    
    --endregion
    
    --region 房间内
    local _PrefabTeammateCareers = {}
    
    local _MatchStack = XStack.New()
    function XMultiDimManager.RefreshMatchCareer()
        _MatchStack:Clear()
        local matchDic = {}
        local roomData = XDataCenter.RoomManager.RoomData
        if not roomData or (not roomData.RecommendClass) or (#roomData.RecommendClass == 0) then
            return
        end
        for _, recommendCareer in pairs(roomData.RecommendClass) do
            if not matchDic[recommendCareer] then
                matchDic[recommendCareer] = 1
            else
                matchDic[recommendCareer] = matchDic[recommendCareer] + 1                
            end
        end

        for _, playerData in pairs(roomData.PlayerDataList) do
            local cfg = XMultiDimConfig.GetMultiDimCharacterCareer(playerData.FightNpcData.Character.Id)
            if matchDic[cfg.Career] and matchDic[cfg.Career] > 0 then
                matchDic[cfg.Career] = matchDic[cfg.Career] - 1
            else
                for k,v in pairs(matchDic) do
                    if v > 0 then
                        matchDic[k] = matchDic[k] - 1
                        break
                    end
                end
            end
        end

        for career,count in pairs(matchDic) do
            if count > 0 then
                for i = 1, count do
                    _MatchStack:Push(career)
                end
            end
        end
    end
    
    function XMultiDimManager.GetMatchCareer()
        if _MatchStack:IsEmpty() then
            XMultiDimManager.RefreshMatchCareer()
        end
        return _MatchStack:Pop()
    end
    
    local function UpdatePrefabTeammateCareers(data)
        for _, info in pairs(data) do
            _PrefabTeammateCareers[info.DifficultyId] = info
        end
    end
    
    function XMultiDimManager.GetPrefabTeammateCareers(id)
        if _PrefabTeammateCareers[id] then
            return _PrefabTeammateCareers[id].Careers
        end
    end
    

    function XMultiDimManager.SelectTeammatesCareer(difficultyId, pos, career,cb)
        local req = { DifficultyId = difficultyId, TeamPos = pos,CareerId = career }

        XNetwork.Call(RequestProto.MultiDimSelectTeamMatesCareer, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if _PrefabTeammateCareers[difficultyId] then
                _PrefabTeammateCareers[difficultyId].Careers[pos - 1] = career
            else
                _PrefabTeammateCareers[difficultyId] = {DifficultyId = difficultyId, Careers = {}}
                _PrefabTeammateCareers[difficultyId].Careers[pos - 1] = career
            end
            if cb then
                cb()
            end
        end)
    end
    
    function XMultiDimManager.ChangeRecommendCareer(oldCareer, newCareer,cb)
        local req = {
            BeforeClassId = oldCareer,
            AfterClassId = newCareer
        }
        XNetwork.Call(RequestProto.MultiDimChangeRecommendCareer,req,function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end
    
    --endregion
    
    --region 保存本地信息
    
    -- 是否点击过
    function XMultiDimManager.CheckClickMainTeamFightBtn(themeId)
        local key = XMultiDimManager.GetFirstRewardKey(themeId)
        local timeData = XSaveTool.GetData(key) or 0
        local currentTime = XTime.GetSeverTodayFreshTime()
        
        return timeData and currentTime == timeData
    end

    function XMultiDimManager.GetFirstRewardKey(themeId)
        if XPlayer.Id and _ActivityId then
            return string.format("%s_%s_%s_%s", XMultiDimConfig.MultiDimFirstReward, tostring(XPlayer.Id), tostring(_ActivityId), tostring(themeId))
        end
    end
    
    function XMultiDimManager.GetMultiDimActivityKey(key)
        if XPlayer.Id and _ActivityId then
            return string.format("%s_%s_%s", key, tostring(XPlayer.Id), tostring(_ActivityId))
        end
    end
    
    function XMultiDimManager.CheckThemeOpenOnceDialog()
        local key = XMultiDimManager.GetMultiDimActivityKey(XMultiDimConfig.MultiDimThemeUnlock)
        local isUnlock = XSaveTool.GetData(key) or false
        return isUnlock
    end
    
    function XMultiDimManager.GetDefaultActivityThemeId()
        local key = XMultiDimManager.GetMultiDimActivityKey(XMultiDimConfig.MultiDimDefaultThemeId)
        local themeId = XSaveTool.GetData(key) or 0
        return themeId
    end
    
    function XMultiDimManager.SaveDefaultActivityThemeId(value)
        local key = XMultiDimManager.GetMultiDimActivityKey(XMultiDimConfig.MultiDimDefaultThemeId)
        local themeId = XSaveTool.GetData(key)
        if themeId and themeId == value then
            return
        end
        XSaveTool.SaveData(key, value)
    end
    
    --endregion
    
    --region 服务端下发

    function XMultiDimManager.RefreshSingleStageData(singleStageIds)
        if not singleStageIds then
            return
        end
        for key, stageId in pairs(singleStageIds) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Passed = true
            end
        end
    end
    
    local function ResetData()
        _ActivityId = 0 -- 当前开发活动ID
        _PresetCharacterDic = {} -- 预选角色
        _DailyFirstPassThemeId = {} -- 主题每日首通
        _FirstPassDifficultyId = {} -- 首次通关难度
        _MyRankInfo = {} -- 我的排行信息
        _RankInfoDic = {} -- 排行信息
        _PresetCareerId = {} -- 预选职业
        _LastTalentResetTime = 0 -- 上次重置天赋时间
        _TalentInfoDic = {}
        _FightRecordDic = {} -- 战斗记录
        LastSyncRankListTime = {}   --排行榜List最后刷新时间
    end
    
    --[[
    public class NotifyMultiDimActivityData
    {
        public int ActivityNo;
        //天赋
        public HashSet<int> Talents = new HashSet<int>();        
        //已通过单人副本ID
        public HashSet<int> SingleStageId = new HashSet<int>();       
        //主题每日首通
        public HashSet<int> DailyFirstPassThemeId = new HashSet<int>();        
        //首次通关难度，MultiDimDifficulty表的ID
        public HashSet<int> FirstPassDifficultyId = new HashSet<int>();        
        //战斗记录
        public List<XMultiDimFightRecord> FightRecords = new List<XMultiDimFightRecord>();        
        //预选职业
        public List<XMultiDimPrefabCareer> PrefabCareers = new List<XMultiDimPrefabCareer>();
        //预选角色
        public List<XMultiDimPrefabCharacter> PrefabChacaterIds = new List<XMultiDimPrefabCharacter>();
        //上次重置天赋时间
        public long LastTalentResetTime;
    }
    ]]
    -- 登录下发
    function XMultiDimManager.NotifyMultiDimActivityData(data)
        local activityId = data.ActivityNo
        if XTool.IsNumberValid(_ActivityId) and activityId ~= _ActivityId then
            ResetData()
        end

        UpdateActivityId(activityId)
        UpdateTalentInfo(data.Talents)
        XMultiDimManager.RefreshSingleStageData(data.SingleStageId)
        UpdateFirstPassThemeId(data.DailyFirstPassThemeId)
        UpdateFirstPassDifficultyId(data.FirstPassDifficultyId)
        UpdateFightRecord(data.FightRecords)
        UpdatePrefabCareerId(data.PrefabCareers)
        UpdatePresetCharacterDic(data.PrefabChacaterIds)
        UpdateTalentResetTime(data.LastTalentResetTime)
        UpdatePrefabTeammateCareers(data.PrefabTeammateCareers)
    end
    --[[
    public class NotifyMultiDimDailyFirstPassUpdate
    {
        //主题每日首通
        public HashSet<int> DailyFirstPassThemeId = new HashSet<int>();
    }
    ]]
    -- 主题每日首通更新
    function XMultiDimManager.NotifyMultiDimDailyFirstPassUpdate(data)
        UpdateFirstPassThemeId(data.DailyFirstPassThemeId)
    end
    --[[
    public class NotifyMultiDimDifficultyFirstPassUpdate
    {
        //首次通关难度，MultiDimDifficulty表的ID
        public HashSet<int> FirstPassDifficultyId = new HashSet<int>();
    }
    ]]
    -- 难度首通更新
    function XMultiDimManager.NotifyMultiDimDifficultyFirstPassUpdate(data)
        UpdateFirstPassDifficultyId(data.FirstPassDifficultyId)
    end
    --[[
    public class NotifyMultiDimFightRecordUpdate
    {
        //战斗记录
        public List<XMultiDimFightRecord> FightRecords = new List<XMultiDimFightRecord>();
    }
    ]]
    -- 战斗记录更新
    function XMultiDimManager.NotifyMultiDimFightRecordUpdate(data)
        UpdateFightRecord(data.FightRecords)
    end
    --endregion
    
    function XMultiDimManager.Init()
    end
    
    XMultiDimManager.Init()
    return XMultiDimManager
end

XRpc.NotifyMultiDimActivityData = function(data)
    XDataCenter.MultiDimManager.NotifyMultiDimActivityData(data)
end

XRpc.NotifyMultiDimDailyFirstPassUpdate = function(data)
    XDataCenter.MultiDimManager.NotifyMultiDimDailyFirstPassUpdate(data)
end

XRpc.NotifyMultiDimDifficultyFirstPassUpdate = function(data)
    XDataCenter.MultiDimManager.NotifyMultiDimDifficultyFirstPassUpdate(data)
end

XRpc.NotifyMultiDimFightRecordUpdate = function(data)
    XDataCenter.MultiDimManager.NotifyMultiDimFightRecordUpdate(data)
end