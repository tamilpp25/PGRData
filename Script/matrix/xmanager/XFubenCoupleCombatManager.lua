local XCoupleCombatBaseData = require("XEntity/XCoupleCombat/XCoupleCombatBaseData")

local tableInsert = table.insert
local ipairs = ipairs
local pairs = pairs

XFubenCoupleCombatManagerCreator = function()
    local XFubenCoupleCombatManager = {}
    local ActivityInfo = nil
    local ActivityDay = 0
    local DefaultActivityInfo = nil

    local CoupleCombatDb = XCoupleCombatBaseData.New()
    local IsRegisterEditBattleProxy = false

    -------- local function begin ----------
    local function Init()
        if ActivityInfo then
            DefaultActivityInfo = ActivityInfo
        else
            local activityTemplates = XFubenCoupleCombatConfig.GetActTemplates()
            for _, template in pairs(activityTemplates) do
                DefaultActivityInfo = XFubenCoupleCombatConfig.GetActivityTemplateById(template.Id)
                if XFunctionManager.CheckInTimeByTimeId(DefaultActivityInfo.TimeId) then
                    ActivityInfo = DefaultActivityInfo
                end
            end
        end

        XFubenCoupleCombatManager.RegisterEditBattleProxy()
    end

    -------- local function end ----------
    local FUBEN_COUPLE_COMBAT_PROTO = {
        ResetStageMemberRequest = "CoupleCombatResetStageMemberRequest",
        AmendCharacterCareerSkillRequest = "CoupleCombatAmendCharacterCareerSkillRequest",
    }

    function XFubenCoupleCombatManager.GetCurrentActTemplate()
        return ActivityInfo or DefaultActivityInfo
    end

    function XFubenCoupleCombatManager.GetChapterTemplate(type)
        if not ActivityInfo then return {} end
        local id = ActivityInfo.ChapterIds[type]
        return XFubenCoupleCombatConfig.GetChapterTemplate(id) or {}
    end

    function XFubenCoupleCombatManager.OnActivityEnd()
        XLuaUiManager.RunMain()
        if XFubenCoupleCombatManager.GetIsActivityEnd() then
            XUiManager.TipText("ActivityMainLineEnd", XUiManager.UiTipType.Wrong)
        else
            XUiManager.TipText("ArenaOnlineTimeOut", XUiManager.UiTipType.Wrong, true)
        end
    end

    -- 检测关卡是否处于开放状态
    function XFubenCoupleCombatManager.CheckStageOpen(stageId)
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if not stageCfg then
            return false
        end
        local openDay = XFubenCoupleCombatConfig.GetStageOpenDay(stageId)
        if ActivityDay < openDay then
            local nowTime = XTime.GetServerNowTimestamp()
            local refreshTime = XTime.GetSeverNextRefreshTime()
            local remainTime = XUiHelper.GetTime((openDay - ActivityDay - 1) * 60 * 60 * 24 + refreshTime - nowTime, XUiHelper.TimeFormatType.MOE_WAR)
            return false, CS.XTextManager.GetText("ScheOpenCountdown", remainTime)
        end

        for _, preStageId in pairs(stageCfg.PreStageId or {}) do
            if not CoupleCombatDb:GetStageData(preStageId) then
                return false, CS.XTextManager.GetText("FubenPreStageNotPass")
            end
        end

        return true
    end

    function XFubenCoupleCombatManager.CheckChapterUnlock(chapterId)
        local timeId = XFubenCoupleCombatConfig.GetChapterTimeId(chapterId)
        if not XFunctionManager.CheckInTimeByTimeId(timeId) then
            local nowTime = XTime.GetServerNowTimestamp()
            local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
            local timeDesc = XUiHelper.GetTime(startTime - nowTime)
            return false, timeDesc
        end

        local isUnlock = CoupleCombatDb:IsUnlockChapter(chapterId)
        if isUnlock then
            return true, ""
        end

        return false, XFubenCoupleCombatConfig.GetChapterLockDesc(chapterId)
    end

    -- 获取关卡进度
    function XFubenCoupleCombatManager.GetStageSchedule(chapterId)
        local stageIds = XFubenCoupleCombatConfig.GetChapterStageIds(chapterId)
        local passCount = 0
        local allCount = #stageIds
        for _, stageId in ipairs(stageIds) do
            if CoupleCombatDb:IsStageUsedCharacter(stageId) then
                passCount = passCount + 1
            end
        end
        return passCount, allCount
    end

    --获得区域进度
    function XFubenCoupleCombatManager.GetChapterSchedule()
        local activityInfo = XFubenCoupleCombatManager.GetCurrentActTemplate()
        local chapterIdList = not XTool.IsTableEmpty(activityInfo) and activityInfo.ChapterIds or XFubenCoupleCombatConfig.GetChapterIdList()
        local chapterAllCount = #chapterIdList
        local chapterPassCount = 0
        local stagePassCount, stageAllCount
        for _, chapterId in ipairs(chapterIdList) do
            stagePassCount, stageAllCount = XFubenCoupleCombatManager.GetStageSchedule(chapterId)
            if stagePassCount == stageAllCount then
                chapterPassCount = chapterPassCount + 1
            end
        end

        return chapterPassCount, chapterAllCount
    end

    --==============================
    ---@desc 新副本界面进度
    ---@return string
    --==============================
    function XFubenCoupleCombatManager.GetProgressTips()
        local activityInfo = XFubenCoupleCombatManager.GetCurrentActTemplate()
        local chapterIdList = not XTool.IsTableEmpty(activityInfo) and activityInfo.ChapterIds or XFubenCoupleCombatConfig.GetChapterIdList()
        local chapterStagePassCount = 0
        local chapterStageAllCount = 0
        for _, chapterId in ipairs(chapterIdList) do
            local stagePassCount, stageAllCount = XFubenCoupleCombatManager.GetStageSchedule(chapterId)
            chapterStagePassCount = chapterStagePassCount + stagePassCount
            chapterStageAllCount = chapterStageAllCount + stageAllCount
        end
        return XUiHelper.GetText("ActivityBossSingleProcess", chapterStagePassCount, chapterStageAllCount)
    end

    function XFubenCoupleCombatManager.GetFeatureMatch(stageId, teamData)
        local matchDic = {}
        local featureList = {}
        local feature = XFubenCoupleCombatManager.GetStageFeatureIdList(stageId)
        if not feature then return matchDic end
        featureList[0] = feature
        for _, v in ipairs(feature) do
            matchDic[v] = 0
        end

        for i, id in ipairs(teamData) do
            local charFeature = XFubenCoupleCombatConfig.GetCharacterFeature(id)
            featureList[i] = charFeature
            for _, v in ipairs(charFeature) do
                if matchDic[v] then
                    matchDic[v] = matchDic[v] + 1
                end
            end
        end
        return matchDic, featureList
    end

    --v1.32 角色特性与关卡推荐特性重合特性
    function XFubenCoupleCombatManager.GetFeatureMatchOneChar(stageId, charId)
        local matchDic = {}
        local feature = XFubenCoupleCombatManager.GetStageFeatureIdList(stageId)
        if not feature then return matchDic end
        for _, v in ipairs(feature) do
            matchDic[v] = 0
        end

        local charFeature = XFubenCoupleCombatConfig.GetCharacterFeature(charId)
        for _, v in ipairs(charFeature) do
            if matchDic[v] then
                matchDic[v] = matchDic[v] + 1
            end
        end
        return matchDic
    end

    --v1.32 获得关卡推荐特效
    function XFubenCoupleCombatManager.GetStageFeatureIdList(stageId)
        local featureDic = {}
        local result = {}
        local stageInterInfo = XFubenCoupleCombatConfig.GetStageInfo(stageId)
        if not stageInterInfo then return featureDic end
        for _, v in ipairs(stageInterInfo.Feature) do
            if not XTool.IsNumberValid(featureDic[v]) then
                table.insert(result, v)
            end
            featureDic[v] = v
        end
        return result
    end

    -- 检测角色是否已使用状态
    function XFubenCoupleCombatManager.CheckCharacterUsed(stageId, charId)
        return CoupleCombatDb:IsCharacterUsed(stageId, charId)
    end

    function XFubenCoupleCombatManager.GetStageUsedCharacter(stageId)
        return CoupleCombatDb:GetCharacterIds(stageId)
    end

    function XFubenCoupleCombatManager.GetUsedSkillIds()
        return CoupleCombatDb:GetUsedSkillIds()
    end

    function XFubenCoupleCombatManager.IsSkillUsed(skillId)
        local usedSkillIds = XFubenCoupleCombatManager.GetUsedSkillIds()
        for _, usedSkillId in ipairs(usedSkillIds) do
            if usedSkillId == skillId then
                return true
            end
        end
        return false
    end

    --根据技能类型返回正在使用中的技能Id
    function XFubenCoupleCombatManager.GetUsedSkillByType(type)
        local usedSkillIds = XFubenCoupleCombatManager.GetUsedSkillIds()
        for _, usedSkillId in ipairs(usedSkillIds) do
            local types = XFubenCoupleCombatConfig.GetCharacterCareerSkillType(usedSkillId)
            for _, careerType in ipairs(types) do
                if careerType == type then
                    return usedSkillId
                end
            end
        end
    end

    function XFubenCoupleCombatManager.GetChapterRobotIdsByStageId(stageId)
        local chapterId = XFubenCoupleCombatConfig.GetChapterIdByStageId(stageId)
        if not chapterId then
            return
        end

        local robotIds = XFubenCoupleCombatConfig.GetChapterRobotIds(chapterId)
        -- local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(stageId)
        -- local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
        -- local limitTypeRobotIdList = {}
        -- for _, robotId in ipairs(robotIds) do
        --     if defaultCharacterType == XRobotManager.GetRobotCharacterType(robotId) then
        --         table.insert(limitTypeRobotIdList, robotId)
        --     end
        -- end

        return robotIds
    end

    -- [初始化数据]
    function XFubenCoupleCombatManager.InitStageInfo()
        local stageIdList = XFubenCoupleCombatConfig.GetStageIdList()
        for _, stageId in ipairs(stageIdList) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                stageInfo.Type = XDataCenter.FubenManager.StageType.CoupleCombat
            end
        end

        -- 通关后会执行InitStage 所以需要刷新
        XFubenCoupleCombatManager.RefreshStagePassed()
    end

    function XFubenCoupleCombatManager.RefreshStagePassed()
        for _, chapter in pairs(XFubenCoupleCombatConfig.GetChapterTemplates()) do
            for _, stageId in ipairs(chapter.StageIds) do
                local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                if stageInfo then
                    stageInfo.Passed = CoupleCombatDb:GetStageData(stageId) and true or false
                    stageInfo.Unlock = XFubenCoupleCombatManager.CheckStageOpen(stageId)
                    stageInfo.IsOpen = true

                    if stageCfg.RequireLevel > 0 and XPlayer.Level < stageCfg.RequireLevel then
                        stageInfo.Unlock = false
                    end

                    for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                        if preStageId > 0 then
                            if not CoupleCombatDb:GetStageData(preStageId) then
                                stageInfo.Unlock = false
                                stageInfo.IsOpen = false
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    function XFubenCoupleCombatManager.IsHaveNextStageIdByStageId(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        return stageInfo and stageInfo.NextStageId and true or false
    end

    function XFubenCoupleCombatManager.PreFight(stage, teamId)
        local preFight = {}
        preFight.CardIds = {}
        preFight.RobotIds = {}
        preFight.StageId = stage.StageId
        local teamData = XDataCenter.TeamManager.LoadTeamLocal(stage.StageId)
        for _, v in pairs(teamData.TeamData or {}) do
            if not XRobotManager.CheckIsRobotId(v) then
                table.insert(preFight.CardIds, v)
                table.insert(preFight.RobotIds, 0)
            else
                table.insert(preFight.CardIds, 0)
                table.insert(preFight.RobotIds, v)
            end
        end

        preFight.CaptainPos = teamData.CaptainPos
        preFight.FirstFightPos = teamData.FirstFightPos

        return preFight
    end

    function XFubenCoupleCombatManager.GetAvailableActs()
        local act = ActivityInfo or DefaultActivityInfo
        local activityList = {}
        if act and
                not XFubenCoupleCombatManager.GetIsActivityEnd() and
                not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FubenCoupleCombat) then
                tableInsert(activityList, {
                    Id = act.Id,
                    Type = XDataCenter.FubenManager.ChapterType.CoupleCombat,
                    Name = act.Name,
                    Icon = act.BannerBg,
                })
        end
        return activityList
    end

    --判断活动是否开启
    function XFubenCoupleCombatManager.GetIsActivityEnd()
        local timeNow = XTime.GetServerNowTimestamp()
        local isEnd = timeNow >= XFubenCoupleCombatManager.GetEndTime()
        local isStart = timeNow >= XFubenCoupleCombatManager.GetStartTime()
        local inActivity = (not isEnd) and (isStart)
        return not inActivity, timeNow < XFubenCoupleCombatManager.GetStartTime()
    end

    --获取活动开始时间
    function XFubenCoupleCombatManager.GetStartTime()
        if DefaultActivityInfo then
            return XFunctionManager.GetStartTimeByTimeId(DefaultActivityInfo.TimeId) or 0
        end
        return 0
    end

    --获取活动结束时间
    function XFubenCoupleCombatManager.GetEndTime()
        if DefaultActivityInfo then
            return XFunctionManager.GetEndTimeByTimeId(DefaultActivityInfo.TimeId) or 0
        end
        return 0
    end

    --获得当前活动时间内的章节Id列表
    function XFubenCoupleCombatManager.GetChapterIdList()
        return DefaultActivityInfo and DefaultActivityInfo.ChapterIds or {}
    end

    -- 主题活动页面是否可挑战接口
    function XFubenCoupleCombatManager.IsChallengeable()
        if not ActivityInfo then return false end

        local chapterIdList = XFubenCoupleCombatConfig.GetChapterIdList()
        local isUnlock
        local stageIds
        for _, chapterId in ipairs(chapterIdList) do
            isUnlock = XFubenCoupleCombatManager.CheckChapterUnlock(chapterId)
            if not isUnlock then
                goto continue
            end

            stageIds = XFubenCoupleCombatConfig.GetChapterStageIds(chapterId)
            for _, stageId in ipairs(stageIds) do
                if XFubenCoupleCombatManager.CheckStageOpen(stageId) and not CoupleCombatDb:GetStageData(stageId) then
                    return true
                end
            end

            :: continue ::
        end

        return false
    end

    -- 注册出战界面代理
    function XFubenCoupleCombatManager.RegisterEditBattleProxy()
        if IsRegisterEditBattleProxy then return end
        IsRegisterEditBattleProxy = true
        XUiNewRoomSingleProxy.RegisterProxy(XDataCenter.FubenManager.StageType.CoupleCombat,
                require("XUi/XUiFubenCoupleCombat/Proxy/XUiCoupleCombatNewRoomSingle"))
        XUiRoomCharacterProxy.RegisterProxy(XDataCenter.FubenManager.StageType.CoupleCombat,
                require("XUi/XUiFubenCoupleCombat/Proxy/XUiCoupleCombatRoomCharacter"))
    end

    --检查是否有新职业技能解锁，并弹出提示界面
    function XFubenCoupleCombatManager.CheckCharacterCareerSkillInDic()
        local activeSkillList = CoupleCombatDb:CheckCharacterCareerSkillInDic()
        if XTool.IsTableEmpty(activeSkillList) then
            return
        end

        XLuaUiManager.Open("UiCoupleCombatNewSkill", activeSkillList)
    end

    --检查自动装备技能
    function XFubenCoupleCombatManager.CheckAutoAmendSkill()
        local skillGroupTypeToSkillIdsMap = XFubenCoupleCombatConfig.GetSkillGroupTypeToSkillIdsMap()
        local condition
        local isUnlock
        local selectedSkillIds = {}
        local selectedSkillTypes = {}
        for careerType, skillIds in pairs(skillGroupTypeToSkillIdsMap) do
            for _, skillId in ipairs(skillIds) do
                if selectedSkillTypes[careerType] then
                    goto continue
                end

                condition = XFubenCoupleCombatConfig.GetCharacterCareerSkillCondition(skillId)
                isUnlock = not XTool.IsNumberValid(condition) and true or XConditionManager.CheckCondition(condition)
                if not CoupleCombatDb:GetUsedSkillIdBySkillType(careerType) and isUnlock then
                    table.insert(selectedSkillIds, skillId)
                    selectedSkillTypes[careerType] = skillId
                end
                :: continue ::
            end
        end

        if not XTool.IsTableEmpty(selectedSkillIds) then
            XFubenCoupleCombatManager.RequestAmendCharacterCareerSkill(selectedSkillIds)
        end
    end

    --修改上阵角色职业技能请求
    function XFubenCoupleCombatManager.RequestAmendCharacterCareerSkill(selectedSkillIds)
        local usedSkillIds = XTool.Clone(XFubenCoupleCombatManager.GetUsedSkillIds())
        local selectedSkillType
        local isSameTypeSkill
        for _, selectedSkillId in ipairs(selectedSkillIds) do
            isSameTypeSkill = false
            selectedSkillType = XFubenCoupleCombatConfig.GetCharacterCareerSkillType(selectedSkillId)
            for i, skillId in ipairs(usedSkillIds) do
                --存在相同类型的技能时替换
                if selectedSkillType == XFubenCoupleCombatConfig.GetCharacterCareerSkillType(skillId) then
                    usedSkillIds[i] = selectedSkillId
                    isSameTypeSkill = true
                    break
                end
            end

            if not isSameTypeSkill then
                table.insert(usedSkillIds, selectedSkillId)
            end
        end

        XNetwork.Call(FUBEN_COUPLE_COMBAT_PROTO.AmendCharacterCareerSkillRequest, { SelectedSkillIds = usedSkillIds }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            CoupleCombatDb:UpdateUsedSkillIds(usedSkillIds)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_COUPLECOMBAT_AMEND_CHARACTER_CAREER_SKILL, selectedSkillIds)
        end)
    end

    --重置关卡
    function XFubenCoupleCombatManager.ResetStage(stageId, cb)
        XNetwork.Call(FUBEN_COUPLE_COMBAT_PROTO.ResetStageMemberRequest, { StageId = stageId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            CoupleCombatDb:ResetStage(stageId)
            XDataCenter.TeamManager.SaveTeamLocal(XTool.Clone(XDataCenter.TeamManager.EmptyTeam), stageId)

            if cb then cb() end
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE)
        end)
    end

    --登录/活动开始/跨周时下发
    function XFubenCoupleCombatManager.NotifyData(data)
        ActivityInfo = XFubenCoupleCombatConfig.GetActivityTemplateById(data.Data.ActivityId)
        if not ActivityInfo then
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_ON_RESET, XDataCenter.FubenManager.StageType.CoupleCombat)
            return
        end
        ActivityDay = data.ActivityDay
        Init()

        CoupleCombatDb:UpdateData(data.Data)

        XFubenCoupleCombatManager.RefreshStagePassed()

        XFubenCoupleCombatManager.CheckAutoAmendSkill()
        CoupleCombatDb:CheckCharacterCareerSkillInDic()
    end

    -- 下发关卡数据（通关星数）
    function XFubenCoupleCombatManager.NotifyStageData(data)
        local stageInfo = data.StageData
        CoupleCombatDb:UpdateStageData(stageInfo)
        CoupleCombatDb:UpdateUnlockChapterIds(data.UnlockChapterIds)

        XFubenCoupleCombatManager.RefreshStagePassed()
        XDataCenter.TeamManager.SaveTeamLocal(XTool.Clone(XDataCenter.TeamManager.EmptyTeam), stageInfo.StageId)
        XFubenCoupleCombatManager.CheckAutoAmendSkill()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE)
    end

    -- 下发活动天数（每日数据变化（日重置闹钟））
    function XFubenCoupleCombatManager.NotifyDailyData(data)
        ActivityDay = data.ActivityDay
        XFubenCoupleCombatManager.RefreshStagePassed()
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_COUPLECOMBAT_UPDATE)
    end

    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, function()
        Init()
    end)
    return XFubenCoupleCombatManager
end

XRpc.NotifyCoupleCombatData = function(data)
    --XDataCenter.FubenCoupleCombatManager.NotifyData(data)
end

XRpc.NotifyCoupleCombatStageData = function(data)
    --XDataCenter.FubenCoupleCombatManager.NotifyStageData(data)
end

XRpc.NotifyCoupleCombatDailyData = function(data)
    --XDataCenter.FubenCoupleCombatManager.NotifyDailyData(data)
end