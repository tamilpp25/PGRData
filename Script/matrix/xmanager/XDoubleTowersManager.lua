XDoubleTowersManagerCreator = function()
    local math = math
    local BaseInfo = require("XEntity/XDoubleTowers/XDoubleTowersInfo").New()
    local _DoubleTowerRankData = require("XEntity/XDoubleTowers/XDoubleTowerRankData").New()
    local StageState = XDoubleTowersConfigs.StageState
    local _CurSelectModuleType = XDoubleTowersConfigs.ModuleType.Role
    local _ModuleType2StrKey = {
        [XDoubleTowersConfigs.ModuleType.Role] = "Role",
        [XDoubleTowersConfigs.ModuleType.Guard] = "Guard"
    }

    ---@class XDoubleTowersManager
    local XDoubleTowersManager = {}

    --region local variable

    --==============================
    ---@desc 本地缓存key
    ---@key  目的
    ---@return string 构造的key
    --==============================
    local GetCookiesKey = function(key)
        return "XDoubleTowersManager_" .. XPlayer.Id .. "_" .. BaseInfo:GetActivityId() .. "_" .. key .. "_End"
    end

    --==============================
    ---@desc 检查角色插槽
    ---@return boolean
    --==============================
    local CheckRoleSlotUnlock = function(index)
        local key = GetCookiesKey(_ModuleType2StrKey[XDoubleTowersConfigs.ModuleType.Role])
        local data = XSaveTool.GetData(key)
        if not data then
            XSaveTool.SaveData(key, {[1] = true})
            return false
        else
            if index then
                return not data[index]
            else
                local count = XDoubleTowersConfigs.GetRolePluginMaxCount()
                -- 不检查第一个插槽
                for idx = 2, count do
                    local preStageId = XDoubleTowersConfigs.GetSlotPreStageId(idx, XDoubleTowersConfigs.ModuleType.Role)
                    local isUnLock = not XTool.IsNumberValid(preStageId) and true or BaseInfo:IsStagePassed(preStageId)
                    if not data[idx] and isUnLock then
                        return true
                    end
                end
            end
        end
        return false
    end

    --==============================
    ---@desc 检查守卫插槽
    ---@return boolean
    --==============================
    local CheckGuardSlotUnlock = function(index)
        local key = GetCookiesKey(_ModuleType2StrKey[XDoubleTowersConfigs.ModuleType.Guard])
        local data = XSaveTool.GetData(key)
        if not data then
            XSaveTool.SaveData(key, {[1] = true})
            return false
        else
            if index then
                return not data[index]
            else
                local count = XDoubleTowersConfigs.GetGuardPluginMaxCount()
                -- 不检查第一个插槽
                for idx = 2, count do
                    local preStageId = XDoubleTowersConfigs.GetSlotPreStageId(idx, XDoubleTowersConfigs.ModuleType.Guard)
                    local isUnLock = not XTool.IsNumberValid(preStageId) and true or BaseInfo:IsStagePassed(preStageId)
                    if not data[idx] and isUnLock then
                        return true
                    end
                end
            end
        end
        return false
    end
    --endregion

    --region global variable
    --显示装备与卸载提示
    XDoubleTowersManager.ShowEquipTips = nil
    --endregion

    XDoubleTowersManager.IsOpen = function()
        return XDoubleTowersManager.IsFunctionOpen() and XDoubleTowersManager.IsActivityOpen()
    end

    XDoubleTowersManager.IsFunctionOpen = function()
        local FunctionId = XFunctionManager.FunctionName.DoubleTowers
        return XFunctionManager.JudgeCanOpen(FunctionId)
    end

    XDoubleTowersManager.IsActivityOpen = function()
        return XFunctionManager.CheckInTimeByTimeId(XDoubleTowersManager.GetTimeLimitId())
    end

    XDoubleTowersManager.GetActivityChapters = function()
        local chapters = {}
        if XDoubleTowersManager.IsActivityOpen() then
            local temp = {}
            temp.Id = BaseInfo:GetActivityId()
            temp.Name = XDoubleTowersManager.GetActivityName()
            temp.BannerBg = XDoubleTowersConfigs.GetActivityBackground(BaseInfo:GetActivityId())
            temp.Type = XDataCenter.FubenManager.ChapterType.DoubleTowers
            table.insert(chapters, temp)
        end
        return chapters
    end

    XDoubleTowersManager.GetActivityStartTime = function()
        local timeId = XDoubleTowersConfigs.GetTimeLimitId(BaseInfo:GetActivityId())
        return XFunctionManager.GetStartTimeByTimeId(timeId)
    end

    XDoubleTowersManager.GetActivityEndTime = function()
        local timeId = XDoubleTowersConfigs.GetTimeLimitId(BaseInfo:GetActivityId())
        return XFunctionManager.GetEndTimeByTimeId(timeId)
    end

    XDoubleTowersManager.GetTimeLimitId = function()
        return XDoubleTowersConfigs.GetTimeLimitId(BaseInfo:GetActivityId())
    end

    XDoubleTowersManager.GetActivityName = function()
        return XDoubleTowersConfigs.GetTitleName(BaseInfo:GetActivityId())
    end

    XDoubleTowersManager.GetActivityRemainTime = function()
        local currentTime = XTime.GetServerNowTimestamp()
        return math.max(0, XFunctionManager.GetEndTimeByTimeId(XDoubleTowersManager.GetTimeLimitId()) - currentTime)
    end

    XDoubleTowersManager.NotifyDoubleTowersData = function(data)
        BaseInfo:UpdateData(data)
    end

    ---@return number@收菜货币的id
    XDoubleTowersManager.GetCoinItemId = function()
        return XDoubleTowersConfigs.GetCoinItemId(BaseInfo:GetActivityId())
    end

    ---@return number@距离下次收菜的剩余时间
    XDoubleTowersManager.GetGatherRemainTime = function()
        local lastGatherTime = BaseInfo:GetLastGatherTime()
        local currentTime = XTime.GetServerNowTimestamp()
        local passedTime = currentTime - lastGatherTime
        passedTime = math.max(passedTime, 0)

        local gatherInterval = XDoubleTowersConfigs.GetGatherInterval(BaseInfo:GetActivityId())
        if passedTime == 0 then
            return gatherInterval, gatherInterval
        end
        return gatherInterval - passedTime % gatherInterval, gatherInterval
    end

    ---@return number@最大储存代币数量
    XDoubleTowersManager.GetMaxCoinAmount = function()
        return XDoubleTowersConfigs.GetMaxCoins(BaseInfo:GetActivityId())
    end

    ---@return number@一次收集的代币数量
    XDoubleTowersManager.GetOnceGatherCoins = function()
        return XDoubleTowersConfigs.GetGatherCoins(BaseInfo:GetActivityId())
    end

    ---@return number@当前能收集的代币数量
    XDoubleTowersManager.GetCanGatherCoins = function()
        local lastGatherTime = BaseInfo:GetLastGatherTime()
        local currentTime = XTime.GetServerNowTimestamp()
        local passedTime = currentTime - lastGatherTime
        passedTime = math.max(passedTime, 0)

        local gatherInterval = XDoubleTowersConfigs.GetGatherInterval(BaseInfo:GetActivityId())
        local onceCoins = XDataCenter.DoubleTowersManager.GetOnceGatherCoins()

        -- 随时间增加的 + 已存储的
        local canGatherCoins = math.floor(passedTime / gatherInterval) * onceCoins + BaseInfo:GetCacheCoin()
        return math.min(canGatherCoins, XDoubleTowersManager.GetMaxCoinAmount())
    end

    XDoubleTowersManager.IsCoinFull = function()
        return XDoubleTowersManager.GetCanGatherCoins() >= XDoubleTowersManager.GetMaxCoinAmount()
    end

    XDoubleTowersManager.GetHelpKey = function()
        return XDoubleTowersConfigs.GetHelpKey(BaseInfo:GetActivityId())
    end

    XDoubleTowersManager.IsStageCanChallenge = function(stageId)
        if not stageId then
            return false
        end
        return XDoubleTowersManager.GetStageState(stageId) ~= StageState.Lock
    end

    XDoubleTowersManager.GetStageState = function(stageId)
        -- 已通关
        if BaseInfo:IsStagePassed(stageId) then
            return StageState.Clear
        end

        -- 未到开放时间
        local groupId = XDoubleTowersConfigs.GetGroupIdByStageId(stageId)
        if XDoubleTowersManager.IsGroupLocked4TimeLimit(groupId) then
            return StageState.Lock
        end

        -- 前置关卡未通关
        local preconditionStageId = XDoubleTowersConfigs.GetPreconditionStage(stageId)
        if not XDoubleTowersManager.IsStageClear(preconditionStageId) then
            return StageState.Lock
        end

        -- 默认可挑战
        return StageState.NotClear
    end

    -- 这个方法与GetStageState部分重复
    XDoubleTowersManager.GetGroupLockReason = function(groupId)
        local preconditionStageId = XDoubleTowersConfigs.GetGroupPreconditionStage(groupId)
        if not XDoubleTowersManager.IsStageClear(preconditionStageId) then
            return XDoubleTowersConfigs.ReasonOfLockGroup.PreconditionStageNotClear
        end
        if XDoubleTowersManager.IsGroupLocked4TimeLimit(groupId) then
            return XDoubleTowersConfigs.ReasonOfLockGroup.TimeLimit
        end
        return XDoubleTowersConfigs.ReasonOfLockGroup.None
    end

    XDoubleTowersManager.IsStageClear = function(stageId)
        -- 默认true
        if not stageId or stageId <= 0 then
            return true
        end
        return XDoubleTowersManager.GetStageState(stageId) == StageState.Clear
    end

    -- 关卡组 未到开放时间
    XDoubleTowersManager.IsGroupLocked4TimeLimit = function(groupId)
        local timelimitID = XDoubleTowersConfigs.GetGroupTimeLimitId(groupId)
        return timelimitID and timelimitID >= 0 and not XFunctionManager.CheckInTimeByTimeId(timelimitID, true)
    end

    XDoubleTowersManager.GetGroupState = function(groupId)
        if XDoubleTowersManager.IsGroupLocked4TimeLimit(groupId) then
            return StageState.Lock
        end
        local preconditionStageId = XDoubleTowersConfigs.GetGroupPreconditionStage(groupId)
        if not XDoubleTowersManager.IsStageClear(preconditionStageId) then
            return StageState.Lock
        end

        local group = XDoubleTowersManager.GetGroup(groupId)
        local clearAmount, lockAmount = 0, 0
        local stageAmount = #group
        -- 1关都每配，显示lock
        if stageAmount == 0 then
            return StageState.Lock
        end

        for stageIndex = 1, stageAmount do
            local stageId = group[stageIndex]
            local state = XDoubleTowersManager.GetStageState(stageId)
            -- 有任意关可挑战
            if state == StageState.NotClear then
                return StageState.NotClear
            end
            if state == StageState.Lock then
                lockAmount = lockAmount + 1
            elseif state == StageState.Clear then
                clearAmount = clearAmount + 1
            end
        end
        -- 所有关卡都clear
        if clearAmount == stageAmount then
            return StageState.Clear
        end
        -- 所有关卡都lock
        if lockAmount == stageAmount then
            return StageState.Lock
        end
        -- 默认lock，有可能是关卡组解锁了，但是没有一关可挑战
        XLog.Warning("XDoubleTowersManager 未定义的group state", ";通关数", clearAmount, ";未解锁数", lockAmount, ";关卡数量", #group)
        return StageState.Lock
    end

    XDoubleTowersManager.GetGroupOpenRemainTime = function(group)
        local timelimitID = XDoubleTowersConfigs.GetGroupTimeLimitId(group)
        if not timelimitID or timelimitID == 0 then
            return 0
        end
        local endTime = XFunctionManager.GetStartTimeByTimeId(timelimitID)
        local currentTime = XTime.GetServerNowTimestamp()
        local remainTime = endTime - currentTime
        return math.max(remainTime, 0)
    end

    XDoubleTowersManager.GetSpecialStageWinCount = function()
        return BaseInfo:GetSpecialStageWinCount()
    end

    -- 特殊关卡，不可选择，只能挑战下一关
    XDoubleTowersManager.GetSpecialStageId = function()
        local groupId = XDoubleTowersManager.GetSpecialGroupId()
        local group = XDoubleTowersManager.GetGroup(groupId)
        local isAllPassed = true
        for i = 1, #group do
            local stageId = group[i]
            if XDoubleTowersManager.GetStageState(stageId) ~= StageState.Clear then
                isAllPassed = false
                break
            end
        end
        if isAllPassed then
            return group[#group]
        end

        for i = 1, #group do
            local stageId = group[i]
            if XDoubleTowersManager.GetStageState(stageId) == StageState.NotClear then
                return stageId
            end
        end
        return group[1]
    end

    XDoubleTowersManager.IsSpecialStage = function(stageId)
        local groupId = XDoubleTowersConfigs.GetGroupIdByStageId(stageId)
        return XDoubleTowersManager.IsSpecialGroup(groupId)
    end

    ---@return XTeam
    XDoubleTowersManager.GetXTeam = function()
        ---@type XTeam
        local team = XDataCenter.TeamManager.GetXTeam(XDoubleTowersConfigs.TeamId)
        if not team then
            team = XDataCenter.TeamManager.GetXTeamByTypeId(XDoubleTowersConfigs.TeamTypeId)
            -- 去掉请求服务端的callback，即可
            team:UpdateSaveCallback(false)
            team.EntitiyIds[team.CaptainPos] = BaseInfo:GetTeamDb():GetRoleId()
        end
        return team
    end

    XDoubleTowersManager.OnOpenMain = function()
        if not XDoubleTowersManager.IsOpen() then
            XUiManager.TipText("FestivalActivityNotInActivityTime")
            return
        end
        XLuaUiManager.Open("UiDoubleTowers")
    end

    function XDoubleTowersManager.GetBaseInfo()
        return BaseInfo
    end

    function XDoubleTowersManager.GetActivityId()
        return XDoubleTowersManager.GetBaseInfo():GetActivityId()
    end

    function XDoubleTowersManager.GetNextStageId(stageId)
        local groupId = XDoubleTowersConfigs.GetGroupIdByStageId(stageId)
        local group = XDoubleTowersManager.GetGroup(groupId)
        local nextStageIndex = false
        for i = 1, #group do
            local id = group[i]
            if id == stageId then
                nextStageIndex = i
                break
            end
        end
        local nextStageId = false
        if nextStageIndex then
            nextStageId = group[nextStageIndex + 1]
        end
        if not nextStageId then
            local groupIndex = XDoubleTowersConfigs.GetGroupIndexByStageId(stageId)
            local nextGroupIndex = groupIndex + 1
            local nextGroupId = XDoubleTowersManager.GetGroupId(nextGroupIndex)
            local nextGroup = XDoubleTowersManager.GetGroup(nextGroupId)
            if nextGroup then
                nextStageId = nextGroup[1]
            end
        end
        return nextStageId
    end

    function XDoubleTowersManager.GetGroupId(groupIndex)
        return XDoubleTowersConfigs.GetGroupId(BaseInfo:GetActivityId(), groupIndex)
    end

    function XDoubleTowersManager.IsSpecialGroupUnlock()
        return XDoubleTowersManager.GetGroupState(XDoubleTowersManager.GetSpecialGroupId()) ~=
            XDoubleTowersConfigs.StageState.Lock
    end

    function XDoubleTowersManager.GetGroup(groupId)
        return XDoubleTowersConfigs.GetGroup(BaseInfo:GetActivityId(), groupId)
    end

    function XDoubleTowersManager.GetSpecialGroupId()
        return XDoubleTowersConfigs.GetSpecialGroupId(BaseInfo:GetActivityId())
    end

    function XDoubleTowersManager.IsSpecialGroup(groupId)
        return groupId == XDoubleTowersManager.GetSpecialGroupId()
    end

    function XDoubleTowersManager.GetStageId(groupId, stageIndex)
        return XDoubleTowersConfigs.GetStageId(BaseInfo:GetActivityId(), groupId, stageIndex)
    end

    --==============================
    ---@desc 排行榜数据
    --==============================
    function XDoubleTowersManager.GetRankData()
        return _DoubleTowerRankData
    end

    --==============================
    ---@desc 活动结束回调
    --==============================
    function XDoubleTowersManager.HandleActivityEndTime()
        XLuaUiManager.RunMain()
        XUiManager.TipText("ActivityAlreadyOver")
    end

    --==============================
    ---@desc 排行榜活动倒计时
    --==============================
    function XDoubleTowersManager.GetRankCountDownTime()
        return CSXTextManagerGetText(
            "DoubleTowersRankCountDown",
            XUiHelper.GetTime(XDoubleTowersManager.GetActivityRemainTime(), XUiHelper.TimeFormatType.DOUBLE_TOWER)
        )
    end

    --==============================
    ---@desc 设置当前的部署类型（仅能用于部署界面）
    --==============================
    function XDoubleTowersManager.RefreshSelectModuleType(moduleType)
        _CurSelectModuleType = moduleType
    end

    --==============================
    ---@desc 获取当前部署类型（仅能用于部署界面）
    --==============================
    function XDoubleTowersManager.GetSelectModuleType()
        return _CurSelectModuleType
    end

    -- 胜利 & 奖励界面
    function XDoubleTowersManager.ShowReward(winData)
        local stageId = winData.StageId
        if stageId then
            BaseInfo:IncreaseWinCount(stageId)
            BaseInfo:SetJustPassedStage(stageId)
        end
        XLuaUiManager.Open("UiDoubleTowersSettlement", winData)
    end

    function XDoubleTowersManager.GetJustPassedStage()
        return BaseInfo:GetJustPassedStage()
    end

    function XDoubleTowersManager.InitStageInfo()
        for _, cfg in pairs(XDoubleTowersConfigs.GetAllStageConfigs()) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(cfg.Id)
            stageInfo.Type = XDataCenter.FubenManager.StageType.DoubleTowers
        end
    end

    function XDoubleTowersManager.GetTotalNormalStageAmount()
        return XDoubleTowersConfigs.GetTotalNormalStageAmount(BaseInfo:GetActivityId())
    end

    function XDoubleTowersManager.GetPassedNormalStageAmount()
        local passedAmount = 0
        local activityId = BaseInfo:GetActivityId()
        local allGroup = XDoubleTowersConfigs.GetGroupConfigs()
        for groupId, groupCfg in pairs(allGroup) do
            if groupCfg.ActivityId == activityId and not groupCfg.IsSpecial then
                local group = XDoubleTowersManager.GetGroup(groupId)
                for i = 1, #group do
                    local stageId = group[i]
                    if XDoubleTowersManager.GetStageState(stageId) == XDoubleTowersConfigs.StageState.Clear then
                        passedAmount = passedAmount + 1
                    end
                end
            end
        end
        return passedAmount
    end

    function XDoubleTowersManager.SetRoleId(roleId)
        BaseInfo:GetTeamDb():SetRoleId(roleId)
    end

    --==============================
    ---@desc 红点检测 -- 是否有新的插槽解锁
    ---@moduleType 插件类型
    ---@return boolean
    --==============================
    function XDoubleTowersManager.CheckSlotUnlocked(args)
        local moduleType
        local index
        if args then
            moduleType = args.ModuleType
            index = args.Index
        end
        if moduleType then
            if moduleType == XDoubleTowersConfigs.ModuleType.Role then
                return CheckRoleSlotUnlock(index)
            elseif moduleType == XDoubleTowersConfigs.ModuleType.Guard then
                return CheckGuardSlotUnlock(index)
            end
            return false
        else
            if CheckRoleSlotUnlock() or CheckGuardSlotUnlock() then
                return true
            end
            return false
        end
    end

    --==============================
    ---@desc 更新本地解锁插槽数缓存
    ---@moduleType 插件类型
    --==============================
    function XDoubleTowersManager.RefreshUnlockSlotByModuleType(moduleType, index)
        if not moduleType then
            return
        end
        if not index then
            return
        end
        local key = GetCookiesKey(_ModuleType2StrKey[moduleType])
        local data = XSaveTool.GetData(key)
        if not data then
            data = {}
        end
        if not data[index] then
            data[index] = true
            XSaveTool.SaveData(key, data)
        end
    end

    --region request
    XDoubleTowersManager.RequestGatherCoins = function()
        XNetwork.CallWithAutoHandleErrorCode(
            "DoubleTowerTakeCacheCoinRequest",
            {},
            function(result)
                if result.Code ~= XCode.Success then
                    return
                end
                -- 更新时间
                local lastGatherTime = BaseInfo:GetLastGatherTime()
                local currentTime = XTime.GetServerNowTimestamp()
                local passedTime = currentTime - lastGatherTime
                passedTime = math.max(passedTime, 0)
                local gatherInterval = XDoubleTowersConfigs.GetGatherInterval(BaseInfo:GetActivityId())
                local addTime = math.floor(passedTime / gatherInterval) * gatherInterval
                BaseInfo:SetLastGatherTime(BaseInfo:GetLastGatherTime() + addTime)

                local cacheCoin = result.CacheCoin
                BaseInfo:SetCacheCoin(cacheCoin)

                XUiManager.TipText("DoubleTowersGatherSuccess")

                -- 需要立刻刷新界面
                XEventManager.DispatchEvent(XEventId.EVENT_DOUBLE_TOWERS_UPDATE_GATHER)
            end
        )
    end

    --请求升级插件
    function XDoubleTowersManager.RequestDoubleTowerUpgradePlugin(pluginId, cb)
        local req = {
            PluginId = pluginId --插件Id
        }
        XNetwork.CallWithAutoHandleErrorCode(
            "DoubleTowerUpgradePluginRequest",
            req,
            function(res)
                BaseInfo:UpdatePluginDb(res.PluginDb)
                if cb then
                    cb(pluginId)
                end
            end
        )
    end

    --请求设置插件
    -- req = {
    --     RoleId：角色配置Id
    --     RoleBasePluginId：SelectPluginType为0时传PluginLevelId，否则传PluginId
    --     RolePluginList：PluginId列表
    --     GuardId：守卫配置Id
    --     GuardBasePluginId：SelectPluginType为0时传PluginLevelId，否则传PluginId
    --     GuardPluginList：PluginId列表
    -- }
    function XDoubleTowersManager.RequestDoubleTowerSetTeam(cb)
        local teamDb = XDoubleTowersManager.GetBaseInfo():GetTeamDb()
        local req = teamDb:GetRequestDoubleTowerSetTeam()
        XNetwork.CallWithAutoHandleErrorCode(
            "DoubleTowerSetTeamRequest",
            req,
            function(res)
                if cb then
                    cb(res)
                end
            end
        )
    end

    --请求排行榜数据
    function XDoubleTowersManager.RequestDoubleTowerGetRank(cb)
        local req = {ActivityId = XDoubleTowersManager.GetBaseInfo():GetActivityId()}
        XNetwork.CallWithAutoHandleErrorCode(
            "DoubleTowerGetRankRequest",
            req,
            function(res)
                _DoubleTowerRankData:UpdateData(res)
                if cb then
                    cb()
                end
            end
        )
    end

    --重置插件
    function XDoubleTowersManager.RequestDoubleTowerResetPlugin(pluginIdList, cb)
        local pluginCount = #pluginIdList
        for _, pluginId in ipairs(pluginIdList) do
            XNetwork.CallWithAutoHandleErrorCode(
                "DoubleTowerResetPluginRequest",
                {PluginId = pluginId},
                function(res)
                    XDoubleTowersManager.GetBaseInfo():ResetPlugin(pluginId, res.Level)
                    if cb then
                        cb()
                    end
                end
            )
        end
    end
    --endregion

    return XDoubleTowersManager
end

--region Notify
XRpc.NotifyDoubleTowerActivity = function(data)
    XDataCenter.DoubleTowersManager.NotifyDoubleTowersData(data.ActivityDb)
end
--endregion
