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
    }

    local LastSyncGuildRankListTime = 0   --工会总分排行榜List最后刷新时间
    local LastSyncRankListTime = 0   --内部排行榜List最后刷新时间
    local LastSyncStageInfoTime = 0   --关卡详细信息最后刷新时间

    local SYNC_RANK_LIST_SECOND = 60        --获取排行榜List请求保护时间

    ---- local function begin -----
    local function RegisterEditBattleProxy()
        if IsRegisterEditBattleProxy then return end
        IsRegisterEditBattleProxy = true
        XUiNewRoomSingleProxy.RegisterProxy(XDataCenter.FubenManager.StageType.GuildBoss,
                require("XUi/XUiGuildBoss/XUiGuildBossNewRoomSingle"))
    end

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

        RegisterEditBattleProxy()
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
    
    --获取已领取的积分宝箱id
    function XGuildBossManager.GetScoreBoxGot()
        return GuildBossInfoData.ScoreBoxGot
    end

    --获取已领取的血量奖励id
    function XGuildBossManager.GetHpBoxGot()
        return GuildBossInfoData.HpBoxGot
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
    --Set End

    --other
    function XGuildBossManager.GetHpRewardId(id)
        local hpRewardData = XGuildBossConfig.HpRewards()
        local now = XTime.GetServerNowTimestamp()
        return now > GuildBossNewRewardTime and hpRewardData[id].NewRewardId or hpRewardData[id].RewardId
    end

    function XGuildBossManager.GetScoreRewardId(id)
        local rewardData = XGuildBossConfig.ScoreRewards()
        local now = XTime.GetServerNowTimestamp()
        return now > GuildBossNewRewardTime and rewardData[id].NewRewardId or rewardData[id].RewardId
    end
    
    --更新是否有奖励可领
    function XGuildBossManager.UpdateReward()
        --bossHp宝箱
        local hpRewardData = XGuildBossConfig.HpRewards()
        local curBossHpPercent = GuildBossInfoData.HpLeft / GuildBossInfoData.HpMax * 100
        if GuildBossInfoData.HpBoxGot >= #hpRewardData then
            HasBossHpReward = false
        else
            if curBossHpPercent <= hpRewardData[GuildBossInfoData.HpBoxGot + 1].HpPercent then
                HasBossHpReward = true
            else
                HasBossHpReward = false
            end
        end
        --积分宝箱
        HasScoreReward = false
        local myTotalScore = XGuildBossManager.GetMyTotalScore()
        local scoreBoxGot = GuildBossInfoData.ScoreBoxGot
        local rewardData = XGuildBossConfig.ScoreRewards()
        for i = 1, #rewardData do
            local isGet = false
            for _,val in pairs(scoreBoxGot) do
                if val == rewardData[i].Id then
                    isGet = true
                    break
                end
            end
            if myTotalScore >= rewardData[i].Score and not isGet then
                HasScoreReward = true
            end
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

    function XGuildBossManager.GetKilledBossLv()
        return KilledBossLv or "??"
    end
    --boss hp tip end

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

    function XGuildBossManager.GuildBossActivityRequest(cb, isForce)
        -- 请求间隔保护
        if not isForce then
            local now = XTime.GetServerNowTimestamp()
            if LastSyncStageInfoTime + SYNC_RANK_LIST_SECOND >= now then
                if cb then
                    cb()
                end
                return
            end
            LastSyncStageInfoTime = now
        end
        XNetwork.Call(GuildBossRpc.GuildBossActivityRequest, {}, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            GuildBossInfoData.ActivityId = res.ActivityId
            GuildBossInfoData.ScoreSumBest = res.GuildScoreSumBest
            GuildBossInfoData.HpMax = res.HpMax
            GuildBossInfoData.HpLeft = res.HpLeft
            XGuildBossManager.LocalBossHpLog()
            GuildBossInfoData.TotalScore = res.GuildScoreSum
            GuildBossInfoData.BossLevel = res.BossLevel
            GuildBossInfoData.BossLevelNext = res.BossLevelNext
            GuildBossInfoData.ScoreBoxGot = res.ScoreBoxGot
            GuildBossInfoData.HpBoxGot = res.HpBoxGot --已领取的血量奖励id
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
            table.insert(GuildBossInfoData.ScoreBoxGot, id)
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
            GuildBossInfoData.HpBoxGot = id
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
    --Request End

    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, Init)
    return XGuildBossManager
end

return XGuildBossManagerCreator