--射击玩法管理器
XMaverickManagerCreator = function()
    local XMaverickConfigs = XMaverickConfigs
    local XMaverickManager = { }
    local CurrentActivity = XMaverickConfigs.GetDefaultActivity() or { }
    local MemberDataInfos = { } --MemberDataInfos和ActiveTalentIds都是以id为key的字典 注意遍历的方式
    local PassStageDataInfos = { } --同上
    --队伍数据
    local Team = {
        TeamData = { }, --就算是空的也不能少
        CaptainPos = 1,
        FirstFightPos = 1,
        -- 0表示仅保存在本地
        TeamId = 0,
        RobotIds = { }, --此玩法唯一真正使用的数据
    }
    --一些常量
    XMaverickManager.SaveKeys = XMaverickConfigs.GetSaveKeys()
    XMaverickManager.LvUpConsumeItemId = XMaverickConfigs.GetLvUpConsumeItemId()
    XMaverickManager.MemberPropertyTypes = XMaverickConfigs.GetMemberPropertyTypes()
    XMaverickManager.StageTypes = XMaverickConfigs.GetStageTypes()
    XMaverickManager.ResultKeys = XMaverickConfigs.GetResultKeys()
    XMaverickManager.CameraTypes = XMaverickConfigs.GetCameraTypes()
    XMaverickManager.RankTopCount = 100

    --================
    --协议名称
    --================
    local REQUEST_NAMES = { --请求名称
        UpgradeMember = "UpgradeMemberMaverickRequest", --角色升级
        ResetMember = "ResetMemberMaverickRequest", --角色重置
        EnableTalent = "EnableTalentMaverickRequest", --启用天赋
        DisableTalent = "DisableTalentMaverickRequest", --禁用天赋
        GetRankList = "MaverickRankingListRequest", --获取排行榜
    }
    
    --将列表转换为字典
    local function ListToDict(list, value)
        local dict = { }
        for _, item in ipairs(list) do
            dict[item] = value or true
        end
        return dict
    end

    --初始化活动数据
    function XMaverickManager.InitData(data)
        CurrentActivity = XMaverickConfigs.GetActivity(data.ActivityId) or CurrentActivity
        XMaverickManager.UpdateStageData(data.PassStageDataInfos)
        XMaverickManager.UpdateMemberData(data.MemberDataInfos)
    end

    --[[
    ================
    获取玩法开始时间
    ================
    ]]
    function XMaverickManager.GetStartTime()
        return XFunctionManager.GetStartTimeByTimeId(CurrentActivity.TimeId) or 0
    end
    --[[
    ================
    获取玩法结束时间
    ================
    ]]
    function XMaverickManager.GetEndTime()
        return XFunctionManager.GetEndTimeByTimeId(CurrentActivity.TimeId) or 0
    end

    --[[
    ================
    获取模式开始时间
    ================
    ]]
    function XMaverickManager.GetPatternStartTime(patternId)
        local patternWithStage = XMaverickConfigs.GetPatternWithStageById(patternId)
        return XFunctionManager.GetStartTimeByTimeId(patternWithStage.Pattern.TimeId) or 0
    end
    --[[
    ================
    获取模式结束时间
    ================
    ]]
    function XMaverickManager.GetPatternEndTime(patternId)
        local patternWithStage = XMaverickConfigs.GetPatternWithStageById(patternId)
        return XFunctionManager.GetEndTimeByTimeId(patternWithStage.Pattern.TimeId) or 0
    end

    --[[
    ================
    获取玩法是否关闭(用于判断玩法入口，进入活动条件等)
    @return param1:玩法是否关闭
    @return param2:是否活动未开启
    ================
    ]]
    function XMaverickManager.IsActivityEnd()
        local timeNow = XTime.GetServerNowTimestamp()
        local isEnd = timeNow >= XMaverickManager.GetEndTime()
        local isStart = timeNow >= XMaverickManager.GetStartTime()
        local inActivity = (not isEnd) and (isStart)
        return (not inActivity), (not isStart)
    end

    --[[
     ================
     获取模式是否关闭(用于判断模式入口，进入模式条件等)
     @return param1:模式是否关闭
     @return param2:是否模式未开启
     @return param3:模式多久后开启
     ================
     ]]
    function XMaverickManager.IsPatternEnd(patternId)
        local timeNow = XTime.GetServerNowTimestamp()
        local timeStart = XMaverickManager.GetPatternStartTime(patternId)
        local timeEnd = XMaverickManager.GetPatternEndTime(patternId)
        local isEnd = timeNow >= timeEnd
        local isStart = timeNow >= timeStart
        local inPattern = (not isEnd) and (isStart)
        local remainStartTime = 0
        if not isStart then
            remainStartTime = timeStart - timeNow
        end
        return XMaverickManager.IsActivityEnd() --[[优先判断活动总的结束条件]] or (not inPattern), (not isStart), remainStartTime
    end

    --===================
    --获取活动名称
    --===================
    function XMaverickManager.GetActivityName()
        return CurrentActivity.Name
    end
    --===================
    --获取活动入口配图地址
    --===================
    function XMaverickManager.GetEntryTexture()
        return CurrentActivity.EntryTexture
    end

    --===================
    --获取活动总进度文本
    --===================
    function XMaverickManager.GetTotalProgressStr()
        local taskList = XDataCenter.TaskManager.GetTaskList(TaskType.Maverick) or { }
        local totalTaskCount = #taskList
        local finishedTaskCount = 0
        for _, task in ipairs(taskList) do
            if task.State == XDataCenter.TaskManager.TaskState.Finish then
                finishedTaskCount = finishedTaskCount + 1
            end
        end
        return CS.XTextManager.GetText("MaverickActivityProgressStr", finishedTaskCount, totalTaskCount)
    end

    --===================
    --获取模式进度
    --===================
    function XMaverickManager.GetPatternProgress(patternId)
        local stages = XMaverickManager.GetStages(patternId)
        local totalStageCount = #stages
        local finishedStageCount = 0
        for _, stage in pairs(stages) do
            if XMaverickManager.CheckStageFinished(stage.StageId) then
                finishedStageCount = finishedStageCount + 1
            end
        end
        return finishedStageCount, totalStageCount
    end

    --===================
    --获取模式进度文本
    --===================
    function XMaverickManager.GetPatternProgressStr(patternId)
        local stages = XMaverickManager.GetStages(patternId)
        local totalStageCount = #stages
        local finishedStageCount = 0
        for _, stage in pairs(stages) do
            if XMaverickManager.CheckStageFinished(stage.StageId) then
                finishedStageCount = finishedStageCount + 1
            end
        end
        return string.format("%d/%d", finishedStageCount, totalStageCount)
    end

    --===================
    --获取活动配置简表
    --===================
    function XMaverickManager.GetActivityChapters()
        local timeNow = XTime.GetServerNowTimestamp()
        local isEnd = timeNow >= XMaverickManager.GetEndTime()
        local isStart = timeNow >= XMaverickManager.GetStartTime()
        local inActivity = (not isEnd) and (isStart)
        if not inActivity then
            return {}
        end
        local chapters = {}
        table.insert(chapters, { Id = CurrentActivity.Id, Type = XDataCenter.FubenManager.ChapterType.Maverick})
        return chapters
    end

    --================
    --判断是否第一次进入玩法(本地存储纪录)
    --================
    function XMaverickManager.GetIsFirstIn()
        local activityName = XMaverickManager.GetActivityName()
        local localData = XSaveTool.GetData("MaverickFirstIn" .. XPlayer.Id .. activityName)
        if localData == nil then
            XSaveTool.SaveData("MaverickFirstIn".. XPlayer.Id .. activityName, true)
            return true
        end
        return false
    end

    function XMaverickManager.GetPatternIds()
        return CurrentActivity.PatternIds
    end

    function XMaverickManager.GetPatternName(patternId)
        local patternWithStage = XMaverickConfigs.GetPatternWithStageById(patternId)
        if not patternWithStage then
            return
        end

        return patternWithStage.Pattern.PatternName
    end

    function XMaverickManager.ContainRankStage(patternId)
        local rankStageId = CurrentActivity.RankStageId
        local stages = XMaverickManager.GetStages(patternId)

        for _, stage in pairs(stages) do
            if stage.StageId == rankStageId then
                return true
            end
        end

        return false
    end
    
    function XMaverickManager.CheckRankOpen()
        local stage = XMaverickManager.GetStage(CurrentActivity.RankStageId)
        
        return not XMaverickManager.IsPatternEnd(stage.PatternId)
    end

    function XMaverickManager.GetStages(patternId)
        return XMaverickConfigs.GetStages(patternId) or { }
    end

    --获取关卡词缀
    function XMaverickManager.GetStageAffixes(affixIds)
        local affixes = {}
        if affixIds then
            for i, eventId in ipairs(affixIds) do
                affixes[i] = XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId)
            end
        end
        return affixes
    end

    function XMaverickManager.CheckStageOpen(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if not stageCfg then
            return false
        end

        for _, preStageId in pairs(stageCfg.PreStageId or {}) do
            if not XMaverickManager.CheckStageFinished(preStageId) then
                return false
            end
        end

        return true
    end

    function XMaverickManager.GetStageScore(stageId)
        if XMaverickManager.CheckStageFinished(stageId) then
            return PassStageDataInfos[stageId].Score
        else
            return 0
        end
    end

    function XMaverickManager.CheckStageFinished(stageId)
        return PassStageDataInfos[stageId] ~= nil
    end

    function XMaverickManager.GetRankData(cb)
        XNetwork.Call(REQUEST_NAMES.GetRankList, nil,
                function(response)
                    if response.Code ~= XCode.Success then
                        XUiManager.TipCode(response.Code)
                        return
                    end

                    local data = { }
                    data.MaxRankCount = response.TotalCount
                    data.MyRankData = response.RankingInfo
                    data.MyRankData.RankNum = response.Ranking
                    data.RankListData = response.RankingPlayers or { }
                    --索引为排名
                    for i, rankData in ipairs(data.RankListData) do
                        rankData.RankNum = i
                    end

                    if cb then
                        cb(data)
                    end
                end)
    end

    function XMaverickManager.GetNumIcon(num)
        return XMaverickConfigs.GetNumIcon(num)
    end

    function XMaverickManager.EndActivity()
        XUiManager.TipText("MaverickEnd")
        XLuaUiManager.RunMain()
    end

    function XMaverickManager.EndPattern(patternId)
        local patternName = XMaverickManager.GetPatternName(patternId)
        XUiManager.TipText("MaverickPatternEnd", nil, true, patternName)
        XLuaUiManager.RunMain()
    end

    function XMaverickManager.GetPatternEnterFlag(patternId)
        local key = string.format(XMaverickManager.SaveKeys.Pattern, XPlayer.Id, CurrentActivity.Id or 0, patternId)
        return XSaveTool.GetData(key) ~= nil
    end

    function XMaverickManager.SetPatternEnterFlag(patternId)
        local key = string.format(XMaverickManager.SaveKeys.Pattern, XPlayer.Id, CurrentActivity.Id or 0, patternId)
        XSaveTool.SaveData(key, true)
    end

    function XMaverickManager.GetLastUsedMemberId()
        local key = string.format(XMaverickManager.SaveKeys.LastUsedCharacterId, XPlayer.Id, CurrentActivity.Id or 0)

        local memberId = XSaveTool.GetData(key)
        if (not memberId) or (not XMaverickManager.GetMember(memberId)) then --由于上一次选择的角色Id是存本地的所以要再判断一下
            local memberIds = { }
            for _, member in pairs(MemberDataInfos) do
                table.insert(memberIds, member.MemberId)
            end
            table.sort(memberIds) --以memberId为基础进行排序
            memberId = memberIds[1] --默认选择第一个成员
            XMaverickManager.SetLastUsedMemberId(memberId)
        end
        return memberId
    end

    function XMaverickManager.SetLastUsedMemberId(memberId)
        local key = string.format(XMaverickManager.SaveKeys.LastUsedCharacterId, XPlayer.Id, CurrentActivity.Id or 0)
        XSaveTool.SaveData(key, memberId)
    end

    function XMaverickManager.GetMemberIds(order)
        local memberIds = { }

        for _, member in pairs(MemberDataInfos) do
            table.insert(memberIds, member.MemberId)
        end

        local lastUsedMemberId = XMaverickManager.GetLastUsedMemberId()
        table.sort(memberIds, function(a, b)
            if order then --上次选择的角色优先放在第一个
                if a == lastUsedMemberId then
                    return true
                end

                if b == lastUsedMemberId then
                    return false
                end
            end
            return a < b
        end)

        return memberIds
    end

    function XMaverickManager.GetMember(memberId)
        for _, member in pairs(MemberDataInfos) do
            if member.MemberId == memberId then
                return member
            end
        end
    end

    function XMaverickManager.GetRobotId(member)
        return XMaverickConfigs.GetRobotId(member)
    end

    function XMaverickManager.GetCombatScore(member)
        return XMaverickConfigs.GetCombatScore(member)
    end

    function XMaverickManager.GetAttributes(memberId)
        return XMaverickConfigs.GetAttributes(memberId)
    end

    function XMaverickManager.GetMinMemberLevel(memberId)
        return XMaverickConfigs.GetMinMemberLevel(memberId)
    end

    function XMaverickManager.GetMaxMemberLevel(memberId)
        return XMaverickConfigs.GetMaxMemberLevel(memberId)
    end

    function XMaverickManager.GetSkills(memberId)
        return XMaverickConfigs.GetSkills(memberId)
    end

    function XMaverickManager.EnterFight(stageId, memberId)
        memberId = memberId or XMaverickManager.GetLastUsedMemberId()
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo then
            stageInfo.Type = XDataCenter.FubenManager.StageType.Maverick
        end
        
        local member = XDataCenter.MaverickManager.GetMember(memberId)
        local robotId = XDataCenter.MaverickManager.GetRobotId(member)
        Team.RobotIds = { robotId }
        Team.StageId = stageId

        local stage = XDataCenter.FubenManager.GetStageCfg(stageId)
        XDataCenter.FubenManager.EnterFight(stage)
    end

    function XMaverickManager.PreFight()
        return Team
    end

    function XMaverickManager.FinishFight(settle)
        if settle.IsWin then
            local stage = XMaverickManager.GetStage(settle.StageId)
            if stage.StageType == XMaverickManager.StageTypes.Endless then
                XLuaUiManager.Open("UiFubenMaverickFight", settle, function(stageScore)
                    --更新关卡数据
                    local stageInfos = {
                        { StageId = settle.StageId, Score = stageScore }
                    }
                    XMaverickManager.UpdateStageData(stageInfos)
                end)
            else
                local beginData = XDataCenter.FubenManager.GetFightBeginData()
                local winData = XDataCenter.FubenManager.GetChallengeWinData(beginData, settle)
                XLuaUiManager.Open("UiSettleWin", winData, nil, nil, true)
                --更新关卡数据
                local stageInfos = {
                    { StageId = settle.StageId, Score = 0 }
                }
                XMaverickManager.UpdateStageData(stageInfos)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_RESULT_WIN)
        else
            XLuaUiManager.Open("UiFubenMaverickLose")
        end
    end

    function XMaverickManager.CallFinishFight()
        local XFubenManager = XDataCenter.FubenManager
        local res = XFubenManager.FubenSettleResult
        XFubenManager.FubenSettling = false
        XFubenManager.FubenSettleResult = nil

        --通知战斗结束，关闭战斗设置页面
        CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_FINISH)

        if not res then
            -- 强退
            XLuaUiManager.Open("UiFubenMaverickLose")
            return
        end

        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            XLuaUiManager.Open("UiFubenMaverickLose")
            CS.XGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_SETTLE_FAIL, res.Code)
            return
        end
        
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FIGHT_RESULT, res.Settle)

        XMaverickManager.FinishFight(res.Settle)
    end
    
    function XMaverickManager.GetStage(stageId)
        return XMaverickConfigs.GetStage(stageId)
    end

    function XMaverickManager.GetMemberLvUpConsumeInfo(member)
        return XMaverickConfigs.GetMemberLvUpConsumeInfo(member)
    end

    function XMaverickManager.ResetMember(memberId)
        local tipTitle = CSXTextManagerGetText("ResetMaverickMemberConfirmTitle")
        local content = CSXTextManagerGetText("ResetMaverickMemberConfirmContent")
        local confirmCb = function()
            XNetwork.Call(REQUEST_NAMES.ResetMember, { MemberId = memberId }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end

                --激活天赋数据二次处理
                local member = reply.MemberDataInfo
                member.ActiveTalentIds = ListToDict(member.ActiveTalentIds)
                --更新数据缓存
                MemberDataInfos[memberId] = member
                
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_MAVERICK_MEMBER_UPDATE)
            end)
        end
        XLuaUiManager.Open("UiDialog", tipTitle, content, XUiManager.DialogType.Normal, nil, confirmCb)
    end

    function XMaverickManager.UpgradeMember(memberId)
        XNetwork.Call(REQUEST_NAMES.UpgradeMember, { MemberId = memberId }, function(reply)
            if reply.Code ~= XCode.Success then
                XUiManager.TipCode(reply.Code)
                return
            end

            --激活天赋数据二次处理
            local member = reply.MemberDataInfo
            member.ActiveTalentIds = ListToDict(member.ActiveTalentIds)
            --更新数据缓存
            MemberDataInfos[memberId] = member

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_MAVERICK_MEMBER_UPDATE)
        end)
    end

    function XMaverickManager.EnableTalent(memberId, talentId)
        XNetwork.Call(REQUEST_NAMES.EnableTalent, { MemberId = memberId, TalentId = talentId }, function(reply)
            if reply.Code ~= XCode.Success then
                XUiManager.TipCode(reply.Code)
                return
            end

            --更新数据缓存
            MemberDataInfos[memberId].ActiveTalentIds[talentId] = true

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_MAVERICK_MEMBER_UPDATE)
        end)
    end

    function XMaverickManager.DisableTalent(memberId, talentId)
        XNetwork.Call(REQUEST_NAMES.DisableTalent, { MemberId = memberId, TalentId = talentId }, function(reply)
            if reply.Code ~= XCode.Success then
                XUiManager.TipCode(reply.Code)
                return
            end

            --更新数据缓存
            for _, id in ipairs(reply.AllCancelActiveTalentIds) do
                MemberDataInfos[memberId].ActiveTalentIds[id] = nil
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_MAVERICK_MEMBER_UPDATE)
        end)
    end

    function XMaverickManager.UpdateMemberData(data)
        for _, info in pairs(data) do
            --成员数据二次处理 以解锁的天赋Id为key
            info.ActiveTalentIds = ListToDict(info.ActiveTalentIds)
            --更新数据缓存
            MemberDataInfos[info.MemberId] = info
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MAVERICK_MEMBER_UPDATE)
    end
    
    function XMaverickManager.UpdateStageData(data)
        for _, info in pairs(data) do
            local stageInfo = PassStageDataInfos[info.StageId]
            if stageInfo then
                if info.Score > stageInfo.Score then
                    stageInfo.Score = info.Score
                end
            else
                PassStageDataInfos[info.StageId] = info
            end
        end
    end

    function XMaverickManager.CheckTalentActive(memberId, talentId)
        return MemberDataInfos[memberId].ActiveTalentIds[talentId] ~= nil
    end

    function XMaverickManager.CheckTalentCanActive(memberId, talentId)
        if XMaverickManager.CheckTalentActive(memberId, talentId) then
            return false
        end
        
        local talentConfig = XMaverickManager.GetTalentConfig(talentId)
        local preTalentId = talentConfig.PreTalentId
        if preTalentId and preTalentId > 0 then
            return XMaverickManager.CheckTalentUnlock(memberId, talentId) and
                    XMaverickManager.CheckTalentActive(memberId, talentConfig.PreTalentId)
        else
            return XMaverickManager.CheckTalentUnlock(memberId, talentId)
        end
    end

    function XMaverickManager.CheckTalentUnlock(memberId, talentId)
        local talentConfig = XMaverickManager.GetTalentConfig(talentId)
        local member = XMaverickManager.GetMember(memberId)

        return member.Level >= talentConfig.UnlockLevel
    end

    function XMaverickManager.GetMemberActiveTalentIds(memberId)
        local activeTalentIds = { }
        for id, _ in pairs(MemberDataInfos[memberId].ActiveTalentIds) do
            table.insert(activeTalentIds, id)
        end
        return activeTalentIds
    end

    function XMaverickManager.GetMemberTalentIds(memberId)
        return XMaverickConfigs.GetMemberTalentIds(memberId)
    end

    function XMaverickManager.GetTalentConfig(talentId)
        return XMaverickConfigs.GetTalentConfig(talentId)
    end
    
    function XMaverickManager.GetPatternImagePath(patternId)
        return XMaverickConfigs.GetPatternImagePath(patternId)
    end
    
    function XMaverickManager.GetDisplayAttribs(member)
        local result = { }
        local displayAttribs = XMaverickConfigs.GetDisplayAttribs(member)
        for name, index in pairs(XMaverickManager.MemberPropertyTypes) do
            result[index] = displayAttribs[name]
        end
        
        return result
    end

    function XMaverickManager.InitStageInfo()
        local stageIds = XMaverickConfigs.GetAllStageIds()
        for _, stageId in ipairs(stageIds) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.Maverick
            end
        end
    end

    function XMaverickManager.CheckUnlockByStageId(stageId)
        return XMaverickManager.CheckStageOpen(stageId)
    end
    
    return XMaverickManager
end

-- =========        =========
-- =========XRpc方法=========
-- =========        =========
--活动数据初始化
XRpc.NotifyMaverickData = function(data)
    XDataCenter.MaverickManager.InitData(data.MaverickData)
end
--通关后推送的数据
XRpc.NotifyMaverickUnlockMemberData = function(data)
    XDataCenter.MaverickManager.UpdateMemberData(data.MemberDataInfos)
end