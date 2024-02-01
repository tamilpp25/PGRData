XAutoFightManagerCreator = function()
    local tableremove = table.remove
    local tableinsert = table.insert

    local AutoFightManager = {}


    local METHOD_NAME = {
        StartAutoFight = "StartAutoFightRequest",
        ObtainAutoFightRewards = "ObtainAutoFightRewardsRequest",
        StartNewAutoFight = "SweepRequest",
    }

    AutoFightManager.State = {
        None = 0,
        Fighting = 1,
        Complete = 2
    }

    local Records = {}
    local RecordLookup

    --local timer
    --local updateInterval = XScheduleManager.SECOND

    local BeginData


    function AutoFightManager.GetRecordCount()
        return #Records
    end

    -- local function CreateTimer()
    --     timer = XScheduleManager.ScheduleForever(function()
    --         local now = XTime.GetServerNowTimestamp()
    --         local cnt = 0
    --         for _, v in pairs(Records) do
    --             if now >= v.CompleteTime then
    --                 cnt = cnt + 1
    --             end
    --         end
    --         XEventManager.DispatchEvent(XEventId.EVENT_AUTO_FIGHT_CHANGE, cnt)
    --     end, updateInterval)
    -- end

    -- local RemoveTimer
    -- RemoveTimer = function()
    --     if timer then
    --         XScheduleManager.UnSchedule(timer)
    --     end
    --     XEventManager.RemoveEventListener(XEventId.EVENT_USER_LOGOUT, RemoveTimer)
    --     XEventManager.RemoveEventListener(XEventId.EVENT_NETWORK_DISCONNECT, RemoveTimer)
    -- end

    local function UpdateRecords(records)
        Records = records
        RecordLookup = {}
        for _, v in pairs(Records) do
            RecordLookup[v.StageId] = v
        end
    end

    --(records) --NotifyLogin
     function AutoFightManager.InitAutoFightData(records)
        UpdateRecords(records)
        -- CreateTimer()
        -- XEventManager.AddEventListener(XEventId.EVENT_USER_LOGOUT, RemoveTimer)
        -- XEventManager.AddEventListener(XEventId.EVENT_NETWORK_DISCONNECT, RemoveTimer)
    end

    function AutoFightManager.CheckAutoFightAvailable(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if not stageCfg or stageCfg.AutoFightId <= 0 then
            return XCode.FubenManagerAutoFightStageInvalid
        end

        local stageData = XDataCenter.FubenManager.GetStageData(stageId)
        if not stageData then
            return XCode.FubenManagerAutoFightStageInvalid
        end

        return XCode.Success
    end

    --(stageId, times, cb(res = {Code, Record}))
    function AutoFightManager.StartAutoFight(stageId, times, cb)
        XNetwork.Call(METHOD_NAME.StartAutoFight, { StageId = stageId, Times = times }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            tableinsert(Records, res.Record)
            RecordLookup[res.Record.StageId] = res.Record
            XEventManager.DispatchEvent(XEventId.EVENT_AUTO_FIGHT_START, stageId)

            if cb then
                cb(res)
            end
        end)
    end

    --2.10:新增log参数用于失败时的log输出
    function AutoFightManager.StartNewAutoFight(stageId, count, cb,openLog)
        XNetwork.Call(METHOD_NAME.StartNewAutoFight, { StageId = stageId, Count = count }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                if openLog then
                    --内部会输出最大挑战次数的计算过程log
                    XLog.Error('-------->自动挑战失败，关卡Id:'..stageId..' 挑战次数:'..count..' 输出客户端计算的最大次数挑战计算情况：')
                    XDataCenter.FubenManager.GetStageMaxChallengeCount(stageId,true)
                end
                return
            end

            XEventManager.DispatchEvent(XEventId.EVENT_AUTO_FIGHT_START, stageId)

            if cb then
                cb(res)
            end
        end)
    end

    function AutoFightManager.GetRecords()
        return Records
    end

    --(index, cb(res = {Code, TeamExp, CharacterExp, Rewards}))
    function AutoFightManager.ObtainRewards(index, cb)
        local record = Records[index]
        if not record then
            XUiManager.TipCode(XCode.FubenManagerAutoFightIndexInvalid)
            return
        end

        local stageId = record.StageId

        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local cardIds = record.CardIds
        local hasRobot = false
        if stageCfg.RobotId and #stageCfg.RobotId > 0 then
            hasRobot = true
            cardIds = {}
            for _, v in pairs(stageCfg.RobotId) do
                local charId = XRobotManager.GetCharacterId(v)
                tableinsert(cardIds, charId)
            end
        end

        XNetwork.Call(METHOD_NAME.ObtainAutoFightRewards, { Index = index - 1, StageId = stageId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            tableremove(Records, index)
            RecordLookup[stageId] = nil

            XEventManager.DispatchEvent(XEventId.EVENT_AUTO_FIGHT_REMOVE, stageId)

            if hasRobot then
                res.CharacterExp = 0
            end

            if cb then
                cb(res)
            end

            XLuaUiManager.Open("UiAutoFightReward", cardIds, res)
        end)
    end

    function AutoFightManager.GetRecordByStageId(stageId)
        return RecordLookup and RecordLookup[stageId]
    end

    function AutoFightManager.GetIndexByStageId(stageId)
        for k, v in pairs(Records) do
            if v.StageId == stageId then
                return k
            end
        end
        return 0
    end

    function AutoFightManager.GetAutoFightBeginData()
        return BeginData
    end

    function AutoFightManager.RecordFightBeginData(stageId, times, cardIds)
        BeginData = {
            CharExp = {},
            RoleLevel = XPlayer.GetLevelOrHonorLevel(),
            RoleExp = XPlayer.Exp,
            StageId = stageId,
            Times = times,
        }

        for _, charId in pairs(cardIds) do
            local char = XMVCA.XCharacter:GetCharacter(charId)
            if char ~= nil then
                table.insert(BeginData.CharExp, { Id = charId, Quality = char.Quality, Exp = char.Exp, Level = char.Level })
            end
        end
    end

    function AutoFightManager.CheckOpenDialog(stageId, stage)
        local maxChallengeNum = XDataCenter.FubenManager.GetStageMaxChallengeNums(stageId)
        local stageData = XDataCenter.FubenManager.GetStageData(stageId)
        if maxChallengeNum > 0 then
            local chanllengedNum = 0
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo.Type == XDataCenter.FubenManager.StageType.Prequel then
                local info = XDataCenter.PrequelManager.GetUnlockChallengeStagesByStageId(stageId)
                if info then
                    chanllengedNum = info.Count
                end
            else
                chanllengedNum = stageData and stageData.PassTimesToday or 0
            end

            maxChallengeNum = maxChallengeNum - chanllengedNum
            if maxChallengeNum <= 0 then
                local msg = CS.XTextManager.GetText("FubenChallengeCountNotEnough")
                XUiManager.TipMsg(msg)
                return
            end
        end
        XLuaUiManager.Open("UiAutoFightEnter", stageId, stage)
    end

    return AutoFightManager
end