---@class XTaskData
---@field Id number taskId
---@field Schedule table<number, table>
---@field State number XTaskManager.TaskState
---@field ActivityId number 活动编号
---@field RecordTime number 领取时间

TaskType = {
    Story = 1, -- 普通/剧情
    Daily = 2, -- 每日
    Weekly = 3,-- 每周
    Achievement = 4, -- 成就
    Activity = 5, -- 活动
    OffLine = 6, -- 下线(未使用)
    NewPlayer = 7, -- 新手目标
    CharacterStory = 8, -- 角色剧情(未使用)
    Bfrt = 9,        -- 据点任务(未使用)
    ArenaChallenge = 10,
    TimeLimit = 11, --限时任务
    DormNormal = 12, --宿舍普通
    DormDaily = 13, --宿舍日常
    BossSingle = 14,  -- 单挑boss(未使用)
    BabelTower = 15, --巴别塔任务
    RogueLike = 16, --爬塔玩法
    Regression = 17, --回归活动
    GuildMainly = 18, --公会主线
    GuildDaily = 19,  -- 公会日常
    ArenaOnlineWeekly = 20, -- 区域联机
    SpecialTrain = 21, -- 特训关日常任务(未使用)
    InfestorWeekly = 22, -- 异聚迷宫
    GuildWeekly = 23, --工会周长
    BossOnLine = 24, --日服联机boss
    WorldBoss = 25, --世界boss
    Expedition = 26, -- 远征自走棋(未使用)
    RpgTower = 27, --兵法蓝图
    MentorShipGrow = 28, -- 师徒成长任务
    MentorShipGraduate = 29, -- 师徒毕业挑战
    MentorShipWeekly = 30, -- 师徒每周任务
    NieR = 31, --尼尔玩法
    Pokemon = 32, --口袋战双
    ZhouMu = 39, --多周目
    ChristmasTree = 40, --圣诞树(未使用)
    ChessPursuit = 41, --追击玩法(未使用)
    Couplet = 42, --春节对联小游戏
    SimulatedCombat = 43, --模拟作战
    WhiteValentine = 44, --白色情人节
    MoeWarDaily = 45, -- 萌战每日任务
    MoeWarNormal = 46, -- 萌战累计任务
    FingerGuessing = 47, -- 猜拳小游戏
    PokerGuessing = 48, --翻牌猜大小
    Reform = 49,    -- 改造玩法
    PokerGuessingCollection = 50, --翻牌猜大小收藏品任务
    Passport = 51,  --通行证任务
    CoupleCombat = 52,   -- 双人玩法
    LivWarmSoundsActivity = 53,   -- 丽芙预热音频解密任务
    LivWarmExtActivity = 54,   -- 丽芙预热宣发任务
    Maverick = 56,   -- 二周年射击玩法
    Doomsday = 57,   -- 末日生存
    PivotCombat = 62, --SP区域作战
    BodyCombineGame = 63, -- 接头霸王
    GuildWar = 64, --公会战任务
    GuildWarTerm2 = 65, --工会战任务 二期 
    WeekChallenge = 66, -- 周挑战
    DoubleTower = 67,   --动作塔防
    GoldenMiner = 68, --黄金矿工
    TaikoMaster = 69, --音游
    SuperSmash = 70, --超限乱斗（2期时新增）
    Newbie = 71, -- 新手荣誉任务（新手任务二期）
    CharacterTower = 73, -- 本我回廊（角色塔）
    DlcHunt = 75, -- DlcHunt
    BackFlow = 76, -- 回流玩家
    SpecialTrainDailySwitchTask = 77, -- 特训关每日任务
    Rift = 82, --大秘境任务
    Kotodama=83,--言灵任务
}

XTaskManagerCreator = function()
    local tableInsert = table.insert
    local tableSort = table.sort

    local Json = require("XCommon/Json")
    local WeekTaskRefreshId = 10001
    local WeekTaskEpochTime = 0
    local WeekTaskRefreshDay = 1
    ---@class XTaskManager
    local XTaskManager = {}

    local ITEM_NEWBIE_PROGRESS_ID = CS.XGame.ClientConfig:GetInt("NewPlayerTaskExpId")

    XTaskManager.TaskType = TaskType
    XTaskManager.OperationState = {
        DoWork = 1,
        GetReward = 2,
        GetedReward = 3
    }

    XTaskManager.ActiveRewardType = {
        Daily = 1,
        Weekly = 2
    }
    
    XTaskManager.AchvType = {
        Fight = 1,
        Collect = 2,
        Social = 3,
        Other = 4,
    }

    XTaskManager.TaskState = {
        InActive = -1, --未激活
        Standby = 0, --待命
        Active = 1, --已激活
        Accepted = 2, --已接受
        Achieved = 3, --完成（未领奖励）
        Finish = 4, --结束（领取奖励）
        Invalid = 5, --已失效/过期
    }

    XTaskManager.NewPlayerTaskGroupState = {
        Lock = 1, --未解锁
        AllTodo = 2, --待完成
        HasAward = 3, --有奖励没领取
        AllFinish = 4, --全都结束
    }

    XTaskManager.CourseType = {
        None = 0, -- 无状态
        Reward = 1, -- 有经历节点
        Function = 2, -- 有功能开启节点
        Normal = 3, -- 普通节点
    }

    XTaskManager.UpdateViewCallback = nil

    local CourseInfos = {}  -- {key = ChapterId, Value = {LasetId, NextChapterId, Courses = {stageId, type, nextType......}}}
    local CourseChapterRewards = {}

    local TaskDataGroup = {}
    
    -- 创建新系统或者优化原有系统时请使用新的通用任务接口
    -------------------------------------------------------
    local CourseData = {}
    ---@type XTaskData[]
    local TotalTaskData = {}
    local StoryTaskData = {}
    local DailyTaskData = {}
    local WeeklyTaskData = {}
    local ActivityTaskData = {}
    local NewPlayerTaskData = {}
    local AchvTaskData = {}
    local ArenaTaskData = {}
    local TimeLimitTaskData = {}
    local ArenaOnlineWeeklyTaskData = {}
    local InfestorWeeklyTaskData = {}

    local StoryGroupTaskData = {}
    local DormStoryGroupTaskData = {}
    local DormDailyGroupTaskData = {}
    local FinishedTasks = {}

    -- 宿舍任务
    local DormNormalTaskData = {}
    local DormDailyTaskData = {}

    local BabelTowerTaskData = {}
    local RogueLikeTaskData = {}
    local WorldBossTaskData = {}
    local RiftTaskData = {}

    --师徒任务
    local MentorGrowTaskData = {}
    local MentorGraduateTaskData = {}
    local MentorWeeklyTaskData = {}

    local RpgTowerTaskData = {}
    local WhiteValentineTaskData = {}
    local FingerGuessingTaskData = {}
    local PokerGuessingTaskData = {}
    local GuildDailyTaskData = {}
    local GuildMainlyTaskData = {}
    local GuildWeeklyTaskData = {}
    local ZhouMuTaskData = {}

    local RegressionTaskData = {}
    local LinkTaskTimeDict = {}
	local NieRTaskData = {}
	
	local PokemonTaskData = {}
    -- 小游戏
    local CoupletTaskData = {}
    local SimulatedCombatTaskData = {}

    local MoeWarDailyTaskData = {}
    local MoeWarNormalTaskData = {}

    --通行证
    local PassportTaskData = {}

    --音频解密
    local LivWarmSoundsActivityTaskData = {}
    
    local TaskResultDataCache = {}
    local _IsInit = false
    
    -------------------------------------------------------

    local NewbieActivenessRecord = {}
    XTaskManager.NewPlayerLastSelectTab = "NewPlayerHint_LastSelectTab"
    XTaskManager.TaskLastSelectTab = "TaskHint_LastSelectTab"
    XTaskManager.DormTaskLastSelectTab = "DormTaskHint_LastSelectTab"
    XTaskManager.NewPLayerTaskFirstTalk = "NewPlayerHint_FirstTalk"

    local RegressionTaskRedPointCount = 0
    local RegressionTaskCanGetDic = {}
    local RegressionTaskTypeToRedPointCountDic = {}

    function XTaskManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, XTaskManager.SetCourseOnSyncStageData)

        local alarmClockData = XTaskConfig.GetAlarmClockById(WeekTaskRefreshId)
        local jsonFormatData = Json.decode(alarmClockData.DayOfWeek)
        WeekTaskEpochTime = alarmClockData.EpochTime
        WeekTaskRefreshDay = jsonFormatData[1]
    end

    -- 重登时，重置cache
    function XTaskManager.ClearCache()
        --CourseInfos = {}
        --CourseChapterRewards = {}
        TaskDataGroup = {}
        --CourseData = {}
        TotalTaskData = {}
        StoryTaskData = {}
        DailyTaskData = {}
        WeeklyTaskData = {}
        --ActivityTaskData = {}
        --NewPlayerTaskData = {}
        --AchvTaskData = {}
        --ArenaTaskData = {}
        --TimeLimitTaskData = {}
        --ArenaOnlineWeeklyTaskData = {}
        --InfestorWeeklyTaskData = {}
        --StoryGroupTaskData = {}
        --DormStoryGroupTaskData = {}
        --DormDailyGroupTaskData = {}
        FinishedTasks = {}
        --DormNormalTaskData = {}
        --DormDailyTaskData = {}
        --BabelTowerTaskData = {}
        --RogueLikeTaskData = {}
        --WorldBossTaskData = {}
        --MentorGrowTaskData = {}
        --MentorGraduateTaskData = {}
        --MentorWeeklyTaskData = {}
        --RpgTowerTaskData = {}
        --WhiteValentineTaskData = {}
        --FingerGuessingTaskData = {}
        PokerGuessingTaskData = {}
        --GuildDailyTaskData = {}
        --GuildMainlyTaskData = {}
        --GuildWeeklyTaskData = {}
        --ZhouMuTaskData = {}
        --RegressionTaskData = {}
        --LinkTaskTimeDict = {}
        --NieRTaskData = {}
        --PokemonTaskData = {}
        --CoupletTaskData = {}
        --SimulatedCombatTaskData = {}
        --MoeWarDailyTaskData = {}
        --MoeWarNormalTaskData = {}
        --PassportTaskData = {}
        --LivWarmSoundsActivityTaskData = {}
        TaskResultDataCache = {}
        --RegressionTaskRedPointCount = 0
        --RegressionTaskCanGetDic = {}
        --RegressionTaskTypeToRedPointCountDic = {}
    end

    function XTaskManager.InitTaskData(data)
        if _IsInit then
            XTaskManager.ClearCache()
        else
            _IsInit = true
        end
        
        local taskdata = data.Tasks
        FinishedTasks = {}
        for _, v in pairs(data.FinishedTasks or {}) do
            FinishedTasks[v] = true
        end

        if data.TaskLimitIdActiveInfos then
            for _, v in pairs(data.TaskLimitIdActiveInfos) do
                LinkTaskTimeDict[v.TaskLimitId] = v.ActiveTime
                XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_INFO_UPDATE)
            end
        end
        NewbieActivenessRecord = data.NewPlayerRewardRecord
        XTaskManager.InitCourseData(data.Course)

        for _, value in pairs(taskdata) do
            TotalTaskData[value.Id] = value
        end
        local taskTemplate = XTaskConfig.GetTaskTemplate()
        for k, v in pairs(taskTemplate) do
            if not TotalTaskData[k] and v.Type ~= XTaskManager.TaskType.Daily and v.Type ~= XTaskManager.TaskType.Weekly and v.Type ~= XTaskManager.TaskType.InfestorWeekly then
                TotalTaskData[k] = {}
                TotalTaskData[k].Id = k
                TotalTaskData[k].Schedule = {}
                local conditions = v.Condition

                for _, var in ipairs(conditions) do
                    if FinishedTasks and FinishedTasks[k] then
                        tableInsert(TotalTaskData[k].Schedule, { Id = var, Value = v.Result })
                        TotalTaskData[k].State = XTaskManager.TaskState.Finish
                    else
                        tableInsert(TotalTaskData[k].Schedule, { Id = var, Value = 0 })
                        TotalTaskData[k].State = XTaskManager.TaskState.Active
                    end
                end

            end
        end

        local regressionTaskType
        for k, v in pairs(TotalTaskData) do
            local taskType = taskTemplate[k] and taskTemplate[k].Type or nil
            if (taskTemplate[k] == nil) then
                XLog.Warning("服务端数据异常 不存在任务配置id：", k)
-- 创建新系统或者优化原有系统时请使用新的通用任务接口
-------------------------------------------------------
            elseif taskType == XTaskManager.TaskType.Story then
                StoryTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.Daily then
                DailyTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.Weekly then
                WeeklyTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.Activity then
                ActivityTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.NewPlayer then
                NewPlayerTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.Achievement then
                AchvTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.ArenaChallenge then
                ArenaTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.TimeLimit then
                TimeLimitTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.DormNormal then
                DormNormalTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.DormDaily then
                DormDailyTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.BabelTower then
                BabelTowerTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.RogueLike then
                RogueLikeTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.WorldBoss then
                WorldBossTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.RpgTower then
                RpgTowerTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.WhiteValentine then
                WhiteValentineTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.FingerGuessing then
                FingerGuessingTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.ZhouMu then
                ZhouMuTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.GuildDaily then
                GuildDailyTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.GuildMainly then
                GuildMainlyTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.GuildWeekly then
                GuildWeeklyTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.MentorShipGrow then
                MentorGrowTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.MentorShipGraduate then
                MentorGraduateTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.MentorShipWeekly then
                MentorWeeklyTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.Regression then
                regressionTaskType = XRegressionConfigs.GetTaskTypeById(k)
                RegressionTaskData[k] = v
                if RegressionTaskCanGetDic[k] then
                    if v.State ~= XDataCenter.TaskManager.TaskState.Achieved then
                        RegressionTaskTypeToRedPointCountDic[regressionTaskType] = RegressionTaskTypeToRedPointCountDic[regressionTaskType] - 1
                        RegressionTaskRedPointCount = RegressionTaskRedPointCount - 1
                        RegressionTaskCanGetDic[k] = nil
                    end
                else
                    if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                        RegressionTaskCanGetDic[k] = true
                        RegressionTaskTypeToRedPointCountDic[regressionTaskType] = RegressionTaskTypeToRedPointCountDic[regressionTaskType] or 0
                        RegressionTaskTypeToRedPointCountDic[regressionTaskType] = RegressionTaskTypeToRedPointCountDic[regressionTaskType] + 1
                        RegressionTaskRedPointCount = RegressionTaskRedPointCount + 1
                    end
                end
            elseif taskType == XTaskManager.TaskType.ArenaOnlineWeekly then
                ArenaOnlineWeeklyTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.InfestorWeekly then
                InfestorWeeklyTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.NieR then
                NieRTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.Pokemon then
                PokemonTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.Couplet then
                CoupletTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.SimulatedCombat then
                SimulatedCombatTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.MoeWarDaily then
                MoeWarDailyTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.MoeWarNormal then
                MoeWarNormalTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.PokerGuessing or taskType == XTaskManager.TaskType.PokerGuessingCollection then
                PokerGuessingTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.Passport then
                PassportTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.LivWarmSoundsActivity then
                LivWarmSoundsActivityTaskData[k] = v
            elseif taskType == XTaskManager.TaskType.Rift then
                RiftTaskData[k] = v
                -------------------------------------------------------
            elseif taskType and taskType ~= XTaskManager.TaskType.OffLine then
                -- XLog.Warning(taskType, k, v, "TaskDataGroup",TaskDataGroup)
                if not TaskDataGroup[taskType] then 
                    TaskDataGroup[taskType] = {} 
                end
                TaskDataGroup[taskType][k] = v

            end
        end

        XEventManager.DispatchEvent(XEventId.EVENT_TASK_SYNC)
        XEventManager.DispatchEvent(XEventId.EVENT_NOTICE_TASKINITFINISHED)--上面那个事件触发太频繁，这里只需要监听初始完成
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_TASK_SYNC)
    end

    function XTaskManager.InitCourseInfos()
        local courseChapterRewardTemp = {}
        local courseTemplate = XTaskConfig.GetCourseTemplate()
        for k, v in pairs(courseTemplate) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(v.StageId)
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(v.StageId)
            if not stageInfo or not stageCfg then
                local path = XTaskConfig.GetTaskCoursePath()
                XLog.ErrorTableDataNotFound("XTaskManager.InitCourseInfos", "StageId", path, "CourseId", tostring(k))
                return
            end

            local SetType = function(cfg)
                if cfg.RewardId and cfg.RewardId > 0 then
                    return XTaskManager.CourseType.Reward
                elseif cfg.Tip and cfg.Tip ~= "" then
                    return XTaskManager.CourseType.Function
                else
                    return XTaskManager.CourseType.Normal
                end
            end

            local SetCourse = function(lastStageId)
                local type = SetType(v)

                local nextType = XTaskManager.CourseType.None
                if stageInfo.NextStageId and courseTemplate[stageInfo.NextStageId] then
                    local nextCfg = courseTemplate[stageInfo.NextStageId]
                    nextType = SetType(nextCfg)
                end

                local chapter = XDataCenter.FubenMainLineManager.GetChapterCfg(stageInfo.ChapterId)
                local name = chapter.OrderId .. "-" .. stageCfg.OrderId

                -- 寻找还没有领奖励的关卡
                if type == XTaskManager.CourseType.Reward or lastStageId == v.StageId then
                    if XTaskManager.CheckCourseCanGet(v.StageId) then
                        if courseChapterRewardTemp[stageInfo.ChapterId] then
                            if type == XTaskManager.CourseType.Reward then
                                tableInsert(courseChapterRewardTemp[stageInfo.ChapterId].stageIds, v.StageId)
                            end

                            local stageInfo1 = XDataCenter.FubenManager.GetStageInfo(lastStageId)
                            if lastStageId == v.StageId and not stageInfo1.Passed then
                                courseChapterRewardTemp[stageInfo1.ChapterId].LastStageId = v.StageId
                            end
                        else
                            if type == XTaskManager.CourseType.Reward then
                                courseChapterRewardTemp[stageInfo.ChapterId] = {}
                                courseChapterRewardTemp[stageInfo.ChapterId].ChapterId = stageInfo.ChapterId
                                courseChapterRewardTemp[stageInfo.ChapterId].OrderId = chapter.OrderId
                                courseChapterRewardTemp[stageInfo.ChapterId].stageIds = {}
                                tableInsert(courseChapterRewardTemp[stageInfo.ChapterId].stageIds, v.StageId)
                            end

                            local stageInfo2 = XDataCenter.FubenManager.GetStageInfo(lastStageId)
                            if lastStageId == v.StageId and not stageInfo2.Passed then
                                if courseChapterRewardTemp[stageInfo2.ChapterId] then
                                    courseChapterRewardTemp[stageInfo2.ChapterId].LastStageId = v.StageId
                                else
                                    courseChapterRewardTemp[stageInfo2.ChapterId] = {}
                                    courseChapterRewardTemp[stageInfo2.ChapterId].ChapterId = stageInfo2.ChapterId
                                    courseChapterRewardTemp[stageInfo2.ChapterId].OrderId = chapter.OrderId
                                    courseChapterRewardTemp[stageInfo2.ChapterId].stageIds = {}
                                    courseChapterRewardTemp[stageInfo2.ChapterId].LastStageId = v.StageId
                                end
                            end
                        end
                    end
                end
                -- 寻找还没有领奖励的关卡
                return {
                    CouresType = type,
                    NextCouresType = nextType,
                    StageId = v.StageId,
                    Tip = v.Tip,
                    TipEn = v.TipEn,
                    RewardId = v.RewardId,
                    ShowId = v.ShowId,
                    OrderId = stageCfg.OrderId,
                    Name = name,
                    PreStageId = stageCfg.PreStageId
                }
            end

            if CourseInfos[stageInfo.ChapterId] then
                local course = SetCourse(CourseInfos[stageInfo.ChapterId].LastStageId)
                tableInsert(CourseInfos[stageInfo.ChapterId].Courses, course)
            else
                local nextChapterId = XDataCenter.FubenMainLineManager.GetNextChapterId(stageInfo.ChapterId)
                local lastStageId = XDataCenter.FubenMainLineManager.GetLastStageId(stageInfo.ChapterId)
                local isStageIdTableEmpty = XDataCenter.FubenMainLineManager.IsStageIdTableEmpty(stageInfo.ChapterId)
                if not isStageIdTableEmpty then
                    CourseInfos[stageInfo.ChapterId] = {}
                    CourseInfos[stageInfo.ChapterId].Courses = {}
                    CourseInfos[stageInfo.ChapterId].NextChapterId = nextChapterId
                    CourseInfos[stageInfo.ChapterId].LastStageId = lastStageId
                    local course = SetCourse(lastStageId)
                    tableInsert(CourseInfos[stageInfo.ChapterId].Courses, course)
                end
            end
        end
        
        local needk
        for k, v in pairs(CourseInfos) do
            if not needk or needk < k then
                needk = k
            end
            tableSort(v.Courses, function(a, b)
                return a.OrderId < b.OrderId
            end)
        end
        
        for _, v in pairs(courseChapterRewardTemp) do
            tableSort(v.stageIds, function(a, b)
                return a < b
            end)
            tableInsert(CourseChapterRewards, v)
        end

        tableSort(CourseChapterRewards, function(a, b)
            return a.OrderId < b.OrderId
        end)
    end

    function XTaskManager.InitCourseData(coursedata)
        CourseData = {}
        CourseInfos = {}
        CourseChapterRewards = {}

        if coursedata then
            XTool.LoopCollection(coursedata, function(key)
                CourseData[key] = key
            end)
        end
        XTaskManager.InitCourseInfos()
    end

    function XTaskManager.SetCourseData(stageId)
        local allRewardGet = false
        if not CourseData[stageId] then
            CourseData[stageId] = stageId

            --移除 CourseChapterRewards 里的Id,并判断是否领取完
            local remov_stage_i = -1
            local remov_stage_j = -1
            local remov_chapter_i = -1
            for i = 1, #CourseChapterRewards do
                for j = 1, #CourseChapterRewards[i].stageIds do
                    if CourseChapterRewards[i].stageIds[j] == stageId then
                        remov_stage_i = i
                        remov_stage_j = j
                        if #CourseChapterRewards[i].stageIds <= 1 then
                            local lastId = CourseChapterRewards[i].LastStageId
                            local stageInfo = XDataCenter.FubenManager.GetStageInfo(lastId)
                            if (stageInfo and stageInfo.Passed) or not lastId then
                                remov_chapter_i = i
                            end
                        end
                        break
                    end
                end
            end

            if remov_stage_i > 0 and remov_stage_j > 0 then
                table.remove(CourseChapterRewards[remov_stage_i].stageIds, remov_stage_j)
            end

            if remov_chapter_i > 0 then
                table.remove(CourseChapterRewards, remov_chapter_i)
                allRewardGet = true
            end
        end
        return allRewardGet
    end

    --判断是否有进度
    function XTaskManager.CheckTaskHasSchedule(task)
        local hasSchedule = false
        XTool.LoopMap(task.Schedule, function(_, pair)
            if pair.Value > 0 then
                hasSchedule = true
            end
        end)

        return hasSchedule
    end

    function XTaskManager.CheckCourseCanGet(stageId)
        if CourseData[stageId] then
            return false
        else
            return true
        end
    end

    function XTaskManager.GetCourseInfo(chapterId)
        return CourseInfos[chapterId]
    end

    function XTaskManager.GetCourseCurChapterId()
        if not CourseChapterRewards or #CourseChapterRewards <= 0 then
            return nil
        end
        return CourseChapterRewards[1].ChapterId
    end

    function XTaskManager.SetCourseOnSyncStageData(stageId)
        local remov_chapter_i = -1
        for i = 1, #CourseChapterRewards do
            local lastId = CourseChapterRewards[i].LastStageId
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(lastId)
            if #CourseChapterRewards[i].stageIds <= 0 and lastId == stageId and stageInfo.Passed then
                remov_chapter_i = i
                break
            end
        end

        if remov_chapter_i > 0 then
            table.remove(CourseChapterRewards, remov_chapter_i)
        end
    end

    function XTaskManager.GetCourseCurRewardIndex(curChapterId)
        if not CourseChapterRewards or #CourseChapterRewards <= 0 then
            return nil
        end

        if not CourseChapterRewards[1].stageIds[1] and #CourseChapterRewards[1].stageIds <= 0 then
            return nil
        end

        local stageId = CourseChapterRewards[1].stageIds[1]
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if not stageInfo.Passed then
            return nil
        end
        local courses = CourseInfos[curChapterId].Courses
        for i = 1, #courses do
            if stageId == courses[i].StageId then
                return i
            end
        end
        return nil
    end

    function XTaskManager.GetTaskDataById(taskid)
        return TotalTaskData[taskid]
    end

    function XTaskManager.IsTaskFinished(taskId)
        return FinishedTasks[taskId]
    end

    local function CheckTask(task)
        if not task then return false end

        local template = XTaskConfig.GetTaskTemplate()[task.Id]

        -- startTime限制
        if template.StartTime ~= nil and template.StartTime ~= "" then
            local now = XTime.GetServerNowTimestamp()
            local startTime = XTime.ParseToTimestamp(template.StartTime)
            if startTime and startTime > now then return false end
        end
        -- endTime限制
        if template.EndTime ~= nil and template.EndTime ~= "" then
            local now = XTime.GetServerNowTimestamp()
            local endTime = XTime.ParseToTimestamp(template.EndTime)
            if endTime and endTime < now then return false end
        end

        -- showCondition限制
        if template.ShowCondition ~= nil and template.ShowCondition ~= 0 then
            -- 不满足返回false
            if not XConditionManager.CheckCondition(template.ShowCondition) then
                return false
            end
        end

        local preId = template and template.ShowAfterTaskId or -1
        if preId > 0 then
            local preTask = TotalTaskData[preId]

            if preTask then
                if preTask.State ~= XTaskManager.TaskState.Finish and preTask.State ~= XTaskManager.TaskState.Invalid then
                    return false
                end
            else
                if FinishedTasks[preId] then
                    return true
                end
                return false
            end
        end
        return true
    end

    local function State2Num(state)
        if state == XTaskManager.TaskState.Achieved then
            return 1
        end
        if state == XTaskManager.TaskState.Finish then
            return -1
        end
        return 0
    end

    local function CompareState(stateA, stateB)
        if stateA == stateB then
            return 0
        end
        local a = State2Num(stateA)
        local b = State2Num(stateB)
        if a > b then return 1 end
        if a < b then return -1 end
        return 0
    end

    local function GetTaskList(tasks)
        local list = {}
        local type
        local taskTemplate = XTaskConfig.GetTaskTemplate()
        for _, task in pairs(tasks) do
            type = taskTemplate[task.Id].Type
            break
        end
        if type == XTaskManager.TaskType.Achievement
        or type == XTaskManager.TaskType.ArenaChallenge
        or type == XTaskManager.TaskType.Regression 
        or type == XTaskManager.TaskType.NieR
		or type == XTaskManager.TaskType.MoeWarDaily
		or type == XTaskManager.TaskType.MoeWarNormal
        or type == XTaskManager.TaskType.PokerGuessing
        or type == XTaskManager.TaskType.LivWarmSoundsActivity
        or type == XTaskManager.TaskType.LivWarmExtActivity then
            for _, task in pairs(tasks) do
                if CheckTask(task) then
                    tableInsert(list, task)
                end
            end
        else
            for _, task in pairs(tasks) do
                if task.State ~= XTaskManager.TaskState.Finish and task.State ~= XTaskManager.TaskState.Invalid then
                    if CheckTask(task) then
                        tableInsert(list, task)
                    end
                end
            end
        end

        tableSort(list, function(a, b)
            local pa, pb = taskTemplate[a.Id].Priority, taskTemplate[b.Id].Priority
            local stateA = TotalTaskData[a.Id].State
            local stateB = TotalTaskData[b.Id].State
            local compareResult = CompareState(stateA, stateB)
            if compareResult == 0 then
                if pa ~= pb then
                    return pa > pb
                else
                    return a.Id > b.Id
                end
            else
                return compareResult > 0
            end
        end)

        return list
    end


    function XTaskManager.SetAchievedList()
        local tasks = XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.Achievement)
        local list = {}

        local taskTemplate = XTaskConfig.GetTaskTemplate()
        for _, task in pairs(tasks) do
            if not (task.State == XTaskManager.TaskState.Invalid) then
                if taskTemplate[task.Id] and taskTemplate[task.Id].ShowAfterTaskId > 0 then
                    local preId = taskTemplate[task.Id].ShowAfterTaskId
                    if TotalTaskData[preId] then
                        if (TotalTaskData[preId].State == XTaskManager.TaskState.Finish or TotalTaskData[preId].State == XTaskManager.TaskState.Invalid) then
                            tableInsert(list, task)
                        end
                    elseif FinishedTasks[preId] then
                        tableInsert(list, task)
                    end
                else
                    tableInsert(list, task)
                end
            end
        end

        local listAchieved = {}
        for _, v in pairs(list) do
            if v.State == XTaskManager.TaskState.Achieved or v.State == XTaskManager.TaskState.Finish then
                tableInsert(listAchieved, v)
            end
        end
    end

    --获取成就任务已完成和总数量
    function XTaskManager.GetAchievedTasksByType(achvType)

        local achieveCount = 0
        local totalCount = 0
        local achieveList = {}
        local achvTaskData = XTaskManager.GetAchvTaskList()
        for _, task in pairs(achvTaskData) do
            local _achvType = XTaskConfig.GetTaskTemplate()[task.Id].AchvType
            if _achvType == achvType and task ~= nil then
                tableInsert(achieveList, task)
                totalCount = totalCount + 1
                if task.State == XTaskManager.TaskState.Finish or task.State == XTaskManager.TaskState.Achieved then
                    achieveCount = achieveCount + 1
                end
            end
        end

        return achieveList, achieveCount, totalCount
    end

    --红点---------------------------------------------------------
    --根据成就任务类型判断是否有奖励可以领取
    function XTaskManager.HasAchieveTaskRewardByAchieveType(achvType)
        for _, task in pairs(AchvTaskData) do
            local _achvType = XTaskConfig.GetTaskTemplate()[task.Id].AchvType
            if _achvType == achvType and task ~= nil and task.State == XTaskManager.TaskState.Achieved then
                return true
            end
        end

        return false
    end

    --判断历程是否有奖励获取
    function XTaskManager.CheckAllCourseCanGet()

        if not CourseInfos then
            return false
        end

        local curChapterId = XTaskManager.GetCourseCurChapterId()
        if not CourseInfos[curChapterId] then
            return
        end

        local canGet = false
        for _, v in ipairs(CourseInfos[curChapterId].Courses) do

            local stageId = v.StageId
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)

            if v.CouresType == XTaskManager.CourseType.Reward and stageInfo.Passed and XTaskManager.CheckCourseCanGet(stageId) then
                canGet = true
                break
            end
        end

        return canGet
    end

    --根据任务类型判断是否有奖励可以领取
    function XTaskManager.GetIsRewardForEx(taskType, groupId)
        local taskList = nil

        -- 创建新系统或者优化原有系统时请使用新的通用任务接口
        -------------------------------------------------------
        if taskType == XTaskManager.TaskType.Story then
            taskList = XTaskManager.GetStoryTaskList()
        elseif taskType == XTaskManager.TaskType.Daily then
            taskList = XTaskManager.GetDailyTaskList()
        elseif taskType == XTaskManager.TaskType.Weekly then
            taskList = XTaskManager.GetWeeklyTaskList()
        elseif taskType == XTaskManager.TaskType.Activity then
            taskList = XTaskManager.GetActivityTaskList()
        elseif taskType == XTaskManager.TaskType.Achievement then
            taskList = XTaskManager.GetAchvTaskList()
        elseif taskType == XTaskManager.TaskType.DormDaily then
            taskList = XTaskManager.GetDormDailyTaskList()
        elseif taskType == XTaskManager.TaskType.DormNormal then
            taskList = XTaskManager.GetDormNormalTaskList()
        elseif taskType == XTaskManager.TaskType.BabelTower then
            taskList = XTaskManager.GetBabelTowerTaskList()
        elseif taskType == XTaskManager.TaskType.RogueLike then
            taskList = XTaskManager.GetRogueLikeTaskList()
        elseif taskType == XTaskManager.TaskType.GuildDaily then
            taskList = XTaskManager.GetGuildDailyTaskList()
        elseif taskType == XTaskManager.TaskType.GuildMainly then
            taskList = XTaskManager.GetGuildMainlyTaskList()
        elseif taskType == XTaskManager.TaskType.GuildWeekly then
            taskList = XTaskManager.GetGuildWeeklyTaskList()
        elseif taskType == XTaskManager.TaskType.ArenaOnlineWeekly then
            taskList = XTaskManager.GetArenaOnlineWeeklyTaskList()
        elseif taskType == XTaskManager.TaskType.InfestorWeekly then
            taskList = XTaskManager.GetInfestorWeeklyTaskList()
        elseif taskType == XTaskManager.TaskType.WorldBoss then
            taskList = XTaskManager.GetWorldBossTaskList()
        elseif taskType == XTaskManager.TaskType.MentorShipGrow then
            taskList = XTaskManager.GetMentorGrowTaskList()
        elseif taskType == XTaskManager.TaskType.MentorShipGraduate then
            taskList = XTaskManager.GetMentorGraduateTaskList()
        elseif taskType == XTaskManager.TaskType.MentorShipWeekly then
            taskList = XTaskManager.GetMentorWeeklyTaskList()
        elseif taskType == XTaskManager.TaskType.NieR then
            taskList = XTaskManager.GetNieRTaskList()
        elseif taskType == XTaskManager.TaskType.Pokemon then
            taskList = XTaskManager.GetPokemonTaskList()
        elseif taskType == XTaskManager.TaskType.Couplet then
            taskList = XTaskManager.GetCoupletTaskList()
        elseif taskType == XTaskManager.TaskType.SimulatedCombat then
            taskList = XTaskManager.GetSimulatedCombatTaskList()
        elseif taskType == XTaskManager.TaskType.MoeWarDaily then
            taskList = XTaskManager.GetMoeWarDailyTaskList()
        elseif taskType == XTaskManager.TaskType.MoeWarNormal then
            taskList = XTaskManager.GetMoeWarNormalTaskList()
        elseif taskType == XTaskManager.TaskType.Passport then
            taskList = XTaskManager.GetPassportTaskList()
        elseif taskType == XTaskManager.TaskType.LivWarmSoundsActivity then
            taskList = XTaskManager.GetLivWarmSoundsActivityFullTaskList()
        -------------------------------------------------------
        elseif taskType then
            taskList = XTaskManager.GetTaskList(taskType, groupId)
        end

        if taskList == nil then
            return false
        end
        local res = false
        for _, taskInfo in pairs(taskList) do
            if taskInfo ~= nil and taskInfo.State == XTaskManager.TaskState.Achieved then
                res = true
                if taskType == XTaskManager.TaskType.Story then
                    -- 剧情模式判断有无可领取时 必须判断是否是当前进度中的章节任务
                    res = res and XTaskManager.GetCurrentStoryTaskGroupId() == XDataCenter.TaskManager.GetTaskTemplate(taskInfo.Id).GroupId
                end
                break
            end
        end
        return res
    end

    --判断新手任务是否有奖励可以领取
    function XTaskManager.CheckIsNewPlayerTaskReward()
        local newPlayerTaskGroupTemplate = XTaskConfig.GetNewPlayerTaskGroupTemplate()
        if not newPlayerTaskGroupTemplate then
            return false
        end


        local hasReward = false

        for k, _ in pairs(newPlayerTaskGroupTemplate) do
            local state = XTaskManager.GetNewPlayerGroupTaskStatus(k)

            local talkConfig = XTaskManager.GetNewPlayerTaskTalkConfig(k)
            local isNewPlayerTaskUIGroupActive = XPlayer.IsNewPlayerTaskUIGroupActive(k)
            if talkConfig and not isNewPlayerTaskUIGroupActive and talkConfig.StoryId and state ~= XTaskManager.NewPlayerTaskGroupState.Lock then
                hasReward = true
                break
            end

            if state == XTaskManager.NewPlayerTaskGroupState.HasAward then
                hasReward = true
                break
            end
        end

        return hasReward
    end

    --判断是否有每日活跃任务是否有奖励可以领取
    function XTaskManager.CheckHasWeekActiveTaskReward()
        local wActiveness = XDataCenter.ItemManager.GetWeeklyActiveness().Count
        local weekActiveness = XTaskConfig.GetWeeklyActiveness()

        for i = 1, 2 do
            if weekActiveness[i] <= wActiveness and (not XPlayer.IsGetWeeklyActivenessReward(i)) then
                return true
            end
        end

        return false
    end


    --判断是否有周活跃任务是否有奖励可以领取
    function XTaskManager.CheckHasDailyActiveTaskReward()
        local dActiveness = XDataCenter.ItemManager.GetDailyActiveness().Count
        local dailyActiveness = XTaskConfig.GetDailyActiveness()
        for i = 1, 5 do
            if dailyActiveness[i] <= dActiveness and (not XPlayer.IsGetDailyActivenessReward(i)) then
                return true
            end
        end

        return false
    end

    -- 创建新系统或者优化原有系统时请使用新的通用任务接口
    -------------------------------------------------------
    function XTaskManager.GetStoryTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.Story))
    end

    function XTaskManager.GetDailyTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.Daily))
    end

    function XTaskManager.GetWeeklyTaskList()
        local weeklyTasks = XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.Weekly) or {}
        local arenaOnlineWeeklyTasks = XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.ArenaOnlineWeekly) or {}
        local guildWeeklyTasks = XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.GuildWeekly) or {}
        local infestorWeeklyTasks = XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.InfestorWeekly) or {}

        local tasks = {}
        for k, v in pairs(weeklyTasks) do
            tasks[k] = v
        end

        for k, v in pairs(arenaOnlineWeeklyTasks) do
            tasks[k] = v
        end

        for k, v in pairs(guildWeeklyTasks) do
            tasks[k] = v
        end

        for k, v in pairs(infestorWeeklyTasks) do
            tasks[k] = v
        end

        return GetTaskList(tasks)
    end

    function XTaskManager.GetActivityTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.Activity))
    end

    function XTaskManager.GetAchvTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.Achievement))
    end

    function XTaskManager.GetTimeLimitTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.TimeLimit))
    end

    function XTaskManager.GetArenaChallengeTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.ArenaChallenge))
    end

    function XTaskManager.GetDormNormalTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.DormNormal))
    end

    function XTaskManager.GetDormDailyTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.DormDaily))
    end

    function XTaskManager.GetBabelTowerTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.BabelTower))
    end

    function XTaskManager.GetArenaOnlineWeeklyTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.ArenaOnlineWeekly))
    end

    function XTaskManager.GetInfestorWeeklyTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.InfestorWeekly))
    end

    -- 包括已完成的任务
    function XTaskManager.GetRiftTaskList()
        local tasks = {}
        for _, v in pairs(RiftTaskData) do
            tableInsert(tasks, v)
        end
        return tasks
    end

    -- 包括已完成的任务
    function XTaskManager.GetBabelTowerFullTaskList()
        local tasks = {}
        for _, v in pairs(BabelTowerTaskData) do
            table.insert(tasks, v)
        end
        return tasks
    end

    function XTaskManager.GetRogueLikeTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.RogueLike))
    end

    function XTaskManager.GetRogueLikeFullTaskList()
        local tasks = {}
        for _, v in pairs(RogueLikeTaskData) do
            table.insert(tasks, v)
        end
        return tasks
    end

    function XTaskManager.GetRpgTowerTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.RpgTower))
    end

    function XTaskManager.GetRpgTowerFullTaskList()
        local tasks = {}
        for _, v in pairs(RpgTowerTaskData) do
            table.insert(tasks, v)
        end
        return tasks
    end
    
    function XTaskManager.GetWhiteValentineTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.WhiteValentine))
    end

    function XTaskManager.GetWhiteValentineFullTaskList()
        local tasks = {}
        for _, v in pairs(WhiteValentineTaskData) do
            table.insert(tasks, v)
        end
        return tasks
    end

    function XTaskManager.GetWhiteValentineFirstNotAcheivedMission()
        local taskList = XDataCenter.TaskManager.GetWhiteValentineFullTaskList()
        for _, v in pairs(taskList or {}) do
            v.SortWeight = 2
            if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                v.SortWeight = 1
            elseif v.State == XDataCenter.TaskManager.TaskState.Finish or v.State == XDataCenter.TaskManager.TaskState.Invalid then
                v.SortWeight = 3
            end
        end
        table.sort(taskList, function(taskA, taskB)
                if taskA.SortWeight == taskB.SortWeight then
                    return taskA.Id < taskB.Id
                end
                return taskA.SortWeight < taskB.SortWeight
            end)
        return taskList[1]
    end

    function XTaskManager.GetPokerGuessingTaskList()
        return GetTaskList(PokerGuessingTaskData)
    end

    function XTaskManager.GetFingerGuessingTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.FingerGuessing))
    end

    function XTaskManager.GetFingerGuessingFullTaskList()
        local tasks = {}
        for _, v in pairs(FingerGuessingTaskData) do
            table.insert(tasks, v)
        end
        return tasks
    end

    function XTaskManager.GetZhouMuFullTaskList()
        local tasks = {}
        for _, v in pairs(ZhouMuTaskData) do
            table.insert(tasks, v)
        end
        return tasks
    end

    function XTaskManager.GetWorldBossTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.WorldBoss))
    end

    function XTaskManager.GetNierTaskListByGroupId(groupId)
        local tasksCfgs = XTaskConfig.GetTaskTemplate()
        local result = {}
        for _, task in pairs(NieRTaskData) do
            local taskId = task.Id
            local task = NieRTaskData[taskId]
            if tasksCfgs[taskId].GroupId == groupId and task then
                result[taskId] = task
            end
        end
        return GetTaskList(result)
    end

    function XTaskManager.GetNieRTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.NieR))
    end

    function XTaskManager.GetWorldBossFullTaskList()
        local tasks = {}
        --local bossTaskDataDic = XDataCenter.WorldBossManager.GetWorldBossBossTaskDataDic()
        --
        --for _, v in pairs(WorldBossTaskData) do
        --    local IsCanShow = true
        --    for _, data in pairs(bossTaskDataDic and bossTaskDataDic[v.Id] or {}) do
        --        if data:GetIsLock() then
        --            IsCanShow = false
        --            break
        --        end
        --    end
        --    if IsCanShow then
        --        table.insert(tasks, v)
        --    end
        --end
        return tasks
    end

    function XTaskManager.GetMentorGrowTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.MentorShipGrow))
    end

    function XTaskManager.GetMentorGrowFullTaskList()
        local taskTemplate = XTaskConfig.GetTaskTemplate()
        local tasks = {}
        for _, v in pairs(MentorGrowTaskData) do
            table.insert(tasks, v)
        end
        tableSort(tasks, function(a, b)
                local pa, pb = taskTemplate[a.Id].Priority, taskTemplate[b.Id].Priority
                local stateA = TotalTaskData[a.Id].State
                local stateB = TotalTaskData[b.Id].State
                local compareResult = CompareState(stateA, stateB)
                if compareResult == 0 then
                    if pa ~= pb then
                        return pa > pb
                    else
                        return a.Id > b.Id
                    end
                else
                    return compareResult > 0
                end
            end)

        return tasks
    end

    function XTaskManager.GetMentorGraduateTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.MentorShipGraduate))
    end

    function XTaskManager.GetMentorGraduateFullTaskList()
        local taskTemplate = XTaskConfig.GetTaskTemplate()
        local tasks = {}
        for _, v in pairs(MentorGraduateTaskData) do
            table.insert(tasks, v)
        end
        tableSort(tasks, function(a, b)
                local pa, pb = taskTemplate[a.Id].Priority, taskTemplate[b.Id].Priority
                local stateA = TotalTaskData[a.Id].State
                local stateB = TotalTaskData[b.Id].State
                local compareResult = CompareState(stateA, stateB)
                if compareResult == 0 then
                    if pa ~= pb then
                        return pa > pb
                    else
                        return a.Id > b.Id
                    end
                else
                    return compareResult > 0
                end
            end)
        return tasks
    end

    function XTaskManager.GetCoupletTaskList()
        local tasks = {}
        for _, v in pairs(CoupletTaskData) do
            table.insert(tasks, v)
        end
        return tasks
    end
    
    function XTaskManager.GetSimulatedCombatTaskList()
        local tasks = {}
        for _, v in pairs(SimulatedCombatTaskData) do
            table.insert(tasks, v)
        end
        return tasks
    end



    function XTaskManager.CheckMentorGraduateAllAchieved()
        local taskTemplate = XTaskConfig.GetTaskTemplate()
        for _, v in pairs(MentorGraduateTaskData) do
            if TotalTaskData[v.Id].State < XTaskManager.TaskState.Achieved then
                return false
            end
        end
        return true
    end

    function XTaskManager.GetMentorWeeklyTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.MentorShipWeekly))
    end

    function XTaskManager.GetMentorWeeklyFullTaskList()
        local taskTemplate = XTaskConfig.GetTaskTemplate()
        local tasks = {}
        for _, v in pairs(MentorWeeklyTaskData) do
            table.insert(tasks, v)
        end
        tableSort(tasks, function(a, b)
                local pa, pb = taskTemplate[a.Id].Priority, taskTemplate[b.Id].Priority
                local stateA = TotalTaskData[a.Id].State
                local stateB = TotalTaskData[b.Id].State
                local compareResult = CompareState(stateA, stateB)
                if compareResult == 0 then
                    if pa ~= pb then
                        return pa > pb
                    else
                        return a.Id > b.Id
                    end
                else
                    return compareResult > 0
                end
            end)
        return tasks
    end

    -- 包括已完成的任务
    function XTaskManager.GetGuildDailyTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.GuildDaily))
    end

    function XTaskManager.GetGuildDailyFullTaskList()
        local tasks = {}
        for _, v in pairs(GuildDailyTaskData) do
            table.insert(tasks, v)
        end
        return tasks
    end

    function XTaskManager.GetGuildMainlyTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.GuildMainly))
    end

    function XTaskManager.GetGuildMainlyFullTaskList()
        local tasks = {}
        for _, v in pairs(GuildMainlyTaskData) do
            table.insert(tasks, v)
        end
        return tasks
    end

    function XTaskManager.GetGuildWeeklyTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.GuildWeekly))
    end

    function XTaskManager.GetGuildWeeklyFullTaskList()
        local tasks = {}
        for _, v in pairs(GuildWeeklyTaskData) do
            table.insert(tasks, v)
        end
        return tasks
    end

    function XTaskManager.CheckLimitTaskList(taskGroupId)
        local tasks = XTaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
        for _, v in pairs(tasks or {}) do
            if v.State == XTaskManager.TaskState.Achieved then
                return true
            end
        end
        return false
    end

    function XTaskManager.GetTimeLimitTaskListByGroupId(taskGroupId, isSort)
        if isSort == nil then isSort = true end
        local taskDatas = {}

        local timeLimitTaskCfg = taskGroupId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(taskGroupId)
        if not timeLimitTaskCfg then return taskDatas end

        if not XTaskConfig.IsTimeLimitTaskInTime(taskGroupId) then
            return taskDatas
        end

        for _, taskId in ipairs(timeLimitTaskCfg.TaskId) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if CheckTask(taskData) then
                tableInsert(taskDatas, taskData)
            end
        end
        for _, taskId in ipairs(timeLimitTaskCfg.DayTaskId) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if CheckTask(taskData) then
                tableInsert(taskDatas, taskData)
            end
        end
        for _, taskId in ipairs(timeLimitTaskCfg.WeekTaskId) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if CheckTask(taskData) then
                tableInsert(taskDatas, taskData)
            end
        end

        if isSort then
            local achieved = XDataCenter.TaskManager.TaskState.Achieved
            local finish = XDataCenter.TaskManager.TaskState.Finish
            tableSort(taskDatas, function(a, b)
                if a.State ~= b.State then
                    if a.State == achieved then
                        return true
                    end
                    if b.State == achieved then
                        return false
                    end
                    if a.State == finish then
                        return false
                    end
                    if b.State == finish then
                        return true
                    end
                end
    
                local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(a.Id)
                local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(b.Id)
                return templatesTaskA.Priority > templatesTaskB.Priority
            end)
        end

        return taskDatas
    end

    -- 读取一串taskid的数据
    ---@return XTaskData[]
    function XTaskManager.GetTaskIdListData(taskIds, isSort)
        if isSort == nil then isSort = true end
        local taskDatas = {}
        if XTool.IsTableEmpty(taskIds) then return taskDatas end
        
        for _, taskId in ipairs(taskIds) do
            local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
            if CheckTask(taskData) then
                tableInsert(taskDatas, taskData)
            end
        end

        if isSort then
            local achieved = XDataCenter.TaskManager.TaskState.Achieved
            local finish = XDataCenter.TaskManager.TaskState.Finish
            tableSort(taskDatas, function(a, b)
                if a.State ~= b.State then
                    if a.State == achieved then
                        return true
                    end
                    if b.State == achieved then
                        return false
                    end
                    if a.State == finish then
                        return false
                    end
                    if b.State == finish then
                        return true
                    end
                end
    
                local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(a.Id)
                local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(b.Id)
                return templatesTaskA.Priority > templatesTaskB.Priority
            end)
        end

        return taskDatas
    end

    function XTaskManager.GetPokemonTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.Pokemon))
    end

    function XTaskManager.GetMoeWarDailyTaskList()
        return GetTaskList(MoeWarDailyTaskData)
    end

    function XTaskManager.GetMoeWarNormalTaskList()
        return GetTaskList(MoeWarNormalTaskData)
    end

    function XTaskManager.GetPassportTaskList()
        return GetTaskList(PassportTaskData)
    end

    function XTaskManager.GetDlcHuntTaskList()
        return GetTaskList(XTaskManager.GetTaskDataByTaskType(XTaskManager.TaskType.DlcHunt))
    end

    function XTaskManager.GetLivWarmSoundsActivityFullTaskList()
        return GetTaskList(LivWarmSoundsActivityTaskData)
    end
    --根据任务类型获取对应的任务数据
    function XTaskManager.GetSortTaskListByTaskType(taskType)
        return GetTaskList(XTaskManager.GetTaskList(taskType))
    end

    ---------------- 仅支持使用通用接口的任务类型 --------------
    function XTaskManager.GetTaskList(taskType, groupId)
        local tasks = {}

        if TaskDataGroup[taskType] ~= nil then
            for _, v in pairs(TaskDataGroup[taskType]) do
                if groupId then
                    local templates = XTaskConfig.GetTaskCfgById(v.Id)
                    if templates.GroupId ~= groupId then
                        goto CONTINUE
                    end
                end
                table.insert(tasks, v)
                ::CONTINUE::
            end
        end
        return tasks
    end

    function XTaskManager.GetTaskProgress(taskType, groupId)
        local passCount = 0
        local allCount = 0
        if TaskDataGroup[taskType] ~= nil then
            for _, task in pairs(TaskDataGroup[taskType]) do
                if groupId then
                    local templates = XTaskConfig.GetTaskCfgById(task.Id)
                    if templates.GroupId ~= groupId then
                        goto CONTINUE
                    end
                end
                allCount = allCount + 1
                if task.State == XDataCenter.TaskManager.TaskState.Finish then
                    passCount = passCount + 1
                end
                ::CONTINUE::
            end
        end
        return passCount, allCount
    end

    function XTaskManager.GetTaskProgressByTaskList(taskList)
        local passCount = 0
        local allCount = 0
        for _, task in pairs(taskList) do
            allCount = allCount + 1
            if task.State == XDataCenter.TaskManager.TaskState.Finish then
                passCount = passCount + 1
            end
            :: CONTINUE ::
        end
        return passCount, allCount
    end
    ---------------------------------------------------

    --根据任务类型获得成就任务
    function XTaskManager.GetAchvTaskByAchieveType(achvType)
        local achieveTasks = XTaskManager.GetAchvTaskList()
        local taskList = {}
        for _, var in achieveTasks do
            if var.AchvType == achvType then
                tableInsert(taskList, var)
            end
        end
    end

    function XTaskManager.GetTaskDataByTaskType(taskType)
        local datas = {}

        if taskType == XTaskManager.TaskType.Story then
            datas = StoryTaskData
        elseif taskType == XTaskManager.TaskType.Daily then
            datas = DailyTaskData
        elseif taskType == XTaskManager.TaskType.Weekly then
            datas = WeeklyTaskData
        elseif taskType == XTaskManager.TaskType.Activity then
            datas = ActivityTaskData
        elseif taskType == XTaskManager.TaskType.NewPlayer then
            datas = NewPlayerTaskData
        elseif taskType == XTaskManager.TaskType.Achievement then
            datas = AchvTaskData
        elseif taskType == XTaskManager.TaskType.ArenaChallenge then
            datas = ArenaTaskData
        elseif taskType == XTaskManager.TaskType.TimeLimit then
            datas = TimeLimitTaskData
        elseif taskType == XTaskManager.TaskType.DormDaily then
            datas = DormDailyTaskData
        elseif taskType == XTaskManager.TaskType.DormNormal then
            datas = DormNormalTaskData
        elseif taskType == XTaskManager.TaskType.BabelTower then
            datas = BabelTowerTaskData
        elseif taskType == XTaskManager.TaskType.RogueLike then
            datas = RogueLikeTaskData
        elseif taskType == XTaskManager.TaskType.GuildDaily then
            datas = GuildDailyTaskData
        elseif taskType == XTaskManager.TaskType.GuildMainly then
            datas = GuildMainlyTaskData
        elseif taskType == XTaskManager.TaskType.GuildWeekly then
            datas = GuildWeeklyTaskData
        elseif taskType == XTaskManager.TaskType.ArenaOnlineWeekly then
            datas = ArenaOnlineWeeklyTaskData
        elseif taskType == XTaskManager.TaskType.InfestorWeekly then
            datas = InfestorWeeklyTaskData
        elseif taskType == XTaskManager.TaskType.WorldBoss then
            datas = WorldBossTaskData
        elseif taskType == XTaskManager.TaskType.RpgTower then
            datas = RpgTowerTaskData
        elseif taskType == XTaskManager.TaskType.WhiteValetine then
            datas = WhiteValentineTaskData
        elseif taskType == XTaskManager.TaskType.FingerGuessing then
            datas = FingerGuessingTaskData
        elseif taskType == XTaskManager.TaskType.MentorShipGrow then
            datas = MentorGrowTaskData
        elseif taskType == XTaskManager.TaskType.MentorShipGraduate then
            datas = MentorGraduateTaskData
        elseif taskType == XTaskManager.TaskType.MentorShipWeekly then
            datas = MentorWeeklyTaskData
        elseif taskType == XTaskManager.TaskType.NieR then
            datas = NieRTaskData
        elseif taskType == XTaskManager.TaskType.Pokemon then
            datas = PokemonTaskData
        elseif taskType == XTaskManager.TaskType.Couplet then
            datas = CoupletTaskData
        elseif taskType == XTaskManager.TaskType.SimulatedCombat then
            datas = SimulatedCombatTaskData
        elseif taskType == XTaskManager.TaskType.MoeWarDaily then
            datas = MoeWarDailyTaskData
        elseif taskType == XTaskManager.TaskType.MoeWarNormal then
            datas = MoeWarNormalTaskData
        elseif taskType == XTaskManager.TaskType.PokerGuessing or taskType == XTaskManager.TaskType.PokerGuessingCollection then
            datas = PokerGuessingTaskData
        elseif taskType == XTaskManager.TaskType.Passport then
            datas = PassportTaskData
        elseif taskType == XTaskManager.TaskType.Rift then
            datas = RiftTaskData
        elseif taskType then
            datas = TaskDataGroup[taskType] or {}
        end
        local result = TaskResultDataCache[taskType] or {}
        if not XTool.IsTableEmpty(result) then
            return result
        end
        for k, v in pairs(datas) do
            --原:  v.State ~= XTaskManager.TaskState.Finish and v.State ~= XTaskManager.TaskState.Invalid
            local dataTaskType = XTaskConfig.GetTaskTemplate()[v.Id].Type
            if dataTaskType == XTaskManager.TaskType.Achievement and v.State == XTaskManager.TaskState.Finish then
                result[k] = v
            elseif v.State ~= XTaskManager.TaskState.Finish and v.State ~= XTaskManager.TaskState.Invalid then
                result[k] = v
            elseif dataTaskType == XTaskManager.TaskType.ArenaChallenge and v.State ~= XTaskManager.TaskState.Invalid then
                result[k] = v
            elseif dataTaskType == XTaskManager.TaskType.SpecialTrainDailySwitchTask and v.State ~= XTaskManager.TaskState.Invalid then
                result[k] = v
            elseif dataTaskType == XTaskManager.TaskType.DlcHunt and v.State ~= XTaskManager.TaskState.Invalid then
                result[k] = v
            end
        end
        TaskResultDataCache[taskType] = result
        return result
    end

    function XTaskManager.ResetStoryGroupTaskData()
        for _, v in pairs(StoryGroupTaskData) do
            v.UnfinishCount = 0
        end
    end

    function XTaskManager.GetCurrentStoryTaskGroupId()
        XTaskManager.ResetStoryGroupTaskData()

        local headGroupId = 1
        for _, v in pairs(StoryTaskData) do
            local templates = XTaskManager.GetTaskTemplate(v.Id)
            if templates.GroupId > 0 then
                if templates.ShowAfterGroup <= 0 then
                    headGroupId = templates.GroupId
                end
                local groupDatas = StoryGroupTaskData[templates.GroupId]
                if groupDatas == nil then
                    StoryGroupTaskData[templates.GroupId] = {}
                    groupDatas = StoryGroupTaskData[templates.GroupId]
                    groupDatas.GroupId = templates.GroupId
                    groupDatas.ShowAfterGroup = templates.ShowAfterGroup
                    groupDatas.UnfinishCount = 0
                end

                if v.State ~= XTaskManager.TaskState.Finish and v.State ~= XTaskManager.TaskState.Invalid then
                    groupDatas.UnfinishCount = groupDatas.UnfinishCount + 1
                end
            end
        end

        for _, groupDatas in pairs(StoryGroupTaskData) do
            if groupDatas.ShowAfterGroup > 0 then
                StoryGroupTaskData[groupDatas.ShowAfterGroup].NextGroupId = groupDatas.GroupId
            end
        end

        local currentGoupId = headGroupId
        local currentGroupDatas = StoryGroupTaskData[currentGoupId]
        while currentGroupDatas and currentGroupDatas.UnfinishCount <= 0 do
            currentGoupId = currentGroupDatas.NextGroupId
            if currentGoupId == nil then break end
            currentGroupDatas = StoryGroupTaskData[currentGoupId]
        end
        return currentGoupId
    end

    function XTaskManager.ResetDormStoryGroupTaskData()
        for _, v in pairs(DormStoryGroupTaskData) do
            v.UnfinishCount = 0
        end
    end

    function XTaskManager.ResetDormDailyGroupTaskData()
        for _, v in pairs(DormDailyGroupTaskData) do
            v.UnfinishCount = 0
        end
    end

    function XTaskManager.GetCurrentDormDailyTaskGroupId()
        XTaskManager.ResetDormDailyGroupTaskData()

        local headGroupId = 1
        for _, v in pairs(DormDailyTaskData) do
            local templates = XTaskManager.GetTaskTemplate(v.Id)
            if templates.GroupId > 0 then
                if templates.ShowAfterGroup <= 0 then
                    headGroupId = templates.GroupId
                end
                local groupDatas = DormDailyGroupTaskData[templates.GroupId]
                if groupDatas == nil then
                    DormDailyGroupTaskData[templates.GroupId] = {}
                    groupDatas = DormDailyGroupTaskData[templates.GroupId]
                    groupDatas.GroupId = templates.GroupId
                    groupDatas.ShowAfterGroup = templates.ShowAfterGroup
                    groupDatas.UnfinishCount = 0
                end

                if v.State ~= XTaskManager.TaskState.Finish and v.State ~= XTaskManager.TaskState.Invalid then
                    groupDatas.UnfinishCount = groupDatas.UnfinishCount + 1
                end
            end
        end

        for _, groupDatas in pairs(DormDailyGroupTaskData) do
            if groupDatas.ShowAfterGroup > 0 then
                DormDailyGroupTaskData[groupDatas.ShowAfterGroup].NextGroupId = groupDatas.GroupId
            end
        end

        local currentGoupId = headGroupId
        local currentGroupDatas = DormDailyGroupTaskData[currentGoupId]
        while currentGroupDatas and currentGroupDatas.UnfinishCount <= 0 do
            currentGoupId = currentGroupDatas.NextGroupId
            if currentGoupId == nil then break end
            currentGroupDatas = DormDailyGroupTaskData[currentGoupId]
        end
        return currentGoupId
    end

    function XTaskManager.GetCurrentDormStoryTaskGroupId()
        XTaskManager.ResetDormStoryGroupTaskData()

        local headGroupId = 1
        for _, v in pairs(DormNormalTaskData) do
            local templates = XTaskManager.GetTaskTemplate(v.Id)
            if templates.GroupId > 0 then
                if templates.ShowAfterGroup <= 0 then
                    headGroupId = templates.GroupId
                end
                local groupDatas = DormStoryGroupTaskData[templates.GroupId]
                if groupDatas == nil then
                    DormStoryGroupTaskData[templates.GroupId] = {}
                    groupDatas = DormStoryGroupTaskData[templates.GroupId]
                    groupDatas.GroupId = templates.GroupId
                    groupDatas.ShowAfterGroup = templates.ShowAfterGroup
                    groupDatas.UnfinishCount = 0
                end

                if v.State ~= XTaskManager.TaskState.Finish and v.State ~= XTaskManager.TaskState.Invalid then
                    groupDatas.UnfinishCount = groupDatas.UnfinishCount + 1
                end
            end
        end

        for _, groupDatas in pairs(DormStoryGroupTaskData) do
            if groupDatas.ShowAfterGroup > 0 then
                DormStoryGroupTaskData[groupDatas.ShowAfterGroup].NextGroupId = groupDatas.GroupId
            end
        end

        local currentGoupId = headGroupId
        local currentGroupDatas = DormStoryGroupTaskData[currentGoupId]
        while currentGroupDatas and currentGroupDatas.UnfinishCount <= 0 do
            currentGoupId = currentGroupDatas.NextGroupId
            if currentGoupId == nil then break end
            currentGroupDatas = DormStoryGroupTaskData[currentGoupId]
        end
        return currentGoupId
    end
    -- 检查主线剧情任务的红点
    function XTaskManager.CheckStoryTaskByGroup()
        -- 只检查当前组和当前没有组id的任务时候可以领取
        local currTaskGroupId = XDataCenter.TaskManager.GetCurrentStoryTaskGroupId()

        for _, taskInfo in pairs(StoryTaskData) do
            local templates = XDataCenter.TaskManager.GetTaskTemplate(taskInfo.Id)
            -- 分组任务和非组任务
            if templates.GroupId > 0 then
                --组任务
                if currTaskGroupId and currTaskGroupId == templates.GroupId then
                    if taskInfo ~= nil and currTaskGroupId == templates.GroupId and taskInfo.State == XTaskManager.TaskState.Achieved then
                        return true
                    end
                end
            else
                --非组任务
                if taskInfo ~= nil and taskInfo.State == XTaskManager.TaskState.Achieved then
                    return true
                end
            end
        end
        return false
    end


    function XTaskManager.GetTaskTemplate(templateId)
        local template = XTaskConfig.GetTaskTemplate()[templateId]
        if not template then
            local path = XTaskConfig.GetTaskPath()
            XLog.ErrorTableDataNotFound("XTaskManager.GetTaskTemplate", "template", path, "templateId", tostring(templateId))
        else
            return template
        end
    end

    function XTaskManager.GetShowAfterTaskId(templateId)
        local template = XTaskManager.GetTaskTemplate(templateId)
        if template then
            return template.ShowAfterTaskId
        end
    end

    function XTaskManager.SyncTasks(data)
        if data.TaskLimitIdActiveInfos then
            for _, v in pairs(data.TaskLimitIdActiveInfos) do
                LinkTaskTimeDict[v.TaskLimitId] = v.ActiveTime
            end
            if not XTaskManager.IgnoreSyncTasksEvent then
                XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_INFO_UPDATE)
            end
        end
        local tasks = data.Tasks
        XTool.LoopCollection(tasks.Tasks, function(value)
            FinishedTasks[value.Id] = value.State == XTaskManager.TaskState.Finish
            local taskType = XTaskManager.GetTaskTemplate(value.Id).Type
            if taskType then
                --如果有任务同步，则清空缓存
                TaskResultDataCache[taskType] = nil
            end
            TotalTaskData[value.Id] = value
            if taskType == XTaskManager.TaskType.Story then
                StoryTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.Daily then
                DailyTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.Weekly then
                WeeklyTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.Activity then
                ActivityTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.NewPlayer then
                NewPlayerTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.Achievement then
                AchvTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.ArenaChallenge then
                ArenaTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.TimeLimit then
                TimeLimitTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.DormDaily then
                DormDailyTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.DormNormal then
                DormNormalTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.BabelTower then
                BabelTowerTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.RogueLike then
                RogueLikeTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.GuildDaily then
                GuildDailyTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.GuildMainly then
                GuildMainlyTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.GuildWeekly then
                GuildWeeklyTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.Regression then
                local id = value.Id
                local regressionTaskType = XRegressionConfigs.GetTaskTypeById(id)
                RegressionTaskData[id] = value
                if RegressionTaskCanGetDic[id] then
                    if value.State ~= XDataCenter.TaskManager.TaskState.Achieved then
                        RegressionTaskTypeToRedPointCountDic[regressionTaskType] = RegressionTaskTypeToRedPointCountDic[regressionTaskType] - 1
                        RegressionTaskRedPointCount = RegressionTaskRedPointCount - 1
                        RegressionTaskCanGetDic[id] = nil
                    end
                else
                    if value.State == XDataCenter.TaskManager.TaskState.Achieved then
                        RegressionTaskCanGetDic[id] = true
                        RegressionTaskTypeToRedPointCountDic[regressionTaskType] = RegressionTaskTypeToRedPointCountDic[regressionTaskType] or 0
                        RegressionTaskTypeToRedPointCountDic[regressionTaskType] = RegressionTaskTypeToRedPointCountDic[regressionTaskType] + 1
                        RegressionTaskRedPointCount = RegressionTaskRedPointCount + 1
                    end
                end
            elseif taskType == XTaskManager.TaskType.ArenaOnlineWeekly then
                ArenaOnlineWeeklyTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.InfestorWeekly then
                InfestorWeeklyTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.WorldBoss then
                WorldBossTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.RpgTower then
                RpgTowerTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.MentorShipGrow then
                MentorGrowTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.MentorShipGraduate then
                MentorGraduateTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.MentorShipWeekly then
                MentorWeeklyTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.ZhouMu then
                ZhouMuTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.NieR then
				NieRTaskData[value.Id] = value
			elseif taskType == XTaskManager.TaskType.Pokemon then
				PokemonTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.Couplet then
                CoupletTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.SimulatedCombat then
                SimulatedCombatTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.WhiteValentine then
                WhiteValentineTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.FingerGuessing then
                FingerGuessingTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.MoeWarDaily then
                MoeWarDailyTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.MoeWarNormal then
                MoeWarNormalTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.PokerGuessing or taskType == XTaskManager.TaskType.PokerGuessingCollection then
                PokerGuessingTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.Passport then
                PassportTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.LivWarmSoundsActivity then
                LivWarmSoundsActivityTaskData[value.Id] = value
            elseif taskType == XTaskManager.TaskType.Rift then
                RiftTaskData[value.Id] = value
            else
                if not TaskDataGroup[taskType] then
                    TaskDataGroup[taskType] = {}
                end
                TaskDataGroup[taskType][value.Id] = value
            end
        end)
        if not XTaskManager.IgnoreSyncTasksEvent then
            XEventManager.DispatchEvent(XEventId.EVENT_TASK_SYNC)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_TASK_SYNC)
        end
    end

    -- 关闭同步任务事件
    function XTaskManager.CloseSyncTasksEvent()
        XTaskManager.IgnoreSyncTasksEvent = true
    end

    -- 开启同步任务事件
    function XTaskManager.OpenSyncTasksEvent()
        XTaskManager.IgnoreSyncTasksEvent = false
        XEventManager.DispatchEvent(XEventId.EVENT_ACTIVITY_INFO_UPDATE)
        XEventManager.DispatchEvent(XEventId.EVENT_TASK_SYNC)
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_TASK_SYNC)
    end

    --根据任务类型判断是否有奖励可以领取
    function XTaskManager.GetIsRewardFor(taskType)
        local taskList = nil
        if taskType == XTaskManager.TaskType.Story then
            taskList = StoryTaskData
        elseif taskType == XTaskManager.TaskType.Daily then
            taskList = DailyTaskData
        elseif taskType == XTaskManager.TaskType.Activity then
            taskList = ActivityTaskData
        elseif taskType == XTaskManager.TaskType.Achievement then
            taskList = AchvTaskData
        elseif taskType == XTaskManager.TaskType.ArenaChallenge then
            taskList = ArenaTaskData
        elseif taskType == XTaskManager.TaskType.TimeLimit then
            taskList = TimeLimitTaskData
        elseif taskType == XTaskManager.TaskType.DormDaily then
            taskList = DormDailyTaskData
        elseif taskType == XTaskManager.TaskType.DormNormal then
            taskList = DormNormalTaskData
        elseif taskType == XTaskManager.TaskType.BabelTower then
            taskList = BabelTowerTaskData
        elseif taskType == XTaskManager.TaskType.RogueLike then
            taskList = RogueLikeTaskData
        elseif taskType == XTaskManager.TaskType.GuildDaily then
            taskList = GuildDailyTaskData
        elseif taskType == XTaskManager.TaskType.GuildMainly then
            taskList = GuildMainlyTaskData
        elseif taskType == XTaskManager.TaskType.GuildWeekly then
            taskList = GuildWeeklyTaskData
        elseif taskType == XTaskManager.TaskType.ArenaOnlineWeekly then
            taskList = XTaskManager.GetArenaOnlineWeeklyTaskList()
        elseif taskType == XTaskManager.TaskType.InfestorWeekly then
            taskList = XTaskManager.GetInfestorWeeklyTaskList()
        elseif taskType == XTaskManager.TaskType.WorldBoss then
            taskList = WorldBossTaskData
        elseif taskType == XTaskManager.TaskType.RpgTower then
            taskList = RpgTowerTaskData
        elseif taskType == XTaskManager.TaskType.MentorShipGrow then
            taskList = MentorGrowTaskData
        elseif taskType == XTaskManager.TaskType.MentorShipGraduate then
            taskList = MentorGraduateTaskData
        elseif taskType == XTaskManager.TaskType.MentorShipWeekly then
            taskList = MentorWeeklyTaskData
        elseif taskType == XTaskManager.TaskType.ZhouMu then
            taskList = ZhouMuTaskData
        elseif taskType == XTaskManager.TaskType.NieR then
			taskList = NieRTaskData
		elseif taskType == XTaskManager.TaskType.Pokemon then
			taskList = PokemonTaskData
        elseif taskType == XTaskManager.TaskType.Couplet then
            taskList = CoupletTaskData
        elseif taskType == XTaskManager.TaskType.SimulatedCombat then
            taskList = SimulatedCombatTaskData
        elseif taskType == XTaskManager.TaskType.WhiteValentine then
            taskList = WhiteValentineTaskData
        elseif taskType == XTaskManager.TaskType.FingerGuessing then
            taskList = FingerGuessingTaskData
        elseif taskType == XTaskManager.TaskType.MoeWarDaily then
            taskList = MoeWarDailyTaskData
        elseif taskType == XTaskManager.TaskType.MoeWarNormal then
            taskList = MoeWarNormalTaskData
        elseif taskType == XTaskManager.TaskType.PokerGuessing or taskType == XTaskManager.TaskType.PokerGuessingCollection then
            taskList = PokerGuessingTaskData
        elseif taskType == XTaskManager.TaskType.Passport then
            taskList = PassportTaskData
        elseif taskType == XTaskManager.TaskType.LivWarmSoundsActivity then
            taskList = LivWarmSoundsActivityTaskData
        elseif taskType == XTaskManager.TaskType.Rift then
            taskList = RiftTaskData
        else
            taskList = TaskDataGroup[taskType]
        end

        if taskList == nil then
            return false
        end

        if taskType == XTaskManager.TaskType.Story then
            return XTaskManager.CheckStoryTaskByGroup()
        end

        for _, taskInfo in pairs(taskList) do
            if taskInfo ~= nil and taskInfo.State == XTaskManager.TaskState.Achieved then
                return true
            end
        end
        return false
    end
    --获取周奖励
    function XTaskManager.GetIsWeekReward()
        local activeness = XDataCenter.ItemManager.GetWeeklyActiveness().Count
        local rewardIds = XTaskManager.GetWeeklyActivenessRewardIds()
        for index = 1, #rewardIds do
            if activeness >= rewardIds[index] then
                return true
            end
        end
        return false
    end

    function XTaskManager.FinishTask(taskId, cb)
        cb = cb or function() end
        XNetwork.Call("FinishTaskRequest", { TaskId = taskId }, function(reply)
            if reply.Code ~= XCode.Success then
                XUiManager.TipCode(reply.Code)
                XEventManager.DispatchEvent(XEventId.EVENT_TASK_FINISH_FAIL)
                --BDC
                CS.XHeroBdcAgent.BdcAwardButtonClick(taskId, 2)
                return
            end
            --BDC
            CS.XHeroBdcAgent.BdcAwardButtonClick(taskId, 1)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FINISH_TASK)
            XEventManager.DispatchEvent(XEventId.EVENT_FINISH_TASK)

            cb(reply.RewardGoodsList)

        end)
    end

    --批量领取任务奖励
    local MultiTaskResReward = {}
    function XTaskManager.FinishMultiTaskRequest(taskIds, cb, notTip, isLoopReceive)
        if XTool.IsTableEmpty(taskIds) then
            XLog.BuglyLog("XTaskManager", "FinishMultiTaskRequest taskIds empty")
            return
        end

        cb = cb or function() end
        XNetwork.Call("FinishMultiTaskRequest", { TaskIds = taskIds }, function(reply)
            if reply.Code ~= XCode.Success then
                if not notTip then
                    XUiManager.TipCode(reply.Code)
                end
                XEventManager.DispatchEvent(XEventId.EVENT_TASK_FINISH_FAIL)
                return
            end

            if isLoopReceive then
                for k, v in pairs(reply.RewardGoodsList) do
                    table.insert(MultiTaskResReward, v)
                end
                if not XTool.IsTableEmpty(reply.NotDealTaskIds) then
                    XTaskManager.FinishMultiTaskRequest(reply.NotDealTaskIds, cb, notTip, isLoopReceive)
                    return
                end
            else
                MultiTaskResReward = reply.RewardGoodsList
            end

            cb(MultiTaskResReward)
            MultiTaskResReward = {}
            XEventManager.DispatchEvent(XEventId.EVENT_FINISH_MULTI, true)
        end)
    end

    --获取历程奖励
    function XTaskManager.GetCourseReward(stageId, cb)
        cb = cb or function() end
        XNetwork.Call("GetCourseRewardRequest", { StageId = stageId }, function(reply)
            if reply.Code ~= XCode.Success then
                XUiManager.TipCode(reply.Code)
                return
            end

            -- 这里顺序不要变
            local allRewardGet = XTaskManager.SetCourseData(stageId)
            if cb then cb(allRewardGet) end

            XUiManager.OpenUiObtain(reply.RewardGoodsList)
            XEventManager.DispatchEvent(XEventId.EVENT_TASK_COURSE_REWAED)
        end)
    end

    -- v1.31 【任务日常活跃】一键领取
    function XTaskManager.GetActivenessReward(rewardType, cb)
        cb = cb or function() end
        -- 优化一键领取后StageIndex和RewardId这两个参数后端不再使用
        XNetwork.Call("GetActivenessRewardRequest", { StageIndex = 0, RewardId = 0, RewardType = rewardType }, function(reply)
            if reply.Code ~= XCode.Success then
                XUiManager.TipCode(reply.Code)
                return
            end

            cb()

            XEventManager.DispatchEvent(XEventId.EVENT_TASK_SYNC)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_TASK_SYNC)
            XUiManager.OpenUiObtain(reply.RewardGoodsList)
        end)
    end
    
    --客户端判断完成条件，向服务端请求完成
    function XTaskManager.RequestClientTaskFinish(taskId, func)
        local taskCfg = XTaskConfig.GetTaskCfgById(taskId)
        local conditionTemplates = XTaskConfig.GetTaskCondition(taskCfg.Condition[1])
        local taskType = conditionTemplates.Params[2]
        -- 请求任务条件完成
        local req = { ClientTaskType = taskType }
        
        XNetwork.Call("DoClientTaskEventRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            if func then func() end
        end)
    end

    ----NewPlayerTask
    function XTaskManager.GetNewPlayerTaskTalkConfig(group)
        return XTaskConfig.GetNewPlayerTaskTalkTemplate()[group]
    end

    function XTaskManager.GetNewPlayerTaskGroup(group)
        return XTaskConfig.GetNewPlayerTaskGroupTemplate()[group]
    end

    function XTaskManager.GetNewbiePlayTaskReddotByOpenDay(openDay)

        if XPlayer.NewPlayerTaskActiveDay == nil then
            return false
        end

        if XPlayer.NewPlayerTaskActiveDay < openDay then
            return false
        end

        local tasks = XTaskConfig.GetNewPlayerTaskGroupTemplate()[openDay]
        if not tasks or not tasks.TaskId then return false end

        for _, id in pairs(tasks.TaskId) do
            local stateTask = XTaskManager.GetTaskDataById(id)
            if stateTask and stateTask.State == XTaskManager.TaskState.Achieved then
                return true
            end
        end
        return false
    end

    function XTaskManager.GetNewPlayerTaskListByGroup(group)
        local tTaskGroupConfig = XTaskConfig.GetNewPlayerTaskGroupTemplate()[group]
        if not tTaskGroupConfig then return end
        local tTaskIdList = tTaskGroupConfig.TaskId
        if not tTaskIdList then return end
        local tCurGroupTaskList = {}
        for _, v in ipairs(tTaskIdList) do
            local template = XTaskConfig.GetTaskTemplate()[v]
            local preId = template and template.ShowAfterTaskId
            preId = preId and preId > 0 and preId
            local preTask = preId and NewPlayerTaskData[preId]
            if not preTask or preTask and preTask.State == XTaskManager.TaskState.Finish then
                tableInsert(tCurGroupTaskList, v)
            end
        end
        tableSort(tCurGroupTaskList, function(aId, bId)
            local a = NewPlayerTaskData[aId]
            local b = NewPlayerTaskData[bId]
            local fCallfunc = function(aId2, bId2)
                return aId2 < bId2
            end
            if a and b then
                if a.State ~= b.State then
                    if a.State == XTaskManager.TaskState.Achieved then
                        return true
                    end
                    if b.State == XTaskManager.TaskState.Achieved then
                        return false
                    end
                    if a.State == XTaskManager.TaskState.Finish or a.State == XTaskManager.TaskState.Invalid then
                        return false
                    end
                    if b.State == XTaskManager.TaskState.Finish or b.State == XTaskManager.TaskState.Invalid then
                        return true
                    end
                else
                    return fCallfunc(aId, bId)
                end
            else
                if a and a.State == XTaskManager.TaskState.Finish then
                    return false
                end
                if b and b.State == XTaskManager.TaskState.Finish then
                    return true
                end
                return fCallfunc(aId, bId)
            end

        end)
        return tCurGroupTaskList
    end

    function XTaskManager.GetNewPlayerGroupTaskStatus(group)

        if XPlayer.NewPlayerTaskActiveDay < group then
            return XTaskManager.NewPlayerTaskGroupState.Lock
        end

        local tTaskGroupConfig = XTaskConfig.GetNewPlayerTaskGroupTemplate()[group]
        if not tTaskGroupConfig then return end
        local tTaskIdList = tTaskGroupConfig.TaskId
        if not tTaskIdList then return end
        local finishCount = 0
        for _, v in ipairs(tTaskIdList) do
            local tTaskData = NewPlayerTaskData[v]
            if not tTaskData then
                return XTaskManager.NewPlayerTaskGroupState.Lock
            end
            local template = XTaskManager.GetTaskTemplate(tTaskData.Id)
            local preId = template and template.ShowAfterTaskId
            local preTask = preId == 0 and nil or TotalTaskData[preId]

            if preTask then
                if preTask.State == XTaskManager.TaskState.Finish and tTaskData.State == XTaskManager.TaskState.Achieved then
                    return XTaskManager.NewPlayerTaskGroupState.HasAward
                end
            elseif FinishedTasks[preId] then
                return XTaskManager.NewPlayerTaskGroupState.HasAward
            end

            if not preTask and tTaskData.State == XTaskManager.TaskState.Achieved then
                return XTaskManager.NewPlayerTaskGroupState.HasAward
            end

            if tTaskData.State == XTaskManager.TaskState.Finish then
                finishCount = finishCount + 1
            end
        end

        if finishCount == #tTaskIdList then
            return XTaskManager.NewPlayerTaskGroupState.AllFinish
        end

        return XTaskManager.NewPlayerTaskGroupState.AllTodo
    end

    function XTaskManager.FindNewPlayerTaskTalkContent(group)
        local config = XTaskConfig.GetNewPlayerTaskTalkTemplate()[group]
        if not config then
            return
        end
        local tTaskGroupConfig = XTaskConfig.GetNewPlayerTaskGroupTemplate()[group]
        if not tTaskGroupConfig then return end
        local tTaskIdList = tTaskGroupConfig.TaskId
        if not tTaskIdList then return end
        local finishCount = 0
        for _, v in ipairs(tTaskIdList) do
            local tTaskData = NewPlayerTaskData[v]
            if tTaskData and tTaskData.State == XTaskManager.TaskState.Finish then
                finishCount = finishCount + 1
            end
        end

        local index = 1
        for i, v in ipairs(config.GetCount) do
            if finishCount >= v then
                index = i
            end
        end
        return config.TalkContent[index], config
    end

    function XTaskManager.SetNewPlayerTaskActiveUi(group)
        XNetwork.Call("SetNewPlayerTaskActiveUiRequest", { Group = group }, function(reply)
            if reply.Code ~= XCode.Success then
                XUiManager.TipCode(reply.Code)
                return
            end
            XPlayer.SetNewPlayerTaskActiveUi(reply.Result)
        end)
    end

    function XTaskManager.CheckTaskFinished(taskId)
        local taskData = XTaskManager.GetTaskDataById(taskId)
        return taskData and taskData.State == XTaskManager.TaskState.Finish
    end

    function XTaskManager.CheckTaskAchieved(taskId)
        local taskData = XTaskManager.GetTaskDataById(taskId)
        return taskData and taskData.State == XTaskManager.TaskState.Achieved
    end

    function XTaskManager.GetFinalChapterId()
        for k, v in pairs(CourseInfos or {}) do
            if v.NextChapterId == nil then
                return k
            end
        end
        return nil
    end

    function XTaskManager.CheckNewbieActivenessAvailable()
        local currentCount = XDataCenter.ItemManager.GetCount(ITEM_NEWBIE_PROGRESS_ID)
        for _, v in pairs(XTaskConfig.GetTaskNewbieActivenessTemplate().Activeness or {}) do
            if not XTaskManager.CheckNewbieActivenessRecord(v) and currentCount >= v then
                return true
            end
        end
        return false
    end

    function XTaskManager.CheckNewbieTaskAvailable()
        if not XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.Target) then
            return false
        end

        if XTaskManager.CheckNewbieActivenessAvailable() then
            return true
        end

        for _, groupDatas in pairs(XTaskConfig.GetNewPlayerTaskGroupTemplate() or {}) do
            for _, taskId in pairs(groupDatas.TaskId or {}) do
                local stateTask = XTaskManager.GetTaskDataById(taskId)
                if stateTask and stateTask.State ~= XTaskManager.TaskState.Finish and stateTask.State ~= XTaskManager.TaskState.Invalid then
                    return true
                end
            end
        end
        return false
    end

    function XTaskManager.CheckNewbieActivenessRecord(activenessId)
        for _, record in pairs(NewbieActivenessRecord or {}) do
            if activenessId == record then
                return true
            end
        end
        return false
    end

    function XTaskManager.UpdateNewbieActivenessRecord(activenessId)
        for _, record in pairs(NewbieActivenessRecord or {}) do
            if activenessId == record then
                return
            end
        end
        NewbieActivenessRecord[#NewbieActivenessRecord + 1] = activenessId
    end

    function XTaskManager.GetStoryTaskShowId()
        local groupId = XTaskManager.GetCurrentStoryTaskGroupId()
        if groupId == nil or groupId <= 0 then
            return 0
        end
        -- 有没有主题任务。
        local maxPriority = 0
        local currentTask = 0
        for _, v in pairs(StoryTaskData) do
            local templates = XTaskManager.GetTaskTemplate(v.Id)
            if templates.GroupId == groupId and templates.ShowType == 1 then
                if v.State ~= XTaskManager.TaskState.Finish and v.State ~= XTaskManager.TaskState.Invalid then
                    if templates.Priority >= maxPriority then
                        maxPriority = templates.Priority
                        currentTask = v.Id
                    end
                end
            end
        end
        return currentTask
    end

    function XTaskManager.SaveNewPlayerHint(key, value)
        if XPlayer.Id then
            key = string.format("%s_%s", tostring(XPlayer.Id), key)
            CS.UnityEngine.PlayerPrefs.SetInt(key, value)
            CS.UnityEngine.PlayerPrefs.Save()
        end
    end

    function XTaskManager.GetNewPlayerHint(key, defaultValue)
        if XPlayer.Id then
            key = string.format("%s_%s", tostring(XPlayer.Id), key)
            if CS.UnityEngine.PlayerPrefs.HasKey(key) then
                local newPlayerHint = CS.UnityEngine.PlayerPrefs.GetInt(key)
                return (newPlayerHint == nil or newPlayerHint == 0) and defaultValue or newPlayerHint
            end
        end
        return defaultValue
    end

    function XTaskManager.GetNewPlayerRewardReq(activeness, rewardList, cb)
        XNetwork.Call("GetNewPlayerRewardRequest", { Activeness = activeness }, function(response)
            cb = cb or function() end
            if response.Code == XCode.Success then
                XUiManager.OpenUiObtain(rewardList, CS.XTextManager.GetText("DailyActiveRewardTitle"))
                XTaskManager.UpdateNewbieActivenessRecord(activeness)
                cb()
                XEventManager.DispatchEvent(XEventId.EVENT_NEWBIETASK_PROGRESSCHANGED)
            else
                XUiManager.TipCode(response.Code)
            end
        end)
    end

    function XTaskManager.GetDormTaskDailyListData()
        return XTaskManager.SortDormDailyTaskByGroup(XTaskManager.GetDormDailyTaskList()) or {}
    end

    function XTaskManager.GetDormTaskStoryListData()
        return XTaskManager.SortDormStoryTaskByGroup(XTaskManager.GetDormNormalTaskList()) or {}
    end

    -- v1.31 【宿舍】获取带一键领取任务数据-日常
    function XTaskManager.GetDormDailyTasksAllReceiveData()
        local result = {}
        -- 有任务可领取时添加一键领取数据
        if XTaskManager.GetIsRewardForEx(XTaskManager.TaskType.DormDaily) then
            result = XTaskManager.GetAchieveTaskByRecursion(XTaskManager.GetDormTaskDailyListData(), XTaskManager.TaskType.DormDaily, XTaskManager.GetDormTaskDailyListData)
        else
            result = XTaskManager.GetDormTaskDailyListData()
        end
        return result
    end

    -- v1.31 【宿舍】获取带一键领取任务数据-剧情
    function XTaskManager.GetDormStoryTasksAllReceiveData()
        local result = {}
        -- 有任务可领取时添加一键领取数据
        if XTaskManager.GetIsRewardForEx(XTaskManager.TaskType.DormNormal) then
            result = XTaskManager.GetAchieveTaskByRecursion(XTaskManager.GetDormTaskStoryListData(), XTaskManager.TaskType.DormNormal, XTaskManager.GetDormTaskStoryListData)
        else
            result = XTaskManager.GetDormTaskStoryListData()
        end
        return result
    end

    -- v1.31 【任务】处理可完成任务taskID
    function XTaskManager.GetAchieveTask(tasksData)
        local result = {}
        for _, task in ipairs(tasksData) do
            if task.State == XTaskManager.TaskState.Achieved then
                table.insert(result, task.Id)
            end
        end
        return result
    end

    -- v1.31 【任务】递归思路添加多级任务添加一键领取数据
    function XTaskManager.GetAchieveTaskByRecursion(tasksData, taskType, getNewTasksCB)
        local result = {}
        -- 领取奖励table
        local GoodsList = {}
        -- 前向引用定义
        local cb
        local first = function ()
            XDataCenter.TaskManager.FinishMultiTaskRequest(XTaskManager.GetAchieveTask(getNewTasksCB()), function(rewardGoodsList)
                for _, goods in ipairs(rewardGoodsList) do
                    table.insert(GoodsList, goods)
                end
                -- 刷新数据后判断是否有可领取的多级任务，有则递归调用
                if XTaskManager.GetIsRewardForEx(taskType) then
                    cb()
                else
                    local horizontalNormalizedPosition = 0
                    XUiManager.OpenUiObtain(GoodsList, nil, nil, nil, horizontalNormalizedPosition)
                end
            end)
        end
        -- 递归方法引用
        cb = first
        result = XTaskManager.AddReceiveData(tasksData, first)
        return result
    end

    -- v1.31 【任务】添加一键领取数据
    function XTaskManager.AddReceiveData(tasksData, receiveCb)
        local result = {}
        local receiveAllData = {ReceiveAll = true, AllAchieveTaskDatas = {}, ReceiveCb = nil}
        if receiveCb then
            receiveAllData.ReceiveCb = receiveCb
        end

        result[1] = receiveAllData
        for index, task in ipairs(tasksData) do
            table.insert(result, index + 1, task)
            if task.State == XTaskManager.TaskState.Achieved then
                table.insert(receiveAllData.AllAchieveTaskDatas, task.Id)
            end
        end
        return result
    end

    function XTaskManager.SortDormStoryTaskByGroup(tasks)
        local currTaskGroupId = XDataCenter.TaskManager.GetCurrentDormStoryTaskGroupId()
        if currTaskGroupId == nil or currTaskGroupId <= 0 then return tasks end
        return XTaskManager.SortDormTask(tasks, currTaskGroupId)
    end

    function XTaskManager.SortDormDailyTaskByGroup(tasks)
        local currTaskGroupId = XDataCenter.TaskManager.GetCurrentDormDailyTaskGroupId()
        if currTaskGroupId == nil or currTaskGroupId <= 0 then return tasks end
        return XTaskManager.SortDormTask(tasks, currTaskGroupId)
    end

    function XTaskManager.SortDormTask(tasks, currTaskGroupId)
        local sortedTasks = {}
        -- 过滤，留下组id相同，没有组id的任务
        for _, v in pairs(tasks) do
            local templates = XDataCenter.TaskManager.GetTaskTemplate(v.Id)
            if templates.GroupId <= 0 or templates.GroupId == currTaskGroupId then

                v.SortWeight = 1
                v.SortWeight = (templates.GroupId > 0) and 2 or v.SortWeight
                v.SortWeight = (v.State == XDataCenter.TaskManager.TaskState.Achieved) and 3 or v.SortWeight
                v.SortWeight = (templates.GroupTheme == 1) and 4 or v.SortWeight
                v.GroupTheme = templates.GroupTheme
                tableInsert(sortedTasks, v)
            end
        end

        -- 排序，主题任务，可领取的任务，不能领取的任务
        tableSort(sortedTasks, function(taskA, taskB)
            local templatesTaskA = XDataCenter.TaskManager.GetTaskTemplate(taskA.Id)
            local templatesTaskB = XDataCenter.TaskManager.GetTaskTemplate(taskB.Id)
            if taskA.SortWeight == taskB.SortWeight then
                return templatesTaskA.Priority > templatesTaskB.Priority
            end
            return taskA.SortWeight > taskB.SortWeight
        end)

        return sortedTasks
    end

    --宿舍主界面，任务提示。（可领奖励或未完成的）
    function XTaskManager.GetDormTaskTips()
        local storytasks = XTaskManager.GetDormTaskStoryListData()
        local taskguideids = XDormConfig.GetDormitoryGuideTaskCfg()
        if _G.next(storytasks) then
            for _, data in pairs(storytasks) do
                if data.State == XTaskManager.TaskState.Achieved and taskguideids[data.Id] then
                    return data, XTaskManager.TaskType.DormNormal, XTaskManager.TaskState.Achieved
                end
            end
        end

        if _G.next(storytasks) then
            for _, data in pairs(storytasks) do
                if data.State ~= XTaskManager.TaskState.Achieved and data.State ~= XTaskManager.TaskState.Finish and taskguideids[data.Id] and data.GroupTheme ~= 1 then
                    return data, XTaskManager.TaskType.DormNormal, XTaskManager.TaskState.Standby
                end
            end
        end

        local dailytasks = XTaskManager.GetDormDailyTaskList() or {}
        if _G.next(dailytasks) then
            for _, data in pairs(dailytasks) do
                if data.State == XTaskManager.TaskState.Achieved then
                    return data, XTaskManager.TaskType.DormDaily, XTaskManager.TaskState.Achieved
                end
            end
        end

        if _G.next(dailytasks) then
            for _, data in pairs(dailytasks) do
                if data.State ~= XTaskManager.TaskState.Achieved and data.State ~= XTaskManager.TaskState.Finish then
                    return data, XTaskManager.TaskType.DormDaily, XTaskManager.TaskState.Standby
                end
            end
        end
    end

    -- 获取每周任务刷新时间
    function XTaskManager.GetWeeklyTaskRefreshTime()
        return WeekTaskRefreshDay, WeekTaskEpochTime
    end

    -- 检查任务是否特定时间刷新（每日/每周）
    function XTaskManager.CheckTaskRefreshable(taskId)
        local config = XTaskManager.GetTaskTemplate(taskId)
        if not config then return false end


        local taskType = config.Type
        if taskType == XTaskManager.TaskType.Daily then
            return true
        end

        if taskType == XTaskManager.TaskType.Weekly then
            return true
        end

        if taskType == XTaskManager.TaskType.TimeLimit then
            return XTaskConfig.GetTimeLimitWeeklyTasksCheckTable()[taskId]
        end

        return false
    end
    --============
    --获取兵法蓝图玩法是否有未领取奖励的任务
    --============
    function XTaskManager.GetRpgTowerHaveAchievedTask()
        local haveTask = false
        for _, task in pairs(RpgTowerTaskData) do
            if task.State == XTaskManager.TaskState.Achieved then
                haveTask = true
                break
            end
        end
        return haveTask
    end
    --============
    --获取白色情人节玩法是否有未领取奖励的任务
    --============
    function XTaskManager.GetWhiteValentineHaveAchievedTask()
        local haveTask = false
        for _, task in pairs(WhiteValentineTaskData) do
            if task.State == XTaskManager.TaskState.Achieved then
                haveTask = true
                break
            end
        end
        return haveTask
    end
    --============
    --获取猜拳玩法是否有未领取奖励的任务
    --============
    function XTaskManager.GetFingerGuessingHaveAchievedTask()
        local haveTask = false
        for _, task in pairs(FingerGuessingTaskData) do
            if task.State == XTaskManager.TaskState.Achieved then
                haveTask = true
                break
            end
        end
        return haveTask
    end
    --============
    --获取猜拳玩法已完成任务和任务总数
    --============
    function XTaskManager.GetFingerGuessingTaskNum()
        local total = 0
        local achived = 0
        for _, task in pairs(FingerGuessingTaskData) do
            total = total + 1
            if task.State == XTaskManager.TaskState.Achieved or task.State == XTaskManager.TaskState.Finish then
                achived = achived + 1
            end
        end
        return achived, total
    end
    -- 判断累积消费活动是否有未领取奖励任务
    XTaskManager.ConsumeRewardTaskIds = {[39301] = 39301, [39302] = 39302, [39303] = 39303, [39304] = 39304, [39305] = 39305, [39306] = 39306, [39307] = 39307 } -- 累消任务ID
    function XTaskManager.CheckConsumeTaskHaveReward()
        local haveReward = false
        for _, task in pairs(TimeLimitTaskData) do
            if XTaskManager.ConsumeRewardTaskIds[task.Id] and task.State == XTaskManager.TaskState.Achieved then
                haveReward = true
                break
            end
        end
        return haveReward
    end

    --回归活动任务相关------------------------------------------------------------------------>>>
    function XTaskManager.GetRegressionTaskRedPointCount()
        return RegressionTaskRedPointCount
    end

    function XTaskManager.GetRegressionTaskTypeToRedPointCount(type)
        return RegressionTaskTypeToRedPointCountDic[type] or 0
    end

    --获取链接公告任务开启的时间戳
    function XTaskManager.GetLinkTimeTaskOpenTime(id)
        return LinkTaskTimeDict[id]
    end

    function XTaskManager.GetRegressionTaskByType(type)
        local activityId = XDataCenter.RegressionManager.GetTaskActivityId()
        if not XTool.IsNumberValid(activityId) then
            return
        end
        local groupId = XRegressionConfigs.GetTaskGroupIdByActivityId(activityId)
        local taskIdList = XRegressionConfigs.GetTaskIdListByIdAndType(groupId, type)
        local taskList
        if taskIdList then
            taskList = {}
            local oneTaskData
            for _, id in ipairs(taskIdList) do
                oneTaskData = RegressionTaskData[id]
                if oneTaskData then
                    tableInsert(taskList, oneTaskData)
                end
            end
            return GetTaskList(taskList)
        end
    end

    -- 对任务数据进行排序
    function XTaskManager.SortTaskList(taskList)
        local taskTemplate = XTaskConfig.GetTaskTemplate()
        tableSort(taskList, function(a, b)
            local pa, pb = taskTemplate[a.Id].Priority, taskTemplate[b.Id].Priority
            local stateA = a.State or TotalTaskData[a.Id].State
            local stateB = b.State or TotalTaskData[b.Id].State
            local compareResult = CompareState(stateA, stateB)
            if compareResult == 0 then
                if pa ~= pb then
                    return pa > pb
                else
                    return a.Id > b.Id
                end
            else
                return compareResult > 0
            end
        end)
    end

    function XTaskManager.GetTaskByTypeAndGroup(taskType, groupId)
        local taskList = XTaskManager.GetTaskDataByTaskType(taskType)
        local result = {}
        for id, data in pairs(taskList) do
            if XTaskConfig.GetTaskGroupId(id) == groupId then
                result[#result + 1] = data
            end
        end
        XTaskManager.SortTaskList(result)
        return result
    end

    function XTaskManager.GetTimeLimitTaskByGroupId(groupId)
        local taskList = TimeLimitTaskData
        local result = {}
        for id, data in pairs(taskList) do
            if XTaskConfig.GetTaskGroupId(id) == groupId then
                result[#result + 1] = data
            end
        end
        XTaskManager.SortTaskList(result)
        return result
    end

    function XTaskManager.CheckAchievedTaskByTypeAndGroup(taskType, groupId)
        local taskDatas = XTaskManager.GetTaskByTypeAndGroup(taskType, groupId)
        for i, taskData in pairs(taskDatas) do
            if taskData.State == XTaskManager.TaskState.Achieved then
                return true
            end
        end
        return false
    end

    XTaskManager.Init()
    return XTaskManager
end

--玩法登录下发
XRpc.NotifyTask = function(data)
    XDataCenter.TaskManager.SyncTasks(data)
end

--登录下发
XRpc.NotifyTaskData = function(data)
    XDataCenter.TaskManager.InitTaskData(data.TaskData)
    XDataCenter.NewbieTaskManager.InitTaskData(data.TaskData)
    XDataCenter.ActivityManager.SetBackFlowEndTime(data.TaskData)
end