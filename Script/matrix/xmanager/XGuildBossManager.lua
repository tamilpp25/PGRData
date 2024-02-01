XGuildBossManagerCreator = function()
    local XGuildBossManager = {}
    --保存boss血量，活动时间，总分等相关信息
    local GuildBossInfoData = {}
    --保存关卡信息
    local GuildBossLevelData = {}
    --保存排行榜相关信息
    --local GuildBossRankData = {}
    --boss死后所增加的分数
    local GuildBossDeathAddScore = CS.XGame.Config:GetInt("GuildBossDeathAddScore")
    local GuildBossStageAddBuffPoint = CS.XGame.Config:GetInt("GuildBossStageAddBuffPoint")--激活安稳度所需要的次数
    --关卡数量（不包含boss）
    local GuildBossStageCount = 7
    --是否需要刷新选关页面数据
    local NeedUpdateStageInfo = false
    --本次战斗消减boss血量
    local CurFightBossHp = 0
    --本次战斗获得贡献值
    local CurFightContribute = 0
    --是否有Boss血量宝箱可以领
    local HasBossHpReward = false
    --是否有积分宝箱可以领
    local HasScoreReward = false
    --是否是从工会页面进入（用于判断是否要在本地记录boss血量）
    local IsFirstEnter = false
    --当前所选关卡的类型，用于选人页面保存不同的队伍
    local CurSelectStageType = nil
    --周长任务刷新时间
    local GuildBossWeeklyTaskTime = nil
    local GuildBossNewRewardTime = CS.XGame.Config:GetInt("GuildBossNewRewardDate") --新奖励切换显示时间
    --公会boss血量降为0
    local IsBossDead = nil
    local BossDeadEndTime = nil -- 记录hp状态需要用活动结束时间一并记录，防止第二次boss被击败不弹出提示
    local NeedShowBossDeadTip = false
    local KilledBossLv = 0
    local IsRegisterEditBattleProxy = false

    local GuildBossRpc = {
        GuildBossInfoRequest = "GuildBossInfoRequest",                          --公会boss主界面信息请求
        GuildBossPlayerRankRequest = "GuildBossPlayerRankRequest",              --公会boss成员排行
        GuildBossGuildRankRequest = "GuildBossGuildRankRequest",                --公会boss全服排行
        GuildBossActivityRequest = "GuildBossActivityRequest",                  --活动挑战情况
        GuildBossStageRequest = "GuildBossStageRequest",                        --请求单个关卡的挑战情况
        GuildBossPlayerStageRankRequest = "GuildBossPlayerStageRankRequest",    --请求单个关卡的排行榜
        GuildBossScoreBoxRequest = "GuildBossScoreBoxRequest",                  --领取积分奖励宝箱
        GuildBossHpBoxRequest = "GuildBossHpBoxRequest",                        --领取boss血量奖励
        GuildBossLevelRequest = "GuildBossLevelRequest",                        --设置下期的boss难度等级
        GuildBossSetOrderRequest = "GuildBossSetOrderRequest",                  --设置公会boss的战术指挥
        GuildBossUploadRequest = "GuildBossUploadRequest",                      --战斗结束确认上传分数
        GuildBossGetAllBossRewardRequest = "GuildBossGetAllBossRewardRequest",  --一键领取Boss血量奖励和积分奖励
    }

    local LastSyncGuildRankListTime = 0   --工会总分排行榜List最后刷新时间
    local LastSyncRankListTime = 0   --内部排行榜List最后刷新时间
    local LastSyncStageInfoTime = 0   --关卡详细信息最后刷新时间

    local SYNC_RANK_LIST_SECOND = 60        --获取排行榜List请求保护时间

    ---- local function begin -----
    local function Init()
        -- 初始化hp的持久化记录
        local hpStr = CS.UnityEngine.PlayerPrefs.GetString(XGuildBossManager.GetBossDeadTipKey(), "")

        if hpStr ~= "" then
            local strs = string.Split(hpStr, "|")
            local endTime = tonumber(strs[1]) or -1
            local oldHp = tonumber(strs[2]) or -1
            if oldHp ~= -1 then
                IsBossDead = (oldHp <= 0)
                if IsBossDead and endTime ~= -1 then
                    BossDeadEndTime = tonumber(endTime)
                end
            end
        end
    end
    
    local function List2FlagTab(originList, targetList)
        originList = originList or {}
        if XTool.IsTableEmpty(targetList) then
            return originList
        end
        for _, target in pairs(targetList) do
            originList[target] = true
        end
        return originList
    end
    ---- local function end -----
    --Get Begin
    --获取boss血量上限
    function XGuildBossManager.GetMaxBossHp()
        return GuildBossInfoData.HpMax
    end

    --获取boss当前血量
    function XGuildBossManager.GetCurBossHp()
        return GuildBossInfoData.HpLeft
    end

    --获取挑战记录
    function XGuildBossManager.GetLogs()
        return GuildBossInfoData.Logs
    end

    --获取剩余时间
    function XGuildBossManager.GetEndTime()
        return GuildBossInfoData.EndTime
    end
    
    --获取工会总分数
    function XGuildBossManager.GetTotalScore()
        return GuildBossInfoData.TotalScore
    end

    --获取关卡信息
    function XGuildBossManager.GetLevelData()
        return GuildBossLevelData
    end

    --获取关卡信息
    function XGuildBossManager.GetLevelDataByStageId(stageId)
        for i = 1, #GuildBossLevelData do
            if GuildBossLevelData[i].StageId == stageId then
                return GuildBossLevelData[i]
            end
        end
        return nil
    end

    --获取历史最高工会总分
    function XGuildBossManager.GetScoreSumBest()
        return GuildBossInfoData.ScoreSumBest
    end

    --获取当前工会boss等级
    function XGuildBossManager.GetCurBossLevel()
        return GuildBossInfoData.BossLevel
    end
    
    --获取下期工会boss等级
    function XGuildBossManager.GetNextBossLevel()
        return GuildBossInfoData.BossLevelNext
    end

    --获取低浓度区的关卡信息
    function XGuildBossManager.GetLowLevelInfo()
        for i = 1, #GuildBossLevelData do
            if GuildBossLevelData[i].Type == GuildBossLevelType.Low and GuildBossLevelData[i].Score > 0 then
                return GuildBossLevelData[i]
            end
        end
        return nil
    end

    --获取高浓度区的关卡信息
    function XGuildBossManager.GetHighLevelInfo()
        for i = 1, #GuildBossLevelData do
            if GuildBossLevelData[i].Type == GuildBossLevelType.High and GuildBossLevelData[i].Score > 0 then
                return GuildBossLevelData[i]
            end
        end
        return nil
    end

    --获取boss关卡信息
    function XGuildBossManager.GetBossLevelInfo()
        for i = 1, #GuildBossLevelData do
            if GuildBossLevelData[i].Type == GuildBossLevelType.Boss then
                return GuildBossLevelData[i]
            end
        end
    end

    --获取本期低浓度区分
    function XGuildBossManager.GetLowScore()
        for i = 1, #GuildBossLevelData do
            if GuildBossLevelData[i].Type == GuildBossLevelType.Low and GuildBossLevelData[i].Score > 0 then
                return GuildBossLevelData[i].Score
            end
        end
        return 0
    end

    --获取本期高浓度区分
    function XGuildBossManager.GetHighScore()
        for i = 1, #GuildBossLevelData do
            if GuildBossLevelData[i].Type == GuildBossLevelType.High and GuildBossLevelData[i].Score > 0 then
                return GuildBossLevelData[i].Score
            end
        end
        return 0
    end

    --获取本期boss分
    function XGuildBossManager.GetBossScore()
        for i = 1, #GuildBossLevelData do
            if GuildBossLevelData[i].Type == GuildBossLevelType.Boss and GuildBossLevelData[i].Score > 0 then
                return GuildBossLevelData[i].Score
            end
        end
        return 0
    end

    --获取本期我的总分
    function XGuildBossManager.GetMyTotalScore()
        local sumScore = 0
        for i = 1, #GuildBossLevelData do
            sumScore = sumScore + GuildBossLevelData[i].Score
        end
        if GuildBossInfoData.HpLeft == 0 and sumScore > 0 then
            sumScore = sumScore + GuildBossDeathAddScore
        end
        return sumScore
    end

    --获取斩杀boss的额外分数
    function XGuildBossManager.GetAdditionalScore()
        return GuildBossDeathAddScore
    end

    --获取满安稳值所需挑战次数
    function XGuildBossManager.GuildBossStageAddBuffPoint()
        return GuildBossStageAddBuffPoint
    end
    
    function XGuildBossManager.IsScoreRewardReceive(id)
        local rec = GuildBossInfoData.ScoreBoxGot[id]
        return rec and true or false
    end
    
    function XGuildBossManager.GetMaxBossHpGot()
        local max = 0
        for id, _ in pairs(GuildBossInfoData.HpBoxGot or {}) do
            max = math.max(id, max)
        end
        return max
    end
    
    function XGuildBossManager.IsHpRewardReceived(id)
        local rec = GuildBossInfoData.HpBoxGot[id]
        return rec and true or false
    end
    
    function XGuildBossManager.IsHpRewardAllReceived()
        local rewards = XGuildBossConfig.HpRewards()
        for _, reward in pairs(rewards or {}) do
            if not XGuildBossManager.IsHpRewardReceived(reward.Id) then
                return false
            end
        end
        
        return true
    end
    
    --获取可以领取的最小奖励Id, 没有则获取最大未领取。全领取则获取最大Id
    function XGuildBossManager.GetMinReceivedId()
        local rewards = XGuildBossConfig.HpRewards() or {}
        local rewardIds = {}
        local curBossHpPercent = GuildBossInfoData.HpLeft / GuildBossInfoData.HpMax * 100
        for _, reward in pairs(rewards) do
            --可领取但未领取
            if reward.HpPercent >= curBossHpPercent 
                    and not XGuildBossManager.IsHpRewardReceived(reward.Id) then
                table.insert(rewardIds, reward.Id)
            end
        end
        if XTool.IsTableEmpty(rewardIds) then
            local id = XGuildBossManager.GetMaxBossHpGot()
            return XGuildBossManager.IsHpRewardAllReceived() and id or id + 1
        end
        if #rewardIds == 1 then
            return rewardIds[1]
        end
        table.sort(rewardIds, function(a, b) 
            return a < b
        end)
        return rewardIds[1]
    end
    
    function XGuildBossManager.ProcessTaskList(hook)
        XGuildBossManager.GuildBossActivityRequest(function()
            local taskList = XGuildBossConfig.GetTaskList()
            local bossScore = XDataCenter.GuildBossManager.GetMyTotalScore()

            local leftHp = XGuildBossManager.GetCurBossHp()
            local maxHp = XGuildBossManager.GetMaxBossHp()
            local leftPercent = math.ceil( leftHp / maxHp * 100)

            for _, task in ipairs(taskList or {}) do
                local taskType = task.TaskType
                if taskType == GuildTaskType.BossScore then
                    task.RewardId = XDataCenter.GuildBossManager.GetScoreRewardId(task.TaskId)
                elseif taskType == GuildTaskType.BossHp then
                    task.RewardId = XDataCenter.GuildBossManager.GetHpRewardId(task.TaskId)
                end
                task.State = GuildBossRewardType.Disable
                if task.TaskType == GuildTaskType.BossScore then
                    task.Value = bossScore
                    if bossScore >= task.Target then
                        local received = XGuildBossManager.IsScoreRewardReceive(task.TaskId)
                        task.State = received and GuildBossRewardType.Acquired or GuildBossRewardType.Available
                    end
                elseif task.TaskType == GuildTaskType.BossHp then
                    task.Value = leftPercent
                    if leftPercent <= task.Target then
                        local received = XGuildBossManager.IsHpRewardReceived(task.TaskId)
                        task.State = received
                                and GuildBossRewardType.Acquired or GuildBossRewardType.Available
                    end
                end
            end

            local SortByState = {
                [GuildBossRewardType.Acquired] = 1,
                [GuildBossRewardType.Disable] = 100,
                [GuildBossRewardType.Available] = 10000,
            }

            table.sort(taskList, function(taskA, taskB)
                local stateA = SortByState[taskA.State]
                local stateB = SortByState[taskB.State]
                if stateA ~= stateB then
                    return stateA > stateB
                end
                if taskA.GroupId ~= taskB.GroupId then
                    return taskA.GroupId < taskB.GroupId
                end
                return taskA.TaskId < taskB.TaskId
            end)

            if hook then hook(taskList) end
        end, nil, function()
            if hook then hook({}) end
        end)
    end

    --获取当前关卡的战术布局顺序
    --function XGuildBossManager.GetOrderString()
    --    local orderString = ""
    --    for i = 1, GuildBossStageCount do
    --        orderString = orderString .. tostring(GuildBossLevelData[i].Order)
    --    end
    --    return orderString
    --end

    --获取关卡在数据中的位置
    function XGuildBossManager.GetStageDataPos(data)
        for i = 1, GuildBossStageCount do
            if GuildBossLevelData[i].StageId == data.StageId then
                return i
            end
        end
        return -1
    end

    function XGuildBossManager.GetStageCount()
        return GuildBossStageCount
    end

    --得到某一关限制使用的robotID
    function XGuildBossManager.GetStageRobotTab(stageId)
        for i = 1, #GuildBossLevelData do
            if GuildBossLevelData[i].StageId == stageId then
                for j = 1, #GuildBossInfoData.RobotList do
                    if GuildBossInfoData.RobotList[j].Type == GuildBossLevelData[i].Type then
                        return GuildBossInfoData.RobotList[j].RobotIds
                    end
                end
            end
        end
        return nil
    end

    --获取工会前五
    --function XGuildBossManager.GetGuildBossTopFive()
    --    return GuildBossInfoData.TopFive
    --end

    --获取我的排名信息
    function XGuildBossManager.GetMyRankData()
        return GuildBossInfoData.MyRank
    end

    --获取我的排名名次信息
    function XGuildBossManager.GetMyRankNum()
        return GuildBossInfoData.MyRankNum
    end

    --获取工会的排名信息
    function XGuildBossManager.GetMyGuildRankData()
        return GuildBossInfoData.MyGuildRankData
    end

    --获取工会的排名名次信息
    function XGuildBossManager.GetMyGuildRankNum()
        return GuildBossInfoData.MyGuildRankNum
    end

    --获取工会排名
    function XGuildBossManager.GetAllGuildRankList()
        return GuildBossInfoData.AllGuildRankList
    end

    --获取工会内排名
    function XGuildBossManager.GetAllRankList()
        return GuildBossInfoData.AllRankList
    end

    --点击关卡的时候获取该关卡的详细信息
    function XGuildBossManager.GetDetailLevelData(stageId)
        return GuildBossInfoData.DetailLevelData[stageId]
    end

    --获取某关卡的排行榜
    function XGuildBossManager.GetDetailLevelRankData(stageId)
        return GuildBossInfoData.DetailLevelRankData[stageId]
    end

    --获取log版本号
    function XGuildBossManager.GetLogId()
        local logId = 0
        if GuildBossInfoData.Logs ~= nil then
            for i = 1, #GuildBossInfoData.Logs do
                if GuildBossInfoData.Logs[i].LogId > logId then
                    logId = GuildBossInfoData.Logs[i].LogId
                end
            end
        end
        return logId
    end

    --本次战斗消减boss血量
    function XGuildBossManager.GetCurFightBossHp()
        return CurFightBossHp
    end
    
    --本次战斗贡献值
    function XGuildBossManager.GetCurFightContribute()
        return CurFightContribute
    end

    --获取活动版本号
    function XGuildBossManager.GetActivityId()
        return GuildBossInfoData.ActivityId
    end

    --获取当前所选关卡类型
    function XGuildBossManager.GetCurSelectStageType()
        return CurSelectStageType
    end

    --获取周长任务刷新时间
    function XGuildBossManager.GetWeeklyTaskTime()
        return GuildBossWeeklyTaskTime
    end

    --获取风格信息
    function XGuildBossManager.GetFightStyle()
        return GuildBossInfoData.FightStyle
    end
    --Get End

    --Set Begin
    --设置优先顺序(GuildBossLevelData.Order) orderData = "1234123"
    --function XGuildBossManager.SetOrderData(orderData)
    --    --检查合法性
    --    if orderData == nil or string.len(orderData) ~= GuildBossStageCount then
    --        for i = 1, GuildBossStageCount do
    --            GuildBossLevelData[i].Order = 0
    --        end
    --        return
    --    end
    --    for i = 1, GuildBossStageCount do
    --        GuildBossLevelData[i].Order = tonumber(orderData[i])
    --    end
    --end

    --是否需要刷新
    function XGuildBossManager.SetNeedUpdateStageInfo(isNeed)
        NeedUpdateStageInfo = isNeed
    end

    --本次战斗消减boss血量
    function XGuildBossManager.SetCurFightBossHp(hp)
        CurFightBossHp = hp
    end

    --设置是否有Boss血量宝箱可以领
    function XGuildBossManager.SetBossHpReward(val)
        HasBossHpReward = val
    end

    --设置是否有积分宝箱可以领
    function XGuildBossManager.SetScoreReward(val)
        HasScoreReward = val
    end

    --设置是否是从工会页面进入
    function XGuildBossManager.SetFirstEnterMark(val)
        IsFirstEnter = val
    end

    --设置当前所选关卡类型
    function XGuildBossManager.SetCurSelectStageType(type)
        CurSelectStageType = type
    end

    --设置周长任务刷新时间
    function XGuildBossManager.SetGuildBossWeeklyTaskTime(time)
        GuildBossWeeklyTaskTime = time
    end

    -- 设置风格详情
    function XGuildBossManager.SetFightStyle(fightStyle)
        GuildBossInfoData.FightStyle = fightStyle
    end

    --Set End

    --other
    function XGuildBossManager.GetHpRewardId(id)
        local hpRewardData = XGuildBossConfig.HpRewards()
        local cfg = hpRewardData[id]
        local timeId = cfg.TimeId
        return XFunctionManager.CheckInTimeByTimeId(timeId) and hpRewardData[id].NewRewardId or hpRewardData[id].RewardId
    end

    function XGuildBossManager.GetScoreRewardId(id)
        local rewardData = XGuildBossConfig.ScoreRewards()
        local cfg = rewardData[id]
        local timeId = cfg.TimeId
        return XFunctionManager.CheckInTimeByTimeId(timeId) and rewardData[id].NewRewardId or rewardData[id].RewardId
    end
    
    --更新是否有奖励可领
    function XGuildBossManager.UpdateReward()
        --bossHp宝箱
        local hpRewardData = XGuildBossConfig.HpRewards()
        local curBossHpPercent = GuildBossInfoData.HpLeft / GuildBossInfoData.HpMax * 100
        local maxHpGotId = XGuildBossManager.GetMaxBossHpGot()
        if maxHpGotId >= #hpRewardData then
            HasBossHpReward = false
        else
            if curBossHpPercent <= hpRewardData[maxHpGotId + 1].HpPercent then
                HasBossHpReward = true
            else
                HasBossHpReward = false
            end
        end
        --积分宝箱
        HasScoreReward = false
        local myTotalScore = XGuildBossManager.GetMyTotalScore()
        local rewardData = XGuildBossConfig.ScoreRewards()
        for i = 1, #rewardData do
            local isGet = false
            local data = rewardData[i]
            --if XFunctionManager.CheckInTimeByTimeId(data.TimeId) then
            isGet = XGuildBossManager.IsScoreRewardReceive(data.Id)
            if myTotalScore >= data.Score and not isGet then
                HasScoreReward = true
            end
            --end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDBOSS_HPBOX_CHANGED)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDBOSS_SCOREBOX_CHANGED)
    end

    --如果被踢了或者其他需要清除缓存日志的情况
    function XGuildBossManager.ClearLog()
        GuildBossInfoData.Logs = nil
    end

    --如果被踢了或者其他需要清除奖励信息
    function XGuildBossManager.ClearReward()
        HasBossHpReward = false
        HasScoreReward = false
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDBOSS_HPBOX_CHANGED)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDBOSS_SCOREBOX_CHANGED)
    end

    function XGuildBossManager.UpdateLog(newActivityId, logs)
        --log
        if GuildBossInfoData.ActivityId then
            if GuildBossInfoData.ActivityId ~= newActivityId then
                GuildBossInfoData.Logs = logs
            else
                if logs then
                    if GuildBossInfoData.Logs == nil then
                        GuildBossInfoData.Logs = logs
                    else
                        for i = 1, #logs do
                            table.insert(GuildBossInfoData.Logs, logs[i])
                        end
                    end
                end
            end
        else
            GuildBossInfoData.Logs = logs
        end

        --清除离开公会的成员的日志
        local allMemberList = XDataCenter.GuildManager.GetMemberList()
        for k, data in pairs(GuildBossInfoData.Logs) do
            if not allMemberList[data.PlayerId] then
                table.remove(GuildBossInfoData.Logs, k)
            end
        end
    end

    --是否需要刷新
    function XGuildBossManager.IsNeedUpdateStageInfo()
        return NeedUpdateStageInfo
    end

    --是否有奖励可以领
    function XGuildBossManager.IsReward()
        return HasBossHpReward or HasScoreReward
    end

    --是否有Boss血量宝箱可以领
    function XGuildBossManager.IsBossHpReward()
        return HasBossHpReward
    end

    --是否有积分宝箱可以领
    function XGuildBossManager.IsScoreReward()
        return HasScoreReward
    end

    --是否是核心技能
    function XGuildBossManager.IsCoreStyleSkill(id)
        local allSkill = XGuildBossConfig.GetGuildBossFightStyleSkill() 
        local config = allSkill[id]
        return config and config.IsCore and config.IsCore > 0
    end

    --本地记录当前BossHp，用于显示不在期间其他人造成的伤害
    function XGuildBossManager.LocalBossHpLog()
        local curHp = GuildBossInfoData.HpLeft
        local curActivity = GuildBossInfoData.ActivityId
        local logHp = XSaveTool.GetData("GuildBossHp" .. XPlayer.Id)
        local logActivity = XSaveTool.GetData("GuildBossActivity" .. XPlayer.Id)
        if logHp and logActivity and logActivity == curActivity and tonumber(logHp) > curHp and IsFirstEnter then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildBossHpNote", tonumber(logHp) - curHp))
        else
            IsFirstEnter = false
        end
        XSaveTool.SaveData("GuildBossHp" .. XPlayer.Id, curHp)
        XSaveTool.SaveData("GuildBossActivity" .. XPlayer.Id, curActivity)
    end

    function XGuildBossManager.ParseRankName(rank)
        if rank >= 1 then
            return (math.modf(rank))
        elseif rank == 0 then
            return ""
        else
            local rankNum = math.modf(rank * 100)
            return rankNum .. "%"
        end
        return ""
    end
    --other end

    --boss hp tip
    function XGuildBossManager.GetBossDeadTipKey()
        return "BossDeadTip" .. XPlayer.Id
    end

    function XGuildBossManager.UpdateGuildBossHp(hp, bossLv)
        if NeedShowBossDeadTip then
            return
        end
        local isDead = (hp <= 0)
        
        if IsBossDead == isDead then
            return
        end
        
        
        local endTime = XDataCenter.GuildManager.GuildBossEndTime()
        if not endTime then
            XLog.Error("初始化[boss被击败]的本地信息失败 endTime = nil, 需确保NotifyGuildData下发时间早于该接口调用")
            return
        end
        
        if endTime == BossDeadEndTime then
            return
        end

        IsBossDead = isDead
        
        if isDead then
            BossDeadEndTime = endTime
            KilledBossLv = bossLv
        else
            BossDeadEndTime = false
        end
        local saveStr = endTime .. "|" .. (isDead and "0" or "1")
        CS.UnityEngine.PlayerPrefs.SetString(XGuildBossManager.GetBossDeadTipKey(), saveStr)

        if isDead and not XLuaUiManager.IsUiShow("UiGuildBossStage") and not XLuaUiManager.IsUiShow("UiGuildBossHall")  then
            NeedShowBossDeadTip = true
            -- XGuildBossManager.CheckShowTip()
        end
    end

    function XGuildBossManager.CheckShowTip()
        if not NeedShowBossDeadTip then
            return false
        end
        if CS.XFight.IsRunning then
            return false
        end
        NeedShowBossDeadTip = false
        XLuaUiManager.Open("UiGuildBossTip")
        return true
    end

    -- 判断是否是固定机器人 nzwjV3
    function XGuildBossManager.CheckIsGuildFixedRobot(charaId)
        return XGuildBossConfig.GetAllRegularRobot()[charaId]
    end

    function XGuildBossManager.GetKilledBossLv()
        return KilledBossLv or "??"
    end
    --boss hp tip end

    -- [初始化数据]
    function XGuildBossManager.InitStageInfo()
        local stages = XGuildBossConfig.GetBossStageInfos()
        for _, v in pairs(stages) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(v.Id)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.GuildBoss
            end
        end
    end

    function XGuildBossManager.PreFight(stage, teamId)
        local preFight = {}
        local curTeam = XDataCenter.TeamManager.GetPlayerTeamData(teamId)
        preFight.CardIds = {}
        preFight.StageId = stage.StageId
        preFight.CaptainPos = curTeam.CaptainPos
        preFight.FirstFightPos = curTeam.FirstFightPos
        preFight.RobotIds = {}
        for _, v in pairs(curTeam.TeamData or {}) do
            if not XRobotManager.CheckIsRobotId(v) then
                table.insert(preFight.CardIds, v)
                table.insert(preFight.RobotIds, 0)
            else
                table.insert(preFight.CardIds, 0)
                table.insert(preFight.RobotIds, v)
            end
        end
        return preFight
    end
    --Fight
    function XGuildBossManager.FinishFight(settle)
        if settle.IsWin then
            XLuaUiManager.Open("UiGuildBossFightResult", settle)
        else
            XLuaUiManager.Open("UiSettleLose", settle)
        end
    end
    --Fight End

    --Request Begin
    --公会boss主界面信息请求
    function XGuildBossManager.GuildBossInfoRequest(cb)
        XNetwork.Call(GuildBossRpc.GuildBossInfoRequest, {LogId = XGuildBossManager.GetLogId()}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
           
            XGuildBossManager.UpdateLog(res.ActivityId, res.Logs)
            GuildBossInfoData.ActivityId = res.ActivityId
            GuildBossInfoData.HpMax = res.HpMax
            GuildBossInfoData.HpLeft = res.HpLeft
            XGuildBossManager.LocalBossHpLog()
            GuildBossInfoData.EndTime = res.EndTime
            XDataCenter.GuildManager.SetGuildBossEndTime(res.EndTime) --更新入口处的倒计时
            GuildBossInfoData.MyRank = res.MyRank
            GuildBossInfoData.MyRankNum = res.MyRankNum
            --GuildBossInfoData.TopFive = res.TopFive
            GuildBossInfoData.TotalScore = res.TotalScore
            
            if GuildBossInfoData.MyRank.RankLevel == 0 then
                GuildBossInfoData.MyRank.Name = XPlayer.Name
                GuildBossInfoData.MyRank.Id = XPlayer.Id
                GuildBossInfoData.MyRank.RankLevel = XDataCenter.GuildManager.GetCurRankLevel()
                GuildBossInfoData.MyRank.HeadPortraitId = XPlayer.CurrHeadPortraitId
                GuildBossInfoData.MyRank.HeadFrameId = XPlayer.CurrHeadFrameId
            end

            if cb then
                cb()
            end
            NeedShowBossDeadTip = false
        end)
    end
    
    function XGuildBossManager.ReqOpenGuildBossHall()
        local isInTime = XFunctionManager.CheckInTimeByTimeId(CS.XGame.Config:GetInt("GuildBossTempBanTimeId"))
        if isInTime then
            XUiManager.TipError(CS.XTextManager.GetText("GuildBossOpenLimit"))
            return
        end
        XDataCenter.GuildBossManager.GuildBossInfoRequest(function() XLuaUiManager.Open("UiGuildBossHall") end)
    end

    -- 打开工会boss之前先请求服务端 不能直接通过UiManager打开
    function XGuildBossManager.OpenGuildBossHall()
        if not XDataCenter.GuildManager.IsInitGuildData() then
            XDataCenter.GuildManager.GetGuildDetails(0, XGuildBossManager.ReqOpenGuildBossHall)
        else
            XGuildBossManager.ReqOpenGuildBossHall()
        end
    end
    
    --Test Debug
    function XGuildBossManager.GuildBossTestDamageRequest(stageId, score)
        XNetwork.Call("GuildBossTestDamageRequest", {ActivityId = GuildBossInfoData.ActivityId, StageId = stageId, Score = score, CardIds = {1,2,3}}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            if cb then
                cb()
            end
        end)
    end
    --Test End

    function XGuildBossManager.GuildBossActivityRequest(cb, isForce, errorCb)
        -- 请求间隔保护
        local now = XTime.GetServerNowTimestamp()
        if not isForce then
            if LastSyncStageInfoTime + SYNC_RANK_LIST_SECOND >= now then
                if cb then
                    cb()
                end
                return
            end
        end
        XNetwork.Call(GuildBossRpc.GuildBossActivityRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if errorCb then errorCb() end
                return
            end
            LastSyncStageInfoTime = now
            GuildBossInfoData.ActivityId = res.ActivityId
            GuildBossInfoData.ScoreSumBest = res.GuildScoreSumBest
            GuildBossInfoData.HpMax = res.HpMax
            GuildBossInfoData.HpLeft = res.HpLeft
            XGuildBossManager.LocalBossHpLog()
            GuildBossInfoData.TotalScore = res.GuildScoreSum
            GuildBossInfoData.BossLevel = res.BossLevel
            GuildBossInfoData.BossLevelNext = res.BossLevelNext
            GuildBossInfoData.ScoreBoxGot = List2FlagTab(GuildBossInfoData.ScoreBoxGot, res.ScoreBoxGot)
            GuildBossInfoData.HpBoxGot = List2FlagTab(GuildBossInfoData.HpBoxGot, res.HpBoxGotNew) 
            GuildBossInfoData.RobotList = res.RobotList  --每类关卡限制的robotId
            GuildBossLevelData = res.BossList
            for i = 1, #GuildBossLevelData do
                if string.len(res.Order) < GuildBossStageCount then
                    GuildBossLevelData[i].Order = 0
                else
                    GuildBossLevelData[i].Order = tonumber(string.sub(res.Order, i, i))
                end
                if GuildBossLevelData[i].Type == GuildBossLevelType.High then
                    GuildBossLevelData[i].NameOrder = i - 4
                else
                    GuildBossLevelData[i].NameOrder = i
                end
            end
            XGuildBossManager.UpdateReward()
            
            if cb then
                cb()
            end
            NeedShowBossDeadTip = false
        end)
    end

    -- 激活或卸载风格技能
    function XGuildBossManager.GuildBossStyleSkillChangeRequeset(operType, skillId, cb)
        -- 向服务器请求激活技能
        XNetwork.Call("GuildSelectFightStyleSkillRequest", {OperType = operType, SkillId = skillId}, function(reply)
            if reply.Code ~= XCode.Success then
                XUiManager.TipCode(reply.Code)
                return
            end

            if cb then
                cb()
            end
            -- 改变后再请求一次风格信息并刷新
            XDataCenter.GuildBossManager.GuildBossStyleInfoRequest(function ()
                XEventManager.DispatchEvent(XEventId.EVENT_GUILDBOSS_STYLE_CHANGED) --刷新当前查看的风格的信息
            end)
            
        end)
       
    end

    function XGuildBossManager.GuildBossStyleInfoRequest(cb)
        -- 向服务器请求风格信息 再打开
        XNetwork.Call("GuildFightStyleRequest", nil, function(reply)
            if reply.Code ~= XCode.Success then
                XUiManager.TipCode(reply.Code)
                return
            end

            XGuildBossManager.SetFightStyle(reply.FightStyle)
            if cb then
                cb()
            end
        end)
    end
    
    function XGuildBossManager.GuildBossLevelRequest(level, cb)
        XNetwork.Call(GuildBossRpc.GuildBossLevelRequest, {BossLevelNext = level, ActivityId = GuildBossInfoData.ActivityId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            GuildBossInfoData.BossLevelNext = level
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDBOSS_UPDATEDIFF)

            if cb then
                cb()
            end
        end)
    end

    function XGuildBossManager.GuildBossScoreBoxRequest(id, cb)
        XNetwork.Call(GuildBossRpc.GuildBossScoreBoxRequest, {BoxId = id}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XUiManager.OpenUiObtain(res.RewardGoods)
            GuildBossInfoData.ScoreBoxGot = List2FlagTab(GuildBossInfoData.ScoreBoxGot, { id })
            XGuildBossManager.UpdateReward()

            if cb then
                cb()
            end
        end)
    end

    function XGuildBossManager.GuildBossHpBoxRequest(id, cb)
        XNetwork.Call(GuildBossRpc.GuildBossHpBoxRequest, {BoxId = id}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XUiManager.OpenUiObtain(res.RewardGoods)
            GuildBossInfoData.HpBoxGot = List2FlagTab(GuildBossInfoData.HpBoxGot, { id })
            XGuildBossManager.UpdateReward()

            if cb then
                cb()
            end
        end)
    end

    function XGuildBossManager.GuildBossSetOrderRequest(data, cb)
        XNetwork.Call(GuildBossRpc.GuildBossSetOrderRequest, {Order = data, ActivityId = GuildBossInfoData.ActivityId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            for i = 1, #GuildBossLevelData do
                GuildBossLevelData[i].Order = tonumber(string.sub(data, i, i))
                if GuildBossLevelData[i].Type == GuildBossLevelType.High then
                    GuildBossLevelData[i].NameOrder = i - 4
                else
                    GuildBossLevelData[i].NameOrder = i
                end
            end
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDBOSS_UPDATEORDER)
            
            if cb then
                cb()
            end
        end)
    end

    function XGuildBossManager.GuildBossUploadRequest(stageId, cb)
        XNetwork.Call(GuildBossRpc.GuildBossUploadRequest, {StageId = stageId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            CurFightBossHp = res.SubHp
            CurFightContribute = res.Contribute

            if cb then
                cb()
            end
        end)
    end

    function XGuildBossManager.GuildBossGuildRankRequest(cb)
        -- 请求间隔保护
        local now = XTime.GetServerNowTimestamp()
        if LastSyncGuildRankListTime + SYNC_RANK_LIST_SECOND >= now then
            if cb then
                cb()
            end
            return false
        end
        LastSyncGuildRankListTime = now
        XNetwork.Call(GuildBossRpc.GuildBossGuildRankRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            GuildBossInfoData.AllGuildRankList = res.RankList
            GuildBossInfoData.MyGuildRankData = res.MyRank
            GuildBossInfoData.MyGuildRankNum = res.MyRankNum

            if cb then
                cb()
            end
        end)
        return true
    end

    function XGuildBossManager.GuildBossPlayerRankRequest(cb, immediate)
        -- 请求间隔保护
        local now = XTime.GetServerNowTimestamp()
        if not immediate and LastSyncRankListTime + SYNC_RANK_LIST_SECOND >= now then
            if cb then
                cb()
            end
            return
        end
        LastSyncRankListTime = now
        XNetwork.Call(GuildBossRpc.GuildBossPlayerRankRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            GuildBossInfoData.AllRankList = res.RankList

            if cb then
                cb()
            end
        end)
    end

    function XGuildBossManager.GuildBossStageRequest(stageId, cb)
        XNetwork.Call(GuildBossRpc.GuildBossStageRequest, {StageId = stageId , LogId = XGuildBossManager.GetLogId()}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            XGuildBossManager.UpdateLog(GuildBossInfoData.ActivityId, res.Logs)
            if GuildBossInfoData.DetailLevelData == nil then
                GuildBossInfoData.DetailLevelData = {}
            end
            GuildBossInfoData.DetailLevelData[stageId] = res
            if cb then
                cb()
            end
        end)
    end

    function XGuildBossManager.GuildBossPlayerStageRankRequest(stageId, cb)
        XNetwork.Call(GuildBossRpc.GuildBossPlayerStageRankRequest, {StageId = stageId}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            
            if GuildBossInfoData.DetailLevelRankData == nil then
                GuildBossInfoData.DetailLevelRankData = {}
            end
            GuildBossInfoData.DetailLevelRankData[stageId] = res.RankList

            if cb then
                cb()
            end
        end)
    end
    
    function XGuildBossManager.GuildBossGetAllBossRewardRequest(cb)
        
        XNetwork.Call(GuildBossRpc.GuildBossGetAllBossRewardRequest, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            XUiManager.OpenUiObtain(res.RewardGoods)
            GuildBossInfoData.HpBoxGot = List2FlagTab(GuildBossInfoData.HpBoxGot, res.BossHpId)
            GuildBossInfoData.ScoreBoxGot = List2FlagTab(GuildBossInfoData.ScoreBoxGot, res.BossScoreId)
            XGuildBossManager.UpdateReward()

            if cb then cb() end
        end)
    end
    --Request End

    function XGuildBossManager.GetXTeamByStageId(stageId)
        local typeId
        local type = XDataCenter.GuildBossManager.GetCurSelectStageType()
        if type == GuildBossLevelType.Low then
            typeId = CS.XGame.Config:GetInt("TypeIdGuildBossLow")
        elseif type == GuildBossLevelType.High then
            typeId = CS.XGame.Config:GetInt("TypeIdGuildBossHigh")
        elseif type == GuildBossLevelType.Boss then
            typeId = CS.XGame.Config:GetInt("TypeIdGuildBossBoss")
        end
        local robotList = XDataCenter.GuildBossManager.GetStageRobotTab(stageId)
        --所有合法的角色ID
        local characterList = {}
        for i = 1, #robotList do
            table.insert(characterList, XRobotManager.GetCharacterId(robotList[i]))
            table.insert(characterList, robotList[i])
        end
    
        local curTeam = XDataCenter.TeamManager.GetPlayerTeam(typeId)
        --清除不符合规则的
        for i = 1, #curTeam.TeamData do
            if curTeam.TeamData[i] > 0 then
                local isOk = false
                for j = 1, #characterList do
                    if curTeam.TeamData[i] == characterList[j] then
                        isOk = true
                        break
                    end
                end
                if not isOk then
                    curTeam.TeamData[i] = 0
                end
            end
        end
        
        local xTeam = XDataCenter.TeamManager.GetXTeamByTypeId(typeId)
        xTeam:UpdateFromTeamData(curTeam)
        xTeam:UpdateSaveCallback(function(inTeam)
            XDataCenter.TeamManager.RequestSaveTeam(inTeam)
            XDataCenter.TeamManager.SetPlayerTeamLocal(inTeam:SwithToOldTeamData(), nil, nil, false)
        end)

        return xTeam
    end

    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, Init)
    return XGuildBossManager
end

return XGuildBossManagerCreator