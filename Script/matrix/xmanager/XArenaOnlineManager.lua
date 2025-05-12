XArenaOnlineManagerCreator = function()
    local XArenaOnlineManager = {}

    local AreaChanged = false           --区域是否改变
    local NextRefreshTime = 0           -- 下一次副本刷新时间
    local AssistCount = 0               -- 助战总次数
    local StagePassCount = {}           -- 通关次数
    local ScetionData = {}              -- 小节数据
    local StageInfodData = {}           -- 关卡数据
    local CurCapterId = 0               -- 当前章节ID
    local CurSectionId = 0              -- 当前小节ID
    local CurChallengeId = 0            -- 单机模式下当前挑战ID
    local FubenStageStrs = {}           -- 副本星数
    local CharEndurances = {}           -- 角色耐力
    local FirstPassCount = 0            -- 首通总次数
    local FirstPassList = {}            -- 首通关卡
    local PlayerTeamData = {}
    local TypeId = CS.XGame.Config:GetInt("TypeIdArenaOnline")
    local DefaultTeam = {
        CaptainPos = 1,
        FirstFightPos = 1,
        TeamData = { 0, 0, 0 },
    }

    local InFightChangeCache = false    -- 是否在战斗中缓存

    local sec_of_refresh_time = 5 * 60 * 60

    local SetAreasInfo = function(areas)
        ScetionData = {}
        StageInfodData = {}
        for _, v in ipairs(areas) do
            if not ScetionData[v.Id] then
                ScetionData[v.Id] = {}
                ScetionData[v.Id].Id = v.Id
                ScetionData[v.Id].OpenDays = {}
                ScetionData[v.Id].Stages = {}
                ScetionData[v.Id].GroupId = v.GroupId
            end

            local section = XArenaOnlineConfigs.GetSectionById(v.Id)
            for _, day in ipairs(section.OpenDays) do
                local weekOfSun = 7
                local weekOfDeflautSun = 0
                if day == weekOfDeflautSun then
                    table.insert(ScetionData[v.Id].OpenDays, weekOfSun)
                else
                    table.insert(ScetionData[v.Id].OpenDays, day)
                end
            end

            local group = XArenaOnlineConfigs.GetStageGroupById(v.GroupId)
            for _, stageId in ipairs(group.StageIds) do
                table.insert(ScetionData[v.Id].Stages, stageId)
                if not StageInfodData[stageId] then
                    StageInfodData[stageId] = {}
                    local stageCfg = XArenaOnlineConfigs.GetStageById(stageId)
                    StageInfodData[stageId].BuffIds = stageCfg.EventId
                end
            end

            table.sort(ScetionData[v.Id].OpenDays, function(a, b)
                    return a < b
                end)

            table.sort(ScetionData[v.Id].Stages, function(a, b)
                    local sortA =  XArenaOnlineConfigs.GetStageSortByStageId(a)
                    local sortB =  XArenaOnlineConfigs.GetStageSortByStageId(b)
                    return sortA < sortB
                end)
        end
    end
    
    --重置stageInfo数据
    function XArenaOnlineManager.ResetStageInfo()
        local arenaOnlineCfgs = XArenaOnlineConfigs.GetStages()
        for _, cfg in pairs(arenaOnlineCfgs) do
            for _, id in pairs(cfg.Difficulty) do
                local levelControl = XFubenConfigs.GetStageMultiplayerLevelControlCfgById(id)
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(levelControl.StageId)
                if stageInfo then
                    stageInfo.Passed = false
                end
            end
            for _, id in pairs(cfg.SingleDiff) do
                local levelControl = XFubenConfigs.GetStageMultiplayerLevelControlCfgById(id)
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(levelControl.StageId)
                if stageInfo then
                    stageInfo.Passed = false
                end
            end
        end
    end

    function XArenaOnlineManager.OpenFightLoading(stageId)
        local roomData = XDataCenter.RoomManager.RoomData
        if roomData then
            XLuaUiManager.Open("UiOnLineLoading")
        else
            XDataCenter.FubenManager.OpenFightLoading(stageId)
        end
    end

    function XArenaOnlineManager.CloseFightLoading()
        local roomData = XDataCenter.RoomManager.RoomData
        if roomData then
            XLuaUiManager.Remove("UiOnLineLoading")
            XLuaUiManager.Remove("UiOnLineLoadingCute")
        else
            XDataCenter.FubenManager.CloseFightLoading()
        end
    end

    -- 处理成为客户端需要的联机数据
    function XArenaOnlineManager.HandlerLoginData(data)
        NextRefreshTime = data.NextRefreshTime
        AreaChanged = false
        AssistCount = data.AssistCount
        FirstPassCount = data.FirstPassCount
        SetAreasInfo(data.Areas)
        FubenStageStrs = {}

        if data.Stars and #data.Stars > 0 then
            for _, v in ipairs(data.Stars) do
                local count = (v.StarsMark & 1) + (v.StarsMark & 2 > 0 and 1 or 0) + (v.StarsMark & 4 > 0 and 1 or 0)
                local map = {(v.StarsMark & 1) > 0, (v.StarsMark & 2) > 0, (v.StarsMark & 4) > 0 }
                FubenStageStrs[v.StageId] = {}
                FubenStageStrs[v.StageId].Count = count
                FubenStageStrs[v.StageId].StarsMap = map
            end
        end

        CharEndurances = {}
        if data.EnduranceList and #data.EnduranceList > 0 then
            for _, v in ipairs(data.EnduranceList) do
                CharEndurances[v.CharacterId] = v.EnduranceCount
            end
        end

        StagePassCount = {}
        if data.Bottoms and #data.Bottoms > 0 then
            for _, v in ipairs(data.Bottoms) do
                local key = tostring(v.DropId) .. tostring(v.BottomId)
                StagePassCount[key] = v.CurLevel
            end
        end

        FirstPassList = {}
        if data.FirstPassList and #data.FirstPassList > 0 then
            for _, v in ipairs(data.FirstPassList) do
                XArenaOnlineManager.HandlerStagePass(v)
            end
        end
    end

    -- 获取开启章节
    function XArenaOnlineManager.GetArenaOnlineChapters()
        local list = {}
        local defualtList = {}
        local level = XPlayer.Level
        local chapters = XArenaOnlineConfigs.GetChapters()
        local defaultChapterId = XArenaOnlineConfigs.DEFAULT_CHAPTERID
        for _, v in pairs(chapters) do
            if v.Id == defaultChapterId then
                table.insert(defualtList, v)
            end

            if level >= v.MinLevel and level <= v.MaxLevel then
                table.insert(list, v)
            end
        end
        table.sort(list, function(a, b)
                return a.Id < b.Id
            end)

        return #list > 0 and list or defualtList
    end

    -- 获取小节数据
    function XArenaOnlineManager.GetSectionData()
        local list = {}
        local chapter = XArenaOnlineManager.GetCurChapterCfg()
        if not chapter then return list end

        for _, sectionId in ipairs(chapter.SectionId) do
            if ScetionData[sectionId] then
                table.insert(list, ScetionData[sectionId])
            end
        end
        return list
    end

    -- 获取角色耐力值
    function XArenaOnlineManager.GetCharEndurance(characterId)
        return CharEndurances[characterId] or 0
    end

    -- 获取当前单个小节
    function XArenaOnlineManager.GetCurSectionData()
        local data = ScetionData[CurSectionId]
        if not data then
            return nil
        end

        return data
    end

    -- 获取当前单个小节Prefab
    function XArenaOnlineManager.GetCurSectionPrefabPath()
        local data = ScetionData[CurSectionId]
        if not data or not data.GroupId then
            return nil
        end
        return XArenaOnlineConfigs.GetStageGroupPrefabPathById(data.GroupId)
    end
    -- 获取当前单个小节Icon
    function XArenaOnlineManager.GetCurSectionIcon(sectionid)
        local data = ScetionData[sectionid]
        if not data or not data.GroupId then
            return nil
        end
        return XArenaOnlineConfigs.GetStageGroupIconById(data.GroupId)
    end
    -- 获取下次刷新时间
    function XArenaOnlineManager.GetNextRefreshTime()
        return NextRefreshTime
    end

    -- 获取首通总次数
    function XArenaOnlineManager.GetFirstPassCount()
        return FirstPassCount
    end

    -- 获取通关总次数
    function XArenaOnlineManager.GetStageTotalCount(stageId)
        return XArenaOnlineConfigs.GetStageBottomCountByStageId(stageId)
    end

    -- 获取当前通关次数
    function XArenaOnlineManager.GetStagePassCount(stageId)
        local key = XArenaOnlineConfigs.GetStageDropKeyByStageId(stageId)
        return StagePassCount[key] or 0
    end

    -- 获取上一次助战次数
    function XArenaOnlineManager.GetLastAssistCount()
        return AssistCount - 1 > 0 and AssistCount - 1 or 0
    end

    -- 获取助战次数
    function XArenaOnlineManager.GetAssistCount()
        return AssistCount or 0
    end

    -- 通过副本StageId获取联机关卡Config
    function XArenaOnlineManager.GetArenaOnlineStageCfgStageId(stageId)
        return XArenaOnlineConfigs.GetStageById(stageId)
    end

    -- 通过副本StageId获取联机关卡同调Config
    function XArenaOnlineManager.GetActiveBuffCfgByStageId(stageId)
        local stageCfg = XArenaOnlineConfigs.GetStageById(stageId)
        local activeBuffId = stageCfg.ActiveBuffId
        return XArenaOnlineConfigs.GetActiveBuffById(activeBuffId)
    end

    -- 通过联机StageId获取副本Info
    function XArenaOnlineManager.GetStageInfo(stageId)
        local id = XArenaOnlineManager.GetStageId(stageId)
        if id then
            -- XLog.Warning(stageId,id,XDataCenter.FubenManager.GetStageInfo(id))
            return XDataCenter.FubenManager.GetStageInfo(id)
        end
        return XDataCenter.FubenManager.GetStageInfo(stageId)
    end
    
    function XArenaOnlineManager.GetLevelControl(id)
        local data = XDataCenter.RoomManager.RoomData
        local level = 1
        if data and data.ChallengeLevel then
            level = data.ChallengeLevel
        end
        local stageInfo
        local cfg = XArenaOnlineConfigs.GetStageById(id)
        if cfg and cfg.Difficulty[level] then
            local id = cfg.Difficulty[level]
            return XFubenConfigs.GetStageMultiplayerLevelControlCfgById(id)
        end
    end
    
    function XArenaOnlineManager.GetStageIdByIdAndLevel(id, level)
        local stageInfo
        local cfg = XArenaOnlineConfigs.GetStageById(id)
        if cfg and cfg.Difficulty[level] then
            local id = cfg.Difficulty[level]
            local levelControl = XFubenConfigs.GetStageMultiplayerLevelControlCfgById(id)
            return levelControl.StageId
        end
    end
    
    function XArenaOnlineManager.GetStageId(id)
        local levelControl = XArenaOnlineManager.GetLevelControl(id)
        if levelControl then
            return levelControl.StageId
        end
    end

    -- 通过副本ChallengeId获取副本星数
    function XArenaOnlineManager.GetStageStarsByChallengeId(challengeId)
        return FubenStageStrs[challengeId] and FubenStageStrs[challengeId].Count or 0
    end

    -- 通过ChallengeId获取副本星数Map
    function XArenaOnlineManager.GetStageStarsMapByChallengeId(challengeId)
        if not FubenStageStrs[challengeId] then
            return {false, false, false}
        else
            return FubenStageStrs[challengeId].StarsMap
        end
    end

    -- 检查当前构造体是否满足同调
    function XArenaOnlineManager.CheckActiveBuffOnByCharId(charId)
        local challengeId = XArenaOnlineManager.GetCurChallengeId()
        local buffCfg = XArenaOnlineManager.GetActiveBuffCfgByStageId(challengeId)
        local minQulity = XMVCA.XCharacter:GetCharMinQuality(charId)
        return minQulity <= buffCfg.Quality
    end

    -- 检查关卡是否通关
    function XArenaOnlineManager.CheckStagePass(challengeId)
        if not challengeId then return false end
        local cfg = XArenaOnlineConfigs.GetStageById(challengeId)
        if cfg then
            --三种难度只要一种通过即为通过
            for _,levelControlId in ipairs(cfg.Difficulty) do
                local levelControlCfg = XFubenConfigs.GetStageMultiplayerLevelControlCfgById(levelControlId)
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(levelControlCfg.StageId)
                if stageInfo.Passed then
                    return true
                end
            end
            for _,levelControlId in ipairs(cfg.SingleDiff) do
                local levelControlCfg = XFubenConfigs.GetStageMultiplayerLevelControlCfgById(levelControlId)
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(levelControlCfg.StageId)
                if stageInfo.Passed then
                    return true
                end
            end
        end
        return false

        -- local cfg = XArenaOnlineManager.GetArenaOnlineStageCfgStageId(challengeId)
        -- local levelControl = XFubenConfigs.GetStageMultiplayerLevelControlCfgById(cfg.SingleDiff[1])
        -- local stageId = levelControl.StageId
        -- local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        -- return stageInfo.Passed
    end

    -- 判断是否符合当前模式
    function XArenaOnlineManager.CheckStageIsArenaOnline(stageId)
        local info = XDataCenter.FubenManager.GetStageInfo(stageId)
        return info and info.Type == XDataCenter.FubenManager.StageType.ArenaOnline
    end

    -- 获取单人模式对应的难度等级，同时保存挑战Id
    function XArenaOnlineManager.GetSingleModeDifficulty(challengeId, isSave)
        local cfg = XDataCenter.ArenaOnlineManager.GetArenaOnlineStageCfgStageId(challengeId)
        local levelControlCfg = XFubenConfigs.GetStageMultiplayerLevelControlCfgById(cfg.SingleDiff[1])
        if isSave then
            CurChallengeId = challengeId
        end
        return levelControlCfg.Difficulty
    end

    -- 判断当前是否为单机模式
    function XArenaOnlineManager.CheckSingleMode()
        return XDataCenter.RoomManager.RoomData == nil
    end

    -- 获取当前挑战id
    function XArenaOnlineManager.GetCurChallengeId()
        if XDataCenter.RoomManager.RoomData then
            return XDataCenter.RoomManager.RoomData.ChallengeId
        else
            return CurChallengeId
        end
    end

    -- 获取所有关卡进度
    function XArenaOnlineManager.GetStageSchedule()
        local passCount = 0
        local allCount = 0
        local list = XArenaOnlineManager.GetArenaOnlineChapters()
        if not list or #list <= 0 then
            return passCount, allCount
        end
        CurCapterId = list[1].Id

        local sectionList = {}
        local chapter = XArenaOnlineManager.GetCurChapterCfg()
        if not chapter then
            return passCount, allCount
        end

        for _, sectionId in ipairs(chapter.SectionId) do
            if ScetionData[sectionId] then
                sectionList[sectionId] = ScetionData[sectionId]
            end
        end

        for _, v in pairs(sectionList) do
            for _, challengeId in ipairs(v.Stages) do
                allCount = allCount + 1
                if XArenaOnlineManager.CheckStagePass(challengeId) then
                    passCount = passCount + 1
                end
            end
        end
        return passCount, allCount
    end

    -- 获取小节关卡进度
    function XArenaOnlineManager.GetStageScheduleByScetionId(sectionId)
        local passCount = 0
        local allCount = 0
        local scetion = ScetionData[sectionId]
        if not scetion then
            return passCount, allCount
        end

        for _, challengeId in ipairs(scetion.Stages) do
            allCount = allCount + 1
            if XArenaOnlineManager.CheckStagePass(challengeId) then
                passCount = passCount + 1
            end
        end
        return passCount, allCount
    end

    -- 判断小节是否开启
    function XArenaOnlineManager.CheckSectionLeftTime(sectionId)
        local scetion = ScetionData[sectionId]
        if not scetion then
            return -1
        end

        local freshNow = XTime.GetServerNowTimestamp() - sec_of_refresh_time
        local severDay = XTime.GetWeekDay(freshNow, true)
        local nextOpenDay = scetion.OpenDays[1]
        for _, day in ipairs(scetion.OpenDays) do
            if day == severDay then
                return 0
            elseif day > severDay then
                nextOpenDay = day
                break
            end
        end

        return XTime.GetNextWeekOfDayStartWithMon(nextOpenDay, sec_of_refresh_time)
    end

    -- 获取通关条件数量
    function XArenaOnlineManager.GetStarInfoBySectionid(sectionId)
        local stars = 0
        local allStars = 0
        local scetion = ScetionData[sectionId]
        if not scetion then
            return stars, allStars
        end

        allStars = XArenaOnlineConfigs.GetStageGroupRequireStar(scetion.GroupId)
        for _, challengeId in ipairs(scetion.Stages) do
            stars = stars + XArenaOnlineManager.GetStageStarsByChallengeId(challengeId)
        end

        return stars, allStars
    end

    -- 获取关卡信息
    function XArenaOnlineManager.GetArenaOnlineStageInfo(stageId)
        local data = StageInfodData[stageId]
        if not data then
            XLog.Error("XArenaOnlineManager.GetArenaOnlineStageInfo not found by id : " .. tostring(stageId))
            return nil
        end
        return data
    end

    -- 获取当前联机关卡耐力消耗
    function XArenaOnlineManager.GetStageEndurance(challengeId)
        if not XDataCenter.RoomManager.RoomData and not challengeId then
            return 0
        end

        local stageId = challengeId or XDataCenter.RoomManager.RoomData.ChallengeId
        return XArenaOnlineConfigs.GetStageEnduranceCostByStageId(stageId)
    end

    -- 检查是否更新
    function XArenaOnlineManager.CheckTimeOut()
        if NextRefreshTime == nil then
            return false
        end
        local curTime = XTime.GetServerNowTimestamp()
        local offset = NextRefreshTime - curTime
        return offset <= 0
    end

    -- 设置当前章节ID
    function XArenaOnlineManager.SetCurChapterId()
        if CurCapterId > 0 then return end

        local list = XArenaOnlineManager.GetArenaOnlineChapters()
        if not list or #list <= 0 then return end
        CurCapterId = list[1].Id
    end

    -- 获取当前章节配置表
    function XArenaOnlineManager.GetCurChapterCfg()
        if CurCapterId <= 0 then
            return nil
        end

        return XArenaOnlineConfigs.GetChapterById(CurCapterId)
    end

    -- 获取当前小节配置表
    function XArenaOnlineManager.GetCurSectionCfg()
        if CurSectionId <= 0 then
            return nil
        end

        return XArenaOnlineConfigs.GetSectionById(CurSectionId)
    end

    -- 检查当前小节是否需要日刷新
    function XArenaOnlineManager.CheckCurSectionDayRefrsh()
        if CurSectionId <= 0 then
            return true
        end

        local section = ScetionData[CurSectionId]
        if not section then
            return true
        end

        local freshNow = XTime.GetServerNowTimestamp()
        local severDay = XTime.GetWeekDay(freshNow, true)
        for _, day in ipairs(section.OpenDays) do
            if day == severDay then
                return false
            end
        end

        return true
    end

    -- 打开区域联机详情
    function XArenaOnlineManager.OpenArenaOnlineChapter(chapterId)
        CurCapterId = chapterId
        XLuaUiManager.Open("UiArenaOnlineChapter")
    end

    -- 打开区域联机小节详情
    function XArenaOnlineManager.OpenArenaOnlineSection(sectionId)
        CurSectionId = sectionId
        XLuaUiManager.Open("UiArenaOnlineSection")
    end

    -- 判斷好友邀請是否提示
    function XArenaOnlineManager.CheckInviteTipShow()
        -- local key = XPrefs.ArenaOnlineInvit.. tostring(XPlayer.Id)
        -- local isShow = true
        -- if CS.UnityEngine.PlayerPrefs.HasKey(key) then
        --     local time = CS.UnityEngine.PlayerPrefs.GetInt(key)
        --     local now = XTime.GetServerNowTimestamp()
        --     isShow = now > time
        -- end

        -- return isShow
        return XDataCenter.SetManager.InviteButton == 1
    end

    -- 处理今日不在提示逻辑
    function XArenaOnlineManager.SetInviteTip()
        local key = XPrefs.ArenaOnlineInvit.. tostring(XPlayer.Id)
        local time = XTime.GetSeverTomorrowFreshTime()
        CS.UnityEngine.PlayerPrefs.SetInt(key, time)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    -- 判断是否第一次打开
    function XArenaOnlineManager.CheckFirstOpen()
        local cfg = XArenaOnlineManager.GetCurChapterCfg()
        local key = XPrefs.ArenaOnlineFirstOpen .. tostring(XPlayer.Id) .. tostring(cfg.StoryId)

        return not CS.UnityEngine.PlayerPrefs.HasKey(key)
    end

    -- 设置第一次打开
    function XArenaOnlineManager.SetFirstOpen()
        local cfg = XArenaOnlineManager.GetCurChapterCfg()
        local key = XPrefs.ArenaOnlineFirstOpen .. tostring(XPlayer.Id) .. tostring(cfg.StoryId)
        local time = XTime.GetSeverTomorrowFreshTime()
        CS.UnityEngine.PlayerPrefs.SetInt(key, time)
        CS.UnityEngine.PlayerPrefs.Save()
    end

    function XArenaOnlineManager.ShowReward(winData)
        if XDataCenter.FubenManager.CheckHasFlopReward(winData, true) then
            XLuaUiManager.Open("UiFubenFlopReward", function()
                XArenaOnlineManager.OpenSettleUi(winData)
            end, winData)
        else
            XArenaOnlineManager.OpenSettleUi(winData)
        end
    end

    function XArenaOnlineManager.OpenSettleUi(winData)
        if XDataCenter.RoomManager.RoomData then
            XLuaUiManager.PopThenOpen("UiMultiplayerFightGrade", function ()
                    XLuaUiManager.PopThenOpen("UiSettleWinMainLine", winData)
            end)
        else
            XLuaUiManager.PopThenOpen("UiSettleWinMainLine", winData)
        end
    end

    -- 处理战斗结算数据
    function XArenaOnlineManager.HandlerFightEndData(data)
        AssistCount = data.AssistCount
        FirstPassCount = data.FirstPassCount

        local t = data.Star
        local count = (t.StarsMark & 1) + (t.StarsMark & 2 > 0 and 1 or 0) + (t.StarsMark & 4 > 0 and 1 or 0)
        local map = {(t.StarsMark & 1) > 0, (t.StarsMark & 2) > 0, (t.StarsMark & 4) > 0 }
        if not FubenStageStrs[t.StageId] then
            FubenStageStrs[t.StageId] = {}
        end
        FubenStageStrs[t.StageId].Count = count
        FubenStageStrs[t.StageId].StarsMap = map

        for k, v in ipairs(data.EnduranceList) do
            CharEndurances[v.CharacterId] = v.EnduranceCount
        end
        -- CharEndurances[data.Endurance.CharacterId] = data.Endurance.EnduranceCount

        if data.Bottom then
            local key = tostring(data.Bottom.DropId) .. tostring(data.Bottom.BottomId)
            StagePassCount[key] = data.Bottom.CurLevel
        end
        XArenaOnlineManager.HandlerStagePass(data.PassInfo)
    end

    -- 处理已通关卡
    function XArenaOnlineManager.HandlerStagePass(data)
        if data then
            FirstPassList[data.StageId] = data
            local stageInfo = XDataCenter.ArenaOnlineManager.GetStageInfo(data.StageId)
            if stageInfo then
                stageInfo.Passed = true
            end
            if next(data.SingleCharacterIds) then
                local teamData = {}
                teamData.TeamData =  data.SingleCharacterIds

                for k,v in ipairs(data.SingleCharacterIds) do
                    if v == data.CaptainId then
                        teamData.CaptainPos = k
                    end
                    if v == data.FirstFightId then
                        teamData.FirstFightPos = k
                    end
                end
                PlayerTeamData[data.StageId] = teamData
            end
        end
    end

    function XArenaOnlineManager.GetPlayerTeam(challengeId)
        local teamId = XDataCenter.TeamManager.GetTeamId(TypeId)

        if PlayerTeamData[challengeId] then
            PlayerTeamData[challengeId].TeamId = teamId
            return XTool.Clone(PlayerTeamData[challengeId])
        else
            DefaultTeam.TeamId = teamId
            return XTool.Clone(DefaultTeam)
        end
    end

    -- 处理周更新
    function XArenaOnlineManager.HandlerWeekRefresh(data)
        NextRefreshTime = data.NextRefreshTime
        AreaChanged = true
        SetAreasInfo(data.Areas)
        FubenStageStrs = {}
        CharEndurances = {}
        FirstPassList = {}
        XArenaOnlineManager.ResetStageInfo()
        XEventManager.DispatchEvent(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH)
    end
    
    --区域是否变更
    function XArenaOnlineManager.IsAreaChanged()
        return AreaChanged 
    end
    
    --设置区域变更标记
    function XArenaOnlineManager.SetAreaChanged(value)
        AreaChanged = value
    end

    -- 区域联机更新回主界面处理
    function XArenaOnlineManager.RunMain()
        if InFightChangeCache then
            return
        end

        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            InFightChangeCache = true
            return
        end
        local notDialogTip = true
        XLuaUiManager.RunMain(notDialogTip)
        XUiManager.TipMsg(CS.XTextManager.GetText("ArenaOnlineTimeOut"))
    end

    -- 处理日更新
    function XArenaOnlineManager.HandlerDayRefresh()
        XEventManager.DispatchEvent(XEventId.EVENT_ARENAONLINE_DAY_REFRESH)
    end

    -- 战斗结束后判断是否跳到主界面
    function XArenaOnlineManager.JudgeGotoMainWhenFightOver(stageId)
        local stageType = XMVCA.XFuben:GetStageType(stageId)
        if stageType ~= XDataCenter.FubenManager.StageType.ArenaOnline then
            return false
        end

        if not InFightChangeCache then
            return false
        end

        InFightChangeCache = false
        local notDialogTip = true
        XUiManager.TipText("ArenaOnlineTimeOut")
        XLuaUiManager.RunMain(notDialogTip)

        return true
    end

    function XArenaOnlineManager.OpenPrivateChat(chatData)
        if not XDataCenter.ArenaOnlineManager.CheckInviteTipShow() then
            return
        end

        if chatData.MsgType ~= ChatMsgType.RoomMsg then
            return
        end

        local contentData = XChatData.DecodeRoomMsg(chatData.Content)
        if not contentData then
            return
        end

        if chatData.SenderId == XPlayer.Id then
            return
        end

        XArenaOnlineManager.RecordPrivateChatData(chatData)
        if XArenaOnlineManager.IsShowMaskUI() or XDataCenter.MovieManager.IsPlayingMovie() then
            return
        end

        if XLuaUiManager.IsUiShow("UiArenaOnlineInvitation")then
            return
        end

        XLuaUiManager.Open("UiArenaOnlineInvitation")
    end

    function XArenaOnlineManager.RecordPrivateChatData(chatData)
        if not XArenaOnlineManager.ChatDatas then
            XArenaOnlineManager.ChatDatas = {}
        end

        table.insert(XArenaOnlineManager.ChatDatas, chatData)
    end

    function XArenaOnlineManager.ClearPrivateChatData()
        XArenaOnlineManager.ChatDatas = {}
    end

    function XArenaOnlineManager.GetPrivateChatData()
        return XArenaOnlineManager.ChatDatas
    end

    function XArenaOnlineManager.RemovePrivateChatData(senderId)
        if not XArenaOnlineManager.ChatDatas then
            return
        end

        local chatData
        for i = #XArenaOnlineManager.ChatDatas, 1, -1 do
            chatData = XArenaOnlineManager.ChatDatas[i]
            if chatData and chatData.SenderId == senderId then
                table.remove(XArenaOnlineManager.ChatDatas, i)
            end
        end
    end

    function XArenaOnlineManager.IsShowMaskUI()
        for _,uiname in pairs(XArenaOnlineConfigs.MaskArenOnlineUIName)do
            if XLuaUiManager.IsUiShow(uiname)then
                return true
            end
        end

        return false
    end

    function XArenaOnlineManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_PRIVATECHAT, XArenaOnlineManager.OpenPrivateChat)
    end

    XArenaOnlineManager.Init()
    return XArenaOnlineManager
end

-- 关闭合众战局功能
XRpc.NotifyArenaOnlineLoginData = function(data)
    --XDataCenter.ArenaOnlineManager.HandlerLoginData(data)
end

XRpc.NotifyArenaOnlineFightEnd = function(data)
    --XDataCenter.ArenaOnlineManager.HandlerFightEndData(data)
end

XRpc.NotifyArenaOnlineInfo = function(data)
    --XDataCenter.ArenaOnlineManager.HandlerWeekRefresh(data)
end

XRpc.NotifyArenaOnlineDayRefresh = function()
    --XDataCenter.ArenaOnlineManager.HandlerDayRefresh()
end