--===========================
--公会战活动管理器
--模块负责：吕天元 陈思亮 张爽
--===========================
XGuildWarManagerCreator = function()
    --===================================
    --DEBUG相关
    --===================================
    local DEBUG = true
    local _printDebug = function(...)
        if not DEBUG then return end
        XLog.Debug(...)
    end
    -------------------------------------
    -------------------------------------
    local XGuildWarManager = {}
    local Config = XGuildWarConfig
    local InitialManagers = false
    local LeaderManager
    local BattleManagers = {}
    -------------------------------------
    --活动参数
    -------------------------------------
    local ActivityId = 0
    local CurrentRoundId = 1
    local ActivityName = ""
    local ActivityTimeId = 0
    local RoundTimeId = 0
    local ActionPoint = 0
    local RoundDatas = {}
    local PopupRecord
    local NeedPopup
    local SpecialRoleList
    --主要特攻角色
    local MainSpecialRoleId
    --难度通关记录
    local DifficultyPassRecord
    --公会战总任务信息列表
    local GuildWarTaskList
    --公会战真任务TaskId -》 TaskData检索字典
    local GuildWarTaskByTaskIdDic
    --任务缓存，只有临时任务数据
    local CompleteTaskId
    --表示所有轮次结束的标记(用于标记最后一轮战斗结束到活动关闭期间)
    local AllRoundFinishFlag
    --新一轮开始标记(用于弹出界面)
    local NewRoundFlag = false
    --===============
    --公会战 协议名
    --===============
    local METHOD_NAME = {
        GetActivityData = "GuildWarGetActivityDataRequest", --主动请求活动信息
        EditPlan = "GuildWarEditLineRequest", --
        RequestRanking = "GuildWarOpenRankRequest", --
        SelectDifficult = "GuildWarSelectDifficultyRequest", --选择难度
        ConfirmFight = "GuildWarConfirmFightResultRequest", --确认关卡结果
        StageSweep = "GuildWarSweepRequest", --
        PopUp = "GuildWarPopupRequest", --弹窗请求
        PopupActionID = "GuildWarPopupActionRequest", --行动播放进度保存请求
        PlayerMove = "GuildWarMoveRequest", -- 玩家移动
    }

    local function InitActivityCfg(cfg)
        ActivityId = cfg.Id
        ActivityName = cfg.Name
        ActivityTimeId = cfg.TimeId
    end

    local function CheckIsGuildMaster()
        return XDataCenter.GuildManager.IsGuildLeader()
    end
    local InitListenerFlag
    local function AddInitListener()
        if InitListenerFlag then return end
        XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, XGuildWarManager.SyncTasks)
        InitListenerFlag = true
    end

    local function RemoveInitListener()
        if not InitListenerFlag then return end
        XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, XGuildWarManager.SyncTasks)
        InitListenerFlag = false
    end
    --===============
    --初始化
    --===============
    function XGuildWarManager.Init()
        if XGuildWarConfig.CLOSE_DEBUG then return end
        local cfg = Config.GetCurrentActivity()
        if cfg then
            InitActivityCfg(cfg)
        end
        CurrentRoundId = 1
        RoundTimeId = 0
        ActionPoint = 0
        RoundDatas = {}
        SpecialRoleList = nil
        MainSpecialRoleId = nil
        PopupRecord = nil
        GuildWarTaskList = nil
        GuildWarTaskByTaskIdDic = nil
        NewRoundFlag = false
        CompleteTaskId = {}
        NeedPopup = {}
        DifficultyPassRecord = {}
        RemoveInitListener()
        AddInitListener()
    end
    --===============
    --创建战斗管理器
    --===============
    local function CreateRound(roundId)
        local manager = require("XEntity/XGuildWar/Round/XGuildWarRound")
        return manager.New(roundId)
    end
    --================
    --处理登陆活动数据通知
    --================
    function XGuildWarManager.OnNotifyActivityData(data)
        local cfg = Config.GetCfgByIdKey(
            Config.TableKey.Activity,
            data.ActivityNo
        )
        InitActivityCfg(cfg)
        PopupRecord = data.PopupRecord and data.PopupRecord.SettleDatas or {}
        local activityData = data.ActivityData
        XGuildWarManager.RefreshActivityData(activityData)
        XGuildWarManager.RefreshMyRoundData(data.MyRoundData)
        XGuildWarManager.RefreshFightRecords(data.FightRecords)
        XGuildWarManager.RefreshLastActionIdDic(data.ActionPlayed)
    end
    --================
    --处理公会活动数据刷新
    --================
    function XGuildWarManager.RefreshActivityData(activityData)
        if not activityData then
            return
        end
        --先取出当前RoundId
        local preRoundId = CurrentRoundId or 0
        --是否是新的一轮
        NewRoundFlag = false
        CurrentRoundId = activityData.CurRoundId
        AllRoundFinishFlag = false
        --CurrentRoundId是0时表示活动还没开始或休战期
        if not CurrentRoundId or (CurrentRoundId == 0) then
            --RestRoundId为表示当前轮次(涵盖轮次期间和后面的休战期)的Id
            --在第一轮开始之前，活动结束后这个值为0
            local subRoundId = activityData.RestRoundId
            if subRoundId and subRoundId > 0 then
                CurrentRoundId = subRoundId
            else
                for roundId = Config.ROUND_NUM, 1, -1 do
                    local roundCfg = Config.GetCfgByIdKey(
                        Config.TableKey.Round,
                        roundId
                    )
                    local timeId = roundCfg.TimeId
                    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
                    local now = XTime.GetServerNowTimestamp()
                    if now >= endTime then
                        --从最后一轮开始算，活动时间内，当前时间大于轮次结束时间，表示是处于当轮休战期
                        CurrentRoundId = roundId
                        if roundId == Config.ROUND_NUM then
                            AllRoundFinishFlag = true
                        end
                        return
                    elseif roundId == 1 and now >= XGuildWarManager.GetActivityStartTime() then
                        --活动时间内，CurrentRoundId为0且不是休战期或活动结束，那么则是开始活动期间
                        --默认取第一轮数据
                        CurrentRoundId = 1
                    end
                end
                local lastRoundCfg = Config.GetCfgByIdKey(
                    Config.TableKey.Round,
                    Config.ROUND_NUM
                )
                local timeId = lastRoundCfg.TimeId
                local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
                local now = XTime.GetServerNowTimestamp()
                if now >= endTime then
                    --活动时间内，当前时间大于最后一轮结束时间，表示是结束活动期间
                    --默认取最后一轮数据
                    CurrentRoundId = Config.ROUND_NUM
                    AllRoundFinishFlag = true
                elseif now >= XGuildWarManager.GetActivityStartTime() then
                    --活动时间内，CurrentRoundId为0且不是活动结束，那么则是开始活动期间
                    --默认取第一轮数据
                    CurrentRoundId = 1
                else
                    --不在活动期间，返回
                    return
                end
            end
        end
        --对比更新后的RoundId，取得是否是新一轮
        NewRoundFlag = (CurrentRoundId > preRoundId)
        local roundConfig = Config.GetCfgByIdKey(
            Config.TableKey.Round,
            CurrentRoundId,
            true
        )
        RoundTimeId = roundConfig and roundConfig.TimeId
        if activityData then
            for _, roundData in ipairs(activityData.RoundData) do
                local round = XGuildWarManager.GetRoundByRoundId(roundData.RoundId)
                if round then
                    round:RefreshRoundData(roundData)
                end
            end
            local battleManager = XGuildWarManager.GetBattleManager()
            if battleManager then --活动开启前battleManager会为空
                battleManager:SetActionList(activityData.ActionList)
            end
            for _, settleData in pairs(activityData.SettleDatas or {}) do
                if settleData.IsPass == 1 then
                    DifficultyPassRecord[settleData.DifficultyId] = true
                end
                local round = XGuildWarManager.GetRoundByRoundId(settleData.RoundId)
                if round then
                    round:SetSettleData(settleData)
                end
            end
        end
        --先重置缓存的完成任务情况
        CompleteTaskId = {}
        for _, taskId in pairs(activityData.CompleteTaskId or {}) do
            if not CompleteTaskId[taskId] then
                CompleteTaskId[taskId] = true
            end
        end
        XGuildWarManager.RefreshGuildWarTaskList()
        --如果是新的一轮，发出通知
        if NewRoundFlag then
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_NEW_ROUND)
        end
    end
    --================
    --获取新一轮开始标记
    --该标记在获取后会设置回False
    --================
    function XGuildWarManager.GetNewRoundFlag()
        local flag = NewRoundFlag
        NewRoundFlag = false
        return flag
    end
    --================
    --处理玩家活动数据刷新
    --================
    function XGuildWarManager.RefreshMyRoundData(myRoundData)
        if myRoundData then
            for _, myData in ipairs(myRoundData) do
                local round = XGuildWarManager.GetRoundByRoundId(myData.RoundId)
                if round then
                    round:UpdateMyRoundData(myData)
                end
                :: goNext ::
            end
        end
    end
    --================
    --处理战斗数据刷新
    --================
    function XGuildWarManager.RefreshFightRecords(fightRecords)
        if fightRecords then
            local round = XGuildWarManager.GetCurrentRound()
            if round then
                round:UpdateFightRecords(fightRecords)
            end
        end
    end
    --================
    --处理最后的ActionId刷新
    --================
    function XGuildWarManager.RefreshLastActionIdDic(actionIdList)
        if actionIdList then
            local round = XGuildWarManager.GetCurrentRound()
            if round then
                round:UpdateLastActionIdDic(actionIdList)
            end
        end
    end
    --================
    --用轮次Id获取轮次对象
    --@param roundId:轮次Id
    --若roundId为nil或为0会返回空
    --================
    function XGuildWarManager.GetRoundByRoundId(roundId)
        if not roundId or (roundId == 0) then return nil end
        if not RoundDatas[roundId] then
            RoundDatas[roundId] = CreateRound(roundId)
        end
        return RoundDatas[roundId]
    end

    function XGuildWarManager.GetCurrentRound()
        return XGuildWarManager.GetRoundByRoundId(CurrentRoundId)
    end

    function XGuildWarManager.GetPopupRecord()
        if not PopupRecord then
            return nil
        end
        local record = PopupRecord
        PopupRecord = nil
        return record
    end
    --===============
    --初始化管理器
    --===============
    function XGuildWarManager.InitManagers()
        if InitialManagers then return end
        InitialManagers = true
    end
    -------------------------------------------------------
    --
    -------------------------------------------------------
    --===============
    --获取给定配置的活动Id(XGuildWarActivityManager的Id)
    --若配置为空，则返回0
    --===============
    function XGuildWarManager.GetActivityId()
        return ActivityId or 0
    end
    --===============
    --获取当前配置的活动名称(XGuildWarActivityManager的Name)
    --若配置为空，则返回字符串"UnNamed"
    --===============
    function XGuildWarManager.GetName()
        return ActivityName or "UnNamed"
    end
    --===============
    --获取当前轮次
    --若配置为空，则返回1
    --===============
    function XGuildWarManager.GetCurrentRoundId()
        return CurrentRoundId or 1
    end
    ---------------------------------------
    ---------------------------------------
    --会长相关
    ---------------------------------------
    ---------------------------------------

    --================
    --请求：选择难度
    --@param nodeList: --路线，节点ID列表
    --@param cb: function 回调
    --================
    function XGuildWarManager.EditPlan(nodeList, cb)
        if not CheckIsGuildMaster() then
            XUiManager.TipMsg(XUiHelper.GetText("GuildWarNotGuildMaster"))
            return
        end
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.EditPlan, {AttackPlan = nodeList}, function(res)
                local battleManager = XGuildWarManager.GetBattleManager()
                battleManager:UpdateNodePathIndex(nodeList)
                if cb then
                    cb()
                end
            end)
    end
    ---------------------------------------
    ---------------------------------------
    --活动，轮次时间相关
    ---------------------------------------
    ---------------------------------------
    --===============
    --获取给定配置的活动TimeId
    --若配置为空，则返回0
    --===============
    function XGuildWarManager.GetActvityTimeId()
        return ActivityTimeId or 0
    end
    --===============
    --获取当前轮次的TimeId
    --若为空，则返回0
    --===============
    function XGuildWarManager.GetRoundTimeId()
        return RoundTimeId or 0
    end
    --===============
    --检查当前活动是否在开放时间内
    --===============
    function XGuildWarManager.CheckActivityIsInTime()
        if XGuildWarConfig.CLOSE_DEBUG then return false end
        local now = XTime.GetServerNowTimestamp()
        return (now >= XGuildWarManager.GetActivityStartTime())
        and (now < XGuildWarManager.GetActivityEndTime())
    end
    --===============
    --获取当前活动开始时间戳(根据TimeId)
    --===============
    function XGuildWarManager.GetActivityStartTime()
        if XGuildWarConfig.CLOSE_DEBUG then return 0 end
        return XFunctionManager.GetStartTimeByTimeId(ActivityTimeId)
    end
    --===============
    --获取当前活动结束时间戳(根据TimeId)
    --===============
    function XGuildWarManager.GetActivityEndTime()
        if XGuildWarConfig.CLOSE_DEBUG then return 0 end
        return XFunctionManager.GetEndTimeByTimeId(ActivityTimeId)
    end
    --===============
    --获取当前活动剩余时间(秒)
    --===============
    function XGuildWarManager.GetActivityLeftTime()
        local now = XTime.GetServerNowTimestamp()
        local endTime = XGuildWarManager.GetActivityEndTime()
        local leftTime = endTime - now
        return leftTime
    end
    --===============
    --检查当前轮次是否在开放时间内
    --===============
    function XGuildWarManager.CheckRoundIsInTime()
        if XGuildWarConfig.CLOSE_DEBUG then return false end
        local now = XTime.GetServerNowTimestamp()
        return (now >= XGuildWarManager.GetRoundStartTime())
        and (now < XGuildWarManager.GetRoundEndTime())
    end
    --===============
    --获取当前轮次开始时间戳(根据TimeId)
    --===============
    function XGuildWarManager.GetRoundStartTime()
        return XFunctionManager.GetStartTimeByTimeId(RoundTimeId)
    end
    --===============
    --获取当前轮次结束时间戳(根据TimeId)
    --===============
    function XGuildWarManager.GetRoundEndTime()
        return XFunctionManager.GetEndTimeByTimeId(RoundTimeId)
    end
    --===============
    --获取当前轮次剩余时间(秒)
    --===============
    function XGuildWarManager.GetRoundLeftTime()
        local now = XTime.GetServerNowTimestamp()
        local endTime = XGuildWarManager.GetRoundEndTime()
        local leftTime = endTime - now
        return leftTime
    end
    --=========================
    --获取服务器下一次关卡刷新时间的时间戳
    --=========================
    function XGuildWarManager.GetNextMapRefreshTime()
        local oclock = Config.GetClientConfigValues("DayRefreshTime", "Float")[1]
        return XTime.GetServerNextTargetTime(oclock)
    end
    --=========================
    --获取固定时长刷新的时间间隔
    --=========================
    function XGuildWarManager.GetHourRefreshTime()
        local time = Config.GetClientConfigValues("HourRefreshTime", "Float")[1]
        return time
    end
    --=========================
    --获取最大目标节点数
    --=========================
    function XGuildWarManager.GetPathMarkMaxCount()
        local time = Config.GetClientConfigValues("PathMarkMaxCount", "Float")[1]
        return time
    end
    --================
    --检查是否能进入玩法
    --@return1 :是否在活动时间内(true为在活动时间内)
    --@return2 :是否未开始活动(true为未开始活动)
    --================
    function XGuildWarManager.CheckActivityCanGoTo()
        if XGuildWarConfig.CLOSE_DEBUG then return false end
        local isActivityEnd, notStart = XGuildWarManager.CheckActivityIsEnd()
        return not isActivityEnd, notStart
    end
    --================
    --检查玩法是否关闭(用于判断玩法入口，进入活动条件等)
    --@return1 :玩法是否关闭
    --@return2 :是否活动未开启
    --================
    function XGuildWarManager.CheckActivityIsEnd()
        local timeNow = XTime.GetServerNowTimestamp()
        local startTime = XGuildWarManager.GetActivityStartTime()
        local endTime = XGuildWarManager.GetActivityEndTime()
        local isEnd = timeNow >= endTime
        local isStart = timeNow >= startTime
        local inActivity = (not isEnd) and (isStart)
        return not inActivity, timeNow < startTime
    end
    --=============
    --检查本轮公会是否已经选择难度
    --=============
    function XGuildWarManager.CheckHaveDifficultySelected()
        local battleManager = XGuildWarManager.GetBattleManager()
        local mydata = battleManager:GetCurrentMyRoundData()
        if not mydata or (not next(mydata)) then return false end
        return mydata.DifficultyId > 0
    end
    --=============
    --检查是否公会跳过轮
    --=============
    function XGuildWarManager.CheckIsGuildSkipRound(roundId)
        local round = XGuildWarManager.GetRoundByRoundId(roundId or CurrentRoundId)
        return round and round:CheckIsSkipRound()
    end
    --=============
    --检查是否玩家跳过轮
    --=============
    function XGuildWarManager.CheckIsPlayerSkipRound(roundId)
        local round = XGuildWarManager.GetRoundByRoundId(roundId or CurrentRoundId)
        return round and round:CheckIsMySkipRound()
    end
    --=============
    --根据轮次Id检查是否跳过轮
    --=============
    function XGuildWarManager.CheckIsSkipRound(roundId)
        return XGuildWarManager.CheckIsGuildSkipRound(roundId)
        or XGuildWarManager.CheckIsPlayerSkipRound(roundId)
    end
    --=============
    --检查当前轮是否跳过轮
    --=============
    function XGuildWarManager.CheckIsSkipCurrentRound()
        return XGuildWarManager.CheckIsGuildSkipRound()
        or XGuildWarManager.CheckIsPlayerSkipRound()
    end
    --=============
    --检查当轮是否能进入地图
    --=============
    function XGuildWarManager.CheckCanEnterMain()
        --检查轮数是否开始
        local isInRound = XGuildWarManager.CheckRoundIsInTime()
        if not isInRound then return false end
        --第二步检查跳过情况
        local isSkip = XGuildWarManager.CheckIsSkipRound()
        if isSkip then return false end
        --第三步检查是否选择了难度
        local isSelectDifficulty = XGuildWarManager.CheckHaveDifficultySelected()
        if not isSelectDifficulty then return false end
    end

    function XGuildWarManager.CheckIsInGuildByRound(roundId)
        if roundId == 0 then return true end --全局任务默认在公会
        local round = XGuildWarManager.GetRoundByRoundId(roundId)
        if not round then return false end
        local isChange = round:CheckIsChangeGuild()
        return not isChange
    end
    --===============
    --获取到下一轮的开放时间
    --若已经没有下一轮，返回nil
    --===============
    function XGuildWarManager.GetNextRoundTime()
        local now = XTime.GetServerNowTimestamp()
        local startTime = XGuildWarManager.GetRoundStartTime()
        --检查是否是第一轮未开始
        if CurrentRoundId == 1 and now < startTime then
            return XUiHelper.GetTime(startTime - now, XUiHelper.TimeFormatType.ACTIVITY)
        elseif CurrentRoundId == Config.ROUND_NUM then
            return nil
        else
            local nextRoundCfg = Config.GetCfgByIdKey(
                Config.TableKey.Round,
                CurrentRoundId + 1
            )
            local nextStartTime = XFunctionManager.GetStartTimeByTimeId(nextRoundCfg.TimeId)
            return XUiHelper.GetTime(nextStartTime - now, XUiHelper.TimeFormatType.ACTIVITY)
        end
    end
    --================
    --获取上一轮轮次控件
    --若这是第一轮，则返回nil
    --================
    function XGuildWarManager.GetPreRound()
        if not CurrentRoundId or (CurrentRoundId <= 1) then
            return nil
        end
        return XGuildWarManager.GetRoundByRoundId(CurrentRoundId - 1)
    end
    --------------------------------------------------------
    --------------------------------------------------------
    --难度选择相关
    --------------------------------------------------------
    --------------------------------------------------------
    --================
    --获取难度数据列表
    --================
    function XGuildWarManager.GetDifficultyDataList()
        local cfgs = Config.GetAllConfigs(Config.TableKey.Difficulty)
        local datas = {}
        for id, cfg in pairs(cfgs or {}) do
            local data = {
                Id = id,
                Name = cfg.Name,
                RecommendActive = cfg.RecommendActive,
                FightEventIds = cfg.FightEventIds,
                PreId = cfg.PreId or 0,
                BgPath = cfg.BgPath,
                LockText = cfg.LockText or "",
            }
            datas[id] = data
        end
        return datas
    end
    --================
    --检查难度是否已通关
    --================
    function XGuildWarManager.CheckDifficultyIsPass(difficultyId)
        if difficultyId == 0 then return true end
        return difficultyId and DifficultyPassRecord[difficultyId]
    end
    --================
    --获取本期上一次通关的难度
    --若是第一轮，返回难度1
    --================
    function XGuildWarManager.GetDifficultyPreSelected()
        if CurrentRoundId == 1 then return 1 end
        for i = CurrentRoundId - 1, 1, -1 do
            local round = XGuildWarManager.GetRoundByRoundId(i)
            local battleManager = round and round:GetBattleManager()
            if battleManager and battleManager:CheckAllInfectIsDead() then
                return round:GetDifficulty()
            end
        end
        return 1
    end
    --================
    --获取难度名称
    --若传入参数为空，则返回空字符串""
    --================
    function XGuildWarManager.GetDifficultyName(difficultyId)
        local cfg = Config.GetCfgByIdKey(
            Config.TableKey.Difficulty,
            difficultyId,
            true
        )
        return cfg and cfg.Name or ""
    end
    --================
    --获取结算奖励Id
    --@isPass 是否通过
    --================
    function XGuildWarManager.GetRoundSettleReward(difficultyId, isPass)
        local rewardId = 0
        local cfg = Config.GetCfgByIdKey(
            Config.TableKey.Difficulty,
            difficultyId,
            true
        )
        if not cfg then return 0 end
        if isPass == 1 then
            rewardId = cfg and cfg.PassRewardId
        else
            rewardId = cfg and cfg.UnPassRewardId
        end
        return rewardId
    end
    --================
    --请求：选择难度
    --@param cb: function 回调
    --================
    function XGuildWarManager.SelectDifficulty(difficulty, cb)
        if not CheckIsGuildMaster() then
            XLog.Debug(XUiHelper.GetText("GuildWarNotGuildMaster"))
            return
        end
        local preActive = 0
        if CurrentRoundId > 1 then
            local preRound = XGuildWarManager.GetRoundByRoundId(CurrentRoundId - 1)
            if not preRound:CheckIsSkipRound() then
                preActive = preRound:GetTotalActivation()
            end
        end
        local confirmCb = function()
            XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.SelectDifficult, {DifficultyId = difficulty}, function(res)
                    if cb then
                        cb()
                    end
                end)
        end
        local difficultyCfg = Config.GetCfgByIdKey(
            Config.TableKey.Difficulty,
            difficulty
        )
        local tipTitle = XUiHelper.GetText("GuildWarSelectDifficultyConfirmTitle")
        local recommend = difficultyCfg.RecommendActive
        --比较推荐值与上一轮的活跃度的大小，获取对应文本
        local tipText = ((recommend > preActive) and XUiHelper.GetText("GWSelectDifficultyConfirmContentNotRecommend", difficultyCfg.RecommendActive, preActive))
        or (XUiHelper.GetText("GWSelectDifficultyConfirmContentRecommend", difficultyCfg.RecommendActive, preActive))
        local content = tipText
        XLuaUiManager.Open("UiDialog", tipTitle, content, XUiManager.DialogType.Normal, nil, confirmCb)
    end
    --------------------------------------------------------
    --------------------------------------------------------
    --任务相关
    --------------------------------------------------------
    --------------------------------------------------------
    --===============
    --初始化任务数据
    --===============
    function XGuildWarManager.InitGuildWarTaskList()
        local TaskManager = XDataCenter.TaskManager
        GuildWarTaskList = {}
        GuildWarTaskByTaskIdDic = {}
        local taskCfgs = Config.GetAllConfigs(Config.TableKey.Task)
        --获取所有真任务数据
        local taskDatas = TaskManager.GetTaskList(TaskManager.TaskType.GuildWar)
        --构筑临时检索用字典
        local taskDataDic = {}
        for _, taskData in pairs(taskDatas) do
            taskDataDic[taskData.Id] = taskData
        end
        for id, cfg in pairs(taskCfgs) do
            local roundId = cfg.RoundId or 0
            if not GuildWarTaskList[roundId] then
                GuildWarTaskList[roundId] = {}
            end
            local roundList = GuildWarTaskList[roundId]
            local difficultyId = cfg.DifficultyId or 0
            if not roundList[difficultyId] then
                roundList[difficultyId] = {}
            end

            if cfg.SubType == XGuildWarConfig.SubTaskType.Real then
                --真任务,任务数据从TaskManager走通常任务逻辑，构造专用数据
                local originTaskData = taskDataDic[cfg.TaskId]
                local resultTaskData = originTaskData and XTool.Clone(originTaskData) or {}
                resultTaskData.TaskType = cfg.SubType
                resultTaskData.GuildWarTaskId = cfg.Id
                resultTaskData.RoundId = roundId
                --真任务需要任务Id走通用逻辑
                resultTaskData.Id = cfg.TaskId
                if originTaskData then
                    resultTaskData.SortWeight = (resultTaskData.State == XDataCenter.TaskManager.TaskState.Finish and 2)
                    or (resultTaskData.State == XDataCenter.TaskManager.TaskState.Achieved and 0) or 1
                else
                    --没有数据也要构筑一个空的占位
                    resultTaskData.Schedule = { [1] = { Id = cfg.TaskId, Value = 0 }}
                    resultTaskData.State = XDataCenter.TaskManager.TaskState.Accepted
                    resultTaskData.SortWeight = 1
                end
                table.insert(roundList[difficultyId], resultTaskData)
                GuildWarTaskByTaskIdDic[cfg.TaskId] = resultTaskData
            else
                --临时任务,直接构造专用数据
                local resultTaskData = {
                    GuildWarTaskId = cfg.Id,
                    Name = cfg.Name,
                    TaskType = cfg.SubType,
                    Icon = cfg.Icon,
                    Desc = cfg.Desc,
                    RewardId = cfg.RewardId,
                    RoundId = roundId,
                    State = CompleteTaskId[cfg.Id] and XDataCenter.TaskManager.TaskState.Finish or XDataCenter.TaskManager.TaskState.Accepted,
                    SortWeight = CompleteTaskId[cfg.Id] and 2 or 1
                }
                table.insert(roundList[difficultyId], resultTaskData)
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_TASK_REFRESH)
    end
    --===============
    --刷新所有临时任务数据
    --===============
    function XGuildWarManager.RefreshGuildWarTaskList()
        if not GuildWarTaskList then
            --初始化会用此时最新数据，不需要再刷新，初始化完后返回
            XGuildWarManager.InitGuildWarTaskList()
            return
        end
        for roundId, dataListByDifficulty in pairs(GuildWarTaskList) do
            for difficultyId, taskList in pairs(dataListByDifficulty) do
                for _, taskData in pairs(taskList) do
                    if taskData.TaskType ~= XGuildWarConfig.SubTaskType.Real then
                        taskData.State = CompleteTaskId[taskData.GuildWarTaskId] and XDataCenter.TaskManager.TaskState.Finish or XDataCenter.TaskManager.TaskState.Accepted
                        taskData.SortWeight = CompleteTaskId[taskData.GuildWarTaskId] and 2 or 1
                    end
                end
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_TASK_REFRESH)
    end
    --===============
    --同步所有真任务数据
    --===============
    function XGuildWarManager.SyncTasks()
        if not GuildWarTaskList then
            --初始化会用此时最新数据，不需要再刷新，初始化完后返回
            XGuildWarManager.InitGuildWarTaskList()
            return
        end
        local TaskManager = XDataCenter.TaskManager
        --获取所有真任务数据
        local taskDatas = TaskManager.GetTaskList(TaskManager.TaskType.GuildWar)
        for _, taskData in pairs(taskDatas or {}) do
            local task = GuildWarTaskByTaskIdDic[taskData.Id]
            if task then
                task.Schedule = XTool.Clone(taskData.Schedule)
                task.State = taskData.State
                task.SortWeight = (task.State == XDataCenter.TaskManager.TaskState.Finish and 2)
                or (task.State == XDataCenter.TaskManager.TaskState.Achieved and 0) or 1
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_TASK_REFRESH)
    end
    --================
    --获取公会战全部任务列表
    --================
    function XGuildWarManager.GetAllTaskList()
        if not GuildWarTaskList then
            XGuildWarManager.InitGuildWarTaskList()
        end
        return GuildWarTaskList
    end
    --================
    --获取公会战显示的任务类型(屏蔽跳过的轮数)
    --================
    function XGuildWarManager.GetAllShowedTaskTypeList()
        local index = Config.TaskType.Activity
        local showedTaskTypeList = {}
        while true do
            local isNotStart = CurrentRoundId < index
            if isNotStart then break end
            local cfg = Config.GetCfgByIdKey(
                Config.TableKey.TaskType,
                index,
                true
            )
            if not cfg or (not next(cfg)) then break end
            local isSkip
            if index == 0 then
                isSkip = false
            else
                local round = XGuildWarManager.GetRoundByRoundId(index)
                isSkip = (round and round:CheckIsTaskNotShow())
            end
            if not isSkip then
                table.insert(showedTaskTypeList, { Name = cfg.Name, TaskType = cfg.Id})
            end
            index = index + 1
        end
        return showedTaskTypeList
    end
    --================
    --根据工会战任务类型Id获取公会战任务列表(屏蔽没有选择的难度)
    --@param taskType:任务类型Id
    --@return TaskData列表
    --================
    function XGuildWarManager.GetTaskList(taskType)
        if not GuildWarTaskList then
            XGuildWarManager.InitGuildWarTaskList()
        end
        if not taskType then taskType = 0 end
        if taskType == XGuildWarConfig.TaskType.Activity then
            local tempTaskDatas = {}
            for _, taskList in pairs(GuildWarTaskList[taskType] or {}) do
                for index, taskData in pairs(taskList) do
                    table.insert(tempTaskDatas, taskData)
                end
            end
            table.sort(tempTaskDatas, function(dataA, dataB)
                    if dataA.SortWeight == dataB.SortWeight then
                        return dataA.GuildWarTaskId < dataB.GuildWarTaskId
                    end
                    return dataA.SortWeight < dataB.SortWeight
                end)
            --周期任务不分难度
            return tempTaskDatas
        end
        local tempTaskDatas = {}
        local difficultyId = XGuildWarManager.GetRoundByRoundId(taskType):GetMyDifficulty()
        for difficulty, taskDataList in pairs(GuildWarTaskList[taskType] or {}) do
            if difficultyId == difficulty then
                for _, taskData in pairs(taskDataList) do
                    table.insert(tempTaskDatas, taskData)
                end
            end
        end
        table.sort(tempTaskDatas, function(dataA, dataB)
                if dataA.SortWeight == dataB.SortWeight then
                    return dataA.GuildWarTaskId < dataB.GuildWarTaskId
                end
                return dataA.SortWeight < dataB.SortWeight
            end)
        return tempTaskDatas
    end
    --===============
    --检查有没任务可接收奖励
    --===============
    function XGuildWarManager.CheckTaskAchieved()
        if XGuildWarConfig.CLOSE_DEBUG then return false end
        if XGuildWarManager.CheckActivityIsEnd() then
            return false
        end
        --只有真任务有这个状态
        for _, taskData in pairs(GuildWarTaskByTaskIdDic or {}) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
        return false
    end
    --================
    --根据工会战任务类型Id获取改任务类型有没可领奖励任务
    --@param taskType:任务类型Id
    --@return result:bool true有可领奖励任务 false没有
    --================
    function XGuildWarManager.CheckTaskCanAchievedByType(taskType)
        local taskDatas = XGuildWarManager.GetTaskList(taskType)
        for _, taskData in pairs(taskDatas or {}) do
            if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                return true
            end
        end
        return false
    end
    --------------------------------------------------------
    --------------------------------------------------------
    --排行榜相关
    --------------------------------------------------------
    --------------------------------------------------------
    function XGuildWarManager.CheckReadCurrentRanking()
        if CurrentRoundId == 1 then
            return true
        end
        local isRead = XSaveTool.GetData("GuildWar" .. XGuildWarManager.GetActivityId() .. XGuildWarManager.GetActvityTimeId() .. XPlayer.Id .. (CurrentRoundId - 1))
        return isRead
    end
    --===============
    --请求排行榜信息
    --@param cb: function 回调
    --===============
    function XGuildWarManager.RequestRanking(rankType, uid, cb)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.RequestRanking, {RankType = rankType, Uid = uid }, function(res)
                if cb then
                    cb(res.RankList, res.MyRankInfo)
                end
            end)
    end
    --------------------------------------------------------
    --------------------------------------------------------
    --弹窗相关
    --------------------------------------------------------
    --------------------------------------------------------
    --===============
    --对比新弹窗记录数据，检查是否有新的节点攻破
    --@param newPopupRecord:新弹窗记录数据
    --===============
    function XGuildWarManager.CheckNewRecord(newPopupRecord)
        if not newPopupRecord then return end
        local isNew = false
        for index, data in pairs(newPopupRecord.SettleDatas) do
            local roundId = data.RoundId
            if not (PopupRecord and PopupRecord[index]) and (not XGuildWarManager.CheckIsSkipRound(data.RoundId))
                and data.PlayerActivation > 0 then
                table.insert(NeedPopup, data)
                isNew = true
            end
        end
        PopupRecord = newPopupRecord.SettleDatas
        if isNew then
            XGuildWarManager.OpenNewRecord()
        end
    end

    function XGuildWarManager.OpenNewRecord()
        local record = NeedPopup[1]
        if not record then return end
        table.remove(NeedPopup, 1)
        XLuaUiManager.Open("UiGuildWarLastResults", record, function()
                XGuildWarManager.OpenNewRecord()
            end)
    end
    --===============
    --请求弹窗
    --@param cb: function 回调
    --===============
    function XGuildWarManager.RequestPopup(cb)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.PopUp, {}, function(res)
                local newRecord = res.PopupRecord
                XGuildWarManager.CheckNewRecord(newRecord)
                if cb then
                    cb()
                end
            end)
    end
    --===============
    --行动播放进度保存请求
    --@param cb: function 回调
    --===============
    function XGuildWarManager.RequestPopupActionID(showedActionIdList, cb)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.PopupActionID, {ActionPlayed = showedActionIdList}, function(res)
                if cb then
                    cb()
                end
            end)
    end
    --------------------------------------------------------
    --------------------------------------------------------
    --特攻角色相关
    --------------------------------------------------------
    --------------------------------------------------------
    --===============
    --获取所有特攻角色列表
    --@return 角色Id列表 (默认索引1是主攻角色)
    --===============
    function XGuildWarManager.GetSpecialRoleList()
        if not SpecialRoleList then
            local tempList = {}
            local roles = Config.GetAllConfigs(Config.TableKey.SpecialRole)
            for _, role in pairs(roles) do
                local data = { Center = role.CenterCharacter == 1, CharacterId = role.Id }
                table.insert(tempList, data)
            end
            table.sort(tempList, function(roleDataA, roleDataB)
                    if roleDataA.Center then
                        return true
                    end
                    if roleDataB.Center then
                        return false
                    end
                    return roleDataA.CharacterId < roleDataB.CharacterId
                end)
            SpecialRoleList = {}
            --主要特攻角色
            MainSpecialRoleId = tempList[1].CharacterId
            for i = 1, #tempList do
                table.insert(SpecialRoleList, tempList[i].CharacterId)
            end
        end
        return SpecialRoleList
    end
    --===============
    --根据实体Id获取特攻角色的Buff数据
    --若传入非特攻角色的Id，返回nil
    --@return buffData = { Icon = 图标地址, Name = Buff名称, Desc = Buff描述 }
    --===============
    function XGuildWarManager.GetSpecialRoleBuff(entityId)
        if not entityId then return nil end
        local characterId = 0
        if XRobotManager.CheckIsRobotId(entityId) then
            characterId = XRobotManager.GetCharacterId(entityId)
        else
            characterId = entityId
        end
        local roleCfg = Config.GetCfgByIdKey(
            Config.TableKey.SpecialRole,
            characterId,
            true
        )
        if not roleCfg then return nil end
        local fightEventId = roleCfg.FightEventId
        if not fightEventId or (fightEventId == 0) then return nil end
        local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
        if not cfg then return nil end
        local buffData = { Icon = cfg.Icon, Name = cfg.Name, Desc = cfg.Description}
        return buffData
    end
    --===============
    --获取特攻角色队伍Buff数据
    --@return buffData = { Icon = 图标地址, Name = Buff名称, Desc = Buff描述 }
    --===============
    function XGuildWarManager.GetSpecialTeamBuff()
        local teamCfg = Config.GetCfgByIdKey(
            Config.TableKey.SpecialTeam,
            1
        )
        local fightEventId = teamCfg.FightEventId
        if not fightEventId or (fightEventId == 0) then return nil end
        local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
        if not cfg then return nil end
        local buffData = { Icon = cfg.Icon, Name = cfg.Name, Desc = cfg.Description}
        return buffData
    end
    --===============
    --根据实体Id检查是否特攻角色
    --===============
    function XGuildWarManager.CheckIsSpecialRole(entityId)
        if not entityId then return false end
        local characterId = 0
        if XRobotManager.CheckIsRobotId(entityId) then
            characterId = XRobotManager.GetCharacterId(entityId)
        else
            characterId = entityId
        end
        local roleCfg = Config.GetCfgByIdKey(
            Config.TableKey.SpecialRole,
            characterId,
            true
        )
        return next(roleCfg) ~= nil
    end
    --===============
    --根据队伍数据检查是否特攻角色队伍
    --@return CurrentSpecial, MaxNum, IsSpecial
    --CurrentSpecial = (int)当前特攻角色数量
    --MaxNum = (int)激活需要的特攻角色数量
    --IsSpecial = (bool)是否已激活
    --===============
    function XGuildWarManager.CheckIsSpecialTeam(entityIds)
        if not entityIds then return false end
        local count = 0
        local isSpecialTeam = true
        for _, entityId in pairs(entityIds) do
            if entityId == 0 then
                isSpecialTeam = false --队伍要全队满员，且都是特攻角色才满足条件
                goto continue
            end
            local isSpecialRole = XGuildWarManager.CheckIsSpecialRole(entityId)
            if not isSpecialRole then
                isSpecialTeam = false
                goto continue
            end
            count = count + 1
            :: continue ::
        end
        return count, XDataCenter.TeamManager.GetMaxPos(), isSpecialTeam
    end
    --------------------------------------------------------
    --------------------------------------------------------
    --战斗相关
    --------------------------------------------------------
    --------------------------------------------------------
    --================
    --处理轮次结算通知
    --================
    function XGuildWarManager.OnNotifyGuildWarRoundSettle(data)
        if XUiManager.CheckTopUi(CsXUiType.Normal, "UiGuildWarStageMain")
            or XUiManager.CheckTopUi(CsXUiType.Normal, "UiGuildMain") then
            XGuildWarManager.RequestPopup()
        end
    end

    function XGuildWarManager.GetBattleManager()
        local round = XGuildWarManager.GetCurrentRound()
        if round then
            return round:GetBattleManager()
        end
        return nil
    end
    --================
    --检查是否有足够活动体力
    --================
    function XGuildWarManager.CheckEnoughActionPoint(actionPoint)
        return ActionPoint >= actionPoint
    end
    --================
    --获取当前活动体力值
    --================
    function XGuildWarManager.GetCurrentActionPoint()
        return ActionPoint
    end
    --================
    --扣除活动体力
    --================
    function XGuildWarManager.CostActionPoint(costPoint)
        if not XGuildWarManager.CheckEnoughActionPoint(costPoint) then
            XUiManager.TipText("GuildWarActionPointNotEnough")
            return
        end
        ActionPoint = ActionPoint - costPoint
    end
    --===============
    --确认战斗
    --@param cb: function 回调
    --===============
    function XGuildWarManager.ConfirmFight(stageId, cb)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.ConfirmFight, {StageId = stageId}, function(res)
                if cb then
                    cb()
                end
            end)
    end
    --===============
    --扫荡关卡
    --@param cb: function 回调
    --===============
    function XGuildWarManager.StageSweep(uid, sweepType, stageId, cb)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.StageSweep, {Uid = uid, SweepType = sweepType
                , StageId = stageId}, function(res)
                if cb then
                    cb()
                end
            end)
    end
    --------------------------------------------------------
    --------------------------------------------------------
    --入口，跳转相关
    --------------------------------------------------------
    --------------------------------------------------------
    --================
    --跳转到活动主界面
    --================
    function XGuildWarManager.JumpTo()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.GuildWar) then
            local canGoTo, notStart = XGuildWarManager.CheckActivityCanGoTo()
            if canGoTo then
                if XGuildWarManager.CheckCanEnterMain() then
                    XLuaUiManager.Open("UiGuildWarMain")
                end
            elseif notStart then
                XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityNotStart"))
            else
                XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
            end
        end
    end
    --================
    --玩法关闭时弹出主界面
    --================
    function XGuildWarManager.OnActivityEndHandler()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
    end
    --===============
    --获取活动信息
    --@param cb: function 回调
    --===============
    function XGuildWarManager.GetActivityData(cb)
        if XGuildWarConfig.CLOSE_DEBUG then return end
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.GetActivityData, {}, function(res)
                XGuildWarManager.RefreshActivityData(res.ActivityData)
                if cb then
                    cb()
                end
            end)
    end
    --===============
    --获取活动信息
    --@param cb: function 回调
    --===============
    function XGuildWarManager.RequestPlayerMove(targetNodeId, cb)
        local cost = tonumber(XGuildWarConfig.GetServerConfigValue("MoveCostEnergy"))
        if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId
                , cost) then
            return
        end
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.PlayerMove, {
                CurNodeId = XGuildWarManager.GetBattleManager():GetCurrentNodeId(),
                NextNodeId = targetNodeId,
            }, function(res)
                XGuildWarManager.GetBattleManager():UpdateNodeDatas(res.NodeDatas)
                XGuildWarManager.GetBattleManager():UpdateCurrentNodeId(targetNodeId)
                XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PLAYER_MOVE)
                if cb then cb() end
            end)
    end
    --===============
    -- 副本接口BEGIN
    --===============
    function XGuildWarManager.InitStageInfo()
        -- 关卡池的关卡
        local configs = XGuildWarConfig.GetAllConfigs(XGuildWarConfig.TableKey.Stage)
        local stageInfo = nil
        for _, config in pairs(configs) do
            stageInfo = XDataCenter.FubenManager.GetStageInfo(config.StageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.GuildWar
            else
                XLog.Error("公会战找不到配置的关卡id：" .. config.StageId)
            end
        end
    end

    function XGuildWarManager.ShowReward(winData, playEndStory)
        XLuaUiManager.Open("UiSettleWinCommon", winData, require("XUi/XUiGuildWar/XUiGuildWarSettleWin"))
    end

    function XGuildWarManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local battleManager = XGuildWarManager.GetBattleManager()
        local team = battleManager:GetTeam()
        local cardIds = { 0, 0, 0}
        local robotIds = { 0, 0, 0}
        for pos, entityId in ipairs(team:GetEntityIds()) do
            if XEntityHelper.GetIsRobot(entityId) then
                robotIds[pos] = entityId
            else
                cardIds[pos] = entityId
            end
        end
        local result = {
            StageId = stage.StageId,
            IsHasAssist = isAssist,
            ChallengeCount = challengeCount,
            CaptainPos = team:GetCaptainPos(),
            FirstFightPos = team:GetFirstFightPos(),
            CardIds = cardIds,
            RobotIds = robotIds,
        }
        result.GuildWarUid = XGuildWarManager.GetBattleManager():GetCurrentClientBattleUID()
        return result
    end
    --===============
    -- 副本接口END
    --===============
    function XGuildWarManager.GetMaxEnergy()
        return tonumber(XGuildWarConfig.GetServerConfigValue("MaxEnergy"))
    end
    XGuildWarManager.Init()
    return XGuildWarManager
end
--============
--登陆数据通知
--============
XRpc.NotifyGuildWarActivityData = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then return end
    XDataCenter.GuildWarManager.OnNotifyActivityData(data)
end
--============
--轮次结算通知
--============
XRpc.NotifyGuildWarRoundSettle = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then return end
    XDataCenter.GuildWarManager.OnNotifyGuildWarRoundSettle(data)
end
--============
--通知客户端，战斗记录有刷新
--============
XRpc.NotifyGuildWarFightRecordChange = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then return end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateFightRecords(data.FightRecords)
end
--============
--通知客户端，活动数据有刷新(8点)
--============
XRpc.NotifyGuildWarActivityDataChange = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then return end
    XDataCenter.GuildWarManager.RefreshActivityData(data.ActivityData)
end
--============
--通知客户端，新事件发生
--============
XRpc.NotifyGuildWarAction = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then return end
    local battleManager = XDataCenter.GuildWarManager.GetBattleManager()
    battleManager:AddActionList(data.ActionList)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, data.ActionList)
end
--============
--通知客户端，节点数据更新
--============
XRpc.NotifyGuildWarNodeUpdate = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then return end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateNodeData(data.NodeData)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE)
end
--============
--通知客户端，怪物数据更新
--============
XRpc.NotifyGuildWarMonsterUpdate = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then return end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateMonsterData(data.MonsterData)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_MONSTER_CHANGE)
end
