--===========================
--公会战活动管理器
--模块负责：吕天元 陈思亮 张爽
--二期负责: 曾立斌
--三期负责： 建南
--===========================
XGuildWarManagerCreator = function()
    --===================================
    --DEBUG相关
    --===================================
    local DEBUG = true
    local _printDebug = function(...)
        if not DEBUG then
            return
        end
        XLog.Debug(...)
    end
    -------------------------------------
    -------------------------------------
    ---@class XGuildWarManager
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
    --援助角色数据
    local _DataAssistant
    local _AssistantCharacterList = {}
    --特攻角色列表
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
    --下一轮选择的难度ID
    local NextDifficultyId
    --上期活动最高难度ID
    local LastMaxDifficultyId
    local IsNotifyDataFirstTime = true
    --记录刚刚通过的关卡ID
    local _JustPassedStageId = false
    --===============
    --公会战 协议名
    --===============
    local METHOD_NAME = {
        GetActivityData = "GuildWarGetActivityDataRequest", --主动请求活动信息
        EditPlan = "GuildWarEditLineRequest", --编辑指挥路线
        RequestRanking = "GuildWarOpenRankRequest", --查询排行榜
        SelectDifficult = "GuildWarSelectDifficultyRequest", --选择难度
        ConfirmFight = "GuildWarConfirmFightResultRequest", -- 确认关卡结果
        StageSweep = "GuildWarSweepRequest", -- 请求关卡扫荡
        PopUp = "GuildWarPopupRequest", -- 弹窗请求
        PopupActionID = "GuildWarPopupActionRequest", -- 行动播放进度保存请求
        PlayerMove = "GuildWarMoveRequest", -- 玩家移动

        AssistantDetail = "GuildWarOpenSupportPanelRequest", -- 请求援助界面需要的信息
        AssistantCancel = "GuildWarEndSupportRequest", -- 取消援助
        AssistantSet = "GuildWarSupportCharacterRequest", --设置援助角色
        AssistantCharacterList = "GuildWarAssistCharacterListRequest", --支援角色列表
        SetTeam = "GuildWarSetTeamRequest", -- 设置队伍，每次进战斗之前发这条协议，支援角色每次打开编队界面的时候要清掉
        CanMove = "GuildWarCanMoveRequest", -- 能否移动请求
        ReceiveSupportSupply = "GuildWarReceivedSupportRequest", -- 领取补给

        SetAreaTeam = "GuildWarSetHideAreaTeamRequest", --设置多区域节点玩法区域队伍，每次进战斗之前发这条协议
        ResetAreaTeamScore = "GuildWarResetHideAreaTeamRequest", --重置多区域节点玩法区域分数
        UploadAreaScore = "GuildWarUploadHideNodePointRequest", --上传多区域节点玩法分数
        ReceiveBossReward = "XGuildWarGetBossRewardRequest", --领取boss奖励
    }

    --自己是否管理员(逻辑上判断可否选择难度？)
    local function CheckIsGuildMaster()
        return XGuildWarManager.IsCanSelectDifficulty()
    end

    --事件监听
    local InitListenerFlag
    local function AddInitListener()
        if InitListenerFlag then
            return
        end
        XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, XGuildWarManager.SyncTasks)
        InitListenerFlag = true
    end
    local function RemoveInitListener()
        if not InitListenerFlag then
            return
        end
        XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, XGuildWarManager.SyncTasks)
        InitListenerFlag = false
    end

    --region 初始化
    --初始化活动设置
    local function InitActivityCfg(cfg)
        ActivityId = cfg.Id
        ActivityName = cfg.Name
        ActivityTimeId = cfg.TimeId
    end
    --初始化
    function XGuildWarManager.Init()
        if XGuildWarConfig.CLOSE_DEBUG then
            return
        end
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
    --endregion

    --region 活动时间 功能开启 功能跳转 相关
    --获取给定配置的活动Id(XGuildWarActivityManager的Id) 若配置为空，则返回0
    function XGuildWarManager.GetActivityId()
        return ActivityId or 0
    end
    --获取当前配置的活动名称(XGuildWarActivityManager的Name) 若配置为空，则返回字符串"UnNamed"
    function XGuildWarManager.GetName()
        return ActivityName or "UnNamed"
    end
    --获取给定配置的活动TimeId 若配置为空，则返回0
    function XGuildWarManager.GetActvityTimeId()
        return ActivityTimeId or 0
    end
    --检查当前活动是否在开放时间内
    function XGuildWarManager.CheckActivityIsInTime()
        if XGuildWarConfig.CLOSE_DEBUG then
            return false
        end
        local now = XTime.GetServerNowTimestamp()
        return (now >= XGuildWarManager.GetActivityStartTime())
                and (now < XGuildWarManager.GetActivityEndTime())
    end
    --获取当前活动开始时间戳(根据TimeId)
    function XGuildWarManager.GetActivityStartTime()
        if XGuildWarConfig.CLOSE_DEBUG then
            return 0
        end
        return XFunctionManager.GetStartTimeByTimeId(ActivityTimeId)
    end
    --获取当前活动结束时间戳(根据TimeId)
    function XGuildWarManager.GetActivityEndTime()
        if XGuildWarConfig.CLOSE_DEBUG then
            return 0
        end
        return XFunctionManager.GetEndTimeByTimeId(ActivityTimeId)
    end
    --获取当前活动剩余时间(秒)
    function XGuildWarManager.GetActivityLeftTime()
        local now = XTime.GetServerNowTimestamp()
        local endTime = XGuildWarManager.GetActivityEndTime()
        local leftTime = endTime - now
        return leftTime
    end
    --================
    --检查是否能进入玩法
    --@return1 :是否在活动时间内(true为在活动时间内)
    --@return2 :是否未开始活动(true为未开始活动)
    --================
    function XGuildWarManager.CheckActivityCanGoTo()
        if XGuildWarConfig.CLOSE_DEBUG then
            return false
        end
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
    --玩法关闭时弹出主界面
    function XGuildWarManager.OnActivityEndHandler()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
    end
    --================
    --跳转到活动主界面 2022.5.15 by zlb 这段代码不能正常运行
    --================
    -- function XGuildWarManager.JumpTo()
    --     if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.GuildWar) then
    --         local canGoTo, notStart = XGuildWarManager.CheckActivityCanGoTo()
    --         if canGoTo then
    --             if XGuildWarManager.CheckCanEnterMain() then
    --                 XLuaUiManager.Open("UiGuildWarMain")
    --             end
    --         elseif notStart then
    --             XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityNotStart"))
    --         else
    --             XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
    --         end
    --     end
    -- end
    --================
    --endregion

    --region 活动玩家数据
    --主动请求 活动数据 更新数据 @param cb: function 回调
    function XGuildWarManager.GetActivityData(cb)
        if XGuildWarConfig.CLOSE_DEBUG then
            return
        end
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.GetActivityData, {}, function(res)
            XGuildWarManager.RefreshActivityData(res.ActivityData)
            if cb then
                cb()
            end
        end)
    end
    --登陆活动数据通知 更新数据
    function XGuildWarManager.OnNotifyActivityData(data)
        local cfg = Config.GetCfgByIdKey(
                Config.TableKey.Activity,
                data.ActivityNo
        )
        InitActivityCfg(cfg)
        PopupRecord = data.PopupRecord and data.PopupRecord.SettleDatas or {}
        local activityData = data.ActivityData
        XGuildWarManager.RefreshActivityData(activityData) --处理公会活动数据刷新
        XGuildWarManager.RefreshMyRoundData(data.MyRoundData) --处理玩家活动数据刷新
        XGuildWarManager.RefreshFightRecords(data.FightRecords) --处理战斗数据刷新
        XGuildWarManager.RefreshLastActionIdDic(data.ActionPlayed) --处理最后的ActionId刷新
        XGuildWarManager.RefreshAreaTeamNodeData(data.HideAreaTeamInfos or {}, data.LastHideAreaTeamInfos or {}) --隐藏区域队伍记录
        if activityData and IsNotifyDataFirstTime then
            IsNotifyDataFirstTime = false
            XGuildWarManager.RequestAssistantDetail() --请求援助角色信息
        end
    end
    --处理公会活动数据刷新
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

        --更新回合数据
        for _, roundData in ipairs(activityData.RoundData) do
            local round = XGuildWarManager.GetRoundByRoundId(roundData.RoundId)
            if round then
                round:RefreshRoundData(roundData)
            end
        end

        --更新当前回合战场动画数据
        local battleManager = XGuildWarManager.GetBattleManager()
        if battleManager then
            --活动开启前battleManager会为空
            battleManager:SetActionList(activityData.ActionList)
        end

        --更新轮次结算数据
        for _, settleData in pairs(activityData.SettleDatas or {}) do
            if settleData.IsPass == 1 then
                DifficultyPassRecord[settleData.DifficultyId] = true
            end
            local round = XGuildWarManager.GetRoundByRoundId(settleData.RoundId)
            if round then
                round:SetSettleData(settleData)
            end
        end

        --刷新任务数据
        XGuildWarManager.RefreshGuildWarTaskList(activityData)

        -- 下一轮选择的难度ID
        NextDifficultyId = activityData.NextDifficultyId

        -- 上期活动最高难度ID
        LastMaxDifficultyId = activityData.LastMaxDifficultyId

        --如果是新的一轮，发出通知
        if NewRoundFlag then
            XGuildWarManager.StartTimerRoundEnd()
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_NEW_ROUND)
        end
    end
    --处理玩家活动数据刷新
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
    --处理战斗数据刷新
    function XGuildWarManager.RefreshFightRecords(fightRecords)
        if fightRecords then
            local round = XGuildWarManager.GetCurrentRound()
            if round then
                round:UpdateFightRecords(fightRecords)
            end
        end
    end
    --处理最后的ActionId刷新
    function XGuildWarManager.RefreshLastActionIdDic(actionIdList)
        if actionIdList then
            local round = XGuildWarManager.GetCurrentRound()
            if round then
                round:UpdateLastActionIdDic(actionIdList)
            end
        end
    end
    --更新多区域队伍挑战节点数据
    --param HideAreaTeamInfos:List<C# XGuildWarTeamInfo>
    function XGuildWarManager.RefreshAreaTeamNodeData(areaTeamInfos, recordTeamInfos)
        local battleManager = XGuildWarManager.GetBattleManager()
        if battleManager then
            --活动开启前battleManager会为空
            battleManager:UpdateAreaTeamNodeInfos(areaTeamInfos, recordTeamInfos)
        end
    end
    --endregion

    --region 会战战斗轮次

    --region 轮次管理器 XGuildWarRound
    --创建轮次管理器
    ---@return XGuildWarRound
    local function CreateRound(roundId)
        local manager = require("XEntity/XGuildWar/Round/XGuildWarRound")
        return manager.New(roundId)
    end
    --================
    --用轮次Id获取轮次管理器
    --@param roundId:轮次Id
    --若roundId为nil或为0会返回空
    --================
    ---@return XGuildWarRound
    function XGuildWarManager.GetRoundByRoundId(roundId)
        if not roundId or (roundId == 0) then
            return nil
        end
        if not RoundDatas[roundId] then
            RoundDatas[roundId] = CreateRound(roundId)
        end
        return RoundDatas[roundId]
    end
    --获取当前轮次管理器
    function XGuildWarManager.GetCurrentRound()
        return XGuildWarManager.GetRoundByRoundId(CurrentRoundId)
    end
    --获取上一轮轮次管理器 若这是第一轮，则返回nil
    function XGuildWarManager.GetPreRound()
        if not CurrentRoundId or (CurrentRoundId <= 1) then
            return nil
        end
        return XGuildWarManager.GetRoundByRoundId(CurrentRoundId - 1)
    end
    --endregion

    --region 跳过轮
    --检查是否公会跳过轮
    function XGuildWarManager.CheckIsGuildSkipRound(roundId)
        local round = XGuildWarManager.GetRoundByRoundId(roundId or CurrentRoundId)
        return round and round:CheckIsSkipRound()
    end
    --检查是否玩家跳过轮
    function XGuildWarManager.CheckIsPlayerSkipRound(roundId)
        local round = XGuildWarManager.GetRoundByRoundId(roundId or CurrentRoundId)
        return round and round:CheckIsMySkipRound()
    end
    --根据轮次Id检查是否跳过轮
    function XGuildWarManager.CheckIsSkipRound(roundId)
        return XGuildWarManager.CheckIsGuildSkipRound(roundId)
                or XGuildWarManager.CheckIsPlayerSkipRound(roundId)
    end
    --检查当前轮是否跳过轮
    function XGuildWarManager.CheckIsSkipCurrentRound()
        return XGuildWarManager.CheckIsGuildSkipRound()
                or XGuildWarManager.CheckIsPlayerSkipRound()
    end
    --endregion
    --计算轮次用时
    local function CalRoundUseTime(roundStartTime, roundEndTime, assistStartTime, assistEndTime, lastRecvTime, nowTime)
        if assistStartTime >= roundEndTime then
            return 0
        end

        if assistEndTime > 0 and assistEndTime <= roundStartTime then
            return 0
        end

        local startTime = assistStartTime < roundStartTime and roundStartTime or assistStartTime
        local endTime = 0
        if assistEndTime == 0 then
            endTime = roundEndTime
        else
            endTime = assistEndTime > roundEndTime and roundEndTime or assistEndTime
        end

        if lastRecvTime >= endTime then
            return 0
        end

        startTime = lastRecvTime > startTime and lastRecvTime or startTime

        if nowTime <= startTime then
            return 0
        end

        endTime = nowTime > endTime and endTime or nowTime

        return endTime - startTime
    end
    --获取新一轮开始标记 该标记在获取后会设置回False
    function XGuildWarManager.GetNewRoundFlag()
        local flag = NewRoundFlag
        NewRoundFlag = false
        return flag
    end
    --获取当前轮次Id 若配置为空，则返回1
    function XGuildWarManager.GetCurrentRoundId()
        return CurrentRoundId or 1
    end
    --获取当前轮次的TimeId 若为空，则返回0
    function XGuildWarManager.GetRoundTimeId()
        return RoundTimeId or 0
    end
    --检查当前轮次是否在开放时间内(不在时间内 即为休战期)
    function XGuildWarManager.CheckRoundIsInTime()
        if XGuildWarConfig.CLOSE_DEBUG then
            return false
        end
        local now = XTime.GetServerNowTimestamp()
        return (now >= XGuildWarManager.GetRoundStartTime())
                and (now < XGuildWarManager.GetRoundEndTime())
    end
    --获取当前轮次开始时间戳(根据TimeId)
    function XGuildWarManager.GetRoundStartTime()
        return XFunctionManager.GetStartTimeByTimeId(RoundTimeId)
    end
    --获取当前轮次结束时间戳(根据TimeId)
    function XGuildWarManager.GetRoundEndTime()
        return XFunctionManager.GetEndTimeByTimeId(RoundTimeId)
    end
    --获取是否最后一轮
    function XGuildWarManager.IsLastRound()
        if not XGuildWarManager.CheckActivityIsInTime() then
            return false
        end
        local nextRoundTime = XGuildWarManager.GetNextRoundTime()
        return not nextRoundTime
    end
    --获取当前轮次剩余时间(秒)
    function XGuildWarManager.GetRoundLeftTime()
        if XGuildWarManager.CheckRoundIsInTime() then
            local now = XTime.GetServerNowTimestamp()
            local endTime = XGuildWarManager.GetRoundEndTime()
            local leftTime = endTime - now
            return leftTime
        else
            local nextRoundTime = XGuildWarManager.GetNextRoundTime(true)
            -- 没有下一轮, 又非进行中, 活动应该已经结束了
            if not nextRoundTime then
                return 0
            end
            return nextRoundTime
            -- local now = XTime.GetServerNowTimestamp()
            -- return now - nextRoundTime
        end
    end
    --获取服务器下一次关卡刷新时间的时间戳
    function XGuildWarManager.GetNextMapRefreshTime()
        local oclock = Config.GetClientConfigValues("DayRefreshTime", "Float")[1]
        return XTime.GetServerNextTargetTime(oclock)
    end
    --获取固定时长刷新的时间间隔
    function XGuildWarManager.GetHourRefreshTime()
        local time = Config.GetClientConfigValues("HourRefreshTime", "Float")[1]
        return time
    end
    --检查当轮是否能进入地图
    function XGuildWarManager.CheckCanEnterMain()
        --检查轮数是否开始
        local isInRound = XGuildWarManager.CheckRoundIsInTime()
        if not isInRound then
            return false
        end
        --第二步检查跳过情况
        local isSkip = XGuildWarManager.CheckIsSkipRound()
        if isSkip then
            return false
        end
        --第三步检查是否选择了难度
        local isSelectDifficulty = XGuildWarManager.CheckHaveDifficultySelected()
        if not isSelectDifficulty then
            return false
        end
    end
    --获取在当前回合是否在工会？
    function XGuildWarManager.CheckIsInGuildByRound(roundId)
        if roundId == 0 then
            return true
        end --全局任务默认在公会
        local round = XGuildWarManager.GetRoundByRoundId(roundId)
        if not round then
            return false
        end
        local isChange = round:CheckIsChangeGuild()
        return not isChange
    end
    --获取到下一轮的开放时间 若已经没有下一轮，返回nil=
    function XGuildWarManager.GetNextRoundTime(notFormat)
        local now = XTime.GetServerNowTimestamp()
        local startTime = XGuildWarManager.GetRoundStartTime()
        --检查是否是第一轮未开始
        if CurrentRoundId == 1 and now < startTime then
            if notFormat then
                return startTime - now
            end
            return XUiHelper.GetTime(startTime - now, XUiHelper.TimeFormatType.ACTIVITY)
        elseif CurrentRoundId == Config.ROUND_NUM then
            return nil
        else
            local nextRoundCfg = Config.GetCfgByIdKey(
                    Config.TableKey.Round,
                    CurrentRoundId + 1
            )
            local nextStartTime = XFunctionManager.GetStartTimeByTimeId(nextRoundCfg.TimeId)
            if notFormat then
                return nextStartTime - now
            end
            return XUiHelper.GetTime(nextStartTime - now, XUiHelper.TimeFormatType.ACTIVITY)
        end
    end
    --重置新回合标志位
    function XGuildWarManager.ResetNewRound()
        NewRoundFlag = true
    end
    --开启回合结束定时器
    local _RoundEndTimer = false
    function XGuildWarManager.StartTimerRoundEnd()
        XGuildWarManager.StopTimerRoundEnd()
        local roundEntTime = XGuildWarManager.GetRoundEndTime()
        if roundEntTime then
            _RoundEndTimer = XScheduleManager.ScheduleForever(function()
                local roundEntTime = XGuildWarManager.GetRoundEndTime()
                if not roundEntTime then
                    XGuildWarManager.StopTimerRoundEnd()
                end
                if XTime.GetServerNowTimestamp() > roundEntTime then
                    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ROUND_END)
                    XGuildWarManager.StopTimerRoundEnd()
                end
            end, 1)
        end
    end
    --关闭回合结束定时器
    function XGuildWarManager.StopTimerRoundEnd()
        if _RoundEndTimer then
            XScheduleManager.UnSchedule(_RoundEndTimer)
            _RoundEndTimer = false
        end
    end
    --endregion

    --region 工会成员权限
    --================
    --请求：编辑计划路线(标记关卡)
    --@param nodeList: --路线，节点ID列表
    --@param cb: function 回调
    --================
    function XGuildWarManager.EditPlan(nodeList, cb)
        if not CheckIsGuildMaster() then
            XUiManager.TipMsg(XUiHelper.GetText("GuildWarNotGuildMaster"))
            return
        end
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.EditPlan, { AttackPlan = nodeList }, function(res)
            local battleManager = XGuildWarManager.GetBattleManager()
            battleManager:UpdateNodePathIndex(nodeList)
            if cb then
                cb()
            end
        end)
    end
    --获取标记关卡最大节点数
    function XGuildWarManager.GetPathMarkMaxCount()
        local time = Config.GetClientConfigValues("PathMarkMaxCount", "Float")[1]
        return time
    end
    -- 获取自己能否选择难度(取决于自己是否会长或副会长)
    function XGuildWarManager.IsCanSelectDifficulty()
        return XDataCenter.GuildManager.IsGuildCoLeader()
                or XDataCenter.GuildManager.IsGuildLeader()
    end
    --endregion

    --region UI相关

    --endregion

    --region 难度选择相关
    --检查本轮公会是否已经选择难度
    function XGuildWarManager.CheckHaveDifficultySelected()
        local battleManager = XGuildWarManager.GetBattleManager()
        if not battleManager then
            return NextDifficultyId ~= 0
        end
        local mydata = battleManager:GetCurrentMyRoundData()
        if not mydata or (not next(mydata)) then
            return false
        end
        return mydata.DifficultyId > 0
    end
    --本轮选择难度
    function XGuildWarManager.GetDifficultySelected()
        local battleManager = XGuildWarManager.GetBattleManager()
        local mydata = battleManager:GetCurrentMyRoundData()
        if not mydata or (not next(mydata)) then
            return false
        end
        return mydata.DifficultyId
    end
    --获取难度数据列表
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
    --检查难度是否已通关
    function XGuildWarManager.CheckDifficultyIsPass(difficultyId)
        if difficultyId == 0 then
            return true
        end
        return difficultyId and DifficultyPassRecord[difficultyId]
    end
    -- 获取某个难度是否解锁 
    function XGuildWarManager.CheckDifficultyIsUnlock(difficultyId)
        if XGuildWarManager.CheckDifficultyIsPass(difficultyId) then
            return true
        end
        local preId = XGuildWarConfig.GetDifficultyPreId(difficultyId)
        if not XTool.IsNumberValid(preId) then
            return true
        end
        return XGuildWarManager.CheckDifficultyIsPass(preId)
    end
    --获取本期上一次通关的难度 若是第一轮，返回难度1
    function XGuildWarManager.GetDifficultyPreSelected()
        if CurrentRoundId == 1 then
            return 1
        end
        for i = CurrentRoundId - 1, 1, -1 do
            local round = XGuildWarManager.GetRoundByRoundId(i)
            local battleManager = round and round:GetBattleManager()
            if battleManager and battleManager:CheckAllInfectIsDead() then
                return round:GetDifficulty()
            end
        end
        return 1
    end
    --获取难度名称 若传入参数为空，则返回空字符串""
    function XGuildWarManager.GetDifficultyName(difficultyId)
        local cfg = Config.GetCfgByIdKey(
                Config.TableKey.Difficulty,
                difficultyId,
                true
        )
        return cfg and cfg.Name or ""
    end
    --获取结算奖励Id @isPass 是否通过
    function XGuildWarManager.GetRoundSettleReward(difficultyId, isPass)
        local rewardId = 0
        local cfg = Config.GetCfgByIdKey(
                Config.TableKey.Difficulty,
                difficultyId,
                true
        )
        if not cfg then
            return 0
        end
        if isPass == 1 then
            rewardId = cfg and cfg.PassRewardId
        else
            rewardId = cfg and cfg.UnPassRewardId
        end
        return rewardId
    end
    -- 活跃度
    function XGuildWarManager.IsActivationNotRecommend(difficulty)
        local preActive = 0
        if CurrentRoundId > 1 then
            local preRound = XGuildWarManager.GetRoundByRoundId(CurrentRoundId - 1)
            if not preRound:CheckIsSkipRound() then
                preActive = preRound:GetTotalActivation()
            end
        end
        local recommendActivation = XGuildWarConfig.GetDifficultyRecommendActivation(difficulty)
        return preActive <= recommendActivation
    end
    --获取下一难度ID
    function XGuildWarManager.GetNextDifficultyId(isDefaultSelect)
        if isDefaultSelect
                and NextDifficultyId == 0
                and not XGuildWarManager.CheckHaveDifficultySelected()
        then
            return XGuildWarManager.GetDifficultyPreSelected()
        end
        return NextDifficultyId
    end
    --获取曾经作战的最高难度
    function XGuildWarManager.GetLastMaxDifficultyId()
        return LastMaxDifficultyId
    end
    --请求：选择难度 @param cb: function 回调
    function XGuildWarManager.SelectDifficulty(difficulty, cb)
        if not XGuildWarManager.IsCanSelectDifficulty() then
            XUiManager.TipText("GuildWarNotGuildMaster")
            return
        end
        local preActive = 0
        if CurrentRoundId > 1 then
            local preRound = XGuildWarManager.GetRoundByRoundId(CurrentRoundId - 1)
            if not preRound:CheckIsSkipRound() then
                preActive = preRound:GetTotalActivation()
            end
        end
        local difficultyCfg = Config.GetCfgByIdKey(
                Config.TableKey.Difficulty,
                difficulty
        )
        local recommend = difficultyCfg.RecommendActive
        --比较推荐值与上一轮的活跃度的大小，获取对应文本
        if recommend > preActive then
            local tipTitle = XUiHelper.GetText("GuildWarSelectDifficultyConfirmTitle")
            local content = XUiHelper.GetText("GWSelectDifficultyConfirmContentNotRecommend")
            local confirmCb = function()
                XGuildWarManager.CallSelectDifficulty(difficulty, cb)
            end
            XLuaUiManager.Open("UiDialog", tipTitle, content, XUiManager.DialogType.Normal, nil, confirmCb)
        else
            XGuildWarManager.CallSelectDifficulty(difficulty, cb)
        end
    end
    function XGuildWarManager.CallSelectDifficulty(difficulty, cb)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.SelectDifficult, { DifficultyId = difficulty }, function(res)
            NextDifficultyId = difficulty
            if cb then
                cb()
            end
            XUiManager.TipText("GuildWarSelectDifficultySuccess")
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUILD_WAR_DIFFICULTY_SELECTED)
        end)
    end
    --endregion

    --region 任务相关
    --初始化任务数据
    function XGuildWarManager.InitGuildWarTaskList()
        local TaskManager = XDataCenter.TaskManager
        GuildWarTaskList = {}
        GuildWarTaskByTaskIdDic = {}
        local taskCfgs = Config.GetAllConfigs(Config.TableKey.Task)
        --获取所有真任务数据
        local taskDatas = XGuildWarManager.GetTaskDataWithTerm2()
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
                    resultTaskData.SortWeight = XGuildWarManager.GetWeightByTask(resultTaskData)
                else
                    --没有数据也要构筑一个空的占位
                    resultTaskData.Schedule = { [1] = { Id = cfg.TaskId, Value = 0 } }
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
    --获取任务的加权参数(应该是用来排序?)
    function XGuildWarManager.GetWeightByTask(data)
        local taskData = XDataCenter.TaskManager.GetTaskDataById(data.Id)
        local state = taskData and taskData.State or data.State
        return (state == XDataCenter.TaskManager.TaskState.Finish and 2)
                or (state == XDataCenter.TaskManager.TaskState.Achieved and 0) or 1
    end
    --刷新所有临时任务数据
    function XGuildWarManager.RefreshGuildWarTaskList(activityData)
        --先重置缓存的完成任务情况
        CompleteTaskId = {}
        for _, taskId in pairs(activityData.CompleteTaskId or {}) do
            if not CompleteTaskId[taskId] then
                CompleteTaskId[taskId] = true
            end
        end
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
    --同步所有真任务数据
    function XGuildWarManager.SyncTasks()
        if not GuildWarTaskList then
            --初始化会用此时最新数据，不需要再刷新，初始化完后返回
            XGuildWarManager.InitGuildWarTaskList()
            return
        end
        local TaskManager = XDataCenter.TaskManager
        --获取所有真任务数据
        local taskDatas = XGuildWarManager.GetTaskDataWithTerm2()
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
    --获取公会战全部任务列表
    function XGuildWarManager.GetAllTaskList()
        if not GuildWarTaskList then
            XGuildWarManager.InitGuildWarTaskList()
        end
        return GuildWarTaskList
    end
    --获取公会战显示的任务类型(屏蔽跳过的轮数)
    function XGuildWarManager.GetAllShowedTaskTypeList()
        local index = Config.TaskType.Activity
        local showedTaskTypeList = {}
        while true do
            local isNotStart = CurrentRoundId < index
            if isNotStart then
                break
            end
            local cfg = Config.GetCfgByIdKey(
                    Config.TableKey.TaskType,
                    index,
                    true
            )
            if not cfg or (not next(cfg)) then
                break
            end
            local isSkip
            if index == 0 then
                isSkip = false
            else
                local round = XGuildWarManager.GetRoundByRoundId(index)
                isSkip = (round and round:CheckIsTaskNotShow())
                --第三期新加逻辑，若本轮被跳过，则检查是否有可以领取奖励的任务，如果有，则显示Tab。
                if isSkip then
                    local taskDatas = XGuildWarManager.GetTaskList(cfg.Id)
                    for _, taskData in pairs(taskDatas) do
                        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                            isSkip = false
                            break
                        end
                    end
                end
            end
            if not isSkip then
                table.insert(showedTaskTypeList, { Name = cfg.Name, TaskType = cfg.Id })
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
        if not taskType then
            taskType = 0
        end
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
    --检查有没任务可接收奖励
    function XGuildWarManager.CheckTaskAchieved()
        if XGuildWarConfig.CLOSE_DEBUG then
            return false
        end
        if XGuildWarManager.CheckActivityIsEnd() then
            return false
        end
        --只有真任务有这个状态
        --for _, taskData in pairs(GuildWarTaskByTaskIdDic or {}) do
        --    if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
        --        return true
        --    end
        --end

        -- 红点判断与界面显示的任务一致
        local taskTypeList = XGuildWarManager.GetAllShowedTaskTypeList()
        for i = 1, #taskTypeList do
            local taskTypeData = taskTypeList[i]
            local taskType = taskTypeData.TaskType
            local taskDataList = XGuildWarManager.GetTaskList(taskType)
            for _, taskData in pairs(taskDataList) do
                if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                    return true
                end
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
    --获取2期任务
    function XGuildWarManager.GetTaskDataWithTerm2()
        local taskManager = XDataCenter.TaskManager
        return XTool.MergeArray(taskManager.GetTaskList(taskManager.TaskType.GuildWar),
                taskManager.GetTaskList(taskManager.TaskType.GuildWarTerm2))
    end
    --endregion

    --region 排行榜相关
    --本地持久化已经阅读过排行榜标记
    function XGuildWarManager.LocalStroageSaveReadCurrentRanking(targetRound)
        XSaveTool.SaveData("GuildWar" .. XGuildWarManager.GetActivityId() .. XGuildWarManager.GetActvityTimeId() .. XPlayer.Id .. (targetRound - 1), true)
    end
    --检查是否已经阅读过排行榜
    function XGuildWarManager.LocalStroageLoadReadCurrentRanking()
        if CurrentRoundId == 1 then
            return true
        end
        local isRead = XSaveTool.GetData("GuildWar" .. XGuildWarManager.GetActivityId() .. XGuildWarManager.GetActvityTimeId() .. XPlayer.Id .. (CurrentRoundId - 1))
        return isRead
    end
    --请求排行榜信息 @param cb: function 回调
    function XGuildWarManager.RequestRanking(rankType, uid, cb)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.RequestRanking, { RankType = rankType, Uid = uid }, function(res)
            if cb then
                cb(res.RankList, res.MyRankInfo)
            end
        end)
    end
    --endregion

    --region 弹窗相关
    --获取弹窗记录?
    function XGuildWarManager.GetPopupRecord()
        if not PopupRecord then
            return nil
        end
        local record = PopupRecord
        PopupRecord = nil
        return record
    end
    --===============
    --对比新弹窗记录数据，检查是否有新的节点攻破
    --@param newPopupRecord:新弹窗记录数据
    --===============
    function XGuildWarManager.CheckNewRecord(newPopupRecord)
        if not newPopupRecord then
            return
        end
        local isNew = false
        for index, data in pairs(newPopupRecord.SettleDatas) do
            local roundId = data.RoundId
            if not (PopupRecord and PopupRecord[index]) and (not XGuildWarManager.CheckIsSkipRound(data.RoundId)) then
                table.insert(NeedPopup, data)
                isNew = true
            end
        end
        PopupRecord = newPopupRecord.SettleDatas
        if isNew then
            XGuildWarManager.OpenNewRecord()
        end
    end
    --打开新的结算弹窗
    function XGuildWarManager.OpenNewRecord()
        local record = NeedPopup[1]
        if not record then
            return
        end
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
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.PopupActionID, { ActionPlayed = showedActionIdList }, function(res)
            if cb then
                cb()
            end
        end)
    end
    --endregion

    --region 特攻角色相关
    --===============
    --获取所有特攻角色列表
    --@return 角色Id列表 (默认索引1是主攻角色)
    --===============
    function XGuildWarManager.GetSpecialRoleList()
        if not SpecialRoleList then
            local tempList = {}
            local roles = XGuildWarConfig.GetSpecialRoles()
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
        if not entityId then
            return nil
        end
        local characterId = 0
        if XRobotManager.CheckIsRobotId(entityId) then
            characterId = XRobotManager.GetCharacterId(entityId)
        else
            characterId = entityId
        end
        local roleCfg = XGuildWarConfig.GetSpecialRole(characterId)
        if not roleCfg then
            return nil
        end
        local fightEventId = roleCfg.FightEventId
        if not fightEventId or (fightEventId == 0) then
            return nil
        end
        local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
        if not cfg then
            return nil
        end
        local buffData = { Icon = cfg.Icon, Name = cfg.Name, Desc = cfg.Description }
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
        if not fightEventId or (fightEventId == 0) then
            return nil
        end
        local cfg = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(fightEventId)
        if not cfg then
            return nil
        end
        local buffData = { Icon = cfg.Icon, Name = cfg.Name, Desc = cfg.Description }
        return buffData
    end
    --根据实体Id检查是否特攻角色
    function XGuildWarManager.CheckIsSpecialRole(entityId)
        if not entityId then
            return false
        end
        local characterId = 0
        if XRobotManager.CheckIsRobotId(entityId) then
            characterId = XRobotManager.GetCharacterId(entityId)
        else
            characterId = entityId
        end
        local roles = XGuildWarConfig.GetSpecialRoles()
        local roleCfg = roles[characterId]
        return roleCfg ~= nil
    end
    --根据实体Id检查是否头牌特攻角色
    function XGuildWarManager.CheckIsCenterSpecialRole(entityId)
        if not entityId then
            return false
        end
        local characterId = 0
        if XRobotManager.CheckIsRobotId(entityId) then
            characterId = XRobotManager.GetCharacterId(entityId)
        else
            characterId = entityId
        end
        local roles = XGuildWarConfig.GetSpecialRoles()
        local spRoleCfg = roles[characterId]
        if spRoleCfg == nil then
            return false
        end
        return spRoleCfg.CenterCharacter == 1
    end
    --获得特攻角色专属图标
    function XGuildWarManager.GetSpecialRoleIcon(entityId)
        if not entityId then
            return false
        end
        local characterId = 0
        if XRobotManager.CheckIsRobotId(entityId) then
            characterId = XRobotManager.GetCharacterId(entityId)
        else
            characterId = entityId
        end
        local roleCfg = XGuildWarConfig.GetSpecialRole(characterId)
        if roleCfg == nil then
            return false
        end
        if roleCfg.CenterCharacter == 1 then
            return XGuildWarConfig.GetClientConfigValues("SpecialRoleIcon1", "string")[1]
        end
        return XGuildWarConfig.GetClientConfigValues("SpecialRoleIcon2", "string")[1]
    end
    --===============
    --根据队伍数据检查是否特攻角色队伍
    --@return CurrentSpecial, MaxNum, IsSpecial
    --CurrentSpecial = (int)当前特攻角色数量
    --MaxNum = (int)激活需要的特攻角色数量
    --IsSpecial = (bool)是否已激活
    --===============
    function XGuildWarManager.CheckIsSpecialTeam(members)
        if not members then
            return false
        end
        local count = 0
        local isSpecialTeam = true
        for _, member in pairs(members) do
            local entityId = member:GetEntityId()
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
        local maxPos = XDataCenter.TeamManager.GetMaxPos()
        return count, maxPos, isSpecialTeam and count == maxPos
    end
    --endregion

    --region 战场节点
    --获取当前轮次的工会战战场节点管理器
    ---@return XGWBattleManager
    function XGuildWarManager.GetBattleManager()
        local round = XGuildWarManager.GetCurrentRound()
        if round then
            return round:GetBattleManager()
        end
        return nil
    end

    --获取节点实例
    ---@return XGWNode
    local function GetNode(nodeId)
        return XGuildWarManager.GetBattleManager():GetNode(nodeId)
    end
    function XGuildWarManager.GetNode(nodeId)
        return GetNode(nodeId)
    end

    --获取节点的奖励ID(有些节点击破后可以获得奖励)
    function XGuildWarManager.GetNodeRewardId(nodeId)
        return GetNode(nodeId):GetRewardId()
    end

    --获取某个节点的成员数量
    function XGuildWarManager.GetNodeMember(nodeId)
        return GetNode(nodeId):GetMemberCount()
    end

    --获取节点扫荡所需要的能量
    function XGuildWarManager.GetNodeSweepCostEnergy(nodeId)
        return GetNode(nodeId):GetSweepCostEnergy()
    end

    --获取节点战斗所需要的能量
    function XGuildWarManager.GetNodeFightCostEnergy(nodeId)
        return GetNode(nodeId):GetFightCostEnergy()
    end

    --获取刚刚通过关卡的节点
    function XGuildWarManager.GetJustPassedNode()
        local stageId = _JustPassedStageId
        _JustPassedStageId = false
        return XGuildWarManager.GetBattleManager():FindNodeByStage(stageId)
    end

    --region 子节点类型代码
    -- 获取某节点的子节点
    function XGuildWarManager.GetChildNode(nodeId, childIndex)
        local id = XGuildWarConfig.GetChildNodeId(nodeId, childIndex)
        local node = GetNode(id)
        return node
    end

    -- 获取子节点血量
    function XGuildWarManager.GetChildHp(nodeId, childIndex)
        local node = XGuildWarManager.GetChildNode(nodeId, childIndex)
        return node:GetHP(), node:GetMaxHP()
    end

    -- 获取子节点是否虚弱
    function XGuildWarManager.IsChildHasWeakness(nodeId, childIndex)
        local nodeId = XGuildWarConfig.GetChildNodeId(nodeId, childIndex)
        return GetNode(nodeId):HasWeakness()
    end

    -- 获取虚弱状态的子节点索引
    function XGuildWarManager.GetWeaknessChildIndex(nodeId)
        local index = 1
        while true do
            local childNodeId = XGuildWarConfig.GetChildNodeId(nodeId, index)
            if childNodeId == nil then
                break ;
            end
            if GetNode(childNodeId):HasWeakness() then
                return index
            end
            index = index + 1
        end
        return 0
    end

    -- 获取子节点是否被击倒
    function XGuildWarManager.IsChildNodeDefeated(nodeId, childIndex)
        local nodeId = XGuildWarConfig.GetChildNodeId(nodeId, childIndex)
        return GetNode(nodeId):GetHP() <= 0
    end
    --endregion

    --播放节点破坏动画？
    function XGuildWarManager.ShowNodeDestroyed(actionGroup, showOverCallback)
        local nodeIdList = {}
        for _, action in pairs(actionGroup or {}) do
            table.insert(nodeIdList, action.NodeId)
        end
        if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
            XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
        end

        local callBackFinish = function()
            XLuaUiManager.SetMask(true, XGuildWarConfig.MASK_KEY)
            showOverCallback()
        end

        local callBackCheck = function()
            local IsKillBoss = false
            for _, nodeId in pairs(nodeIdList or {}) do
                local node = XGuildWarManager.GetBattleManager():GetNode(nodeId)
                if node:GetIsLastNode() and node:GetIsJustDestroyed() then
                    node:SetIsJustDestroyed(false)
                    IsKillBoss = true
                    break
                end
            end

            if IsKillBoss then
                XScheduleManager.ScheduleOnce(function()
                    XLuaUiManager.Open("UiGuildWarBossReaults", callBackFinish)
                end, 1)
            else
                callBackFinish()
            end
        end
        XLuaUiManager.Open("UiGuildWarStageResults", nodeIdList, callBackCheck)
    end
    --endregion

    --region 战斗队伍
    --endregion

    --region 队伍
    local _Team = false --队伍
    function XGuildWarManager.GetTeam()
        if not _Team then
            _Team = require("XEntity/XStronghold/XStrongholdTeam").New(0)
        end
        return _Team
    end
    --endregion

    --region 援助角色
    --region 援助补给
    --获取物资补给是否大于0(感觉是红点用的)
    function XGuildWarManager.IsSupplyMoreThanZero()
        return XGuildWarManager.GetTimeSupply() > 0
                or XGuildWarManager.GetAssistantSupply() > 0
    end
    --领取援助补给
    function XGuildWarManager.ReceiveSupportSupply()
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.ReceiveSupportSupply, {}, function(res)
            if res.Code ~= XCode.Success then
                return
            end
            _DataAssistant = _DataAssistant or {}
            if _DataAssistant then
                _DataAssistant.SupportSupply = 0
            end

            if _DataAssistant.MyAssistRecords then
                local nowTime = XTime.GetServerNowTimestamp()
                for i = 1, #_DataAssistant.MyAssistRecords do
                    local record = _DataAssistant.MyAssistRecords[i]
                    if record.EndTime == 0 then
                        record.EndTime = nowTime
                    end
                end
            end

            --  物品弹窗
            if res.TotalSupply > 0 then
                local rewards = {}
                table.insert(rewards, { TemplateId = XDataCenter.ItemManager.ItemId.GuildWarCoin, Count = res.TotalSupply })
                XUiManager.OpenUiObtain(rewards)
            end

            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE)
            XDataCenter.GuildWarManager.RequestAssistantDetail()
        end)
    end
    --获取时间补给?
    function XGuildWarManager.GetTimeSupply()
        if not _DataAssistant then
            return 0
        end

        local lastRecvTime = _DataAssistant.LastRecvTime or 0
        local nowTime = XTime.GetServerNowTimestamp()
        local totalSupply = 0
        local isMax = false

        local roundToRecvDict = {}
        local countLimit = tonumber(XGuildWarConfig.GetServerConfigValue("AssistTimeSupplyLimit"))

        local getAssistRecords = _DataAssistant.GetAssistRecords
        local receivedRecord = {}
        if getAssistRecords then
            for i = 1, #getAssistRecords do
                local record = getAssistRecords[i]
                receivedRecord[record.RoundId] = record.TimeSupply
            end

            for roundId = 1, Config.ROUND_NUM do
                local lastReceive = receivedRecord[roundId] or 0
                -- 历史记录已经到达上限 && 当前轮
                if lastReceive >= countLimit and roundId == XGuildWarManager.GetCurrentRoundId() then
                    isMax = true
                end
            end
        end

        for i = 1, #(_DataAssistant.MyAssistRecords or {}) do
            local myAssistRecord = _DataAssistant.MyAssistRecords[i]
            for roundId = 1, Config.ROUND_NUM do
                local lastReceive = receivedRecord[roundId] or 0
                local roundCfg = Config.GetCfgByIdKey(
                        Config.TableKey.Round,
                        roundId
                )
                local timeId = roundCfg.TimeId
                local roundStartTime = XFunctionManager.GetStartTimeByTimeId(timeId)
                local roundEndTime = XFunctionManager.GetEndTimeByTimeId(timeId)
                local useTime = CalRoundUseTime(roundStartTime, roundEndTime, myAssistRecord.AssistTime,
                        myAssistRecord.EndTime, lastRecvTime, nowTime)
                if useTime <= 0 then
                    -- continue
                else
                    local duration = 600    -- 配置 "AssistTimeSupply" 对应,每10分钟增加一次,故600秒
                    local minute10 = math.floor(useTime * 1.0 / duration)
                    if minute10 <= 0 then
                        --continue
                    else
                        local add = minute10 * XGuildWarConfig.GetServerConfigValue("AssistTimeSupply")
                        local preSupply = roundToRecvDict[roundId] or 0
                        -- 加之前已经超了
                        if lastReceive + preSupply >= countLimit then
                            if roundId == XGuildWarManager.GetCurrentRoundId() then
                                isMax = true
                            end
                            --continue
                        else
                            -- 把剩余的填上
                            local max = math.min(lastReceive + preSupply + add, countLimit);

                            -- 最大值
                            if max == countLimit and roundId == XGuildWarManager.GetCurrentRoundId() then
                                isMax = true
                            end

                            local toAdd = max - (lastReceive + preSupply);
                            if toAdd <= 0 then
                                --continue
                            else
                                roundToRecvDict[roundId] = preSupply + toAdd;
                            end
                        end
                    end
                end
            end
        end

        for roundId, supply in pairs(roundToRecvDict) do
            totalSupply = totalSupply + supply
        end

        return totalSupply, isMax
    end
    --获取援助补给
    function XGuildWarManager.GetAssistantSupply()
        if not _DataAssistant then
            return 0
        end
        return _DataAssistant.SupportSupply or 0
    end
    -- 援助补给达到最大
    function XGuildWarManager.IsAssistantSupplyMax()
        local roundId = XGuildWarManager.GetCurrentRoundId()

        -- 无效id
        if roundId <= 0 then
            return false
        end

        -- 本轮领过的
        local received = 0
        if _DataAssistant then
            local allRecord = _DataAssistant.GetAssistRecords
            if allRecord then
                for i = 1, #allRecord do
                    local record = allRecord[i]
                    if record.RoundId == roundId then
                        received = record.AssistSupply
                    end
                end
            end
        end

        -- 本轮未领取的
        local toReceived = 0
        if _DataAssistant then
            local allRecord = _DataAssistant.ToAssistRecords
            if allRecord then
                for i = 1, #allRecord do
                    local record = allRecord[i]
                    if record.RoundId == roundId then
                        toReceived = record.AssistSupply
                    end
                end
            end
        end

        return received + toReceived >= tonumber(XGuildWarConfig.GetServerConfigValue("AssistCountSupplyLimit"))
    end
    --endregion

    -- 请求援助界面需要的信息
    function XGuildWarManager.RequestAssistantDetail()
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.AssistantDetail, {}, function(res)
            if res.Code ~= XCode.Success then
                return
            end
            _DataAssistant = res.SupportDetail
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE)
        end)
    end

    --设置援助角色
    function XGuildWarManager.SendAssistant(characterId)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.AssistantSet, {
            CharacterId = characterId
        }, function(res)
            if _DataAssistant then
                _DataAssistant.CharacterId = characterId
            else
                _DataAssistant = {
                    CharacterId = characterId
                }
            end
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE)
        end)
    end

    --取消援助角色
    function XGuildWarManager.CancelAssistant()
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.AssistantCancel, {
            CharacterId = XGuildWarManager.GetAssistantCharacterId()
        }, function(res)
            if res.Code ~= XCode.Success then
                return
            end
            if _DataAssistant then
                _DataAssistant.CharacterId = false
            end
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE)
        end)
    end

    --获取玩家是否派出援助角色
    function XGuildWarManager.HasSendAssistant()
        local characterId = XGuildWarManager.GetAssistantCharacterId()
        return XTool.IsNumberValid(characterId)
    end

    --获取是否派出了支援角色
    function XGuildWarManager.IsSendAssistantCharacter()
        local id = XGuildWarManager.GetAssistantCharacterId()
        return id and id > 0
    end

    --获取援助日志
    function XGuildWarManager.GetAssistantLog()
        if not _DataAssistant then
            return {}
        end
        local dataSource = _DataAssistant.MyLogs or {}
        local invalidIdList = {}
        for i = 1, #dataSource do
            local data = dataSource[i]
            local memberData = XDataCenter.GuildManager.GetMemberDataByPlayerId(data.UserId)
            if not memberData then
                invalidIdList[#invalidIdList + 1] = i
            end
        end
        for i = #invalidIdList, 1, -1 do
            table.remove(dataSource, invalidIdList[i])
        end
        return dataSource
    end

    --获取玩家派出的援助角色ID
    function XGuildWarManager.GetAssistantCharacterId()
        if not _DataAssistant then
            return false
        end
        return _DataAssistant.CharacterId
    end

    --打开选择援助角色界面
    function XGuildWarManager.OpenUiSelectAssistant()
        XLuaUiManager.Open("UiGuildWarCharacter")
    end

    local lastTimeRequestAssistantList = 0
    local IntervalRequestAssistantList = 20
    --请求支援角色列表
    function XGuildWarManager.RequestAssistCharacterList(callback)
        local time = XTime.GetServerNowTimestamp()
        if time - lastTimeRequestAssistantList < IntervalRequestAssistantList then
            XLog.Warning("[XGuildWarManager] 请求支援列表时间间隔过短")
            if callback then
                callback()
            end
            return
        end
        lastTimeRequestAssistantList = time
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.AssistantCharacterList, {}, function(res)
            if res.Code ~= XCode.Success then
                return
            end
            _AssistantCharacterList = res.CharacterList
            for i = 1, #_AssistantCharacterList do
                local data = _AssistantCharacterList[i]
                data.Id = data.PlayerId
            end
            XGuildWarManager.GetBattleManager():GetTeam():KickOutInvalidMembers()
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ASSISTANT_UPDATE_CHARACTER_LIST)
            if callback then
                callback()
            end
        end)
    end

    -- 设置队伍，每次进战斗之前发这条协议，支援角色每次打开编队界面的时候要清掉
    function XGuildWarManager.RequestSetTeam(teamInfo, callback)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.SetTeam, {
            TeamInfo = teamInfo
        }, function(res)
            -- if res.CharacterList then
            --     _AssistantCharacterList = res.CharacterList
            -- end
            if res.Code ~= XCode.Success then
                return
            end
            if callback then
                callback()
            end
        end)
    end

    --获取援助角色列表
    function XGuildWarManager.GetAssistantCharacterList()
        return _AssistantCharacterList or {}
    end

    --打开派送援助角色UI
    function XGuildWarManager.OpenUiSendAssistant()
        local supportData = {
            CanSupportCancel = true,
            HideBtnRecommend = true,
            CheckInSupportCb = function(characterId)
                return XDataCenter.GuildWarManager.GetAssistantCharacterId() == characterId
            end,
            SetCharacterCb = function(characterId)
                XLuaUiManager.Close("UiCharacter")
                XDataCenter.GuildWarManager.SendAssistant(characterId)
                return true
            end,
            CancelCharacterCb = function(characterId)
                XLuaUiManager.Close("UiCharacter")
                XDataCenter.GuildWarManager.CancelAssistant(characterId)
            end,
            --显示高优先级图标
            CheckHighPriority = function(characterId)
                -- 特攻角色
                local isSpecialRole = XDataCenter.GuildWarManager.CheckIsSpecialRole(characterId)
                local icon = false
                if isSpecialRole then
                    icon = XDataCenter.GuildWarManager.GetSpecialRoleIcon(characterId)
                end
                return isSpecialRole, icon
            end
        }
        XLuaUiManager.Open("UiCharacter", nil, nil, nil, nil, nil, nil, supportData)
    end

    --获取援助角色能力
    function XGuildWarManager.GetAssistantCharacterAbility(entityId, playerId)
        local data = XGuildWarManager.GetAssistantCharacterData(entityId, playerId)
        if not data then
            return 0
        end
        return data.FightNpcData.Character.Ability
    end

    --获取援助角色ViewModel
    function XGuildWarManager.GetAssistantCharacterViewModel(entityId, playerId)
        if playerId == XPlayer.Id then
            local character = XDataCenter.CharacterManager.GetCharacter(entityId)
            return character and character:GetCharacterViewModel()
        end
        local data = XGuildWarManager.GetAssistantCharacterData(entityId, playerId)
        if data then
            local XCharacterViewModel = require("XEntity/XCharacter/XCharacterViewModel")
            local characterId = data.FightNpcData.Character.Id
            ---@type XCharacterViewModel
            local characterViewModel = XCharacterViewModel.New(characterId)
            characterViewModel:UpdateByFightNpcData(data.FightNpcData)
            return characterViewModel
        end
        return false
    end

    --获取援助角色数据
    function XGuildWarManager.GetAssistantCharacterData(entityId, playerId)
        for i, data in pairs(_AssistantCharacterList) do
            if playerId == data.PlayerId and entityId == data.FightNpcData.Character.Id then
                return data
            end
        end
    end

    --获取援助角色时装
    function XGuildWarManager.GetAssistantCharacterFashion(entityId, playerId)
        local characterData = XDataCenter.GuildWarManager.GetAssistantCharacterData(entityId, playerId)
        return characterData and characterData.FightNpcData.Character.FashionId
    end

    --获取援助角色解放等级
    function XGuildWarManager.GetAssistantCharacterLiberateLv(entityId, playerId)
        local characterData = XDataCenter.GuildWarManager.GetAssistantCharacterData(entityId, playerId)
        return characterData and characterData.FightNpcData.Character.LiberateLv
    end

    --获取援助角色支援机
    function XGuildWarManager.GetAssistantCharacterPartner(entityId, playerId)
        local data = XGuildWarManager.GetAssistantCharacterData(entityId, playerId)
        if data then
            return data.FightNpcData.Partner and data.FightNpcData.Partner.TemplateId
        end
        return false
    end

    --援助角色是否可用
    function XGuildWarManager.IsAssistantCharacterValid(entityId, playerId)
        local data = XGuildWarManager.GetAssistantCharacterData(entityId, playerId)
        if not data then
            return false
        end
        local isCd = XGuildWarManager.GetCdUsingAssistantCharacter(data) > 0
        if isCd then
            return false
        end
        return true
    end

    --获取使用援助角色的CD
    function XGuildWarManager.GetCdUsingAssistantCharacter(data)
        if not data then
            return 0
        end
        local cd = XGuildWarConfig.GetServerConfigValue("UseAssistCharacterCd")
        local LastUseTime = data.LastUseTime
        return tonumber(cd) - (XTime.GetServerNowTimestamp() - LastUseTime)
    end

    --endregion

    --region 地图行动
    local INF = 0xFFFFFFF
    --迪杰斯特拉(Dijkstra)寻路算法
    local function Dijkstra(start, map, n)
        local dist = {}
        local flag = {}
        local preNode = {}

        for i, v in pairs(map) do
            dist[i] = map[start][i]
            flag[i] = false;
            if dist[i] == INF then
                preNode[i] = -1
            else
                preNode[i] = start
            end
        end

        flag[start] = true
        dist[start] = 0
        for i, v in pairs(map) do
            local temp = INF
            local t = start
            for j, v in pairs(map[i]) do
                if (not flag[j]) and dist[j] < temp then
                    t = j;
                    temp = dist[j]
                end
            end
            if t == start then
                break
            end
            flag[t] = true

            for j, v in pairs(map[i]) do
                if (not flag[j]) and map[t][j] < INF then
                    if (dist[j] > (dist[t] + map[t][j])) then
                        dist[j] = dist[t] + map[t][j]
                        preNode[j] = t
                    end
                end
            end
        end
        return dist
    end

    --获取移动到目标消耗的资源数量
    function XGuildWarManager.GetMoveCost(targetId)
        local nodes = XGuildWarManager.GetBattleManager():GetNodes()
        local n = #nodes

        local map = {}
        for i = 1, n do
            for j = 1, n do
                local node1 = nodes[i]
                local node2 = nodes[j]
                local id1 = node1:GetId()
                local id2 = node2:GetId()
                map[id1] = map[id1] or {}
                map[id1][id2] = INF
            end
        end

        for i = 1, n do
            local node = nodes[i]
            local children = node:GetNextNodes()
            for j = 1, #children do
                local childNode = children[j]
                if node:GetIsDead() or node:GetIsBaseNode()
                        or childNode:GetIsDead() or childNode:GetIsBaseNode()
                then
                    map[node:GetId()][childNode:GetId()] = 1 -- 默认路程为1
                    map[childNode:GetId()][node:GetId()] = 1 -- 默认路程为1
                end
            end
        end

        local currentNodeId = XGuildWarManager.GetBattleManager():GetCurrentNodeId()
        if not map[currentNodeId] then
            XLog.Error("[XGuildWarManager] 当前节点不存在:", currentNodeId)
            return "???"
        end
        local dist = Dijkstra(currentNodeId, map, n)
        local path = dist[targetId] or 0
        return math.floor(path * XGuildWarConfig.GetServerConfigValue("MoveCostEnergy"))
    end
    --endregion

    --region 多区域队伍挑战节点玩法区域 3期隐藏关 (一种带着多个子关卡 并且关卡使用队伍不能重复的玩法 可能未来不叫隐藏关)

    --请求进入关卡
    function XGuildWarManager.RequestEnterAreaTeamStage(childNode)
        local rootNode = childNode:GetParentNode()
        XGuildWarManager.RequestSetAreaTeam(rootNode, function()
            local stageId = childNode:GetStageId()
            local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
            local team = childNode:GetXTeam()
            local teamId = team:GetId()
            local isAssist = team:GetHasAssistant()
            local challengeCount = 1
            --战斗管理器记录战斗节点的UID 供PreFight使用
            XGuildWarManager.GetBattleManager():UpdateCurrentClientBattleInfo(childNode:GetUID(), childNode:GetStutesType())
            XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount, nil, nil, nil)
        end)
    end
    --请求设置多区域节点玩法区域队伍
    --param teamDataList:List<XGuildWarProto.XGuildWarTeamInfo>
    function XGuildWarManager.RequestSetAreaTeam(rootNode, callback)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.SetAreaTeam, {
            TeamInfos = rootNode:GetXGuildWarTeamInfos(), },
                function(res)
                    if res.Code == XCode.Success then
                        if callback then
                            callback()
                        end
                        return
                    end
                    if res.code == XCode.GuildWarAssistCharacterCountError
                            or res.code == XCode.GuildWarSameCharacterError
                            or res.code == XCode.GuildWarAssistCharacterCd then
                        XGuildWarManager.RequestAssistCharacterList()
                    end
                    return
                end
        )
    end
    --请求重置多区域节点玩法区域分数
    function XGuildWarManager.RequestResetAreaTeamScore(childNode)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.ResetAreaTeamScore, {
            NodeId = childNode:GetId(), },
                function(res)
                    if res.Code == XCode.Success then
                        XGuildWarManager.GetBattleManager():ResetAreaTeamNodeCurPoint(childNode:GetId())
                        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_SECRETNODE_RESET)
                    end
                end
        )
    end
    --请求上传多区域节点玩法分数
    function XGuildWarManager.RequestUploadAreaScore(rootNode)
        --因为第三期暂时只有仅有一个多区域节点
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.UploadAreaScore, {},
                function(res)
                    if res.Code == XCode.Success then
                        local children = rootNode:GetChildrenNodes()
                        for index, childNode in ipairs(children) do
                            XGuildWarManager.GetBattleManager():UploadAreaTeamNodeRecord(childNode:GetId())
                        end
                        XUiManager.TipMsg(CS.XTextManager.GetText("GuildWarTeamAreaUploadSuccess"))
                        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_SECRETNODE_RESET)
                    end
                end
        )
    end
    --设置子节点分数（关卡打完后 自己通过结算数据设置分数和队伍）
    function XGuildWarManager.SetAndLockAreaScore(node, score)
        --构建一个跟后端数据一样格式的数据 XGuildWarTeamInfo(C#)
        local xGuildWarTeamInfo = node:GetXGuildWarTeamInfo()
        xGuildWarTeamInfo.CurPoint = score
        XGuildWarManager.GetBattleManager():UpdateAreaTeamNodeInfos({ xGuildWarTeamInfo }, {})
    end
    --endregion

    --region 战斗 副本相关
    --处理轮次结算通知
    function XGuildWarManager.OnNotifyGuildWarRoundSettle(data)
        if XUiManager.CheckTopUi(CsXUiType.Normal, "UiGuildWarStageMain")
                or XUiManager.CheckTopUi(CsXUiType.Normal, "UiGuildMain") then
            XGuildWarManager.RequestPopup()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ROUND_END)
    end

    --region 体力
    --检查是否有足够活动体力
    function XGuildWarManager.CheckEnoughActionPoint(actionPoint)
        return ActionPoint >= actionPoint
    end
    --获取当前活动体力值
    function XGuildWarManager.GetCurrentActionPoint()
        return ActionPoint
    end
    --扣除活动体力
    function XGuildWarManager.CostActionPoint(costPoint)
        if not XGuildWarManager.CheckEnoughActionPoint(costPoint) then
            XUiManager.TipText("GuildWarActionPointNotEnough")
            return
        end
        ActionPoint = ActionPoint - costPoint
    end
    --获取活动体力最大值
    function XGuildWarManager.GetMaxActionPoint()
        return tonumber(XGuildWarConfig.GetServerConfigValue("MaxEnergy"))
    end
    --endregion

    --===============
    --扫荡关卡
    --@param cb: function 回调
    --===============
    function XGuildWarManager.StageSweep(uid, sweepType, stageId, cb)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.StageSweep, { Uid = uid, SweepType = sweepType
        , StageId = stageId }, function(res)
            if cb then
                cb()
            end
        end)
    end

    --===============
    --确认战斗
    --@param cb: function 回调
    --===============
    function XGuildWarManager.ConfirmFight(stageId, cb)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.ConfirmFight, { StageId = stageId }, function(res)
            if cb then
                cb()
            end
        end)
    end

    --region 副本接口
    --初始化副本数据
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
    --获取战斗预处理数据(FubenManager调用)
    function XGuildWarManager.PreFight(stage, teamId, isAssist, challengeCount, challengeId)
        local xTeam = XDataCenter.TeamManager.GetXTeam(teamId)
        local cardIds = { 0, 0, 0 }
        local robotIds = { 0, 0, 0 }
        for pos, entityId in ipairs(xTeam:GetEntityIds()) do
            cardIds[pos] = entityId
        end
        local result = {
            StageId = stage.StageId,
            IsHasAssist = isAssist,
            ChallengeCount = challengeCount,
            CaptainPos = xTeam:GetCaptainPos(),
            FirstFightPos = xTeam:GetFirstFightPos(),
            CardIds = cardIds,
            RobotIds = robotIds,
        }
        result.GuildWarUid = XGuildWarManager.GetBattleManager():GetCurrentClientBattleUID()
        return result
    end
    --结束战斗 结算(FubenManager调用)
    function XGuildWarManager.FinishFight(settle, ...)
        XDataCenter.FubenManager.FinishFight(settle, ...)
        XGuildWarManager.SetJustPassedStage(settle.StageId)
    end

    --刚刚通过的关卡ID 标志位
    function XGuildWarManager.SetJustPassedStage(stageId)
        _JustPassedStageId = stageId
    end
    --战斗胜利显示奖励接口(FubenManager调用)
    function XGuildWarManager.ShowReward(winData, playEndStory)
        local result = winData.SettleData.GuildWarFightResult
        if not (result.NodeId == 0) then
            local battleManager = XGuildWarManager.GetBattleManager()
            local node = battleManager:GetNode(result.NodeId)
            if node:GetNodeType() == XGuildWarConfig.NodeType.Term3SecretChild then
                XGuildWarManager.SetAndLockAreaScore(node, result.Point)
            end
        end
        XLuaUiManager.Open("UiSettleWinCommon", winData, require("XUi/XUiGuildWar/XUiGuildWarSettleWin"))
    end
    --endregion
    --endregion

    --===============
    --获取活动信息
    --@param cb: function 回调
    --===============
    function XGuildWarManager.RequestPlayerMove(targetNodeId, cb)
        local cost = tonumber(XGuildWarConfig.GetServerConfigValue("MoveCostEnergy"))
        if not XEntityHelper.CheckItemCountIsEnough(XGuildWarConfig.ActivityPointItemId, cost) then
            return
        end
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.PlayerMove, {
            CurNodeId = XGuildWarManager.GetBattleManager():GetCurrentNodeId(),
            NextNodeId = targetNodeId,
        }, function(res)
            XGuildWarManager.GetBattleManager():UpdateNodeDatas(res.NodeDatas)
            XGuildWarManager.GetBattleManager():UpdateCurrentNodeId(targetNodeId)
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_PLAYER_MOVE)
            if cb then
                cb()
            end
        end)
    end

    -- 活动已开, 第一轮未开始, 可以选择难度
    function XGuildWarManager.IsOnPreselectionStage()
        local nowTime = XTime.GetServerNowTimestamp()
        local activityTime = XDataCenter.GuildWarManager.GetActivityStartTime()
        local roundStartTime = XDataCenter.GuildWarManager.GetRoundStartTime()
        return nowTime < roundStartTime and roundStartTime > activityTime
    end

    --打开公会战争主界面UI(有个叫打开难度回调的参数？)
    function XGuildWarManager.OpenUiGuildWarMain(openDifficultyFunc)
        if XGuildWarManager.IsOnPreselectionStage() then
            XLuaUiManager.Open("UiGuildWarSelect")
            return
        end
        local currentRoundId = XGuildWarManager.GetCurrentRoundId()
        if currentRoundId == 1 then
            local now = XTime.GetServerNowTimestamp()
            local roundStartTime = XGuildWarManager.GetRoundStartTime()
            if now < roundStartTime then
                XUiManager.TipText("GuildWarNoInRound")
                return
            end
        end
        if XGuildWarManager.CheckIsGuildSkipRound() then
            XUiManager.TipText("GuildWarIsSkip")
            return
        end
        XDataCenter.GuildWarManager.GetActivityData(function()
            local haveSelectDifficulty = XDataCenter.GuildWarManager.CheckHaveDifficultySelected()
            if not haveSelectDifficulty then
                if openDifficultyFunc then
                    openDifficultyFunc()
                end
                return
            end
            -- 可能是由于服务端请求1分钟cd问题, 导致无数据, 也可能skipRound的判断出错, 加上容错处理
            if not XGuildWarManager.GetBattleManager() then
                XUiManager.TipText("GuildWarIsSkip")
                return
            end
            XLuaUiManager.Open("UiGuildWarStageMain")
        end)
    end

    ---@param node XTerm4BossGWNode
    function XGuildWarManager.RequestReceiveBossReward(rewardId, nodeUid)
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.ReceiveBossReward, {
            Id = rewardId,
            NodeUid = nodeUid,
        }, function(res)
            if res.Code ~= XCode.Success then
                return
            end
            XGuildWarManager.GetBattleManager():AddRewardReceived(rewardId)
            if res.RewardGoodsList and #res.RewardGoodsList > 0 then
                XUiManager.OpenUiObtain(res.RewardGoodsList)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_BOSS_REWARD)
        end)
    end

    function XGuildWarManager.OnEnterUiGuild()
        if XDataCenter.GuildWarManager.CheckActivityIsInTime() then
            XDataCenter.GuildWarManager.GetActivityData(function()
                XDataCenter.GuildWarManager.RequestPopup()
            end)
        end
    end
    
    function XGuildWarManager.IsShowRedPointBossReward()
        local battleManager = XGuildWarManager.GetBattleManager()
        if not battleManager then
            return false
        end
        ---@type XGWNode
        local node = battleManager:GetNodeBossRoot()
        if not node then
            return false
        end
        local configs = XGuildWarConfig.GetBossReward(node:GetDifficultyId())
        if not configs then
            return false
        end
        local isShowRedPoint = false
        for i = 1, #configs do
            local config = configs[i]
            local id = config.Id
            if not battleManager:IsRewardReceived(id)
                    and XGuildWarConfig.IsBossRewardCanReceive(node, config)
            then
                isShowRedPoint = true
                break
            end
        end
        return isShowRedPoint
    end

    XGuildWarManager.Init()
    return XGuildWarManager
end
--============
--登陆数据通知
--============
XRpc.NotifyGuildWarActivityData = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    XDataCenter.GuildWarManager.OnNotifyActivityData(data)
end
--============
--轮次结算通知
--============
XRpc.NotifyGuildWarRoundSettle = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    XDataCenter.GuildWarManager.OnNotifyGuildWarRoundSettle(data)
end
--============
--通知客户端，战斗记录有刷新
--============
XRpc.NotifyGuildWarFightRecordChange = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateFightRecords(data.FightRecords)
end
--============
--通知客户端，活动数据有刷新(8点)
--============
XRpc.NotifyGuildWarActivityDataChange = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    XDataCenter.GuildWarManager.RefreshActivityData(data.ActivityData)
end
--============
--通知客户端，新事件发生
--============
XRpc.NotifyGuildWarAction = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    local battleManager = XDataCenter.GuildWarManager.GetBattleManager()
    battleManager:AddActionList(data.ActionList)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTIONLIST_CHANGE, data.ActionList)
end
--============
--通知客户端，节点数据更新
--============
XRpc.NotifyGuildWarNodeUpdate = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateNodeData(data.NodeData)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE)
end
--============
--通知客户端，怪物数据更新
--============
XRpc.NotifyGuildWarMonsterUpdate = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateMonsterData(data.MonsterData)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_MONSTER_CHANGE)
end

XRpc.NotifyGuildWarBossLevelUp = function(data)
    if XGuildWarConfig.CLOSE_DEBUG then
        return
    end
    XDataCenter.GuildWarManager.GetBattleManager():UpdateNodeData(data.NodeData)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_NODEDATA_CHANGE)
end