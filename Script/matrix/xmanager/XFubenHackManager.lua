local tableInsert = table.insert
local ipairs = ipairs
local pairs = pairs
local CsPlayerPrefs = CS.UnityEngine.PlayerPrefs
local KEY_LAST_LEVEL = "LastLevel"
local KEY_LAST_EXP = "LastExp"
local KEY_AFFIX_UNLOCK = "AffixUnlock"
local KEY_STAGE_DETAIL = "StageDetail"
local KEY_TEAM = "Team"

XFubenHackManagerCreator = function()
    local MAX_STAGE_STAR_COUNT = 3
    local XFubenHackManager = {}
    local ActivityInfo = nil
    local DefaultActivityInfo = nil

    local LevelInfo = {
        Level = 0,
        TotalExp = 0,
        Exp = 0,
        LastLevel = nil,
        LastExp = nil,
    }
    local CurChapterId = 1
    local IsTicketGet = false
    local BuffBarList = {}

    local StageStarRecordDic = {}
    local AffixUnlockMap = {} -- 已解锁buff表
    local RewardDic = {} --已经领取的星级奖励
    local LevelExpDic = {} -- 每一级所需要的总经验
    local BuffLevelDic = {} -- BuffId对应的等级
    local StageDetailReadDic = {} -- 关卡详情已读标记
    local BuffPosLevelDic = {} -- Buff栏开放表
    local IsRegisterEditBattleProxy = false

    -------- local function begin ----------
    local function Init()
        local activityTemplates = XFubenHackConfig.GetActTemplates()
        for _, template in pairs(activityTemplates) do
            DefaultActivityInfo = ActivityInfo or XFubenHackConfig.GetActivityTemplateById(template.Id)
        end

        XFubenHackManager.RegisterEditBattleProxy()
    end

    local function GetKey(key)
        return string.format("%s_FubenHack_%d_%d_%s", tostring(XPlayer.Id), ActivityInfo.Id, CurChapterId, key)
    end

    --最后一次保存的等级
    local function GetLastLevel()
        return LevelInfo.LastLevel or CsPlayerPrefs.GetInt(GetKey(KEY_LAST_LEVEL), -1)
    end

    local function GetLastExp()
        return LevelInfo.LastExp or CsPlayerPrefs.GetInt(GetKey(KEY_LAST_EXP), -1)
    end

    -- 保存当前等级
    local function SaveLevel(level)
        local curLevel = level or XFubenHackManager.GetLevel()
        CsPlayerPrefs.SetInt(KEY_LAST_LEVEL,  curLevel)
        CsPlayerPrefs.Save()
        LevelInfo.LastLevel = curLevel
    end

    local function SaveExp(exp)
        local curExp = exp or XFubenHackManager.GetTotalExp()
        CsPlayerPrefs.SetInt(KEY_LAST_EXP, curExp)
        LevelInfo.LastExp = curExp
    end

    local function GetLevelByExp(exp)
        for i = XFubenHackManager.GetMaxLevel(), 1, -1 do
            if exp >= LevelExpDic[i] then
                return i
            end
        end
    end

    local GetStarsCount = function(starsMark)
        local count = (starsMark & 1) + (starsMark & 2 > 0 and 1 or 0) + (starsMark & 4 > 0 and 1 or 0)
        local starMap = {(starsMark & 1) > 0, (starsMark & 2) > 0, (starsMark & 4) > 0 }
        return count, starMap
    end

    -------- local function end ----------
    local FUBEN_HACK_PROTO = {
        GetHackRewardRequest = "GetHackRewardRequest",
        SetHackBuffRequest = "SetHackBuffRequest",
        GetHackDailyTicketRequest = "GetHackDailyTicketRequest",
    }

    function XFubenHackManager.GetCurrentActTemplate()
        return ActivityInfo
    end

    function XFubenHackManager.OnActivityEnd()
        XLuaUiManager.RunMain()
        if XFubenHackManager.GetIsActivityEnd() then
            XUiManager.TipText("ActivityMainLineEnd", XUiManager.UiTipType.Wrong)
        else
            XUiManager.TipText("ArenaOnlineTimeOut", XUiManager.UiTipType.Wrong, true)
        end
    end

    -- 判断等级是否提升
    function XFubenHackManager.CheckLevelUp()
        local curLevel = XFubenHackManager.GetLevel()
        local lastLevel = GetLastLevel()
        -- -1 表示未保存过
        if lastLevel == -1 then
            SaveLevel()
            return false
        end
        if lastLevel < curLevel then
            XLuaUiManager.Open("UiHackLevelUpTips",lastLevel, curLevel)
            SaveLevel(curLevel)
            return true
        end
        return false
    end

    -- 判断经验是否提升
    function XFubenHackManager.CheckExpAdd()
        local curExp = XFubenHackManager.GetTotalExp()
        local lastExp = GetLastExp()
        -- -1 表示未保存过
        if lastExp == -1 then
            SaveExp()
            CsPlayerPrefs.Save()
            return false
        end

        if lastExp < curExp then
            local AnimTempLevel = GetLevelByExp(lastExp)
            local lastLevelExp = lastExp - LevelExpDic[AnimTempLevel]
            local lvCfg = XFubenHackManager.GetLevelCfg(AnimTempLevel)
            if LevelInfo.Level > AnimTempLevel then
                AnimTempLevel = AnimTempLevel + 1
                LevelInfo.LastExp = LevelExpDic[AnimTempLevel]
                return true, true, AnimTempLevel - 1, lastLevelExp, lvCfg.UpExp, lvCfg.UpExp
            else
                SaveExp(LevelInfo.TotalExp)
                return true, false, AnimTempLevel, lastLevelExp, XFubenHackManager.GetCurExp(), lvCfg.UpExp
            end
        end
        return false, false
    end

    -- 等级
    function XFubenHackManager.GetLevel()
        return LevelInfo.Level
    end

    function XFubenHackManager.GetTotalExp()
        return LevelInfo.TotalExp
    end

    function XFubenHackManager.GetCurExp()
        return LevelInfo.CurExp
    end

    function XFubenHackManager.GetNextUpExp()
        local lvCfg = XFubenHackManager.GetLevelCfg(LevelInfo.Level)
        if not lvCfg then
            return 0
        end
        return lvCfg.UpExp
    end

    function XFubenHackManager.GetReadDetailMark(stageId)
        return StageDetailReadDic[stageId]
    end

    function XFubenHackManager.SetReadDetailMark(stageId)
        StageDetailReadDic[stageId] = true
        XSaveTool.SaveData(GetKey(KEY_STAGE_DETAIL), StageDetailReadDic)
    end

    function XFubenHackManager.GetBuffBarList()
        return BuffBarList
    end

    function XFubenHackManager.GetBuffAbilityBonus()
        local bonus = 0
        for _, v in ipairs(BuffBarList) do
            if v ~= 0 then
                bonus = bonus + XFubenHackConfig.GetBuffById(v).AbilityBonus
            end
        end
        return bonus
    end

    function XFubenHackManager.CheckAffixEquip(buffId)
        for _, v in ipairs(BuffBarList) do
            if v == buffId then
                return true
            end
        end
        return false
    end

    function XFubenHackManager.GetLevelByBuffId(buffId)
        return BuffLevelDic[buffId]
    end

    function XFubenHackManager.CheckAffixRedPoint()
        for i = 1, LevelInfo.Level do
            if not AffixUnlockMap[i] then
                return true
            end
        end

        local count = 0
        local buffBarCount = 0
        for i = XFubenHackConfig.BuffBarCapacity, 0, -1 do
            if XFubenHackManager.IsBuffPosUnlock(i) then
                buffBarCount = i
                break
            end
        end

        for i = 1, buffBarCount do
            if BuffBarList[i] == 0  then
                if LevelInfo.Level >= buffBarCount then
                    return true
                end
            else
                count = count + 1
            end
        end

        if count < LevelInfo.Level and count < buffBarCount then
            return true
        end

        return false
    end

    function XFubenHackManager.GetBuffListShowIndex()
        for i = 1, LevelInfo.Level do
            if not AffixUnlockMap[i+1] then
                return i
            end
        end
        return LevelInfo.Level
    end

    function XFubenHackManager.IsAffixUnlock(level)
        return LevelInfo.Level >= level and AffixUnlockMap[level]
    end

    function XFubenHackManager.UnlockAffix(level)
        if LevelInfo.Level < level then
            local desc = CS.XTextManager.GetText("FubenHackUnlockBuffFail")
            return false, desc
        else
            AffixUnlockMap[level] = true
            XSaveTool.SaveData(GetKey(KEY_AFFIX_UNLOCK), AffixUnlockMap)
            local desc = CS.XTextManager.GetText("FubenHackUnlockBuffSucc")
            return true, desc
        end
    end

    function XFubenHackManager.IsBuffPosUnlock(index)
        return BuffPosLevelDic[index] and LevelInfo.Level >= BuffPosLevelDic[index], BuffPosLevelDic[index] or -1
    end

    function XFubenHackManager.GetLevelCfg(level)
        return XFubenHackConfig.GetLevelCfg(CurChapterId, level)
    end

    function XFubenHackManager.GetMaxLevel()
        local cfgs = XFubenHackConfig.GetLevelCfgs(CurChapterId)
        return cfgs and #cfgs or 0
    end

    -- 保存编队信息
    function XFubenHackManager.SaveTeamLocal(curTeam)
        XSaveTool.SaveData(GetKey(KEY_TEAM), curTeam)
    end

    -- 读取本地编队信息
    function XFubenHackManager.LoadTeamLocal()
        local team = XSaveTool.GetData(GetKey(KEY_TEAM)) or XDataCenter.TeamManager.EmptyTeam
        return team
    end

    --获取奖励
    function XFubenHackManager.GetStarRewardList()
        local ownStars = XFubenHackManager.GetStarProgress()
        local canGet = false
        local startIndex = 1
        local leastGap = XMath.IntMax()
        local starReward = {}
        for i, v in ipairs(XFubenHackManager.GetCurChapterTemplate().RewardId) do
            local cfg = XFubenHackConfig.GetRewardById(v)
            if cfg then
                local data = {}
                data.Id = cfg.Id
                data.RequireStar = cfg.NeedStars
                data.RewardId = cfg.RewardId
                data.IsFinish = ownStars >= cfg.NeedStars
                data.IsReward = XFubenHackManager.CheckStarRewardGet(v)
                starReward[i] = data
                if canGet then goto CONTINUE end
                if data.IsFinish and not data.IsReward then
                    startIndex = i
                    canGet = true
                elseif not data.IsFinish then
                    local gap = cfg.NeedStars - ownStars
                    if leastGap > gap then
                        leastGap = gap
                        startIndex = i
                    end
                end
            end
            ::CONTINUE::
        end

        return starReward, canGet, startIndex
    end

    --判断是否已经领奖
    function XFubenHackManager.CheckStarRewardGet(rewardId)
        if not rewardId then
            return
        end

        return RewardDic and RewardDic[rewardId]
    end

    function XFubenHackManager.GetStarReward(id, cb)
        XNetwork.Call(FUBEN_HACK_PROTO.GetHackRewardRequest, { Id = id }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            RewardDic[id] = true
            if cb then
                cb(res.RewardGoodsList)
            end

            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_HACK_UPDATE)
        end)
    end

    -- [初始化数据]
    function XFubenHackManager.InitStageInfo()
        local stages = XFubenHackConfig.GetStages()
        for _, v in pairs(stages) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(v.Id)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.Hack
            end
        end

        -- 通关后需要会执行InitStage 所以需要刷新
        XFubenHackManager.RefreshStagePassed()
    end

    function XFubenHackManager.RefreshStagePassed()
        if CurChapterId == 0 then return end
        local chapter = XFubenHackManager.GetCurChapterTemplate()
        for _, stageId in ipairs(chapter.StageId) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
            if stageInfo then
                stageInfo.Passed = StageStarRecordDic[stageId] or false
                stageInfo.StarsMap = XFubenHackManager.GetStarMap(stageId)
                stageInfo.Unlock = true
                stageInfo.IsOpen = true

                if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                    stageInfo.Unlock = false
                end

                for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                    if preStageId > 0 then
                        if not StageStarRecordDic[preStageId] then
                            stageInfo.Unlock = false
                            stageInfo.IsOpen = false
                            break
                        end
                    end
                end
            end
        end
    end

    function XFubenHackManager.CheckPreFight(stage)
        if not StageStarRecordDic[stage.StageId] then
            local consume = XFubenHackConfig.GetStageInfo(stage.StageId).ConsumeTicket
            local count = XDataCenter.ItemManager.GetCount(ActivityInfo.TicketId)
            if consume > count then
                local msg = CS.XTextManager.GetText("FubenHackTicketNotEnough")
                XUiManager.TipMsg(msg)
                return false
            end
        end
        return true
    end

    function XFubenHackManager.PreFight(stage, teamId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.RobotIds = {}
        preFight.StageId = stage.StageId

        if not stage.RobotId or #stage.RobotId <= 0 then
            local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
            for i, v in pairs(teamData) do
                local isRobot = XRobotManager.CheckIsRobotId(v)
                --preFight.RobotIds[i] = isRobot and v or 0
                if isRobot then tableInsert(preFight.RobotIds, v) end
                preFight.CardIds[i] =  XRobotManager.CheckIdToCharacterId(v)
            end
            preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
            preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
        end

        return preFight
    end

    -- [胜利]
    function XFubenHackManager.ShowReward(winData)
        if not winData then return end

        XLuaUiManager.Open("UiSettleWinMainLine", winData)
    end

    function XFubenHackManager.SetBuff(index, buffId, cb)
        if index == 0 then
            for pos, v in ipairs(BuffBarList) do
                if v == 0 and XFubenHackManager.IsBuffPosUnlock(pos) then
                    index = pos
                    break
                end
            end
        end

        if index ~= 0 then
            XNetwork.Call(FUBEN_HACK_PROTO.SetHackBuffRequest, {Index = index, BuffId = buffId},function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return false
                end

                BuffBarList[index] = buffId
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_HACK_UPDATE)

                cb(true)
            end)
        else
            cb(false, CS.XTextManager.GetText("FubenHackEquipBuffFail"))
        end
    end

    function XFubenHackManager.GetHackDailyTicket()
        if IsTicketGet then return false end
        XNetwork.Call(FUBEN_HACK_PROTO.GetHackDailyTicketRequest, {},function(res)
            if res.Code ~= XCode.Success then
                -- XUiManager.TipCode(res.Code)
                return false
            end

            IsTicketGet = true
            local rewards = {{ TemplateId = res.TicketId , Count = res.TicketCount }}
            XUiManager.OpenUiObtain(rewards, CS.XTextManager.GetText("FubenHackDailyTicket"))
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_HACK_UPDATE)
            return true
        end)
    end

    function XFubenHackManager.GetCurChapterTemplate()
        return XFubenHackConfig.GetChapterTemplate(CurChapterId) or {}
    end

    function XFubenHackManager.GetStarMap(stageId)
        local starsMark = StageStarRecordDic[stageId] or 0
        local count, starMap = GetStarsCount(starsMark)
        return starMap, count
    end

    -- 获取所有关卡进度
    function XFubenHackManager.GetStageSchedule()
        local chapter = XFubenHackManager.GetCurChapterTemplate()
        local passCount = 0
        local allCount = #chapter.StageId

        for _, stageId in ipairs(chapter.StageId) do
            if StageStarRecordDic[stageId] then
                passCount = passCount + 1
            end
        end

        return passCount, allCount
    end

    -- 主题活动页面是否可挑战接口
    function XFubenHackManager.IsChallengeable()
        if not ActivityInfo then return false end

        if not IsTicketGet or XDataCenter.ItemManager.GetCount(ActivityInfo.TicketId) > 0 then
            local passCount, allCount = XFubenHackManager.GetStageSchedule()
            if passCount < allCount then
                return true
            end
        end

        return false
    end

    -- 获取篇章星数
    function XFubenHackManager.GetStarProgress()
        local templates = XFubenHackManager.GetCurChapterTemplate()
        local totalStars = #templates.StageId * MAX_STAGE_STAR_COUNT
        local ownStars = 0
        for _, v in ipairs(templates.StageId) do
            local _, starCount = XFubenHackManager.GetStarMap(v)
            ownStars = ownStars + starCount
        end
        return ownStars, totalStars
    end

    function XFubenHackManager.GetAvailableActs()
        local act = XFubenHackManager.GetCurrentActTemplate()
        local activityList = {}
        if act and
                not XFubenHackManager.GetIsActivityEnd() and
                not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenHack) then
            tableInsert(activityList, {
                Id = act.Id,
                Type = XDataCenter.FubenManager.ChapterType.Hack,
                Name = act.Name,
                Icon = act.BannerBg,
            })
        end
        return activityList
    end

    --判断活动是否开启
    function XFubenHackManager.GetIsActivityEnd()
        if not ActivityInfo then
            return true, true
        end
        local timeNow = XTime.GetServerNowTimestamp()
        local isEnd = timeNow >= XFubenHackManager.GetEndTime()
        local isStart = timeNow >= XFubenHackManager.GetStartTime()
        local inActivity = (not isEnd) and (isStart)
        return not inActivity, timeNow < XFubenHackManager.GetStartTime()
    end

    --获取活动开始时间
    function XFubenHackManager.GetStartTime()
        if DefaultActivityInfo then
            return XFunctionManager.GetStartTimeByTimeId(DefaultActivityInfo.TimeId) or 0
        end
        return 0
    end

    --获取活动结束时间
    function XFubenHackManager.GetEndTime()
        if DefaultActivityInfo then
            return XFunctionManager.GetEndTimeByTimeId(DefaultActivityInfo.TimeId) or 0
        end
        return 0
    end

    --获取本轮结束时间
    function XFubenHackManager.GetCurChapterEndTime()
        local chapter = XFubenHackManager.GetCurChapterTemplate()
        if DefaultActivityInfo then
            return XFunctionManager.GetEndTimeByTimeId(chapter.TimeId) or 0
        end
        return 0
    end

    -- 注册出战界面代理
    function XFubenHackManager.RegisterEditBattleProxy()
        if IsRegisterEditBattleProxy then return end
        IsRegisterEditBattleProxy = true
        XUiNewRoomSingleProxy.RegisterProxy(XDataCenter.FubenManager.StageType.Hack,
                require("XUi/XUiFubenHack/Proxy/XUiHackNewRoomSingle"))
        XUiRoomCharacterProxy.RegisterProxy(XDataCenter.FubenManager.StageType.Hack,
                require("XUi/XUiFubenHack/Proxy/XUiHackRoomCharacter"))
    end

    --登录/活动开始/跨周时下发
    function XFubenHackManager.NotifyData(data)
        ActivityInfo = XFubenHackConfig.GetActivityTemplateById(data.Id)
        CurChapterId = data.ChapterId

        if CurChapterId ~= 0 then
            LevelExpDic = {[1] = 0}
            BuffPosLevelDic = {}
            local maxLv = XFubenHackManager.GetMaxLevel()
            for i = 1, maxLv do
                local levelCfg = XFubenHackManager.GetLevelCfg(i)
                LevelExpDic[i + 1] = LevelExpDic[i] + levelCfg.UpExp
                BuffLevelDic[levelCfg.BuffId] = i

                for pos = 1, levelCfg.UnlockBuffPos do
                    if not BuffPosLevelDic[pos] then
                        BuffPosLevelDic[pos] = i
                    end
                end
            end
            --BuffLevelDic[XFubenHackManager.GetLevelCfg(maxLv).BuffId] = maxLv

            LevelInfo.Level = data.Level
            LevelInfo.TotalExp = data.TotalExp
            LevelInfo.CurExp = data.TotalExp - LevelExpDic[data.Level] or 0
            IsTicketGet = data.IsTicketGet
            BuffBarList = data.LevelBuffIds

            RewardDic = {}
            for _, rewardId in ipairs(data.RewardIds) do
                RewardDic[rewardId] = true
            end

            StageStarRecordDic = {}
            for _, stageInfo in ipairs(data.StageInfos) do
                StageStarRecordDic[stageInfo.Id] = stageInfo.Star
            end
            XFubenHackManager.RefreshStagePassed()

            AffixUnlockMap = XSaveTool.GetData(GetKey(KEY_AFFIX_UNLOCK))
            if not AffixUnlockMap then
                AffixUnlockMap = {}
                for i = 1, LevelInfo.Level do
                    AffixUnlockMap[i] = true
                end
                XSaveTool.SaveData(GetKey(KEY_AFFIX_UNLOCK), AffixUnlockMap)
            end
            StageDetailReadDic = XSaveTool.GetData(GetKey(KEY_STAGE_DETAIL)) or {}
        end

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_ON_RESET, XDataCenter.FubenManager.StageType.Hack)
    end

    -- 下发等级数据
    function XFubenHackManager.NotifyHackLevelData(data)
        LevelInfo.Level = data.Level
        LevelInfo.TotalExp = data.TotalExp
        LevelInfo.CurExp = data.TotalExp - LevelExpDic[data.Level]
        -- 派发更新通知
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_HACK_UPDATE)
    end

    -- 下发关卡数据（通关星数）
    function XFubenHackManager.NotifyStageData(stageInfo)
        StageStarRecordDic[stageInfo.Id] = stageInfo.Star
        XFubenHackManager.RefreshStagePassed()
    end

    -- 下发门票领取状态
    function XFubenHackManager.NotifyHackTicketGetState(data)
        IsTicketGet = data.IsTicketGet
        -- 派发更新通知
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_HACK_UPDATE)
    end

    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, function()
        Init()
    end)
    return XFubenHackManager
end

XRpc.NotifyHackLoginData = function(data)
    --XDataCenter.FubenHackManager.NotifyData(data)
end

XRpc.NotifyHackLevelData = function(data)
    --XDataCenter.FubenHackManager.NotifyHackLevelData(data)
end

XRpc.NotifyHackStageInfoChange = function(data)
    --XDataCenter.FubenHackManager.NotifyStageData(data.StageInfo)
end

XRpc.NotifyHackTicketGetState = function(data)
    --XDataCenter.FubenHackManager.NotifyHackTicketGetState(data)
end
