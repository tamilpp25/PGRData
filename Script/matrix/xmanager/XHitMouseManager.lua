--===================
--2022年元旦预热小游戏打地鼠活动
--===================
XHitMouseManagerCreator = function()
    local HitMouseManager = {}

    local ActivityId

    local function GetActivityConfig()
        if not ActivityId or (ActivityId <= 0) then return end
        return XHitMouseConfigs.GetCfgByIdKey(
            XHitMouseConfigs.TableKey.Activity,
            ActivityId
        )
    end

    local StageScores
    --================
    --已接受奖励的下标，注意后端接受的下标从0开始，要+1处理
    --================
    local RewardIndexReceived
    --================
    --请求协议名称
    --================
    local REQUEST_NAMES = { --请求名称
        StageUnlock = "HitMouseUnlockRequest",
        GameFinish = "FinishHitMouseRequest",
        GetRewards = "HitMouseGetAwardRequest",
    }

    --=====================================
    --临时Test方法 Start
    --=====================================
    function HitMouseManager.TestStageUnlock()
        HitMouseManager.StageUnlock(2)
    end

    function HitMouseManager.TestGameFinish()
        HitMouseManager.GameFinish(2, 0)
    end

    function HitMouseManager.TestGetRewards()
        HitMouseManager.GetRewards()
    end
    --=====================================
    --临时Test方法 End
    --=====================================
    function HitMouseManager.Init()
        ActivityId = nil
        StageScores = {}
        RewardIndexReceived = {}
    end

    function HitMouseManager.InitData(data)
        if data.ActivityId == 0 then
            if ActivityId and ActivityId > 0 then
                XEventManager.DispatchEvent(XEventId.EVENT_HIT_MOUSE_ACTIVITY_END)
            end
            ActivityId = nil
            return
        end
        ActivityId = data.ActivityId
        for _, stageScoreData in pairs(data.LevelScores or {}) do
            --stageScoreData = { int StageId; int Scores}
            StageScores[stageScoreData.StageId] = stageScoreData.Scores
        end
        for _, rewardIndex in pairs(data.GetRewardIndex or {}) do
            RewardIndexReceived[rewardIndex + 1] = true
        end
    end

    function HitMouseManager.GetGameConfig()
        if not ActivityId then
            return
        end
        local cfg = XHitMouseConfigs.GetCfgByIdKey(
            XHitMouseConfigs.TableKey.Game,
            ActivityId
        )
        return cfg
    end
    --==============
    --获取关卡列表
    --==============
    function HitMouseManager.GetStageCfgs()
        if not ActivityId then
            return {}
        end
        return XHitMouseConfigs.GetCfgByIdKey(
            XHitMouseConfigs.TableKey.Activity2Stage,
            ActivityId
        )
    end
    --==============
    --获取小游戏规则标题和规则描述
    --==============
    function HitMouseManager.GetRuleText()
        if not ActivityId then
            return "NoData", "NoData"
        end
        local config = HitMouseManager.GetGameConfig()
        return config and config.RuleTitle, config and config.RuleText
    end

    function HitMouseManager.GetComboSizeDic()
        if not ActivityId then
            return "NoData", "NoData"
        end
        local config = HitMouseManager.GetGameConfig()
        local dic = {}
        for index, textNum in pairs(config.ComboTextNum or {}) do
            table.insert(dic,
                {
                    Count = textNum,
                    Size = config.ComboTextSize and config.ComboTextSize[index]
                }
            )
        end
        return dic
    end

    function HitMouseManager.GetStartEffect()
        if not ActivityId then
            return
        end
        local config = HitMouseManager.GetGameConfig()
        return config and config.StartEffect
    end
    --==============
    --获取小游戏地鼠坑位数量
    --==============
    function HitMouseManager.GetMoleMaxNum()
        if not ActivityId then
            return 0
        end
        local config = HitMouseManager.GetGameConfig()
        return config and config.MoleNum
    end
    --==============
    --获取小游戏奖励Id列表
    --==============
    function HitMouseManager.GetRewardIds()
        if not ActivityId then
            return {}
        end
        local config = GetActivityConfig()
        return config and config.RewardIds or {}
    end
    --==============
    --获取小游戏奖励分数列表
    --==============
    function HitMouseManager.GetRewardScores()
        if not ActivityId then
            return {}
        end
        local config = GetActivityConfig()
        return config and config.RewardScores or {}
    end
    --==============
    --获取小游戏现在获得的合计分数
    --==============
    function HitMouseManager.GetCurrentScores()
        local total = 0
        for _, score in pairs(StageScores) do
            total = total + score
        end
        return total
    end
    --==============
    --获取小游戏关卡获得的分数
    --==============
    function HitMouseManager.GetStageScore(stageId)
        return StageScores[stageId] or 0
    end
    --==============
    --检查小游戏关卡是否已解锁
    --@param stageId:关卡Id
    --==============
    function HitMouseManager.CheckStageUnlock(stageId)
        local activityConfig = GetActivityConfig()
        if not activityConfig then return end
        local haveUnlock = StageScores[stageId] ~= nil
        return haveUnlock
    end
    --==============
    --检查小游戏前置关卡是否已解锁
    --@param stageId:关卡Id
    --==============
    function HitMouseManager.CheckPreStageUnlock(stageId)
        local cfg = XHitMouseConfigs.GetCfgByIdKey(
            XHitMouseConfigs.TableKey.Stage,
            stageId
        )
        if not cfg then return false end
        if cfg.PreStageId == 0 then return true end
        return HitMouseManager.CheckStageUnlock(cfg.PreStageId)
    end

    function HitMouseManager.CheckPreStageClear(stageId)
        local cfg = XHitMouseConfigs.GetCfgByIdKey(
            XHitMouseConfigs.TableKey.Stage,
            stageId
        )
        if not cfg then return false end
        if cfg.PreStageId == 0 then return true end
        return StageScores[cfg.PreStageId] and StageScores[cfg.PreStageId] > 0
    end
    --==============
    --获取解锁关卡的道具Id
    --==============
    function HitMouseManager.GetUnlockItemId()
        local cfg = GetActivityConfig()
        return cfg and cfg.UseItem or 0
    end
    --==============
    --检查小游戏奖励是否已领取
    --@param index:奖励序号
    --==============
    function HitMouseManager.CheckRewardIsGet(index)
        return RewardIndexReceived[index]
    end
    --==============
    --检查小游戏奖励是否可领取
    --@param index:奖励序号
    --==============
    function HitMouseManager.CheckRewardCanGet(index)
        local currentScore = HitMouseManager.GetCurrentScores()
        local scores = HitMouseManager.GetRewardScores()
        local score = scores[index] or 0
        return (currentScore >= score) and (not HitMouseManager.CheckRewardIsGet(index))
    end
    --=====================================
    --请求协议 Start
    --=====================================
    --=================
    --进入关卡时请求
    --@param stageId:关卡Id
    --@param callBack:回调
    --=================
    function HitMouseManager.StageUnlock(stageId, callBack)
        if StageScores[stageId] ~= nil then return end
        XNetwork.Call(REQUEST_NAMES.StageUnlock,
            { StageId = stageId },
            function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                StageScores[stageId] = 0
                if callBack then callBack() end
            end)
    end
    --=================
    --结束关卡时请求
    --@param stageId:关卡Id
    --@param score:分数
    --@param callBack:回调
    --=================
    function HitMouseManager.GameFinish(stageId, score, callBack)
        XNetwork.Call(REQUEST_NAMES.GameFinish,
            { StageId = stageId, Scores = score },
            function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                if score > StageScores[stageId] then
                    StageScores[stageId] = score
                    XEventManager.DispatchEvent(XEventId.EVENT_HIT_MOUSE_STAGE_REFRESH)
                end
                if callBack then callBack() end
            end)
    end
    --=================
    --领取奖励时请求
    --@param callBack:回调
    --=================
    function HitMouseManager.GetRewards(callBack)
        XNetwork.Call(REQUEST_NAMES.GetRewards,
            {},
            function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                for _, rewardIndex in pairs(reply.GetRewardIndex or {}) do
                    RewardIndexReceived[rewardIndex + 1] = true
                end
                XUiManager.OpenUiObtain(reply.RewardGoods, nil, nil)
                XEventManager.DispatchEvent(XEventId.EVENT_HIT_MOUSE_REWARD_REFRESH)
                if callBack then callBack() end
            end)
    end
    --=====================================
    --请求协议 End
    --=====================================

    --=====================================
    --跳转和活动时间方法集 Start
    --=====================================
    function HitMouseManager.JumpTo()
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.HitMouse) then
            local canGoTo, notStart = HitMouseManager.CheckCanGoTo()
            if canGoTo then
                XLuaUiManager.Open("UiHitMouseMain")
            elseif notStart then
                XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityNotStart"))
            else
                XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
            end
        end
    end
    --===============
    --检查当前活动是否在开放时间内
    --===============
    function HitMouseManager.CheckActivityIsInTime()
        local now = XTime.GetServerNowTimestamp()
        return (now >= HitMouseManager.GetActivityStartTime())
        and (now < HitMouseManager.GetActivityEndTime())
    end
    --===============
    --获取当前活动开始时间戳(根据TimeId)
    --===============
    function HitMouseManager.GetActivityStartTime()
        local Config = GetActivityConfig()
        if not Config then return 0 end
        return XFunctionManager.GetStartTimeByTimeId(Config.TimeId)
    end
    --===============
    --获取当前活动结束时间戳(根据TimeId)
    --===============
    function HitMouseManager.GetActivityEndTime()
        local Config = GetActivityConfig()
        if not Config then return 0 end
        return XFunctionManager.GetEndTimeByTimeId(Config.TimeId)
    end
    --===============
    --获取当前活动剩余时间(秒)
    --===============
    function HitMouseManager.GetActivityLeftTime()
        local now = XTime.GetServerNowTimestamp()
        local endTime = HitMouseManager.GetActivityEndTime()
        local leftTime = endTime - now
        return leftTime
    end
    --================
    --检查是否能进入玩法
    --@return1 :是否在活动时间内(true为在活动时间内)
    --@return2 :是否未开始活动(true为未开始活动)
    --================
    function HitMouseManager.CheckCanGoTo()
        local isActivityEnd, notStart = HitMouseManager.CheckIsEnd()
        return not isActivityEnd, notStart
    end
    --================
    --检查玩法是否关闭(用于判断玩法入口，进入活动条件等)
    --@return1 :玩法是否关闭
    --@return2 :是否活动未开启
    --================
    function HitMouseManager.CheckIsEnd()
        local timeNow = XTime.GetServerNowTimestamp()
        local startTime = HitMouseManager.GetActivityStartTime()
        local endTime = HitMouseManager.GetActivityEndTime()
        local isEnd = timeNow >= endTime
        local isStart = timeNow >= startTime
        local inActivity = (not isEnd) and (isStart)
        return not inActivity, timeNow < startTime
    end
    --================
    --玩法关闭时弹出主界面
    --================
    function HitMouseManager.OnActivityEndHandler()
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(CS.XTextManager.GetText("CommonActivityEnd"))
    end
    --=====================================
    --跳转和活动时间方法集 End
    --=====================================
    HitMouseManager.Init()
    return HitMouseManager
end

XRpc.NotifyHitMouseData = function(data)
    XDataCenter.HitMouseManager.InitData(data)
end